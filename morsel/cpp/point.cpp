
#include <point.h>


Point::Point(int x, int y) {
	this->x = x;
	this->y = y;
}

Point::Point() {
	this->x = 0;
	this->y = 0;
}

Point& Point::operator+=(const Point &p)
{ x += p.x; y += p.y; return *this; }
