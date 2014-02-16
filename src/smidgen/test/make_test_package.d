
module make_test_package;

import smidgen.ast.package_: Package, ModulePackage;
import smidgen.converter_manager: ConverterManager;
import smidgen.base_converters: getBaseConverters;


ModulePackage makeTestPackage(ModulePackage package_) {
	ConverterManager converterManager = new ConverterManager();
	package_.parentModulesHolder.converterManager = converterManager;
	foreach(converter; getBaseConverters()) {
		converterManager.addConverter(converter);
	}
	return package_;
}	