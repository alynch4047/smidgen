
/*
* CPP Wrapper for Point
*/

#include <instance_tracker.h>

#include <point.h>



// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" void SMID_Point_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Point_SMI: Point {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static Point_SMI* SMIMake_Point() {
	Point_SMI* retVal = new Point_SMI();
	registerDInstance(retVal);
	return retVal;
};

private:
    Point_SMI(): Point() {inhibitDestructorCallbackToD = false;};


public:
	
static Point_SMI* SMIMake_Point(int x, int y) {
	Point_SMI* retVal = new Point_SMI(x, y);
	registerDInstance(retVal);
	return retVal;
};

private:
    Point_SMI(int x, int y): Point(x, y) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:


// Destructor
~Point_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Point_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" Point_SMI* Point_Point_SMIX5() {
	
	Point_SMI* obj = Point_SMI::SMIMake_Point();
	return obj;
}


extern "C" Point_SMI* Point_Point_SMIX6(int x, int y) {
	
	Point_SMI* obj = Point_SMI::SMIMake_Point(x, y);
	return obj;
}


extern "C" int Point_getX_SMIX7(Point* self) {

	int retValue = self->getX();
	return retValue;

}

extern "C" int Point_getY_SMIX8(Point* self) {

	int retValue = self->getY();
	return retValue;

}

extern "C" Point& Point_operatorplusequals_SMIX9(Point* self, const Point& p) {

	Point& retValue = self->operator+=(p);
	return retValue;

}

extern "C" int Point_useCalculator_SMIX10(Point* self, Calculator* calculator) {

	int retValue = self->useCalculator(calculator);
	return retValue;

}

extern "C" double Point_getANumberMCD_SMIX11(Point* self, double x) {

	return 10 * x;

}

extern "C" Point::Place* Point_getAPlace_SMIX13(Point* self, Point::Place other) {

	Point::Place* retValue = self->getAPlace(other);
	return retValue;

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Point_CPPObject(Point* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Point_SMI_CPPObject(Point_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Point
