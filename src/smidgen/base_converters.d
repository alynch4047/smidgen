/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.base_converters;

import std.string;
import std.array: replace;

import smidgen.converter: Converter;
import smidgen.ast.argument: Argument, CType, ArgType;


/*
* This converter converts char* to D string and back again
*/
class PCharConverter: Converter {
	
	void setTypeName(string typeName) {}
	
	string getName() {
		return "PCharConverter";
	}
	
	string CToDInDInline(string typeName, string argumentName) {
		return "CToDString(" ~ argumentName~ ")";
	}
	
	string DToCInDInline(Argument argument, string nameSuffix) {
		return format("cast(char*) toStringz(%s)", argument.name ~ nameSuffix);
	}
	
	string typeNameC() {
		return "char*";
	}
	
	string typeNameD() {
		return "string";
	}	
	
	string transferTypeC() {
		return "char*";
	}
	
	string CToCTransferInCFunctionName() {
		return "convertPCharToPChar";
	}
	
	string CToCTransferInCFunction() {
		return 
		"char* convertPCharToPChar(char* toConvert) {
			return toConvert;
   		 }";
	}
	
	string CToCTransferInCFunctionSignature() {
		return "char* convertPCharToPChar(char* toConvert)";
	}	
	
	string CToCTransferInCInline(string typeName, string argumentName) {
		return "";
	}	
	
	string CTransferToCInCFunction() {
		return "char* convertPCharToPCharArgument(char* toConvert) {
			return toConvert;
   		 }";
	}
	
	string CTransferToCInCFunctionName() {
		return "convertPCharToPCharArgument";
	}	
	
	string CTransferToCInCFunctionSignature() {
		return "char* convertPCharToPCharArgument(char* toConvert)";
	}
	
	string CTransferToCInCInline(string typeName, string argumentName) {
		return "";
	}		
	
	string includeInHeader() {
		return "using namespace std;";
	}
	
	string getDefaultValue(string sipDefaultValue) {
		return '"' ~ sipDefaultValue ~ '"';
	}
	
}


/*
* This converter converts a C++ string to D string and back again
*/
class StringConverter: Converter {
	
	void setTypeName(string typeName) {}
	
	string getName() {
		return "StringConverter";
	}
	
	string CToDInDInline(string typeName, string argumentName) {
		return "CToDString(" ~ argumentName~ ")";
	}
	
	string DToCInDInline(Argument argument, string nameSuffix) {
		return format("cast(char*) toStringz(%s)", argument.name ~ nameSuffix);
	}
	
	string typeNameC() {
		return "string";
	}
	
	string typeNameD() {
		return "string";
	}	
	
	string transferTypeC() {
		return "char*";
	}
	
	string CToCTransferInCFunctionName() {
		return "convertCStringToPChar";
	}	
	
	string CToCTransferInCFunction() {
		return 
		"char* convertCStringToPChar(string toConvert) {
			return (char*) toConvert.c_str();
   		 }";
	}	
	
	string CToCTransferInCFunctionSignature() {
		return "char* convertCStringToPChar(string toConvert)";
	}		
	
	string CToCTransferInCInline(string typeName, string argumentName) {
		return "";
	}
	
	string CTransferToCInCFunction() {
		return 
		"string convertPCharToCString(char* toConvert) {
			return *(new string(toConvert));
		}";
	}
	
	string CTransferToCInCFunctionName() {
		return "convertPCharToCString";
	}	
	
	string CTransferToCInCFunctionSignature() {
		return "string convertPCharToCString(char* toConvert)";
	}		
	
	string CTransferToCInCInline(string typeName, string argumentName) {
		return "";
	}	
	
	string includeInHeader() {
		return "#include <string>";
	}	
	
	string getDefaultValue(string sipDefaultValue) {
		return '"' ~ sipDefaultValue ~ '"';
	}	
}


/**
* This converter converts a C++ int to D enum and back again
*/
class EnumConverter: Converter {
	
	/// The enum type in D format e.g. E.GlobalColor
	string enumName;
	
	void setTypeName(string typeName) {enumName = typeName; }
	
	string getName() {
		return "EnumConverter";
	}
	
	string CToDInDInline(string typeName, string argumentName) {
		// we dont want the fully qualified enum name because the import will be
		// e.g. import morselcore.E.GlobalColor;
		// so we just want the 'GlobalColor' element
		string type = enumName.split(".")[$ - 1]; 
		return "cast(" ~ type ~") " ~ argumentName;
	}
	
	string DToCInDInline(Argument argument, string nameSuffix) {
		return "cast(int) " ~ argument.name ~ nameSuffix;
	}
	
	string typeNameC() {
		return enumName.replace(".", "::");
	}
	
	string typeNameD() {
		return enumName;
	}	
	
	string transferTypeC() {
		return "int";
	}
	
	string CToCTransferInCFunctionName() {
		return "";
	}	
	
	string CToCTransferInCFunction() {
		return "";
	}	
	
	string CToCTransferInCFunctionSignature() {
		return "";
	}		
	
	string CToCTransferInCInline(string typeName, string argumentName) {
		return "(%s) %s".format(typeName, argumentName);
	}	
	
	string CTransferToCInCFunction() {
		return "";
	}
	
	string CTransferToCInCFunctionName() {
		return "";
	}	
	
	string CTransferToCInCFunctionSignature() {
		return "";
	}		
	
	string CTransferToCInCInline(string typeName, string argumentName) {
		return "(%s) %s".format(typeName, argumentName);
	}
	
	string includeInHeader() {
		return "";
	}	
	
	string getDefaultValue(string sipDefaultValue) {
		return "cast(%s) %s".format(enumName, sipDefaultValue);
	}
}
	
Converter getBaseConverter(CType ctype) {
	if (ctype.name == "char" && ctype.argType == ArgType.pointer)
	 return new PCharConverter();
	if (ctype.name == "string") return new StringConverter();
	return null;
}


Converter[] getBaseConverters() {
	Converter c1 = new StringConverter();
	Converter c2 = new PCharConverter();
	// EnumConverter is directly loaded by ConverterManager
	Converter[] converters = [c1, c2];
	return converters;
}



