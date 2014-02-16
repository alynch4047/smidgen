/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.ast.method;

import std.string: strip, format;
import std.algorithm: canFind, filter;
import std.array: join, replace, replicate, split;
import std.stdio: writeln;

import pegged.grammar;

public import smidgen.converter: Converter, ConvertedTypeArgumentPostfix;
public import smidgen.converter_manager: ConverterManager, ConverterManagerProvider;
import smidgen.cpp_wrapper: factoryFunctionPrefix, fromDBase;

public import smidgen.ast.klass: Klass, INTERFACE_IMPL_SUFFIX;
public import smidgen.ast.argument: Argument, CType, Annotation, baseTypeNames, ArgType;
import smidgen.ast.package_: Package;


enum Visibility {protected_, private_, public_, public_slots_, signals_};

static string RET_VALUE_UNCONVERTED = "retValUnconverted";
static string SMID =  "SMID_";
static string TRANSFERBACK = "TransferBack";
static string TRANSFER = "Transfer";
static string TRANSFERTHIS = "TransferThis";
static string DNAME = "DName";


/**
* Remove all leading and trailing whitespace from all lines and then indent
* all lines by the given number of tabs. Also remove all blank lines.
*/
string indent(string code, int numTabs) {
	string result;
	code = strip(code);
	foreach(line; code.split("\n")) {
		if (line.strip.length == 0) {
			// remove empty lines
			continue;
		}
		result ~= "\t".replicate(numTabs) ~ line.strip ~ "\n";
	}
	return result;
}


/**
* The Method interface represents a wrapped method.
*
* It contains all the metadata about the method, and can output the wrapped C function
* and D method code.
*
* See_Also: smidgen.ast.klass
*/
interface Method: ConverterManagerProvider {
	bool virtual();
	bool abstract_();
	bool static_();
	bool constructor();
	bool destructor();
	bool hasEllipsis();
	bool const_();
	bool transferBack();
	
	Klass klass();
	Argument[] arguments();
	Visibility visibility();
	string name();	
	string DName();	
	string deTypedefedName(string name);
	CType returnType();
	
	bool excludeFromWrapping(out string reason);
	bool overrides(Method method);
	bool isOverridingBaseMethod();
	@property Klass getClassOfName(string name);
	string methodNameC(Klass wrapForKlass);
	/// methodCodeD code will replace the CPP code that calls the actual CPP method.
	string methodCodeD();	
	void setMethodCodeD(string code);
	string argumentTypesC();
	Converter getConverter(CType type);
	string virtualFunctionNameD(Klass wrapForKlass);
	string toString();
	string toStringC(Klass wrapForKlass);
	string toStringDVirtualExport(Klass wrapForKlass);
	string toStringDSignature();
	string toStringD(Klass wrapForKlass);
	string toStringDExport(Klass wrapForKlass);
}

/**
* The MethodImpl class is the main implementation of Method
*/
class MethodImpl: Method {
	
	/**
	* Either package_or klass should be set but not both,
	* package indicates it is a function
	*/
	private Klass _klass;
	private Package package_;
	
	/// index is used to distinguish methods of the same name but differing arguments
	private int index;
	
	private bool _virtual = false;
	private bool _abstract_ = false;
	private bool _static_ = false;
	private bool _constructor = false;
	private bool _destructor = false;
	private bool _hasEllipsis = false;
	private bool _const_ = false;
	
	private Annotation[] annotations;
	private Visibility _visibility;
	private string _name;
	private string _annotatedDName;
	private string _methodCodeD;
	private Argument[] _arguments;
	private CType _returnType;	
	
	@property bool virtual() {return _virtual;}
	@property bool abstract_() {return _abstract_;}
	@property bool static_() {return _static_;}
	@property bool constructor() {return _constructor;}
	@property bool destructor() {return _destructor;}
	@property bool hasEllipsis() {return _hasEllipsis;}
	@property bool const_() {return _const_;}
	@property CType returnType() {return _returnType;}
	@property Klass klass() {return _klass;}
	@property Argument[] arguments() {return _arguments;}
	@property Visibility visibility() {return _visibility;}
	@property string name() {return _name;}
	string methodCodeD() {return _methodCodeD;}
	void setMethodCodeD(string code) {_methodCodeD = code;}
	@property bool transferBack() {
		return canFind(annotations, new Annotation(TRANSFERBACK));
	}
	
	this(Klass klass, Visibility visibility, string name, CType returnType) {
		this._klass = klass;
		this._visibility = visibility;
		this._name = name;
		
		this._returnType = returnType;
	}
	
	this(int index, ParseTree tree, Package package_) {
		this.package_ = package_;
		this(index, tree);
	}		
	
	this(int index, ParseTree tree, Klass klass, Visibility visibility) {
		this._klass = klass;
		this._visibility = visibility;
		this(index, tree);
	}	
	
	this(int index, ParseTree tree)
		in {
			assert(klass !is null || package_ !is null);
		}
		body {
		this.index = index;

		
		if (tree.name == "Smidgen.ConstructorSignature") {
			_constructor = true;
		}
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.ReturnType"):
					_returnType = new CType(child, this);
					break;
				case("Smidgen.MethodName"):
					_name = strip(child.input[child.begin .. child.end]);
					break;
				case("Smidgen.Parameters"):
					foreach(int i, parameter; child.children) {
						auto argument = new Argument(parameter, this);
						if (! argument.isEllipsis) {
							addArgument(i, argument);
						} else {
							_hasEllipsis = true;
						}
					}
					break;
				case("Smidgen.Virtual"):
					_virtual = true;
					break;
				case("Smidgen.MethodConst"):
					_const_ = true;
					break;					
				case("Smidgen.Static"):
					_static_ = true;
					break;					
				case("Smidgen.Abstract"):
					_abstract_ = true;	
					break;	
				case("Smidgen.CPPSignature"):
					break;						
				case("Smidgen.Annotation"):
					auto annotationContent = child.children[0];
					auto annotation = new Annotation(annotationContent);
					addAnnotation(annotation);
					break;					
				default:
				    writeln("Method found " ~ child.name);	
			}
		}
	}		
		
	void addAnnotation(Annotation annotation) {
		annotations ~= annotation;
		if (annotation.name == DNAME) {
			_annotatedDName = annotation.value;
		}
	}	
		
	ConverterManager getConverterManager() {
		if (package_) {
			return package_.getConverterManager();
		} else {
			return klass.getConverterManager();
		}	
	}
	
	void addArgument(int i, Argument arg) {
		if (arg.name.length == 0) {
			arg.name = format("arg%s", i);
		}
		_arguments ~= arg;
	}
	
	/**
	* Return the argument names separated by commas 
	*/
	string getArgumentNames() {
		string[] argumentNames;
		foreach (argument; arguments) {
			argumentNames ~= argument.name;
		}
		return argumentNames.join(", ");
	}
	
	/**
	* Get the arguments for calling the wrapped C function from D
	*/
	string getArgumentNamesD() {
		string[] argumentNames;
		foreach (argument; arguments) {
			if (argument.type.isWrappedType() && ! getConverter(argument.type)) {
				argumentNames ~= argument.name ~ "_wrappedObj";
			}	
			else {
				argumentNames ~= argument.name;
			}	
		}
		return argumentNames.join(", ");
	}	
	
	Converter getConverter(CType type) {
		assert(getConverterManager);
		return getConverterManager.getConverter(type);
	}
	
	/**
	* Return the underlying name after stripping away all the typedefs. E.g. if
	*  typedef X XP;
	*  typedef XP Y;
	* then deTypedefedName("Y") should return "X"; 
	*/
	string deTypedefedName(string name) {
		return klass.deTypedefedName(name);
	}
	
	/**
	* Check if a method should be excluded from the wrapping
	*/ 
	bool excludeFromWrapping(out string reason) {
		if (visibility == Visibility.private_
			|| visibility == Visibility.signals_
			) {
				reason = "Method is " ~ to!string(visibility);
				return true;
		}
		foreach(argument; arguments) {
			if (argument.array.length > 0) {
				reason = "Contains array argument";
				return true;
			}
			if (! getConverter(argument.type) &&
					getClassOfName(argument.type.name) is null && 
					! argument.type.isPrimitiveType) {
				reason = format("Contains argument of unwrapped/unconvertible type %s",
					 		argument.type.name);
				return true;
			} 
		}
		if (hasEllipsis) {
			reason = "Contains an argument which is an ellipsis";
			return true;
		}
		if (! constructor && 
				 ! getConverter(returnType) && 
			     getClassOfName(returnType.name) is null && 
			     ! returnType.isPrimitiveType) {
			reason = format("Contains returnType of unwrapped/unconvertible type %s",
					 		returnType.name);
			return true;
		} 
		return false;
	}
	
	bool isDefaultConstructor() {
		return (constructor && arguments.length == 0);
	}
	
	/**
	* Get the D name for a method. This should return the replacement D name if
	* it exists (function annotation /DName=myDName/) 
	* else call makeSafeName and return the safe name.  
	*/ 
	@property string DName() {
		if (_annotatedDName) {
			return _annotatedDName;
		} else {
			return makeSafeName();
		}
	}
	
	/**
	* Make the method name safe to use as a D name, largely for mangling
	* C++ operator methods.
	*/
	string makeSafeName() {
		string safeName = name.replace("==", "equals");
		safeName = safeName.replace("=", "equals");
		safeName = safeName.replace("+", "plus");
		safeName = safeName.replace("-", "minus");
		safeName = safeName.replace(">", "rarrow");
		safeName = safeName.replace("<", "larrow");
		safeName = safeName.replace("|", "pipe");
		safeName = safeName.replace("/", "div");
		safeName = safeName.replace("*", "times");
		safeName = safeName.replace("!", "not");
		
		if (safeName == "destroy") {
			safeName = "destroy_";
		}
		
		return safeName;
	}
	
	/**
	* Construct the extern C method name. To avoid duplicate names with mixin classes
	* (e.g. Calculator) we need to disambiguate between when teh method is in 
	* CalculatorImpl and when it is mixed into e.g. Rect
	*/
	string methodNameC(Klass wrapForKlass) {
		
		string nestedClassParentName;
		if (wrapForKlass.parentKlass) {
			nestedClassParentName = wrapForKlass.parentKlass.name ~ "_";
		} 
		return format("%s%s_%s_SMIX%s", nestedClassParentName, wrapForKlass.name, makeSafeName, index);
	}
	
	/**
	* Construct the function name for calling the virtual method from external to D
	*/
	string virtualFunctionNameD(Klass wrapForKlass) {
		return SMID ~ methodNameC(wrapForKlass);
	}
	

	/**
	* Return the arguments list (type and name) for passing to the C++ transfer types,
	* using argument names that have the mangled suffix for converted types
	*/
	string argumentTypesC() {
		string[] argumentTypes;
		foreach (argument; arguments) {
			argumentTypes ~= argument.toStringC();
		}
		return join(argumentTypes, ", ");
	}
	
	/**
	* Return the arguments list (type and name) for receiving from  the C++ transfer types,
	* using argument names that have the mangled suffix for converted types. Wrapped
	* objects should be declared as void*
	*/
	string argumentTypesCVirtualExport() {
		string[] argumentTypes;
		foreach (argument; arguments) {
			argumentTypes ~= argument.toStringCVirtualExport();
		}
		return join(argumentTypes, ", ");
	}	
	
	/**
	* Return the C constructor code
	*/
	string toStringCConstructor(Klass wrapForKlass) {
		
		string argumentTypes = argumentTypesC();
		string converterCode = getConverterManager().getArgumentsConverterCodeCPP(arguments);
		
		string parentClassName = wrapForKlass.name;
		string newClassName = wrapForKlass.cppWrapperClassName;
		string factoryFunctionName = "%s::%s%s".format(newClassName,
			 							factoryFunctionPrefix, parentClassName);
		string signature = "
extern \"C\" %s* %s(%s) {
	%s
	%s* obj = %s(%s);
	return obj;
}\n\n".format(newClassName, methodNameC(wrapForKlass), argumentTypes,
				converterCode,
				newClassName, factoryFunctionName, getArgumentNames());
		return signature;
	}
	
	/**
	* Return the signature for the C method code
	*/ 
	string toStringCSignature(Klass wrapForKlass) {
		string signature;
		string template_;
		
		string argumentTypes = argumentTypesC();
		if (argumentTypes.length > 0 && ! static_) {
			argumentTypes = ", " ~ argumentTypes;
		}
		
		string parentClassName = wrapForKlass.CName;
		string selfReferent = static_ ? "" : "%s* self".format(parentClassName);
		
		if (getConverter(returnType)) {
			auto converter = getConverter(returnType);
			/*
			extern \"C\" char* Shape_getName_SMIX3(Shape* self)
			*/	
			template_ = "extern \"C\" %s %s(%s%s) ";
			signature = template_.format(converter.transferTypeC, methodNameC(wrapForKlass),
				 selfReferent, argumentTypes); 
		} else {
			if (returnType.argType == ArgType.value && returnType.isWrappedType()) {
				template_ = "extern \"C\" %s* %s(%s%s)";
			} else {
				template_ = "extern \"C\" %s %s(%s%s)";
			}	
			signature = template_.format(returnType.toStringC(),
					 			methodNameC(wrapForKlass), selfReferent, argumentTypes); 
		}
		return signature;
	}
	
	/**
	* Return the body of the C method code
	*/ 
	string toStringCBody() {
		string converterCode = getConverterManager().getArgumentsConverterCodeCPP(arguments);
		return converterCode;
	}
	
	/**
	* Return the string of the return type for the C wrapper function
	*/ 
	string toStringCReturnTypeString() {
		string returnDecl;
		if (getConverter(returnType)) {
			auto converter = getConverter(returnType);
			returnDecl = converter.transferTypeC;
		} else if (returnType.argType == ArgType.value && returnType.isWrappedType()) {
			returnDecl = returnType.name;
		} else {
			returnDecl = returnType.toStringC();
		}
		return returnDecl;
	}
	
	bool isPublic() {
		return ((visibility == Visibility.public_) 
			|| (visibility == Visibility.public_slots_) 
					);
	}
	
	/**
	* Return the C code that takes the result of the method call, converts it if
	* necessary, copies it if necessary, and returns it.
	*/
	string toStringCReturnValue(Klass wrapForKlass) {
		/*
		if (isCreatedByD(self) {
			return ((Rect_SMI*) self)->perimeter_fromDBase(factor, name);
		} else {
			// Not possible to get here for non-virtual protected methods (?) because
			// only a CreatedBy.D wrapper has this as a public method, and that
			// will be a Rect_SMI wrapped obj.
			// If virtual then can get here
			return self->perimeter(factor, name);
		*/
		
		if (methodCodeD) {
			return methodCodeD;
		}
		
		string template_;
		string virtClassName = wrapForKlass.cppWrapperClassName;
		string argumentNames = getArgumentNames();
		string parentClassName = wrapForKlass.name;
		
		if (returnType.name == "void" && returnType.argType == ArgType.value) {
			if (isPublic()  && virtual && ! static_) {
				template_ = 
"if (isCreatedByD(self))  {
	(( %s*) self)->%s%s(%s);
} else {
	self->%s(%s);
}";
				return template_.format(virtClassName, name, fromDBase, argumentNames,
									 name, argumentNames);
			} else if (visibility == Visibility.protected_ && ! static_) {
				template_ = 
"if (isCreatedByD(self))  {
	(( %s*) self)->%s%s(%s);
}";
				return template_.format(virtClassName, name, fromDBase, argumentNames);
			} else {
				if (! static_) {
					template_ = "self->%s(%s);";
					return template_.format(name, argumentNames);
				} else {
					template_ = "%s::%s(%s);";
					return template_.format(wrapForKlass.CName, name, argumentNames);
				}	
			}
		}
		
		string methodReturnType;
		string return_;
		if  (getConverter(returnType)) {
			auto converter = getConverter(returnType);
			methodReturnType = converter.typeNameC;
		} else {
			methodReturnType = returnType.toStringC();
		}
		
		string constCastStart;
		string constCastEnd;
		if (returnType.isConst) {
			constCastStart = "const_cast<%s> (".format(methodReturnType);
			constCastEnd = ")";
		}
		
		if (visibility == Visibility.public_  && virtual && ! static_) {
			template_ = 
"if (isCreatedByD(self))  {
	%s retValue = %s(( %s*) self)->%s%s(%s)%s;
	$CONVERT_COPY_AND_RETURN	
} else {
	%s retValue = %sself->%s(%s)%s;
	$CONVERT_COPY_AND_RETURN
}
";
			return_ = template_.format(
				methodReturnType, constCastStart, virtClassName, name, fromDBase, argumentNames, constCastEnd,
				methodReturnType, constCastStart, name, argumentNames, constCastEnd);
		} else if (visibility == Visibility.protected_ && ! static_) {
			template_ = 
"if (isCreatedByD(self))  {
	%s retValue = %s(( %s*) self)->%s%s(%s)%s;
	$CONVERT_COPY_AND_RETURN
}
";
			return_ = template_.format(
				methodReturnType, constCastStart, virtClassName, name, fromDBase, argumentNames, constCastEnd);
		} else {
			string selfClassReferent = static_ ? wrapForKlass.CName ~ "::" ~ name: "self->" ~ name;
			template_ = 
"%s retValue = %s%s(%s)%s;
$CONVERT_COPY_AND_RETURN
";
			return_ = template_.format(
				methodReturnType, constCastStart, selfClassReferent, argumentNames, constCastEnd);
		}
		
		string convertCopyAndReturn = returnTypeToTransferTypeConverterCode(returnType);
		
		return_ = return_.replace("$CONVERT_COPY_AND_RETURN", convertCopyAndReturn);
		
		return return_;
	}
	
	/**
	* Return the C++ code that converts retValue from the C++ return type
	* to the C++ transfer type (if necessary) or copies it (if necessary), and returns it.
	*/ 
	string returnTypeToTransferTypeConverterCode(CType returnType) {
		string convertCopyAndReturn;
		if (getConverter(returnType)) {
			auto converter = getConverter(returnType);
			if (converter.CToCTransferInCFunctionSignature.length == 0) {
				// use inline converter
				convertCopyAndReturn = 
"%s convertedRetValue = %s;
return convertedRetValue;".format(
						converter.transferTypeC,
						converter.CToCTransferInCInline(converter.transferTypeC, "retValue"));
			} else {
				// use function converter
				convertCopyAndReturn = 
"%s convertedRetValue = %s(retValue);
return convertedRetValue;".format(
						converter.transferTypeC, converter.CToCTransferInCFunctionName);
			}			
		} else if (returnType.argType == ArgType.value && returnType.isWrappedType()) {
			convertCopyAndReturn = 
"%s* copiedRetValue = new %s(retValue);
return copiedRetValue;".format(returnType.name, returnType.name);
		} else {
			convertCopyAndReturn = "return retValue;";
		}
		return convertCopyAndReturn;
	}
	
	
	/**
	* Returns the C code for the wrapped method
	*/ 
	string toStringCMethod(Klass wrapForKlass) {
		/*
		string name = convertPCharToCString(name___SMI);
		if (isCreatedByD(self) {
			return (Rect_SMI*) self->perimeter_fromDBase(factor, name);
		} else {
			// Not possible to get here for non-virtual protected methods (?) because
			// only a CreatedBy.D wrapper has this as a public method, and that
			// will be a Rect_SMI wrapped obj.
			// If virtual then can get here
			return self->perimeter(factor, name);
		*/
		
		string result;
		string signature = toStringCSignature(wrapForKlass);
		string body_ = toStringCBody();
		body_ = indent(body_, 1);
		
		string returnValue = toStringCReturnValue(wrapForKlass);
		returnValue = indent(returnValue, 1);
		
		string template_ = 
"
%s {
%s
%s
}
";
		return template_.format(signature, body_, returnValue);
	}
	
	/**
	* Return the CPP code for this method, wrapping it for the klass wrapForKlass (used
	* to handle mixin classes. E.g. method Calculator.add with have a wrapForKlass of
	* Rect when it is going into the Rect wrapper)
	*/
	string toStringC(Klass wrapForKlass) {
		
		if (abstract_) return "";
		
		if (constructor) {
			return toStringCConstructor(wrapForKlass);
		} 
		else {
			return toStringCMethod(wrapForKlass);
		}	
	}
	
	
	/**
	* Construct the extern (C) declaration for the wrapped C function, for use in D e.g.
	*
	* extern (C) void  vtkRenderer_AddActor(void*, void*);
	*/ 
	string toStringDExport(Klass wrapForKlass) {
		
		if (abstract_) return "";
		
		string argumentTypes = "";
		foreach (argument; arguments) {
			argumentTypes ~= ", " ~ argument.toStringDExport();
		}
		
		string returnTypeName;
		string signature;
		
		if (! constructor) {
			returnTypeName = returnType.toStringD();
			if (returnType.isWrappedType()) {
				returnTypeName = "void*";
			}	
			if (getConverter(returnType)) {
				returnTypeName = getConverter(returnType).transferTypeC;
			}
			if (returnType.isEnum) {
				returnTypeName = "int";
			}
			
			if (static_) {
				if (argumentTypes.length > 0) {
				argumentTypes = argumentTypes[2 .. $];
			}	
				signature = "extern (C) %s %s(%s);\n\n".format( 
					returnTypeName, methodNameC(wrapForKlass), argumentTypes);
			} else {
				signature = "extern (C) %s %s(void* self%s);\n\n".format( 
					returnTypeName, methodNameC(wrapForKlass), argumentTypes);
			}
		} else {
			returnTypeName = "void*";
			if (argumentTypes.length > 0) {
				argumentTypes = argumentTypes[2 .. $];
			}	
			signature = "extern (C) %s %s(%s);\n\n".format( 
				returnTypeName, methodNameC(wrapForKlass), argumentTypes);
		}
		
		return signature;
	}
	
	/**
	* Return if this method overrides the given method
	*/
	bool overrides(Method method) {
		if (method.name != name) {
			return false;
		}
		if (method.returnType != returnType) {
			return false;
		}
		if (method.arguments.length != arguments.length) {
			return false;
		}
		foreach(i, argument; arguments) {
			if (argument != method.arguments[i]) {
				return false;
			}
		}
		return true;
	}	
	
	/**
	* Return if this method overrides any base class method
	*/
	bool isOverridingBaseMethod() {
		foreach(method; klass.getBaseMethods()) {
			if (overrides(method)) {
				return true;
			}
		}
		return false;
	}
	
	/**
	* Get the signature for this method in D
	*/
	string toStringDSignature() {
		
		string argumentTypes = "";
		foreach (argument; arguments) {
			argumentTypes ~= ", " ~ argument.toStringD();
		}
		if (argumentTypes.length > 0) argumentTypes = argumentTypes[2 .. $];
		
		string signature;
		if (! constructor) {
			signature = "%s %s(%s)".format(returnType.toStringD(), DName, argumentTypes);
			if (visibility == Visibility.protected_) {
				signature = "protected " ~ signature;
			}
			if (static_) {
				signature = "static " ~ signature;
			}			
			if (isOverridingBaseMethod() && ! static_) {
				signature = "override " ~ signature;
			}
		} else {
			signature = "this(%s)".format(argumentTypes);
		}
		
		return signature;
	}
	
	/**
	* Create the extern (C) function that calls the appropriate virtual method call for the wrapped
	* class to be called from C. e.g.
	*
	*   extern (C) int SMID_Rect_multBy2_SMIX6(void* wrappedObject, int arg0) {
	*        Rect wrapper = getWrappedObject!Rect(wrappedObject);
	*        assert(wrapper.createdBy == CreatedBy.D);
	*        int retVal = wrapper.multBy2(arg0);
	*        return retVal;
	*   }     
	*/ 
	
	string toStringDVirtualExport(Klass wrapForKlass)
	    in {
			assert(virtual);
		}
		body {
		string template_ = 
"extern (C) %s %s(void* wrappedObject%s) {
	debug {writeln(\"Call exported D func %s \"); }
	// Get wrapper for 'this'
	%s wrapper = getWrappedObject!(%s)(wrappedObject, false);
	assert(wrapper.createdBy == CreatedBy.D, \"Object 'this' in virtual call not created by D!\");
%s%s";	
	
		string callTemplateNonVoid = 
"	// Call virtual D function
	%s %s = wrapper.%s(%s);";	

		string callTemplateVoid = 
"	// Call virtual D function
	wrapper.%s(%s);";	

		string returnTemplate = 
"	// Code to convert D return value to C++ transfer type
	%s retVal = %s;
	return retVal;";		
	
		string returnTypeName = returnType.toStringCTransfer();
		string returnTypeNameD = returnType.toStringD();
		string methodNameC = SMID ~ methodNameC(wrapForKlass);
		string argumentTypes = argumentTypesCVirtualExport();
		if (argumentTypes.length > 0) {
			argumentTypes = ", " ~ argumentTypes;
		}
		string parentClassName = wrapForKlass.name;
		string argumentNames = getArgumentNames();
		string thisDottedDName = getClassOfName(parentClassName).DName;
		
		/**
		* For arguments which are wrapped but are not convertible,
		* get the wrapper objects for them
		*/
		string getWrappedArgumentConversionCode() {
			string conversionCode;
			foreach(argument; arguments) {
				if (! argument.type.isWrappedType() || getConverter(argument.type)) continue;
				conversionCode ~= 
		"%s %s = getWrappedObject!(%s)(%s, false, OwnedBy.None);
		// If OwnedBy.None then the D wrapper was only created for this virtual method 
		scope(exit) if (%s.ownedBy == OwnedBy.None) %s.destroy();\n".format(
						argument.type.name, argument.name, 
						argument.type.name, argument.name ~ ConvertedTypeArgumentPostfix,
						argument.name, argument.name);
			}
			return conversionCode;
		}
		
		string wrappedArgumentConversionCode = getWrappedArgumentConversionCode();
		if (wrappedArgumentConversionCode.length > 0) {
			wrappedArgumentConversionCode = 
			  "// Code to get D wrappers of non-convertible wrapped arguments\n%s\n".format(
			  					wrappedArgumentConversionCode);
			wrappedArgumentConversionCode = indent(wrappedArgumentConversionCode, 1);	  
		}	
		
		string argumentConversionCode = 
			getConverterManager().getArgumentsConverterCodeDVirtualExport(arguments);
		if (argumentConversionCode.length > 0) {
			argumentConversionCode = 
			  "// Code to convert arguments to D where required\n%s\n".format(argumentConversionCode);
			argumentConversionCode = indent(argumentConversionCode, 1);  
		}
		
		string conversionCode;
		if (getConverter(returnType)){
			Argument returnArg = new Argument(returnType, RET_VALUE_UNCONVERTED, this);
			conversionCode = getConverter(returnType).DToCInDInline(returnArg, "");
		} else if (returnType.isWrappedType()) {
			// Returned object is a wrapper so return its wrapped object 
			conversionCode = "cast(void*) %s.wrappedObj".format(RET_VALUE_UNCONVERTED);
		} else
		{
			// return value is a base type, just return it untouched
			conversionCode = RET_VALUE_UNCONVERTED;
		}
		
		string bodyCode = template_.format(
			returnTypeName, methodNameC, argumentTypes,
			methodNameC,
			thisDottedDName, thisDottedDName, 
			wrappedArgumentConversionCode, argumentConversionCode);
		
		string callCodeNonVoid = callTemplateNonVoid.format(
				returnTypeNameD, RET_VALUE_UNCONVERTED, name, argumentNames);
		
		string callCodeVoid = callTemplateVoid.format(
				name, argumentNames);
		
		string returnCode = returnTemplate.format(returnTypeName, conversionCode);
		
		if (returnType.name == "void" && returnType.argType == ArgType.value) {
			// If the return type is void then no return is necessary
			return bodyCode ~ callCodeVoid ~ "\n}\n";
		} else {
			return bodyCode ~ callCodeNonVoid ~ "\n" ~ returnCode ~ "\n}\n";
		}
		
	}
	
	/**
	* Get the D method declaration for abstract methods
	*/
	string toStringDAbstract(string signature) {
		signature = "abstract " ~ signature;
		string stringD = format("\t%s;\n\n", signature);		
		return stringD;
	}
	
	/**
	* Create the code to call the method that casts the wrapped object to one of its
	* superclasses (in multiple inheritance)
	*/ 
	string getCastPointerCall(string interfaceName, string argumentName) {
		// e.g. void* arg0_wrappedObj = arg0.getCastPointerForInterface("Calculator");
		return 
		"// Cast interface typed arguments to correct base class\n" 
		"void* %s_wrappedObj = %s ? %s.getCastPointerForInterface(\"%s\") : null;".format(
			argumentName, argumentName, argumentName, interfaceName);
	}
	
	/**
	* Get the klass of the given name, preferring local scope in ambiguous cases. The 
	* name is qualified CPP style e.g. Place, Point::Place
	*/ 
	@property Klass getClassOfName(string name) {
		return klass.getClassOfName(name);
	}
	
	/**
	* Return a range of arguments that are interfaces
	*/
	auto argumentsOfTypeInterface() {
		return arguments.filter!(a => this.isInterface(a));
	}
	
	/**
	* Return a range of arguments that are wrapped types and not converted
	*/
	auto argumentsOfWrappedTypeNotConverted() {
		return arguments.filter!(a => a.type.isWrappedType() && ! getConverter(a.type));
	}	
	
	bool isInterface(Argument argument) {
		return (argument.type.isWrappedType() && ! getConverter(argument.type) && 
				 getClassOfName(argument.type.name).wrapAsInterface);
	}
	
	/**
	* Create the code that, 
	*     A) for arguments which are interfaces, casts the wrappedObj
	*        of the argument to the correct base class (that equates to the interface name)
	*     B) For other wrapped types, gets the wrapped object
	*/
	string getArgumentCastingCode() {
		string argumentCastingCode;
		foreach (argument; argumentsOfWrappedTypeNotConverted) {
			if (isInterface(argument)) {
				argumentCastingCode ~= getCastPointerCall(argument.type.name, argument.name) ~ "\n";
			} else {
				argumentCastingCode ~= "void* %s_wrappedObj = %s ? %s.wrappedObj : null;\n".format(
					argument.name, argument.name, argument.name);
			}
					
		}
		return argumentCastingCode;
	}
	
	/**
	* Return true if the return type is not by value.
	*/
	bool retTypeIsNotByValue() {
		if (_returnType.argType == ArgType.value) {
			return false;
		} else {
			return true;
		}
	}
	
	/**
	* Return the code that sets the ownedBy flag according to the Transfer, TransferBack
	* and TransferThis annotations.
	*/ 
	string setArgumentOwnership() {
		string code;
		foreach(argument; arguments) {
			string argumentName = argument.nameIncPostfix;
			if (argument.transfer) {
				code ~= 
"		// %s is marked /Transfer/
		if (%s) %s.ownedBy = OwnedBy.CPP;
".format(argumentName, argumentName, argumentName);
			}
			if (argument.transferBack) {
				code ~= 
"		// %s is marked /TransferBack/
		if (%s) %s.ownedBy = OwnedBy.D;
".format(argumentName, argumentName, argumentName);
			}
			
			if (argument.transferThis) {
				code ~= 
"		// %s is marked /TransferThis/
		if (%s) this.ownedBy = OwnedBy.CPP;
".format(argumentName, argumentName);
			}
		}
		return code;
	}
	
	/**
	* Return the body of the D method.
	* It must create a variable with the method result called RET_VALUE_UNCONVERTED (unless
	* this is a constructor / destructor/ void method).
	*/
	string toStringDBody(Klass wrapForKlass) {
		
		string body_;
		
		if (visibility == Visibility.protected_) {
			body_ ~= 
"\t\t// Protected methods can only be called if this object was created from D
\t\tassert(createdBy == CreatedBy.D);\n";
		}
		
		body_ ~= getConverterManager().getArgumentsConverterCodeD(arguments);
		
		body_ ~= setArgumentOwnership();
		
		string parentClassName = wrapForKlass.name;
		string argumentCastingCode = getArgumentCastingCode();
		string argumentNames = getArgumentNamesD();
		
		if (constructor) {
			body_ ~= 
			"
			%s
			wrappedObj = %s(%s);
			registerWrappedObj(this, wrappedObj);
			super(wrappedObj, CreatedBy.D, OwnedBy.D);
			".format(argumentCastingCode,
				methodNameC(wrapForKlass), argumentNames);
		}
		else
		{
			if (! static_) {
				body_ ~= 
				"			checkCPPObjectIsValid();\n";
			}	
			
			string wrappedObjId = static_ ? "" : "wrappedObj"; 
			
			if (argumentNames.length > 0 && ! static_) {
					argumentNames = ", " ~ argumentNames;
			}
			if (returnType.name == "void") {
				body_ ~= format("%s\n%s(%s%s);", argumentCastingCode,
					 methodNameC(wrapForKlass), wrappedObjId, argumentNames);
			}
			else {
				if (! getConverter(returnType) && returnType.isWrappedType) {
					Klass returnTypeKlass = getClassOfName(returnType.name);
					string classNameToWrapAs = returnTypeKlass.DName;
					if (returnTypeKlass.wrapAsInterface) {
						/*
						* In this scenario, if the returned object is not already wrapped
						* then it is very hard to deduce the actual class of the returned object,
						* so we wrap it as the Impl of the interface.
						*/
						classNameToWrapAs ~= INTERFACE_IMPL_SUFFIX;
					}
					string ownedBy;
					if(retTypeIsNotByValue() && ! transferBack) {
						ownedBy = "OwnedBy.CPP";
					} else {
					ownedBy = "OwnedBy.D";
					}
					
					body_ ~= 
					"
					%s
					void* retWrappedObj = %s(%s%s);
					OwnedBy ownedBy = %s;
					bool registerNewWrappers = true;
					%s %s = getWrappedObject!(%s)(retWrappedObj, registerNewWrappers, ownedBy);
					".format(argumentCastingCode,
							 methodNameC(wrapForKlass), wrappedObjId, argumentNames,
							 ownedBy,
						 	 returnTypeKlass.DName, RET_VALUE_UNCONVERTED, classNameToWrapAs);
				 }
				else {
					string unconvertedReturnType;
					if (getConverter(returnType)) {
						unconvertedReturnType = getConverter(returnType).transferTypeC();
					} else {
						unconvertedReturnType = returnType.toStringD();
					}
					body_ ~= 
					"
					%s
					%s %s = %s(%s%s);
					".format(argumentCastingCode,
							 unconvertedReturnType, RET_VALUE_UNCONVERTED, 
									methodNameC(wrapForKlass), wrappedObjId, argumentNames);
				}
			}
		}	
		
		return body_;
		
	}
	
	/**
	* Return the final section of the D method.
	* It must handle a variable with the method result called RET_VALUE_UNCONVERTED 
	* and convert it to the D type if necessary.
	*/
	string toStringDReturn() {
		string return_;
		if (getConverter(returnType)) {
			return_ = "return " ~ getConverter(returnType).CToDInDInline(returnType.name, RET_VALUE_UNCONVERTED) ~ ";";
		} else {
			return_ = "return %s;".format(RET_VALUE_UNCONVERTED);
		}
		return return_;
	}
	
	/**
	* Return the D code for this method, wrapping it for the klass wrapForKlass (used
	* to handle mixin classes. E.g. method Calculator.add with have a wrapForKlass of
	* Rect when it is going into the Rect wrapper)
	*/
	string toStringD(Klass wrapForKlass) {
		
		string signature = toStringDSignature();
		
		if (abstract_) {
			return toStringDAbstract(signature);
		}		
		string body_ = toStringDBody(wrapForKlass);
		body_ = indent(body_, 2);
		
		string return_;
		if (! constructor && ! destructor && ! (returnType.name == "void")) {
			return_ = toStringDReturn();
			return_ = indent(return_, 2);
		}
		
		string stringD = "\t%s {\n%s%s\t}\n\n".format(signature, body_, return_);		
		return stringD;
	}
	
	override string toString() {
		string argsRepr = "";
		foreach(argument; arguments) {
			argsRepr ~= argument.toString() ~ "\n";
		}
		string repr = format("<Method %s %s %s>", name, returnType, argsRepr);
		return repr;
	}
	
}