/**
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*
*/

module smidgen.ast.overrided_class_method;

import smidgen.ast.method: Method, Argument, CType, Converter, Visibility, ConverterManager;
import smidgen.ast.klass: Klass;

///**
//* The OverridedClassMethod is a Method where its klass
//* is redirected to a different klass to its original. This is used for getting method
//* code declarations for an interface, that is to then be used inside an inheriting class.
//*/
//class OverridedClassMethod: Method {
//	
//	private Klass _overridingClass;
//	private Method _overriddenMethod;
//	
//	this(Klass overridingClass, Method overriddenMethod) {
//		this._overridingClass = overridingClass;
//		this._overriddenMethod = overriddenMethod;
//	}
//	
//	
//	// Method Interface
//	@property bool virtual() {return _overriddenMethod.virtual;}
//	@property bool abstract_() {return _overriddenMethod.abstract_;}
//	@property bool static_() {return _overriddenMethod.static_;}
//	@property bool constructor() {return _overriddenMethod.constructor;}
//	@property bool destructor() {return _overriddenMethod.destructor;}
//	@property bool hasEllipsis() {return _overriddenMethod.hasEllipsis;}
//	@property bool const_() {return _overriddenMethod.const_;}
//	
//	@property Klass klass() {return _overridingClass;}
//	@property Argument[] arguments() {return _overriddenMethod.arguments;}
//	@property Visibility visibility() {return _overriddenMethod.visibility;}
//	@property string name() {return _overriddenMethod.name;}
//	@property CType returnType() {return _overriddenMethod.returnType;}
//	
//	bool excludeFromWrapping(string[] classNames, out string reason) {
//		return _overriddenMethod.excludeFromWrapping(classNames, reason);
//	}
//	string methodNameC() {return _overriddenMethod.methodNameC;}
//	string argumentTypesC() {return _overriddenMethod.argumentTypesC;}
//	Converter getConverter(CType type) {
//		return _overriddenMethod.getConverter(type);
//	}
//	string virtualFunctionNameD() {return _overriddenMethod.virtualFunctionNameD;}
//	override string toString() {return _overriddenMethod.toString;}
//	string toStringC() {return _overriddenMethod.toStringC;}
//	string toStringDVirtualExport() {return _overriddenMethod.toStringDVirtualExport;}
//	string toStringDSignature() {return _overriddenMethod.toStringDSignature;}
//	string toStringD() {return _overriddenMethod.toStringD;}
//	string toStringDExport() {return _overriddenMethod.toStringDExport;}
//	
//	// ConverterManager Interface
//	ConverterManager getConverterManager() {return _overriddenMethod.getConverterManager;}
//	
//}