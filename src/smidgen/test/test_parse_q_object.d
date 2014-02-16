/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_parse_q_object;

import std.stdio;
import std.array;

import unit_threaded.all;

import pegged.grammar;

import smidgen.parse_sip;
import smidgen.ast.other;
import smidgen.ast.klass;
import smidgen.ast.package_;

import smidgen.test.test_extras;

auto sipTest = import("qobject.sip");

void testQObject() {
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	Package package_ = getFirstModulePackage(pt);
	auto klasses = package_.klasses;
	checkEqual(klasses.length, 1);
	auto klassNames = array(map!(a => a.name)(klasses));
	checkEqual(klassNames, ["QObject"]);
}