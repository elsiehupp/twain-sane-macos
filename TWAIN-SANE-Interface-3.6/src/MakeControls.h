#ifndef SANE_DS_CONTROLS_H
#define SANE_DS_CONTROLS_H

#include <Carbon/Carbon.h>

ControlRef MakeStaticTextControl (ControlRef parent, Rect * bounds, CFStringRef text,
                                  SInt16 just, bool small);

ControlRef MakeButtonControl (ControlRef parent, Rect * bounds, CFStringRef text,
                              UInt32 command, bool right, CFStringRef helptext, SInt32 refcon);

ControlRef MakeEditTextControl (ControlRef parent, Rect * bounds, CFStringRef title,
                                CFStringRef text, Boolean ispassword, CFStringRef helptext,
                                SInt32 refcon);

ControlRef MakeCheckBoxControl (ControlRef parent, Rect * bounds, CFStringRef text,
                                SInt32 initval, CFStringRef helptext, SInt32 refcon);

ControlRef MakePopupMenuControl (ControlRef parent, Rect * bounds, CFStringRef title,
                                 MenuRef menu, MenuItemIndex selectedItem, CFStringRef helptext,
                                 SInt32 refcon);

typedef CFStringRef (* CreateValueTextProc) (ControlRef control, SInt32 value);

ControlRef MakeSliderControl (ControlRef parent, Rect * bounds, CFStringRef title,
                              SInt32 minimum, SInt32 maximum, SInt32 value,
                              CreateValueTextProc CreateValueText, CFStringRef helptext, SInt32 refcon);

#endif
