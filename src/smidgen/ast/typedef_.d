
/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013, 2014
* License: GPL v2
*/
module smidgen.ast.typedef_;

import pegged.grammar;

import std.stdio: writeln;
import std.string: format, detab, squeeze;


string tidyWhiteSpace(string str) {
	return str.detab.squeeze(" ").strip;
}

/**
* The Typedef struct represents a typedef statement in a sip file.
*/
struct Typedef {
	
	private string _baseTypeName;
	private string _aliasTypeName;
	
	this(string baseTypeName, string aliasTypeName) {
		this.baseTypeName = baseTypeName;
		this.aliasTypeName = aliasTypeName;
	}
	
	@property string baseTypeName() {
		return _baseTypeName;
	}
	
	@property void baseTypeName(string name) {
		_baseTypeName = tidyWhiteSpace(name);
	}	
	
	@property string aliasTypeName() {
		return _aliasTypeName;
	}
	
	@property void aliasTypeName(string name) {
		_aliasTypeName = tidyWhiteSpace(name);
	}		
	
	this(ParseTree tree) {
		
		foreach(child; tree.children) {
			switch(child.name) {
				case("Smidgen.TypeDefBase"):
					auto baseNameNode = child.children[0];
				    baseTypeName = strip(baseNameNode.input[baseNameNode.begin .. baseNameNode.end]);
				    break;
				case("Smidgen.TypeDefEnd"):
					auto aliasTypeNameNode = child.children[0];
				    aliasTypeName = strip(aliasTypeNameNode.input[aliasTypeNameNode.begin .. aliasTypeNameNode.end]);
				    break;
				default:
					writeln("Typedef found " ~ child.name ~ 
							" " ~ strip(child.input[child.begin .. child.end]));
					break;
			}		
		}
	}		
	
	/**
	* Return the D representation of this typedef. Convert C++ primitive types to the
	* correct D primitive types for this platform. 
	*/
	string toStringD() {
		return "alias %s %s;".format(baseTypeName, aliasTypeName);
	}
	
	/**
	* Return the underlying name after stripping away all the typedefs. E.g. if
	*  typedef X XP;
	*  typedef XP Y;
	* then deTypedefedName("Y") should return "X"; 
	*
	* Params: 
	*   inScopeTypedefs = those Typedefs that are in scope at the calling point 
	*/	
	static string deTypedefedName(Typedef[] inScopeTypedefs, string name) {
		string underlyingTypeName = name;
		bool changed;
		do {
			changed = false;
			foreach (typedef_; inScopeTypedefs) {
				if (typedef_.aliasTypeName == underlyingTypeName) {
					underlyingTypeName = typedef_.baseTypeName;
					changed = true;
				}
			}
		} while (changed);
		return underlyingTypeName;
	}
	
}