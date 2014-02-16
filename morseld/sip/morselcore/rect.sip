

class Rect : Polygon, Calculator {

%TypeHeaderCode
#include <rect.h>
%End

public:

	Rect(int width, int height);
	
	Rect(string name);
	
	virtual mymorselint area();

	virtual string getName();
	
	char* getDesc(char* initVal);
	
	Rect* makeDoubledRect();
	
	static void incCount();

	int getClassId();
	
	virtual Point doubleMyPoint(Point&);
	
	int takeAnIntArray(int[2]);
	
	Point getMyPointDoubled(Point& point);
	
	virtual string extendNameWithString(string extension);
	
	virtual Rect* addRect(Rect* rect);
	
	virtual void doNothing(); 
	
	virtual int areaTimesThree();
	
	virtual void unknownFunc(UnKnownClass xxx);
	
	Point getTopLeftValue();

	Point& getTopLeftRef();	
	
	int getNameLength();
	
	string getExtendedName(string extension=abc);
	
	Calculator* getCalculator();
	
	
protected:
	int perimeter(int factor, string name);	

};
