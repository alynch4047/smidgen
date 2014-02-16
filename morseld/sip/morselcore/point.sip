

struct Point {

%TypeHeaderCode
#include <point.h>
%End

private:

	int x;
	int y;

public:

	Point();

	Point(int x, int y);
	
	int getX();
	int getY();

	Point& operator+=(const Point &p);

	int useCalculator(Calculator* calculator);
	
    double getANumberMCD(double x);
%MethodCodeD
    return 10 * x;
%End	
	
	Point::Place* getAPlace(Point::Place other);
	
	class Place {
	
	%TypeHeaderCode
    #include <point.h>
    %End
	
		int z;
	public:
		~Place();
		Place();
		Place(const Place &other);
		Place &operator=(const Place &other);
		
		static string getThreePlusNum(string num);
		
		int getZ();
		void setZ(int z) ;
		// include a method that should cause the import of a new class in
		// the D wrapper (i.e. Shape)
		virtual int getShapeAreaTimesZ(Shape& shape);
	
	};

};