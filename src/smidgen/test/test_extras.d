/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.test.test_extras;

import std.string: replace;

public import make_test_package: makeTestPackage;

import unit_threaded.check;
import pegged.grammar;

import smidgen.parse_sip;
import smidgen.ast.klass: Klass;
import smidgen.ast.package_: ModulePackage;
import smidgen.ast.modules_holder;
import smidgen.base_converters: getBaseConverters;


/**
* Get the first ModulePackage for a Smidgen parse tree.
*/
ModulePackage getFirstModulePackage(ParseTree pt) {
	ModulesHolder modulesHolder = new ModulesHolder(pt);
	auto converterManager = modulesHolder.converterManager;
	foreach(converter; getBaseConverters) {
		converterManager.addConverter(converter);
	}
	return modulesHolder.packages[0];
}


string stripAllWhitespace(string str) {
	string newStr = str.replace("\t", "");
	newStr = newStr.replace("\n", "");
	newStr = newStr.replace("\r", "");
	newStr = newStr.replace(" ", "");
	return newStr;
}

void checkEqualWS(string s1, string s2) {
	checkEqual(stripAllWhitespace(s1), stripAllWhitespace(s2));
}


Klass makeVtkRenderer() {
	
	string sipDef = "

   %Module(name=test)

   class vtkRenderer: vtkObject {
        void SetBackground(double a, double b, double c);
		void AddActor(vtkActor* actor);
        void SetName(char* name);
   }

   class vtkActor {

   }

   class vtkObject {

   }

";

	ParseTree pt = Smidgen(sipDef);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	makeTestPackage(package_);
	
	return package_.getClassOfName("vtkRenderer");
}