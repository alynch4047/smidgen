/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.test.test_make_c_wrapper;

import std.string;
import std.stdio;
import std.algorithm;

import pegged.grammar;
import unit_threaded.all;

import smidgen.make_c_wrapper;
import smidgen.parse_sip;
import smidgen.ast.method;

import smidgen.test.test_extras;


static string nestingTest = """

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


void testGetMethodToStringCWithNestedClass() {
	ParseTree pt = Smidgen(nestingTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	Klass B1 = package_.getClassOfName("B1");
	Klass A = package_.getClassOfName("A");
	Method getPoint = A.methods[0];
	
	Klass Point = package_.getClassOfName("Point");
	checkEqual(B1.nestedKlasses.length, 1);
	Klass B1Point = B1.nestedKlasses[0];
	checkEqual(B1Point.nestedKlasses.length, 1);
	Method getMyD4 = B1Point.methods[0];
	
	Klass B1PointPlace = B1Point.nestedKlasses[0];
	Method getMyD10 = B1PointPlace.methods[0];
	string expected = """
extern \"C\" D10* Point_Place_getMyD10_SMIX0(B1::Point::Place* self, B1::Point::Place p9) {

	D10 retValue = self->getMyD10(p9);
	D10* copiedRetValue = new D10(retValue);
	return copiedRetValue;

}
""";
//	writeln(getMyD10.toStringC(B1PointPlace));
//	writeln(expected);
	checkEqualWS(getMyD10.toStringC(B1PointPlace), expected);

}