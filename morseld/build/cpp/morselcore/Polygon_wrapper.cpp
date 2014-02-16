
/*
* CPP Wrapper for Polygon
*/

#include <instance_tracker.h>

#include <polygon.h>

// Headers for converters
using namespace std;
#include <string>


// Externs for converters
extern char* convertPCharToPChar(char* toConvert);
extern char* convertPCharToPCharArgument(char* toConvert);
extern char* convertCStringToPChar(string toConvert);
extern string convertPCharToCString(char* toConvert);
// End of header section for converters


// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" int SMID_Polygon_getClassId_SMIX5(void* wrappedObject);
extern "C" int SMID_Polygon_area_SMIX6(void* wrappedObject);
extern "C" char* SMID_Polygon_getConstCharVirtual_SMIX10(void* wrappedObject);
extern "C" int SMID_Polygon_swapColor_SMIX13(void* wrappedObject, int color___SMI);
extern "C" void SMID_Polygon_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Polygon_SMI: Polygon {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static Polygon_SMI* SMIMake_Polygon(string name) {
	Polygon_SMI* retVal = new Polygon_SMI(name);
	registerDInstance(retVal);
	return retVal;
};

private:
    Polygon_SMI(string name): Polygon(name) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:

int getClassId_fromDBase() {
	return Polygon::getClassId();
}	
int getClassId() {
	// This can only be called from a C++ instance, never from a D instance
	
	int retValue = SMID_Polygon_getClassId_SMIX5(this);
	return retValue;
}	

int area_fromDBase() {
	return Polygon::area();
}	
int area() {
	// This can only be called from a C++ instance, never from a D instance
	
	int retValue = SMID_Polygon_area_SMIX6(this);
	return retValue;
}	

const char* getConstCharVirtual_fromDBase() {
	return Polygon::getConstCharVirtual();
}	
const char* getConstCharVirtual() {
	// This can only be called from a C++ instance, never from a D instance
	
	char* retValue = SMID_Polygon_getConstCharVirtual_SMIX10(this);
	return convertPCharToPCharArgument(retValue);
}	

E::GlobalColor swapColor_fromDBase(E::GlobalColor color) {
	return Polygon::swapColor(color);
}	
E::GlobalColor swapColor(E::GlobalColor color___SMI) {
	// This can only be called from a C++ instance, never from a D instance
	int color = (int) color___SMI;

	int retValue = SMID_Polygon_swapColor_SMIX13(this, color);
	return (E::GlobalColor) retValue;
}	

const char* getConstCharProtected_fromDBase() {
	return Polygon::getConstCharProtected();
}

// Destructor
~Polygon_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Polygon_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" int Polygon_getFourPlusNum_SMIX2(int num) {

	int retValue = Polygon::getFourPlusNum(num);
	return retValue;

}

extern "C" void Polygon_incCount_SMIX3() {

	Polygon::incCount();

}

extern "C" char* Polygon_getCountS_SMIX4(char* suffix___SMI)  {
	string suffix = convertPCharToCString(suffix___SMI);

	string retValue = Polygon::getCountS(suffix);
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;

}

extern "C" int Polygon_getClassId_SMIX5(Polygon* self) {

	if (isCreatedByD(self))  {
	int retValue = (( Polygon_SMI*) self)->getClassId_fromDBase();
	return retValue;
	} else {
	int retValue = self->getClassId();
	return retValue;
	}

}

extern "C" int Polygon_area_SMIX6(Polygon* self) {

	if (isCreatedByD(self))  {
	int retValue = (( Polygon_SMI*) self)->area_fromDBase();
	return retValue;
	} else {
	int retValue = self->area();
	return retValue;
	}

}

extern "C" Polygon_SMI* Polygon_Polygon_SMIX7(char* name___SMI) {
	string name = convertPCharToCString(name___SMI);

	Polygon_SMI* obj = Polygon_SMI::SMIMake_Polygon(name);
	return obj;
}


extern "C" char* Polygon_getConstChar_SMIX9(Polygon* self)  {

	char* retValue = const_cast<char*> (self->getConstChar());
	char* convertedRetValue = convertPCharToPChar(retValue);
	return convertedRetValue;

}

extern "C" char* Polygon_getConstCharVirtual_SMIX10(Polygon* self)  {

	if (isCreatedByD(self))  {
	char* retValue = const_cast<char*> ((( Polygon_SMI*) self)->getConstCharVirtual_fromDBase());
	char* convertedRetValue = convertPCharToPChar(retValue);
	return convertedRetValue;
	} else {
	char* retValue = const_cast<char*> (self->getConstCharVirtual());
	char* convertedRetValue = convertPCharToPChar(retValue);
	return convertedRetValue;
	}

}

extern "C" void Polygon_setColor_SMIX11(Polygon* self, int color___SMI) {
	E::GlobalColor color = (E::GlobalColor) color___SMI;

	self->setColor(color);

}

extern "C" int Polygon_getColor_SMIX12(Polygon* self)  {

	E::GlobalColor retValue = self->getColor();
	int convertedRetValue = (int) retValue;
	return convertedRetValue;

}

extern "C" int Polygon_swapColor_SMIX13(Polygon* self, int color___SMI)  {
	E::GlobalColor color = (E::GlobalColor) color___SMI;

	if (isCreatedByD(self))  {
	E::GlobalColor retValue = (( Polygon_SMI*) self)->swapColor_fromDBase(color);
	int convertedRetValue = (int) retValue;
	return convertedRetValue;
	} else {
	E::GlobalColor retValue = self->swapColor(color);
	int convertedRetValue = (int) retValue;
	return convertedRetValue;
	}

}

extern "C" char* Polygon_getConstCharProtected_SMIX15(Polygon* self)  {

	if (isCreatedByD(self))  {
	char* retValue = const_cast<char*> ((( Polygon_SMI*) self)->getConstCharProtected_fromDBase());
	char* convertedRetValue = convertPCharToPChar(retValue);
	return convertedRetValue;
	}

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Polygon_CPPObject(Polygon* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Polygon_SMI_CPPObject(Polygon_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Polygon
