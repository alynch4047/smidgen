/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_klass;

import std.string;
import std.stdio;
import std.algorithm;

import unit_threaded.all;
import pegged.grammar;

import smidgen.test.test_extras;

import smidgen.ast.other;
import smidgen.parse_sip;
import smidgen.ast.klass;
import smidgen.ast.method;
import smidgen.ast.argument;
import smidgen.ast.package_;


void testGetClassName() {
	
	string sipTestData = """

	%Module(name=test)

    class C1: CBase {}

    class C2 {}


""";

	ParseTree pt = Smidgen(sipTestData);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);

 	Klass klass = package_.getClassOfName("C1");
 	checkNotNull(klass);
 	checkEqual(klass.name, "C1"); 
 	klass = package_.getClassOfName("C2");
 	checkNotNull(klass);
 	checkEqual(klass.name, "C2"); 
 	klass = package_.getClassOfName("C3");
 	checkNull(klass, "C1"); 
}