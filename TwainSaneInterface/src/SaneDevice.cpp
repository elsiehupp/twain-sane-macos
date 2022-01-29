#include <Carbon/Carbon.h>
#include <TWAIN/TWAIN.h>

#include <libintl.h>

#include <sane/sane.h>
#include <sane/saneopts.h>

#include <algorithm>
#include <cstdlib>
#include <map>
#include <string>

#include "SaneDevice.h"
#include "SaneCallback.h"
#include "Buffer.h"
#include "Image.h"
#include "UserInterface.h"
#include "MakeControls.h"
#include "DataSource.h"

extern "C" {
SANE_Status sane_constrain_value (const SANE_Option_Descriptor * opt, void * value, SANE_Word * info);
}

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


SaneDevice::SaneDevice (DataSource * ds) : currentDevice (-1),
                                           datasource (ds),
                                           userinterface (NULL),
                                           image (NULL) {

    SANE_Status status;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME);

    CFStringRef sanelocalization =
        CFBundleCopyLocalizedString (bundle, CFSTR ("sane-localization"), NULL, NULL);
    char locale [16];
    CFStringGetCString (sanelocalization, locale, 16, kCFStringEncodingUTF8);
    CFRelease (sanelocalization);
    setenv ("LANG", locale, 1);

    CFStringRef SANELocaleDir =
        (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, CFSTR ("SANELocaleDir"));
    char localedir [64];
    CFStringGetCString (SANELocaleDir, localedir, 64, kCFStringEncodingUTF8);
    bindtextdomain ("sane-backends", localedir);
    bind_textdomain_codeset ("sane-backends", "UTF-8");

    status = sane_init (&saneversion, SaneAuthCallback);
    assert (status == SANE_STATUS_GOOD);

    status = sane_get_devices (&devicelist, false);
    assert (status == SANE_STATUS_GOOD);

    if (!devicelist || !(*devicelist)) return;

    int firstDevice = -1;
    CFStringRef deviceString =
        (CFStringRef) CFPreferencesCopyAppValue (CFSTR ("Current Device"), BNDLNAME);
    if (deviceString) {
        if (CFGetTypeID (deviceString) == CFStringGetTypeID ()) {
            for (int device = 0; firstDevice == -1 && devicelist [device]; device++) {
                CFStringRef deviceListString = CreateName (device);
                if (CFStringCompare (deviceString, deviceListString,
                                     kCFCompareCaseInsensitive) == kCFCompareEqualTo)
                    firstDevice = device;
                CFRelease (deviceListString);
            }
        }
        CFRelease (deviceString);
    }
    if (firstDevice == -1) firstDevice = 0;
    int newDevice = ChangeDevice (firstDevice);
    for (int device = 0; newDevice == -1 && devicelist [device]; device++) {
        if (device == firstDevice) continue;
        newDevice = ChangeDevice (device);
    }
}


SaneDevice::~SaneDevice() {

    HideUI ();
    DequeueImage ();

    if (currentDevice != -1) {
        CFStringRef deviceString = CreateName ();
        CFPreferencesSetAppValue (CFSTR ("Current Device"), deviceString, BNDLNAME);
        CFRelease (deviceString);
    }

    for (std::map <int, SANE_Handle>::iterator svsh = sanehandles.begin ();
         svsh != sanehandles.end(); svsh++) {

        currentDevice = svsh->first;

        CFStringRef deviceString = CreateName ();
        CFStringRef deviceKey =
            CFStringCreateWithFormat (NULL, NULL, CFSTR ("Device %@"), deviceString);
        CFRelease (deviceString);
        CFDictionaryRef optionDictionary = CreateOptionDictionary ();
        CFPreferencesSetAppValue (deviceKey, optionDictionary, BNDLNAME);
        CFRelease (deviceKey);
        CFRelease (optionDictionary);

        sane_close (GetSaneHandle ());
    }

    sane_exit ();

    CFPreferencesAppSynchronize (BNDLNAME);
}


void SaneDevice::CallBack (TW_UINT16 MSG) {

    datasource->CallBack (MSG);
}


CFStringRef SaneDevice::CreateName (int device) {

    if (device == -1) device = currentDevice;

    if (!devicelist [device]) return NULL;

    CFStringRef constvendor = CFStringCreateWithCString (NULL, devicelist [device]->vendor, kCFStringEncodingUTF8);
    CFMutableStringRef vendor = CFStringCreateMutableCopy (NULL, 0, constvendor);
    CFRelease(constvendor);
    CFStringTrimWhitespace (vendor);

    CFStringRef constmodel = CFStringCreateWithCString (NULL, devicelist [device]->model, kCFStringEncodingUTF8);
    CFMutableStringRef model = CFStringCreateMutableCopy (NULL, 0, constmodel);
    CFRelease(constmodel);
    CFStringTrimWhitespace (model);

    char * backend = (char *) devicelist [device]->name;
    char * end = strchr (backend, ':');
    if (strncmp (backend, "net:", 4) == 0) {
        // IPv6 addresses should be between brackets
        if (*(end + 1) == '[') end = strchr (end + 1, ']');
        if (end) end = strchr (end + 1, ':');
        if (end) backend = end + 1;
        if (end) end = strchr (end + 1, ':');
    }
    if (end && strncmp (backend, "test:", 5) == 0) end = strchr (end + 1, ':');
    int len = (end ? end - devicelist [device]->name : strlen (devicelist [device]->name));

    char * n = new char [len + 1];
    strncpy (n, devicelist [device]->name, len);
    n [len] = '\0';
    CFStringRef name = CFStringCreateWithCString (NULL, n, kCFStringEncodingUTF8);
    delete[] n;

    CFStringRef text = CFStringCreateWithFormat (NULL, NULL, CFSTR ("%@ %@ (%@)"), vendor, model, name);

    CFRelease (name);
    CFRelease (vendor);
    CFRelease (model);

    return text;
}


int SaneDevice::ChangeDevice (int device) {

    SANE_Status status;

    int oldDevice = currentDevice;
    currentDevice = device;

    if (!GetSaneHandle ()) {
        SANE_Handle sanehandle;

        UInt32 result;
        do {
            SaneCallbackDevice (this);
            status = sane_open (devicelist [currentDevice]->name, &sanehandle);
            result = SaneCallbackResult ();
        }
        while (status != SANE_STATUS_GOOD && result == kHICommandOK);

        if (status != SANE_STATUS_GOOD) {
            if (HasUI()) OpenDeviceFailed ();
            currentDevice = oldDevice;
            return currentDevice;
        }

        assert (status == SANE_STATUS_GOOD);
        assert (sanehandle);
        sanehandles [currentDevice] = sanehandle;

        CFStringRef deviceString = CreateName ();
        CFStringRef deviceKey =
            CFStringCreateWithFormat (NULL, NULL, CFSTR ("Device %@"), deviceString);
        CFRelease (deviceString);
        CFDictionaryRef optionDictionary =
            (CFDictionaryRef) CFPreferencesCopyAppValue (deviceKey, BNDLNAME);
        CFRelease (deviceKey);
        if (optionDictionary) {
            if (CFGetTypeID (optionDictionary) == CFDictionaryGetTypeID ())
                ApplyOptionDictionary (optionDictionary);
            CFRelease (optionDictionary);
        }
    }

    optionIndex.clear ();

    for (int option = 1; const SANE_Option_Descriptor * optdesc =
         sane_get_option_descriptor (GetSaneHandle (), option); option++)
        if (optdesc->type != SANE_TYPE_GROUP) optionIndex [optdesc->name] = option;

    return currentDevice;
}


void SaneDevice::ShowUI (bool uionly) {

    userinterface = new UserInterface (this, currentDevice, uionly);
}


void SaneDevice::HideUI () {

    if (userinterface) delete userinterface;
    userinterface = NULL;
}


bool SaneDevice::HasUI () {

    return (userinterface != NULL);
}


void SaneDevice::ShowSheetWindow (WindowRef window) {

    if (userinterface) userinterface->ShowSheetWindow (window);
}


void SaneDevice::OpenDeviceFailed () {

    OSStatus osstat;
    OSErr oserr;

    CFStringRef text;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (CFSTR ("se.ellert.twain-sane"));

    Rect windowrect = { 0, 0, 100, 500 };
    WindowRef window;

    if (HasUI()) {
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

        text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, kCFBundleNameKey);
        osstat = SetWindowTitleWithCFString (window, text);
        assert (osstat == noErr);
    }

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

    CFStringRef dev = CreateName ();
    CFStringRef format =
        CFBundleCopyLocalizedString (bundle, CFSTR ("Could not open the image source %@"), NULL, NULL);
    text = CFStringCreateWithFormat (NULL, NULL, format, dev);
    CFRelease (format);
    CFRelease (dev);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
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

    if (HasUI()) {
        ShowSheetWindow (window);
    }
    else {
        osstat = RepositionWindow (window, NULL, kWindowAlertPositionOnMainScreen);
        assert (osstat == noErr);

        ShowWindow (window);
    }

    osstat = RunAppModalLoopForWindow (window);
    assert (osstat == noErr);

    if (HasUI())
        HideSheetWindow (window);
    else
        HideWindow (window);

    DisposeEventHandlerUPP (AlertEventHandlerUPP);

    DisposeWindow (window);
}


void SaneDevice::SaneError (SANE_Status status) {

    OSStatus osstat;
    OSErr oserr;

    CFStringRef text;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (CFSTR ("se.ellert.twain-sane"));

    Rect windowrect = { 0, 0, 100, 500 };
    WindowRef window;

    if (HasUI()) {
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

        text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, kCFBundleNameKey);
        osstat = SetWindowTitleWithCFString (window, text);
        assert (osstat == noErr);
    }

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

    text = CFStringCreateWithCString (NULL, sane_strstatus (status), kCFStringEncodingUTF8);
    MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
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

    if (HasUI()) {
        ShowSheetWindow (window);
    }
    else {
        osstat = RepositionWindow (window, NULL, kWindowAlertPositionOnMainScreen);
        assert (osstat == noErr);

        ShowWindow (window);
    }

    osstat = RunAppModalLoopForWindow (window);
    assert (osstat == noErr);

    if (HasUI())
        HideSheetWindow (window);
    else
        HideWindow (window);

    DisposeEventHandlerUPP (AlertEventHandlerUPP);

    DisposeWindow (window);
}


TW_UINT16 SaneDevice::GetCustomData (pTW_CUSTOMDSDATA customdata) {

    CFMutableDictionaryRef dataDictionary =
        CFDictionaryCreateMutable (NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                   &kCFTypeDictionaryValueCallBacks);
    CFStringRef deviceString = CreateName();
    CFDictionaryAddValue (dataDictionary, CFSTR ("Current Device"), deviceString);
    CFStringRef deviceKey = CFStringCreateWithFormat (NULL, NULL, CFSTR ("Device %@"), deviceString);
    CFRelease (deviceString);
    CFDictionaryRef optionDictionary = CreateOptionDictionary ();
    CFDictionaryAddValue (dataDictionary, deviceKey, optionDictionary);
    CFRelease (deviceKey);
    CFRelease (optionDictionary);

    CFDataRef xml = CFPropertyListCreateXMLData (NULL, dataDictionary);
    CFRelease (dataDictionary);

    customdata->InfoLength = CFDataGetLength (xml);
    customdata->hData = (TW_HANDLE) NewHandle (customdata->InfoLength);
    HLock ((Handle) customdata->hData);
    CFDataGetBytes (xml, CFRangeMake (0, customdata->InfoLength), (UInt8 *) *(Handle) customdata->hData);
    HUnlock ((Handle) customdata->hData);

    CFRelease (xml);

    return TWRC_SUCCESS;
}


TW_UINT16 SaneDevice::SetCustomData (pTW_CUSTOMDSDATA customdata) {

    bool done = false;

    HLock ((Handle) customdata->hData);
    CFDataRef xml = CFDataCreate (NULL, (UInt8 *) *(Handle) customdata->hData, customdata->InfoLength);
    HUnlock ((Handle) customdata->hData);

    CFDictionaryRef dataDictionary =
        (CFDictionaryRef) CFPropertyListCreateFromXMLData (NULL, xml, kCFPropertyListImmutable, NULL);
    CFRelease (xml);

    if (dataDictionary) {
        if (CFGetTypeID (dataDictionary) == CFDictionaryGetTypeID ()) {
            CFStringRef deviceString =
                (CFStringRef) CFDictionaryGetValue (dataDictionary, CFSTR ("Current Device"));
            if (deviceString && CFGetTypeID (deviceString) == CFStringGetTypeID ()) {
                for (int device = 0; devicelist [device]; device++) {
                    CFStringRef deviceListString = CreateName (device);
                    if (CFStringCompare (deviceString, deviceListString,
                                         kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        if (ChangeDevice (device) == device) {
                            CFStringRef deviceKey =
                                CFStringCreateWithFormat (NULL, NULL, CFSTR ("Device %@"), deviceString);
                            CFDictionaryRef optionDictictionary =
                                (CFDictionaryRef) CFDictionaryGetValue (dataDictionary, deviceKey);
                            CFRelease (deviceKey);
                            if (optionDictictionary &&
                                CFGetTypeID (optionDictictionary) == CFDictionaryGetTypeID ()) {
                                ApplyOptionDictionary (optionDictictionary);
                                done = true;
                            }
                        }
                    }
                    CFRelease (deviceListString);
                }
            }
        }
        CFRelease (dataDictionary);
    }

    return (done ? TWRC_SUCCESS : datasource->SetStatus (TWCC_OPERATIONERROR));
}


CFDictionaryRef SaneDevice::CreateOptionDictionary () {

    SANE_Status status;

    CFMutableDictionaryRef dict =
        CFDictionaryCreateMutable (NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                   &kCFTypeDictionaryValueCallBacks);

    for (int option = 1; const SANE_Option_Descriptor * optdesc =
         sane_get_option_descriptor (GetSaneHandle (), option); option++) {

        if (optdesc->type != SANE_TYPE_GROUP &&
            SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {

            CFStringRef key = CFStringCreateWithCString (NULL, optdesc->name, kCFStringEncodingUTF8);

            switch (optdesc->type) {

                case SANE_TYPE_BOOL:

                    SANE_Bool optval;
                    status = sane_control_option (GetSaneHandle (), option,
                                                  SANE_ACTION_GET_VALUE, &optval, NULL);
                    assert (status == SANE_STATUS_GOOD);
                    CFDictionaryAddValue (dict, key, (optval ? kCFBooleanTrue : kCFBooleanFalse));
                    break;

                case SANE_TYPE_INT:

                    if (optdesc->size > sizeof (SANE_Word)) {
                        SANE_Word * optval = new SANE_Word [optdesc->size / sizeof (SANE_Word)];
                        status = sane_control_option (GetSaneHandle (), option,
                                                      SANE_ACTION_GET_VALUE, optval, NULL);
                        assert (status == SANE_STATUS_GOOD);
                        CFMutableArrayRef cfarray =
                            CFArrayCreateMutable (NULL, 0, &kCFTypeArrayCallBacks);
                        for (int i = 0; i < optdesc->size / sizeof (SANE_Word); i++) {
                            CFNumberRef cfvalue =
                                CFNumberCreate (NULL, kCFNumberIntType, &optval [i]);
                            CFArrayAppendValue (cfarray, cfvalue);
                            CFRelease (cfvalue);
                        }
                        delete[] optval;
                        CFDictionaryAddValue (dict, key, cfarray);
                        CFRelease (cfarray);
                    }
                    else {
                        SANE_Word optval;
                        status = sane_control_option (GetSaneHandle (), option,
                                                      SANE_ACTION_GET_VALUE, &optval, NULL);
                        assert (status == SANE_STATUS_GOOD);
                        CFNumberRef cfvalue = CFNumberCreate (NULL, kCFNumberIntType, &optval);
                        CFDictionaryAddValue (dict, key, cfvalue);
                        CFRelease (cfvalue);
                    }
                    break;

                case SANE_TYPE_FIXED:

                    if (optdesc->size > sizeof (SANE_Word)) {
                        SANE_Word * optval = new SANE_Word [optdesc->size / sizeof (SANE_Word)];
                        status = sane_control_option (GetSaneHandle (), option,
                                                      SANE_ACTION_GET_VALUE, optval, NULL);
                        assert (status == SANE_STATUS_GOOD);
                        CFMutableArrayRef cfarray =
                            CFArrayCreateMutable (NULL, 0, &kCFTypeArrayCallBacks);
                        for (int i = 0; i < optdesc->size / sizeof (SANE_Word); i++) {
                            double val = SANE_UNFIX (optval [i]);
                            CFNumberRef cfvalue = CFNumberCreate (NULL, kCFNumberDoubleType, &val);
                            CFArrayAppendValue (cfarray, cfvalue);
                            CFRelease (cfvalue);
                        }
                        delete[] optval;
                        CFDictionaryAddValue (dict, key, cfarray);
                        CFRelease (cfarray);
                    }
                    else {
                        SANE_Word optval;
                        status = sane_control_option (GetSaneHandle (), option,
                                                      SANE_ACTION_GET_VALUE, &optval, NULL);
                        assert (status == SANE_STATUS_GOOD);
                        double val = SANE_UNFIX (optval);
                        CFNumberRef cfvalue = CFNumberCreate (NULL, kCFNumberDoubleType, &val);
                        CFDictionaryAddValue (dict, key, cfvalue);
                        CFRelease (cfvalue);
                    }
                    break;

                case SANE_TYPE_STRING: {

                    SANE_String optval = new char [optdesc->size];
                    status = sane_control_option (GetSaneHandle (), option,
                                                  SANE_ACTION_GET_VALUE, optval, NULL);
                    assert (status == SANE_STATUS_GOOD);
                    CFStringRef cfvalue = CFStringCreateWithCString (NULL, optval,
                                                                     kCFStringEncodingUTF8);
                    delete[] optval;
                    CFDictionaryAddValue (dict, key, cfvalue);
                    CFRelease (cfvalue);
                    break;
                }

                default:
                    break;
            }

            CFRelease (key);
        }
    }

    return dict;
}


void SaneDevice::ApplyOptionDictionary (CFDictionaryRef dict) {

    SANE_Status status;

    for (int option = 1; const SANE_Option_Descriptor * optdesc =
         sane_get_option_descriptor (GetSaneHandle (), option); option++) {

        if (optdesc->type != SANE_TYPE_GROUP &&
            SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {

            CFStringRef key = CFStringCreateWithCString (NULL, optdesc->name, kCFStringEncodingUTF8);

            switch (optdesc->type) {

                case SANE_TYPE_BOOL: {

                    CFBooleanRef cfvalue = (CFBooleanRef) CFDictionaryGetValue (dict, key);
                    if (cfvalue && CFGetTypeID (cfvalue) == CFBooleanGetTypeID ()) {
                        SANE_Bool optval = CFBooleanGetValue (cfvalue);
                        status = sane_control_option (GetSaneHandle (), option,
                                                      SANE_ACTION_SET_VALUE, &optval, NULL);
                        assert (status == SANE_STATUS_GOOD);
                    }
                    break;
                }

                case SANE_TYPE_INT:

                    if (optdesc->size > sizeof (SANE_Word)) {
                        CFArrayRef cfarray = (CFArrayRef) CFDictionaryGetValue (dict, key);
                        if (cfarray && CFGetTypeID (cfarray) == CFArrayGetTypeID () &&
                            CFArrayGetCount (cfarray) == optdesc->size / sizeof (SANE_Word)) {
                            SANE_Word * optval = new SANE_Word [optdesc->size / sizeof (SANE_Word)];
                            status = sane_control_option (GetSaneHandle (), option,
                                                          SANE_ACTION_GET_VALUE, optval, NULL);
                            assert (status == SANE_STATUS_GOOD);
                            for (int i = 0; i < optdesc->size / sizeof (SANE_Word); i++) {
                                CFNumberRef cfvalue =
                                    (CFNumberRef) CFArrayGetValueAtIndex (cfarray, i);
                                if (cfvalue && CFGetTypeID (cfvalue) == CFNumberGetTypeID ())
                                    CFNumberGetValue (cfvalue, kCFNumberIntType, &optval [i]);
                            }
                            status = sane_control_option (GetSaneHandle (), option,
                                                          SANE_ACTION_SET_VALUE, optval, NULL);
                            assert (status == SANE_STATUS_GOOD);
                            delete[] optval;
                        }
                    }
                    else {
                        CFNumberRef cfvalue = (CFNumberRef) CFDictionaryGetValue (dict, key);
                        if (cfvalue && CFGetTypeID (cfvalue) == CFNumberGetTypeID ()) {
                            SANE_Word optval;
                            CFNumberGetValue (cfvalue, kCFNumberIntType, &optval);
                            status = sane_control_option (GetSaneHandle (), option,
                                                          SANE_ACTION_SET_VALUE, &optval, NULL);
                            assert (status == SANE_STATUS_GOOD);
                        }
                    }
                    break;

                case SANE_TYPE_FIXED:

                    if (optdesc->size > sizeof (SANE_Word)) {
                        CFArrayRef cfarray = (CFArrayRef) CFDictionaryGetValue (dict, key);
                        if (cfarray && CFGetTypeID (cfarray) == CFArrayGetTypeID () &&
                            CFArrayGetCount (cfarray) == optdesc->size / sizeof (SANE_Word)) {
                            SANE_Word * optval = new SANE_Word [optdesc->size / sizeof (SANE_Word)];
                            status = sane_control_option (GetSaneHandle (), option,
                                                          SANE_ACTION_GET_VALUE, optval, NULL);
                            assert (status == SANE_STATUS_GOOD);
                            for (int i = 0; i < optdesc->size / sizeof (SANE_Word); i++) {
                                CFNumberRef cfvalue =
                                    (CFNumberRef) CFArrayGetValueAtIndex (cfarray, i);
                                if (cfvalue && CFGetTypeID (cfvalue) == CFNumberGetTypeID ()) {
                                    double val;
                                    CFNumberGetValue (cfvalue, kCFNumberDoubleType, &val);
                                    optval [i] = SANE_FIX (val);
                                }
                            }
                            status = sane_control_option (GetSaneHandle (), option,
                                                          SANE_ACTION_SET_VALUE, optval, NULL);
                            assert (status == SANE_STATUS_GOOD);
                            delete[] optval;
                        }
                    }
                    else {
                        CFNumberRef cfvalue = (CFNumberRef) CFDictionaryGetValue (dict, key);
                        if (cfvalue && CFGetTypeID (cfvalue) == CFNumberGetTypeID ()) {
                            double val;
                            CFNumberGetValue (cfvalue, kCFNumberDoubleType, &val);
                            SANE_Word optval = SANE_FIX (val);
                            status = sane_control_option (GetSaneHandle (), option,
                                                          SANE_ACTION_SET_VALUE, &optval, NULL);
                            assert (status == SANE_STATUS_GOOD);
                        }
                    }
                    break;

                case SANE_TYPE_STRING: {

                    CFStringRef cfvalue = (CFStringRef) CFDictionaryGetValue (dict, key);
                    if (cfvalue && CFGetTypeID (cfvalue) == CFStringGetTypeID ()) {
                        SANE_String optval = new char [optdesc->size];
                        CFStringGetCString (cfvalue, optval, optdesc->size, kCFStringEncodingUTF8);
                        status = sane_control_option (GetSaneHandle (), option,
                                                      SANE_ACTION_SET_VALUE, optval, NULL);
                        assert (status == SANE_STATUS_GOOD);
                        delete[] optval;
                    }
                    break;
                }

                default:
                    break;
            }

            CFRelease (key);
        }
    }
}


void SaneDevice::GetRect (SANE_Rect * rect) {

    int option;
    const SANE_Option_Descriptor * optdesc;
    SANE_Status status;

    option = optionIndex [SANE_NAME_SCAN_TL_Y];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                      &rect->top, NULL);
        assert (status == SANE_STATUS_GOOD);
        rect->type = optdesc->type;
        rect->unit = optdesc->unit;
    }
    else {
        rect->top = -1;
        rect->type = SANE_TYPE_FIXED;
        rect->unit = SANE_UNIT_MM;
    }

    option = optionIndex [SANE_NAME_SCAN_TL_X];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                      &rect->left, NULL);
        assert (status == SANE_STATUS_GOOD);
    }
    else
        rect->left = -1;

    option = optionIndex [SANE_NAME_SCAN_BR_Y];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                      &rect->bottom, NULL);
        assert (status == SANE_STATUS_GOOD);
    }
    else
        rect->bottom = -1;

    option = optionIndex [SANE_NAME_SCAN_BR_X];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                      &rect->right, NULL);
        assert (status == SANE_STATUS_GOOD);
    }
    else
        rect->right = -1;
}


void SaneDevice::SetRect (SANE_Rect * rect) {

    int option;
    const SANE_Option_Descriptor * optdesc;
    SANE_Status status;
    SANE_Int info;

    SANE_Rect oldrect;
    GetRect (&oldrect);

    if (rect->top < oldrect.bottom) {

        option = optionIndex [SANE_NAME_SCAN_TL_Y];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->top, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->top, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->top, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }

        option = optionIndex [SANE_NAME_SCAN_BR_Y];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->bottom, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->bottom, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->bottom, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }
    }

    else {

        option = optionIndex [SANE_NAME_SCAN_BR_Y];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->bottom, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->bottom, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->bottom, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }

        option = optionIndex [SANE_NAME_SCAN_TL_Y];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->top, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->top, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->top, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }
    }

    if (rect->left < oldrect.right) {

        option = optionIndex [SANE_NAME_SCAN_TL_X];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->left, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->left, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->left, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }

        option = optionIndex [SANE_NAME_SCAN_BR_X];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->right, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->right, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->right, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }
    }

    else {

        option = optionIndex [SANE_NAME_SCAN_BR_X];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->right, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->right, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->right, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }

        option = optionIndex [SANE_NAME_SCAN_TL_X];
        optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
        if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
            status = sane_constrain_value (optdesc, &rect->left, NULL);
            assert (status == SANE_STATUS_GOOD);
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                          &rect->left, &info);
            assert (status == SANE_STATUS_GOOD);
            if (info & SANE_INFO_INEXACT) {
                status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                              &rect->left, NULL);
                assert (status == SANE_STATUS_GOOD);
            }
        }
    }
}


void SaneDevice::GetMaxRect (SANE_Rect * rect) {

    int option;
    const SANE_Option_Descriptor * optdesc;

    option = optionIndex [SANE_NAME_SCAN_TL_Y];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap)) {
        switch (optdesc->constraint_type) {
            case SANE_CONSTRAINT_RANGE:
                rect->top = optdesc->constraint.range->min;
                break;
            case SANE_CONSTRAINT_WORD_LIST:
                rect->top = optdesc->constraint.word_list [1];
                break;
            default:
                rect->top = -1;
                break;
        }
        rect->type = optdesc->type;
        rect->unit = optdesc->unit;
    }
    else
        rect->top = -1;

    option = optionIndex [SANE_NAME_SCAN_TL_X];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap)) {
        switch (optdesc->constraint_type) {
            case SANE_CONSTRAINT_RANGE:
                rect->left = optdesc->constraint.range->min;
                break;
            case SANE_CONSTRAINT_WORD_LIST:
                rect->left = optdesc->constraint.word_list [1];
                break;
            default:
                rect->left = -1;
                break;
        }
    }
    else
        rect->left = -1;

    option = optionIndex [SANE_NAME_SCAN_BR_Y];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap)) {
        switch (optdesc->constraint_type) {
            case SANE_CONSTRAINT_RANGE:
                rect->bottom = optdesc->constraint.range->max;
                break;
            case SANE_CONSTRAINT_WORD_LIST:
                rect->bottom = optdesc->constraint.word_list [optdesc->constraint.word_list [0]];
                break;
            default:
                rect->bottom = -1;
                break;
        }
    }
    else
        rect->bottom = -1;

    option = optionIndex [SANE_NAME_SCAN_BR_X];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap)) {
        switch (optdesc->constraint_type) {
            case SANE_CONSTRAINT_RANGE:
                rect->right = optdesc->constraint.range->max;
                break;
            case SANE_CONSTRAINT_WORD_LIST:
                rect->right = optdesc->constraint.word_list [optdesc->constraint.word_list [0]];
                break;
            default:
                rect->right = -1;
                break;
        }
    }
    else
        rect->right = -1;
}


void SaneDevice::GetResolution (SANE_Resolution * res) {

    int option;
    const SANE_Option_Descriptor * optdesc;
    SANE_Status status;

    option = optionIndex [SANE_NAME_SCAN_X_RESOLUTION];
    if (!option)
        option = optionIndex [SANE_NAME_SCAN_RESOLUTION];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                      &res->h, NULL);
        assert (status == SANE_STATUS_GOOD);
        res->type = optdesc->type;
    }
    else {
        res->h = 72;
        res->type = SANE_TYPE_INT;
    }

    option = optionIndex [SANE_NAME_SCAN_Y_RESOLUTION];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_GETTABLE (optdesc->cap)) {
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                      &res->v, NULL);
        assert (status == SANE_STATUS_GOOD);
    }
    else
        res->v = res->h;
}


void SaneDevice::SetResolution (SANE_Resolution * res) {

    int option;
    const SANE_Option_Descriptor * optdesc;
    SANE_Status status;
    SANE_Int info;

    option = optionIndex [SANE_NAME_SCAN_X_RESOLUTION];
    if (!option)
        option = optionIndex [SANE_NAME_SCAN_RESOLUTION];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
        status = sane_constrain_value (optdesc, &res->h, NULL);
        assert (status == SANE_STATUS_GOOD);
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                      &res->h, &info);
        assert (status == SANE_STATUS_GOOD);
        if (info & SANE_INFO_INEXACT) {
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                          &res->h, NULL);
            assert (status == SANE_STATUS_GOOD);
        }
    }

    option = optionIndex [SANE_NAME_SCAN_Y_RESOLUTION];
    optdesc = (option ? sane_get_option_descriptor (GetSaneHandle (), option) : NULL);
    if (optdesc && SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
        status = sane_constrain_value (optdesc, &res->v, NULL);
        assert (status == SANE_STATUS_GOOD);
        status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                      &res->v, &info);
        assert (status == SANE_STATUS_GOOD);
        if (info & SANE_INFO_INEXACT) {
            status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                          &res->v, NULL);
            assert (status == SANE_STATUS_GOOD);
        }
    }
}


TW_UINT16 SaneDevice::GetPixelType (pTW_CAPABILITY capability, bool onlyone) {

    int option = optionIndex [SANE_NAME_SCAN_MODE];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_STRING) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    TW_UINT16 pixeltype = (TW_UINT16) -1;

    SANE_String optval = new char [optdesc->size];
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE, optval, NULL);
    assert (status == SANE_STATUS_GOOD);

    if (strncasecmp (optval, "binary", 6) == 0 ||
        strncasecmp (optval, "lineart", 7) == 0 ||
        strncasecmp (optval, "halftone", 8) == 0) pixeltype = TWPT_BW;
    else if (strncasecmp (optval, "gray", 4) == 0) pixeltype = TWPT_GRAY;
    else if (strncasecmp (optval, "color", 5) == 0) pixeltype = TWPT_RGB;

    delete[] optval;

    if (pixeltype == (TW_UINT16) -1) return datasource->SetStatus (TWCC_BADVALUE);

    if (onlyone) return datasource->BuildOneValue (capability, TWTY_UINT16, pixeltype);

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_STRING_LIST: {

            bool havebw = false;
            bool havegray = false;
            bool havergb = false;

            for (int i = 0; optdesc->constraint.string_list [i] != NULL; i++) {
                if (strncasecmp (optdesc->constraint.string_list [i], "binary", 6) == 0 ||
                    strncasecmp (optdesc->constraint.string_list [i], "lineart", 7) == 0 ||
                    strncasecmp (optdesc->constraint.string_list [i], "halftone", 8) == 0) havebw = true;
                else if (strncasecmp (optdesc->constraint.string_list [i], "gray", 4) == 0) havegray = true;
                else if (strncasecmp (optdesc->constraint.string_list [i], "color", 5) == 0) havergb = true;
            }

            TW_UINT16 pixeltypes [3];

            TW_UINT32 numitems = 0;
            TW_UINT32 currentindex = 0;
            if (havebw) {
                pixeltypes [numitems] = TWPT_BW;
                if (pixeltype == TWPT_BW) currentindex = numitems;
                numitems++;
            }
            if (havegray) {
                pixeltypes [numitems] = TWPT_GRAY;
                if (pixeltype == TWPT_GRAY) currentindex = numitems;
                numitems++;
            }
            if (havergb) {
                pixeltypes [numitems] = TWPT_RGB;
                if (pixeltype == TWPT_RGB) currentindex = numitems;
                numitems++;
            }

            return datasource->BuildEnumeration (capability, TWTY_UINT16, numitems, currentindex, 0, pixeltypes);
            break;
        }

        default:
            return datasource->BuildOneValue (capability, TWTY_UINT16, pixeltype);
            break;
    }
}


TW_UINT16 SaneDevice::GetPixelTypeDefault (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_MODE];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap)) return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->constraint_type != SANE_CONSTRAINT_STRING_LIST)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    bool havebw = false;
    bool havegray = false;
    bool havergb = false;

    for (int i = 0; optdesc->constraint.string_list [i] != NULL; i++) {
        if (strncasecmp (optdesc->constraint.string_list [i], "binary", 6) == 0 ||
            strncasecmp (optdesc->constraint.string_list [i], "lineart", 7) == 0 ||
            strncasecmp (optdesc->constraint.string_list [i], "halftone", 8) == 0) havebw = true;
        else if (strncasecmp (optdesc->constraint.string_list [i], "gray", 4) == 0) havegray = true;
        else if (strncasecmp (optdesc->constraint.string_list [i], "color", 5) == 0) havergb = true;
    }

    TW_UINT16 pixeltype;

    if (havebw)
        pixeltype = TWPT_BW;
    else if (havegray)
        pixeltype = TWPT_GRAY;
    else if (havergb)
        pixeltype = TWPT_RGB;
    else
        return datasource->SetStatus (TWCC_BADVALUE);

    return datasource->BuildOneValue (capability, TWTY_UINT16, pixeltype);
}


TW_UINT16 SaneDevice::SetPixelType (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_MODE];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_SETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->constraint_type != SANE_CONSTRAINT_STRING_LIST)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    bool havebw = false;
    bool havegray = false;
    bool havergb = false;

    for (int i = 0; optdesc->constraint.string_list [i] != NULL; i++) {
        if (strncasecmp (optdesc->constraint.string_list [i], "binary", 6) == 0 ||
            strncasecmp (optdesc->constraint.string_list [i], "lineart", 7) == 0 ||
            strncasecmp (optdesc->constraint.string_list [i], "halftone", 8) == 0) havebw = true;
        else if (strncasecmp (optdesc->constraint.string_list [i], "gray", 4) == 0) havegray = true;
        else if (strncasecmp (optdesc->constraint.string_list [i], "color", 5) == 0) havergb = true;
    }

    TW_UINT16 pixeltype;
    bool inexact = false;

    if (capability) {
        if (capability->ConType != TWON_ONEVALUE) return datasource->SetStatus (TWCC_BADVALUE);
        pixeltype = ((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item;
        // fallback to gray if binary/lineart/halftone does not exist
        if (pixeltype == TWPT_BW && !havebw) {
            pixeltype = TWPT_GRAY;
            inexact = true;
        }
    }
    else {
        if (havebw)
            pixeltype = TWPT_BW;
        else if (havegray)
            pixeltype = TWPT_GRAY;
        else if (havergb)
            pixeltype = TWPT_RGB;
        else
            return datasource->SetStatus (TWCC_BADVALUE);
    }

    for (int i = 0; optdesc->constraint.string_list [i] != NULL; i++) {

        if ((pixeltype == TWPT_BW && (strncasecmp (optdesc->constraint.string_list [i], "binary", 6) == 0 ||
                                      strncasecmp (optdesc->constraint.string_list [i], "lineart", 7) == 0 ||
                                      strncasecmp (optdesc->constraint.string_list [i], "halftone", 8) == 0)) ||
            (pixeltype == TWPT_GRAY && strncasecmp (optdesc->constraint.string_list [i], "gray", 4) == 0) ||
            (pixeltype == TWPT_RGB && strncasecmp (optdesc->constraint.string_list [i], "color", 5) == 0)) {

            SANE_String optval = new char [optdesc->size];
            strcpy (optval, optdesc->constraint.string_list [i]);
            SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE,
                                                      optval, NULL);
            assert (status == SANE_STATUS_GOOD);
            delete[] optval;
            return (inexact ? TWRC_CHECKSTATUS : TWRC_SUCCESS);
        }
    }

    return datasource->SetStatus (TWCC_BADVALUE);
}


TW_UINT16 SaneDevice::GetBitDepth (pTW_CAPABILITY capability, bool onlyone) {

    int option = optionIndex [SANE_NAME_BIT_DEPTH];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Int bitdepth;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE, &bitdepth, NULL);
    assert (status == SANE_STATUS_GOOD);

    if (onlyone) return datasource->BuildOneValue (capability, TWTY_UINT16, bitdepth);

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            return datasource->BuildRange (capability, TWTY_UINT16,
                                           optdesc->constraint.range->min,
                                           optdesc->constraint.range->max,
                                           std::max (optdesc->constraint.range->quant, 1),
                                           optdesc->constraint.range->min,
                                           bitdepth);
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            pTW_UINT16 itemlist = new TW_UINT16 [optdesc->constraint.word_list [0]];
            TW_UINT32 currentindex = 0;
            for (int i = 0; i < optdesc->constraint.word_list [0]; i++) {
                itemlist [i] = optdesc->constraint.word_list [i + 1];
                if (bitdepth == optdesc->constraint.word_list [i + 1]) currentindex = i;
            }
            TW_UINT16 retval = datasource->BuildEnumeration (capability, TWTY_UINT16,
                                                             optdesc->constraint.word_list [0],
                                                             currentindex, 0, itemlist);
            delete[] itemlist;
            return retval;
            break;
        }

        default:
            return datasource->BuildOneValue (capability, TWTY_UINT16, bitdepth);
            break;
    }
}


TW_UINT16 SaneDevice::GetBitDepthDefault (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_BIT_DEPTH];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap)) return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE:
            return datasource->BuildOneValue (capability, TWTY_UINT16, optdesc->constraint.range->min);
            break;

        case SANE_CONSTRAINT_WORD_LIST:
            return datasource->BuildOneValue (capability, TWTY_UINT16, optdesc->constraint.word_list [1]);
            break;

        default:
            return datasource->SetStatus (TWCC_BADVALUE);
            break;
    }
}


TW_UINT16 SaneDevice::SetBitDepth (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_BIT_DEPTH];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_SETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Int bitdepth;

    if (capability) {
        if (capability->ConType != TWON_ONEVALUE) return datasource->SetStatus (TWCC_BADVALUE);
        bitdepth = ((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item;
    }
    else {
        switch (optdesc->constraint_type) {
            case SANE_CONSTRAINT_RANGE:
                bitdepth = optdesc->constraint.range->min;
                break;
            case SANE_CONSTRAINT_WORD_LIST:
                bitdepth = optdesc->constraint.word_list [1];
                break;
            default:
                return datasource->SetStatus (TWCC_BADVALUE);
                break;
        }
    }

    SANE_Int info;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE, &bitdepth, &info);
    assert (status == SANE_STATUS_GOOD);
    return (info ? TWRC_CHECKSTATUS : TWRC_SUCCESS);
}


TW_UINT16 SaneDevice::GetXNativeResolution (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_X_RESOLUTION];
    if (!option)
        option = optionIndex [SANE_NAME_SCAN_RESOLUTION];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32,
                                                  S2T (SANE_INT2FIX (optdesc->constraint.range->max)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (optdesc->constraint.range->max));
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32,
                                                  S2T (SANE_INT2FIX (optdesc->constraint.word_list
                                                                     [optdesc->constraint.word_list [0]])));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32,
                                                  S2T (optdesc->constraint.word_list
                                                       [optdesc->constraint.word_list [0]]));
            break;
        }

        default:

            SANE_Word xres;
            SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                                      &xres, NULL);
            assert (status == SANE_STATUS_GOOD);

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (xres)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (xres));
            break;
    }
}


TW_UINT16 SaneDevice::GetYNativeResolution (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_Y_RESOLUTION];
    if (!option) return GetXNativeResolution (capability);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32,
                                                  S2T (SANE_INT2FIX (optdesc->constraint.range->max)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (optdesc->constraint.range->max));
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32,
                                                  S2T (SANE_INT2FIX (optdesc->constraint.word_list
                                                                     [optdesc->constraint.word_list [0]])));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32,
                                                  S2T (optdesc->constraint.word_list
                                                       [optdesc->constraint.word_list [0]]));
            break;
        }

        default:

            SANE_Word yres;
            SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE,
                                                      &yres, NULL);
            assert (status == SANE_STATUS_GOOD);

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (yres)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (yres));
            break;
    }
}


TW_UINT16 SaneDevice::GetXResolution (pTW_CAPABILITY capability, bool onlyone) {

    int option = optionIndex [SANE_NAME_SCAN_X_RESOLUTION];
    if (!option)
        option = optionIndex [SANE_NAME_SCAN_RESOLUTION];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word xres;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE, &xres, NULL);
    assert (status == SANE_STATUS_GOOD);

    if (onlyone) {
        if (optdesc->type == SANE_TYPE_INT)
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (xres)));
        else
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (xres));
    }

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->min)),
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->max)),
                                               S2T (SANE_INT2FIX (std::max (optdesc->constraint.range->quant, 1))),
                                               S2T (SANE_INT2FIX (72)),
                                               S2T (SANE_INT2FIX (xres)));
            else
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (optdesc->constraint.range->min),
                                               S2T (optdesc->constraint.range->max),
                                               S2T (std::max (optdesc->constraint.range->quant, 1)),
                                               S2T (SANE_INT2FIX (72)),
                                               S2T (xres));
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            pTW_FIX32 itemlist = new TW_FIX32 [optdesc->constraint.word_list [0]];
            TW_UINT32 currentindex = 0;
            TW_UINT32 defaultindex = 0;
            for (int i = 0; i < optdesc->constraint.word_list [0]; i++) {
                if (optdesc->type == SANE_TYPE_INT)
                    itemlist [i] = S2T (SANE_INT2FIX (optdesc->constraint.word_list [i + 1]));
                else
                    itemlist [i] = S2T (optdesc->constraint.word_list [i + 1]);
                if (std::abs (T2S (itemlist [i]) - SANE_INT2FIX (72)) <
                    std::abs (T2S (itemlist [defaultindex]) - SANE_INT2FIX (72))) defaultindex = i;
                if (xres == optdesc->constraint.word_list [i + 1]) currentindex = i;
            }
            TW_UINT16 retval = datasource->BuildEnumeration (capability, TWTY_FIX32,
                                                             optdesc->constraint.word_list [0],
                                                             currentindex, defaultindex, itemlist);
            delete[] itemlist;
            return retval;
            break;
        }

        default:
            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (xres)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (xres));
            break;
    }
}


TW_UINT16 SaneDevice::GetXResolutionDefault (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_X_RESOLUTION];
    if (!option)
        option = optionIndex [SANE_NAME_SCAN_RESOLUTION];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap)) return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (72)));
}


TW_UINT16 SaneDevice::SetXResolution (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_X_RESOLUTION];
    if (!option)
        option = optionIndex [SANE_NAME_SCAN_RESOLUTION];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_SETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word xres;

    if (capability) {
        if (capability->ConType != TWON_ONEVALUE) return datasource->SetStatus (TWCC_BADVALUE);
        if (optdesc->type == SANE_TYPE_INT)
            xres = SANE_FIX2INT (T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item))));
        else
            xres = T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item)));
    }
    else {
        if (optdesc->type == SANE_TYPE_INT)
            xres = 72;
        else
            xres = SANE_INT2FIX (72);
    }

    SANE_Int info;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE, &xres, &info);
    assert (status == SANE_STATUS_GOOD);
    return (info ? TWRC_CHECKSTATUS : TWRC_SUCCESS);
}


TW_UINT16 SaneDevice::GetYResolution (pTW_CAPABILITY capability, bool onlyone) {

    int option = optionIndex [SANE_NAME_SCAN_Y_RESOLUTION];
    if (!option) return GetXResolution (capability, onlyone);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word yres;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE, &yres, NULL);
    assert (status == SANE_STATUS_GOOD);

    if (onlyone) {
        if (optdesc->type == SANE_TYPE_INT)
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (yres)));
        else
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (yres));
    }

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->min)),
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->max)),
                                               S2T (SANE_INT2FIX (std::max (optdesc->constraint.range->quant, 1))),
                                               S2T (SANE_INT2FIX (72)),
                                               S2T (SANE_INT2FIX (yres)));
            else
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (optdesc->constraint.range->min),
                                               S2T (optdesc->constraint.range->max),
                                               S2T (std::max (optdesc->constraint.range->quant, 1)),
                                               S2T (SANE_INT2FIX (72)),
                                               S2T (yres));
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            pTW_FIX32 itemlist = new TW_FIX32 [optdesc->constraint.word_list [0]];
            TW_UINT32 currentindex = 0;
            TW_UINT32 defaultindex = 0;
            for (int i = 0; i < optdesc->constraint.word_list [0]; i++) {
                if (optdesc->type == SANE_TYPE_INT)
                    itemlist [i] = S2T (SANE_INT2FIX (optdesc->constraint.word_list [i + 1]));
                else
                    itemlist [i] = S2T (optdesc->constraint.word_list [i + 1]);
                if (std::abs (T2S (itemlist [i]) - SANE_INT2FIX (72)) <
                    std::abs (T2S (itemlist [defaultindex]) - SANE_INT2FIX (72))) defaultindex = i;
                if (yres == optdesc->constraint.word_list [i + 1]) currentindex = i;
            }
            TW_UINT16 retval = datasource->BuildEnumeration (capability, TWTY_FIX32,
                                                             optdesc->constraint.word_list [0],
                                                             currentindex, defaultindex, itemlist);
            delete[] itemlist;
            return retval;
            break;
        }

        default:
            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (yres)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (yres));
            break;
    }
}


TW_UINT16 SaneDevice::GetYResolutionDefault (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_Y_RESOLUTION];
    if (!option) GetXResolutionDefault (capability);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap)) return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (72)));
}


TW_UINT16 SaneDevice::SetYResolution (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_SCAN_Y_RESOLUTION];
    if (!option) return TWRC_SUCCESS; // Just ignore it....

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_SETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word yres;

    if (capability) {
        if (capability->ConType != TWON_ONEVALUE) return datasource->SetStatus (TWCC_BADVALUE);
        if (optdesc->type == SANE_TYPE_INT)
            yres = SANE_FIX2INT (T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item))));
        else
            yres = T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item)));
    }
    else {
        if (optdesc->type == SANE_TYPE_INT)
            yres = 72;
        else
            yres = SANE_INT2FIX (72);
    }

    SANE_Int info;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE, &yres, &info);
    assert (status == SANE_STATUS_GOOD);
    return (info ? TWRC_CHECKSTATUS : TWRC_SUCCESS);
}


TW_UINT16 SaneDevice::GetPhysicalWidth (pTW_CAPABILITY capability) {

    int loption = optionIndex [SANE_NAME_SCAN_TL_X];
    int roption = optionIndex [SANE_NAME_SCAN_BR_X];
    if (!loption || !roption) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * loptdesc = sane_get_option_descriptor (GetSaneHandle (), loption);
    const SANE_Option_Descriptor * roptdesc = sane_get_option_descriptor (GetSaneHandle (), roption);

    if (!SANE_OPTION_IS_ACTIVE (loptdesc->cap) || !SANE_OPTION_IS_ACTIVE (roptdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (roptdesc->type != SANE_TYPE_INT && roptdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    double unitsPerInch;
    if (roptdesc->unit == SANE_UNIT_MM)
        unitsPerInch = 25.4;
    else
        unitsPerInch = 72.0;

    switch (roptdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            TW_FIX32 maxwidth;
            if (roptdesc->type == SANE_TYPE_INT)
                maxwidth = S2T (SANE_FIX ((roptdesc->constraint.range->max -
                                           loptdesc->constraint.range->min) / unitsPerInch));
            else
                maxwidth = S2T (lround ((roptdesc->constraint.range->max -
                                         loptdesc->constraint.range->min) / unitsPerInch));

            // Compensate for rounding errors...
            if ((maxwidth.Frac & 0x7FFF) + 0x0400 > 0x8000) {
                if (maxwidth.Frac < 0x8000)
                    maxwidth.Frac = 0x8000;
                else {
                    maxwidth.Whole++;
                    maxwidth.Frac = 0;
                }
            }

            return datasource->BuildOneValue (capability, TWTY_FIX32, maxwidth);
            break;
        }

        default:
            return datasource->SetStatus (TWCC_CAPUNSUPPORTED);
            break;
    }
}


TW_UINT16 SaneDevice::GetPhysicalHeight (pTW_CAPABILITY capability) {

    int toption = optionIndex [SANE_NAME_SCAN_TL_Y];
    int boption = optionIndex [SANE_NAME_SCAN_BR_Y];
    if (!toption || !boption) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * toptdesc = sane_get_option_descriptor (GetSaneHandle (), toption);
    const SANE_Option_Descriptor * boptdesc = sane_get_option_descriptor (GetSaneHandle (), boption);

    if (!SANE_OPTION_IS_ACTIVE (toptdesc->cap) || !SANE_OPTION_IS_ACTIVE (boptdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (boptdesc->type != SANE_TYPE_INT && boptdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    double unitsPerInch;
    if (boptdesc->unit == SANE_UNIT_MM)
        unitsPerInch = 25.4;
    else
        unitsPerInch = 72.0;

    switch (boptdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            TW_FIX32 maxheight;
            if (boptdesc->type == SANE_TYPE_INT)
                maxheight = S2T (SANE_FIX ((boptdesc->constraint.range->max -
                                            toptdesc->constraint.range->min) / unitsPerInch));
            else
                maxheight = S2T (lround ((boptdesc->constraint.range->max -
                                          toptdesc->constraint.range->min) / unitsPerInch));

            // Compensate for rounding errors...
            if ((maxheight.Frac & 0x7FFF) + 0x0400 > 0x8000) {
                if (maxheight.Frac < 0x8000)
                    maxheight.Frac = 0x8000;
                else {
                    maxheight.Whole++;
                    maxheight.Frac = 0;
                }
            }

            return datasource->BuildOneValue (capability, TWTY_FIX32, maxheight);
            break;
        }

        default:
            return datasource->SetStatus (TWCC_CAPUNSUPPORTED);
            break;
    }
}


TW_UINT16 SaneDevice::GetBrightness (pTW_CAPABILITY capability, bool onlyone) {

    int option = optionIndex [SANE_NAME_BRIGHTNESS];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word brightness;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE, &brightness, NULL);
    assert (status == SANE_STATUS_GOOD);

    if (onlyone) {
        if (optdesc->type == SANE_TYPE_INT)
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (brightness)));
        else
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (brightness));
    }

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->min)),
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->max)),
                                               S2T (SANE_INT2FIX (std::max (optdesc->constraint.range->quant, 1))),
                                               S2T (0),
                                               S2T (SANE_INT2FIX (brightness)));
            else
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (optdesc->constraint.range->min),
                                               S2T (optdesc->constraint.range->max),
                                               S2T (std::max (optdesc->constraint.range->quant, 1)),
                                               S2T (0),
                                               S2T (brightness));
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            pTW_FIX32 itemlist = new TW_FIX32 [optdesc->constraint.word_list [0]];
            TW_UINT32 currentindex = 0;
            TW_UINT32 defaultindex = 0;
            for (int i = 0; i < optdesc->constraint.word_list [0]; i++) {
                if (optdesc->type == SANE_TYPE_INT)
                    itemlist [i] = S2T (SANE_INT2FIX (optdesc->constraint.word_list [i + 1]));
                else
                    itemlist [i] = S2T (optdesc->constraint.word_list [i + 1]);
                if (optdesc->constraint.word_list [i + 1] == 0) defaultindex = i;
                if (optdesc->constraint.word_list [i + 1] == brightness) currentindex = i;
            }
            TW_UINT16 retval = datasource->BuildEnumeration (capability, TWTY_FIX32,
                                                             optdesc->constraint.word_list [0],
                                                             currentindex, defaultindex, itemlist);
            delete[] itemlist;
            return retval;
            break;
        }

        default:
            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (brightness)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (brightness));
            break;
    }
}


TW_UINT16 SaneDevice::GetBrightnessDefault (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_BRIGHTNESS];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap)) return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (0));
}


TW_UINT16 SaneDevice::SetBrightness (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_BRIGHTNESS];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_SETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word brightness;

    if (capability) {
        if (capability->ConType != TWON_ONEVALUE) return datasource->SetStatus (TWCC_BADVALUE);
        if (optdesc->type == SANE_TYPE_INT)
            brightness = SANE_FIX2INT (T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item))));
        else
            brightness = T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item)));
    }
    else
        brightness = 0;

    SANE_Int info;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE, &brightness, &info);
    assert (status == SANE_STATUS_GOOD);
    return (info ? TWRC_CHECKSTATUS : TWRC_SUCCESS);
}


TW_UINT16 SaneDevice::GetContrast (pTW_CAPABILITY capability, bool onlyone) {

    int option = optionIndex [SANE_NAME_CONTRAST];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_GETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word contrast;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_GET_VALUE, &contrast, NULL);
    assert (status == SANE_STATUS_GOOD);

    if (onlyone) {
        if (optdesc->type == SANE_TYPE_INT)
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (contrast)));
        else
            return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (contrast));
    }

    switch (optdesc->constraint_type) {

        case SANE_CONSTRAINT_RANGE: {

            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->min)),
                                               S2T (SANE_INT2FIX (optdesc->constraint.range->max)),
                                               S2T (SANE_INT2FIX (std::max (optdesc->constraint.range->quant, 1))),
                                               S2T (0),
                                               S2T (SANE_INT2FIX (contrast)));
            else
                return datasource->BuildRange (capability, TWTY_FIX32,
                                               S2T (optdesc->constraint.range->min),
                                               S2T (optdesc->constraint.range->max),
                                               S2T (std::max (optdesc->constraint.range->quant, 1)),
                                               S2T (0),
                                               S2T (contrast));
            break;
        }

        case SANE_CONSTRAINT_WORD_LIST: {

            pTW_FIX32 itemlist = new TW_FIX32 [optdesc->constraint.word_list [0]];
            TW_UINT32 currentindex = 0;
            TW_UINT32 defaultindex = 0;
            for (int i = 0; i < optdesc->constraint.word_list [0]; i++) {
                if (optdesc->type == SANE_TYPE_INT)
                    itemlist [i] = S2T (SANE_INT2FIX (optdesc->constraint.word_list [i + 1]));
                else
                    itemlist [i] = S2T (optdesc->constraint.word_list [i + 1]);
                if (optdesc->constraint.word_list [i + 1] == 0) defaultindex = i;
                if (optdesc->constraint.word_list [i + 1] == contrast) currentindex = i;
            }
            TW_UINT16 retval = datasource->BuildEnumeration (capability, TWTY_FIX32,
                                                             optdesc->constraint.word_list [0],
                                                             currentindex, defaultindex, itemlist);
            delete[] itemlist;
            return retval;
            break;
        }

        default:
            if (optdesc->type == SANE_TYPE_INT)
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (SANE_INT2FIX (contrast)));
            else
                return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (contrast));
            break;
    }
}


TW_UINT16 SaneDevice::GetContrastDefault (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_CONTRAST];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap)) return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    return datasource->BuildOneValue (capability, TWTY_FIX32, S2T (0));
}


TW_UINT16 SaneDevice::SetContrast (pTW_CAPABILITY capability) {

    int option = optionIndex [SANE_NAME_CONTRAST];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (!SANE_OPTION_IS_ACTIVE (optdesc->cap) || !SANE_OPTION_IS_SETTABLE (optdesc->cap))
        return datasource->SetStatus (TWCC_CAPSEQERROR);

    if (optdesc->type != SANE_TYPE_INT && optdesc->type != SANE_TYPE_FIXED)
        return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    SANE_Word contrast;

    if (capability) {
        if (capability->ConType != TWON_ONEVALUE) return datasource->SetStatus (TWCC_BADVALUE);
        if (optdesc->type == SANE_TYPE_INT)
            contrast = SANE_FIX2INT (T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item))));
        else
            contrast = T2S (*((TW_FIX32*) &(((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item)));
    }
    else
        contrast = 0;

    SANE_Int info;
    SANE_Status status = sane_control_option (GetSaneHandle (), option, SANE_ACTION_SET_VALUE, &contrast, &info);
    assert (status == SANE_STATUS_GOOD);
    return (info ? TWRC_CHECKSTATUS : TWRC_SUCCESS);
}


TW_UINT16 SaneDevice::GetLayout (pTW_IMAGELAYOUT imagelayout) {

    SANE_Rect bounds;

    GetRect (&bounds);

    double unitsPerInch;
    if (bounds.unit == SANE_UNIT_MM)
        unitsPerInch = 25.4;
    else
        unitsPerInch = 72.0;

    if (bounds.type == SANE_TYPE_INT) {
        imagelayout->Frame.Top    = S2T (SANE_FIX (bounds.top    / unitsPerInch));
        imagelayout->Frame.Left   = S2T (SANE_FIX (bounds.left   / unitsPerInch));
        imagelayout->Frame.Bottom = S2T (SANE_FIX (bounds.bottom / unitsPerInch));
        imagelayout->Frame.Right  = S2T (SANE_FIX (bounds.right  / unitsPerInch));
    }
    else {
        imagelayout->Frame.Top    = S2T (lround (bounds.top    / unitsPerInch));
        imagelayout->Frame.Left   = S2T (lround (bounds.left   / unitsPerInch));
        imagelayout->Frame.Bottom = S2T (lround (bounds.bottom / unitsPerInch));
        imagelayout->Frame.Right  = S2T (lround (bounds.right  / unitsPerInch));
    }

    imagelayout->DocumentNumber = 1;
    imagelayout->PageNumber = 1;
    imagelayout->FrameNumber = 1;

    return TWRC_SUCCESS;
}


TW_UINT16 SaneDevice::SetLayout (pTW_IMAGELAYOUT imagelayout) {

    SANE_Rect bounds;

    int option = optionIndex [SANE_NAME_SCAN_TL_Y];
    if (!option) return datasource->SetStatus (TWCC_CAPUNSUPPORTED);

    bounds.type = sane_get_option_descriptor (GetSaneHandle (), option)->type;
    bounds.unit = sane_get_option_descriptor (GetSaneHandle (), option)->unit;

    double unitsPerInch;
    if (bounds.unit == SANE_UNIT_MM)
        unitsPerInch = 25.4;
    else
        unitsPerInch = 72.0;

    if (bounds.type == SANE_TYPE_INT) {
        bounds.top    = lround (SANE_UNFIX (T2S (imagelayout->Frame.Top))    * unitsPerInch);
        bounds.left   = lround (SANE_UNFIX (T2S (imagelayout->Frame.Left))   * unitsPerInch);
        bounds.bottom = lround (SANE_UNFIX (T2S (imagelayout->Frame.Bottom)) * unitsPerInch);
        bounds.right  = lround (SANE_UNFIX (T2S (imagelayout->Frame.Right))  * unitsPerInch);
    }
    else {
        bounds.top    = lround (T2S (imagelayout->Frame.Top)    * unitsPerInch);
        bounds.left   = lround (T2S (imagelayout->Frame.Left)   * unitsPerInch);
        bounds.bottom = lround (T2S (imagelayout->Frame.Bottom) * unitsPerInch);
        bounds.right  = lround (T2S (imagelayout->Frame.Right)  * unitsPerInch);
    }

    SetRect (&bounds);

    return TWRC_SUCCESS;
}


Image * SaneDevice::Scan (bool queue, bool indicators) {

    Image * scanImage = new Image;

    SANE_Status status;
    OSStatus osstat;
    OSErr oserr;

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME);

    GetRect (&scanImage->bounds);
    GetResolution (&scanImage->res);

    Buffer dataBuffer;

    bool cancelled = false;
    for (int iframe = 0; ; iframe++) {

        status = sane_start (GetSaneHandle ());

        if (status != SANE_STATUS_GOOD) {
            if (HasUI()) SaneError (status);
            cancelled = true;
            break;
        }

        status = sane_get_parameters (GetSaneHandle (), &scanImage->param);

        if (status != SANE_STATUS_GOOD) {
            if (HasUI()) SaneError (status);
            cancelled = true;
            break;
        }

        scanImage->frame [scanImage->param.format] = iframe;

        if (iframe == 0) {
            // If we don't know the height, allocate memory for 12 inches
            int lines;
            if (scanImage->param.lines > 0)
                lines = scanImage->param.lines;
            else if (scanImage->res.type == SANE_TYPE_INT)
                lines = 12 * scanImage->res.v;
            else
                lines = lround (ceil (SANE_UNFIX (12 * scanImage->res.v)));

            // Add one extra line so we don't trigger a resizing of the handle
            if (scanImage->param.format == SANE_FRAME_GRAY ||
                scanImage->param.format == SANE_FRAME_RGB)
                dataBuffer.SetSize ((lines + 1) * scanImage->param.bytes_per_line);
            else
                dataBuffer.SetSize ((lines + 1) * scanImage->param.bytes_per_line * 3);
        }

        WindowRef window = NULL;

        if (HasUI() || indicators) {

            Rect windowrect = { 0, 0, 100, 300 };

            if (HasUI()) {
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

                CFStringRef text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, kCFBundleNameKey);
                osstat = SetWindowTitleWithCFString (window, text);
                assert (osstat == noErr);
            }

            ControlRef rootcontrol;
            oserr = GetRootControl (window, &rootcontrol);
            assert (oserr == noErr);

            Rect controlrect;

            controlrect.top = 20;
            controlrect.left = 20;
            controlrect.right = windowrect.right - windowrect.left - 20;

            CFStringRef text = CFBundleCopyLocalizedString (bundle, CFSTR ("Scanning Image..."), NULL, NULL);
            MakeStaticTextControl (rootcontrol, &controlrect, text, teFlushLeft, false);
            CFRelease (text);

            controlrect.top = controlrect.bottom + 20;
            controlrect.bottom = controlrect.top + 16;

            ControlRef progressControl;
            osstat = CreateProgressBarControl (NULL, &controlrect, 0, 0, 0, true, &progressControl);
            assert (osstat == noErr);

            oserr = EmbedControl (progressControl, rootcontrol);
            assert (oserr == noErr);

            windowrect.bottom = controlrect.bottom + 20;

            osstat = SetWindowBounds (window, kWindowContentRgn, &windowrect);
            assert (osstat == noErr);

            if (HasUI()) {
                userinterface->ShowSheetWindow (window);
            }
            else {
                osstat = RepositionWindow (window, NULL, kWindowAlertPositionOnMainScreen);
                assert (osstat == noErr);

                ShowWindow (window);
            }
        }

        while (status == SANE_STATUS_GOOD) {
            Size maxlength = dataBuffer.CheckSize ();
            Ptr p = dataBuffer.GetPtr ();
            assert (p);
            SANE_Int length;
            status = sane_read (GetSaneHandle (), (SANE_Byte *) p, maxlength, &length);
            dataBuffer.ReleasePtr (length);
        }

        if (window) {

            if (HasUI())
                HideSheetWindow (window);
            else
                HideWindow (window);

            DisposeWindow (window);
        }

        if (status != SANE_STATUS_GOOD && status != SANE_STATUS_EOF) {
            if (HasUI()) SaneError (status);
            cancelled = true;
            break;
        }

        if (scanImage->param.last_frame) break;
    }

    sane_cancel (GetSaneHandle ());

    if (cancelled) return NULL;

    scanImage->imagedata = dataBuffer.Claim ();
    assert (scanImage->imagedata);

    int lines = GetHandleSize (scanImage->imagedata) / scanImage->param.bytes_per_line;
    if (scanImage->param.format != SANE_FRAME_GRAY &&
        scanImage->param.format != SANE_FRAME_RGB) lines /= 3;

    if (scanImage->param.lines < 0) scanImage->param.lines = lines;

    if (queue) {
        if (image) delete image;
        image = scanImage;
    }

    return scanImage;
}


void SaneDevice::SetPreview (SANE_Bool preview) {

    int option = optionIndex [SANE_NAME_PREVIEW];
    if (!option) return;

    const SANE_Option_Descriptor * optdesc = sane_get_option_descriptor (GetSaneHandle (), option);

    if (optdesc && optdesc->type == SANE_TYPE_BOOL &&
        SANE_OPTION_IS_ACTIVE (optdesc->cap) && SANE_OPTION_IS_SETTABLE (optdesc->cap)) {
        SANE_Status status = sane_control_option (GetSaneHandle (), option,
                                                  SANE_ACTION_SET_VALUE, &preview, NULL);
        assert (status == SANE_STATUS_GOOD);
    }
}


Image * SaneDevice::GetImage () {

    return image;
}


void SaneDevice::DequeueImage () {

    if (image) delete image;
    image = NULL;
}


const SANE_Handle SaneDevice::GetSaneHandle () {

    if (sanehandles.find (currentDevice) == sanehandles.end ()) return NULL;
    return sanehandles [currentDevice];
}


const SANE_Int SaneDevice::GetSaneVersion () {

    return saneversion;
}


void SaneDevice::GetAreaOptions (int * top, int * left, int * bottom, int * right) {

    if (top)    *top    = optionIndex [SANE_NAME_SCAN_TL_Y];
    if (left)   *left   = optionIndex [SANE_NAME_SCAN_TL_X];
    if (bottom) *bottom = optionIndex [SANE_NAME_SCAN_BR_Y];
    if (right)  *right  = optionIndex [SANE_NAME_SCAN_BR_X];
}
