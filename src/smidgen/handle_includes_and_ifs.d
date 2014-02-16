/**
* Take a collection of sip file data and merge it into one sip file, based on
* %Include and %If statements
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/


module smidgen.handle_includes_and_ifs;

import std.string;
import std.array;
import std.path: buildPath, dirName, baseName;
import std.stdio: File, writeln;
import std.algorithm;

import pegged.grammar;

/**
* Merge all the code based on the %Include statements, and include and exclude code according
* to the %If clauses The function string(string, string) sipFileLinesGetter should
* take the file name and directory name, and return a range over the sip file data lines.
*/
string handle_incs_and_ifs(alias sipFileLinesGetter)(string sipFileName,
	 														string workingDirectory) {
	 string result;
	 auto linesGetter = sipFileLinesGetter(sipFileName, workingDirectory);
	 foreach(line; linesGetter) {
//	 	line = strip(line);
	 	if (line.startsWith("%Include")) {
	 			line = line["%Include".length .. $];
	 			if (line.startsWith(")")) {
	 				continue;
	 			}
 				string includedSipFilePath = strip(line).idup;
 				string includedDirectory = includedSipFilePath.dirName;
 				string includedSipFileName = includedSipFilePath.baseName;
 				string includedWorkingDirectory = buildPath(workingDirectory, includedDirectory);
 				result ~= handle_incs_and_ifs!sipFileLinesGetter(includedSipFileName, 
 																	includedWorkingDirectory);
	 		}
	 	else {
	 		result ~= line ~ "\n";
	 	}
	 }
     result = handle_ifs(result);
	 return result;
}


mixin(grammar("
IfHandler:

Section           <- (Feature / Platform / Timeline / Platforms / IfCode /  DeclarationCode / DeclarationLine)* :Sep? endOfInput  
Feature           <- :Sep? :'%Feature' :Sep SymbolName :InLineSep? :NewLine
Platform          <- :Sep? :'%Platform' :Sep SymbolName :InLineSep? :NewLine
Timeline          <- :Sep? :'%Timeline' :Sep? :'{':Sep? SymbolName (:Sep? SymbolName)+ :Sep? :'}' :InLineSep :NewLine
Platforms         <- :Sep? :'%Platforms' :Sep? :'{':Sep? SymbolName (:Sep? SymbolName)+ :Sep? :'}' :InLineSep :NewLine
IfCode            <- :Sep? :'%If' :Sep? IfCondition ~(!NewLine .)* :NewLine (!End (:Sep? IfCode :Sep?) / (:Sep? DeclarationCode :Sep?) / (DeclarationLine))+ :End
IfCondition       <- Range / OredQualifier
Range             <- :Sep? '(' :Sep? VersionId? :Sep? Hyphen :Sep? VersionId? :Sep? ')'
OredQualifier     <- :'(' Qualifier (:Sep? '||' :Sep? Qualifier)* :')'
Qualifier         < ~('!'? :Sep? identifier)
Hyphen            <- '-' 
VersionId         <- identifier
SymbolName        <- identifier
DeclarationCode   <- :Sep? DeclarationName (!End (:Sep? IfCode :Sep?) / (:Sep? DeclarationCode :Sep?) / DeclarationLine )* End
DeclarationName   <- ~(!'%End' '%' identifier) ~(!NewLine .)* :NewLine
DeclarationLine   <- (!End ~(!NewLine .)* NewLine)
End               <- :Sep* '%End' :InLineSep* :NewLine
Sep               <- [ \t\r\n]+
InLineSep         <- [ \t]+
NewLine           <- [\r\n]

"));


string getChildContent(ParseTree child) {
	// also strip off trailing CR if found
	string content = child.input[child.begin .. child.end].stripRight;
	return content;
}


class DeclarationCode {

	private string[] lines;
	Section section;

	this(ParseTree tree, Section section) {
		this.section = section;
		foreach(child; tree.children) {
			switch (child.name) {
				case("IfHandler.DeclarationLine"):
					lines ~= getChildContent(child);
					break;
				case("IfHandler.DeclarationName"):
					lines ~= getChildContent(child);
					break;					
				case("IfHandler.IfCode"):
					auto ifCode = new IfCode(child, section);
					foreach(line; ifCode.getLines()) {
						lines ~= line;
					}
					break;
				case("IfHandler.DeclarationCode"):
					auto declarationCode = new DeclarationCode(child, section);
					foreach(line; declarationCode.getLines()) {
						lines ~= line;
					}
					break;		
				case("IfHandler.End"):
					lines ~= "%End";
					break;					
				default:
					writeln("DeclarationCode found %s".format(child.name));
			}
		}
	}
	
	string[] getLines() {
		return lines;
	}
}

enum IfType {Range, OredQualifier};


class IfCode {
	
	private string[] lines;
	Section section;
		
	string fromVersionId;
	string toVersionId;
	string [] oredValues;
	IfType ifType;
	
	string[] getLines() {
		if (ifType == IfType.Range && toVersionId.length == 0) {
			return lines;
		} else { // OredQualifier
			foreach(oredValue; oredValues) {
				if (! oredValue.startsWith("!") && section.features.canFind(oredValue)) {
					return lines;
				} else if (oredValue.startsWith("!") && 
									! section.features.canFind(oredValue[1 .. $])) {
					return lines;
				}
			
			}
			string empty[];
			return empty;
		}
	}
	
	this(ParseTree tree, Section section) {
		this.section = section;
		foreach(child; tree.children) {
			switch (child.name) {
				case("IfHandler.DeclarationLine"):
					lines ~= getChildContent(child);
					break;
				case("IfHandler.IfCode"):
					auto ifCode = new IfCode(child, section);
					foreach(line; ifCode.getLines()) {
						lines ~= line;
					}
					break;
				case("IfHandler.DeclarationCode"):
					auto declarationCode = new DeclarationCode(child, section);
					foreach(line; declarationCode.getLines()) {
						lines ~= line;
					}
					break;		
				case("IfHandler.IfCondition"):
					auto firstChild = child.children[0];
					if (firstChild.name == "IfHandler.Range") {
						ifType = IfType.Range;
						auto range = firstChild;
						assert(range.children.length >= 2);
						if (range.children[0].name == "IfHandler.VersionId") {
							fromVersionId = getChildContent(range.children[0]);
							if (range.children.length == 3) {
								toVersionId = getChildContent(range.children[2]);
							}
						} else {
							toVersionId = getChildContent(range.children[1]);
						}
					} else if (firstChild.name == "IfHandler.OredQualifier") {
						ifType = IfType.OredQualifier;
						auto oredQualifier = firstChild;
						foreach (qualiferNode; oredQualifier.children) {
							oredValues ~= qualiferNode.getChildContent;
						}
					}	
					break;					
				default:
					writeln("IfCode found %s".format(child.name));
			}
		}
	}
}


class Section {
	
	string[] lines;
	string[] features;
	
	this(ParseTree tree) {
		foreach(child; tree.children) {
			switch (child.name) {
				case("IfHandler.DeclarationLine"):
					lines ~= getChildContent(child);
					break;
				case("IfHandler.Feature"):
					auto feature = getChildContent(child.children[0]);
					features ~= feature;
					break;	
				case("IfHandler.Platform"):
					auto platform = getChildContent(child.children[0]);
					// platform is treated functionally like a feature
					features ~= platform;
					break;						
				case("IfHandler.Platforms"):
					break;										
				case("IfHandler.DeclarationCode"):
					auto declarationCode = new DeclarationCode(child, this);
					foreach(line; declarationCode.getLines()) {
						lines ~= line;
					}
					break;					
				case("IfHandler.IfCode"):
					auto ifCode = new IfCode(child, this);
					foreach(line; ifCode.getLines()) {
						lines ~= line;
					}
					break;
				default:
					writeln("Section found %s".format(child.name));
			}
		}
	}
}

string handle_ifs(string content) {
	ParseTree pt = IfHandler(content);
//	pt.writeln;
	auto section = new Section(pt.children[0]);
	string newContent = section.lines.join("\n");
	return newContent ~"\n";
}


	