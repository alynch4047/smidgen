
#ifndef SHAPE_H
#define SHAPE_H

#include <string>
#include <iostream>

#include <base.h>

using namespace std;

class Shape: public Base {

public:

	Shape();

	Shape(int a, int b);

	virtual int getClassId() {return classId;};

	string name;
	static const int classId = 1;

	virtual int area()=0;

	virtual string getName();

	~Shape() {

	}

};

#endif
