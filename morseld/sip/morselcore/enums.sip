

%ModuleCode
#include <enamespace.h>
%End

namespace E {

enum GlobalColor {
	color0,
	color1,
	black,
	white,
	darkGray,
	gray,
	lightGray,
	red,
	green,
	blue,
	cyan,
	magenta,
	yellow,
	darkRed,
	darkGreen,
	darkBlue,
	darkCyan,
	darkMagenta,
	darkYellow,
	transparent
	};

enum KeyboardModifier {
	NoModifier,
	ShiftModifier,
	ControlModifier,
	AltModifier,
	MetaModifier,
	KeypadModifier,
	GroupSwitchModifier,
	KeyboardModifierMask
	};

}