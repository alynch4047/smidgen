/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.tst;

import std.stdio;

import unit_threaded.runner;


int main(string[] args)
{
	return runTests!(
		"smidgen.test.test_parse_sip",
		"smidgen.test.test_cpp_wrapper",
		"smidgen.test.test_ast_classes",
		"smidgen.test.test_handle_includes_and_ifs",
		"smidgen.test.test_klass",
		"smidgen.test.test_make_c_wrapper",
		"smidgen.test.test_make_d_wrapper",
		"smidgen.test.test_parse_q_object",
		"smidgen.test.test_parse_q_global",		
		"smidgen.test.test_parse_q_namespace",
		"smidgen.test.test_parse_q_application", 
		"smidgen.test.test_parse_converter",
		"smidgen.test.test_loaded_converter",
		"smidgen.test.test_typedef",
		"smidgen.test.test_method",
		"smidgen.test.test_argument",
//		"smidgen.test.test_signals_slots"
		)(args);
}