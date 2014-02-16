


class Widget {

%TypeHeaderCode
#include <widget.h>
%End

public:

	virtual int getWidth()=0;
	virtual int getHeight()=0;

	virtual int getClassId();

};