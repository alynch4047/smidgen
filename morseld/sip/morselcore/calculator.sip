

class Calculator {

%TypeHeaderCode
#include <calculator.h>
%End

public:

    static int getFivePlusNum(int num);

	int multiply(int a, int b) ;

	double multiply (double a, double b);

	int add(int a, int b) ;
	
	void doNothing();

	void doNothing2();
	
protected:
    // include a protected constructor to make sure it is handled properly
    Calculator(int a, int b);	

};