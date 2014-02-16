/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.parse_converter;

import pegged.grammar;


mixin(grammar("
GConverter:

Declarations      <- (:Sep? Declaration :Sep?)+ endOfInput

Comment           <- :Sep? '//' ~(!NewLine .)* :NewLine

Declaration       <- :Sep? :'%' SymbolName :InLineSep? :NewLine Content  :End
DeclarationLine   <- (!End :Sep? ~(!NewLine .)* NewLine)
End               <- :Sep* :'%End' :InLineSep* :NewLine

Content           <- ~(DeclarationLine*)

SymbolName        <- identifier
String            <- ~(!Sep .)+
Strings           <- (String InLineSep?)+
Sep               <- [ \t\r\n]+
InLineSep         <- [ \t]+
NewLine           <- [\r\n]


"));

	
			
