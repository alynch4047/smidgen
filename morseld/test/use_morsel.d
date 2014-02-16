
import std.stdio;
import std.string;
import std.conv;
import std.math: approxEqual;

import morselcore.Rect;
import morselcore.Point;
import morselcore.Polygon;
import morselcore.Calculator;
import morselcore.E.KeyboardModifier;
import morselcore.E.GlobalColor;

import morselwidget.Widget;
import morselwidget.RectWidget;

static string FIXED_NAME = "DummyNameFixed";
static string EXTENDED_NAME = "ExtendedName";


class BigRect: Rect {
	
	this(int width, int height) {
		super(width, height);
	}
	
	string strPerimeter(int factor, string name) {
		// perimeter is a protected method
		return to!string(this.perimeter(factor, name));
	}
	
}


class FixedRect: Rect {
	
	this(int width, int height) {
		super(width, height);
	}
	
	this(string name) {
		super(name);
	}
	
	override int area() {
		writeln("Base area is ", super.area());
		writeln("get the virt area!");
		return 100;
	}
	
	override string getName() {
		return FIXED_NAME;
	}
	
	override string extendNameWithString(string extension) {
		return EXTENDED_NAME;
	}
	
	override Point doubleMyPoint(Point point) {
		return new Point(100, 100);
	}
	
}


int multiplyByFive(Calculator calc, int number) {
	return calc.multiply(number, 5);
}


int main() {
	
	writeln("make rect 1");
	auto rect1 = new BigRect(4, 3);
	assert(rect1.createdBy == CreatedBy.D);
	writeln("make rect 2");
	auto rect2 = new Rect(4, 2);
	assert(rect2.createdBy == CreatedBy.D);
	
	assert(rect1.area() == 12);
	assert(rect2.area() == 8);
	
	string testCharS = "ABCDE";
	string resS = rect1.getDesc(testCharS);
	assert(resS == testCharS);
	
	// test returning references and values
	writeln("make point 1");
	auto p1 = new Point(5, 5);
	assert(p1.getX() == 5);
	Point p2 = rect2.getTopLeftRef();
	Point p3 = rect2.getTopLeftValue();
	writeln(p3.getX());
	assert(p3.getX() == 10);
	writeln(p2.getX());
	assert(p2.getX() == 10);
	
	// test indirectly getting same D created object twice returns same D wrapper
	
	
	// test getting same CPP created object twice returns equal objects
	Point p8 = rect2.getTopLeftRef();
	assert (p8 == p2);
	
	// test getting same CPP created object twice returns equal objects with sme hash value
	assert (p8.toHash() == p2.toHash());	
	
	// test enum values
	assert(GlobalColor.color1 == 1);
//	assert(KeyboardModifier.ControlModifier == 0x04000000);
	
	assert(rect1.getName() == "Rectname");
	
	assert(rect1.extendNameWithString("ABC") == "RectnameABC");

	assert(rect1.getNameLength() == 8);
	
	// test  pass reference to method
	Point p4 = new Point(8, 9);
	Point p5 = rect1.doubleMyPoint(p4);
	assert(p5.getX() == 16);
	assert(p5.getY() == 18);

	// test protected method
	assert(rect1.strPerimeter(2, "XYZ") == "28");
	
	Rect doubledRect = rect1.makeDoubledRect();
	assert(doubledRect.area() == 48);
	assert(doubledRect.createdBy == CreatedBy.CPP);
	
	// test virtual method
	Rect rect3 = new FixedRect(2, 3);
	assert(rect3.areaTimesThree() == 300);
	
	// test virtual method requiring conversion of returnType
	Rect rect4 = new FixedRect("Name1");
	assert(rect4.getNameLength() == FIXED_NAME.length);
	
	writeln("Get extended name ", rect4.getExtendedName("DEF"));
	assert(rect4.getExtendedName("DEF") == EXTENDED_NAME);
	
	// test virtual method taking a reference and returning a value 
	Point p6 = rect4.getMyPointDoubled(p4);
	assert(p6.getX() == 100);
	assert(p6.getY() == 100);
	
	// test passing an argument which in D is an interface (so has multiple inheritance
	// and requires adjusting the wrappedObj pointer) 
	assert(p6.useCalculator(rect4) == 8);
	
	// test getting a result of Point (Core class) from a Widget module class
	Rect rect5 = new Rect(3, 9);
	RectWidget rw1 = new RectWidget(rect5);
	Point p7 = rw1.getAPointD();
	
	// test nested classes
	Point.Place pp = new Point.Place();
	pp.setZ(11);
	assert(pp.getShapeAreaTimesZ(rect5) == 11 * 3 * 9); 
	
	// test get nested class from parent
	auto pp1 = p7.getAPlace(pp);
	assert(pp1.getZ() == 11);
	
	// test MethodCodeD for a member function
	double x = p7.getANumberMCD(2.13);
	assert(approxEqual(x, 21.3));
	
	// test using enums
	rect5.setColor(GlobalColor.blue);
	GlobalColor colorx = rect5.getColor();
	assert(colorx == GlobalColor.blue);
	
	// test using enums in virtual calls
	GlobalColor colory = rect5.swapColor(GlobalColor.red);
	assert(colory == GlobalColor.blue);
	assert(rect5.getColor() == GlobalColor.red);
	
	// test static calls
	int i1 = Rect.getFivePlusNum(2);
	assert(i1 == 7);
	// static call on a mixin class
	int i2 = Polygon.getFourPlusNum(2);
	assert(i2 == 6);
	// void static call
	Polygon.incCount();
	// static call with converted arguments and return value
	string s1 = Polygon.getCountS("A");
	assert(s1 == "5A");
	// static call on nested class
	string ans = Point.Place.getThreePlusNum("3");
	assert(ans == "33");
	
	// default values
	string retWithDefault = rect1.getExtendedName();
	assert(retWithDefault == "Rectnameabc");
	
	rect1.setSystemExiting();
	
	writeln("END"); stdout.flush();
	
	rect1.destroy();
	rect2.destroy();
	rect3.destroy();
	rect4.destroy();
	rect5.destroy();
	doubledRect.destroy();
	resS.destroy();
	p1.destroy();
	p2.destroy();
	p3.destroy();
	p4.destroy();
	p5.destroy();
	p6.destroy();
	p7.destroy();
	p8.destroy();
	pp.destroy();
	
	writeln("END2"); stdout.flush();
	
	return 0;
	
}