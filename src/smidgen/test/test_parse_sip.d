/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_parse_sip;

import std.stdio;

import unit_threaded.all;

import pegged.grammar;

import smidgen.parse_sip;
import smidgen.ast.other;
import smidgen.ast.klass;


void testMethods() {
	
	string  methodTest = "void AddActor(vtkActor* actor); ";
	string  methodTestB = "void SetBackground(double a, double b, double c);";
	string  methodTestC = "vtkIdList* GetPointIds();";
	string  methodTestD = "virtual void Render(vtkRenderer* ren, vtkActor* a) = 0;";
	string methodTestE = "void 	SetReferenceCount (int i);";
	
	string methods = "void AddActor(vtkActor* actor); 
	void SetBackground(double a, double b, double c);";
	
	ParseTree pt = Smidgen.MethodSignature(methodTest);
//	writeln(pt);
	checkTrue(pt.successful);	
	
	pt = Smidgen.MethodSignature(methodTestB);
//	writeln(pt);	
	checkTrue(pt.successful);	
	
	pt = Smidgen.ClassElements(methods);
//	writeln(pt);	
	checkTrue(pt.successful);	
	
	pt = Smidgen.MethodSignature(methodTestC);
//	writeln(pt);		
	checkTrue(pt.successful);	
	
	pt = Smidgen.MethodSignature(methodTestD);
//	writeln(pt);		
	checkTrue(pt.successful);	
	
	pt = Smidgen.MethodSignature(methodTestE);
//	writeln(pt);		
	checkTrue(pt.successful);		
	
	pt = Smidgen.MethodSignature("unsigned long int GetMTime ();");
//	writeln(pt);		
	checkTrue(pt.successful);
	
	pt = Smidgen.MethodSignature("virtual unsigned long GetRedrawMTime ();");
//	writeln(pt);		
	checkTrue(pt.successful);
	
	pt = Smidgen.MethodSignature("virtual int 	RenderOpaqueGeometry (vtkViewport *viewport);");
//	writeln(pt);		
	checkTrue(pt.successful);		
	
}


void testParameters() {
	string paramA = "double a";
	string paramB = "tt1& *  abcde";
	string paramC = "vtkViewport *viewport";
	string paramsA = "double a, double b, double c";
	
	ParseTree pt = Smidgen.Parameter(paramA);
//	writeln(pt);
	checkTrue(pt.successful);	
	
	pt = Smidgen.Parameter(paramB);
//	writeln(pt);	
	checkTrue(pt.successful);	
	
	pt = Smidgen.Parameter(paramC);
//	writeln(pt);	
	checkTrue(pt.successful);	
	
	pt = Smidgen.Parameters(paramsA);
//	writeln(pt);
	checkTrue(pt.successful);	
	
	pt = Smidgen.Parameters("ostream &os, vtkIndent indent");
//	writeln(pt);
	checkTrue(pt.successful);			
}

void testTypes() {
	string  cTypeTest = "void &";
	string  cTypeTestB = "const void &";
	string  cTypeTestC = "const void *";
	string  cTypeTestD = "double";
	 
	ParseTree pt = Smidgen.CType(cTypeTest);
//	writeln(pt);	
	checkTrue(pt.successful);	
	pt = Smidgen.CType(cTypeTestB);
//	writeln(pt);	
	checkTrue(pt.successful);	
	pt = Smidgen.CType(cTypeTestC);
//	writeln(pt);	
	checkTrue(pt.successful);	
	pt = Smidgen.CType(cTypeTestD);
//	writeln(pt);	
	checkTrue(pt.successful);	
		 
}

void testTypeHeader() {
	string TH_test = """%TypeHeaderCode
	#include <vtkRenderer.h>
	#include <vtkRenderWindow.h>
	%End
	
	""";
	
	 string THLine_test = """	#include <vtkRenderer.h>
""";	

	ParseTree pt = Smidgen.TypeHeaderCode(TH_test);
//	writeln(pt);
	checkTrue(pt.successful);
	pt = Smidgen.DeclarationLine(THLine_test);
//	writeln(pt);		
	checkTrue(pt.successful);		
	
}

void testClass() {
	
	 string sip_test = """
	class vtkRenderer: vtkObject
	{
	
	%TypeHeaderCode
	#include <vtkRenderer.h>
	%End
	
	public:
	void AddActor(vtkActor* actor); 
	void SetBackground(double a, double b, double c);
	virtual void DoIt();
	virtual void DoIt2() = 0;
	}""";

	 string sip_test_2 = """
	
	class vtkActor
	{
	
	%TypeHeaderCode
	#include <vtkActor.h>
	%End
	
	public:
	virtual int 	IsA (const char *type);
	vtkActor * 	NewInstance () const;
	void 	PrintSelf (ostream &os, vtkIndent indent);
	virtual void 	GetActors (vtkPropCollection *);
	virtual int 	HasTranslucentPolygonalGeometry ();
	virtual void 	Render (vtkRenderer *, vtkMapper *);
	void 	ShallowCopy (vtkProp *prop);
	void 	ReleaseGraphicsResources (vtkWindow *);
	virtual vtkProperty * 	MakeProperty ();
	virtual void 	SetMapper (vtkMapper *);
	virtual void 	ApplyProperties ();
	unsigned long int 	GetMTime ();
	virtual unsigned long 	GetRedrawMTime ();
	virtual bool 	GetSupportsSelection ();
	virtual int 	RenderOpaqueGeometry (vtkViewport *viewport);
	virtual int 	RenderTranslucentPolygonalGeometry (vtkViewport *viewport);
	void 	SetProperty (vtkProperty *lut);
	vtkProperty * 	GetProperty ();
	void 	SetBackfaceProperty (vtkProperty *lut);
	virtual vtkProperty * 	GetBackfaceProperty ();
	virtual void 	SetTexture (vtkTexture *);
	virtual vtkTexture * 	GetTexture ();
	virtual vtkMapper * 	GetMapper ();
	double * 	GetBounds ();
	}
	""";
	
	 string sip_test_3 = """
	
	class vtkProperty
	{
	
	%TypeHeaderCode
	#include <vtkProperty.h>
	%End
	
	public:
	virtual int 	IsA (const char *type);
	vtkProperty * 	NewInstance () const;
	void 	PrintSelf (ostream &os, vtkIndent indent);
	void 	DeepCopy (vtkProperty *p);
	virtual void 	Render (vtkActor *, vtkRenderer *);
	virtual void 	BackfaceRender (vtkActor *, vtkRenderer *);
	void 	RemoveTexture (const char *name);
	void 	RemoveAllTextures ();
	int 	GetNumberOfTextures ();
	virtual void 	ReleaseGraphicsResources (vtkWindow *win);
	virtual void 	PostRender (vtkActor *, vtkRenderer *);
	virtual bool 	GetLighting ();
	virtual void 	SetLighting (bool);
	virtual void 	LightingOn ();
	virtual void 	LightingOff ();
	virtual void 	SetInterpolation (int);
	virtual int 	GetInterpolation ();
	void 	SetInterpolationToFlat ();
	void 	SetInterpolationToGouraud ();
	void 	SetInterpolationToPhong ();
	const char * 	GetInterpolationAsString ();
	virtual void 	SetRepresentation (int);
	virtual int 	GetRepresentation ();
	void 	SetRepresentationToPoints ();
	void 	SetRepresentationToWireframe ();
	void 	SetRepresentationToSurface ();
	const char * 	GetRepresentationAsString ();
	virtual void 	SetColor (double r, double g, double b);
	virtual void 	SetColor (double a[3]);
	double * 	GetColor ();
	void 	GetColor (double rgb[3]);
	void 	GetColor (double &r, double &g, double &b);
	virtual void 	SetAmbient (double);
	virtual double 	GetAmbient ();
	virtual void 	SetDiffuse (double);
	virtual double 	GetDiffuse ();
	virtual void 	SetSpecular (double);
	virtual double 	GetSpecular ();
	virtual void 	SetSpecularPower (double);
	virtual double 	GetSpecularPower ();
	virtual void 	SetOpacity (double);
	virtual double 	GetOpacity ();
	virtual void 	SetAmbientColor (double, double, double);
	virtual void 	SetAmbientColor (double[3]);
	virtual double * 	GetAmbientColor ();
	virtual void 	GetAmbientColor (double &, double &, double &);
	virtual void 	GetAmbientColor (double[3]);
	virtual void 	SetDiffuseColor (double, double, double);
	virtual void 	SetDiffuseColor (double[3]);
	virtual double * 	GetDiffuseColor ();
	virtual void 	GetDiffuseColor (double &, double &, double &);
	virtual void 	GetDiffuseColor (double[3]);
	virtual void 	SetSpecularColor (double, double, double);
	virtual void 	SetSpecularColor (double[3]);
	virtual double * 	GetSpecularColor ();
	virtual void 	GetSpecularColor (double &, double &, double &);
	virtual void 	GetSpecularColor (double[3]);
	virtual int 	GetEdgeVisibility ();
	virtual void 	SetEdgeVisibility (int);
	virtual void 	EdgeVisibilityOn ();
	virtual void 	EdgeVisibilityOff ();
	virtual void 	SetEdgeColor (double, double, double);
	virtual void 	SetEdgeColor (double[3]);
	virtual double * 	GetEdgeColor ();
	virtual void 	GetEdgeColor (double &, double &, double &);
	virtual void 	GetEdgeColor (double[3]);
	virtual void 	SetLineWidth (float);
	virtual float 	GetLineWidth ();
	virtual void 	SetLineStipplePattern (int);
	virtual int 	GetLineStipplePattern ();
	virtual void 	SetLineStippleRepeatFactor (int);
	virtual int 	GetLineStippleRepeatFactor ();
	virtual void 	SetPointSize (float);
	virtual float 	GetPointSize ();
	virtual int 	GetBackfaceCulling ();
	virtual void 	SetBackfaceCulling (int);
	virtual void 	BackfaceCullingOn ();
	virtual void 	BackfaceCullingOff ();
	virtual int 	GetFrontfaceCulling ();
	virtual void 	SetFrontfaceCulling (int);
	virtual void 	FrontfaceCullingOn ();
	virtual void 	FrontfaceCullingOff ();
	virtual char * 	GetMaterialName ();
	virtual void 	SetShading (int);
	virtual int 	GetShading ();
	virtual void 	ShadingOn ();
	virtual void 	ShadingOff ();
	virtual vtkShaderDeviceAdapter2 * 	GetShaderDeviceAdapter2 ();
	virtual void 	AddShaderVariable (const char *name, int numVars, int *x);
	virtual void 	AddShaderVariable (const char *name, int numVars, float *x);
	virtual void 	AddShaderVariable (const char *name, int numVars, double *x);
	void 	AddShaderVariable (const char *name, int v);
	void 	AddShaderVariable (const char *name, float v);
	void 	AddShaderVariable (const char *name, double v);
	void 	AddShaderVariable (const char *name, int v1, int v2);
	void 	AddShaderVariable (const char *name, float v1, float v2);
	void 	AddShaderVariable (const char *name, double v1, double v2);
	void 	AddShaderVariable (const char *name, int v1, int v2, int v3);
	void 	AddShaderVariable (const char *name, float v1, float v2, float v3);
	void 	AddShaderVariable (const char *name, double v1, double v2, double v3);
	void 	SetTexture (const char *name, vtkTexture *texture);
	vtkTexture * 	GetTexture (const char *name);
	void 	SetTexture (int unit, vtkTexture *texture);
	vtkTexture * 	GetTexture (int unit);
	void 	RemoveTexture (int unit);
	}""";
	
	
	 string sip2_test = """
	class vtkTest {
	%TypeHeaderCode
	#include <vtkRenderer.h>
	%End
	
	 public: }""";
	 
	ParseTree pt = Smidgen.Class(sip_test);
//	writeln(pt);
	checkTrue(pt.successful);	
	
	pt = Smidgen.Class(sip_test_2);
//	writeln(pt);
	checkTrue(pt.successful);	

	pt = Smidgen.Class(sip_test_3);
//	writeln(pt);
	checkTrue(pt.successful);	
	
	string sip_test_constructor = """
	class vtkTest {
	%TypeHeaderCode
	#include <vtkRenderer.h>
	%End

	 public:  

	 vtkTest(double x);
}""";
	 
	pt = Smidgen.Class(sip_test_constructor);
//	writeln(pt);
	checkTrue(pt.successful);		 
	
}

void testConstructors() {
	string constructorTestA = "Rect(double width, double height);";
	ParseTree pt = Smidgen.ConstructorSignature(constructorTestA);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testModule() {
		string sip_test_module = """
	%Module (name=M1)
""";
	ParseTree pt = Smidgen.ModuleDecl(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testModules2() {
		string sip_test_module = """
	%Module(name=xyz)

	%Module(name=def)

""";
	ParseTree pt = Smidgen.Package(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testModulesIncludeClass() {
		string sip_test_module = """

// this is a comment5

	class C1 {

public:

	}

	class C2 {

	}


	%Module(name=xyz)

	%Module(name=def)

	%Include abc

	class C3 {

	}

""";
	ParseTree pt = Smidgen.Package(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testComments() {
	string commentTest = """// this is a comment
""";
	ParseTree pt = Smidgen(commentTest);
//	writeln(pt);
	checkTrue(pt.successful);	
	
	commentTest = """// this is a comment
// this is a comment2
""";
	pt = Smidgen(commentTest);
//	writeln(pt);
	checkTrue(pt.successful);		
}


void testSimpleClass() {
		string sip_test_module = """

	class vtkRenderer: vtkObject
	{

	// C2
	
	%TypeHeaderCode
	#include <vtkRenderer.h>
	%End
	
	public:

	void AddActor(vtkActor* actor); 
	void SetBackground(double a, double b, double c);
	virtual void DoIt();
	virtual void DoIt2() = 0;
	}


""";
	ParseTree pt = Smidgen.Class(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testClassElements() {
		string sip_test_module = """
	// C1

	public:

// C2

	%TypeHeaderCode
	#include <vtkRenderer.h>
	%End


protected:
    
void AddActor(vtkActor* actor);
%MethodCode
int i = 1;
#comment
%End

THis is unknown

%PickleCode
ABC DEF
%End

// C3 
""";
	ParseTree pt = Smidgen.ClassElements(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testPackageDirectives() {
		string sip_test_module = """
	%DontWrapDoubleUnderscoreMethods

%GetClassNameCCode
#include <QObject>
#include <QMetaObject>

extern \"C\" const char* getClassNameC(void* wrappedObject) {
	QObject* obj = (QObject*) wrappedObject;
	return obj->metaObject()->className();
}
%End

""";
	ParseTree pt = Smidgen.Package(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testGetClassNameCCode() {
		string sip_test_module = """
	
%GetClassNameCCode
#include <QObject>
#include <QMetaObject>

extern \"C\" const char* getClassNameC(void* wrappedObject) {
	QObject* obj = (QObject*) wrappedObject;
	return obj->metaObject()->className();
}
%End

""";
	ParseTree pt = Smidgen.GetClassNameCCode(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testAnnotation() {
		string sip_test_module = """
	/Transfer=Yes/
""";
	ParseTree pt = Smidgen.Annotation(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testAnnotationWithQuotes() {
		string sip_test_module = """
	/Encoding=\"UTF-8\"/
""";
	ParseTree pt = Smidgen.Annotation(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testMethodWithParameterAnnotation() {
		string sip_test_module = """
	void setBuddy(QWidget * /KeepReference/);
""";
	ParseTree pt = Smidgen.MethodSignature(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testMethodWithAnnotation() { 
		string sip_test_module = """
	virtual bool notify(QObject *, QEvent *) /ReleaseGIL/;
""";
	ParseTree pt = Smidgen.MethodSignature(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testEnums() {
		string sip_test_module = """
	    enum RenderFlag
    {
        DrawWindowBackground,
        DrawChildren,
        IgnoreMask,
    };
""";
	ParseTree pt = Smidgen.Enum(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testDefaultValue() {
		string sip_test_module = """
	  =0
""";
	ParseTree pt = Smidgen.DefaultValue(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
	sip_test_module = """
	  = true
""";
	pt = Smidgen.DefaultValue(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testMethodWithDefaultValue() {
		string sip_test_module = """
	 void setShortcutAutoRepeat(int id, bool enabled = true);
""";
	ParseTree pt = Smidgen.MethodSignature(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testParameterWithDefaultValue() {
		string sip_test_module = """
	bool enabled = true
""";
	ParseTree pt = Smidgen.Parameter(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testConstructorWithDefaultValues() {
		string sip_test_module = """
	QWidget(QWidget *parent /TransferThis/ = 0, Qt::WindowFlags flags = 0);
""";
	ParseTree pt = Smidgen.ConstructorSignature(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testTwoEnums() {
		string sip_test_module = """
	    enum RenderFlag
    {
        DrawWindowBackground,
        DrawChildren,
        IgnoreMask,
    };

	    enum RenderFlag2
    {
        DrawWindowBackground2,
        DrawChildren2,
        IgnoreMask2
    };

""";
	ParseTree pt = Smidgen.Package(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testNamespace() {
		string sip_test_module = """
	namespace Qt {
 
   }
""";
	ParseTree pt = Smidgen.Namespace(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}


void testNamespaceWithEnums() {
		string sip_test_module = """
	namespace Qt {
 
    enum XType { A, B, C};

    enum YType { D, E, F};

   }
""";
	ParseTree pt = Smidgen.Namespace(sip_test_module);
//	writeln(pt);
	checkTrue(pt.successful);
	
}

void testMemberWithoutGetCode() {
	string sipTest ="""
static const QMetaObject staticMetaObject ;
""";
	ParseTree pt = Smidgen.Member(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testMemberOptions() {
	string sipTest ="""
{
%GetCode
        sipPy = qpycore_qobject_staticmetaobject(sipPyType);
%End

    }
""";
	ParseTree pt = Smidgen.MemberOptions(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
} 

void testGetCode() {
	string sipTest ="""%GetCode
        sipPy = qpycore_qobject_staticmetaobject(sipPyType);
%End

   
""";
	ParseTree pt = Smidgen.GetCode(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
} 

void testMemberWithGetCode() {
	string sipTest ="""
static const QMetaObject staticMetaObject {
%GetCode
        sipPy = qpycore_qobject_staticmetaobject(sipPyType);
%End

    };
""";
	ParseTree pt = Smidgen.Member(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testFunctionOperatorEqualsBool() {
		string sipTest ="""
bool operator==(const QPointF &p1, const QPointF &p2);
""";
	ParseTree pt = Smidgen.MethodSignature(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testPackageFunctions() {
		string sipTest ="""
QDataStream &operator<<(QDataStream &, const QPointF & /Constrained/);
QDataStream &operator>>(QDataStream &, QPointF & /Constrained/);
bool operator==(const QPointF &p1, const QPointF &p2);
bool operator!=(const QPointF &p1, const QPointF &p2);
const QPointF operator+(const QPointF &p1, const QPointF &p2);
const QPointF operator-(const QPointF &p1, const QPointF &p2);
const QPointF operator*(const QPointF &p, qreal c);
const QPointF operator*(qreal c, const QPointF &p);
const QPointF operator-(const QPointF &p);
const QPointF operator/(const QPointF &p, qreal c);
""";
	ParseTree pt = Smidgen.Package(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testTemplatedSymbolName() {
				string sipTest ="""QFlags<Qt::MouseButton> """;
	ParseTree pt = Smidgen.TemplatedSymbolName(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testPackageFunctionsWithTemplatedTypes() {
			string sipTest ="""
QFlags<Qt::MouseButton> operator|(Qt::MouseButton f1, QFlags<Qt::MouseButton> f2);
QFlags<Qt::Orientation> operator|(Qt::Orientation f1, QFlags<Qt::Orientation> f2);
QFlags<Qt::KeyboardModifier> operator|(Qt::KeyboardModifier f1, QFlags<Qt::KeyboardModifier> f2);
""";
	ParseTree pt = Smidgen.Package(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}


void testConverters() {
			string sipTest ="""
%Converter abc.converter
%Converter def.converter
""";
	ParseTree pt = Smidgen.Package(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testMethodSignatureEnumArgumentNoArgumentName() {
			string sipTest ="""
virtual int metric(QPaintDevice::PaintDeviceMetric) const;
""";
	ParseTree pt = Smidgen.MethodSignature(sipTest);
	checkTrue(pt.successful);
//	writeln(pt);
}


void testMethodSignatureWithAnnotationWithQuotesAndNegativeDefault() {
				string sipTest ="""
 QString tr(const char *sourceText /Encoding=\"UTF-8\"/,
 		const char *disambiguation = 0, int n = -1) const;
""";
	ParseTree pt = Smidgen.MethodSignature(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testDefaultValueClassInstance() {
				string sipTest ="""
  = QString()
""";
	ParseTree pt = Smidgen.DefaultValue(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testMethodSignatureWithAnnotationWithQuotes() {
				string sipTest ="""
 SIP_PYOBJECT findChild(SIP_PYTYPE type, const QString &name /DocValue=\"\'\'\"/ = QString(),
 Qt::FindChildOptions options = Qt::FindChildrenRecursively) const /DocType=\"QObject\"/;
""";
	ParseTree pt = Smidgen.MethodSignature(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testParserPreservesDeclarationWhitespace() {
				string sipTest ="""%TypeHeaderCodeD
class SlotException: Exception {
this(string message) {
	 super(message);
    }
}
%End
""";
	ParseTree pt = Smidgen.TypeHeaderCodeD(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
	auto declToEnd = pt.children[0];
	auto line3 = declToEnd.children[0].children[2];
	string line3Content = line3.input[line3.begin .. line3.end];
	checkEqual(line3Content[0 .. 2], "\t ");
}

void testParseTypedefsAndModuleCode() {
				string sipTest ="""
// qglobal.sip generated by MetaSIP on Wed Aug 21 06:30:42 2013
//
// This file is part of the QtCore Python extension module.
//
// Copyright (c) 2013 Riverbank Computing Limited <info@riverbankcomputing.com>
// 
// This file is part of PyQt5.
// 
// This file may be used under the terms of the GNU General Public License
// version 3.0 as published by the Free Software Foundation and appearing in
// the file LICENSE included in the packaging of this file.  Please review the
// following information to ensure the GNU General Public License version 3.0
// requirements will be met: http://www.gnu.org/copyleft/gpl.html.
// 
// If you do not wish to use this file under the terms of the GPL version 3.0
// then you may purchase a commercial license.  For more information contact
// info@riverbankcomputing.com.
// 
// This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
// WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.


%Module(name=test)

%ModuleCode
#include <qglobal.h>
%End

// PyQt version information.
int PYQT_VERSION;
const char *PYQT_VERSION_STR;

%ModuleCode
static int PYQT_VERSION = 0x050001;
static const char *PYQT_VERSION_STR = \"5.0.1\";
%End
const int QT_VERSION;
const char *QT_VERSION_STR;
typedef signed char qint8 /PyInt/;
typedef unsigned char quint8 /PyInt/;
typedef short qint16;
typedef unsigned short quint16;
typedef int qint32;
typedef unsigned int quint32;
typedef long long qint64;
typedef unsigned long long quint64;
typedef qint64 qlonglong;
typedef quint64 qulonglong;
typedef double qreal;
typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;
""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testParseTemplatedClass() {
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
}

void testParseMappedType() {
				string sipTest ="""

%Module(name=test)

%MappedType qintptr /DocType=\"sip.voidptr\"/
{
%TypeHeaderCode
#include <QtGlobal>
%End

%ConvertToTypeCode
    qintptr ptr = (qintptr)sipConvertToVoidPtr(sipPy);

    if (!sipIsErr)
        return !PyErr_Occurred();

    // Mapped types deal with pointers, so create one on the heap.
    qintptr *heap = new qintptr;
    *heap = ptr;

    *sipCppPtr = heap;

    // Make sure the pointer doesn't leak.
    return SIP_TEMPORARY;
%End

%ConvertFromTypeCode
    return sipConvertFromVoidPtr((void *)*sipCpp);
%End
};
""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testCToDType() {
	string sipTest ="""%CToDType unsigned char = ubyte
""";
	ParseTree pt = Smidgen.CToDType(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testCToDTypeSingleCTypeSymbolName() {
	string sipTest ="""%CToDType char = byte
""";
	ParseTree pt = Smidgen.CToDType(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}

void testParseConfigurationTypeData() {
				string sipTest ="""
// Comment
%CToDType long = long
%CToDType unsigned char = ubyte

""";
	ParseTree pt = Smidgen(sipTest);
//	writeln(pt);
	checkTrue(pt.successful);
}




