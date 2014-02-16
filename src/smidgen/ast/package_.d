/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.ast.package_;

import std.string;
import std.stdio;

import pegged.grammar;

import smidgen.converter: Converter;
import smidgen.converter_manager: ConverterManager;

import smidgen.ast.argument: CType;
import smidgen.ast.enum_: Enum;
import smidgen.ast.klass: Klass;
import smidgen.ast.typedef_: Typedef;
import smidgen.ast.modules_holder: ModulesHolder;
import smidgen.ast.method: Method, MethodImpl;


abstract class Package {
	
	string name;
	Package parentPackage;
	Klass[] klassesAndEnums;
	NamespacePackage[] packages;
	Method[] methods;
	Typedef[] typedefs;
	
	this() {};
	
	void parseTree(ParseTree tree) {	
		int index = 0;
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.Namespace"):
					auto package_ = new NamespacePackage(child, this);
					packages ~= package_;
					break;
				case("Smidgen.Class"):
					auto klass = new Klass(child, this);
					klassesAndEnums ~= klass;
					break;					
				case("Smidgen.Enum"):
					auto enum_ = new Enum(child, this);
					klassesAndEnums ~= enum_;
					break;	
				case("Smidgen.TypeDef"):
					auto typedefNode = child.children[0];
					if (typedefNode.name == "Smidgen.TypeDefRegular") {
						auto typedef_ = Typedef(typedefNode);
						typedefs ~= typedef_;
					}	
					break;						
				case("Smidgen.MethodSignature"):
					methods ~= new MethodImpl(index, child, this);
					index++;
					break;	
				case("Smidgen.Comment"):	
				case("Smidgen.Member"):					
				case("Smidgen.EmptyLine"):
					break;		
				case("Smidgen.Declarations"):
					foreach(decl; child.children) {
						switch(decl.name) {
							case("Smidgen.Comment"):
							case("Smidgen.MethodCode"):
							case("Smidgen.ModuleCode"):
							case("Smidgen.ModuleHeaderCode"):
							case("Smidgen.IncludeDecl"):
							case("Smidgen.PostInitialisationCode"):
							case("Smidgen.InitialisationCode"):
							case("Smidgen.MappedType"):
							case("Smidgen.IfCode"):
							case("Smidgen.Docstring"):
							case("Smidgen.TypeDef"):
							case("Smidgen.TypeHeaderCode"):
								break;																				
							default:
								writeln("Package.Declarations found " ~ decl.name);
						}	
					}
					break;
				default:	
					writeln("Package found " ~ child.name ~ 
									" " ~ strip(child.input[child.begin .. child.end]));	
			}
		}	
	}
	
	@property Enum[] enums() {
		Enum[] enums;
		foreach(klass; klassesAndEnums) {
			if (klass.isEnum) {
				enums ~= cast(Enum) klass;
			}
		}
		return enums;	
	}
	
	@property Klass[] klasses() {
		Klass[] klasses;
		foreach(klass; klassesAndEnums) {
			if (! klass.isEnum) {
				klasses ~=  klass;
			}
		}
		return klasses;	
	}
	
	@property Package modulePackage() {
		if (isModulePackage) {
			return this;
		} else {
			return parentPackage.modulePackage;
		}
	}
	
	bool isModulePackage() {
		return false;
	}
	
	@property bool dontWrapDoubleUnderscoreMethods() {
		return modulePackage.dontWrapDoubleUnderscoreMethods;
	}	
	
	@property ConverterManager converterManager() {
		return modulePackage.converterManager;
	}	
	
	Converter getConverter(CType type) {
		assert(getConverterManager);
		return getConverterManager.getConverter(type);
	}
	
	ConverterManager getConverterManager() {
		return modulePackage.converterManager;
	}
	
	Klass[] getKnownKlasses() {
		return modulePackage.getKnownKlasses();
	}
	
	/**
	* Return the underlying name after stripping away all the typedefs. E.g. if
	*  typedef X XP;
	*  typedef XP Y;
	* then deTypedefedName("Y") should return "X"; 
	*/
	string deTypedefedName(string name) {
		string deTypedefedName = Typedef.deTypedefedName(typedefs, name);
		if (deTypedefedName == name && parentPackage !is null) {
			return parentPackage.deTypedefedName(name);
		}
		return deTypedefedName;
	}	
	
	/**
	* Get the klass of the given name, preferring local scope in ambiguous cases. The 
	* klassName is qualified CPP style e.g. Place, Point::Place
	*/ 
	Klass getClassOfName(string klassName) {
		foreach(klass; klassesAndEnums) {
			Klass matchingKlass = klass.getClassOfNameDown(klassName);
			if (matchingKlass) {
				return matchingKlass;
			}
		}
		if (parentPackage) {
			return parentPackage.getClassOfName(klassName);
		}
		return null;
	}
	
	/**
	* Return all non-nested classes in this package and any descendent pacakges.
	* Nested klasses are found using the getClassOfName
	* mechanism (via getClassOfNameDown) so are not needed here.
	*/ 
	Klass[] getAllDescendentKlasses() {
		Klass[] allModuleKlasses;
		allModuleKlasses = allModuleKlasses ~ klassesAndEnums;
		foreach(package_; packages) {
			allModuleKlasses = 
					allModuleKlasses ~ package_.getAllDescendentKlasses();
		}
		return allModuleKlasses;
	}	
	
	@property string dottedImportName() {
		throw new Exception("Not implemented");
	}
	
	/**
	* Return the D code that declares the typedefs of this package
	*/
	string getStringTypedefsD() {
		string code;
		foreach(typedef_; typedefs) {
			code ~= typedef_.toStringD() ~ "\n";
		}
		return code;
	}
	
	string getStringPackageGlobals() {
	
		string packageGlobalsCode = format("""
/*
* This module will be imported by all D wrapper modules in the package.
*/ 

module %s.package_globals;

""", dottedImportName);
		return packageGlobalsCode;
	}
}


/**
* NamespacePackage only parses the namespace of the Package/Namespace level AST and
* delegates everything else to the base Package class.
*/
class NamespacePackage: Package {
	
	this() {}
	
	this(ParseTree tree, Package parentPackage) {
		this.parentPackage = parentPackage;
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.Package"):
					parseTree(child);
				    break;
				case("Smidgen.SymbolName"):
				    name = strip(child.input[child.begin .. child.end]);
				    break;				    
				default:
					writeln("Namespace found " ~ child.name);
					break;
			}		
		}
	}	
	
	override @property string dottedImportName() {
		assert(parentPackage);
		return parentPackage.dottedImportName() ~ "." ~ name;
	}	
	
	override string getStringPackageGlobals() {
	
		string packageGlobalsCode =	super.getStringPackageGlobals();
		packageGlobalsCode ~= format("""
// Typedefs header code
%s
// End Typedefs header code
""", getStringTypedefsD());
		return packageGlobalsCode;
		
	}	
}


class ModulePackage: NamespacePackage {
	
	string moduleName_;
	ModulesHolder parentModulesHolder;
	
	this(ParseTree tree, ModulesHolder parentModulesHolder) {
		super();
		this.parentModulesHolder = parentModulesHolder;
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.Package"):
				    parseTree(child);
				    break;
				case("Smidgen.ModuleDecl"):
					auto moduleContents = child.children[0];
					auto moduleNameSymbol = moduleContents.children[0];
					moduleName_ = strip(moduleNameSymbol.input[
						 moduleNameSymbol.begin .. moduleNameSymbol.end]);
					break;	
				default:
					writeln("ModulePackage found " ~ child.name);
					break;
			}		
		}
	}
	
	override bool isModulePackage() {
		return true;
	}
	
	override @property string dottedImportName() {
		return moduleName_;
	}
	
	override @property ConverterManager converterManager() {
		return parentModulesHolder.converterManager;
	}
	
	override @property bool dontWrapDoubleUnderscoreMethods() {
		return parentModulesHolder.dontWrapDoubleUnderscoreMethods;
	}	
	
	override Klass[] getKnownKlasses() {
		return parentModulesHolder.getAllKlasses();
	}	
	
	@property string convertersDHeaderCode() {
		return parentModulesHolder.convertersDHeaderCode;
	}	
	
	/**
	* Get the klass of the given name, preferring local scope in ambiguous cases
	*/ 
	override Klass getClassOfName(string klassName) {
		foreach(klass; getKnownKlasses) {
			Klass matchingKlass = klass.getClassOfNameDown(klassName);
			if (matchingKlass) {
				return matchingKlass;
			}
		}
		return null;
	}	
	
	@property string getClassNameCCode() {
		return parentModulesHolder.getClassNameCCode;
	}	
	
	override string getStringPackageGlobals() {
		string packageGlobalsCode =	super.getStringPackageGlobals();
		packageGlobalsCode ~= format("""
// Converters header code
%s
// End converters header code
""", convertersDHeaderCode);
	
		return packageGlobalsCode;
	}
}
