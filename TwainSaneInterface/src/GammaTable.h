#ifndef SANE_DS_GAMMATABLE_H
#define SANE_DS_GAMMATABLE_H

#include <Carbon/Carbon.h>

typedef void (* SetGammaTableProc) (ControlRef control, double * table);

void MakeGammaTableControl (ControlRef parent, Rect * bounds, CFStringRef title, double * table, int length,
                            SetGammaTableProc setgammatable, CFStringRef helptext, SInt32 refcon);

#endif
