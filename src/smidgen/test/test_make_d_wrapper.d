/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_make_d_wrapper;

import std.string;
import std.stdio;
import std.algorithm;

import pegged.grammar;
import unit_threaded.all;

import smidgen.make_d_wrapper;
import smidgen.ast.other;
import smidgen.parse_sip;
import smidgen.ast.klass;
import smidgen.ast.method;
import smidgen.ast.argument;
import smidgen.ast.package_;

import smidgen.test.test_extras;

void testGetImports() {
	
			string sipTest = """

%Module(name=morselB)

class C1:WrappedObject {}

class C2: C1 {}

class C3 {}
""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass C2 = package_.getClassOfName("C2");
	
	
	string imports = getImports(C2);
	checkEqual(strip(imports), strip("""
import smicommon.created_by: CreatedBy;

import morselB.package_globals;
import morselB.WrappedObject;

import morselB.C1;
"""));
	
	Klass C1 = package_.getClassOfName("C1");
	imports = getImports(C1);
	checkEqual(strip(imports), strip("""
import smicommon.created_by: CreatedBy;

import morselB.package_globals;
import morselB.WrappedObject;
"""));
}


static string nestingTest = """

%Module(name=morselB)

class B1 {

	int x;
	int getX(D6 d6);

	class B1Nested {

		D4 getMyD4(D5 a);

		class B1NestedNested {
			D10 getMyD10(D9 d9);
		};

	};

}

%Module(name=morselD) 

class D4 {};

class D5 {};

class D6 {};

class D9 {};

class D10 {};

class D11 {};

""";

void testGetImportsWithNestedClasses() {
	
	ParseTree pt = Smidgen(nestingTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass B1 = package_.getClassOfName("B1");
	checkEqual(B1.nestedKlasses.length, 1);
	Klass B1Nested = B1.nestedKlasses[0];
	checkEqual(B1Nested.nestedKlasses.length, 1);
	Klass B1NestedNested = B1Nested.nestedKlasses[0];
	
	string imports = getImports(B1);
	checkEqual(strip(imports), strip("""
import smicommon.created_by: CreatedBy;

import morselB.package_globals;
import morselB.WrappedObject;

import morselD.D10;
import morselD.D4;
import morselD.D5;
import morselD.D6;
import morselD.D9;
"""));
	
}

void testAddIndent() {
	string test = """X
Y
\tZ
\t\tZ
A""";

	checkEqual(addIndent(test, 1), """\tX
\tY
\t\tZ
\t\t\tZ
\tA""");
}


void testGetNestingDepth() {
	ParseTree pt = Smidgen(nestingTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass B1 = package_.getClassOfName("B1");
	checkEqual(B1.nestedKlasses.length, 1);
	Klass B1Nested = B1.nestedKlasses[0];
	checkEqual(B1Nested.nestedKlasses.length, 1);
	Klass B1NestedNested = B1Nested.nestedKlasses[0];
	
	checkEqual(B1.nestingDepth, 0);
	checkEqual(B1Nested.nestingDepth, 1);
	checkEqual(B1NestedNested.nestingDepth, 2);
}

void testDottedImportName() {
	ParseTree pt = Smidgen(nestingTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass B1 = package_.getClassOfName("B1");
	checkEqual(B1.nestedKlasses.length, 1);
	Klass B1Nested = B1.nestedKlasses[0];
	checkEqual(B1Nested.nestedKlasses.length, 1);
	Klass B1NestedNested = B1Nested.nestedKlasses[0];
	
	checkEqual(B1.dottedImportName, "morselB.B1");
	checkEqual(B1Nested.dottedImportName, "morselB.B1.B1Nested");
	checkEqual(B1NestedNested.dottedImportName, "morselB.B1.B1Nested.B1NestedNested");
}


static string nestingTest2 = """

%Module(name=morselB)

class Point {

};

class A {

	Point getPoint();
};

class B1 {

	int x;
	int getX(D6 d6);

	class Point {

		Point getMyD4(Place a);

		class Place {
			D10 getMyD10(Place p9);
		};

	};

}

%Module(name=morselD) 

class D4 {};

class D5 {};

class D6 {};

class D9 {};

class D10 {};

class D11 {};

""";


void testArgumentToStringD() {
	ParseTree pt = Smidgen(nestingTest2);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass B1 = package_.getClassOfName("B1");
	Klass A = package_.getClassOfName("A");
	Method getPoint = A.methods[0];
	auto retType = getPoint.returnType;
	checkEqual(retType.toStringD, "Point");
	
	Klass Point = package_.getClassOfName("Point");
	checkEqual(B1.nestedKlasses.length, 1);
	Klass B1Point = B1.nestedKlasses[0];
	checkEqual(B1Point.nestedKlasses.length, 1);
	Method getMyD4 = B1Point.methods[0];
	retType = getMyD4.returnType;
	checkEqual(retType.toStringD, "B1.Point");
	
	Klass B1PointPlace = B1Point.nestedKlasses[0];
	Method getMyD10 = B1PointPlace.methods[0];
	auto argp9 = getMyD10.arguments[0];
	checkEqual(argp9.type.toStringD(), "B1.Point.Place");
}


void testGetLocalClassName() {
	ParseTree pt = Smidgen(nestingTest2);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass B1 = package_.getClassOfName("B1");
	Klass A = package_.getClassOfName("A");
	Method getPoint = A.methods[0];
	Method getX = B1.methods[0];
	
	Klass Point = package_.getClassOfName("Point");
	checkEqual(B1.nestedKlasses.length, 1);
	Klass B1Point = B1.nestedKlasses[0];
	checkEqual(B1Point.nestedKlasses.length, 1);
	Method getMyD4 = B1Point.methods[0];
	
	Klass B1PointPlace = B1Point.nestedKlasses[0];
	Method getMyD10 = B1PointPlace.methods[0];
	
	Klass matchingKlass = getPoint.getClassOfName("B1");
	checkTrue(matchingKlass is B1);
	
	matchingKlass = getPoint.getClassOfName("B1::Point");
	checkTrue(matchingKlass is B1Point);
	
	matchingKlass = getPoint.getClassOfName("B1::Point::Place");
	checkTrue(matchingKlass is B1PointPlace);	
	
	matchingKlass = getX.getClassOfName("B1");
	checkTrue(matchingKlass is B1);
	
	matchingKlass = getX.getClassOfName("B1::Point");
	checkTrue(matchingKlass is B1Point);
	
	matchingKlass = getX.getClassOfName("Point");
	checkTrue(matchingKlass is B1Point);	
	
	matchingKlass = getX.getClassOfName("B1::Point::Place");
	checkTrue(matchingKlass is B1PointPlace);		
}