/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_parse_q_namespace;

import std.stdio;
import std.array;

import unit_threaded.all;

import pegged.grammar;

import smidgen.parse_sip;
import smidgen.ast.other;
import smidgen.ast.klass;
import smidgen.ast.package_;
import smidgen.handle_includes_and_ifs;

import smidgen.test.test_extras: getFirstModulePackage;

auto sipTest = import("qnamespace.sip");


void testQNamespace() {
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package1 = getFirstModulePackage(pt);
	checkEqual(package1.packages.length, 1);
	auto package2 = package1.packages[0];
	auto enums = package2.enums;
	checkEqual(enums.length, 73);
	auto enumNames = array(map!(a => a.name)(enums));
	checkEqual(enumNames, ["GlobalColor", "KeyboardModifier", "Modifier", "MouseButton",
		 "Orientation", "FocusPolicy", "SortOrder", "AlignmentFlag", "TextFlag", 
		 "TextElideMode", "WindowType", "WindowState", "WidgetAttribute", 
		 "ImageConversionFlag", "BGMode", "Key", "ArrowType", "PenStyle", "PenCapStyle", 
		 "PenJoinStyle", "BrushStyle", "UIEffect", "CursorShape", "TextFormat",
		  "AspectRatioMode", "DockWidgetArea", "TimerType", "ToolBarArea", "DateFormat",
		   "TimeSpec", "DayOfWeek", "ScrollBarPolicy", "CaseSensitivity", "Corner",
		    "ConnectionType", "ShortcutContext", "FillRule", "ClipOperation", 
		    "TransformationMode", "FocusReason", "ContextMenuPolicy", "InputMethodQuery",
		     "ToolButtonStyle", "LayoutDirection", "DropAction", "CheckState", 
		     "ItemDataRole", "ItemFlag", "MatchFlag", "WindowModality", 
		     "ApplicationAttribute", "ItemSelectionMode", "TextInteractionFlag",
		      "MaskMode", "Axis", "EventPriority", "SizeMode", "SizeHint",
		       "WindowFrameSection", "TileRule",
		 "InputMethodHint", "AnchorPoint", "CoordinateSystem", "TouchPointState", 
		 "GestureState", "GestureType", "GestureFlag", "NavigationMode", 
		 "CursorMoveStyle", "ScreenOrientation", "FindChildOption", "WhiteSpaceMode", 
		 "HitTestAccuracy"]) ;
	auto functions = package1.methods;
	checkEqual(functions.length, 18);
}