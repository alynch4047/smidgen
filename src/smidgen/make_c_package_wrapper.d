/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.make_c_package_wrapper;

import std.stream: File, FileMode;
import std.stdio: writeln;
import std.path: buildPath;
import std.string: format;

import smidgen.ast.package_: ModulePackage;


void makeCPackageWrapper(string directory, ModulePackage package_) {
	
	string functionSourceCode = package_.getClassNameCCode;
	
	string fileName = buildPath(directory, "package_wrapper.cpp");
	writeln("write package wrapper to " ~ fileName);
	
	auto wrapperFile = new File(fileName, FileMode.OutNew);
	
	wrapperFile.writeString("#include <instance_tracker.h>\n\n");
	
	auto converters = package_.getConverterManager().getConverters();
	if (converters.length > 0) {
		wrapperFile.writeString("// Headers for converters\n");
		foreach(converter; converters) {
			wrapperFile.writeString("%s\n".format(converter.includeInHeader));
		}		
		wrapperFile.writeString("// Converter functions\n");
		foreach(converter; converters) {
			wrapperFile.writeString(converter.CToCTransferInCFunction ~ "\n\n");
			wrapperFile.writeString(converter.CTransferToCInCFunction ~ "\n\n");
		}
	}	
	
	wrapperFile.writeString(functionSourceCode);
	
}

