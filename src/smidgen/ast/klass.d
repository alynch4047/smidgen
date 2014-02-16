/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.ast.klass;

import std.string: format;
import std.stdio: writeln;
import std.array: replace;

import pegged.grammar;

import smidgen.ast.method; //: Method, MethodImpl, Visibility, SMID;
import smidgen.ast.argument: Argument, CType, Annotation;
import smidgen.ast.package_: Package;
import smidgen.ast.other: TypeHeaderCode, EmbeddedCode;
import smidgen.ast.typedef_: Typedef;

import smidgen.base_converters: Converter;
import smidgen.converter_manager: ConverterManager;
import smidgen.cpp_wrapper: CPPWrapperSuffix;

static string INTERFACE_IMPL_SUFFIX = "Impl";


class Member {
	string name;
}


string getNodeText(ParseTree node) {
	return strip(node.input[node.begin .. node.end]);
}


/**
* The Klass class represents a wrapped class.
*
* It contains all the metadata about the class.
*
* See_Also: Method
*/
class Klass {
	
	invariant() {
		assert( (_parentPackage !is null) ||
				(parentKlass !is null)
		);
	}	
	
	bool wrapAsInterface = false;
	bool isStruct = false;
	bool isEnum = false;
	bool isTemplated = false;
	string name;
	string baseClassName = "WrappedObject";
	string[] interfaceNames;
	/// A top level class in a package has a parent package
	Package _parentPackage;
	/// A class nested inside another class has a parent klass
	Klass parentKlass;
	
	private Member[] members;
	Method[] methods;
	Klass[] nestedKlasses;
	Typedef[] typedefs;
	Annotation annotation;
	
	TypeHeaderCode typeHeaderCode;
	string typeBodyCodeD;
	string typeHeaderCodeD;
	
	this(Package parentPackage) {
		this._parentPackage = parentPackage;
	}
	
	this(ParseTree tree, Package parentPackage) {
		this._parentPackage = parentPackage;
		parseTree(tree);
	}
	
	this(ParseTree tree, Klass parentKlass) {
		this.parentKlass = parentKlass;
		parseTree(tree);
	}	
	
	void parseTree(ParseTree tree) {
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.ClassStruct"):
					auto classStruct = child.getNodeText;
					if (classStruct == "struct") {
						isStruct = true;
					}
					break;				
				case("Smidgen.ClassName"):
					name = child.getNodeText;
					break;
				case("Smidgen.BaseClassName"):
					baseClassName = child.getNodeText;
					break;	
				case("Smidgen.Annotation"):
					annotation = new Annotation(child.getNodeText);
					break;
				case("Smidgen.ClassTemplateDecl"):
					isTemplated = true;
					break;													
				case("Smidgen.Interfaces"):
					foreach(interfaceChild; child.children) {
						interfaceNames ~= interfaceChild.getNodeText;
					}
					break;										
				case("Smidgen.ClassElements"):
					Visibility currentVisibility;
					Method currentMethod;
					if (isStruct) {
						currentVisibility = Visibility.public_;
					} else {
						currentVisibility = Visibility.private_;
					}
					foreach(int i, classElement; child.children) {
						switch(classElement.name) {
							case("Smidgen.MethodSignature"):
								auto method = new MethodImpl(i, classElement, this, currentVisibility);
								addMethod(method);
								currentMethod = method;
								break;
							case("Smidgen.ConstructorSignature"):
								auto method = new MethodImpl(i, classElement, this, currentVisibility);
								addMethod(method);
								currentMethod = method;
								break;	
							case("Smidgen.Class"):
								auto nestedKlass = new Klass(classElement, this);
								addKlass(nestedKlass);
								break;		
							case("Smidgen.TypeDef"):
								auto typedefNode = classElement.children[0];
								if (typedefNode.name == "Smidgen.TypeDefRegular") {
									auto typedef_ = Typedef(typedefNode);
									typedefs ~= typedef_;
								}	
								break;									
							case("Smidgen.Visibility"):
								string visibility = classElement.getNodeText;
								switch (visibility) {
									case("public:"):
										currentVisibility = Visibility.public_;
										break;
									case("protected:"):
										currentVisibility = Visibility.protected_;
										break;
									case("private:"):
										currentVisibility = Visibility.private_;
										break;
									case("signals:"):
										currentVisibility = Visibility.signals_;
										break;
									case("public slots:"):
										currentVisibility = Visibility.public_slots_;
										break;	
									default:
										throw new Exception("Did not recognise visibiity: [" ~ visibility ~ "]");
								}
								break;
							case("Smidgen.TypeHeaderCode"):
								typeHeaderCode = new TypeHeaderCode(classElement);
								break;	
							case("Smidgen.TypeBodyCodeD"):	
								auto typeBodyCodeNode = new EmbeddedCode(classElement);
								typeBodyCodeD = typeBodyCodeNode.toStringC();
								break;		
							case("Smidgen.TypeHeaderCodeD"):	
								auto typeHeaderCodeNode = new EmbeddedCode(classElement);
								typeHeaderCodeD = typeHeaderCodeNode.toStringC();
								break;																	
							case("Smidgen.MethodCodeD"):	
								auto methodCodeD = new EmbeddedCode(classElement);
								currentMethod.setMethodCodeD(methodCodeD.toStringC());
								break;	
							case("Smidgen.DestructorSignature"):
							case("Smidgen.Enum"):
							case("Smidgen.Member"):
							case("Smidgen.Docstring"):
							case("Smidgen.ConvertToSubClassCode"):
							case("Smidgen.MethodCode"):
							case("Smidgen.FinalisationCode"):
							case("Smidgen.IfCode"):
							case("Smidgen.TypeCode"):
							case("Smidgen.ConvertToTypeCode"):
							case("Smidgen.GCTraverseCode"):
							case("Smidgen.GCClearCode"):
							case("Smidgen.GetCode"):
							case("Smidgen.PickleCode"):
							case("Smidgen.Comment"):
								break;																	
							default:
								writeln("ClassElements found " ~ classElement.name ~ 
									" " ~ strip(classElement.input[classElement.begin .. classElement.end]));	
						}
					}
					break;
				default:
				    writeln("Klass found " ~ child.name);	
			}
		}
	}	
	
	/**
	* Return the name of the class, but with INTERFACE_IMPL_SUFFIX appended
	* if this klass is an interface type.
	*/
	@property string implementationName() {
		return wrapAsInterface ? name ~ INTERFACE_IMPL_SUFFIX : name;
	}	
	
	@property Package parentPackage() {
		return _parentPackage ? _parentPackage : parentKlass.parentPackage;
	}	
	
	/**
	* Return the CPP class name such as Rect, Point, Point::Place, QMetaObject::Connection
	*/
	@property string CName() {
		if (parentKlass) {
			return parentKlass.CName ~ "::" ~ name;
		} else {
			return name;
		}
	}
	
	/**
	* Return the D class name such as Rect, Point, Point.Place, QMetaObject.Connection
	*/
	@property string DName() {
		if (parentKlass) {
			return parentKlass.DName ~ "." ~ name;
		} else {
			return name;
		}
	}	
	
	/**
	* Return if the name of this class corresponds to the otherName. Should consider
	* all nested name for this class, e.g. for class Place it will match an otherName
	* of both Place and Point::Place.
	*/
	bool matchesName(string otherName) {
		if (otherName == name) return true;
		if (parentKlass) {
			if (otherName == parentKlass.name ~ "::" ~ name) return true;
			//UGH
			if (parentKlass.parentKlass) {
				if (otherName == 
				 parentKlass.parentKlass.name ~ "::" ~ parentKlass.name ~ "::" ~ name) return true;
				if (parentKlass.parentKlass.parentKlass) {
					// need to implement this etc.
					assert(false);
				}
			}
		}
		if (parentPackage) {
			if (otherName == parentPackage.name ~ "::" ~ name) return true;
			if (parentPackage.parentPackage && parentPackage.parentPackage.name.length > 0) {
				if (otherName == parentPackage.parentPackage.name ~ "::" ~ parentPackage.name ~ "::"~ name) return true;
				if (parentPackage.parentPackage.parentPackage) {
					// need to implement this etc.
					assert(false);
				}	
			}
		}
		return false;
	}
	
	/**
	* If this class or any nested class (recursively) matches the name, then return
	* the matching klass else return null. The 
	* name is qualified CPP style e.g. Place, Point::Place
	*/ 
	Klass getClassOfNameDown(string klassName) {
		if (matchesName(klassName)) {
			return this;
		}
		foreach (nestedKlass; nestedKlasses) {
			Klass matchingKlass = nestedKlass.getClassOfNameDown(klassName);
			if (matchingKlass) {
				return matchingKlass;
			}
		} 
		return null;
	}
	
	/**
	* Return the underlying name after stripping away all the typedefs. E.g. if
	*  typedef X XP;
	*  typedef XP Y;
	* then deTypedefedName("Y") should return "X"; 
	*/
	string deTypedefedName(string name) {
		string deTypedefedName = Typedef.deTypedefedName(typedefs, name);
		if (deTypedefedName == name) {
			if (_parentPackage) {
				return _parentPackage.deTypedefedName(name);
			}
			if (parentKlass) {
				return parentKlass.deTypedefedName(name);
			}	
		}
		return deTypedefedName;
	}
	
	/**
	* Get the klass of the given name, preferring local scope in ambiguous cases. The 
	* name is qualified CPP style e.g. Place, Point::Place
	*/ 
	Klass getClassOfName(string klassName) {
		Klass matchingKlass = getClassOfNameDown(klassName);
		if (matchingKlass) return matchingKlass;
		
		return parentPackage.getClassOfName(klassName);
	}
	
	string getWrappedClassName() {
		if (wrapAsInterface) {
			return name ~ INTERFACE_IMPL_SUFFIX;
		}
		else {
			return name;
		}	
	}
	
	string getWrappedClassNameDotted() {
		if (wrapAsInterface) {
			return name ~ INTERFACE_IMPL_SUFFIX;
		}
		else {
			string thisDottedDName = getClassOfName(name).DName;
			return thisDottedDName;
		}	
	}	
	
	@property bool abstract_() {
		foreach (method; methods) {
			if (method.abstract_) return true;
		}
		return false;
	}
	
	void addMethod(Method method) {
		methods ~= method;
	}	
	
	void addKlass(Klass klass) {
		nestedKlasses ~= klass;
	}		
	
	/**
	* Return the nesting depth of this klass, i.e. 0 for a top level class,
	* 1 for a nested class, 2 for a nested nested class etc.
	*/
	int nestingDepth() {
		if (_parentPackage) {
			return 0;
		} else {
			return parentKlass.nestingDepth + 1;
		}
	}
	
	/**
	* Return if the class is nested inside another
	*/
	bool isNested() {
		return (parentKlass !is null);
	}
	
	Converter[string] getUsedConverters() {
		// index converter by class name to make a set
		Converter[string] converters;
		foreach(method; getAllWrappedMethods()) {
			foreach(argument; method.arguments) {
				CType type = argument.type;
				if (getConverter(type)) {
					Converter converter = getConverter(type);
					converters[converter.getName()] = converter;
				}
			}
			if (! method.constructor) {
				CType type = method.returnType;
				if (getConverter(type)) {
					Converter converter = getConverter(type);
					converters[converter.getName()] = converter;
				}
			}
		}	
		return converters;
	}
	
	Converter getConverter(CType type) {
		assert(getConverterManager);
		return getConverterManager.getConverter(type);
	}
	
	ConverterManager getConverterManager() {
		return parentPackage.getConverterManager;
	}	
	
	string getDestructorFunctionName() {
		return SMID ~ name ~ "_destructor"; 
	}
	
	/**
	* Return all the base methods
	*/
	Method[] getBaseMethods() {
		Method[] baseMethods;
		if (baseClassName == "WrappedObject") {
			return baseMethods;
		}
		Klass baseKlass = getClassOfName(baseClassName);
		baseMethods = baseKlass.methods;
		baseMethods = baseMethods ~ baseKlass.getBaseMethods();
		return baseMethods;
	}
	
	/**
	* Get all the other classes that are referenced from this class, for making the imports
	* list. Include argument types, return types, base classes and inherited interfaces. It
	* should also include a recursively gotten list of referenced classes from any nested classes.
	*/
	Klass[] getReferencedClasses() {
		Klass[] klasses;
		foreach(method; methods) {
			foreach(argument; method.arguments) {
				CType type = argument.type;
				if (type.isWrappedType() || type.isEnum) {
					Klass klass = getClassOfName(type.name);
					if (klass) klasses ~= klass; 
				}
			}
			if (! method.constructor) {
				CType type = method.returnType;
				if (method.returnType.isWrappedType() || type.isEnum) {
					Klass klass = getClassOfName(type.name);
					if (klass) klasses ~= klass; 
				}
			}
		}
		
		Klass baseClass = getClassOfName(baseClassName);
		if (baseClass) klasses ~= baseClass; 
		foreach(interfaceName; interfaceNames) {
			Klass klass = getClassOfName(interfaceName);
			assert(klass);
			klasses ~= klass;
		}
		
		foreach(nestedKlass; nestedKlasses) {
			klasses = klasses ~ nestedKlass.getReferencedClasses();
		}
		return klasses;
	}
	
	/**
	* Return the top level klass, i.e. not the nested klass but its top level klass
	* at package level.
	*/
	@property Klass topLevelKlass() {
		if (parentKlass) {
			return parentKlass.topLevelKlass;
		} else {
			return this;
		}
	}
	
	@property string dottedImportName() {
		if (parentKlass) {
			return parentKlass.dottedImportName ~ "." ~ name;
		} else {
			return parentPackage.dottedImportName ~ "." ~ name;
		}	
	}
	
	string toStringConstructorC() {
		/*
		extern "C" vtkRenderer* vtkRenderer_New() {
		return vtkRenderer::New();
		}
		*/
		string signature = format(
			"extern \"C\" %s* %s_New() {
			return %s::New();
            }\n\n", 
			 name, name, name);
		return signature;
	}
	
	string toStringConstructorD() {
		string signature = format(
		"\tthis() { wrappedObj = %s_New(); 
			registerWrappedObj(this, wrappedObj);}", 
			name);
		return signature;
	}
	
	string toStringExportConstructorD() {
		// extern (C) void* vtkRenderer_New();
		
		if (abstract_) return "\n";
		
		string signature = format("extern (C) void* %s_New();\n\n", name);
		return signature;
	}
	
	string toStringConstructorDWithWrappedObj() {
		// make a D constructor that takes a pre-built wrappedObj
		string signature = 
"	this(void* wrappedObj, CreatedBy createdBy, OwnedBy ownedBy) { 
		super(wrappedObj, createdBy, ownedBy); 
	}\n";
		return signature;
	}
	
	string makeGetCastPointerForInterface() {
		if (interfaceNames.length == 0) {
			return "";
		}
		/*
			void* getCastPointerForInterface(string interfaceName) {
				switch(interfaceName) {
					case("Calculator"):
						return castRectAsCalculator(wrappedObj);
					default:
						break;
				}
				return super.getCastPointerForInterface(interfaceName);
			}
		*/
		string template_ =  
"	override void* getCastPointerForInterface(string interfaceName) {
		switch(interfaceName) {
			%s
			default:
				break;
		}
		return super.getCastPointerForInterface(interfaceName);
	}

";		
		string caseStatement = "case(\"%s\"):
				return cast%sAs%s(wrappedObj);\n";
		string caseStatements;				
		foreach(interfaceName; interfaceNames) {
			caseStatements ~= caseStatement.format(interfaceName, name, interfaceName);
		}				
		return template_.format(caseStatements);
	}
	
	/**
	* Return the extern (C) code that declares the CPP casting functions
	*/ 
	string toStringCastPointers() {
		if (interfaceNames.length == 0) {
			return "";
		}
		string code = "// Extern functions that cast pointers to a super class (used for multiple inheritance)\n";
		string template_ = "extern (C) void* cast%sAs%s(void* wrappedObject);\n";
		foreach(interfaceName; interfaceNames) {
			code ~= template_.format(name, interfaceName);
		}
		return code;
	}
	
	/**
	* Return the CPP code for the functions that cast pointers to a super class
	*/
	string getCastPointersFunctions() {
		/*
			extern "C" QPaintDevice* castQWidgetToQPaintDevice(QWidget* obj) {
			return obj;
			}
		*/
		if (interfaceNames.length == 0) {
			return "";
		} 
		string code = "// Functions that upcast pointers to a base class\n";
		foreach(interfaceName; interfaceNames) {
			string template_ = 
"
extern \"C\" %s* cast%sAs%s(%s* obj) {
	return obj;
}
";			code ~= template_.format(interfaceName, name, interfaceName, name);
		}
		return code;
	}
	
	string toStringMethodsC() {
		string methodsSignature;
		foreach (method; getAllWrappedMethods()) {
			string signature = method.toStringC(this);
			methodsSignature ~= signature;
		}
		return methodsSignature;
	}
	
	
	string getCPPDestructorName() {
		string parentKlassName;
		if (parentKlass) {
			parentKlassName = parentKlass.name ~ "_";
		}
		return "SMI_delete_%s%s_CPPObject".format(parentKlassName, name);
	}
	
	string getCPPWrapperDestructorName() {
		string parentKlassName;
		if (parentKlass) {
			parentKlassName = parentKlass.name ~ "_";
		}		
		return "SMI_delete_%s%s_CPPObject".format(parentKlassName, cppWrapperClassName);
	}	
	
	/**
	* Return the name of the CPP wrapper klass
	*/
	string cppWrapperClassName() {
		return CName.replace("::", "_") ~ CPPWrapperSuffix;
	}
	
	/**
	* Return the CPP code to cal the destructor of objects of this class. 
	*/ 
	string toStringDestructorsC() {
		string template_ = 
"

/*
* Function to delete CPP objects, called from D destructor
*/
extern \"C\" void %s(%s* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern \"C\" void %s(%s* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

";
	return template_.format(getCPPDestructorName, CName,
		 					getCPPWrapperDestructorName, cppWrapperClassName);
	}
	
	
	string toStringDestructorsD() {
		string template_ = 
"
	/**
	* Called from the D destructor, delete the wrapped CPP object if it is
	* owned by D and has not already been deleted by another C++ object.
	*/ 
	override void deleteCPPObject() {
		if (_ownedBy == OwnedBy.D && CPPObjectValid) {
			if (_createdBy == CreatedBy.D) {
				%s(wrappedObj);
			} else {
				%s(wrappedObj);
			}
		}
	}
";
		return template_.format(getCPPWrapperDestructorName(), 
								getCPPDestructorName());
	}
	
	
	/**
	* Create the extern(C) functions that allow virtual D method calls for the wrapped
	* class and its descendents to be called from CPP. e.g.
	*
	*   extern (C) int SMID_Rect_multBy2_SMIX6(void* wrappedObject, int arg0) {
	*        Rect wrappedRect = getWrappedObject!Rect(wrappedObject);
	*        int retVal wrappedRect.multBy2(arg0);
	*        return retVal;
	*   }     
	*/ 
	string toStringDVirtualExports() {
		string DExports;
		foreach(method; getAllWrappedMethods()) {
			if (! method.virtual) continue;
			DExports ~= method.toStringDVirtualExport(this) ~ "\n";
		}
		
		DExports ~= getDestructorVirtualExport() ~ "\n\n";
		
		return DExports;
	}
	
	/**
	* Get the code for a function that is called from the CPP wrapper destructor
	* to register the invalidation of the wrapped CPP object
	*/
	string getDestructorVirtualExport() {
		string template_ = 
"
// This function is called from the destructor of the CPPWrapper
// It is not called when a createdByCPP object is destroyed
extern (C) void %s(void* wrappedObject) {
	%s wrapper = getWrappedObject!(%s)(wrappedObject, false);
	wrapper.cppObjectDeleted();
}
";		
	
	return template_.format(getDestructorFunctionName,
		getWrappedClassNameDotted, getWrappedClassNameDotted);
	}
	
	
	/**
	* Get the string of the D method signatures, used in the interface wrapper
	*/
	string toStringMethodSignaturesD() {
		string methodSignatures = "\n";
		
		foreach (method; getAllWrappedMethods()) {
			if (method.constructor) continue;
			string methodSignature = method.toStringDSignature();
			methodSignatures ~= "\t" ~ methodSignature ~ ";\n\n";
		}
		return methodSignatures;
	}
	
	
	/**
	* Return if the given method is covariant to (overrides) any method
	* in this class or any of its base methods
	*/
	bool isCovariantMethod(Method otherMethod) {
		foreach(method; methods) {
			if (method.overrides(otherMethod)) {
				return true;
			}
		}
		foreach(method; getBaseMethods) {
			if (method.overrides(otherMethod)) {
				return true;
			}
		}		
		return false;
	}
	
	/**
	* Get all methods to be wrapped
	*/
	Method[] getAllWrappedMethods(bool printReason=false) {
		Method[] allKnownMethods = methods.dup;
		Method[] allWrappedMethods;
		
		foreach(interfaceName; interfaceNames) {
			foreach(method; getClassOfName(interfaceName).methods) {
				if (method.constructor) continue;
				if (isCovariantMethod(method)) {
					// we don't include methods from multiply inherited base classes
					// if they are overridden by this class 
					continue;
				}
				allKnownMethods ~= method;
			}
		}
		
		foreach (method; allKnownMethods) {
			string reason;
			if (method.excludeFromWrapping(reason)) {
				if (printReason) {
					writeln(format("Exclude %s from wrapping: %s", 
										method.methodNameC(this), reason));
				}
				continue;
			}
			if (parentPackage.dontWrapDoubleUnderscoreMethods &&
							method.name.length > 1 && method.name[0 .. 2] == "__") {
								
				if (printReason) {
					writeln(format("Exclude %s from wrapping: Not wrapping double-underscore methodss", 
										method.methodNameC(this)));
				}
				continue;
			}
			if (method.constructor && abstract_()) {
				// don't wrap constructors for abstract classes
				if (printReason) {
					writeln(format("Exclude %s from wrapping: Abstract constructor", 
										method.methodNameC(this)));
				}
				continue;
			}							
			allWrappedMethods ~= method;
		}
		return allWrappedMethods;
	}
	
	
	/**
	* Get the string of the D code for this klass
	*/
	string toStringMethodsD() {
		string methodsBody;
		
		foreach (method; getAllWrappedMethods()) {
			string methodBody = method.toStringD(this);
			methodsBody ~= methodBody;
		}
		return methodsBody;
	}
	
	string toStringMethodsDExport() {
		string methodsSignature;
		foreach (method; getAllWrappedMethods(true)) {
			string exportSignature = method.toStringDExport(this);
			methodsSignature ~= exportSignature;
		}
		return methodsSignature;
	}
	
	string toStringDestructorsDExport() {
		string template_ = 
"
// CPP Deleters
extern (C) void %s(void* obj);
extern (C) void %s(void* obj);

";		
		return template_.format(getCPPWrapperDestructorName(), 
								getCPPDestructorName());
	}
	
	override string toString() {
		string methodsRepr = "";
		foreach(method; methods) {
			methodsRepr ~= method.toString() ~ '\n';
		}
		auto repr = format("<Klass %s:%s\n%s>", name, baseClassName, methodsRepr);
		return repr;
	}
}