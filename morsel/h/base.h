

#ifndef BASE_H
#define BASE_H

typedef int mymorselint;

class Base {

public:

	static const int classId = 0;

	virtual int getClassId() {return classId;};

};

#endif
