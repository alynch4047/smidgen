/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.test.test_argument;

import std.stdio;

import unit_threaded.all;
import pegged.grammar;

import smidgen.parse_sip;
import smidgen.test.test_extras;

import smidgen.ast.argument: CType;


void testExcludeFromWrappingTypedefedArgumentPrimitive() {
	string sipTest = """

%Module(name=morselA)

typedef int myGreatInt;

class C1 {
	void doIt(myGreatInt);
}

""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	auto method = klass.methods[0];
	auto argument = method.arguments[0];
	checkTrue(argument.type.isPrimitiveType);
}


void testIsWrappedTypeForTypedefedPrimitive() {
	string sipTest = """

%Module(name=morselA)

typedef int myGreatInt;

class C1 {
public:
	myGreatInt doIt(myGreatInt);
}

""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	auto method = klass.methods[0];
	auto argument = method.arguments[0];
	checkFalse(argument.type.isWrappedType);
}


