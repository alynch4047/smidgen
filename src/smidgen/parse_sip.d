/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.parse_sip;

import pegged.grammar;

//  Timeline / Platforms / CToDType /



mixin(grammar("
Smidgen:

OnlyModules            <- Modules endOfInput
OnlyPackage            <- Package endOfInput
Modules                <- (:Comment / ConvertersDHeaderCode / Converter / 
						   GetClassNameCCode / DontWrapDoubleUnderscoreMethods / 
						    CToDType /
						   ModulePackage / EmptyLine )+
CToDType               <- :Sep? '%CToDType' :Sep SymbolName (:Sep? SymbolName)* :Sep? :'=' :Sep? SymbolName :InLineSep? :NewLine 

ModulePackage          <- ModuleDecl Package
Package                <- ((Namespace / Comment /  TypeDef / Declarations / Converter / Enum
 								/ Class / MethodSignature / Member / EmptyLine) :Sep?)* 
Namespace              <- :Sep? 'namespace' :Sep SymbolName :Sep? :'{' :Sep? Package? :Sep? :'}' :Sep? :';'? :Sep?
Unknown                <- (~(!NewLine .)* :NewLine)
TypeDef                <- TypeDefRegular / TypeDefOther
TypeDefRegular         <- :Sep? :'typedef' :Sep TypeDefBase :Sep? TypeDefEnd
TypeDefEnd             <- SymbolName :Sep? :Annotation? :Sep? :';' 
TypeDefBase            <- (Const :Sep)? TypeDefBaseName (:Sep? (Pointer / Reference))*
TypeDefBaseName        <- (!(TypeDefEnd) :Sep? (TemplatedSymbolName / ScopedSymbolName / SymbolName ) :Sep?)+

TypeDefOther           <- :Sep? :'typedef' (~(!NewLine .)* :NewLine)
Converter              <- :Sep? :'%Converter' :Sep ConverterName :NewLine
ConverterName          <-  ~(!NewLine .)* 
EmptyLine              <- InLineSep? NewLine  
Comment                <- :Sep? '//' ~(!NewLine .)* :NewLine
Declarations           <- ((MappedType / AccessCode / TypeHeaderCode / 
 								Docstring / PickleCode / ModuleHeaderCode / ModuleCode /
 								IncludeDecl / MethodCode / IfCode / 
 								InitialisationCode / PostInitialisationCode) :Sep?)+
ModuleDecl             <- :Sep? '%Module' :Sep? ModuleContents :InLineSep? :NewLine
ModuleContents         <- :'(' :Sep? 'name' :Sep? :'=' :Sep? SymbolName :')' 
IncludeDecl            <- :Sep? '%Include' :Sep? IncludeContents :InLineSep? :NewLine
IncludeContents        <- ~(!NewLine .)*
DontWrapDoubleUnderscoreMethods <- '%DontWrapDoubleUnderscoreMethods' :InLineSep? :NewLine
Class                  <- :Sep? ClassTemplateDecl? :Sep? ClassStruct :Sep ClassName  (:Sep? :':' :Sep? BaseClassName (:Sep? :',' :Sep? Interfaces)?)?  :Sep? Annotation? :Sep? :'{' :Sep? ClassElements :Sep? :'}' :';'?
ClassStruct            <- 'class' / 'struct'
ClassName              <- SymbolName
BaseClassName          <- SymbolName
ClassTemplateDecl      <- :Sep? 'template' :Sep? :'<' :Sep? ClassTemplateParameters :Sep?  :'>'
ClassTemplateParameters <- :ClassTemplateParameter (:Sep? :',' :Sep? ClassTemplateParameter)* 
ClassTemplateParameter <- SymbolName
Interfaces             <- :Sep? SymbolName (:Sep? :',' :Sep? SymbolName)* :Sep?
ClassElements          <- (!'}' :Sep? ((Class / Enum / TypeDef / Docstring / FinalisationCode / 
									AccessCode / GCTraverseCode / GCClearCode / GetCode / 
									TypeCode / ConvertToTypeCode / Comment / Visibility / 
									TypeHeaderCode / MethodCodeD / MethodCode /
									TypeBodyCodeD / TypeHeaderCodeD / Member / PickleCode /
									ConvertToSubClassCode / IfCode / ConstructorSignature / 
									DestructorSignature / MethodSignature / EmptyLine / Unknown) :Sep?))*
MethodSignature        <- :Sep? (Static :Sep)? (Virtual :Sep)? ReturnType :Sep? MethodName :Sep?
 							:'(' :Sep? Parameters :Sep? :')' :Sep? MethodConst? 
 								:Sep? Abstract? :Sep? Annotation? :Sep? CPPSignature? :Sep? :';'  
ConstructorSignature   <- :Sep? :Explicit? :Sep? MethodName :Sep? :'(' :Sep? Parameters :Sep? :')' :Sep? Annotation? :Sep? CPPSignature? :Sep? :';' :Sep?
DestructorSignature    <-  :Sep? Virtual? :Sep? '~' MethodName :Sep? :'(' :Sep? :')' :';' :Sep?
MethodName             <- SymbolName  ('=' / '+' / '-' / '/' / '*' / '<' / '>' / '!' / '|' / '[]' / '&' / '~' / '^')*
ReturnType             <- CType
Member                 <- :Sep? (Static :Sep)? (Const :Sep)? CType :Sep? MemberName? :Sep? MemberOptions? :Sep? :';' :Sep?
MemberName             <- SymbolName 
MemberOptions          <- :Sep? :'{' :Sep? ((GetCode / SetCode / AccessCode) :Sep?)* '}'
CPPSignature           <- :'[' CPPSignatureContent :']'
CPPSignatureContent    <- :Sep? ~(!']' .)* :Sep?
Virtual          <- 'virtual'
Static           <- 'static'
Unsigned         <- 'unsigned'
Explicit         <- 'explicit'
Long             <- 'long'
Array            <- '[' Number? ']'
Number           <- ~([0-9]+)
Abstract         <- '=' :Sep? '0'
CType            <- (Const :Sep)? TypeName (:Sep? (Pointer / Reference))*
TypeName         <- (!(MethodName :Sep? '(') :Sep? (TemplatedSymbolName / ScopedSymbolName / SymbolName ) :Sep?)+
Pointer          <- '*'
Reference        <- '&'
Const            <- 'const'
MethodConst      <- 'const'
Enum             <- :Sep? 'enum' :Sep EnumTag :Sep? :'{' ((:Sep? SymbolName :Sep? :','?) / (:Sep? IfCode :Sep?))* :Sep? :'}' :Sep? :';' :Sep?
EnumTag          <- SymbolName
Parameters       <- Parameter? (:Sep? :',' :Sep? Parameter)* 
Parameter        <- (CType :Sep? SymbolName? :Sep? Array? :Sep? Annotation? :Sep? DefaultValue? :Sep?) / (Ellipsis :Sep?)
Ellipsis         <- '...'
Annotation       <- :Sep? :'/' AnnotationContent :'/'
AnnotationContent <- ~(!(NewLine / '/') .)*
DefaultValue     <- :Sep? :'=' :Sep? Value :Sep?
Value            <- (Negative? :Sep? Number) / ScopedSymbolName / InstantiatedClassValue / EnumValue / SymbolName
Negative         <- '-'
InstantiatedClassValue <- SymbolName :Sep? :'(' :Sep? :')'
EnumValue        <- ScopedSymbolName
Visibility        <- ('public:' / 'private:' / 'protected:' / 'signals:' / 'public slots:') :InLineSep? NewLine

MappedType             <- :'%MappedType' :Sep SymbolName :InLineSep? Annotation? :InLineSep? :NewLine :'{' MappedTypeLine+ :'}' :Sep? :';' :NewLine
MappedTypeLine         <- (!'};' ~(!NewLine .)* NewLine)

ConvertersDHeaderCode  <- :'%ConvertersDHeaderCode' DeclarationToEnd
TypeHeaderCode         <- :'%TypeHeaderCode' DeclarationToEnd
ModuleCode             <- :'%ModuleCode' DeclarationToEnd
ModuleHeaderCode       <- :'%ModuleHeaderCode' DeclarationToEnd
ConvertToSubClassCode  <- :'%ConvertToSubClassCode' DeclarationToEnd
TypeBodyCodeD          <- :'%TypeBodyCodeD' DeclarationToEnd
TypeHeaderCodeD        <- :'%TypeHeaderCodeD' DeclarationToEnd
MethodCodeD            <- :'%MethodCodeD' DeclarationToEnd
MethodCode             <- :'%MethodCode' DeclarationToEnd
ConvertToTypeCode <- :'%ConvertToTypeCode' DeclarationToEnd
TypeCode          <- :'%TypeCode' DeclarationToEnd
GCTraverseCode    <- :'%GCTraverseCode' DeclarationToEnd
GCClearCode       <- :'%GCClearCode' DeclarationToEnd
GetCode           <- :'%GetCode' DeclarationToEnd
SetCode           <- :'%SetCode' DeclarationToEnd
Docstring         <- :'%Docstring' DeclarationToEnd
IfCode            <- :'%If' ~(!NewLine .)*  :NewLine ((:Sep? IfCode :Sep?) / DeclarationLine)+ :End
PickleCode        <- :'%PickleCode' DeclarationToEnd
AccessCode        <- :'%AccessCode' DeclarationToEnd
FinalisationCode <- :'%FinalisationCode' DeclarationToEnd
InitialisationCode <- :'%InitialisationCode' DeclarationToEnd
PostInitialisationCode <- :'%PostInitialisationCode' DeclarationToEnd
GetClassNameCCode <- :Sep? :'%GetClassNameCCode' DeclarationToEnd
DeclarationLine   <- (!End ~(!NewLine .)* NewLine)
End               <- :Sep* :'%End' :InLineSep* :NewLine
DeclarationToEnd  <- :InLineSep? :NewLine DeclarationLine+ :End
SymbolName        <- identifier
ScopedSymbolName  <- ~(identifier '::' identifier)
TemplatedSymbolName <- ~(SymbolName :Sep? '<' :Sep? (ScopedSymbolName / SymbolName) :Sep? '>')
String            <- ~(!Sep .)+
Strings           <- (String InLineSep?)+
Sep               <- [ \t\r\n]+
InLineSep         <- [ \t]+
NewLine           <- [\r\n]


"));

	
			
