
/*
* CPP Wrapper for Shape
*/

#include <instance_tracker.h>

#include <shape.h>

// Headers for converters
#include <string>

// Externs for converters
extern char* convertCStringToPChar(string toConvert);
extern string convertPCharToCString(char* toConvert);
// End of header section for converters


// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" char* SMID_Shape_getName_SMIX7(void* wrappedObject);
extern "C" void SMID_Shape_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Shape_SMI: Shape {

public:
	bool inhibitDestructorCallbackToD;

// Constructors



// Protected and virtual method calls
public:

string getName_fromDBase() {
	return Shape::getName();
}	
string getName() {
	// This can only be called from a C++ instance, never from a D instance
	
	char* retValue = SMID_Shape_getName_SMIX7(this);
	return convertPCharToCString(retValue);
}	


// Destructor
~Shape_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Shape_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" char* Shape_getName_SMIX7(Shape* self)  {

	if (isCreatedByD(self))  {
	string retValue = (( Shape_SMI*) self)->getName_fromDBase();
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;
	} else {
	string retValue = self->getName();
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;
	}

}

extern "C" int Shape_getClassId_SMIX8(Shape* self) {

	int retValue = self->getClassId();
	return retValue;

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Shape_CPPObject(Shape* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Shape_SMI_CPPObject(Shape_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Shape
