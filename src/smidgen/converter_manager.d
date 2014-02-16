
/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.converter_manager;

import std.string: format, split;
import std.array: replace;
import std.stdio: writeln;

import smidgen.converter: Converter, ConvertedTypeArgumentPostfix;

import smidgen.ast.argument: Argument, CType;

interface ConverterManagerProvider {
	ConverterManager getConverterManager();
}

/**
* The ConverterManager manages the collection and selection of type Converters.
* It also generates the code that converts arguments and return types between
* C++, the C++ transfer type, and D.
*/
class ConverterManager {
	
	private Converter[] converters;
	
	Converter enumConverter;
	
	void addConverter(Converter converter) {
		converters ~= converter;
	}
	
	/**
	* Return all the known converters
	*/
	Converter[] getConverters() {
		return converters;
	}
	
	/**
	* Get the converter for the given C++ type. If there is no Converter then return null.
	*/
	Converter getConverter(CType type) {
		if (type.isEnum) {
			// this is utter rubbish but compiler problems force it on me
			// (I cant import EnumConverter from base_converters, to instantiate
			// the right converter properly, I get a compile error relation to Argument)	
			enumConverter.setTypeName(type.name.replace("::", "."));
			return enumConverter;
		}
		foreach(converter; converters) {
			if (type.toStringNameAndPointerRef() == converter.typeNameC || 
					type.toStringNameAndPointerRef() == converter.typeNameC ~ "&") {
				return converter;
			}
		}	
		return null;	
	}
	
	/**
	* Return the C++ code that converts the arguments from the C++ transfer type
	* to the C++ type
	*/ 
	string getArgumentsConverterCodeCPP(Argument[] arguments) {
		string converterCode;
		foreach (argument; arguments) {
			if (argument.getConverter(argument.type)) {
				auto converter = argument.getConverter(argument.type);
				string argumentName = argument.name ~ ConvertedTypeArgumentPostfix;
				if (converter.CTransferToCInCFunctionSignature.length == 0) {
					converterCode ~= "%s %s = %s;\n".format(
						converter.typeNameC, argument.name, 
						converter.CTransferToCInCInline(converter.typeNameC, argumentName));
				} else {
					converterCode ~= "%s %s = %s(%s);\n".format(
						converter.typeNameC, argument.name,
						converter.CTransferToCInCFunctionName, argumentName);
				}
			}
		}
		return converterCode;
	}
	
	
	/**
	* Return the C++ code that converts the arguments from the C++ type
	* to the C++ transfer type
	*/ 
	string getArgumentsConverterCodeCPPVirtual(Argument[] arguments) {
		string converterCode;
		foreach (argument; arguments) {
			if (argument.getConverter(argument.type)) {
				auto converter = argument.getConverter(argument.type);
				string argumentName = argument.name ~ ConvertedTypeArgumentPostfix;
				if (converter.CToCTransferInCFunctionSignature.length == 0) {
					converterCode ~= "%s %s = %s;\n".format(
						converter.transferTypeC, argument.name, 
						converter.CToCTransferInCInline(converter.transferTypeC, argumentName));
				} else {
				converterCode ~= "%s %s = %s(%s);\n".format(
					converter.transferTypeC, argument.name,
					converter.CToCTransferInCFunctionName, argumentName);
				}
			}
		}
		return converterCode;
	}	
	
	/**
	* Return the D code that converts the arguments from D type to the C++ transfer type.
	*/ 
	string getArgumentsConverterCodeD(Argument[] arguments) {
		string converterCode;
		foreach (argument; arguments) {
			if (getConverter(argument.type)) {
				Converter converter = getConverter(argument.type);
				converterCode ~= "\t\t%s %s = %s;\n".format(converter.transferTypeC(),
					argument.name,
					converter.DToCInDInline(argument, ConvertedTypeArgumentPostfix));
			}
		}
		return converterCode;
	}
	
	/**
	* Return the D code that converts the arguments from the C++ transfer type to the D type.
	*/ 
	string getArgumentsConverterCodeDVirtualExport(Argument[] arguments) {
		string converterCode;
		foreach (argument; arguments) {
			if (getConverter(argument.type)) {
				Converter converter = getConverter(argument.type);
				string typeNameD = converter.typeNameD();
				if (argument.type.isEnum) {
					// for enums we don't want the fully qualified name
					typeNameD = typeNameD.split(".")[$ - 1];
				}
				converterCode ~= "\t\t%s %s = %s;\n".format(typeNameD,
					argument.name,
					converter.CToDInDInline(argument.type.name, 
						        argument.name ~ ConvertedTypeArgumentPostfix));
			}
		}
		return converterCode;
	}	
	
}


