

class Polygon: Shape {

%TypeHeaderCode
#include <polygon.h>
%End

public:

    static int getFourPlusNum(int num);
    
    static void incCount();

    static string getCountS(string suffix);

	virtual int getClassId();

	virtual int area();

	Polygon(string name);
	
	// need a const return type for testing ( + virtual, protected etc.)
	const char* getConstChar();
	
	virtual const char* getConstCharVirtual();
	
	void setColor(E::GlobalColor color);

    E::GlobalColor getColor();
    
    virtual E::GlobalColor swapColor(E::GlobalColor color=E::green);
	
protected:
    const char* getConstCharProtected();
	

};