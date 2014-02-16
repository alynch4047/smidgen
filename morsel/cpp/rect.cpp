

#include <rect.h>


int Rect::area() {
		return width * height;
	}

Rect::Rect(int width, int height) : Polygon("Rectname") {
	this->width = width;
	this->height = height;
//	this->name = "Rectname";
	this->topLeft = Point(10, 20);
}

Rect::Rect(string name): Polygon(name), width(1), height(1) {
}

char* Rect::getDesc(char* initVal) {
	return initVal;
}

Point Rect::doubleMyPoint(Point& point) {
	return Point(point.getX() * 2, point.getY() * 2);
}

Rect* Rect::makeDoubledRect() {
	return new Rect(width * 2, height * 2);
}

Rect* Rect::addRect(Rect* rect) {
	Rect* newRect = new Rect(this->width + rect->width, this->height + rect->height);
	return newRect;
}

int Rect::perimeter(int factor, string name) {
	return (width + height) * 2 * factor;
}

void Rect::doNothing() {}

int Rect::areaTimesThree() {
	return area() * 3;
}

Point Rect::getTopLeftValue() {
	return topLeft;
}

Point& Rect::getTopLeftRef() {
	return topLeft;
}
