/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.ast.modules_holder;

import std.stdio: writeln;

import pegged.grammar;

import smidgen.converter: Converter;
import smidgen.converter_manager: ConverterManager;

import smidgen.ast.package_: ModulePackage;
import smidgen.ast.klass: Klass;
import smidgen.ast.other: GetClassNameCCode, GetConvertersDHeaderCode;

/**
* The ModulesHolder class is the top level AST class that contains all the wrapped
* modules.
*/
class ModulesHolder {
	
	ModulePackage[] packages;
	
	string getClassNameCCode;
	string convertersCHeaderCode;
	string convertersDHeaderCode;	
	string[] converterNames;
	ConverterManager converterManager;
	
	bool dontWrapDoubleUnderscoreMethods = false;		
	
	this(ParseTree tree) {
		converterManager = new ConverterManager();
		auto onlyModules = tree.children[0];
		auto modules = onlyModules.children[0];
		foreach(child; modules.children) {
			switch(child.name) {
				case("Smidgen.ModulePackage"):
				    auto package_ = new ModulePackage(child, this);
				    packages ~= package_;
				    break;
				case("Smidgen.Converter"):
					auto converterNameNode = child.children[0];
					auto converterName = 
						strip(converterNameNode.input[converterNameNode.begin .. converterNameNode.end]);
					converterNames ~= converterName;
					break;				
				case("Smidgen.DontWrapDoubleUnderscoreMethods"):
					dontWrapDoubleUnderscoreMethods = true;
					break;
				case("Smidgen.GetClassNameCCode"):
					auto declaration = new GetClassNameCCode(child);
					getClassNameCCode = declaration.toStringC();
					break;
				case("Smidgen.ConvertersDHeaderCode"):
					auto declaration = new GetConvertersDHeaderCode(child);
					convertersDHeaderCode = declaration.toStringC();
					break;	
				case("Smidgen.EmptyLine"):
					break;					    
				default:
					writeln("ModulesHolder found " ~ child.name);
					break;
			}		
		}
	}
	
	Klass[] getAllKlasses() {
		Klass[] allKlasses;

		foreach(package_; packages) {
			allKlasses = allKlasses ~ package_.getAllDescendentKlasses(); 
		}
		return allKlasses;
	}	
	
}