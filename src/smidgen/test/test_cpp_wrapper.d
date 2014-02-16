/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_cpp_wrapper;

import std.stdio: writeln;

import unit_threaded.all;

import smidgen.ast.argument: Argument;
import smidgen.test.test_extras;
import smidgen.cpp_wrapper: getCPPWrapper;
import smidgen.test.test_ast_classes: checkEqualWS;


import smidgen.ast.klass: Klass;


void testConstructors() {
	Klass vtkRenderer = makeVtkRenderer();
	string wrapper = getCPPWrapper(vtkRenderer);
//	writeln(wrapper);
	checkEqualWS(wrapper, 
"		// These externs declare the functions in the D wrapper, used for virtual method calls
extern \"C\" void SMID_vtkRenderer_destructor(void* wrappedObject);


// This class is used to wrap virtual and protected methods. All instances created
// from D will be instantiated using this class.
class vtkRenderer_SMI: vtkRenderer {

public:
	bool inhibitDestructorCallbackToD;

// Constructors



// Protected and virtual method calls
public:


// Destructor
~vtkRenderer_SMI() {
	if (! inhibitDestructorCallbackToD) {
		deregisterDInstance(this);
		SMID_vtkRenderer_destructor(this);
	}	
}

};

//END VIRTUAL / PROTECTED CLASS ");
}