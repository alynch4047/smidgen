
/*
* CPP Wrapper for Rect
*/

#include <instance_tracker.h>

#include <rect.h>

// Headers for converters
using namespace std;
#include <string>

// Externs for converters
extern char* convertPCharToPChar(char* toConvert);
extern char* convertPCharToPCharArgument(char* toConvert);
extern char* convertCStringToPChar(string toConvert);
extern string convertPCharToCString(char* toConvert);
// End of header section for converters
// Functions that upcast pointers to a base class

extern "C" Calculator* castRectAsCalculator(Rect* obj) {
	return obj;
}


// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" mymorselint SMID_Rect_area_SMIX4(void* wrappedObject);
extern "C" char* SMID_Rect_getName_SMIX5(void* wrappedObject);
extern "C" Point* SMID_Rect_doubleMyPoint_SMIX10(void* wrappedObject, Point& arg0);
extern "C" char* SMID_Rect_extendNameWithString_SMIX13(void* wrappedObject, char* extension___SMI);
extern "C" Rect* SMID_Rect_addRect_SMIX14(void* wrappedObject, Rect* rect);
extern "C" void SMID_Rect_doNothing_SMIX15(void* wrappedObject);
extern "C" int SMID_Rect_areaTimesThree_SMIX16(void* wrappedObject);
extern "C" void SMID_Rect_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Rect_SMI: Rect {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static Rect_SMI* SMIMake_Rect(int width, int height) {
	Rect_SMI* retVal = new Rect_SMI(width, height);
	registerDInstance(retVal);
	return retVal;
};

private:
    Rect_SMI(int width, int height): Rect(width, height) {inhibitDestructorCallbackToD = false;};


public:
	
static Rect_SMI* SMIMake_Rect(string name) {
	Rect_SMI* retVal = new Rect_SMI(name);
	registerDInstance(retVal);
	return retVal;
};

private:
    Rect_SMI(string name): Rect(name) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:

mymorselint area_fromDBase() {
	return Rect::area();
}	
mymorselint area() {
	// This can only be called from a C++ instance, never from a D instance
	
	mymorselint retValue = SMID_Rect_area_SMIX4(this);
	return retValue;
}	

string getName_fromDBase() {
	return Rect::getName();
}	
string getName() {
	// This can only be called from a C++ instance, never from a D instance
	
	char* retValue = SMID_Rect_getName_SMIX5(this);
	return convertPCharToCString(retValue);
}	

Point doubleMyPoint_fromDBase(Point& arg0) {
	return Rect::doubleMyPoint(arg0);
}	
Point doubleMyPoint(Point& arg0) {
	// This can only be called from a C++ instance, never from a D instance
	
	void* retValue = SMID_Rect_doubleMyPoint_SMIX10(this, arg0);
	return *((Point*) retValue);
}	

string extendNameWithString_fromDBase(string extension) {
	return Rect::extendNameWithString(extension);
}	
string extendNameWithString(string extension___SMI) {
	// This can only be called from a C++ instance, never from a D instance
	char* extension = convertCStringToPChar(extension___SMI);

	char* retValue = SMID_Rect_extendNameWithString_SMIX13(this, extension);
	return convertPCharToCString(retValue);
}	

Rect* addRect_fromDBase(Rect* rect) {
	return Rect::addRect(rect);
}	
Rect* addRect(Rect* rect) {
	// This can only be called from a C++ instance, never from a D instance
	
	void* retValue = SMID_Rect_addRect_SMIX14(this, rect);
	return (Rect*) retValue;
}	

void doNothing_fromDBase() {
	return Rect::doNothing();
}	
void doNothing() {
	// This can only be called from a C++ instance, never from a D instance
	
	SMID_Rect_doNothing_SMIX15(this);
}	

int areaTimesThree_fromDBase() {
	return Rect::areaTimesThree();
}	
int areaTimesThree() {
	// This can only be called from a C++ instance, never from a D instance
	
	int retValue = SMID_Rect_areaTimesThree_SMIX16(this);
	return retValue;
}	

int perimeter_fromDBase(int factor, string name) {
	return Rect::perimeter(factor, name);
}

// Destructor
~Rect_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Rect_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" Rect_SMI* Rect_Rect_SMIX2(int width, int height) {
	
	Rect_SMI* obj = Rect_SMI::SMIMake_Rect(width, height);
	return obj;
}


extern "C" Rect_SMI* Rect_Rect_SMIX3(char* name___SMI) {
	string name = convertPCharToCString(name___SMI);

	Rect_SMI* obj = Rect_SMI::SMIMake_Rect(name);
	return obj;
}


extern "C" mymorselint Rect_area_SMIX4(Rect* self) {

	if (isCreatedByD(self))  {
	mymorselint retValue = (( Rect_SMI*) self)->area_fromDBase();
	return retValue;
	} else {
	mymorselint retValue = self->area();
	return retValue;
	}

}

extern "C" char* Rect_getName_SMIX5(Rect* self)  {

	if (isCreatedByD(self))  {
	string retValue = (( Rect_SMI*) self)->getName_fromDBase();
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;
	} else {
	string retValue = self->getName();
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;
	}

}

extern "C" char* Rect_getDesc_SMIX6(Rect* self, char* initVal___SMI)  {
	char* initVal = convertPCharToPCharArgument(initVal___SMI);

	char* retValue = self->getDesc(initVal);
	char* convertedRetValue = convertPCharToPChar(retValue);
	return convertedRetValue;

}

extern "C" Rect* Rect_makeDoubledRect_SMIX7(Rect* self) {

	Rect* retValue = self->makeDoubledRect();
	return retValue;

}

extern "C" void Rect_incCount_SMIX8() {

	Rect::incCount();

}

extern "C" int Rect_getClassId_SMIX9(Rect* self) {

	int retValue = self->getClassId();
	return retValue;

}

extern "C" Point* Rect_doubleMyPoint_SMIX10(Rect* self, Point& arg0) {

	if (isCreatedByD(self))  {
	Point retValue = (( Rect_SMI*) self)->doubleMyPoint_fromDBase(arg0);
	Point* copiedRetValue = new Point(retValue);
	return copiedRetValue;
	} else {
	Point retValue = self->doubleMyPoint(arg0);
	Point* copiedRetValue = new Point(retValue);
	return copiedRetValue;
	}

}

extern "C" Point* Rect_getMyPointDoubled_SMIX12(Rect* self, Point& point) {

	Point retValue = self->getMyPointDoubled(point);
	Point* copiedRetValue = new Point(retValue);
	return copiedRetValue;

}

extern "C" char* Rect_extendNameWithString_SMIX13(Rect* self, char* extension___SMI)  {
	string extension = convertPCharToCString(extension___SMI);

	if (isCreatedByD(self))  {
	string retValue = (( Rect_SMI*) self)->extendNameWithString_fromDBase(extension);
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;
	} else {
	string retValue = self->extendNameWithString(extension);
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;
	}

}

extern "C" Rect* Rect_addRect_SMIX14(Rect* self, Rect* rect) {

	if (isCreatedByD(self))  {
	Rect* retValue = (( Rect_SMI*) self)->addRect_fromDBase(rect);
	return retValue;
	} else {
	Rect* retValue = self->addRect(rect);
	return retValue;
	}

}

extern "C" void Rect_doNothing_SMIX15(Rect* self) {

	if (isCreatedByD(self))  {
	(( Rect_SMI*) self)->doNothing_fromDBase();
	} else {
	self->doNothing();
	}

}

extern "C" int Rect_areaTimesThree_SMIX16(Rect* self) {

	if (isCreatedByD(self))  {
	int retValue = (( Rect_SMI*) self)->areaTimesThree_fromDBase();
	return retValue;
	} else {
	int retValue = self->areaTimesThree();
	return retValue;
	}

}

extern "C" Point* Rect_getTopLeftValue_SMIX18(Rect* self) {

	Point retValue = self->getTopLeftValue();
	Point* copiedRetValue = new Point(retValue);
	return copiedRetValue;

}

extern "C" Point& Rect_getTopLeftRef_SMIX19(Rect* self) {

	Point& retValue = self->getTopLeftRef();
	return retValue;

}

extern "C" int Rect_getNameLength_SMIX20(Rect* self) {

	int retValue = self->getNameLength();
	return retValue;

}

extern "C" char* Rect_getExtendedName_SMIX21(Rect* self, char* extension___SMI)  {
	string extension = convertPCharToCString(extension___SMI);

	string retValue = self->getExtendedName(extension);
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;

}

extern "C" Calculator* Rect_getCalculator_SMIX22(Rect* self) {

	Calculator* retValue = self->getCalculator();
	return retValue;

}

extern "C" int Rect_perimeter_SMIX24(Rect* self, int factor, char* name___SMI) {
	string name = convertPCharToCString(name___SMI);

	if (isCreatedByD(self))  {
	int retValue = (( Rect_SMI*) self)->perimeter_fromDBase(factor, name);
	return retValue;
	}

}

extern "C" int Rect_getFivePlusNum_SMIX2(int num) {

	int retValue = Rect::getFivePlusNum(num);
	return retValue;

}

extern "C" int Rect_multiply_SMIX3(Rect* self, int a, int b) {

	int retValue = self->multiply(a, b);
	return retValue;

}

extern "C" double Rect_multiply_SMIX4(Rect* self, double a, double b) {

	double retValue = self->multiply(a, b);
	return retValue;

}

extern "C" int Rect_add_SMIX5(Rect* self, int a, int b) {

	int retValue = self->add(a, b);
	return retValue;

}

extern "C" void Rect_doNothing2_SMIX7(Rect* self) {

	self->doNothing2();

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Rect_CPPObject(Rect* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Rect_SMI_CPPObject(Rect_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Rect
