/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_parse_converter;

import std.stdio;

import unit_threaded.all;

import pegged.grammar;

import smidgen.parse_converter;


void testPPChar() {
	string convTest = "	
	
%Name
PPChar
%End
	
%ConvertFromCToDCode
		return \"0\";
%End	
	
%ConvertFromDToCCode
		return format(\"\t\tint %s = 0;\", argument.name);
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
	ParseTree pt = GConverter.Declarations(convTest);
//	writeln(pt);
	checkTrue(pt.successful);
}






