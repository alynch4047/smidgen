
/**
* Make the D wrapper classes for C++ classes and enums.
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
*/
module smidgen.make_d_wrapper;

import std.stdio: writeln;
import std.path: buildPath;
import std.string: format, splitLines;
import std.stream: File, FileMode;
import std.array: join, replicate;
import std.algorithm: uniq, sort, map;

import smidgen.ast.other;
import smidgen.constants;
import smidgen.ast.klass: Klass, INTERFACE_IMPL_SUFFIX;
import smidgen.ast.enum_: Enum;
import smidgen.ast.package_: Package;

/**
* Write the D wrapper file for an enum
*/
void makeDEnumWrapper(string directory, Enum enum_) {
	
	string fileName = buildPath(directory, format("%s.d", enum_.name));
	writeln("Write d enum wrapper to " ~ fileName);
	auto wrapperFile = new std.stream.File(fileName, FileMode.OutNew);
	
	wrapperFile.writeString(getEnumHeader(enum_));
	wrapperFile.writeString(getEnumBody(enum_));
}

/**
* Get the header of the D wrapper file for an enum
*/
string getEnumHeader(Enum enum_) {
	string header = format("\n/*\n* D Wrapper for %s\n*/\n\n", enum_.name);
	header ~= "module %s;\n\n".format(enum_.dottedImportName());
	return header;
}

/**
* Get the body of the D wrapper file for an enum
*/
string getEnumBody(Enum enum_) {
	string enumBody = "enum " ~ enum_.name ~ "{\n";
	foreach(member; enum_.memberNames) {
		enumBody ~= member ~ ",\n";
	}
	enumBody = enumBody[0 .. $ - 2];
	enumBody ~= "\n}\n";
	return enumBody;
}


void makeDClassWrapper(string directory, Klass klass) {
	
	string fileName = buildPath(directory, format("%s.d", klass.getWrappedClassName));
	writeln("Write d class wrapper to " ~ fileName);
	
	auto wrapperFile = new std.stream.File(fileName, FileMode.OutNew);
	
	wrapperFile.writeString(getHeader(klass));
	wrapperFile.writeString(getImports(klass));
	
	if (klass.wrapAsInterface) {
		// include import of interface itself in Impl definition
		string importInterface = "import %s;\n\n".format(klass.dottedImportName);		
		wrapperFile.writeString(importInterface);
	}	
	
	if (klass.typeHeaderCodeD) {
		wrapperFile.writeString("// Include %TypeHeaderCodeD\n");
		wrapperFile.writeString(klass.typeHeaderCodeD);
		wrapperFile.writeString("// End %TypeHeaderCodeD\n\n");
	}
	
	wrapperFile.writeString(getBody(klass));
	wrapperFile.writeString(getDVirtualExports(klass));
	wrapperFile.writeString(getExports(klass));
	wrapperFile.writeString(getFooter(klass));
}


void makeDInterfaceWrapper(string directory, Klass klass) {
	
	string fileName = buildPath(directory, format("%s.d", klass.name));
	writeln("Write d class wrapper to " ~ fileName);
	
	auto wrapperFile = new std.stream.File(fileName, FileMode.OutNew);
	
	wrapperFile.writeString(getHeader(klass, true));
	wrapperFile.writeString(getImports(klass));
	
	wrapperFile.writeString(getInterfaceBody(klass));
	wrapperFile.writeString(getFooter(klass, true));
}


string getHeader(Klass klass, bool makeInterface=false) {
	string klassName = klass.name;
	if (! makeInterface) {
		klassName = klass.getWrappedClassName;
	}
	string header = format("\n/*\n* D Wrapper for %s\n*/\n\n", klassName);
	
	header ~= "module %s.%s;\n\n".format(klass.parentPackage.dottedImportName, klassName);
	
	return header;
}

string getImports(Klass klass) {
	string moduleName = klass.parentPackage.dottedImportName;
	string header = format("import smicommon.created_by: CreatedBy;\n\nimport %s.package_globals;\n",
		 						moduleName);
	header ~= "import %s.WrappedObject;\n\n".format(moduleName);
	
	auto referencedClasses = klass.getReferencedClasses();
	
	// we only want top level classes, no need for separate import for nested classes
	Klass[] topLevelKlasses;
	foreach(referencedClass; referencedClasses) {
		topLevelKlasses ~= referencedClass.topLevelKlass;
	}
	
	foreach(referencedClass; uniq!"a.name == b.name"(sort!"a.name < b.name"(topLevelKlasses))) {
		string referencedClassName = referencedClass.name;
		if (referencedClassName != "WrappedObject" && referencedClassName != klass.name) {
			string dottedClassName = referencedClass.dottedImportName;		
			header ~= "import %s;\n".format(dottedClassName);
			if (klass.getClassOfName(referencedClassName).wrapAsInterface) {
				header ~= "import %s;\n".format(dottedClassName ~ INTERFACE_IMPL_SUFFIX);
			}
		} 
	}
	header ~= "\n";
	return header;
}

string getFooter(Klass klass, bool makeInterface=false) {
	string klassName = klass.name;
	if (! makeInterface) {
		klassName = klass.getWrappedClassName;
	}
	string footer = format("// End D Wrapper for %s\n", klassName);
	return footer;
}


/**
* Create the extern(C) functions that allow virtual method calls for the wrapped
* class and its decendents to be called from C. e.g.
*
*   extern (C) int SMID_Rect_multBy2_SMIX6(void* wrappedObject, int arg0) {
*        Rect wrappedRect = getWrappedObject!Rect(wrappedObject);
*        int retVal wrappedRect.multBy2(arg0);
*        return retVal;
*   }     
*/ 
string getDVirtualExports(Klass klass) {
	string code =  klass.toStringDVirtualExports();
	foreach(nestedKlass; klass.nestedKlasses) {
		code ~= "\n" ~ nestedKlass.getDVirtualExports();
	}
	return code;
}


string getExports(Klass klass) {
	
	string exports;
	if (klass.parentPackage.dottedImportName == VTK_MODULE_NAME) {
		string exportSignature = klass.toStringExportConstructorD();
		exports ~= exportSignature;
	}	
	exports ~= klass.toStringMethodsDExport();
	exports ~= klass.toStringDestructorsDExport();
	exports ~= klass.toStringCastPointers();
	
	foreach(nestedKlass; klass.nestedKlasses) {
		exports ~= "\n" ~ nestedKlass.getExports();
	}
	
	return exports;
}

/**
* Get the class { ... } declaration for the class
*/
string getBody(Klass klass) {
	
	string body_;
	
	string interfaceNames;
	if (klass.interfaceNames.length > 0) {
		interfaceNames = ", " ~ klass.interfaceNames.join(", ");
	}
	if (klass.wrapAsInterface) {
		interfaceNames = ", " ~ klass.name;
	}
	
	string staticClassSpecifier;
	if (klass.isNested) {
		staticClassSpecifier = "static ";
	} else {
		staticClassSpecifier = "";
	}
	
	string baseClassHeader = format("%sclass %s: %s%s {\n", 
		staticClassSpecifier, klass.getWrappedClassName,
		 										klass.baseClassName, interfaceNames);
	body_ ~= baseClassHeader;
	
	if (klass.parentPackage.dottedImportName == VTK_MODULE_NAME && ! klass.abstract_) {
		string constructorD = klass.toStringConstructorD();
		body_ ~= "\n" ~ constructorD ~ "\n";
	} 
	
	string constructorDWithWrappedObj = klass.toStringConstructorDWithWrappedObj();
	
	body_ ~= "\n" ~ constructorDWithWrappedObj ~ "\n";
	
	body_ ~= klass.makeGetCastPointerForInterface();
	
	if (klass.typeBodyCodeD) {
		body_ ~= klass.typeBodyCodeD ~ "\n";
	}
	
	body_ ~= klass.toStringMethodsD();
	
	body_ ~= klass.toStringDestructorsD();
	
	foreach(innerKlass; klass.nestedKlasses) {
		string innerBody = getBody(innerKlass);
		innerBody = addIndent(innerBody, innerKlass.nestingDepth);
		body_ ~= "\n" ~ innerBody;
	}
	
	string baseClassFooter = "}\n\n";
	body_ ~= baseClassFooter;
	
	return body_;
}

/**
* Indent the string code by numTabs tabs
*/ 
string addIndent(string code, int numTabs) {
	string[] lines = code.splitLines;
	return map!(a => "\t".replicate(numTabs) ~ a)(lines).join("\n");
}


string getInterfaceBody(Klass klass) {
	
	string body_ = format("interface %s: HasWrappedObject {\n", klass.name);
	
	body_ ~= klass.toStringMethodSignaturesD();
	
	string baseClassFooter = "}\n\n";
	body_ ~= baseClassFooter;
	
	return body_;
}



