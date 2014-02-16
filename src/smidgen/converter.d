/**
* The converter module specifies required interfaces for type conversion between C++
* and D.
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.converter;

import smidgen.ast.argument: Argument;

/**
* When an argument is going to be converted before being passed on to the wrapped function,
* the name must be mangled. This is done by appending this string to the argument name.
*/
static string ConvertedTypeArgumentPostfix = "___SMI";


/**
* The Converter interface is specified for converting between C++ and D types.  
*/
interface Converter {
	
	/**
	* Set the precise type name that the converter instance is for
	*/
	void setTypeName(string typeName);
	
	/**
	* Returns: The name of the converter
	*/
	string getName();
	
	/**
	* D code that takes a C++ transfer type (variable named argumentName)
	* and converts it to a more useful D type.
	* This code is called with the return value from a wrapped C function.
	*/
	string CToDInDInline(string typeName, string argumentName);
	
	/**
	* D code that takes a D argument and converts it to the appropriate C++ type.
	* Params:
	*   argument   =	the argument the conversion is for
	*   nameSuffix =	this will be appended to the incoming argument name  
	*/
	string DToCInDInline(Argument argument, string nameSuffix);
	
	/**
	* Returns: The C++ type name of the converted type, e.g. char*
	*/
	string typeNameC();
	
	/**
	* Returns: The D type name of the converted type, e.g. string
	*/
	string typeNameD();	
	
	/**
	* Returns: The C++ type that is used to transfer the data between C++ and D
	*/
	string transferTypeC();	
	
	/**
	* Returns: The name of the function used to convert the C++ return type to a plain return type
	* such as char*, void* or int.
	*/
	string CToCTransferInCFunctionName();
	
	/**
	* Returns: the C++ code that implements the function named CToCTransferInCFunctionName.
	* It should take the original C++ type (typeNameC) and convert it to a plain type
	* that can be returned to D (of type transferTypeC)
	*/
	string CToCTransferInCFunction();
	
	/**
	* Returns: the signature of the function defined by CToCTransferInCFunction
	*/ 
	string CToCTransferInCFunctionSignature();
	
	/**
	* If CToCTransferInCFunctionSignature is empty then use this inline and
	* ignore the function version.
	*/
	string CToCTransferInCInline(string typeName, string argumentName);
	
	/**
	* Returns: The name of the CTransferToCInCFunction function.
	*/
	string CTransferToCInCFunctionName();	
	
	/**
	* Returns: the C++ code that takes the C transfer type that is passed in from D 
	* and convert it to the original C++ type (typeNameC)
	*/
	string CTransferToCInCFunction();	
	
	/**
	* Returns: the signature of the CTransferToCInCFunction function
	*/ 
	string CTransferToCInCFunctionSignature();	
	
	/**
	* Returns: the C++ code that takes the C transfer type that is passed in from D 
	* and convert it to the original C++ type (typeNameC). This is the inline version.
	* If CTransferToCInCFunctionSignature is empty then use this inline and
	* ignore the function version.
	*/
	string CTransferToCInCInline(string typeName, string argumentName);		
	
	/**
	* Returns: Includes etc. that should be placed in the C++ wrapper headers for
	* the converters to work
	*/
	string includeInHeader();
	
	/**
	* For the given default value as found in the sip file,
	* return the string representation, as will appear
	* in the argument default in the .d wrapper, for the same value. e.g. This might take
	* a "0" and return a "null", or take the unquoted string 'def' and return a
	* quoted string '"def"'.  
	*/ 
	string getDefaultValue(string sipDefaultValue);

}	