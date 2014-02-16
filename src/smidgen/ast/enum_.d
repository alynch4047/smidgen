/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.ast.enum_;

import std.string;
import std.stdio;

import pegged.grammar;

import smidgen.ast.package_: Package;
import smidgen.ast.klass: Klass;

class Enum: Klass {
	
	string[] memberNames;
	
	this(ParseTree tree, Package parentPackage) {
		super(parentPackage);
		isEnum = true;
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.EnumTag"):
				    name = strip(child.input[child.begin .. child.end]);
				    break;
				case("Smidgen.SymbolName"):
				    auto memberName = strip(child.input[child.begin .. child.end]);
				    memberNames ~= memberName;
				    break;
				default:
					writeln("Enum found " ~ child.name);
					break;
			}		
		}
	}	
}