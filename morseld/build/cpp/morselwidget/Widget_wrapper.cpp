
/*
* CPP Wrapper for Widget
*/

#include <instance_tracker.h>

#include <widget.h>



// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" int SMID_Widget_getClassId_SMIX4(void* wrappedObject);
extern "C" void SMID_Widget_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Widget_SMI: Widget {

public:
	bool inhibitDestructorCallbackToD;

// Constructors



// Protected and virtual method calls
public:

int getClassId_fromDBase() {
	return Widget::getClassId();
}	
int getClassId() {
	// This can only be called from a C++ instance, never from a D instance
	
	int retValue = SMID_Widget_getClassId_SMIX4(this);
	return retValue;
}	


// Destructor
~Widget_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Widget_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" int Widget_getClassId_SMIX4(Widget* self) {

	if (isCreatedByD(self))  {
	int retValue = (( Widget_SMI*) self)->getClassId_fromDBase();
	return retValue;
	} else {
	int retValue = self->getClassId();
	return retValue;
	}

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Widget_CPPObject(Widget* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Widget_SMI_CPPObject(Widget_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Widget
