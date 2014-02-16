

class Shape {

%TypeHeaderCode
#include <shape.h>
%End

%TypeHeaderCodeD
import std.stdio;
%End

%TypeBodyCodeD
    string getADString(string s) {
        return s ~ "$$suffix";
    } 
%End

public:

	Shape();

	Shape(int a, int b);

	virtual int area()=0;

	virtual string getName();

	int getClassId();

};
