/**
Parser generation module for Pegged.
The Pegged parser itself is in pegged.parser, generated from pegged.examples.peggedgrammar.

The documentation is in the /docs directory.
*/
module pegged.grammar;

import std.algorithm: startsWith;
import std.conv: to;
import std.functional: toDelegate;
import std.stdio;

public import pegged.peg;
//public import pegged.introspection;
import pegged.parser;



/**
Option enum to get internal memoization (parse results storing).
*/
enum Memoization { no, yes }

/**
This function takes a (future) module name, a (future) file name and a grammar as a string or a file.
It writes the corresponding parser inside a module with the given name.
*/
void asModule(Memoization withMemo = Memoization.yes)(string moduleName, string fileName, string grammarString, string optHeader = "")
{
    import std.stdio;
    auto f = File(fileName ~ ".d","w");

    f.write("/++\nThis module was automatically generated from the following grammar:\n\n");
    f.write(grammarString);
    f.write("\n\n+/\n");

    f.write("module " ~ moduleName ~ ";\n\n");

    if (optHeader.length > 0)
        f.write(optHeader ~ "\n\n");

    f.write("public import pegged.peg;\n");
    f.write("import std.algorithm: startsWith;\n");
    f.write("import std.functional: toDelegate;\n\n");
    f.write(grammar!(withMemo)(grammarString));
}

/// ditto
void asModule(Memoization withMemo = Memoization.yes)(string moduleName, File file, string optHeader = "")
{
    string grammarDefinition;
    foreach(line; file.byLine)
    {
        grammarDefinition ~= line ~ '\n';
    }
    asModule!(withMemo)(moduleName, grammarDefinition, optHeader);
}

// Helper to insert 'Spacing' before and after Primaries
ParseTree spaceArrow(ParseTree input)
{
    ParseTree wrapInSpaces(ParseTree p)
    {
        ParseTree spacer =
        ParseTree("Pegged.Prefix", true, null, null, 0,0, [
            ParseTree("Pegged.Suffix", true, null, null, 0, 0, [
                ParseTree("Pegged.Primary", true, null, null, 0, 0, [
                    ParseTree("Pegged.RhsName", true, null, null, 0,0, [
                        ParseTree("Pegged.Identifier", true, ["Spacing"])
                    ])
                ])
            ])
        ]);
        ParseTree result = ParseTree("Pegged.WrapAround", true, p.matches, p.input, p.begin, p.end, p.children);
        result.children = spacer ~ result.children ~ spacer;
        return result;
    }
    return modify!( p => p.name == "Pegged.Primary",
                    wrapInSpaces)(input);
}


/**
Generate a parser from a PEG definition.
The parser is a string containing D code, to be mixed in or written in a file.

----
enum string def = "
Gram:
    A <- 'a' B*
    B <- 'b' / 'c'
";

mixin(grammar(def));

ParseTree p = Gram("abcbccbcd");
----
*/
string grammar(Memoization withMemo = Memoization.yes)(string definition)
{
    ParseTree defAsParseTree = Pegged(definition);

    if (!defAsParseTree.successful)
    {
        // To work around a strange bug with ParseTree printing at compile time
        string result = "static assert(false, `" ~ defAsParseTree.toString("") ~ "`);";
        return result;
    }

    string generateCode(ParseTree p, string propagatedName = "")
    {
        string result;

        switch (p.name)
        {
            case "Pegged":
                result = generateCode(p.children[0]);
                break;
            case "Pegged.Grammar":
                string grammarName = generateCode(p.children[0]);
                string shortGrammarName = p.children[0].matches[0];
                //string invokedGrammarName = generateCode(transformName(p.children[0]));
                string firstRuleName = generateCode(p.children[1].children[0]);

                result =
"struct Generic" ~ shortGrammarName ~ "(TParseTree)
{
    import pegged.dynamic.grammar;
    struct " ~ grammarName ~ "\n    {
    enum name = \"" ~ shortGrammarName ~ "\";
    static ParseTree delegate(ParseTree)[string] before;
    static ParseTree delegate(ParseTree)[string] after;
    static ParseTree delegate(ParseTree)[string] rules;

    static this()\n    {\n";

                ParseTree[] definitions = p.children[1 .. $];
                bool userDefinedSpacing;
                foreach(i,def; definitions)
                {
                    if (def.children[0].children.length == 1) // Non-parameterized ruleName
                        result ~= "        rules[\"" ~ def.matches[0] ~ "\"] = toDelegate(&" ~ shortGrammarName ~ "." ~ def.matches[0] ~ ");\n";
                    if (def.matches[0] == "Spacing") // user-defined spacing
                    {
                        userDefinedSpacing = true;
                        break;
                    }
                }
                if(!userDefinedSpacing)
                    result ~= "        rules[\"Spacing\"] = toDelegate(&" ~ shortGrammarName ~ ".Spacing);\n";

                result ~=
"   }

    template hooked(alias r, string name)
    {
        static ParseTree hooked(ParseTree p)
        {
            ParseTree result;

            if (name in before)
            {
                result = before[name](p);
                if (result.successful)
                    return result;
            }

            result = r(p);
            if (result.successful || name !in after)
                return result;

            result = after[name](p);
            return result;
        }

        static ParseTree hooked(string input)
        {
            return hooked!(r, name)(ParseTree(\"\",false,[],input));
        }
    }

    static void addRuleBefore(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar name
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ \": \" ~ ruleSyntax, rules);
        foreach(ruleName,rule; dg.rules)
            if (ruleName != \"Spacing\") // Keep the local Spacing rule, do not overwrite it
                rules[ruleName] = rule;
        before[parentRule] = rules[dg.startingRule];
    }

    static void addRuleAfter(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar named
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ \": \" ~ ruleSyntax, rules);
        foreach(name,rule; dg.rules)
        {
            if (name != \"Spacing\")
                rules[name] = rule;
        }
        after[parentRule] = rules[dg.startingRule];
    }

    static bool isRule(string s)
    {
        return s.startsWith(\"" ~ shortGrammarName ~ ".\");
    }
";

                    if (withMemo == Memoization.yes)
                    result ~=
"    import std.typecons:Tuple, tuple;
    static TParseTree[Tuple!(string, size_t)] memo;\n";

                /+
                        ~ "        switch(s)\n"
                        ~ "        {\n";

                bool[string] ruleNames; // to avoid duplicates, when using parameterized rules
                string parameterizedRulesSpecialCode; // because param rules need to be put in the 'default' part of the switch

                string paramRuleHandler(string target)
                {
                    return "if (s.length >= "~to!string(shortGrammarName.length + target.length + 3)
                          ~" && s[0.."~to!string(shortGrammarName.length + target.length + 3)~"] == \""
                          ~shortGrammarName ~ "." ~ target~"!(\") return true;";
                }

                foreach(i,def; definitions)
                {
                    /+
                    if (def.matches[0] !in ruleNames)
                    {
                        ruleNames[def.matches[0]] = true;

                        if (def.children[0].children.length > 1) // Parameterized rule
                            parameterizedRulesSpecialCode ~= "                " ~ paramRuleHandler(def.matches[0])~ "\n";
                        else
                            result ~= "            case \"" ~ shortGrammarName ~ "." ~ def.matches[0] ~ "\":\n";
                    }
                    +/
                    if (def.matches[0] == "Spacing") // user-defined spacing
                    {
                        userDefinedSpacing = true;
                        break;
                    }
                }
                result ~= "                return true;\n"
                        ~ "            default:\n"
                        ~ parameterizedRulesSpecialCode
                        ~ "                return false;\n        }\n    }\n";
                +/
                result ~= "    mixin decimateTree;\n";

                // If the grammar provides a Spacing rule, then this will be used.
                // else, the predefined 'spacing' rule is used.
                result ~= userDefinedSpacing ? "" : "    alias spacing Spacing;\n\n";

                // Creating the inner functions, each corresponding to a grammar rule
                foreach(def; definitions)
                    result ~= generateCode(def, shortGrammarName);

                // if the first rule is parameterized (a template), it's impossible to get an opCall
                // because we don't know with which template arguments it should be called.
                // So no opCall is generated in this case.
                if (p.children[1].children[0].children.length == 1)
                {
                    // General calling interface
                    result ~= "    static TParseTree opCall(TParseTree p)\n"
                           ~  "    {\n"
                           ~  "        TParseTree result = decimateTree(" ~ firstRuleName ~ "(p));\n"
                           ~  "        result.children = [result];\n"
                           ~  "        result.name = \"" ~ shortGrammarName ~ "\";\n"
                           ~  "        return result;\n"
                           ~  "    }\n\n"
                           ~  "    static TParseTree opCall(string input)\n"
                           ~  "    {\n";

                    if (withMemo == Memoization.no)
                        result ~= "        return " ~ shortGrammarName ~ "(TParseTree(``, false, [], input, 0, 0));\n"
                               ~  "}\n";
                    else
                        result ~= "        if(__ctfe)\n"
                               ~  "        {\n"
                               ~  "            return " ~ shortGrammarName ~ "(TParseTree(``, false, [], input, 0, 0));\n"
                               ~  "        }\n"
                               ~  "        else\n"
                               ~  "        {\n"
                               ~  "            memo = null;\n"
                               ~  "            return " ~ shortGrammarName ~ "(TParseTree(``, false, [], input, 0, 0));\n"
                               ~  "        }\n"
                               ~  "    }\n";

                    result ~= "    static string opCall(GetName g)\n"
                            ~ "    {\n"
                            ~ "        return \"" ~ shortGrammarName ~ "\";\n"
                            ~ "    }\n\n";
                }
                result ~= "    }\n" // end of grammar struct definition
                        ~ "}\n\n" // end of template definition
                        ~ "alias Generic" ~ shortGrammarName ~ "!(ParseTree)."
                        ~ shortGrammarName ~ " " ~ shortGrammarName ~ ";\n\n";
                break;
            case "Pegged.Definition":
                // children[0]: name
                // children[1]: arrow (arrow type as first child)
                // children[2]: description

                string code;

                switch(p.children[1].children[0].name)
                {
                    case "Pegged.LEFTARROW":
                        code ~= generateCode(p.children[2]);
                        break;
                    case "Pegged.FUSEARROW":
                        code ~= "pegged.peg.fuse!(" ~ generateCode(p.children[2]) ~ ")";
                        break;
                    case "Pegged.DISCARDARROW":
                        code ~= "pegged.peg.discard!(" ~ generateCode(p.children[2]) ~ ")";
                        break;
                    case "Pegged.KEEPARROW":
                        code ~= "pegged.peg.keep!("~ generateCode(p.children[2]) ~ ")";
                        break;
                    case "Pegged.DROPARROW":
                        code ~= "pegged.peg.drop!("~ generateCode(p.children[2]) ~ ")";
                        break;
                    case "Pegged.PROPAGATEARROW":
                        code ~= "pegged.peg.propagate!("~ generateCode(p.children[2]) ~ ")";
                        break;
                    case "Pegged.SPACEARROW":
                        ParseTree modified = spaceArrow(p.children[2]);
                        code ~= generateCode(modified);
                        break;
                    case "Pegged.ACTIONARROW":
                        auto actionResult = generateCode(p.children[2]);
                        foreach(action; p.children[1].matches[1..$])
                            actionResult = "pegged.peg.action!(" ~ actionResult ~ ", " ~ action ~ ")";
                        code ~= actionResult;
                        break;
                    default:
                        break;
                }

                bool parameterizedRule = p.children[0].children.length > 1;
                string completeName = generateCode(p.children[0]);
                string shortName = p.matches[0];
                string innerName;
                string hookedName = p.matches[0];

                if (parameterizedRule)
                {
                    result =  "    template " ~ completeName ~ "\n"
                            ~ "    {\n";
                    innerName ~= "\"" ~ shortName ~ "!(\" ~ ";
                    hookedName ~= "_" ~ to!string(p.children[0].children[1].children.length);
                    foreach(i,param; p.children[0].children[1].children)
                        innerName ~= "pegged.peg.getName!("~ param.children[0].matches[0]
                                    ~ (i<p.children[0].children[1].children.length-1 ? ")() ~ \", \" ~ "
                                                                                     : ")");
                    innerName ~= " ~ \")\"";
                }
                else
                {
                    innerName ~= "`" ~ completeName ~ "`";
                }

                string ctfeCode = "        pegged.peg.named!(" ~ code ~ ", \"" ~ propagatedName ~ "." ~ innerName[1..$-1] ~ "\")";
                code =            "hooked!(pegged.peg.named!(" ~ code ~ ", \"" ~ propagatedName ~ "." ~ innerName[1..$-1] ~ "\"), \"" ~ hookedName  ~ "\")";

                if (withMemo == Memoization.no)
                    result ~= "    static TParseTree " ~ shortName ~ "(TParseTree p)\n"
                           ~  "    {\n"
                           ~  "        if(__ctfe)\n"
                           ~  "            return " ~ ctfeCode ~ "(p);\n"
                           ~  "        else\n"
                           ~  "            return " ~ code ~ "(p);\n"
                           ~  "    }\n"
                           ~  "    static TParseTree " ~ shortName ~ "(string s)\n"
                           ~  "    {\n"
                           ~  "        if(__ctfe)\n"
                           ~  "            return " ~ ctfeCode ~ "(TParseTree(\"\", false,[], s));\n"
                           ~  "        else\n"
                           ~  "            return " ~ code ~ "(TParseTree(\"\", false,[], s));\n"
                           ~  "    }\n";
                else
                    result ~= "    static TParseTree " ~ shortName ~ "(TParseTree p)\n"
                           ~  "    {\n"
                           ~  "        if(__ctfe)\n"
                           ~  "        {\n"
                           ~  "            return " ~ ctfeCode ~ "(p);\n"
                           ~  "        }\n"
                           ~  "        else\n"
                           ~  "        {\n"
                           ~  "            if(auto m = tuple("~innerName~",p.end) in memo)\n"
                           ~  "                return *m;\n"
                           ~  "            else\n"
                           ~  "            {\n"
                           ~  "                TParseTree result = " ~ code ~ "(p);\n"
                           ~  "                memo[tuple("~innerName~",p.end)] = result;\n"
                           ~  "                return result;\n"
                           ~  "            }\n"
                           ~  "        }\n"
                           ~  "    }\n\n"
                           ~  "    static TParseTree " ~ shortName ~ "(string s)\n"
                           ~  "    {\n"
                           ~  "        if(__ctfe)\n"
                           ~  "        {\n"
                           ~  "            return " ~ ctfeCode ~ "(TParseTree(\"\", false,[], s));\n"
                           ~  "        }\n"
                           ~  "        else\n"
                           ~  "        {\n"
                           ~  "            memo = null;\n"
                           ~  "            return " ~ code ~ "(TParseTree(\"\", false,[], s));\n"
                           ~  "        }\n"
                           ~  "    }\n";

                    result ~= "    static string " ~ shortName ~ "(GetName g)\n"
                           ~  "    {\n"
                           ~  "        return \"" ~ propagatedName ~ "." ~ innerName[1..$-1] ~ "\";\n"
                           ~  "    }\n\n";

                if (parameterizedRule)
                    result ~= "    }\n";

                break;
            case "Pegged.GrammarName":
                result = generateCode(p.children[0]);
                if (p.children.length == 2)
                    result ~= generateCode(p.children[1]);
                break;
            case "Pegged.LhsName":
                result = generateCode(p.children[0]);
                if (p.children.length == 2)
                    result ~= generateCode(p.children[1]);
                break;
            case "Pegged.ParamList":
                result = "(";
                foreach(i,child; p.children)
                    result ~= generateCode(child) ~ ", ";
                result = result[0..$-2] ~ ")";
                break;
            case "Pegged.Param":
                result = "alias " ~ generateCode(p.children[0]);
                break;
            case "Pegged.SingleParam":
                result = p.matches[0];
                break;
            case "Pegged.DefaultParam":
                result = p.matches[0] ~ " = " ~ generateCode(p.children[1]);
                break;
            case "Pegged.Expression":
                if (p.children.length > 1) // OR expression
                {
                    // Keyword list detection: "abstract"/"alias"/...
                    bool isLiteral(ParseTree p)
                    {
                        return ( p.name == "Pegged.Sequence"
                              && p.children.length == 1
                              && p.children[0].children.length == 1
                              && p.children[0].children[0].children.length == 1
                              && p.children[0].children[0].children[0].children.length == 1
                              && p.children[0].children[0].children[0].children[0].name == "Pegged.Literal");
                    }
                    bool keywordList = true;
                    foreach(child;p.children)
                        if (!isLiteral(child))
                        {
                            keywordList = false;
                            break;
                        }

                    if (keywordList)
                    {
                        result = "pegged.peg.keywords!(";
                        foreach(seq; p.children)
                            result ~= "\"" ~ (seq.matches.length == 3 ? seq.matches[1] : "") ~ "\", ";
                        result = result[0..$-2] ~ ")";
                    }
                    else
                    {
                        result = "pegged.peg.or!(";
                        foreach(seq; p.children)
                            result ~= generateCode(seq) ~ ", ";
                        result = result[0..$-2] ~ ")";
                    }
                }
                else // One child -> just a sequence, no need for a or!( , )
                {
                    result = generateCode(p.children[0]);
                }
                break;
            case "Pegged.Sequence":
                if (p.children.length > 1) // real sequence
                {
                    result = "pegged.peg.and!(";
                    foreach(seq; p.children)
                    {
                        string elementCode = generateCode(seq);
                        // flattening inner sequences
                        if (elementCode.length > 6 && elementCode[0..5] == "pegged.peg.and!(")
                            elementCode = elementCode[5..$-1]; // cutting 'and!(' and ')'
                        result ~= elementCode ~ ", ";
                    }
                    result = result[0..$-2] ~ ")";
                }
                else // One child -> just a Suffix, no need for a and!( , )
                {
                    result = generateCode(p.children[0]);
                }
                break;
            case "Pegged.Prefix":
                result = generateCode(p.children[$-1]);
                foreach(child; p.children[0..$-1])
                    result = generateCode(child) ~ result ~ ")";
                break;
            case "Pegged.Suffix":
                result = generateCode(p.children[0]);
                foreach(child; p.children[1..$])
                {
                    switch (child.name)
                    {
                        case "Pegged.OPTION":
                            result = "pegged.peg.option!(" ~ result ~ ")";
                            break;
                        case "Pegged.ZEROORMORE":
                            result = "pegged.peg.zeroOrMore!(" ~ result ~ ")";
                            break;
                        case "Pegged.ONEORMORE":
                            result = "pegged.peg.oneOrMore!(" ~ result ~ ")";
                            break;
                        case "Pegged.Action":
                            foreach(action; child.matches)
                                result = "pegged.peg.action!(" ~ result ~ ", " ~ action ~ ")";
                            break;
                        default:
                            break;
                    }
                }
                break;
            case "Pegged.Primary":
                result = generateCode(p.children[0]);
                break;
            case "Pegged.RhsName":
                result = "";
                foreach(i,child; p.children)
                    result ~= generateCode(child);
                break;
            case "Pegged.ArgList":
                result = "!(";
                foreach(child; p.children)
                    result ~= generateCode(child) ~ ", "; // Allow  A <- List('A'*,',')
                result = result[0..$-2] ~ ")";
                break;
            case "Pegged.Identifier":
                result = p.matches[0];
                break;
            case "Pegged.NAMESEP":
                result = ".";
                break;
            case "Pegged.Literal":
                if(p.matches.length == 3) // standard case
                    result = "pegged.peg.literal!(\"" ~ p.matches[1] ~ "\")";
                else // only two children -> empty literal
                    result = "pegged.peg.literal!(``)";
                break;
            case "Pegged.CharClass":
                if (p.children.length > 1)
                {
                    result = "pegged.peg.or!(";
                    foreach(seq; p.children)
                        result ~= generateCode(seq) ~ ", ";
                    result = result[0..$-2] ~ ")";
                }
                else // One child -> just a sequence, no need for a or!( , )
                {
                    result = generateCode(p.children[0]);
                }
                break;
            case "Pegged.CharRange":
                /// Make the generation at the Char level: directly what is needed, be it `` or "" or whatever
                if (p.children.length > 1) // a-b range
                {
                    result = "pegged.peg.charRange!('" ~ generateCode(p.children[0])
                                                       ~ "', '"
                                                       ~ generateCode(p.children[1])
                                                       ~ "')";
                }
                else // lone char
                {
                    result = "pegged.peg.literal!(";
                    string ch = p.matches[0];
                    switch (ch)
                    {
                        case "\\[":
                        case "\\]":
                        case "\\-":
                            result ~= "\""  ~ ch[1..$] ~ "\")";
                            break;
                        case "\\\'":
                            result ~= "\"'\")";
                            break;
                        case "\\`":
                            result ~= q{"`")};
                            break;
                        case "\\":
                        case "\\\\":
                            result ~= "`\\`)";
                            break;
                        case "\"":
                        case "\\\"":
                            result ~= "`\"`)";
                            break;
                        case "\n":
                        case "\r":
                        case "\t":
                            result ~= "\"" ~ to!string(to!dchar(ch)) ~ "\")";
                            break;
                        default:
                            result ~= "\"" ~ ch ~ "\")";
                    }
                }
                break;
            case "Pegged.Char":
                string ch = p.matches[0];
                switch (ch)
                {
                    case "\\[":
                    case "\\]":
                    case "\\-":

                    case "\\\'":
                    case "\\\"":
                    case "\\`":
                    case "\\\\":
                        result = ch[1..$];
                        break;
                    case "\n":
                    case "\r":
                    case "\t":
                        result = to!string(to!dchar(ch));
                        break;
                    default:
                        result = ch;
                }
                break;
            case "Pegged.POS":
                result = "pegged.peg.posLookahead!(";
                break;
            case "Pegged.NEG":
                result = "pegged.peg.negLookahead!(";
                break;
            case "Pegged.FUSE":
                result = "pegged.peg.fuse!(";
                break;
            case "Pegged.DISCARD":
                result = "pegged.peg.discard!(";
                break;
            //case "Pegged.CUT":
            //    result = "discardChildren!(";
            //    break;
            case "Pegged.KEEP":
                result = "pegged.peg.keep!(";
                break;
            case "Pegged.DROP":
                result = "pegged.peg.drop!(";
                break;
            case "Pegged.PROPAGATE":
                result = "pegged.peg.propagate!(";
                break;
            case "Pegged.OPTION":
                result = "pegged.peg.option!(";
                break;
            case "Pegged.ZEROORMORE":
                result = "pegged.peg.zeroOrMore!(";
                break;
            case "Pegged.ONEORMORE":
                result = "pegged.peg.oneOrMore!(";
                break;
            case "Pegged.Action":
                result = generateCode(p.children[0]);
                foreach(action; p.matches[1..$])
                    result = "pegged.peg.action!(" ~ result ~ ", " ~ action ~ ")";
                break;
            case "Pegged.ANY":
                result = "pegged.peg.any";
                break;
            case "Pegged.WrapAround":
                result = "pegged.peg.wrapAround!(" ~ generateCode(p.children[0]) ~ ", "
                                                   ~ generateCode(p.children[1]) ~ ", "
                                                   ~ generateCode(p.children[2]) ~ ")";
                break;
            default:
                result = "Bad tree: " ~ p.toString();
                break;
        }
        return result;
    }



    return generateCode(defAsParseTree);
}

/**
Mixin to get what a failed rule expected as input.
Not used by Pegged yet.
*/
mixin template expected()
{
    string expected(ParseTree p)
    {

        switch(p.name)
        {
            case "Pegged.Expression":
                string expectation;
                foreach(i, child; p.children)
                    expectation ~= "(" ~ expected(child) ~ ")" ~ (i < p.children.length -1 ? " or " : "");
                return expectation;
            case "Pegged.Sequence":
                string expectation;
                foreach(i, expr; p.children)
                    expectation ~= "(" ~ expected(expr) ~ ")" ~ (i < p.children.length -1 ? " followed by " : "");
                return expectation;
            case "Pegged.Prefix":
                return expected(p.children[$-1]);
            case "Pegged.Suffix":
                string expectation;
                string end;
                foreach(prefix; p.children[1..$])
                    switch(prefix.name)
                    {
                        case "Pegged.ZEROORMORE":
                            expectation ~= "zero or more times (";
                            end ~= ")";
                            break;
                        case "Pegged.ONEORMORE":
                            expectation ~= "one or more times (";
                            end ~= ")";
                            break;
                        case "Pegged.OPTION":
                            expectation ~= "optionally (";
                            end ~= ")";
                            break;
                        case "Pegged.Action":
                            break;
                        default:
                            break;
                    }
                return expectation ~ expected(p.children[0]) ~ end;
            case "Pegged.Primary":
                return expected(p.children[0]);
            //case "Pegged.RhsName":
            //    return "RhsName, not implemented.";
            case "Pegged.Literal":
                return "the literal `" ~ p.matches[0] ~ "`";
            case "Pegged.CharClass":
                string expectation;
                foreach(i, child; p.children)
                    expectation ~= expected(child) ~ (i < p.children.length -1 ? " or " : "");
                return expectation;
            case "Pegged.CharRange":
                if (p.children.length == 1)
                    return expected(p.children[0]);
                else
                    return "any character between '" ~ p.matches[0] ~ "' and '" ~ p.matches[2] ~ "'";
            case "Pegged.Char":
                return "the character '" ~ p.matches[0] ~ "'";
            case "Pegged.ANY":
                return "any character";
            default:
                return "unknow rule (" ~ p.matches[0] ~ ")";
        }
    }
}

unittest // 'grammar' unit test: low-level functionalities
{
    mixin(grammar(`
    Test1:
        Rule1 <- 'a'
        Rule2 <- 'b'
    `));

    assert(is(Test1 == struct), "A struct name Test1 is created.");
    assert(is(typeof(Test1("a"))), "Test1 is callable with a string arg");
    assert(__traits(hasMember, Test1, "Rule1"), "Test1 has a member named Rule1.");
    assert(__traits(hasMember, Test1, "Rule2"), "Test1 has a member named Rule2.");
    assert(is(typeof(Test1.Rule1("a"))), "Test1.Rule1 is callable with a string arg");
    assert(is(typeof(Test1.Rule2("a"))), "Test1.Rule2 is callable with a string arg");

    assert(__traits(hasMember, Test1, "decimateTree"), "Test1 has a member named decimateTree.");
    assert(__traits(hasMember, Test1, "name"), "Test1 has a member named name.");
    assert(__traits(hasMember, Test1, "isRule"), "Test1 has a member named isRule.");
}

unittest // 'grammar' unit test: PEG syntax
{
    // Here we do not test pegged.peg.*, just the grammar transformations
    // From a PEG to a Pegged expression template.

    mixin(grammar(`
    Terminals:
        Literal1 <- "abc"
        Literal2 <- 'abc'
        EmptyLiteral1 <- ""
        EmptyLiteral2 <- ''

        Any    <- .
        Eps    <- eps
        Letter <- [a-z]
        Digit  <- [0-9]
        ABC    <- [abc]
        Alpha1 <- [a-zA-Z_]
        Alpha2 <- [_a-zA-Z]
        Chars1 <- [\0-\127]
        Chars2 <- [\x00-\xFF]
        Chars3 <- [\u0000-\u00FF]
        Chars4 <- [\U00000000-\U000000FF]
    `));

    ParseTree result = Terminals("abc");

    assert(result.name == "Terminals", "Grammar name test.");
    assert(result.children[0].name == "Terminals.Literal1", "First rule name test.");
    assert(result.begin == 0);
    assert(result.end == 3);
    assert(result.matches == ["abc"]);

    ParseTree reference = Terminals.decimateTree(Terminals.Literal1("abc"));

    assert(result.children[0] == reference, "Invoking a grammar is like invoking its first rule.");

    assert(Terminals.Literal1("abc").successful, "Standard terminal test. Double quote syntax.");
    assert(Terminals.Literal2("abc").successful, "Standard terminal test. Simple quote syntax.");
    assert(Terminals.EmptyLiteral1("").successful , "Standard terminal test. Double quote syntax.");
    assert(Terminals.EmptyLiteral2("").successful, "Standard terminal test. Simple quote syntax.");

    foreach(char c; char.min .. char.max)
        assert(Terminals.Any(""~c).successful, "Any terminal ('.') test.");

    assert(Terminals.Eps("").successful, "Eps test.");
    assert(Terminals.Eps("abc").successful, "Eps test.");

    string lower  = "abcdefghijklmnopqrstuvwxyz";
    string upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    string under  = "_";
    string digits = "0123456789";
    string others = "?./,;:!*&()[]<>";

    foreach(dchar dc; lower)
        assert(Terminals.Letter(to!string(dc)).successful);
    foreach(dchar dc; upper)
        assert(!Terminals.Letter(to!string(dc)).successful);
    foreach(dchar dc; digits)
        assert(!Terminals.Letter(to!string(dc)).successful);
    foreach(dchar dc; others)
        assert(!Terminals.Letter(to!string(dc)).successful);

    foreach(dchar dc; lower)
        assert(!Terminals.Digit(to!string(dc)).successful);
    foreach(dchar dc; upper)
        assert(!Terminals.Digit(to!string(dc)).successful);
    foreach(dchar dc; digits)
        assert(Terminals.Digit(to!string(dc)).successful);
    foreach(dchar dc; others)
        assert(!Terminals.Letter(to!string(dc)).successful);

    foreach(dchar dc; lower ~ upper ~ under)
        assert(Terminals.Alpha1(to!string(dc)).successful);
    foreach(dchar dc; digits ~ others)
        assert(!Terminals.Alpha1(to!string(dc)).successful);

    foreach(dchar dc; lower ~ upper ~ under)
        assert(Terminals.Alpha2(to!string(dc)).successful);
    foreach(dchar dc; digits ~ others)
        assert(!Terminals.Alpha2(to!string(dc)).successful);

    foreach(size_t index, dchar dc; lower ~ upper ~ under)
        assert( (index < 3  && Terminals.ABC(to!string(dc)).successful)
             || (index >= 3 && !Terminals.ABC(to!string(dc)).successful));

    foreach(dchar dc; 0..256)
    {
        string s = to!string(dc);
        if (dc <= '\127')
            assert(Terminals.Chars1(s).successful);
        else
            assert(!Terminals.Chars1(s).successful);

        assert(Terminals.Chars2(s).successful);
        assert(Terminals.Chars3(s).successful);
        assert(Terminals.Chars4(s).successful);
    }

    mixin(grammar(`
    Structure:
        Rule1 <- Rule2 / Rule3 / Rule4   # Or test
        Rule2 <- Rule3 Rule4             # And test
        Rule3 <- "abc"
        Rule4 <- "def"

        Rule5 <- (Rule2 /  Rule4) Rule3  # parenthesis test
        Rule6 <-  Rule2 /  Rule4  Rule3
        Rule7 <-  Rule2 / (Rule4  Rule3)
    `));

    // Invoking Rule2 (and hence, Rule3 Rule4)
    result = Structure("abcdef");

    assert(result.successful, "Calling Rule2.");
    assert(result.name == "Structure", "Grammar name test.");
    assert(result.children[0].name == "Structure.Rule1", "First rule name test");
    assert(result.children[0].children.length == 1);
    assert(result.children[0].children[0].name == "Structure.Rule2");
    assert(result.children[0].children[0].children[0].name == "Structure.Rule3");
    assert(result.children[0].children[0].children[1].name == "Structure.Rule4");
    assert(result.matches == ["abc", "def"]);
    assert(result.begin ==0);
    assert(result.end == 6);

    // Invoking Rule3
    result = Structure("abc");

    assert(result.successful, "Calling Rule3.");
    assert(result.name == "Structure", "Grammar name test.");
    assert(result.children[0].name == "Structure.Rule1", "First rule name test");
    assert(result.children[0].children.length == 1);
    assert(result.children[0].children[0].name == "Structure.Rule3");
    assert(result.children[0].children[0].children.length == 0);
    assert(result.matches == ["abc"]);
    assert(result.begin ==0);
    assert(result.end == 3);

    // Invoking Rule4
    result = Structure("def");

    assert(result.successful, "Calling Rule2.");
    assert(result.name == "Structure", "Grammar name test.");
    assert(result.children[0].name == "Structure.Rule1", "First rule name test");
    assert(result.children[0].children.length == 1);
    assert(result.children[0].children[0].name == "Structure.Rule4");
    assert(result.children[0].children[0].children.length == 0);
    assert(result.matches == ["def"]);
    assert(result.begin ==0);
    assert(result.end == 3);

    // Failure
    result =Structure("ab_def");
    assert(!result.successful);
    assert(result.name == "Structure", "Grammar name test.");
    assert(result.begin == 0);
    assert(result.end == 0);

    // Parenthesis test
    // Rule5 <- (Rule2 /  Rule4) Rule3
    result = Structure.decimateTree(Structure.Rule5("abcdefabc"));
    assert(result.successful);
    assert(result.children.length == 2, "Two children: (Rule2 / Rule4), followed by Rule3.");
    assert(result.children[0].name == "Structure.Rule2");
    assert(result.children[1].name == "Structure.Rule3");

    result = Structure.decimateTree(Structure.Rule5("defabc"));
    assert(result.successful);
    assert(result.children.length == 2, "Two children: (Rule2 / Rule4), followed by Rule3.");
    assert(result.children[0].name == "Structure.Rule4");
    assert(result.children[1].name == "Structure.Rule3");

    // Rule6 <-  Rule2 /  Rule4  Rule3
    result = Structure.decimateTree(Structure.Rule6("abcdef"));
    assert(result.successful);
    assert(result.children.length == 1, "One child: Rule2.");
    assert(result.children[0].name == "Structure.Rule2");

    result = Structure.decimateTree(Structure.Rule6("defabc"));
    assert(result.successful);
    assert(result.children.length == 2, "Two children: Rule4, followed by Rule3.");
    assert(result.children[0].name == "Structure.Rule4");
    assert(result.children[1].name == "Structure.Rule3");

    // Rule7 <-  Rule2 / (Rule4  Rule3)
    // That is, like Rule6
    result = Structure.decimateTree(Structure.Rule7("abcdef"));
    assert(result.successful);
    assert(result.children.length == 1, "One child: Rule2.");
    assert(result.children[0].name == "Structure.Rule2");

    result = Structure.decimateTree(Structure.Rule7("defabc"));
    assert(result.successful);
    assert(result.children.length == 2, "Two children: Rule4, followed by Rule3.");
    assert(result.children[0].name == "Structure.Rule4");
    assert(result.children[1].name == "Structure.Rule3");

    // Prefixes and Suffixes
    mixin(grammar(`
    PrefixSuffix:
        Rule1 <- &"abc"
        Rule2 <- !"abc"
        Rule3 <- "abc"?
        Rule4 <- "abc"*
        Rule5 <- "abc"+
    `));

    // Verifying &"abc" creates a positive look-ahead construct
    result = PrefixSuffix.Rule1("abc");
    reference = posLookahead!(literal!"abc")("abc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule1("def");
    reference = posLookahead!(literal!"abc")("def");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);


    // Verifying !"abc" creates a negative look-ahead construct
    result = PrefixSuffix.Rule2("abc");
    reference = negLookahead!(literal!"abc")("abc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule2("def");
    reference = negLookahead!(literal!"abc")("def");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    // Verifying "abc"? creates an optional construct
    result = PrefixSuffix.Rule3("abc");
    reference = option!(literal!"abc")("abc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule3("def");
    reference = option!(literal!"abc")("def");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    // Verifying "abc"* creates a zero or more construct
    result = PrefixSuffix.Rule4("");
    reference = zeroOrMore!(literal!"abc")("");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule4("abc");
    reference = zeroOrMore!(literal!"abc")("abc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule4("abcabc");
    reference = zeroOrMore!(literal!"abc")("abcabc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    // Verifying "abc"+ creates a one or more construct
    result = PrefixSuffix.Rule5("");
    reference = oneOrMore!(literal!"abc")("");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule5("abc");
    reference = oneOrMore!(literal!"abc")("abc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);

    result = PrefixSuffix.Rule5("abcabc");
    reference = oneOrMore!(literal!"abc")("abcabc");

    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);
    assert(result.children == reference.children);
}

unittest // Multilines rules
{
    mixin(grammar(`
Indentation:
Rule1 <
'a'
    'b'
'c'
    Rule2
<-
 'd'
Rule3
<
'e'
Rule4 <- 'f' Rule5   # Rule4 ends with 'f', then it's Rule5
<- 'g'




    'h'
`));


    assert(Indentation("abc").successful);
    assert(Indentation.Rule2("d").successful);
    assert(Indentation.Rule3("e").successful);
    assert(Indentation.Rule4("f").successful);
    assert(Indentation.Rule5("gh").successful);
}

unittest // Parsing at compile-time
{
    mixin(grammar(`
    Test:
        Rule1 <- 'a' Rule2('b')
        Rule2(B) <- B
    `));

    // Equality on success
    ParseTree result = Test("ab");

    enum CTsuccess = Test("ab");

    assert(CTsuccess == result, "Compile-time parsing is equal to runtime parsing on success.");

    // Equality on failure
    result = Test("ac");
    enum CTfailure = Test("ac");

    assert(CTfailure == result, "Compile-time parsing is equal to runtime parsing on failure.");
}

unittest // PEG extensions (arrows, prefixes, suffixes)
{
    mixin(grammar(`
    Arrows:
        Rule1 <- ABC DEF  # Standard arrow
        Rule2 <  ABC DEF  # Space arrow
        Rule3 <  ABC DEF* # Space arrow
        Rule4 <  ABC+ DEF # Space arrow

        Rule5 <- ABC*
        Rule6 <~ ABC*     # Fuse arrow

        Rule7 <: ABC DEF  # Discard arrow
        Rule8 <^ ABC DEF  # Keep arrow
        Rule9 <; ABC DEF  # Drop arrow
        Rule10 <% ABC Rule1 DEF  # Propagate arrow

        ABC <- "abc"
        DEF <- "def"
    `));

    // Comparing <- ABC DEF and < ABC DEF
    ParseTree result = Arrows.decimateTree(Arrows.Rule1("abcdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end ==6);
    assert(result.matches == ["abc", "def"]);
    assert(result.children.length == 2);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.DEF");

    result = Arrows.decimateTree(Arrows.Rule1("abc  def"));
    assert(!result.successful);

    result = Arrows.decimateTree(Arrows.Rule2("abcdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"]);
    assert(result.children.length == 2);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.DEF");

    result = Arrows.decimateTree(Arrows.Rule2("abc  def  "));
    assert(result.successful, "space arrows consume spaces.");
    assert(result.begin == 0);
    assert(result.end == "abc  def  ".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "def"]);
    assert(result.children.length == 2);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.DEF");

    result = Arrows.decimateTree(Arrows.Rule3("abcdefdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcdefdef".length);
    assert(result.matches == ["abc", "def", "def"]);
    assert(result.children.length == 3);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.DEF");
    assert(result.children[2].name == "Arrows.DEF");

    result = Arrows.decimateTree(Arrows.Rule3("abc  def  defdef"));
    assert(result.successful, "space arrows consume spaces.");
    assert(result.begin == 0);
    assert(result.end == "abc  def  defdef".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "def", "def", "def"]);
    assert(result.children.length == 4);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.DEF");
    assert(result.children[2].name == "Arrows.DEF");
    assert(result.children[3].name == "Arrows.DEF");

    result = Arrows.decimateTree(Arrows.Rule4("abcabcdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcdef".length);
    assert(result.matches == ["abc", "abc", "def"]);
    assert(result.children.length == 3);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.ABC");
    assert(result.children[2].name == "Arrows.DEF");

    result = Arrows.decimateTree(Arrows.Rule4("   abc abcabc  def  "));
    assert(result.successful, "space arrows consume spaces.");
    assert(result.begin == 0);
    assert(result.end == "   abc abcabc  def  ".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "abc", "abc", "def"]);
    assert(result.children.length == 4);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.ABC");
    assert(result.children[2].name == "Arrows.ABC");
    assert(result.children[3].name == "Arrows.DEF");

    //Comparing <- ABC* and <~ ABC*
    result = Arrows.decimateTree(Arrows.Rule5("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "abc", "abc"]);
    assert(result.children.length == 3, "With the * operator, all children are kept.");
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.ABC");
    assert(result.children[2].name == "Arrows.ABC");

    result = Arrows.decimateTree(Arrows.Rule6("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length, "The entire input is parsed.");
    assert(result.matches == ["abcabcabc"], "Matches are fused.");
    assert(result.children.length == 0, "The <~ arrow cuts children.");

    // Comparing <- ABC DEF and <: ABC DEF
    result = Arrows.decimateTree(Arrows.Rule7("abcdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcdef".length, "The entire input is parsed.");
    assert(result.matches is null, "No match with the discard arrow.");
    assert(result.children.length == 0, "No children with the discard arrow.");

    // Comparing <- ABC DEF and <^ ABC DEF
    //But <^ is not very useful anyways. It does not distribute ^ among the subrules.
    result = Arrows.decimateTree(Arrows.Rule8("abcdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcdef".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "def"]);
    assert(result.children.length == 2);

    // Comparing <- ABC DEF and <; ABC DEF
    result = Arrows.decimateTree(Arrows.Rule9("abcdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcdef".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "def"], "The drop arrow keeps the matches.");
    assert(result.children.length == 0, "The drop arrow drops the children.");

    // Comparing <- ABC DEF and <% ABC Rule1 DEF
    //But <% is not very useful anyways. It does not distribute % among the subrules.
    result = Arrows.decimateTree(Arrows.Rule10("abcabcdefdef"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcdefdef".length, "The entire input is parsed.");
    assert(result.matches == ["abc", "abc", "def", "def"]);
    assert(result.children.length == 3);
    assert(result.children[0].name == "Arrows.ABC");
    assert(result.children[1].name == "Arrows.Rule1", "No rule replacement by its own children. See % for that.");
    assert(result.children[2].name == "Arrows.DEF");
}

unittest //More space arrow tests
{
    mixin(grammar(`
    Spaces:
        Rule1 < A (B C)+
        A <- 'a'
        B <- 'b'
        C <- 'c'
    `));

    ParseTree result = Spaces.decimateTree(Spaces.Rule1("abcbc"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcbc".length);
    assert(result.children.length == 5);
    assert(result.children[0].name == "Spaces.A");
    assert(result.children[1].name == "Spaces.B");
    assert(result.children[2].name == "Spaces.C");
    assert(result.children[3].name == "Spaces.B");
    assert(result.children[4].name == "Spaces.C");

    result = Spaces.decimateTree(Spaces.Rule1(" a bc  b  c "));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == " a bc  b  c ".length);
    assert(result.children.length == 5);
    assert(result.children[0].name == "Spaces.A");
    assert(result.children[1].name == "Spaces.B");
    assert(result.children[2].name == "Spaces.C");
    assert(result.children[3].name == "Spaces.B");
    assert(result.children[4].name == "Spaces.C");
}

unittest // Prefix and suffix tests
{
    mixin(grammar(`
    PrefixSuffix:
        # Reference
        Rule1 <-  ABC   DEF
        Rule2 <- "abc" "def"
        Rule3 <-    ABC*
        Rule4 <-   "abc"*

        # Discard operator
        Rule5 <-  :ABC    DEF
        Rule6 <-   ABC   :DEF
        Rule7 <- :"abc"  "def"
        Rule8 <-  "abc" :"def"

        # Drop operator
        Rule9  <-  ;ABC    DEF
        Rule10 <-   ABC   ;DEF
        Rule11 <- ;"abc"  "def"
        Rule12 <-  "abc" ;"def"

        # Fuse operator

        Rule13 <- ~( ABC* )
        Rule14 <- ~("abc"*)

        # Keep operator
        Rule15 <- ^"abc" ^"def"

        # Propagate operator
        Rule16 <- ABC  Rule1 DEF
        Rule17 <- ABC %Rule1 DEF


        ABC <- "abc"
        DEF <- "def"
    `));


    // Comparing standard and discarded rules
    auto result = PrefixSuffix.decimateTree(PrefixSuffix.Rule1("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"]);
    assert(result.children.length == 2);
    assert(result.children[0].name == "PrefixSuffix.ABC");
    assert(result.children[1].name == "PrefixSuffix.DEF");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule5("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["def"]);
    assert(result.children.length == 1, "The first child is discarded.");
    assert(result.children[0].name == "PrefixSuffix.DEF");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule6("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc"]);
    assert(result.children.length == 1, "The second child is discarded.");
    assert(result.children[0].name == "PrefixSuffix.ABC");


    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule2("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"]);
    assert(result.children.length == 0, "Literals do not create children.");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule7("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["def"]);
    assert(result.children.length == 0);

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule8("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc"]);
    assert(result.children.length == 0);

    // Comparing standard and dropped rules

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule9("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"], "All matches are there.");
    assert(result.children.length == 1, "The first child is discarded.");
    assert(result.children[0].name == "PrefixSuffix.DEF");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule10("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"], "All matches are there.");
    assert(result.children.length == 1, "The second child is discarded.");
    assert(result.children[0].name == "PrefixSuffix.ABC");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule11("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"], "All matches are there.");
    assert(result.children.length == 0);

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule12("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 6);
    assert(result.matches == ["abc", "def"], "All matches are there.");
    assert(result.children.length == 0);


    // Comparing standard and fused rules

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule3("abcabcabc"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abc", "abc", "abc"]);
    assert(result.children.length == 3, "Standard '*': 3 children.");
    assert(result.children[0].name == "PrefixSuffix.ABC");
    assert(result.children[1].name == "PrefixSuffix.ABC");
    assert(result.children[2].name == "PrefixSuffix.ABC");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule4("abcabcabc"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abc", "abc", "abc"]);
    assert(result.children.length == 0, "All literals are discarded by the tree decimation.");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule13("abcabcabc"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abcabcabc"], "All matches are fused.");
    assert(result.children.length == 0, "Children are discarded by '~'.");

    result = PrefixSuffix.decimateTree(PrefixSuffix.Rule14("abcabcabc"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abcabcabc"], "All matches are there.");
    assert(result.children.length == 0, "Children are discarded by '~'.");

    // Testing the keep (^) operator

    result  = PrefixSuffix.decimateTree(PrefixSuffix.Rule15("abcdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcdef".length);
    assert(result.matches == ["abc", "def"], "All matches are there.");
    assert(result.children.length == 2, "Both children are kept by '^'.");
    assert(result.children[0].name == `literal!("abc")`,
           `literal!("abc") is kept even though it's not part of the grammar rules.`);
    assert(result.children[1].name == `literal!("def")`,
           `literal!("def") is kept even though it's not part of the grammar rules.`);

    // Comparing standard and propagated (%) rules.
    result  = PrefixSuffix.decimateTree(PrefixSuffix.Rule16("abcabcdefdef"));

    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcdefdef".length);
    assert(result.matches == ["abc", "abc", "def", "def"], "All matches are there.");
    assert(result.children.length == 3, "Standard rule: three children.");
    assert(result.children[0].name == "PrefixSuffix.ABC");
    assert(result.children[1].name == "PrefixSuffix.Rule1");
    assert(result.children[1].children.length == 2, "Rule1 creates two children.");
    assert(result.children[1].children[0].name, "PrefixSuffix.ABC");
    assert(result.children[1].children[1].name, "PrefixSuffix.DEF");
    assert(result.children[2].name == "PrefixSuffix.DEF");

    result  = PrefixSuffix.decimateTree(PrefixSuffix.Rule17("abcabcdefdef"));

    // From (ABC, Rule1(ABC,DEF), DEF) to (ABC,ABC,DEF,DEF)
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcdefdef".length);
    assert(result.matches == ["abc", "abc", "def", "def"], "All matches are there.");
    assert(result.children.length == 4, "%-affected rule: four children.");
    assert(result.children[0].name == "PrefixSuffix.ABC");
    assert(result.children[1].name == "PrefixSuffix.ABC");
    assert(result.children[2].name == "PrefixSuffix.DEF");
    assert(result.children[2].name == "PrefixSuffix.DEF");

    // Testing % and < together
    mixin(grammar(`
    PropTest:
        Rule1 < B C+
        Rule2 <- B (%C)+
        Rule3 <  B (%C)+
        Rule4 <  B %(D E)+

        B <- 'b'
        C <- D E
        D <- 'd'
        E <- 'e'
    `));

    result = PropTest.decimateTree(PropTest.Rule1("bdedede"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "bdedede".length);
    assert(result.matches == ["b", "d", "e", "d", "e", "d", "e"]);
    assert(result.children.length == 4, "b and de, de, de");
    assert(result.children[0].name == "PropTest.B");
    assert(result.children[1].name == "PropTest.C");
    assert(result.children[2].name == "PropTest.C");
    assert(result.children[3].name == "PropTest.C");

    result = PropTest.decimateTree(PropTest.Rule2("bdedede"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "bdedede".length);
    assert(result.matches == ["b", "d", "e", "d", "e", "d", "e"]);
    assert(result.children.length == 7, "b and (d and e), thrice.");
    assert(result.children[0].name == "PropTest.B");
    assert(result.children[1].name == "PropTest.D");
    assert(result.children[2].name == "PropTest.E");
    assert(result.children[3].name == "PropTest.D");
    assert(result.children[4].name == "PropTest.E");
    assert(result.children[5].name == "PropTest.D");
    assert(result.children[6].name == "PropTest.E");

    result = PropTest.decimateTree(PropTest.Rule3("bdedede"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "bdedede".length);
    assert(result.matches == ["b", "d", "e", "d", "e", "d", "e"]);
    assert(result.children.length == 7, "b and (d and e), thrice.");
    assert(result.children[0].name == "PropTest.B");
    assert(result.children[1].name == "PropTest.D");
    assert(result.children[2].name == "PropTest.E");
    assert(result.children[3].name == "PropTest.D");
    assert(result.children[4].name == "PropTest.E");
    assert(result.children[5].name == "PropTest.D");
    assert(result.children[6].name == "PropTest.E");

    result = PropTest.decimateTree(PropTest.Rule3("  b  de de  de "));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "  b  de de  de ".length);
    assert(result.matches == ["b", "d", "e", "d", "e", "d", "e"]);
    assert(result.children.length == 7, "b and (d and e), thrice.");
    assert(result.children[0].name == "PropTest.B");
    assert(result.children[1].name == "PropTest.D");
    assert(result.children[2].name == "PropTest.E");
    assert(result.children[3].name == "PropTest.D");
    assert(result.children[4].name == "PropTest.E");
    assert(result.children[5].name == "PropTest.D");
    assert(result.children[6].name == "PropTest.E");

    result = PropTest.decimateTree(PropTest.Rule4("bdedede"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "bdedede".length);
    assert(result.matches == ["b", "d", "e", "d", "e", "d", "e"]);
    assert(result.children.length == 7, "b and (d and e), thrice.");
    assert(result.children[0].name == "PropTest.B");
    assert(result.children[1].name == "PropTest.D");
    assert(result.children[2].name == "PropTest.E");
    assert(result.children[3].name == "PropTest.D");
    assert(result.children[4].name == "PropTest.E");
    assert(result.children[5].name == "PropTest.D");
    assert(result.children[6].name == "PropTest.E");

    result = PropTest.decimateTree(PropTest.Rule4("  b  de de  de "));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "  b  de de  de ".length);
    assert(result.matches == ["b", "d", "e", "d", "e", "d", "e"]);
    assert(result.children.length == 7, "b and (d and e), thrice.");
    assert(result.children[0].name == "PropTest.B");
    assert(result.children[1].name == "PropTest.D");
    assert(result.children[2].name == "PropTest.E");
    assert(result.children[3].name == "PropTest.D");
    assert(result.children[4].name == "PropTest.E");
    assert(result.children[5].name == "PropTest.D");
    assert(result.children[6].name == "PropTest.E");

    // More than one prefix, more than one suffixes
    mixin(grammar(`
    MoreThanOne:
        Rule1 <- ~:("abc"*)   # Two prefixes (nothing left for ~, after :)
        Rule2 <- :~("abc"*)   # Two prefixes (: will discard everything ~ did)
        Rule3 <- ;:~"abc"     # Many prefixes
        Rule4 <- ~~~("abc"*)  # Many fuses (no global effect)

        Rule5 <- "abc"+*      # Many suffixes
        Rule6 <- "abc"+?      # Many suffixes

        Rule7 <- !!"abc"      # Double negation, equivalent to '&'
        Rule8 <-  &"abc"

        Rule9 <- ^^"abc"+*   # Many suffixes and prefixes
    `));

    assert(is(MoreThanOne), "This compiles all right.");

    result = MoreThanOne.decimateTree(MoreThanOne.Rule1("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches is null);
    assert(result.children is null);

    result = MoreThanOne.decimateTree(MoreThanOne.Rule2("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches is null);
    assert(result.children is null);

    result = MoreThanOne.decimateTree(MoreThanOne.Rule3("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abc".length);
    assert(result.matches is null);
    assert(result.children is null);

    result = MoreThanOne.decimateTree(MoreThanOne.Rule4("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abcabcabc"]);
    assert(result.children is null);

    // +* and +?
    result = MoreThanOne.decimateTree(MoreThanOne.Rule5("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abc", "abc", "abc"]);
    assert(result.children.length == 0);

    result = MoreThanOne.decimateTree(MoreThanOne.Rule6("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "abcabcabc".length);
    assert(result.matches == ["abc", "abc", "abc"]);
    assert(result.children.length == 0);

    // !! is equivalent to &
    result = MoreThanOne.decimateTree(MoreThanOne.Rule7("abc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 0);
    assert(result.matches is null);
    assert(result.children is null);

    result = MoreThanOne.decimateTree(MoreThanOne.Rule8("abc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 0);
    assert(result.matches is null);
    assert(result.children is null);

    // ^^"abc"+*
    result = MoreThanOne.decimateTree(MoreThanOne.Rule9("abcabcabc"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 9);
    assert(result.matches == ["abc", "abc", "abc"]);
    assert(result.children.length == 1);
    assert(result.children[0].name == `zeroOrMore!(oneOrMore!(literal!("abc")))`);
    assert(result.children[0].children.length == 1);
    assert(result.children[0].children[0].name == `oneOrMore!(literal!("abc"))`);
    assert(result.children[0].children[0].children.length == 3);
    assert(result.children[0].children[0].children[0].name == `literal!("abc")`);
    assert(result.children[0].children[0].children[1].name == `literal!("abc")`);
    assert(result.children[0].children[0].children[2].name == `literal!("abc")`);
}

unittest // Issue #88 unit test
{
    enum gram = `
    P:
        Rule1 <- (w 'a' w)*
        Rule2 <- (wx 'a' wx)*
        w <- :(' ' / '\n' / '\t' / '\r')*
        wx <- (:' ' / '\n' / '\t' / '\r')*
    `;

    mixin(grammar(gram));

    string input = "   a   a   a a  a a ";

    ParseTree p1 = P.decimateTree(P.Rule1(input));
    ParseTree p2 = P.decimateTree(P.Rule2(input));
    assert(softCompare(p1,p2));

    input = " a\n  \011\012 a\n\t  a\x09\x0A a ";
    p1 = P.decimateTree(P.Rule1(input));
    p2 = P.decimateTree(P.Rule2(input));
    assert(p1.end == input.length); // Parse the entire string
    assert(p2.end == input.length);
}

unittest // Leading alternation
{
    mixin(grammar(`
    LeadingAlternation:
        Rule1 <- / 'a'
        Rule2 <- / 'a' / 'b'
        Rule3 <- (/ 'a' / 'b')
    `));

    ParseTree result = LeadingAlternation.decimateTree(LeadingAlternation.Rule1("a"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 1);
    assert(result.matches == ["a"]);

    result = LeadingAlternation.decimateTree(LeadingAlternation.Rule2("b"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 1);
    assert(result.matches == ["b"]);

    result = LeadingAlternation.decimateTree(LeadingAlternation.Rule3("b"));
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == 1);
    assert(result.matches == ["b"]);
}

unittest // Extended chars tests
{
mixin(grammar("
    Chars:
        # Lone chars
        Rule1 <- '\t' '0' 'A' '~'
        Rule2 <- '\11' '\60' '\101' '\176'           # \t 0 A ~ in octal
        Rule3 <- '\011' '\060' '\101' '\176'         # \t 0 A ~ in octal (prefix 0)
        Rule4 <- '\x09' '\x30' '\x41' '\x7E'         # \t 0 A ~ in hexadecimal
        Rule5 <- '\u0009' '\u0030' '\u0041' '\u007E' # \t 0 A ~ in unicode
        Rule6 <- '\U00000009' '\U00000030' '\U00000041' '\U0000007E' # \t 0 A ~ in unicode

        # Strings literals
        Rule7 <- '\t0A~'
        Rule8 <- '\11\60\101\176'            # \t 0 A ~ in octal
        Rule9 <- '\011\060\101\176'          # \t 0 A ~ in octal (prefix 0)
        Rule10 <- '\x09\x30\x41\x7E'         # \t 0 A ~ in hexadecimal
        Rule11 <- '\u0009\u0030\u0041\u007E' # \t 0 A ~ in unicode
        Rule12 <- '\U00000009\U00000030\U00000041' '\U0000007E' # \t 0 A ~ in unicode

        # Outside Latin
        Rule13 <- '\u03B1\u03B9\u03C6\u03B1' # alpha in greek
        Rule14 <- 'αιφα'

        # Hello's
        English <- 'Hello'
        Russian <- 'Здравствуйте'
        Arabic <- 'السلام عليك'
        Chinese <- '你好'
        Japanese <- '今日は'
        Spanish <- '¡Hola!'
    "));


    assert(Chars.decimateTree(Chars.Rule1("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule2("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule3("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule4("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule5("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule6("\t0A~")).successful);

    assert(Chars.decimateTree(Chars.Rule7("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule8("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule9("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule10("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule11("\t0A~")).successful);
    assert(Chars.decimateTree(Chars.Rule12("\t0A~")).successful);

    assert(Chars.decimateTree(Chars.Rule13("\u03B1\u03B9\u03C6\u03B1")).successful);
    assert(Chars.decimateTree(Chars.Rule13("αιφα")).successful);

    assert(Chars.decimateTree(Chars.Rule14("\u03B1\u03B9\u03C6\u03B1")).successful);
    assert(Chars.decimateTree(Chars.Rule14("αιφα")).successful);

    assert(Chars.decimateTree(Chars.English("Hello")).successful);
    assert(Chars.decimateTree(Chars.Russian("Здравствуйте")).successful);
    assert(Chars.decimateTree(Chars.Arabic("السلام عليك")).successful);
    assert(Chars.decimateTree(Chars.Chinese("你好")).successful);
    assert(Chars.decimateTree(Chars.Japanese("今日は'")).successful);
    assert(Chars.decimateTree(Chars.Spanish("¡Hola!")).successful);
}

unittest // Extended char range tests
{
    import std.conv;

    mixin(grammar(`
    CharRanges:
        Rule1 <- [a-z]
        Rule2 <- [\141-\172]             # a-z in octal
        Rule3 <- [\x61-\x7A]             # a-z in hexadecimal
        Rule4 <- [\u0061-\u007A]         # a-z in UTF16
        Rule5 <- [\U00000061-\U0000007A] # a-z in UTF32

        Rule6 <- [\-\[\]\\\'\"\n\r\t]
    `));

    string lower = "abcdefghijklmnopqrstuvwxyz";
    string upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    string digits = "0123456789";
    string others = "?./,;:!*&()[]<>";
    string escapes = "-[]\\\'\"\n\r\t";

    foreach(dchar c; lower)
    {
        assert(CharRanges.Rule1(to!string(c)).successful);
        assert(CharRanges.Rule2(to!string(c)).successful);
        assert(CharRanges.Rule3(to!string(c)).successful);
        assert(CharRanges.Rule4(to!string(c)).successful);
        assert(CharRanges.Rule5(to!string(c)).successful);
    }

    foreach(dchar c; upper ~ digits ~ others)
    {
        assert(!CharRanges.Rule1(to!string(c)).successful);
        assert(!CharRanges.Rule2(to!string(c)).successful);
        assert(!CharRanges.Rule3(to!string(c)).successful);
        assert(!CharRanges.Rule4(to!string(c)).successful);
        assert(!CharRanges.Rule5(to!string(c)).successful);
    }

    foreach(dchar c; escapes)
    {
        assert(CharRanges.Rule6(to!string(c)).successful);
    }
}

unittest // qualified names for rules
{
    mixin(grammar(`
    First:
        Rule1 <- "abc"
        Rule2 <- "def"
    `));

    mixin(grammar(`
    Second:
        Rule1 <- First.Rule1
        Rule2 <- First.Rule2
        Rule3 <- pegged.peg.list(pegged.peg.identifier, ',')
    `));

    // Equal on success
    ParseTree reference = First("abc");
    ParseTree result = Second("abc");
    assert(reference.successful);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    // Equal on failure
    reference = First("def");
    result = Second("def");
    assert(!reference.successful);
    assert(!result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    // Second rule test
    reference = First.Rule2("def");
    result = Second.Rule2("def");
    assert(reference.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    // External (predefined) rule call:
    result = Second.Rule3("foo,bar,baz");
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "foo,bar,baz".length);
    assert(result.matches == ["foo", "bar", "baz"]);
}

unittest // Parameterized rules
{
    mixin(grammar(`
    Parameterized:
        # Different arities
        Rule1(A)     <- A+
        Rule1(A,B)   <- (A B)+
        Rule1(A,B,C) <- (A B C)+

        # Inner call
        Call1    <- Rule1('a')
        Call2    <- Rule1('a','b')
        Call3    <- Rule1('a','b','c')
        Call4(A) <- Rule1(A, A, A)
        Call5(A) <- Rule1('a', A, 'c')

        # Default values
        Rule2(A = 'a', B = 'b') <- (A B)+

        # Re-using the parameters
        Rule3(A,B) <- A B B A  # Money money money!

        # The standard parameterized rule
        List(Elem, Sep) < Elem (:Sep Elem)*

        # Another common PEG pattern
        AllUntil(End) <~ (!End .)* :End
    `));

    alias Parameterized.Rule1!(literal!"a") R1;
    alias oneOrMore!(literal!"a") Ref1;

    ParseTree reference = Ref1("aaaa");
    ParseTree result = R1("aaaa");

    assert(result.name == `Parameterized.Rule1!(literal!("a"))`);
    assert(reference.successful);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    result = Parameterized.Call1("aaaa");

    assert(result.name == `Parameterized.Call1`);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    alias Parameterized.Rule1!(literal!"abc") R1long;
    alias oneOrMore!(literal!"abc") Ref1long;

    reference = Ref1long("abcabcabcabc");
    result = R1long("abcabcabcabc");

    assert(result.name == `Parameterized.Rule1!(literal!("abc"))`);
    assert(reference.successful);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    alias Parameterized.Rule1!(literal!"a", literal!"b") R2;
    alias oneOrMore!(and!(literal!"a", literal!"b")) Ref2;

    reference = Ref2("abababab");
    result = R2("abababab");

    assert(result.name == `Parameterized.Rule1!(literal!("a"), literal!("b"))`);
    assert(reference.successful);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    result = Parameterized.Call2("abababab");

    assert(result.name == `Parameterized.Call2`);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    alias Parameterized.Rule1!(literal!"a", literal!"b", literal!"c") R3;
    alias oneOrMore!(and!(literal!"a", literal!"b", literal!"c")) Ref3;

    reference = Ref3("abcabcabcabc");
    result = R3("abcabcabcabc");

    assert(result.name == `Parameterized.Rule1!(literal!("a"), literal!("b"), literal!("c"))`);
    assert(reference.successful);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    result = Parameterized.Call3("abcabcabcabc");

    assert(result.name == `Parameterized.Call3`);
    assert(result.successful);
    assert(result.matches == reference.matches);
    assert(result.begin == reference.begin);
    assert(result.end == reference.end);

    result = Parameterized.Call4!(literal!"A")("AAAAAA");

    assert(result.name == `Parameterized.Call4!(literal!("A"))`);
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "AAAAAA".length);
    assert(result.matches == ["A","A","A","A","A","A"]);

    result = Parameterized.Call5!(literal!"A")("aAcaAc");

    assert(result.name == `Parameterized.Call5!(literal!("A"))`);
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "aAcaAc".length);
    assert(result.matches == ["a","A","c","a","A","c"]);

    // Default parameters
    alias Parameterized.Rule2!() R2_1;
    alias Parameterized.Rule2!(literal!"a") R2_2;
    alias Parameterized.Rule2!(literal!"a", literal!"b") R2_3;

    assert(R2_1("ababab").successful);
    assert(R2_2("ababab").successful);
    assert(R2_3("ababab").successful);

    // Re-using a parameter (A B B A)
    result = Parameterized.Rule3!(literal!"A", literal!"B")("ABBA");

    assert(result.name == `Parameterized.Rule3!(literal!("A"), literal!("B"))`);
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "ABBA".length);
    assert(result.matches == ["A", "B", "B", "A"]);

    alias Parameterized.List!(identifier, literal!",") IdList; // Identifiers separated by ','
    alias Parameterized.List!(IdList, literal!";") IdList2; // IdList's separated by ';'

    result = IdList("foo, bar, baz");

    assert(result.name == `Parameterized.List!(identifier, literal!(","))`);
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "foo, bar, baz".length);
    assert(result.matches == ["foo", "bar", "baz"]);

    result = Parameterized.decimateTree(IdList2("foo,bar,baz; abc, def,   ghi"));

    assert(result.name == `Parameterized.List!(Parameterized.List!(identifier, literal!(",")), literal!(";"))`);
    assert(result.successful);
    assert(result.begin == 0);
    assert(result.end == "foo,bar,baz; abc, def,   ghi".length);
    assert(result.matches == ["foo", "bar", "baz", "abc", "def", "ghi"]);

    assert(result.children.length == 2);

    assert(result.children[0].name == `Parameterized.List!(identifier, literal!(","))`);
    assert(result.children[0].matches == ["foo", "bar", "baz"]);

    assert(result.children[1].name == `Parameterized.List!(identifier, literal!(","))`);
    assert(result.children[1].matches == ["abc", "def", "ghi"]);

    alias Parameterized.AllUntil!(or!(endOfLine)) Line;
    alias zeroOrMore!(Line) Lines;

    string input =
"This is an input text.
Here is another line.

    And the last one.
";

    result = Lines(input);
    assert(result.successful);
    assert(result.children.length == 4);
    assert(result.children[0].matches == ["This is an input text."]);
    assert(result.children[1].matches == ["Here is another line."]);
    assert(result.children[2].matches is null);
    assert(result.children[3].matches == ["    And the last one."]);

    // Parameterized grammar test
    mixin(grammar(`
    Arithmetic(Atom) :
        Expr     <  Factor  (('+'/'-') Factor)*
        Factor   <  Primary (('*'/'/') Primary)*
        Primary  <  '(' Expr ')' / '-' Expr / Atom
    `));

    alias Arithmetic!(identifier) Arith1;
    alias Arithmetic!(or!(identifier, digits)) Arith2;

    assert(Arith1("x + y*z/foo").successful);
    assert(Arith2("x + y*z/foo").successful);

    assert(!Arith1("1 + 2*3/456").successful);
    assert(Arith2("1 + 2*3/456").successful);
    assert(Arith2("1 + 2*3/z").successful);
}

version(unittest) // Semantic actions
{
    P doubler(P)(P p)
    {
        if (p.successful)
            p.matches ~= p.matches;
        return p;
    }
}

unittest // Semantic actions, testing { foo } and { foo, bar, baz }
{
    mixin(grammar(`
    Semantic:
        Rule1 <- 'a' {doubler}
        Rule2 <- 'b' {doubler, doubler}
        Rule3 <- 'b' {doubler} {doubler} # Same as Rule2
        Rule4 <- 'b' {doubler, doubler, doubler}
        Rule5 <- 'a' {doubler} 'b' 'c'{doubler}
        Rule6 <{doubler} 'a'  # Rule Level actions
        Rule7 <{doubler} 'a' 'b' {doubler}  # Rule Level actions
        `));

    ParseTree result = Semantic.decimateTree(Semantic.Rule1("a"));
    assert(result.successful);
    assert(result.matches == ["a", "a"]);

    result = Semantic.decimateTree(Semantic.Rule1("b"));
    assert(!result.successful);
    assert(result.matches == [`"a"`]);

    result = Semantic.decimateTree(Semantic.Rule2("b"));
    assert(result.successful);
    assert(result.matches == ["b", "b", "b", "b"]);

    result = Semantic.decimateTree(Semantic.Rule3("b"));
    assert(result.successful);
    assert(result.matches == ["b", "b", "b", "b"]);

    result = Semantic.decimateTree(Semantic.Rule4("b"));
    assert(result.successful);
    assert(result.matches == ["b", "b", "b", "b", "b", "b", "b", "b"]);

    result = Semantic.decimateTree(Semantic.Rule5("abc"));
    assert(result.successful);
    assert(result.matches == ["a", "a", "b", "c", "c"]);

    result = Semantic.decimateTree(Semantic.Rule6("abc"));
    assert(result.successful);
    assert(result.matches == ["a", "a"]);

    result = Semantic.decimateTree(Semantic.Rule7("abc"));
    assert(result.successful);
    assert(result.matches == ["a", "b", "b", "a", "b", "b"]);

}

version(unittest)
{
    P foo(P)(P p) { return p;} // for testing actions

    void badGrammar(string s)()
    {
        assert(!__traits(compiles, {mixin(grammar(s));}), "This should fail: " ~ s);
    }

    void goodGrammar(string s)()
    {
        assert(__traits(compiles, {mixin(grammar(s));}), "This should work: " ~ s);
    }
}


/+ Failed (commit 4cd177a), DMD crashed. Too many grammar istantiations, I guess.
unittest // failure cases: unnamed grammar, no-rule grammar, syntax errors, etc.
{
    // No grammar
    badGrammar!"";

    // Name without colon nor rules
    badGrammar!"Name";

    // No rule
    badGrammar!"Name:";
    badGrammar!"Name1 Name2";

    // Incomplete and badly formulated rules
    badGrammar!"Name:
        Rule1";
    badGrammar!"Name:
        Rule1 Rule2";
    badGrammar!"Name
        Rule1 Rule2";
    badGrammar!"Name:
        Rule1 <-";
    badGrammar!"Name:
        Rule1 <~";
    badGrammar!"Name:
        Rule1 < ";
    badGrammar!"Name:
        Rule1 <%";
    badGrammar!"Name:
        Rule1 <;";
    badGrammar!"Name
        Rule1 <- <-";

    // Non-closing parenthesis, brackets and quotes
    badGrammar!"Name:
        Rule1 <- ('a'";
    badGrammar!"Name:
        Rule1 <- 'a')";
    badGrammar!"Name:
        Rule1 <- ('a'))";
    badGrammar!"Name:
        Rule1 <- (('a')";
    badGrammar!"Name:
        Rule1 <- 'a";
    badGrammar!"Name:
        Rule1 <- a'";
    badGrammar!`Name:
        Rule1 <- "a`;
    badGrammar!`Name:
        Rule1 <- a"`;
    badGrammar!`Name:
        Rule1 <- 'a"`;
    badGrammar!`Name:
        Rule1 <- "a'`;
    badGrammar!"Name:
        Rule1 <- [a";
    badGrammar!"Name:
        Rule1 <- a]";
    badGrammar!"Name:
        Rule1 <- [a]]";
    // But <- [[a] is legal: matches '[' or 'a'
    goodGrammar!"Name:
        Rule1 <- [[a]";

    // Bad prefix/postfix
    badGrammar!"Name:
        Rule1 <- 'a'~";
    badGrammar!"Name:
        Rule1 <- 'a'%";
    badGrammar!"Name:
        Rule1 <- 'a'!";
    badGrammar!"Name:
        Rule1 <- 'a'&";
    badGrammar!"Name:
        Rule1 <- 'a';";
    badGrammar!"Name:
        Rule1 <- *'a'";
    badGrammar!"Name:
        Rule1 <- +'a'";
    badGrammar!"Name:
        Rule1 <- ?'a'";
    badGrammar!"Name:
        Rule1 <- 'a' {}";
    // Foo is defined in a version(unittest) block
    badGrammar!"Name:
        Rule1 <- 'a' { foo";
    badGrammar!"Name:
        Rule1 <- 'a' foo}";
    badGrammar!"Name:
        Rule1 <- 'a' {foo}}"; // closing }
    badGrammar!"Name:
        Rule1 <- 'a' {{foo}"; // opening {
    badGrammar!"Name:
        Rule1 <- 'a' {foo,}"; // bad comma
    badGrammar!"Name:
        Rule1 <- 'a' {,foo}";
    badGrammar!"Name:
        Rule1 <- {foo}"; // no rule before {}'s
    // DMD Bug :-(
    /+glue.c line 1150 dmd::virtual unsigned int Type::totym():Assertion `0' failed.
    badGrammar!"Name:
        Rule1 <- 'a' {bar}"; // bar not defined
    +/

    // choice ('/') syntax errors
    badGrammar!"Name:
        Rule1 <- 'a' /";
    // But: <- / 'a' is legal (it's equivalent to: <- 'a')
    goodGrammar!"Name:
        Rule1 <- / 'a'";
    badGrammar!"Name:
        Rule1 <- /";
    badGrammar!"Name:
        Rule1 <- 'a' / / 'b'";
}
+/

unittest // Memoization testing
{
    enum gram1 = `
    Test1:
        Rule1 <- Rule2* 'b'   # To force a long evaluation of aaaa...
               / Rule2* 'c'   # before finding a 'b' or a 'c'
        Rule2 <- 'a'
        `;

    enum gram2 = `
    Test2:
        Rule1 <- Rule2* 'b'   # To force a long evaluation of aaaa...
               / Rule2* 'c'   # before finding a 'b' or a 'c'
        Rule2 <- 'a'
        `;

    mixin(grammar!(Memoization.yes)(gram1));
    mixin(grammar!(Memoization.no)(gram2));

    assert(is(typeof(Test1.memo)));
    assert(!is(typeof(Test2.memo)));

    ParseTree result1 = Test1("aaaaaaac");      // Memo + Runtime
    enum ParseTree result2 = Test1("aaaaaaac"); // Memo + Compile-time
    ParseTree result3 = Test2("aaaaaaac");      // No memo + Runtime
    enum ParseTree result4 = Test2("aaaaaaac"); // No memo + Compile-time

    assert(result1 == result2);
    assert(result3 == result4);

    //Directly comparing result1 and result3 is not possible, for the grammar names are different
    assert(pegged.peg.softCompare(result1, result2));
    assert(pegged.peg.softCompare(result1, result3));
    assert(pegged.peg.softCompare(result1, result4));
}

unittest // Test lambda syntax in semantic actions
{
    import std.array;

    auto actions = [

    // Normal action
    `{ myAction }`,

    // List of normal actions
    `{ myAction, myAction2 }`,

    // Simple do-nothing lambda
    `{ (a) {return a;} }`,

    // Simple do-nothing lambda with formatting
    `{ (a) {
        return a;
     }}`,

    // Lambda with commas and spurious braces to try and confuse it
    `{ (a, b) {
        string s = "}";
        if (a.successful,) {
            s ~= q"<}>";
        } else {
            { s ~= q"<}>"; /* } */ }
        }
        return a;} }`,

    // List of mixed actions and lambdas
    `{ myAction , (a) {return a;}, myAction2 , (a) { /* , } */ return a; } }`,

    // Ambiguous lambda (not sure it would compile if used... but it should parse)
    `{ myAction, a => transform(a), myAction2 }`,

    // Something more convoluted
    "{ myAction, (a) {
        /* block } comment with } braces */
        string s = `} {` // wysiwyg string with braces and line comment with brace }
        if (s is null) {
            // }
        } else { // scopes
            { // nested scopes
                writeln(q{ \"}\" }); // token string with nested string with brace
            }
        }

        string s = `1,2,3,4,5` // commas separate actions

        /+ } Crazy nesting block comment
            /+ } +/
            /+ } +/
            /+ /+ } +/ } +/
            }
        +/

        q\"<  } <}> <> <<}<>}>>  >\"; // delimited string
        q\"[ [}] [] [[[ } ]]] ]\"; // delimited string
        q\"( () }(}) (((}))}) )\"; // delimited string
        q\"{ {} {} {{{}}} }\"; // delimited string
        q{ class {} {} struct void \"}\" } /* another token string } */

        struct S
        {
            void foo() {}
            void bar() {}
        }

        return a;
    }, myAction2 }",
    ];

    auto results = [
    [`myAction`],
    [`myAction`,`myAction2`],
    [`(a) {return a;}`],
    [`(a) {
        return a;
     }`],
    [`(a, b) {
        string s = "}";
        if (a.successful,) {
            s ~= q"<}>";
        } else {
            { s ~= q"<}>"; /* } */ }
        }
        return a;}`],
    [`myAction`,`(a) {return a;}`,`myAction2`,`(a) { /* , } */ return a; }`],
    [`myAction`,`a => transform(a)`,`myAction2`],
    [`myAction`,"(a) {
        /* block } comment with } braces */
        string s = `} {` // wysiwyg string with braces and line comment with brace }
        if (s is null) {
            // }
        } else { // scopes
            { // nested scopes
                writeln(q{ \"}\" }); // token string with nested string with brace
            }
        }

        string s = `1,2,3,4,5` // commas separate actions

        /+ } Crazy nesting block comment
            /+ } +/
            /+ } +/
            /+ /+ } +/ } +/
            }
        +/

        q\"<  } <}> <> <<}<>}>>  >\"; // delimited string
        q\"[ [}] [] [[[ } ]]] ]\"; // delimited string
        q\"( () }(}) (((}))}) )\"; // delimited string
        q\"{ {} {} {{{}}} }\"; // delimited string
        q{ class {} {} struct void \"}\" } /* another token string } */

        struct S
        {
            void foo() {}
            void bar() {}
        }

        return a;
    }",`myAction2`]
    ];

    foreach(idx, act; actions)
    {
        auto grammar = `P: Rule <- RuleA ` ~ act ~ ` RuleA <- 'A'`;
        auto p = Pegged(grammar);

        assert(p.successful);

        auto action = p.children[0].children[1]
                                   .children[2]
                                   .children[0]
                                   .children[0]
                                   .children[0]
                                   .children[1];

        assert(action.matches.length == results[idx].length);
        foreach(i, s; action.matches)
            assert(strip(s) == results[idx][i],
                   "\nGot |"~s~"|" ~ "\nNeeded: |"~results[idx][i]~"|");
    }
}

unittest
{
    // Higher-level word boundary test.
    mixin(grammar(`
        TestGrammar:

        Foo < '{' 'X' '}'
        Bar < 'A' 'B'

        Spacing <: 
            / blank+
            / blank* wordBoundary
            / wordBoundary blank*
            / ![a-zA-Z]
            / !.

        `));

    auto pt = TestGrammar.Foo("{ X }");
    assert(pt.successful);
    
    pt = TestGrammar.Foo("{X}");
    assert(pt.successful);
    
    pt = TestGrammar.Bar("A B");
    assert(pt.successful);
    
    pt = TestGrammar.Bar("AB");
    assert(!pt.successful);
}
