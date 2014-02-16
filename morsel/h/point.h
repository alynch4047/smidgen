
#ifndef POINT_H
#define POINT_H

#include <base.h>
#include <calculator.h>
#include <shape.h>


class Point: public Base {

	static const int classId = 3;

	int x;
	int y;

public:

	class Place;

	virtual int getClassId() {return classId;};

	Point();

	Point(int x, int y);

	int getX() { return x;}
	int getY() { return y;}

	Point& operator+=(const Point &p);

	int useCalculator(Calculator* calculator) {return calculator->multiply(2, 4);}

	Point::Place* getAPlace(Point::Place other) {
		Point::Place* newPlace = new Point::Place(other);
		return newPlace;
	}

	class Place: public Base {
		static const int classId = 7;
		int z;
	public:
		~Place() {}
		Place() {z = 0;};
		Place(const Place &other) {z = other.z; }
		Place &operator=(const Place &other) {z = other.z; }

		static string getThreePlusNum(string num) {return num + "3";}

		virtual int getClassId() {return classId;};

		int getZ() {return z;}
		void setZ(int z) {this->z = z;}

		virtual int getShapeAreaTimesZ(Shape& shape) {
			int area = shape.area();
			return area * z;
		}

	};

};

#endif
