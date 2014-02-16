/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.test.test_typedef;

import std.stdio;

import unit_threaded.all;

import smidgen.ast.typedef_: Typedef, tidyWhiteSpace;


void testTidyWhiteSpace() {

	string myTypeName = "  abc   \t\td    e  \t ";
	checkEqual(tidyWhiteSpace(myTypeName), "abc d e");
}

void testGetDeTypeDefedNameOneIndirection() {
	
	Typedef[] typedefs;
	typedefs ~= Typedef("int", "myInt");
	
	checkEqual(typedefs[0].baseTypeName, "int");
	checkEqual(typedefs[0].aliasTypeName, "myInt");
	
	string newName = Typedef.deTypedefedName(typedefs, "myInt");
	checkEqual(newName, "int");
}


void testGetDeTypeDefedNameThreeIndirections() {
	
	Typedef[] typedefs;
	typedefs ~= Typedef("intA", "  intB\t");
	typedefs ~= Typedef("\tintB  ", "myInt");
	typedefs ~= Typedef("int", "intA");
	
	string newName = Typedef.deTypedefedName(typedefs, "myInt");
	checkEqual(newName, "int");
}