
/*
* CPP Wrapper for Place
*/

#include <instance_tracker.h>

    #include <point.h>

// Headers for converters
#include <string>

// Externs for converters
extern char* convertCStringToPChar(string toConvert);
extern string convertPCharToCString(char* toConvert);
// End of header section for converters


// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" int SMID_Point_Place_getShapeAreaTimesZ_SMIX12(void* wrappedObject, Shape& shape);
extern "C" void SMID_Place_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Point_Place_SMI: Point::Place {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static Point_Place_SMI* SMIMake_Place() {
	Point_Place_SMI* retVal = new Point_Place_SMI();
	registerDInstance(retVal);
	return retVal;
};

private:
    Point_Place_SMI(): Place() {inhibitDestructorCallbackToD = false;};


public:
	
static Point_Place_SMI* SMIMake_Place(const Point::Place& other) {
	Point_Place_SMI* retVal = new Point_Place_SMI(other);
	registerDInstance(retVal);
	return retVal;
};

private:
    Point_Place_SMI(const Point::Place& other): Place(other) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:

int getShapeAreaTimesZ_fromDBase(Shape& shape) {
	return Place::getShapeAreaTimesZ(shape);
}	
int getShapeAreaTimesZ(Shape& shape) {
	// This can only be called from a C++ instance, never from a D instance
	
	int retValue = SMID_Point_Place_getShapeAreaTimesZ_SMIX12(this, shape);
	return retValue;
}	


// Destructor
~Point_Place_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Place_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" Point_Place_SMI* Point_Place_Place_SMIX4() {
	
	Point_Place_SMI* obj = Point_Place_SMI::SMIMake_Place();
	return obj;
}


extern "C" Point_Place_SMI* Point_Place_Place_SMIX5(const Point::Place& other) {
	
	Point_Place_SMI* obj = Point_Place_SMI::SMIMake_Place(other);
	return obj;
}


extern "C" Point::Place& Point_Place_operatorequals_SMIX6(Point::Place* self, const Point::Place& other) {

	Point::Place& retValue = self->operator=(other);
	return retValue;

}

extern "C" char* Point_Place_getThreePlusNum_SMIX7(char* num___SMI)  {
	string num = convertPCharToCString(num___SMI);

	string retValue = Point::Place::getThreePlusNum(num);
	char* convertedRetValue = convertCStringToPChar(retValue);
	return convertedRetValue;

}

extern "C" int Point_Place_getZ_SMIX8(Point::Place* self) {

	int retValue = self->getZ();
	return retValue;

}

extern "C" void Point_Place_setZ_SMIX9(Point::Place* self, int z) {

	self->setZ(z);

}

extern "C" int Point_Place_getShapeAreaTimesZ_SMIX12(Point::Place* self, Shape& shape) {

	if (isCreatedByD(self))  {
	int retValue = (( Point_Place_SMI*) self)->getShapeAreaTimesZ_fromDBase(shape);
	return retValue;
	} else {
	int retValue = self->getShapeAreaTimesZ(shape);
	return retValue;
	}

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Point_Place_CPPObject(Point::Place* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Point_Point_Place_SMI_CPPObject(Point_Place_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Place
