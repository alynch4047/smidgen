#ifndef E_H
#define E_H

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
	NoModifier = 0x00000000,
	ShiftModifier = 0x02000000,
	ControlModifier = 0x04000000,
	AltModifier = 0x08000000,
	MetaModifier = 0x10000000,
	KeypadModifier = 0x20000000,
	GroupSwitchModifier = 0x40000000,
	KeyboardModifierMask = 0xfe000000
	};

}

#endif
