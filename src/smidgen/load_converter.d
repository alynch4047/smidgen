
/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.load_converter;

import std.string: format;
import std.stdio: writeln;
import std.array: split, replace;

import pegged.grammar;

import smidgen.parse_converter;

import smidgen.converter: Converter;

import smidgen.ast.argument: Argument, CType, ArgType;


string getNodeData(ParseTree pt) {
	return strip(pt.input[pt.begin .. pt.end]);
}


private class LoadedConverter: Converter {
	
	string[string] itemsByName;
	
	this(ParseTree pt) {
		foreach(child; pt.children) {
			auto declaration = child;
			auto nameNode = declaration.children[0];
			string content;
			if (declaration.children.length == 2) {
				auto contentNode = declaration.children[1];
				content = getNodeData(contentNode);
			}
			itemsByName[getNodeData(nameNode)] = content;
		}	
	}
	
	void setTypeName(string typeName) {}
	
	string getName() {
		return itemsByName["Name"];
	}
	
	string CToDInDInline(string typeName, string argumentName) const {
		string code = itemsByName["CToDInDInline"];
		code = code.replace("$ARGUMENTNAME", argumentName);
		code = code.replace("$TYPENAME", typeName);
		return code;
	}
	
	string DToCInDInline(Argument argument, string nameSuffix) const {
		string code = itemsByName["DToCInDInline"];
		code = code.replace("$ARGUMENTNAME", argument.name);
		code = code.replace("$INCOMINGARGUMENTNAME", argument.name ~ nameSuffix);
		return code;
	}
	
	string typeNameC() {
		return itemsByName["TypeNameC"];
	}
	
	string typeNameD() {
		return itemsByName["TypeNameD"];
	}	
	
	string transferTypeC() {
		return itemsByName["TransferTypeC"];
	}
	
	string CToCTransferInCFunctionName() {
		return itemsByName["CToCTransferInCFunctionName"];
	}	
	
	string CToCTransferInCFunction() {
		return itemsByName["CToCTransferInCFunction"];
	}	
	
	string CToCTransferInCFunctionSignature() {
		return itemsByName["CToCTransferInCFunctionSignature"];
	}	
	
	string CToCTransferInCInline(string typeName, string argumentName) {
		return itemsByName["CToCTransferInCInline"];
	}	
	
	string CTransferToCInCFunction() {
		return itemsByName["CTransferToCInCFunction"];
	}
	
	string CTransferToCInCFunctionName() {
		return itemsByName["CTransferToCInCFunctionName"];
	}	
	
	string CTransferToCInCFunctionSignature() {
		return itemsByName["CTransferToCInCFunctionSignature"];
	}		
	
	string CTransferToCInCInline(string typeName, string argumentName) {
		string code = itemsByName["CTransferToCInCInline"];
		code = code.replace("$ARGUMENTNAME", argumentName);
		code = code.replace("$TYPENAME", typeName);
		return code;
	}		
	
	string includeInHeader() {
		return itemsByName["IncludeInHeader"];
	}	
	
	string getDefaultValue(string sipDefaultValue) {
		string code = itemsByName["SipDefaultValue"];
		code = code.replace("$DEFAULTVALUE", sipDefaultValue);
		return code;
	}
}


Converter loadConverter(string converterData) {
	converterData = "\n" ~ converterData;
	ParseTree pt = GConverter(converterData);
	auto converter = new LoadedConverter(pt.children[0]);
	return converter;
}

