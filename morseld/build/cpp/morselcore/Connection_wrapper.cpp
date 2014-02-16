
/*
* CPP Wrapper for Connection
*/

#include <instance_tracker.h>



// These externs declare the functions in the D wrapper, used for virtual method calls
extern "C" void SMID_Connection_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class Connection_SMI: Connection {

public:
	bool inhibitDestructorCallbackToD;

// Constructors


public:
	
static Connection_SMI* SMIMake_Connection(const Connection& other) {
	Connection_SMI* retVal = new Connection_SMI(other);
	registerDInstance(retVal);
	return retVal;
};

private:
    Connection_SMI(const Connection& other): Connection(other) {inhibitDestructorCallbackToD = false;};



// Protected and virtual method calls
public:


// Destructor
~Connection_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_Connection_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS 


extern "C" Connection_SMI* Connection_Connection_SMIX4(const Connection& other) {
	
	Connection_SMI* obj = Connection_SMI::SMIMake_Connection(other);
	return obj;
}


extern "C" Connection& Connection_operatorequals_SMIX5(Connection* self, const Connection& other) {

	Connection& retValue = self->operator=(other);
	return retValue;

}


/*
* Function to delete CPP objects, called from D destructor
*/
extern "C" void SMI_delete_Connection_CPPObject(Connection* obj) {
	delete obj;
}

/*
* Function to delete CPP Wrapper objects, called from D destructor
*/
extern "C" void SMI_delete_Connection_SMI_CPPObject(Connection_SMI* obj) {
	deregisterDInstance(obj);
	obj->inhibitDestructorCallbackToD = true;
	delete obj;
}

// End CPP Wrapper for Connection
