

#include <iostream>
#include <string.h>

#include <rect.h>
#include <rect_widget.h>
#include <enamespace.h>

using namespace std;


Calculator* castToCalculator(Rect* rect) {
	return rect;
}

int main() {

	Rect* rect1 = new Rect(10.0, 20.0);
	Rect* rect2 = new Rect(5.0, 4.0);

	cout << "area is " << rect1->area() << endl;

	cout << "Value of KeyboardModifier::ControlModifier is "
						<< E::ControlModifier << endl;

	char* testChar = new char[10];
	strcpy(testChar, "ABCDE");
    char* retChar = rect1->getDesc(testChar);
    cout << "retChar " << retChar << endl;

    Point& p1 = rect1->getTopLeftRef();
    cout << "p1X " << p1.getX() << endl;
    Point p2 = rect1->getTopLeftValue();
    cout << "p2X " << p2.getX() << endl;

    cout << "2 * 4 = " << rect1->multiply(2, 4) << endl;
    cout << "2.1 * 4 = " << rect1->multiply(2.1, 4.0) << endl;

    cout << "Rect* " << rect1 << endl;
    Calculator* calc = rect1->getCalculator();
    cout << "Calculator* " << calc << endl;
    bool eq = (rect1 == calc);
    cout << eq << endl;
    eq = (rect1 == rect2);
    cout << eq << endl;

    Calculator* calcCasted = castToCalculator(rect1);
    cout << "Calculator* casted " << calc <<  " Rect* " << rect1 << endl;

    Point* p4 = new Point(2, 3);
    int res = p4->useCalculator(rect1);
    cout << "calculator said " << res << endl;

    delete rect1;
    delete rect2;
    cout << "rect2 deleted" << endl;

    Rect* rect4 = new Rect(1.0, 2.0);
    RectWidget* rectWidget1 = new RectWidget(rect4);
    cout << "rectwidget width " << rectWidget1->getWidth() << endl;

    Rect* rect3 = new Rect(8.0, 3.0);
    Point::Place* place1 = new Point::Place();
    place1->setZ(12);
    cout << "place area times z " << place1->getShapeAreaTimesZ(*rect3) << endl ;
    delete rect3;
    delete place1;

	return 0;
}
