/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_parse_q_application;

import std.stdio;
import std.array;

import unit_threaded.all;

import pegged.grammar;

import smidgen.parse_sip;
import smidgen.ast.other;
import smidgen.ast.klass;
import smidgen.ast.package_;
import smidgen.test.test_extras: getFirstModulePackage;

auto sipTest = import("qapplication.sip"); 

void testQApplication() {
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	auto klasses = package_.klasses;
	checkEqual(klasses.length, 1);
	auto klassNames = array(map!(a => a.name)(klasses));
	checkEqual(klassNames, ["QApplication"]);
}

void testQApplicationStart() {
	string start = "
QApplication *qApp {
%AccessCode
    // Qt implements this has a #define to a function call so we have to handle
    // it like this.
    return qApp;
%End
};";
//typedef QList<QWidget *> QWidgetList;";

	ParseTree pt = Smidgen.Member(start);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testQApplicationStart2() {
	string start = "
typedef QList<QWidget *> QWidgetList;
";
//

	ParseTree pt = Smidgen.TypeDef(start);
//	writeln(pt);
	checkTrue(pt.successful);
	
}


string classTest = import("qapplication_class.sip"); 
void testQApplicationClass() {

	ParseTree pt = Smidgen.Class(classTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

string end = "%ModuleHeaderCode
// Imports from QtCore.
typedef char **(*pyqt5_from_argv_list_t)(PyObject *, int &);
extern pyqt5_from_argv_list_t pyqt5_from_argv_list;

typedef sipErrorState (*pyqt5_get_connection_parts_t)(PyObject *, QObject *, const char *, bool, QObject **, QByteArray &);
extern pyqt5_get_connection_parts_t pyqt5_get_connection_parts;

typedef sipErrorState (*pyqt5_get_pyqtsignal_parts_t)(PyObject *, QObject **, QByteArray &);
extern pyqt5_get_pyqtsignal_parts_t pyqt5_get_pyqtsignal_parts;

typedef void (*pyqt5_update_argv_list_t)(PyObject *, int, char **);
extern pyqt5_update_argv_list_t pyqt5_update_argv_list;

// This is needed for Qt v5.0.0.
#if defined(B0)
#undef B0
#endif
%End

%ModuleCode
// Imports from QtCore.
pyqt5_from_argv_list_t pyqt5_from_argv_list;
pyqt5_get_connection_parts_t pyqt5_get_connection_parts;
pyqt5_get_pyqtsignal_parts_t pyqt5_get_pyqtsignal_parts;
pyqt5_update_argv_list_t pyqt5_update_argv_list;
%End

%PostInitialisationCode
// Imports from QtCore.
pyqt5_from_argv_list = (pyqt5_from_argv_list_t)sipImportSymbol(\"pyqt5_from_argv_list\");
pyqt5_get_connection_parts = (pyqt5_get_connection_parts_t)sipImportSymbol(\"pyqt5_get_connection_parts\");
pyqt5_get_pyqtsignal_parts = (pyqt5_get_pyqtsignal_parts_t)sipImportSymbol(\"pyqt5_get_pyqtsignal_parts\");
pyqt5_update_argv_list = (pyqt5_update_argv_list_t)sipImportSymbol(\"pyqt5_update_argv_list\");
%End";

void testQApplicationEnd() {

	ParseTree pt = Smidgen.Package(end);
//	writeln(pt);
	checkTrue(pt.successful);
	
}
