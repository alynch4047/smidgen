
class RectWidget: Widget {

%TypeHeaderCode
#include <rect_widget.h>
%End

	public:

		int getWidth();
		int getHeight();
		Point getAPoint() /DName="getAPointD"/;
		RectWidget(Rect* rect);
		virtual int getClassId();

};
