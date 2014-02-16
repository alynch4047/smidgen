/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.test.test_loaded_converter;

import std.stdio;

import unit_threaded.all;

import smidgen.load_converter;
import smidgen.ast.argument;


void testPPChar() {
	string convTest ="	

	
%Name
PPChar
%End
	
%CToDInDInline
		return \"0\";
%End	
	
%DToCInDInline
		return \"\t\tint $ARGUMENTNAME = 0;\";
%End
	
%TypeNameC
char**
%End

%TypeNameD 
int
%End
	
%ReturnTypeC
int
%End
	
%ArgumentType
int
%End
	
%ConversionFunctionNameC
convertPPCharToInt
%End
	
%ConversionFunctionC
int convertPPCharToInt(char** toConvert) {
	return 0;
 }
%End
	
%ConversionFunctionCSignature
int convertPPCharToInt(char** toConvert)
%End
	
%ConversionFunctionCArgument
char** convertIntToPPChar(int toConvert) {
	return (char**) 0;
}
%End
	
%ConversionFunctionNameCArgument 
convertIntToPPChar
%End
	
%ConversionFunctionCSignatureArgument
char** convertIntToPPChar(int toConvert)
%End
	
%IncludeInHeader
%End
	";
	auto converter = loadConverter(convTest);
	checkEqual(converter.getName(), "PPChar");
	Argument arg = new Argument(null, "XY", null);
	checkEqual(converter.DToCInDInline(arg, "SUFFIX"), "return \"\t\tint XY = 0;\";");
}






