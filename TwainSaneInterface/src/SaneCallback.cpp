#include <Carbon/Carbon.h>

#include <sane/sane.h>

extern "C" {
#include "md5.h"
}

#include "SaneCallback.h"
#include "MakeControls.h"
#include "SaneDevice.h"


const EventTypeSpec commandProcessEvent [] = { { kEventClassCommand, kEventCommandProcess } };


static SaneDevice * cbdevice = NULL;
static UInt32 cbresult = 0;


void SaneCallbackDevice (SaneDevice * sanedevice) {

    cbdevice = sanedevice;
    cbresult = 0;
}


UInt32 SaneCallbackResult () {

    cbdevice = NULL;
    return cbresult;
}


static OSStatus SaneAuthCallbackEventHandler (EventHandlerCallRef inHandlerCallRef,
                                              EventRef inEvent, void * inUserData) {

    OSStatus osstat;

    HICommandExtended cmd;
    osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeHICommand, NULL,
                                sizeof (HICommandExtended), NULL, &cmd);
    assert (osstat == noErr);

    switch (cmd.commandID) {
        case kHICommandOK:
        case kHICommandCancel:
            SetWRefCon ((WindowRef) inUserData, cmd.commandID);
            osstat = QuitAppModalLoopForWindow ((WindowRef) inUserData);
            assert (osstat == noErr);
            return noErr;
            break;
        default:
            return eventNotHandledErr;
            break;
    }
}


void SaneAuthCallback (SANE_String_Const resource,
                       SANE_Char username [SANE_MAX_USERNAME_LEN],
                       SANE_Char password [SANE_MAX_PASSWORD_LEN]) {

    OSStatus osstat;
    OSErr oserr;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (CFSTR ("se.ellert.twain-sane"));

    CFStringRef text;

    Rect windowrect = { 0, 0, 100, 500 };
    WindowRef window;

    if (cbdevice && cbdevice->HasUI()) {
        osstat = CreateNewWindow (kSheetWindowClass,
                                  kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                  &windowrect, &window);
        assert (osstat == noErr);

        osstat = SetThemeWindowBackground (window, kThemeBrushSheetBackgroundOpaque, true);
        assert (osstat == noErr);
    }
    else {
        osstat = CreateNewWindow (kMovableModalWindowClass,
                                  kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                  &windowrect, &window);
        assert (osstat == noErr);

        osstat = SetThemeWindowBackground (window, kThemeBrushMovableModalBackground, true);
        assert (osstat == noErr);

        text = CFBundleCopyLocalizedString (bundle, CFSTR ("Authentication"), NULL, NULL);
        osstat = SetWindowTitleWithCFString (window, text);
        assert (osstat == noErr);
        CFRelease (text);
    }

    ControlRef rootcontrol;
    oserr = GetRootControl (window, &rootcontrol);
    assert (oserr == noErr);

    Rect controlrect;

    controlrect.left = 20;
    controlrect.right = windowrect.right - windowrect.left - 20;

    controlrect.top = 20;

    CFStringRef res;

    if (cbdevice)
        res = cbdevice->CreateName ();
    else
        res = CFStringCreateWithCString (NULL, resource, kCFStringEncodingUTF8);

    CFStringRef format = CFBundleCopyLocalizedString (bundle,
                                                      CFSTR ("The resource %@ needs authentication"),
                                                      NULL, NULL);

    text = CFStringCreateWithFormat (NULL, NULL, format, res);

    CFRelease (format);
    CFRelease (res);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
    CFRelease (text);

    controlrect.top = controlrect.bottom + 20;

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("Username:"), NULL, NULL);
    ControlRef usernameControl = MakeEditTextControl (rootcontrol, &controlrect, text, NULL,
                                                      false, NULL, 0);
    CFRelease (text);

    controlrect.top = controlrect.bottom + 8;

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("Password:"), NULL, NULL);
    ControlRef passwordControl = MakeEditTextControl (rootcontrol, &controlrect, text, NULL,
                                                      true, NULL, 0);
    CFRelease (text);

    if (!strstr (resource, "$MD5$")) {
        controlrect.top = controlrect.bottom + 8;

        text = CFBundleCopyLocalizedString (bundle, CFSTR ("Plain text password warning"), NULL, NULL);
        MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, true);

        CFRelease (text);
    }

    controlrect.top = controlrect.bottom + 20;

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("OK"), NULL, NULL);
    MakeButtonControl (rootcontrol, &controlrect, text, kHICommandOK, true, NULL, 0);
    CFRelease (text);

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("Cancel"), NULL, NULL);
    MakeButtonControl (rootcontrol, &controlrect, text, kHICommandCancel, true, NULL, 0);
    CFRelease (text);

    windowrect.bottom = controlrect.bottom + 20;

    osstat = SetWindowBounds (window, kWindowContentRgn, &windowrect);
    assert (osstat == noErr);

    EventHandlerUPP SaneAuthCallbackEventHandlerUPP =
        NewEventHandlerUPP (SaneAuthCallbackEventHandler);
    osstat = InstallWindowEventHandler (window, SaneAuthCallbackEventHandlerUPP,
                                        GetEventTypeCount (commandProcessEvent),
                                        commandProcessEvent, window, NULL);
    assert (osstat == noErr);

    if (cbdevice && cbdevice->HasUI()) {
        cbdevice->ShowSheetWindow (window);
    }
    else {
        osstat = RepositionWindow (window, NULL, kWindowAlertPositionOnMainScreen);
        assert (osstat == noErr);

        ShowWindow (window);
    }

    osstat = RunAppModalLoopForWindow (window);
    assert (osstat == noErr);

    if (cbdevice && cbdevice->HasUI())
        HideSheetWindow (window);
    else
        HideWindow (window);

    DisposeEventHandlerUPP (SaneAuthCallbackEventHandlerUPP);

    switch (GetWRefCon (window)) {
        case kHICommandOK:
            oserr = GetControlData (usernameControl, kControlEntireControl,
                                    kControlEditTextCFStringTag,
                                    sizeof (CFStringRef), &text, NULL);
            assert (oserr == noErr);
            CFStringGetCString (text, username, SANE_MAX_USERNAME_LEN, kCFStringEncodingUTF8);
            CFRelease (text);

            oserr = GetControlData (passwordControl, kControlEntireControl,
                                    kControlEditTextCFStringTag,
                                    sizeof (CFStringRef), &text, NULL);
            assert (oserr == noErr);
            if (strstr (resource, "$MD5$")) {
                char tmp [128 + SANE_MAX_PASSWORD_LEN];
                strncpy (tmp, strstr (resource, "$MD5$") + 5, 128);
                tmp [128] = '\0';
                CFStringGetCString (text, &tmp [strlen (tmp)], SANE_MAX_PASSWORD_LEN, kCFStringEncodingUTF8);
                CFRelease (text);
                unsigned char result [16];
                md5_buffer (tmp, strlen (tmp), result);
                text = CFStringCreateWithFormat
                    (NULL, NULL, CFSTR ("$MD5$%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x"),
                     result[0],  result[1],  result[2],  result[3],
                     result[4],  result[5],  result[6],  result[7],
                     result[8],  result[9],  result[10], result[11],
                     result[12], result[13], result[14], result[15]);
            }
            CFStringGetCString (text, password, SANE_MAX_PASSWORD_LEN, kCFStringEncodingUTF8);
            CFRelease (text);
            break;
        case kHICommandCancel:
            username [0] = '\0';
            password [0] = '\0';
            break;
    }

    cbresult = GetWRefCon (window);

    DisposeWindow (window);
}
