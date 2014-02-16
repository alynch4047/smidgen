
module smidgen.test.atst;

import std.stdio;

import unit_threaded.runner;


int main(string[] args)
{
//	return runTests!("smidgen.test.test_parse_q_namespace")(args);
//	return runTests!("smidgen.test.test_parse_q_application")(args);
//	return runTests!("smidgen.test.test_parse_converter")(args);
//	return runTests!("smidgen.test.test_parse_sip")(args);
//	return runTests!("smidgen.test.test_make_c_wrapper")(args);
//	return runTests!("smidgen.test.test_make_d_wrapper")(args);
//	return runTests!("smidgen.test.test_ast_classes")(args);
//	return runTests!("smidgen.test.test_typedef")(args);
//	return runTests!("smidgen.test.test_method")(args);
//	return runTests!("smidgen.test.test_argument")(args);
//	return runTests!("smidgen.test.test_parse_q_global")(args);	
//	return runTests!("smidgen.test.test_cpp_wrapper")(args);
//	return runTests!("smidgen.test.test_loaded_converter")(args);	
	return runTests!("smidgen.test.test_handle_includes_and_ifs")(args);
//	return runTests!("smidgen.test.test_signals_slots")(args);
}