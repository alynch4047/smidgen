
#ifndef WIDGET_H
#define WIDGET_H

#include <base.h>


class Widget: public Base {

	static const int classId = 5;

public:

	virtual int getWidth()=0;
	virtual int getHeight()=0;

	virtual int getClassId() {return classId;};

};

#endif
