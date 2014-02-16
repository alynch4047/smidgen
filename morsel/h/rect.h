

#ifndef RECT_H
#define RECT_H

#include <string>
#include <iostream>

#include <polygon.h>
#include <point.h>
#include <calculator.h>

using namespace std;


class Rect: public Polygon, public Calculator {

	static const int classId = 2;

	int width, height;

	Point topLeft;

public:

	virtual int getClassId() {return classId;};

	virtual int area() ;

	Rect(int width, int height);

	Rect(string name);

	static void incCount() {}

	char* getDesc(char* initVal);

	Rect* makeDoubledRect();

	Rect* getRectAttribute();

	Calculator* getCalculator() {return this;}

	virtual string extendNameWithString(string extension) {
		return name + extension;
	}

	string getExtendedName(string extension) {
		// test virtual function call
		return extendNameWithString(extension);
	}

	virtual void doNothing();

	virtual Rect* addRect(Rect* rect);

	virtual Point doubleMyPoint(Point&);

	Point getMyPointDoubled(Point& point) {
		// test virtual function call
		return doubleMyPoint(point);
	}

	int areaTimesThree();

	Point getTopLeftValue();

	Point& getTopLeftRef();

	int getNameLength() {
		// test virtual function call
		return (int) getName().length();
	}


protected:
	virtual int perimeter(int factor, string name);

};

#endif
