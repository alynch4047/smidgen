
/*
* CPP Wrapper for RectWidget
*/

#include <instance_tracker.h>

#include <rect_widget.h>



// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" int SMID_RectWidget_getClassId_SMIX6(void* wrappedObject);
extern "C" void SMID_RectWidget_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class RectWidget_SMI: RectWidget {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static RectWidget_SMI* SMIMake_RectWidget(Rect* rect) {
	RectWidget_SMI* retVal = new RectWidget_SMI(rect);
	registerDInstance(retVal);
	return retVal;
};

private:
    RectWidget_SMI(Rect* rect): RectWidget(rect) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:

int getClassId_fromDBase() {
	return RectWidget::getClassId();
}	
int getClassId() {
	// This can only be called from a C++ instance, never from a D instance
	
	int retValue = SMID_RectWidget_getClassId_SMIX6(this);
	return retValue;
}	


// Destructor
~RectWidget_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_RectWidget_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" int RectWidget_getWidth_SMIX2(RectWidget* self) {

	int retValue = self->getWidth();
	return retValue;

}

extern "C" int RectWidget_getHeight_SMIX3(RectWidget* self) {

	int retValue = self->getHeight();
	return retValue;

}

extern "C" Point* RectWidget_getAPoint_SMIX4(RectWidget* self) {

	Point retValue = self->getAPoint();
	Point* copiedRetValue = new Point(retValue);
	return copiedRetValue;

}

extern "C" RectWidget_SMI* RectWidget_RectWidget_SMIX5(Rect* rect) {
	
	RectWidget_SMI* obj = RectWidget_SMI::SMIMake_RectWidget(rect);
	return obj;
}


extern "C" int RectWidget_getClassId_SMIX6(RectWidget* self) {

	if (isCreatedByD(self))  {
	int retValue = (( RectWidget_SMI*) self)->getClassId_fromDBase();
	return retValue;
	} else {
	int retValue = self->getClassId();
	return retValue;
	}

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_RectWidget_CPPObject(RectWidget* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_RectWidget_SMI_CPPObject(RectWidget_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for RectWidget
