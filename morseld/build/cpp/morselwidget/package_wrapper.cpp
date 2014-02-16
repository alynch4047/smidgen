#include <instance_tracker.h>

// Headers for converters

#include <string>
using namespace std;
// Converter functions
int convertPPCharToInt(char** toConvert) {
	return 0;
 }

char** convertIntToPPChar(int toConvert) {
	return (char**) 0;
}

char* convertCStringToPChar(string toConvert) {
			return (char*) toConvert.c_str();
   		 }

string convertPCharToCString(char* toConvert) {
			return *(new string(toConvert));
		}

char* convertPCharToPChar(char* toConvert) {
			return toConvert;
   		 }

char* convertPCharToPCharArgument(char* toConvert) {
			return toConvert;
   		 }

#include <shape.h>

extern "C" const char* getClassNameC(char* baseClassName, void* wrappedObject) {
	Base* obj = (Base*) wrappedObject;
	switch (obj->getClassId()) {
		case 1:
			return "Shape";
        case 2:
        	return "Rect";
        case 3:
        	return "Point";
        case 4:
        	return "Polygon";
        case 5:
        	return "Widget";
        case 6:
        	return "RectWidget";
        case 7:
            return "Point.Place";
        default:
            return "MorselUnknownClass";
     }
}
