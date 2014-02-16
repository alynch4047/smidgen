
#include <rect_widget.h>


int RectWidget::getWidth() {
	 return rect->area() / 2;
}


int RectWidget::getHeight() {
	 return rect->area() / 2;
}

RectWidget::RectWidget(Rect* rect) {
	 this->rect = rect;
}

Point RectWidget::getAPoint() {
	Point p1(2, 3);
	return p1;
}
