#include <Carbon/Carbon.h>
#include <AvailabilityMacros.h>

#include <sane/sane.h>

#include <algorithm>

#include "Alerts.h"
#include "DataSource.h"
#include "MakeControls.h"

#if defined (__ppc__)
#define ARCHSTRING CFSTR("ppc")
#elif defined (__ppc64__)
#define ARCHSTRING CFSTR("ppc64")
#elif defined (__i386__)
#define ARCHSTRING CFSTR("i386")
#else
#define ARCHSTRING CFSTR("unknown")
#endif


const EventTypeSpec commandProcessEvent [] = { { kEventClassCommand, kEventCommandProcess } };


static OSStatus AlertEventHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                   void * inUserData) {

    OSStatus osstat;

    HICommandExtended cmd;
    osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeHICommand, NULL,
                                sizeof (HICommandExtended), NULL, &cmd);
    assert (osstat == noErr);

    switch (cmd.commandID) {
        case kHICommandOK:
            osstat = QuitAppModalLoopForWindow ((WindowRef) inUserData);
            assert (osstat == noErr);
            return noErr;
            break;
        default:
            return eventNotHandledErr;
            break;
    }
}


void About (WindowRef parent, SANE_Int saneversion) {

    OSStatus osstat;
    OSErr oserr;

    CFStringRef text;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (CFSTR ("se.ellert.twain-sane"));

    Rect windowrect = { 0, 0, 100, 500 };
    WindowRef window;

    osstat = CreateNewWindow (kSheetWindowClass,
                              kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                              &windowrect, &window);
    assert (osstat == noErr);

    osstat = SetThemeWindowBackground (window, kThemeBrushSheetBackgroundOpaque, true);
    assert (osstat == noErr);

    ControlRef rootcontrol;
    oserr = GetRootControl (window, &rootcontrol);
    assert (oserr == noErr);

    Rect controlrect;

    controlrect.top = 20;
    controlrect.left = 20;
    controlrect.bottom = controlrect.top + 128;
    controlrect.right = controlrect.left + 128;

    IconRef icon;
    ControlButtonContentInfo contentinfo;
    ControlRef iconcontrol;

    oserr = GetIconRef (kOnSystemDisk, 'SANE', 'APPL', &icon);
    assert (oserr == noErr);

    contentinfo.contentType = kControlContentIconRef;
    contentinfo.u.iconRef = icon;
    osstat = CreateIconControl (NULL, &controlrect, &contentinfo, true, &iconcontrol);
    assert (osstat == noErr);

    oserr = EmbedControl (iconcontrol, rootcontrol);
    assert (oserr == noErr);

    int bottom = controlrect.bottom;

    controlrect.top = 20;
    controlrect.left = controlrect.right + 20;
    controlrect.right = windowrect.right - windowrect.left - 20;

    text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, kCFBundleNameKey);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);

    controlrect.top = controlrect.bottom;

    text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle,
                                                               CFSTR ("CFBundleVersionString"));
    text = CFStringCreateWithFormat (NULL, NULL, CFSTR ("%@ (%@)"), text, ARCHSTRING);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
    CFRelease (text);

    controlrect.top = controlrect.bottom;

    text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle,
                                                               CFSTR ("NSHumanReadableCopyright"));
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);

    controlrect.top = controlrect.bottom;

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("translation"), NULL, NULL);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, true);
    CFRelease (text);

    controlrect.top = controlrect.bottom;

    MakeStaticTextControl (rootcontrol, &controlrect,
                           CFSTR ("http://www.ellert.se/twain-sane/"), teFlushLeft, true);

    controlrect.top = controlrect.bottom + 12;

    text = CFStringCreateWithFormat (NULL, NULL, CFSTR ("SANE %i.%i.%i"),
                                     SANE_VERSION_MAJOR (saneversion),
                                     SANE_VERSION_MINOR (saneversion),
                                     SANE_VERSION_BUILD (saneversion));
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
    CFRelease (text);

    controlrect.top = controlrect.bottom;

    MakeStaticTextControl (rootcontrol, &controlrect,
                           CFSTR ("http://www.sane-project.org/"), teFlushLeft, true);

    controlrect.top = controlrect.bottom + 12;

    MakeStaticTextControl (rootcontrol, &controlrect,
                           CFSTR ("libusb"), teFlushLeft, false);

    controlrect.top = controlrect.bottom;

    MakeStaticTextControl (rootcontrol, &controlrect,
                           CFSTR ("http://libusb.sourceforge.net/"), teFlushLeft, true);

    controlrect.top = controlrect.bottom + 12;

    MakeStaticTextControl (rootcontrol, &controlrect,
                           CFSTR ("gettext"), teFlushLeft, false);

    controlrect.top = controlrect.bottom;

    MakeStaticTextControl (rootcontrol, &controlrect,
                           CFSTR ("http://www.gnu.org/software/gettext/"), teFlushLeft, true);

    controlrect.top = std::max (controlrect.bottom + 20, bottom - 20);

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("OK"), NULL, NULL);
    MakeButtonControl (rootcontrol, &controlrect, text, kHICommandOK, true, NULL, 0);
    CFRelease (text);

    windowrect.bottom = controlrect.bottom + 20;

    osstat = SetWindowBounds (window, kWindowContentRgn, &windowrect);
    assert (osstat == noErr);

    EventHandlerUPP AlertEventHandlerUPP = NewEventHandlerUPP (AlertEventHandler);
    osstat = InstallWindowEventHandler (window, AlertEventHandlerUPP,
                                        GetEventTypeCount (commandProcessEvent), commandProcessEvent,
                                        window, NULL);
    assert (osstat == noErr);

    ShowSheetWindow (window, parent);

    osstat = RunAppModalLoopForWindow (window);
    assert (osstat == noErr);

    HideSheetWindow (window);

    DisposeEventHandlerUPP (AlertEventHandlerUPP);

    DisposeWindow (window);
}


void NoDevice () {

    OSStatus osstat;
    OSErr oserr;

    CFStringRef text;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (CFSTR ("se.ellert.twain-sane"));

    Rect windowrect = { 0, 0, 100, 500 };
    WindowRef window;

    osstat = CreateNewWindow (kMovableModalWindowClass,
                              kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                              &windowrect, &window);
    assert (osstat == noErr);

    osstat = SetThemeWindowBackground (window, kThemeBrushMovableModalBackground, true);
    assert (osstat == noErr);

    text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, kCFBundleNameKey);
    osstat = SetWindowTitleWithCFString (window, text);
    assert (osstat == noErr);

    ControlRef rootcontrol;
    oserr = GetRootControl (window, &rootcontrol);
    assert (oserr == noErr);

    Rect controlrect;

    controlrect.top = 20;
    controlrect.left = 20;
    controlrect.bottom = controlrect.top + 64;
    controlrect.right = controlrect.left + 64;

    IconRef icon;
    ControlButtonContentInfo contentinfo;
    ControlRef iconcontrol;

    oserr = GetIconRef (kOnSystemDisk, kSystemIconsCreator, kAlertStopIcon, &icon);
    assert (oserr == noErr);

    contentinfo.contentType = kControlContentIconRef;
    contentinfo.u.iconRef = icon;
    osstat = CreateIconControl (NULL, &controlrect, &contentinfo, true, &iconcontrol);
    assert (osstat == noErr);

    oserr = EmbedControl (iconcontrol, rootcontrol);
    assert (oserr == noErr);

    controlrect.top += 32;
    controlrect.left += 32;

    oserr = GetIconRef (kOnSystemDisk, 'SANE', 'APPL', &icon);
    assert (oserr == noErr);

    contentinfo.contentType = kControlContentIconRef;
    contentinfo.u.iconRef = icon;
    osstat = CreateIconControl (NULL, &controlrect, &contentinfo, true, &iconcontrol);
    assert (osstat == noErr);

    oserr = EmbedControl (iconcontrol, rootcontrol);
    assert (oserr == noErr);

    int bottom = controlrect.bottom;

    controlrect.top = 20;
    controlrect.left = controlrect.right + 20;
    controlrect.right = windowrect.right - windowrect.left - 20;

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("No image source found"), NULL, NULL);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
    CFRelease (text);

    controlrect.top = controlrect.bottom + 12;

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("No image source explanation"), NULL, NULL);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, true);
    CFRelease (text);

    controlrect.top = std::max (controlrect.bottom + 20, bottom - 20);

    text = CFBundleCopyLocalizedString (bundle, CFSTR ("OK"), NULL, NULL);
    MakeButtonControl (rootcontrol, &controlrect, text, kHICommandOK, true, NULL, 0);
    CFRelease (text);

    windowrect.bottom = controlrect.bottom + 20;

    osstat = SetWindowBounds (window, kWindowContentRgn, &windowrect);
    assert (osstat == noErr);

    osstat = RepositionWindow (window, NULL, kWindowAlertPositionOnMainScreen);
    assert (osstat == noErr);

    EventHandlerUPP AlertEventHandlerUPP = NewEventHandlerUPP (AlertEventHandler);
    osstat = InstallWindowEventHandler (window, AlertEventHandlerUPP,
                                        GetEventTypeCount (commandProcessEvent), commandProcessEvent,
                                        window, NULL);
    assert (osstat == noErr);

    ShowWindow (window);

    osstat = RunAppModalLoopForWindow (window);
    assert (osstat == noErr);

    HideWindow (window);

    DisposeEventHandlerUPP (AlertEventHandlerUPP);

    DisposeWindow (window);
}
