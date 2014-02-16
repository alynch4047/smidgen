
/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.make_wrapping;

import std.stdio: writeln;
import std.path: buildPath, dirName, baseName;
import std.conv: to;
import std.file: copy, File, mkdirRecurse, dirEntries, readText, mkdir, exists;
import std.algorithm: filter, canFind;
import std.c.stdlib: exit;
import std.stream: FileMode;
import std.array: replace;
import std.string: format;

import smidgen.make_c_wrapper;
import smidgen.make_d_wrapper;
import smidgen.make_c_package_wrapper;
import smidgen.handle_includes_and_ifs;
import smidgen.parse_sip;
import smidgen.load_converter: loadConverter;
import smidgen.base_converters: Converter, getBaseConverters, EnumConverter;
import smidgen.converter_manager: ConverterManager;

import smidgen.ast.other;
import smidgen.ast.klass: Klass;
import smidgen.ast.package_: ModulePackage;
import smidgen.ast.modules_holder: ModulesHolder;

enum wrappedObjectSrc = import("WrappedObject.d");
enum wrappedObjectBaseSrc = import("WrappedObjectBase.d");
enum createdBySrc = import("created_by.d");
enum instanceTrackerCPP = import("instance_tracker.cpp");
enum instanceTrackerH = import("instance_tracker.h");


int main(char[][] args) {
	
	string SipFilePath, SipDirectory, buildDir, CDirectory, DDirectory;
	
	if (args.length == 3) {
		SipFilePath = to!string(args[1]);
		SipDirectory = SipFilePath.dirName();
		buildDir = to!string(args[2]);
	}
	else {
		writeln("You must specify two arguments, the main Sip file path \n"
			"and output directory where the generated files will be written to.");
		exit(-1);
	}
	string sipFileMainName = SipFilePath.baseName();
	string sipWorkingDirecctory = SipFilePath.dirName();
	
	bool dontWrapDoubleUnderscoreMethods = false;

	auto getSipFileLines(string sipFileName, string workingDirectory) {
		auto file = File(buildPath(workingDirectory, sipFileName));
		return file.byLine;
	}
	auto mainSipFileData = handle_incs_and_ifs!getSipFileLines(sipFileMainName, 
																	sipWorkingDirecctory);	
	
	auto pt = Smidgen(mainSipFileData);
	if (! pt.successful) {
		writeln(pt);
		writeln("Sip parser failed!");
		exit(-1);
	}

	ModulesHolder modulesHolder = new ModulesHolder(pt);
	auto converterManager = modulesHolder.converterManager;
	
	foreach(converterName; modulesHolder.converterNames) {
		string converterFileName = buildPath(SipDirectory, converterName);
		string converterData = readText(converterFileName);
		Converter converter = loadConverter(converterData);
		converterManager.addConverter(converter);
		// this is crazy but unfortunately I can't import EnumConverter into 
		// ConverterManager as I get compile errors if I do so
		converterManager.enumConverter = new EnumConverter();
	}
	
	foreach(converter; getBaseConverters) {
		converterManager.addConverter(converter);
	}
	
	CDirectory = buildPath(buildDir, "cpp");
	DDirectory = buildPath(buildDir, "d");
	
	writeln("SIP files read from  : " ~ SipDirectory);
	writeln("Main SIP file is     : " ~ sipFileMainName);
	writeln("C++ files written to : " ~ CDirectory);
	writeln("D   files written to : " ~ DDirectory);	
	if (! exists(DDirectory)) {
		mkdirRecurse(DDirectory);
	}
	if (! exists(CDirectory)) {
		mkdirRecurse(DDirectory);
	}	
	
	createSMICommonModule(DDirectory);
	
	foreach(modulePackage; modulesHolder.packages) {
		
		writeln("Wrapping module ", modulePackage.moduleName_);
		
		string[] nonAbstractClassNames;
		string[] allInterfaceNames;

		string packageDDirectory = buildPath(DDirectory, modulePackage.moduleName_);
		if (! exists(packageDDirectory)) {
			mkdirRecurse(packageDDirectory);
		}
		
		string packageCDirectory = buildPath(CDirectory, modulePackage.moduleName_);
		if (! exists(packageCDirectory)) {
			mkdirRecurse(packageCDirectory);
		}		
	
		foreach(klass; modulePackage.klasses) {
			foreach(interfaceName; klass.interfaceNames) {
				if(! canFind(allInterfaceNames, interfaceName)) {
					allInterfaceNames ~= interfaceName;
				}
			}
		}	
		
		foreach(interfaceName; allInterfaceNames) {
			writeln(interfaceName, " will be wrapped as an interface");
			modulePackage.getClassOfName(interfaceName).wrapAsInterface = true;
		}	
		
		foreach(klass; modulePackage.klasses) {
			if (! klass.abstract_ && ! klass.wrapAsInterface) {
				nonAbstractClassNames ~= klass.name;
			}
		}
		
		writePackageWrappers(modulePackage, packageDDirectory, packageCDirectory);		
		
		copyBaseFiles(packageDDirectory, packageCDirectory,
			 								modulePackage, nonAbstractClassNames);
		
		makeCPackageWrapper(packageCDirectory, modulePackage);
	}
	
	writeln("Smidgen DONE");
	return 0;
}


void createSMICommonModule(string DDirectory) {
	string packageDDirectory = buildPath(DDirectory, "smicommon");
	if (! exists(packageDDirectory)) {
		mkdirRecurse(packageDDirectory);
	}
	auto fileName = buildPath(packageDDirectory, "created_by.d");
	auto file_ = new std.stream.File(fileName, FileMode.OutNew);
	file_.writeString(createdBySrc);	
	
	fileName = buildPath(packageDDirectory, "WrappedObjectBase.d");
	file_ = new std.stream.File(fileName, FileMode.OutNew);
	file_.writeString(wrappedObjectBaseSrc);	
}

void writePackageWrappers(Package package_, string DDirectory, string CDirectory) {
	
	writePackageGlobals(package_, DDirectory);	
		
	string fileName = buildPath(CDirectory, "cpp_wrappers.txt");
	auto file_ = new std.stream.File(fileName, FileMode.OutNew);
	file_.writeString("The following files should be compiled into this modules' wrapper:\n\n");	
	foreach(klass; package_.klasses) {
		assert(! klass.isEnum);
		makeDClassWrapper(DDirectory, klass);
		makeCClassWrapper(CDirectory, klass);
		if (klass.wrapAsInterface) {
			makeDInterfaceWrapper(DDirectory, klass);
		}
		// for developer convenience update cpp_wrappers.txt with names of
		// all CPP files that need to be compiled into wrapper.
		file_.writeString("\t\t" ~ klass.name ~ "_wrapper.cpp\n");
		foreach(nestedKlass; klass.nestedKlasses) {
			file_.writeString("\t\t" ~ klass.name ~ "_" ~ nestedKlass.name ~ "_wrapper.cpp\n");
		}
	}

	foreach(enum_; package_.enums) {
		assert(enum_.isEnum);
		auto enum__ = cast(Enum) enum_;
		makeDEnumWrapper(DDirectory,  enum__);
	}	
	
	foreach(childPackage; package_.packages) {
		string namespaceDDirectory = makeNamespaceDirectory(DDirectory, childPackage.name);
		string namespaceCDirectory = makeNamespaceDirectory(CDirectory, childPackage.name);
		// do namespace package
		writePackageWrappers(childPackage, namespaceDDirectory, namespaceCDirectory);
	}
}
	
string makeNamespaceDirectory(string directory, string namespaceName) {
	string namespaceDirectoryPath = buildPath(directory, namespaceName);
	if (! exists(namespaceDirectoryPath)) {
		mkdir(namespaceDirectoryPath);
	}
	return namespaceDirectoryPath;
}

/**
* Copy the WrappedObject.d file to the package directory. Include in the D module
* the imports for non abstract base classes, and the case statements for them
* also.
*/
void copyWrappedObject(string DDirectory, string moduleName, 
													string[] nonAbstractClassNames) {
	auto fileName = buildPath(DDirectory, "WrappedObject.d");
	auto file_ = new std.stream.File(fileName, FileMode.OutNew);
	
	string modifiedWrappObjectSrc = wrappedObjectSrc.replace("MODULENAME", moduleName);
	string imports;
	foreach(className; nonAbstractClassNames) {
		imports ~= "import %s.%s;\n".format(moduleName, className);
	}
	modifiedWrappObjectSrc = modifiedWrappObjectSrc.replace("//IMPORTS", imports);
	
	string caseStatements;
	foreach(className; nonAbstractClassNames) {
		caseStatements ~= 
"			case (\"%s\"):
				wrapper = cast(T) new %s(wrappedObj, CreatedBy.CPP, ownedBy);
				debug { writeln(\"Did not find wrappedObj - creating new %s\"); }
				break;
".format(className, className, className);	
	}
	modifiedWrappObjectSrc = modifiedWrappObjectSrc.replace("//CASESTATEMENTS", caseStatements);
	
	file_.writeString(modifiedWrappObjectSrc);
}
													
void writePackageGlobals(Package package_, string DDirectory) {
	string packageGlobalsCode = package_.getStringPackageGlobals();
	auto fileName = buildPath(DDirectory, "package_globals.d");
	auto file_ = new std.stream.File(fileName, FileMode.OutNew);
	file_.writeString(packageGlobalsCode);
}													

void copyBaseFiles(string DDirectory, string CDirectory, ModulePackage package_,
	 												string[] nonAbstractClassNames) {
	// Copy the base class files and module files to the C and D directory.
	
	string moduleName = package_.moduleName_;
	
	copyWrappedObject(DDirectory, moduleName, nonAbstractClassNames);
	
	// write instance_wrapper.cpp
	auto fileName = buildPath(CDirectory, "instance_tracker.cpp");
	auto file_ = new std.stream.File(fileName, FileMode.OutNew);
	file_.writeString(instanceTrackerCPP);
	
	fileName = buildPath(CDirectory, "instance_tracker.h");
	file_ = new std.stream.File(fileName, FileMode.OutNew);
	file_.writeString(instanceTrackerH);
	
}

