
#ifndef CALCULATOR_H
#define CALCULATOR_H

// A mixin class for doing calculations, used for testing multiple inheritance

class Calculator {

public:

	Calculator();

	Calculator(int baseFactor);

	virtual void doNothing() {}

	virtual void doNothing2() {}

	static int getFivePlusNum(int num) {
			return num + 5;
		}

	int multiply(int a, int b) {return a * b;}

	double multiply(double a, double b) {return a * b;}

	int add(int a, int b) { return a + b;}

protected:
	// include a protected constructor to make sure it is handled properly
	Calculator(int a, int b) {};

};

#endif
