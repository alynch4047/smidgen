
/**
*
* This module houses the code that writes the C++ code for the CPPWrapper class
* that inherits the wrapped class. This new class is needed to handle virtual and
* protected methods. Any constructor calls should instantiate this CPPWrapper 
* derived class.
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.cpp_wrapper;

import std.stdio: writeln;
import std.stream: Stream;
import std.string: format, replace;
import std.array: join;

import smidgen.ast.klass: Klass;
import smidgen.converter: ConvertedTypeArgumentPostfix;
import smidgen.ast.method: Method, Visibility, SMID;

/// This suffix is appended to the wrapped class name to make the new class name.
static string CPPWrapperSuffix = "_SMI";

/// This prefix is used to make the static factory function names
static string factoryFunctionPrefix = "SMIMake_";

/// This suffix is used to mangle the virtual method name in the CPPWrapper class
/// which is called from the base D wrapper class. 
static string fromDBase = "_fromDBase";


/**
* Write the CPP wrapper that inherits the class wrapped by klass, used for handling
* virtual and protected methods.
* e.g., where getDesc was protected in the wrapped class:
*
*  class Rect_SMI: Rect {
*   
*   public:
*  	   
*      static Rect SMIMake_Rect(int x) {
*           return new Rect_SMI(x);
*      }
*
*      char* getDesc(char* initVal) {
*      	  return Rect::getDesc(initVal);
*      }
*
*   private:
*      Rect_SMI(int x) {};
*
* }
*/ 
string getCPPWrapper(Klass klass) {
	string externDDeclarations = getExternDDeclarations(klass);
	string constructors = getConstructors(klass);
	string protectedMethodCalls = getVirtualOrProtectedMethodCalls(klass);
	string destructor = getDestructor(klass);
	string klassName = klass.CName;
	string wrapperTemplate =
"

// These externs declare the functions in the D wrapper, used for virtual method calls
%s

// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class %s: %s {

public:
	bool inhibitDestructorCallbackToD;

// Constructors

%s

// Protected and virtual method calls
public:
%s

// Destructor
%s
};\n
//END VIRTUAL / PROTECTED CLASS \n\n";
	string wrapper = wrapperTemplate.format(externDDeclarations,
		klass.cppWrapperClassName, klassName,
		constructors,
		protectedMethodCalls,
		destructor);
	return wrapper;
}

/**
* Get the destructor for the class
*/
string getDestructor(Klass klass) {
	string template_ = 
"~%s() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		%s(this);
	}	
}
";	
	return template_.format(klass.cppWrapperClassName,
		 						klass.getDestructorFunctionName);
}

/**
* Get the extern "C" declarations for the functions in the D wrapper
*/ 
string getExternDDeclarations(Klass klass) {
	string declarations;
	foreach(method; klass.getAllWrappedMethods) {
		string reason;
		if (method.excludeFromWrapping(reason)) continue;
		if (method.abstract_) continue;
		if (! method.virtual) continue;
		declarations ~= getExternDDeclaration(method, klass);
	}
	declarations ~= getDFunctionDestructorDeclaration(klass) ~ "\n";
	return declarations;
}

/**
* Get the extern declaration for the D function that registers the CPPWrapper destruction
*/
string getDFunctionDestructorDeclaration(Klass klass) {
	string template_ = "extern \"C\" void %s(void* wrappedObject);";
	return template_.format(klass.getDestructorFunctionName);
}

/**
* Get the extern "C" declarations for the function in the D wrapper
*/ 
string getExternDDeclaration(Method method, Klass wrapForKlass) {

	string functionName = SMID ~ method.methodNameC(wrapForKlass);
//	string argumentTypes = method.argumentTypesCVirtualExport();
	string argumentTypes = method.argumentTypesC();
	if (argumentTypes.length > 0) {
		argumentTypes = ", " ~ argumentTypes;
	}
	string returnType = method.returnType.toStringCVirtualExport;
	
	string template_ = 
"extern \"C\" %s %s(void* wrappedObject%s);\n";

	return template_.format(returnType, functionName, argumentTypes);
}

/**
* Get the constructors for the CPPWrapper class. e.g.
*    public:
*      	static QLabel_SMI SMIMake_QLabel(QWidget* parent, int flags___SMI){
*			Qt::WindowFlags flags = convertIntToQFlags(flags___SMI);
*			return new QLabel_SMI(parent, flags);
*		};
*		static QLabel_SMI SMIMake_QLabel(char* text___SMI, QWidget* parent, int flags___SMI) {
*			QString text = convertPCharToQString(text___SMI);
*			Qt::WindowFlags flags = convertIntToQFlags(flags___SMI);
*			return new QLabel_SMI(text, parent, flags);
*		};
*    private:
*		QLabel_SMI(QWidget* parent, Qt::WindowFlags flags) : QLabel(parent, flags);
*		QLabel_SMI(QString text, Widget* parent, Qt::WindowFlags flags) : QLabel(text, parent, flags);
*           
*/ 
string getConstructors(Klass klass) {
	string constructors = "";
	foreach(method; klass.getAllWrappedMethods) {
		if (! method.constructor || method.visibility == Visibility.private_ ||
			method.klass.abstract_) continue;
		constructors ~= getConstructorMethods(method) ~ "\n";
	}
	return constructors;
}

/**
* Get the constructor for a CPPWrapper class constructor. e.g.
*     public:
*      	 static QLabel_SMI SMIMake_QLabel(QWidget* parent, int flags___SMI){
*			Qt::WindowFlags flags = convertIntToQFlags(flags___SMI);
*			return new QLabel_SMI(parent, flags);
*		 };
*     private:
*        QLabel_SMI(QWidget* parent, Qt::WindowFlags flags) : QLabel(parent, flags);
*/ 
string getConstructorMethods(Method method) {
	string template_ = 
"
public:
	%s
private:
    %s
";
	return template_.format(getConstructorFactory(method), getConstructor(method));
}	


/**
* Get the constructor factory e.g.:
*	static QLabel_SMI SMIMake_QLabel(QWidget* parent, int flags){
*			return new QLabel_SMI(parent, flags);
*		 };
*/ 
string getConstructorFactory(Method method) {

	string template_ = 
"
static %s* %s%s(%s) {
	%s* retVal = new %s(%s);
	registerDInstance(retVal);
	return retVal;
};
";

	string[] argumentTypes;
	foreach (argument; method.arguments) {
		argumentTypes ~= argument.toStringCRaw();
	}
	string argumentTypesComma = join(argumentTypes, ", ");
	
	string[] argumentNames;
	foreach (argument; method.arguments) {
		argumentNames ~= argument.name;
	}	
	string argumentNamesComma = join(argumentNames, ", ");
	
	string newClassName = method.klass.cppWrapperClassName;
	return template_.format(newClassName, factoryFunctionPrefix,
		method.klass.name, argumentTypesComma, 
		newClassName, newClassName, argumentNamesComma);
}


/**
* Get the constructor e.g.:
*	QLabel_SMI(QWidget* parent, Qt::WindowFlags flags) : QLabel(parent, flags);
*/
string getConstructor(Method method) {	
	
	string[] argumentTypes;
	foreach (argument; method.arguments) {
		argumentTypes ~= argument.toStringCRaw();
	}
	string argumentTypesComma = join(argumentTypes, ", ");
	
	string[] argumentNames;
	foreach (argument; method.arguments) {
		argumentNames ~= argument.name;
	}	
	string argumentNamesComma = join(argumentNames, ", ");
	
	string template_ = "%s(%s): %s(%s) {inhibitDestructorCallbackToD = false;};";
	return template_.format(method.klass.cppWrapperClassName, argumentTypesComma,
		method.klass.name, argumentNamesComma);
}


/**
* Get the virtual or protected method calls for the CPPWrapper class. e.g.
*
double perimeter(int factor, string name__SMI) {
	// This can only be called from a C++ instance, never from a D instance
	char* name = convert(name___SMI);
	return SMID_Rect_perimeter_SMIX13(this, factor, char* name___SMI)
}

double perimeter_fromDBase(int factor, string name) {
	// This is only called from a D Base wrapper class via the C++ wrapper extern "C" func
	return Rect::perimeter(factor, name);
}
*/ 
string getVirtualOrProtectedMethodCalls(Klass klass) {
	string virtualProtectedMethodsCode;
	foreach(method; klass.getAllWrappedMethods) {
		string reason;
		if (method.excludeFromWrapping(reason)) continue;
		if (method.abstract_) continue;
		if (method.constructor) continue;
		if ((! method.visibility == Visibility.protected_) && ! method.virtual) continue;
		virtualProtectedMethodsCode ~= getVirtualOrProtectedMethodCall(method, klass);
	}
	return virtualProtectedMethodsCode;
}


/**
* Get the virtual or protected method call for the CPPWrapper class. e.g.
*

//only reqd for virtual
double perimeter(int factor, string name__SMI) {
	// This can only be called from a C++ instance, never from a D instance
	char* name = convert(name___SMI);
	return SMID_Rect_perimeter_SMIX13(this, factor, char* name)
}

// reqd for virtual/protected
double perimeter_fromDBase(int factor, string name) {
	// This is only called from a D Base wrapper class via the C++ wrapper extern "C" func
	return Rect::perimeter(factor, name);
}
*/ 
string getVirtualOrProtectedMethodCall(Method method, Klass wrapForKlass) {
	
	string code = getFromDBaseMethod(method);
	
	if (method.virtual) {
		
		code ~= getVirtualMethod(method, wrapForKlass);
		
	}	
	return code;
}

/**
* Get fromDBase method call
*/
string getFromDBaseMethod(Method method) {
	assert(method);
	string[] argumentTypes;
	foreach (argument; method.arguments) {
		argumentTypes ~= argument.toStringCRaw();
	}
	string argumentTypesComma = join(argumentTypes, ", ");	
	
	string[] argumentNames;
	foreach (argument; method.arguments) {
		argumentNames ~= argument.name;
	}	
	string argumentNamesComma = join(argumentNames, ", ");
	assert(method.returnType);
	string returnType = method.returnType.toStringC();
	string template_ = 
"
%s %s(%s) {
	return %s::%s(%s);
}";
	return template_.format(returnType, method.name ~ fromDBase, argumentTypesComma,
		method.klass.name, method.name, argumentNamesComma);
}

/**
* Get virtual method call code
*/
string getVirtualMethod(Method method, Klass wrapForKlass) {
	string code;
	string[] argumentNames;
	foreach (argument; method.arguments) {
		string argumentName = argument.name;
		argumentNames ~= argumentName;
	}	
	string argumentNamesComma = join(argumentNames, ", ");
	
	string returnType = method.returnType.toStringC();
	
	string[] argumentTypesV;
	foreach (argument; method.arguments) {
		argumentTypesV ~= argument.toStringCRawSuffixed();
	}	
	string argumentTypesVComma = join(argumentTypesV, ", ");
	
	if (argumentNamesComma.length > 0) {
		argumentNamesComma = ", " ~ argumentNamesComma;
	}

	string converterCode = 
		method.getConverterManager().getArgumentsConverterCodeCPPVirtual(method.arguments);
		
	string returnTypeConverterCode;
	if (method.getConverter(method.returnType)) {
		auto converter = method.getConverter(method.returnType);
		if (converter.CTransferToCInCFunctionSignature.length == 0) {
			returnTypeConverterCode = 
				"return %s;".format(converter.CTransferToCInCInline(converter.typeNameC,
																			"retValue"));
		} else {
			returnTypeConverterCode = 
				"return %s(retValue);".format(converter.CTransferToCInCFunctionName);
		}
	} else {
		string retValue;
		if (method.returnType.isWrappedType() && method.returnType.isValue()) {
			retValue = "*((%s*) retValue)".format(method.returnType.name);
		} else if (method.returnType.isWrappedType()) {
			retValue = "(%s*) retValue".format(method.returnType.name);
		} else {
			retValue = "retValue";
		}
		
		returnTypeConverterCode = "return %s;".format(retValue);
	}
	
	string template_;
	if (method.returnType.isVoid()) {
		
		template_ = 
"	
%s %s(%s) {
	// This can only be called from a C++ instance, never from a D instance
	%s
	%s(this%s);
}	
";
		code = template_.format(returnType, method.name, argumentTypesVComma,
			converterCode,
			method.virtualFunctionNameD(wrapForKlass), argumentNamesComma);
	} else {
	
		template_ = 
"	
%s %s(%s) {
	// This can only be called from a C++ instance, never from a D instance
	%s
	%s retValue = %s(this%s);
	%s
}	
";
		code = template_.format(returnType, method.name, argumentTypesVComma,
			converterCode,
			method.returnType.toStringCTransfer(), method.virtualFunctionNameD(wrapForKlass),
			 				argumentNamesComma, returnTypeConverterCode);
			}
	return code;

}

