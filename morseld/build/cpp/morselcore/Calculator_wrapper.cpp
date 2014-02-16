
/*
* CPP Wrapper for Calculator
*/

#include <instance_tracker.h>

#include <calculator.h>



// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" void SMID_Calculator_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Calculator_SMI: Calculator {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static Calculator_SMI* SMIMake_Calculator(int a, int b) {
	Calculator_SMI* retVal = new Calculator_SMI(a, b);
	registerDInstance(retVal);
	return retVal;
};

private:
    Calculator_SMI(int a, int b): Calculator(a, b) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:


// Destructor
~Calculator_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Calculator_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" int Calculator_getFivePlusNum_SMIX2(int num) {

	int retValue = Calculator::getFivePlusNum(num);
	return retValue;

}

extern "C" int Calculator_multiply_SMIX3(Calculator* self, int a, int b) {

	int retValue = self->multiply(a, b);
	return retValue;

}

extern "C" double Calculator_multiply_SMIX4(Calculator* self, double a, double b) {

	double retValue = self->multiply(a, b);
	return retValue;

}

extern "C" int Calculator_add_SMIX5(Calculator* self, int a, int b) {

	int retValue = self->add(a, b);
	return retValue;

}

extern "C" void Calculator_doNothing_SMIX6(Calculator* self) {

	self->doNothing();

}

extern "C" void Calculator_doNothing2_SMIX7(Calculator* self) {

	self->doNothing2();

}

extern "C" Calculator_SMI* Calculator_Calculator_SMIX10(int a, int b) {
	
	Calculator_SMI* obj = Calculator_SMI::SMIMake_Calculator(a, b);
	return obj;
}



/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Calculator_CPPObject(Calculator* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Calculator_SMI_CPPObject(Calculator_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Calculator
