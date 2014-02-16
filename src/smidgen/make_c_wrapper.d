
/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.make_c_wrapper;

import std.stdio;
import std.path;
import std.string;
import std.stream: Stream, File, FileMode;

import smidgen.cpp_wrapper: getCPPWrapper;

import smidgen.ast.other;
import smidgen.constants;
import smidgen.ast.klass: Klass;


void makeCClassWrapper(string directory, Klass klass) {
	string parentKlassName;
	if (klass.parentKlass) {
		parentKlassName = klass.parentKlass.name ~ "_";
	}
	string fileName = buildPath(directory, format("%s%s_wrapper.cpp", parentKlassName, klass.name));
	
	auto wrapperFile = new std.stream.File(fileName, FileMode.OutNew);
	
	writeHeader(wrapperFile, klass);
	wrapperFile.writeString(getCastPointersFunctions(klass));
	wrapperFile.writeString(getCPPWrapper(klass));
	writeBody(wrapperFile, klass);
	writeFooter(wrapperFile, klass);
	
	foreach(nestedKlass; klass.nestedKlasses) {
		makeCClassWrapper(directory, nestedKlass);
	}
	
}

void writeHeader(Stream wrapperFile, Klass klass) {
	string header = format("\n/*\n* CPP Wrapper for %s\n*/\n\n", klass.name);
	
	header ~= "#include <instance_tracker.h>\n\n";
	
	if (klass.typeHeaderCode)
		header ~= klass.typeHeaderCode.toStringC() ~ "\n"; 
		
	auto converters = klass.getUsedConverters();

	if (converters.length > 0) {
		header ~= "// Headers for converters\n";
		foreach(name, converter; converters) {
			header ~= "%s\n".format(converter.includeInHeader);
		}	
		
		header ~= "\n// Externs for converters\n";
		
		foreach(name, converter; converters) {
			if (converter.CToCTransferInCFunctionSignature.length > 0) {
				header ~= "extern %s;\n".format(converter.CToCTransferInCFunctionSignature);
			}	
			if (converter.CTransferToCInCFunctionSignature.length > 0) {
				header ~= "extern %s;\n".format(converter.CTransferToCInCFunctionSignature);
			}	
		}	
		
		header ~= "// End of header section for converters\n";
	}
	
	
	wrapperFile.writeString(header);
}


string getCastPointersFunctions(Klass klass) {
	return klass.getCastPointersFunctions();
}


void writeFooter(Stream wrapperFile, Klass klass) {
	string footer = format("// End CPP Wrapper for %s\n", klass.name);
	wrapperFile.writeString(footer);
}


void writeBody(Stream wrapperFile, Klass klass) {
	
	if (klass.parentPackage.dottedImportName == VTK_MODULE_NAME && ! klass.abstract_)
		wrapperFile.writeString(klass.toStringConstructorC());
	
	wrapperFile.writeString(klass.toStringMethodsC());
	wrapperFile.writeString(klass.toStringDestructorsC());
}

unittest {
	
	auto vtkRenderer = makeVtkRenderer();
	auto mStream = new MemoryStream();
	mStream.reserve(1000);
	
	writeHeader(mStream, vtkRenderer);
	string data = mStream.toString();
	
	assert(data.indexOf("* CPP Wrapper for vtkRenderer") != -1);
	
}