module unit_threaded.options;

import std.getopt;
import std.stdio;

struct Options {
    immutable bool multiThreaded;
    immutable string[] tests;
    immutable bool debugOutput;
    immutable bool list;
    immutable bool exit;
};

/**
 * Parses the command-line args and returns Options
 */
auto getOptions(string[] args) {
    bool single;
    bool debugOutput;
    bool help;
    bool list;
    getopt(args,
           "single|s", &single, //single-threaded
           "debug|d", &debugOutput, //print debug output
           "help|h", &help,
           "list|l", &list);
    if(help) {
        writeln("Usage: <progname> <options> <tests>...\n",
                "Options: \n",
                "   -h: help\n"
                "   -s: single-threaded\n",
                "   -l: list tests\n",
                "   -d: enable debug output\n");
    }

    if(debugOutput) {
        if(!single) {
            stderr.writeln("\n***** Cannot use -d without -s, forcing -s *****\n\n");
        }
        single = true;
    }
    immutable exit =  help || list;
    return Options(!single, args[1..$].dup, debugOutput, list, exit);
}
