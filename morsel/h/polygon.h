

#ifndef POLYGON_H
#define POLYGON_H

#include <sstream>
#include <string>

#include <shape.h>
#include <enamespace.h>

class make_string {
public:
  template <typename T>
  make_string& operator<<( T const & val ) {
    buffer_ << val;
    return *this;
  }
  operator std::string() const {
    return buffer_.str();
  }
private:
  std::ostringstream buffer_;
};


class Polygon: public Shape {

	static const int classId = 4;

	int numSides;

	E::GlobalColor color;

	char* myText;

public:

	static int getFourPlusNum(int num) {
		return num + 4;
	}

	static void incCount() {}

	static string getCountS(string suffix) {
		string sCount = make_string() << 5;
		return sCount + suffix;
	}

	virtual int getClassId() {return classId;};

	virtual int area();

	void setColor(E::GlobalColor color) {
		this->color = color;
	}

	E::GlobalColor getColor() {
		return this->color;
	}

	virtual E::GlobalColor swapColor(E::GlobalColor color) {
		E::GlobalColor temp = this->color;
		this->color = color;
		return temp;
	}

	const char* getConstChar();

	virtual const char* getConstCharVirtual();

	Polygon(string name);

protected:
	const char* getConstCharProtected();

};

#endif
