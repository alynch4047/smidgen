/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_handle_includes_and_ifs;

import std.string: splitLines;
import std.stdio: writeln;
import std.algorithm;

import pegged.grammar;

import unit_threaded.all;

import smidgen.handle_includes_and_ifs;

static const string sipFileContentsMain1 = """
Line 1
""";

static const string sipFileContentsInc1 = """Inc 1 Line 1
""";

static const string sipFileContentsInc2 = """Inc 2 Line 1
Inc 2 Line 2
""";

static const string sipFileContentsInc3 = """Inc 3 Line 1
%Include inc2.sip 
Inc 3 Line 2
""";

static const string sipFileContentsMain2 = """
Line 1
%Include inc1.sip
""";

static const string sipFileContentsMain3 = """
Line 1
%Include inc1.sip
%Include inc2.sip
""";

static const string sipFileContentsMain4 = """
Line 1
%Include inc1.sip
%Include inc3.sip
""";

static const string configTest = """
%Timeline {Qt_5_0_0 Qt_5_0_1 Qt_5_0_2}

%Platforms {WS_X11 WS_WIN WS_MACX}

%Feature PyQt_Accessibility
%Feature PyQt_SessionManager
%Feature PyQt_SSL
%Feature PyQt_qreal_double
""";

auto getSipFileLines(string sipFileName, string workingDirectory) {
	switch (sipFileName) {
		case "main1.sip":
			return sipFileContentsMain1.splitLines;
		case "main2.sip":
			return sipFileContentsMain2.splitLines;
		case "main3.sip":
			return sipFileContentsMain3.splitLines;
		case "main4.sip":
			return sipFileContentsMain4.splitLines;
		case "inc1.sip":
			return sipFileContentsInc1.splitLines;
		case "inc2.sip":
			return sipFileContentsInc2.splitLines;
		case "inc3.sip":
			return sipFileContentsInc3.splitLines;			
		default:
			throw new Exception("No data found for sip file " ~ sipFileName);													
	}
}


void testSimpleSipFile() {
	checkEqual(strip(handle_incs_and_ifs!getSipFileLines("main1.sip", "")),
		 											strip(sipFileContentsMain1));
}

void testSingleInclude() {
	checkEqual(strip(handle_incs_and_ifs!getSipFileLines("main2.sip", "")),strip( 
"""
Line 1
Inc 1 Line 1
"""));
}

void testDoubleInclude() {
	checkEqual(strip(handle_incs_and_ifs!getSipFileLines("main3.sip", "")),strip( 
"""
Line 1
Inc 1 Line 1
Inc 2 Line 1
Inc 2 Line 2
"""));
}

void testRecursiveInclude() {
	checkEqual(strip(handle_incs_and_ifs!getSipFileLines("main4.sip", "")), strip( 
"""
Line 1
Inc 1 Line 1
Inc 3 Line 1
Inc 2 Line 1
Inc 2 Line 2
Inc 3 Line 2
"""));
}

void testHandleIfsDeclarationCode() {
	string ifTest = "
// C1
%ModuleCode
#include <qnamespace.h>
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
// C1
%ModuleCode
#include <qnamespace.h>
%End"));
}

void testHandleIfs() {
	string ifTest = "
X=1
X=2
%If (Qt_1 - )
X=3
X=4
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=3
X=4"));
}

void testHandleIfsFailingIf() {
	string ifTest = "
X=1
X=2
%If (Qt_1 - Qt_2)
X=3
X=4
%End
X=5
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=5
"));
}

void testHandleEmbeddedIfs() {
	string ifTest = "
X=1
X=2
%If (Qt_1 - )
X=3
%If (Qt_2 - )
X=6
%End
X=4
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=3
X=6
X=4"));
}

void testHandleEmbeddedIfsFailingOuterIf() {
	string ifTest = "
X=1
X=2
%If (Qt_1 - Qt_3)
X=3
%If (Qt_2 - )
X=6
%End
X=4
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
"));
}

void testHandleEmbeddedIfsFailingInnerIf() {
	string ifTest = "
X=1
X=2
%If (Qt_1 -)
X=3
%If (Qt_2 - Qt_3)
X=6
%End
X=4
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=3
X=4
"));
}

void testHandleIfsWithOtherDeclarations() {
	string ifTest = "
// C1
%ModuleCode
#include <qnamespace.h>
%End
%If (Qt_1 -)
X=3
%If (Qt_2 - Qt_3)
X=6
%End
X=4
%End
";
	ParseTree pt = IfHandler.Section(ifTest);
//	pt.writeln;
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
// C1
%ModuleCode
#include <qnamespace.h>
%End
X=3
X=4
"));
}

void testHandleQualifierIf() {
	string ifTest = "
X=1
X=2
%If (Py_Qt3)
X=3
X=4
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
"));
}


void testHandleQualifierIfWithOr() {
	string ifTest = "
X=1
X=2
%If (PyQt3 || XYZ)
X=3
X=4
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
"));
}


void testBigQualifiedIf() {
	string ifTest2 = import("qnamespace_end.sip");
	
	ParseTree pt = IfHandler.IfCode(ifTest2);
//	pt.writeln;	
	checkTrue(pt.successful);
	string handled = handle_ifs(ifTest2);
//	writeln("HANDLED", handled);
	checkEqual(strip(handled), "");
	
}


void testHandleIfsDontLoseDeclWhitespace() {
	string ifTest = "
X=1
%TypeHeaderCodeD
	A
	B
		C
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
%TypeHeaderCodeD
	A
	B
		C
%End
"));
}

void testHandleFeatureIf() {
	string ifTest = "
%Feature PyQt3
X=1
X=2
%If (PyQt2)
X=3
%End
%If (PyQt3)
X=5
X=6
%End
%If (PyQt2 || PyQt3)
X=10
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=5
X=6
X=10
"));
}

void testHandleNegativeFeatureIf() {
	string ifTest = "
%Feature PyQt3
X=1
X=2
%If (!PyQt1)
X=3
%End
%If (! PyQt2)
X=5
X=6
%End
%If (!PyQt3)
X=10
X=11
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=3
X=5
X=6
"));
}

void testHandlePlatformIf() {
	string ifTest = "
%Platform LINUX_64
X=1
X=2
%If (LINUX_64)
X=3
%End
%If (WIN_64)
X=5
X=6
%End
";
	string handled = handle_ifs(ifTest);
	checkEqual(strip(handled), strip(" 
X=1
X=2
X=3
"));
}

