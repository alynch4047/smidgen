

#include <polygon.h>


int Polygon::area() {
		return 1;
	}


Polygon::Polygon(string name): Shape() {
	numSides = 4;
	this->name = name;
	myText = "abc";
}


const char* Polygon::getConstChar() {
	return myText;
}

const char* Polygon::getConstCharVirtual() {
	return myText;
}

const char* Polygon::getConstCharProtected() {
	return myText;
}


