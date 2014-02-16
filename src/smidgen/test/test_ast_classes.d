/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/

module smidgen.test.test_ast_classes;

import std.stdio: writeln;
import std.algorithm: find, canFind;
import std.array: replace;
import std.string: strip, format, splitLines;

import unit_threaded.all;
import pegged.grammar;

import smidgen.test.test_extras;

import smidgen.ast.other;
import smidgen.parse_sip;
import smidgen.ast.klass;
import smidgen.ast.method: Method, Visibility;
import smidgen.ast.argument;
import smidgen.ast.package_;


void testGetReferencedClassNames() {
	Klass vtkRenderer = makeVtkRenderer();
	Klass[] classes = vtkRenderer.getReferencedClasses();
	auto classNames = map!(a => a.name)(classes);
	checkFalse(find(classNames, "vtkActor").empty);
	checkFalse(find(classNames, "vtkObject").empty);
}


void testModuleName() {
	string sipTest = """

%Module(name=morselA)

class C1:WrappedObject {}

class C2: C1 {}

class C3 {}
""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	
	checkEqual(package_.dottedImportName, "morselA");
}


void testToStringDWithArgumentWrapped() {
	
	Klass vtkRenderer = makeVtkRenderer();
	string dString = strip(getDStringForMethod(vtkRenderer, "AddActor"));
	checkEqualWS(dString, "void AddActor(vtkActor actor) {
		checkCPPObjectIsValid();
		void* actor_wrappedObj = actor ? actor.wrappedObj : null;
		vtkRenderer_AddActor_SMIX1(wrappedObj, actor_wrappedObj);
	}");
}

void testToStringDWithMultipleArgumentDouble() {
	
	Klass vtkRenderer = makeVtkRenderer();
	string dString = strip(getDStringForMethod(vtkRenderer, "SetBackground"));
	checkEqualWS(dString, "void SetBackground(double a, double b, double c) {
	checkCPPObjectIsValid();	
	vtkRenderer_SetBackground_SMIX0(wrappedObj, a, b, c);
	}");
}


void testToStringDWithArgumentString() {
	
	Klass vtkRenderer = makeVtkRenderer();
	string dString = strip(getDStringForMethod(vtkRenderer, "SetName"));
	checkEqualWS(dString, "void SetName(string name___SMI) {
		char* name = cast(char*) toStringz(name___SMI);
		checkCPPObjectIsValid();
		vtkRenderer_SetName_SMIX2(wrappedObj, name);
	}");
}


void testToStringDExportWithArgumentString() {
	
	Klass vtkRenderer = makeVtkRenderer();
	string dString = strip(getDStringExportForMethod(vtkRenderer, "SetName"));
	checkEqualWS(dString, "extern (C) void vtkRenderer_SetName_SMIX2(void* self, char* name);");
}


void testToStringCWithArgumentString() {
	
	Klass vtkRenderer = makeVtkRenderer();
	string dString = strip(getCStringForMethod(vtkRenderer, "SetName"));
	checkEqualWS(dString, 
			"extern \"C\" void vtkRenderer_SetName_SMIX2(vtkRenderer* self, char* name___SMI) {
				 char* name = convertPCharToPCharArgument(name___SMI);
				 self->SetName(name);
				}");
}

void testASTTreeParsingModulesLevel() {
	string sipTest = """

// Comment

%DontWrapDoubleUnderscoreMethods

%GetClassNameCCode
#include <QObject>
#include <QMetaObject>

extern \"C\" const char* getClassNameC(void* wrappedObject) {
	QObject* obj = (QObject*) wrappedObject;
	return obj->metaObject()->className();
}
%End

%Module(name=testA)

class J {
}

%Module(name=testB)

class K {
}

class L {
}

""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	ModulesHolder modulesHolder = new ModulesHolder(pt);
	auto packageA = modulesHolder.packages[0];
	checkTrue(packageA.dontWrapDoubleUnderscoreMethods);
	checkEqual(packageA.klasses.length, 1);
	auto packageB = modulesHolder.packages[1];
	checkTrue(packageB.dontWrapDoubleUnderscoreMethods);
	checkEqual(packageB.klasses.length, 2);
}


void testASTTreeParsingNamespaceLevel() {
	string sip_test_constructor = """

%Module(name=test)

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
""";
	
	ParseTree pt = Smidgen(sip_test_constructor);
//	writeln(pt);
	checkTrue(pt.successful);
	
	Klass[] klasses;
	auto package_ = getFirstModulePackage(pt);

	checkEqual(package_.packages.length, 1);
	auto namespacePackage = package_.packages[0];
	checkEqual(namespacePackage.name, "E");
	checkEqual(namespacePackage.enums.length, 2);
	checkEqual(namespacePackage.enums[0].name, "GlobalColor");
	checkEqual(namespacePackage.enums[0].memberNames.length, 20);
	
}

void testDottedClassName() {
		string sipTest = """

%Module(name=morselB)

class C1:WrappedObject {}

class C2: C1 {}

class C3 {}
""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	checkEqual(package_.dottedImportName, "morselB");
	Klass C1 = package_.getClassOfName("C1");
	checkEqual(C1.dottedImportName, "morselB.C1");
	checkEqual(package_.getKnownKlasses().length, 3);
	
}

void testMethodSignatureEnumArgumentNoArgumentName() {
			string sipTest ="""
%Module(name=morselA)
class X{
virtual int metric(QPaintDevice::PaintDeviceMetric) const;
}
""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	auto method = klass.methods[0];
	checkEqual(method.name, "metric");
	auto argument = method.arguments[0];
	checkEqual(argument.type.name, "QPaintDevice::PaintDeviceMetric");
}


void testMethodWithEllipsisIsNotWrapped() {
			string sipTest ="""
%Module(name=morselA)
class X{
virtual int M1(int x, ...) const;
}
""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	package_ = makeTestPackage(package_);
	auto klass = package_.klasses[0];
	auto method = klass.methods[0];
	checkTrue(method.hasEllipsis);
	string reason;
	checkTrue(method.excludeFromWrapping(reason));
}

void testQPaintDeviceIsAbstractClass() {
	string sipTest = "
%Module(name=morselA)
class QPaintDevice
{
%TypeHeaderCode
#include <qpaintdevice.h>
%End

public:
    enum PaintDeviceMetric
    {
        PdmWidth,
        PdmHeight,
        PdmWidthMM,
        PdmHeightMM,
        PdmNumColors,
        PdmDepth,
        PdmDpiX,
        PdmDpiY,
        PdmPhysicalDpiX,
        PdmPhysicalDpiY,
    };

    virtual ~QPaintDevice();
    virtual QPaintEngine *paintEngine() const = 0;
    int width() const;
    int height() const;
    int widthMM() const;
    int heightMM() const;
    int logicalDpiX() const;
    int logicalDpiY() const;
    int physicalDpiX() const;
    int physicalDpiY() const;
    int depth() const;
    bool paintingActive() const;
    int colorCount() const;

protected:
    QPaintDevice();
    virtual int metric(QPaintDevice::PaintDeviceMetric metric) const;

private:
    QPaintDevice(const QPaintDevice &);
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	
	checkTrue(klass.abstract_);

}

void testVirtualConstMethod() {
	string sipTest = "
%Module(name=morselA)
class X {
virtual QPaintEngine *paintEngine() const = 0;
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	checkTrue(method.abstract_);
	checkTrue(method.const_);
	checkFalse(method.transferBack);
}

void testInterfaceIsParsed() {
	string sipTest = "%Module(name=morselA)
class Rect : Shape, Calculator {

%TypeHeaderCode
#include <rect.h>
%End

public:

	Rect(int width, int height);
	
	Rect(string name);
	
	virtual int area();

}";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.interfaceNames.length, 1);
	checkEqual(klass.interfaceNames[0], "Calculator");
}	

void testGetBaseKlasses() {
	string sipTest = """
%Module(name=morselA)
class C1:WrappedObject {
void m1(); 
void m2();
}

class C2: C1 {
void m2();
void m3();
void m4();
void m5();
}

class C3 {}

class C4: C2 {
void m1();
void m4();
}
""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	auto c4 = package_.getClassOfName("C4");
	checkEqual(c4.getBaseMethods.length, 6);
	
}

void testMethodIsOverride() {
	string sipTest = """
%Module(name=morselA)
class C1:WrappedObject {
void m1(); 
void m2(int a);
}

class C2: C1 {
void m2(int a);
void m3();
void m4();
void m5();
}

class C3 {}

class C4: C2 {
void m4();
}

class C5: C2 {
void m8();
}

class C6: C2 {
void m2(int a);
}

class C7: C2 {
void m2(double a);
}
""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	auto c4 = package_.getClassOfName("C4");
	Method m4 = c4.methods[0];
	checkTrue(m4.isOverridingBaseMethod);
	
	auto c5 = package_.getClassOfName("C5");
	Method m8 = c5.methods[0];
	checkFalse(m8.isOverridingBaseMethod);	
	
	auto c6 = package_.getClassOfName("C6");
	Method m2 = c6.methods[0];
	checkTrue(m2.isOverridingBaseMethod);
	
	auto c7 = package_.getClassOfName("C7");
	m2 = c7.methods[0];
	checkFalse(m2.isOverridingBaseMethod);		
	
}

void testGetReferencedClassesIncludesInterfaceNames() {
	string sipTest = """
%Module(name=morselA)
class Inter {
}

class C1:WrappedObject {
void m1(); 
void m2(int a);
}

class C2: C1 {
void m2(int a);
void m3();
void m4();
void m5();
}

class C3: C2, Inter {}

""";
	
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);
	auto inter = package_.getClassOfName("Inter");
	auto c1 = package_.getClassOfName("C1");
	auto c2 = package_.getClassOfName("C2");
	auto c3 = package_.getClassOfName("C3");
	Klass[] klasses = c3.getReferencedClasses;
	checkEqual(klasses.length, 2);
	checkTrue(canFind(klasses, inter));
	checkTrue(canFind(klasses, c2));
	checkFalse(canFind(klasses, c1));
}


void testTransferBackAtMethodLevel() {
	string sipTest = "
%Module(name=morselA)
class X {
	Point* removePoint(int index) /TransferBack/;
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	checkTrue(method.transferBack);
	auto argument = method.arguments[0];
	checkFalse(argument.transferBack);
}


void testTransferBackAtArgumentLevel() {
	string sipTest = "
%Module(name=morselA)
class X {
	Point* removePoint(int index /TransferBack/);
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	checkFalse(method.transferBack);
	auto argument = method.arguments[0];
	checkTrue(argument.transferBack);
	checkFalse(argument.transfer);
}


void testTransferAtArgumentLevel() {
	string sipTest = "
%Module(name=morselA)
class X {
	Point* removePoint(int index /Transfer/);
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	checkFalse(method.transferBack);
	auto argument = method.arguments[0];
	checkTrue(argument.transfer);
}

void testDNameAnnotation() {
	string sipTest = "
%Module(name=morselA)
class X {
	Point* removePoint(int index /Transfer/) /DName=\"DEF\"/;
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	checkEqual(method.DName, "DEF");
}


void testStructVsClass() {
	string sipTest = "
%Module(name=morselA)
class X {
	Point* removePoint(int index /Transfer/) /DName=\"DEF\"/;
public:
	void doItX();
};

struct Y {
	void doIt();
private:
	void doIt2();
};
";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.getClassOfName("X");
	auto method0 = klass.methods[0];
	checkEqual(method0.visibility, Visibility.private_);
	auto method1 = klass.methods[1];
	checkEqual(method1.visibility, Visibility.public_);
	
	klass = package_.getClassOfName("Y");
	method0 = klass.methods[0];
	checkEqual(method0.visibility, Visibility.public_);
	method1 = klass.methods[1];
	checkEqual(method1.visibility, Visibility.private_);	
}


void testMethodCodeD() {
	string sipTest = "
%Module(name=morselA)
class X {
	void doItA();
	void doItB();
%MethodCodeD
// This is the code B
%End
	void doItX();
%MethodCodeD
// This is the code X
%End
	void doItY();
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 4);
	auto methodA = klass.methods[0];
	checkEqual(methodA.methodCodeD, "");	
	auto methodB = klass.methods[1];
	checkEqual(methodB.methodCodeD.strip, "// This is the code B".strip);
	checkEqual(methodB.name, "doItB");
	auto methodX = klass.methods[2];
	checkEqual(methodX.methodCodeD.strip, "// This is the code X".strip);	
	checkEqual(methodX.name, "doItX");
}


void testDeclarationsDontLoseWhitespace() {
	
	string sipTest ="""
%Module(name=morselA)
class X {
%TypeHeaderCodeD
class SlotException: Exception {
		this(string message) {
		super(message);
    }
}
%End
};
""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	string code = klass.typeHeaderCodeD;
	string line3 = code.splitLines[2];
	checkEqual(line3[0 .. 2], "\t\t");
}


void testEnumGetClassOfName() {
	string sip_test_constructor = """

%Module(name=test)

class X {
	E::GlobalColor getColor(E::GlobalColor color);
};

namespace E {

enum GlobalColor {
	color0,
	color1,
	black,
	};

}
""";
	
	ParseTree pt = Smidgen(sip_test_constructor);
//	writeln(pt);
	checkTrue(pt.successful);
	
	auto package_ = getFirstModulePackage(pt);

	Klass X = package_.getClassOfName("X");
	auto getColor = X.methods[0];
	auto arg0 = getColor.arguments[0];
	checkEqual(arg0.type.name, "E::GlobalColor");
	auto klass = getColor.getClassOfName(arg0.type.name);
	checkNotNull(klass);
	checkEqual(klass.name, "GlobalColor");

	Klass enumGlobalColor = package_.getClassOfName("E::GlobalColor");
	checkNotNull(enumGlobalColor);
	checkEqual(enumGlobalColor.name, "GlobalColor");
	
}
	
	
void testDefaultArgumentValueString() {
	string sipTest = "
%Module(name=morselA)
class X {
	void removePoint(char* index=def);
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	auto arg0 = method.arguments[0];
	checkEqual(arg0.toStringD(), "string index___SMI=\"def\"");
}

void testDefaultArgumentValueInteger() {
	string sipTest = "
%Module(name=morselA)
class X {
	void addPoint(int a=3);
};";
	ParseTree pt = Smidgen(sipTest);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	auto arg0 = method.arguments[0];
	checkEqual(arg0.toStringD(), "int a=3");
}

void testDefaultArgumentValueWrappedObj() {
	string sipTest = "
%Module(name=morselA)
class X {
	void getPoint(X* startPoint=0);
};";
	ParseTree pt = Smidgen(sipTest);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkEqual(klass.methods.length, 1);
	auto method = klass.methods[0];
	auto arg0 = method.arguments[0];
	checkEqual(arg0.toStringD(), "X startPoint=null");
}

void testTypeDef() {
	
	string sipTestA = "qint16;
";
	ParseTree pt = Smidgen.TypeDefEnd(sipTestA);
	checkTrue(pt.successful);	
	
	sipTestA = "unsigned short";
	pt = Smidgen.TypeDefBaseName(sipTestA);
	checkTrue(pt.successful);		
	
	sipTestA = "unsigned short";
	pt = Smidgen.TypeDefBase(sipTestA);
	checkTrue(pt.successful);		
	
	string sipTestB = "typedef short qint16;
";
	pt = Smidgen.TypeDefRegular(sipTestB);
	checkTrue(pt.successful);
}


void testPackageTypedefs() {
	string sipTest = "

%Module(name=morselA)

typedef signed char qint8 /PyInt/;
typedef unsigned char quint8 /PyInt/;
typedef short qint16;
typedef unsigned short quint16;
typedef int qint32;
typedef unsigned int*& quint32;
typedef long long qint64;
typedef unsigned long long quint64;
typedef QFlags<Qt::KeyboardModifier> KeyboardModifiers;

class X {
	void getPoint(X* startPoint=0);
};";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	auto package_ = getFirstModulePackage(pt);
	auto typedefs = package_.typedefs;
	checkEqual(typedefs.length, 9);
	foreach (typedef_; typedefs) {
		checkNotNull(typedef_.baseTypeName);
		checkNotNull(typedef_.aliasTypeName);
	}
	checkEqual(typedefs[0].baseTypeName, "signed char");
	checkEqual(typedefs[0].aliasTypeName, "qint8");
	checkEqual(typedefs[8].baseTypeName, "QFlags<Qt::KeyboardModifier>");
	checkEqual(typedefs[8].aliasTypeName, "KeyboardModifiers");	
}


void testClassTypedefs() {
	string sipTest = "

%Module(name=morselA)

typedef signed char qint8 /PyInt/;
typedef unsigned char quint8 /PyInt/;
typedef short qint16;

class X {
	void getPoint(X* startPoint=0);
	typedef unsigned short quint16;
	typedef int qint32;
	typedef unsigned int*& quint32;
	typedef long long qint64;
	typedef unsigned long long quint64;
	typedef QFlags<Qt::KeyboardModifier> KeyboardModifiers;

};";
	ParseTree pt = Smidgen(sipTest);
	auto package_ = getFirstModulePackage(pt);
	auto typedefs = package_.typedefs;
	checkEqual(typedefs.length, 3);
	checkNotNull(package_.klasses[0]);
	checkEqual(package_.klasses[0].name, "X");
	typedefs = package_.klasses[0].typedefs;
	checkEqual(typedefs.length, 6);
	foreach (typedef_; typedefs) {
		checkNotNull(typedef_.baseTypeName);
		checkNotNull(typedef_.aliasTypeName);
	}
	checkEqual(typedefs[0].baseTypeName, "unsigned short");
	checkEqual(typedefs[0].aliasTypeName, "quint16");
	checkEqual(typedefs[5].baseTypeName, "QFlags<Qt::KeyboardModifier>");
	checkEqual(typedefs[5].aliasTypeName, "KeyboardModifiers");	
}
	
void testTemplatedClass() {
				string sipTest ="""

%Module(name=test)

template<ENUM>
class QFlags /PyQt4Flags=0x1/
{
public:
    QFlags(const QFlags &);
    // This is handled by the %ConvertToTypeCode.
    //QFlags(ENUM);
    // This is a convenience, eg. to restore a set of flags from QSettings.
    QFlags(int);
    QFlags();
}
""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	auto package_ = getFirstModulePackage(pt);
	auto klass = package_.klasses[0];
	checkTrue(klass.isTemplated);
}
	