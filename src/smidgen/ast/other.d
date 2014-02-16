/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.ast.other;

import std.string;
import std.stdio: writeln;

import pegged.grammar;

import smidgen.ast.klass: Klass;
import smidgen.ast.method: Method;


class EmbeddedCode {
	
	string[] lines;
	
	this() {}
	
	this(string code) {
	}	
	
	this(ParseTree tree) {
		auto declarationLinesNode = tree.children[0];
		lines = new string[declarationLinesNode.children.length];
		foreach(i, child; declarationLinesNode.children) {
			lines[i] = child.input[child.begin .. child.end];
		}
	}
	
	override string toString() {
		return "<%s %s>".format(this.classinfo.name, lines);
	}
	
	string toStringC() {
		string res = "";
		foreach(line; lines) {
			res ~= line;
		}
		return res;
	}	
}


class TypeHeaderCode: EmbeddedCode {
	this(ParseTree tree) {
		super(tree);
	} 
}

class GetClassNameCCode: EmbeddedCode {
	this(ParseTree tree) {
		super(tree);
	} 	
}

class GetConvertersDHeaderCode: EmbeddedCode {
	this(ParseTree tree) {
		super(tree);
	} 	
}

// Following methods used by tests

string getCStringForMethod(Klass klass, string methodName) {
	foreach(method; klass.methods) {
		if (method.name == methodName) {
			return method.toStringC(klass);
		}
	}
	return null;
}


string getDStringForMethod(Klass klass, string methodName) {
	foreach(method; klass.methods) {
		if (method.name == methodName) {
			return method.toStringD(klass);
		}
	}
	return null;
}


string getDStringExportForMethod(Klass klass, string methodName) {
	foreach(method; klass.methods) {
		if (method.name == methodName) {
			return method.toStringDExport(klass);
		}
	}
	return null;
}

