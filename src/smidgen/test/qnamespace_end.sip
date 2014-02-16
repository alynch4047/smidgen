%If (Py_v3)
// Mapped type for QSet<Qt::DayOfWeek> in Python v3.
%MappedType QSet<Qt::DayOfWeek> /DocType="set-of-Qt.DayOfWeek"/
{
%TypeHeaderCode
#include <qnamespace.h>
#include <qset.h>
%End

%ConvertFromTypeCode
    // Create the set.
    PyObject *s;

    if ((s = PySet_New(NULL)) == NULL)
        return NULL;

    // Set the set elements.
    QSet<Qt::DayOfWeek>::const_iterator it = sipCpp->constBegin();
    QSet<Qt::DayOfWeek>::const_iterator end = sipCpp->constEnd();

    while (it != end)
    {
        PyObject *el_obj;

        if ((el_obj = sipConvertFromEnum(*it, sipType_Qt_DayOfWeek)) == NULL)
        {
            Py_DECREF(s);

            return NULL;
        }

        PySet_Add(s, el_obj);

        ++it;
    }

    return s;
%End

%ConvertToTypeCode
    PyObject *it = PyObject_GetIter(sipPy), *itm;

    // Check the type if that is all that is required.
    if (sipIsErr == NULL)
    {
        if (it == NULL)
            return 0;

        while ((itm = PyIter_Next(it)) != NULL)
        {
            int ok = sipCanConvertToEnum(itm, sipType_Qt_DayOfWeek);

            Py_DECREF(itm);

            if (!ok)
            {
                Py_DECREF(it);
                return 0;
            }
        }

        Py_DECREF(it);
        return 1;
    }

    if (it == NULL)
    {
        *sipIsErr = 1;
        return 0;
    }

    QSet<Qt::DayOfWeek> *qs = new QSet<Qt::DayOfWeek>;

    while ((itm = PyIter_Next(it)) != NULL)
    {
        long l = SIPLong_AsLong(itm);

        Py_DECREF(itm);

        qs->insert(static_cast<Qt::DayOfWeek>(l));
    }

    Py_DECREF(it);

    *sipCppPtr = qs;

    return sipGetState(sipTransferObj);
%End
};
%End
QFlags<Qt::MouseButton> operator|(Qt::MouseButton f1, QFlags<Qt::MouseButton> f2);
QFlags<Qt::Orientation> operator|(Qt::Orientation f1, QFlags<Qt::Orientation> f2);
QFlags<Qt::KeyboardModifier> operator|(Qt::KeyboardModifier f1, QFlags<Qt::KeyboardModifier> f2);
QFlags<Qt::WindowType> operator|(Qt::WindowType f1, QFlags<Qt::WindowType> f2);
QFlags<Qt::AlignmentFlag> operator|(Qt::AlignmentFlag f1, QFlags<Qt::AlignmentFlag> f2);
QFlags<Qt::ImageConversionFlag> operator|(Qt::ImageConversionFlag f1, QFlags<Qt::ImageConversionFlag> f2);
QFlags<Qt::DockWidgetArea> operator|(Qt::DockWidgetArea f1, QFlags<Qt::DockWidgetArea> f2);
QFlags<Qt::ToolBarArea> operator|(Qt::ToolBarArea f1, QFlags<Qt::ToolBarArea> f2);
QFlags<Qt::WindowState> operator|(Qt::WindowState f1, QFlags<Qt::WindowState> f2);
QFlags<Qt::DropAction> operator|(Qt::DropAction f1, QFlags<Qt::DropAction> f2);
QFlags<Qt::ItemFlag> operator|(Qt::ItemFlag f1, QFlags<Qt::ItemFlag> f2);
QFlags<Qt::MatchFlag> operator|(Qt::MatchFlag f1, QFlags<Qt::MatchFlag> f2);
%If (Qt_4_2_0 -)
QFlags<Qt::TextInteractionFlag> operator|(Qt::TextInteractionFlag f1, QFlags<Qt::TextInteractionFlag> f2);
%End
%If (Qt_4_6_0 -)
QFlags<Qt::InputMethodHint> operator|(Qt::InputMethodHint f1, QFlags<Qt::InputMethodHint> f2);
%End
%If (Qt_4_6_0 -)
QFlags<Qt::TouchPointState> operator|(Qt::TouchPointState f1, QFlags<Qt::TouchPointState> f2);
%End
%If (Qt_4_6_0 -)
QFlags<Qt::GestureFlag> operator|(Qt::GestureFlag f1, QFlags<Qt::GestureFlag> f2);
%End
%If (Qt_5_0_0 -)
QFlags<Qt::ScreenOrientation> operator|(Qt::ScreenOrientation f1, QFlags<Qt::ScreenOrientation> f2);
%End
%If (Qt_5_0_0 -)
QFlags<Qt::InputMethodQuery> operator|(Qt::InputMethodQuery f1, QFlags<Qt::InputMethodQuery> f2);
%End
%End


