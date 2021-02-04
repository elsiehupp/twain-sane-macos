#ifndef SANE_DS_USERINTERFACE_H
#define SANE_DS_USERINTERFACE_H

#include <Carbon/Carbon.h>

#include <sane/sane.h>

#include <map>
#include <set>

#include "SaneDevice.h"


class UserInterface {

public:
    UserInterface (SaneDevice * sd, int currentdevice, bool uionly);
    ~UserInterface ();

    int ChangeDevice (int device);
    void ProcessCommand (UInt32 command);
    void ChangeOptionGroup ();
    void Scroll (SInt16 part);
    void ChangeOption (ControlRef control);
    void UpdateOption (int option);
    void SetGammaTable (ControlRef control, double * table);
    void SetScanArea (short int width, short int height);
    void UpdateScanArea ();
    void SetAreaControls ();
    CFStringRef CreateSliderNumberString (ControlRef control, SInt32 value);
    void Invalidate (ControlRef control);
    void Validate (ControlRef control);

    void ShowSheetWindow (WindowRef sheet);
    void DrawPreviewSelection ();
    void TrackPreviewSelection (Point point);
    void PreviewMouseMoved (Point point);

private:
    void BuildOptionGroupBox (bool reset);
    void OpenPreview ();
    void ClosePreview ();

    SaneDevice * sanedevice;

    WindowRef window;
    ControlRef optionGroupBoxControl;
    ControlRef optionGroupMenuControl;
    ControlRef scrollBarControl;
    ControlRef userPaneMasterControl;
    ControlRef previewButton;
    ControlRef scanareacontrol;

    bool canpreview;
    bool bootstrap;
    WindowRef preview;
    ControlRef previewPictControl;

    SANE_Rect maxrect;
    SANE_Rect viewrect;
    SANE_Rect previewrect;

    std::map <int, ControlRef> optionControl;
    std::set <ControlRef> invalid;
};

#endif
