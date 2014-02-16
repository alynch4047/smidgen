/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.ast.argument;

import std.string;
import std.array: split, join;
import std.stdio: writeln;
import std.algorithm: canFind;

import pegged.grammar;

import smidgen.converter: Converter, ConvertedTypeArgumentPostfix;
import smidgen.converter_manager: ConverterManager, ConverterManagerProvider;

import smidgen.ast.method: Method, TRANSFERBACK, TRANSFER, TRANSFERTHIS;
import smidgen.ast.klass: Klass;


class Annotation {
	
	string content;
	string name;
	string value;
	
	this(string content) {
		this.content = content;
		parseNameAndValue();
	}
	
	this(ParseTree tree) {
		auto content = strip(tree.input[tree.begin .. tree.end]);
		this(content);
	}
	
	void parseNameAndValue() {
		if (content.canFind("=")) {
			auto parts = content.split("=");
			name = parts[0];
			value = parts[1 .. $].join("=");	
			if (value[0] == '"' && value[$ - 1] == '"') {
				value = value[1 ..$ - 1];
			}
		} else {
			name = content;
			value = null;
		}
	}
	
	 override bool opEquals(Object o) {
	 	if (o is this) {
			return true;
		}
		if (typeid(o) != typeid(this)) {
			return false;
		}
		
		Annotation other = cast(Annotation) o;
	 	return content == other.content; 
	 	}
}


class Argument: ConverterManagerProvider {
	
	string name;
	string array;
	string defaultValue;
	CType type;
	Annotation[] annotations;
	bool isEllipsis = false;
	
	Method method;
	
	this(CType type, string name, Method method) {
		this.name = name;
		this.type = type;
		this.method = method;
	}

	this(ParseTree tree, Method method) {
		this.method = method;
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.CType"):
					type = new CType(child, method);
					break;
				case("Smidgen.Ellipsis"):
					isEllipsis = true;
					break;					
				case("Smidgen.SymbolName"):
					name = makeSafeName(strip(child.input[child.begin .. child.end]));
					break;
				case("Smidgen.Array"):
					array = strip(child.input[child.begin .. child.end]);
					break;		
				case("Smidgen.Annotation"):
					auto annotationContent = child.children[0];
					auto annotation = new Annotation(annotationContent);
					annotations ~= annotation;
					break;			
				case("Smidgen.DefaultValue"):
					auto valueNode = child.children[0];
					defaultValue = strip(valueNode.input[valueNode.begin .. valueNode.end]);
					break;				
				default:
				    writeln("Argument found " ~ child.name);	
			}
		}
		if (name.length == 0) {
			// check to see if CType has swallowed the argument name. If it has
			// then take the last word of the type.name and make it the argument name
			// XXX should change the parser so that this can not happen
			if ((! isEllipsis) && type.argType == ArgType.value) {
				// doesn't happen for pointers or references because *& blocks progress into name
				string lastWordOfTypeName = split(type.name, " ")[$ - 1];
				if (lastWordOfTypeName == type.name) {
					// there is only one word so it can't include the argument name
					return;
				}
				foreach(baseTypeName; baseTypeNames) {
					if (lastWordOfTypeName == baseTypeName) return;
				}
				// ok last word of type name is actually the argument name 
				// XXX won't work for struct/value types when wrapped, need to check if it is
				// a known struct type
				name = lastWordOfTypeName;
				type.name = to!string(join(split(type.name, " ")[0 .. $-1], " "));
			}
		}
	}	
	
	@property bool transferBack() {
		return hasAnnotation(TRANSFERBACK);
	}
	
	@property bool transfer() {
		return hasAnnotation(TRANSFER);
	}
	
	@property bool transferThis() {
		return hasAnnotation(TRANSFERTHIS);
	}		
	
	bool hasAnnotation(string annotationName) {
		return canFind(annotations, new Annotation(annotationName));
	}
	
	/**
	* Return the name of the argument, appending a postfix if the argument
	* is to be converted.
	*/ 
	@property string nameIncPostfix() {
		if (getConverter(type)) {
			return name ~ ConvertedTypeArgumentPostfix;
		}
		return name;
	}
	
	override bool opEquals(Object o) {
		if (o is this) {
			return true;
		}
		if (typeid(o) != typeid(this)) {
			return false;
		}
		Argument other = cast(Argument) o;
		if (array != other.array) {
			return false;
		}
		if (type != other.type) {
			return false;
		}
		if (isEllipsis != other.isEllipsis) {
			return false;
		}		
		return true;
	}
	
	Converter getConverter(CType type) {
		assert(getConverterManager);
		return getConverterManager.getConverter(type);
	}
	
	ConverterManager getConverterManager() {
		return method.getConverterManager();
	}
	
	/*
	* Returns: If the given name is a D or C keyword then mangle it a bit to make it
	* safe, else return the name as it was passed in
	*/ 
	string makeSafeName(string name) {
		if (name == "version") {
			return "version_";
		}
		return name;
	}
	
	/**
	* Return the argument string for use in C++ constructor specifications. This is 
	* the same as toStringC but uses only raw types not converted type.
	*/
	string toStringCRaw() {
		return type.toStringC() ~ " " ~ name;
	}	
	
	/**
	* Return the argument string for use in C++ virtual method arguments lists. This is 
	* the same as toStringC but uses only raw types not converted type. However,
	* it also adds the suffix to the argument name if it is convertible.
	*/
	string toStringCRawSuffixed() {
		string argumentString = type.toStringC() ~ " " ~ name;
		if (getConverter(type)) {
			argumentString ~= ConvertedTypeArgumentPostfix;
		}
		return argumentString;
	}		
	
	/**
	* Return the argument string for use in export "C" statements 
	*/ 
	string toStringC() {
		string argumentType;
		string argumentName = name;
		if (getConverter(type)) {
			argumentType = getConverter(type).transferTypeC ;
			argumentName ~= ConvertedTypeArgumentPostfix;
		}
		else {
			argumentType = type.toStringC();
		}
		return argumentType ~ " " ~ argumentName;
	}
	
	/**
	* Return the argument string (type and name) for receiving in D from the C++ transfer types,
	* using argument names that have the mangled suffix for converted types. Wrapped
	* objects should be declared as void*
	*/
	string toStringCVirtualExport() {
		string argumentType;
		string argumentName = name;
		if (getConverter(type)) {
			argumentType = getConverter(type).transferTypeC ;
			argumentName ~= ConvertedTypeArgumentPostfix;
		}
		else if (type.isWrappedType()) {
			argumentType = "void*";
			argumentName ~= ConvertedTypeArgumentPostfix;
		} else
		{
			argumentType = type.toStringC();
		}
		return argumentType ~ " " ~ argumentName;
	}	
	
	/**
	* For the given default value as found in the sip file,
	* return the string representation, as will appear
	* in the argument default in the .d wrapper, for the same value. e.g. This might take
	* a "0" and return a "null", or take the unquoted string 'def' and return a
	* quoted string '"def"'.  
	*/ 
	string toStringDDefaultValue() {
		string default_;
		if (defaultValue) {
			if (type.isWrappedType() && ! type.getConverter()) {
				default_ = "null";
			} else if (type.isEnum()) {
				// TODO: enum defaults
				default_ = null;
			} else if (type.getConverter()) {
				default_ = type.getConverter().getDefaultValue(defaultValue);
			} else if (defaultValue.canFind("::")) {
				// TODO: int arguments that take an enum value
				default_ = null;
			} else {
				default_ = defaultValue;
			}
		}
		return default_;
	}
	
	/// Return the argument string for use in d method signatures 
	string toStringD() {
		string argumentName = name;
		if (getConverter(type)) {
			argumentName ~= ConvertedTypeArgumentPostfix;
		}
		string default_ = toStringDDefaultValue();
		if (default_) default_ = "=" ~ default_;
		return "%s %s%s".format(type.toStringD(), argumentName, default_);
	}	
	
	/// Return the argument string for use in export (C) statements 
	string toStringDExport() {
		if (getConverter(type)) {
			return getConverter(type).transferTypeC ~ " " ~ name;
		}
		if (type.isWrappedType()) return "void* " ~ name;
		if (type.isEnum()) return "int " ~ name;
		else return type.toStringD() ~ " " ~ name;
	}
	
	override string toString() {
		return format("<Argument [%s] [%s]>", name, type.toString());
	}
}


enum ArgType {pointer, reference, value, pointerpointer};

string[] baseTypeNames = ["double", 
						  "int", "unsigned int",
						  "float",
						  "void", 
						  "char", "signed char", "unsigned char",
						  "short", "unsigned short", 
						  "long", "unsigned long", "long long", "bool"];


class CType {
	
	invariant() {
		assert(method !is null); 
	}
	
	/**
	* e.g. "const Vector*"
	*/
	bool isConst;
	ArgType argType = ArgType.value;
	string name; // e.g. "Vector" or "int"
	Method method;
	
	this(ParseTree tree, Method method) {
		this.method = method;
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.TypeName"):
					name = strip(child.input[child.begin .. child.end]);
					break;
				case("Smidgen.Pointer"):
					if (argType == ArgType.pointer) {
						// if this is the second pointer
						argType = ArgType.pointerpointer;
					} else {
						argType = ArgType.pointer;
					}
					break;
				case("Smidgen.Reference"):
					argType = ArgType.reference;
					break;
				case("Smidgen.Const"):
					isConst = true;
					break;					
				default:
				    writeln("found " ~ child.name);	
			}
		}
	}
	
	Klass getClassOfName(string klassName) {
		return method.getClassOfName(klassName);
	}
	
	override bool opEquals(Object o) {
		if (o is this) {
			return true;
		}
		if (typeid(o) != typeid(this)) {
			return false;
		}
		CType other = cast(CType) o;
		if (name != other.name) {
			return false;
		}
		if (argType != other.argType) {
			return false;
		}
		if (isConst != other.isConst) {
			return false;
		}		
		return true;
	}
	
	Converter getConverter() {
		return method.getConverterManager.getConverter(this);
	}			
	
	/**
	* Return true if this is a wrapped class, else return false (primitive type or Enum).
	*/ 
	bool isWrappedType() {
		if (isPrimitiveType) {
			return false;
		}
		if (isEnum) {
			return false;
		}
		return true;
	}
	
	bool isEnum() {
		Klass klass = getClassOfName(name);
		// klass can be null for converted types
		if (klass is null) return false;
		return klass.isEnum;
	}
	
	bool isVoid() {
		return (name == "void" && argType == ArgType.value);
	}	
	
	bool isValue() {
		return (argType == ArgType.value);
	}	
	
	bool isPrimitiveType() {
		return baseTypeNames.canFind(deTypedefedName(name));
	}	
	
	/**
	* Return the underlying name after stripping away all the typedefs. E.g. if
	*  typedef X XP;
	*  typedef XP Y;
	* then deTypedefedName("Y") should return "X"; 
	*/
	string deTypedefedName(string name) {
		return method.deTypedefedName(name);
	}
	
	/**
	*  Return the type name as a string, but without const/static.
	*/ 
	string toStringNameAndPointerRef() {
		string res = name;
		if (argType == ArgType.pointer) res ~= "*";
		else if (argType == ArgType.reference) res ~= "&";
		else if (argType == ArgType.pointerpointer) res ~= "**";
		return res;
	}
	
	/**
	*  Return the type name as a string, including const/static.
	*/ 
	string toStringC() {
		string res = "";
		if (isConst) res ~= "const ";
		string typeNameC;
		if (isWrappedType() && ! getConverter()) {
			Klass _klass =  method.getClassOfName(name);
			typeNameC = _klass.CName;
		} else {
			typeNameC = name;
		}
		res ~= typeNameC;
		if (argType == ArgType.pointer) res ~= "*";
		else if (argType == ArgType.reference) res ~= "&";
		else if (argType == ArgType.pointerpointer) res ~= "**";
		return res;
	}
	
	/**
	* Return the type name as a string, but for converted types return the 
	* D type it is converted to. For wrapped types return the wrapped type name. For enums
	* return the unqualified enum name.
	*/
	string toStringD() {
		if (isEnum) {
			// We don't want the fully qualified name here for enums
			assert(getClassOfName(name));
			string type = getClassOfName(name).DName;
			assert(type);
			type = type.split(".")[$ - 1];
			return type;
		}		
		if (getConverter()) {
			return getConverter().typeNameD;
		}
		if (isWrappedType) {
			assert(getClassOfName(name), name);
			return getClassOfName(name).DName;
		}

		else {
			string res = name;
			if (argType == ArgType.pointer) res ~= "*";
			else if (argType == ArgType.reference) res ~= "*";
			else if (argType == ArgType.pointerpointer) res ~= "**";
			return res;
		}
	}
	
	/**
	* Return the type name as a string, but for converted types return the 
	* C++ transfer type for it. For wrapped types return void*.
	*/
	string toStringCTransfer() {
		if (getConverter()) {
			return getConverter().transferTypeC;
		}
		if (isWrappedType()) {
			return "void*";
		}
		else {
			string res = name;
			if (argType == ArgType.pointer) res ~= "*";
			else if (argType == ArgType.reference) res ~= "*";
			else if (argType == ArgType.pointerpointer) res ~= "**";
			return res;
		}
	}
	
	/**
	* Return the type name as a string, but for converted types return the 
	* C++ transfer type for it.
	*/
	string toStringCVirtualExport() {
		if (getConverter()) {
			return getConverter().transferTypeC;
		}
		if (isWrappedType() && isValue()) {
			return name ~ "*";
		}
		else {
			string res = name;
			if (argType == ArgType.pointer) res ~= "*";
			else if (argType == ArgType.reference) res ~= "*";
			else if (argType == ArgType.pointerpointer) res ~= "**";
			return res;
		}
	}	
	
	/**
	* Return the type name as a string, but for use in C code (not a return or 
	* argument type). This is the same as toStringC but with no & appended.
	*/
	string toStringCInline() {
		string res = "";
		if (isConst) res ~= "const ";
		res ~= name;
		if (argType == ArgType.pointer) res ~= "*";
		else if (argType == ArgType.pointerpointer) res ~= "**";
		return res;
	}	
		
	
	override string toString() {
		return format("<CType [%s] %s %s>", name, isConst, argType);
	}
	
}