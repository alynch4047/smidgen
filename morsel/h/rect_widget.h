
#ifndef RECTWIDGET_H
#define RECTWIDGET_H

#include <rect.h>
#include <widget.h>


class RectWidget: public Widget {

	static const int classId = 6;

	Rect* rect;

	public:

		int getWidth();
		int getHeight();

		RectWidget(Rect* rect);

		Point getAPoint();

		virtual int getClassId() {return classId;};

};

#endif
