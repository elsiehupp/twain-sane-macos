import Algorithm
import Buffer
import CStdLib
import CoreFoundation
import DataSource
import Image
import LibIntl
import MakeControls
import Map
import Sane
import Sane.Saneopts
import SaneDevice
import SaneCallback
import Twain
import UserInterface

func S2T(s: Sane.Fixed) -> TW_FIX32 {

    var t: TW_FIX32
    t.Whole = s >> 16
    t.Frac = s & 0xFFFF
    return t
}

func T2S(t: TW_FIX32) -> Sane.Fixed {

    return(t.Whole << 16) + t.Frac
}

struct Rect {
    var top: Sane.Word
    var left: Sane.Word
    var bottom: Sane.Word
    var right: Sane.Word
    var type: Sane.Value_Type
    var unit: Sane.Unit
}

struct Resolution {
    var h: Sane.Word
    var v: Sane.Word
    var type: Sane.Value_Type
}


func OPTION_IS_GETTABLE(cap: any) {
    return((cap) & Sane.CAP_SOFT_DETECT) != 0
}

func FIX2INT(v: any) {
    return((v) + 0x8000) >> Sane.FIXED_SCALE_SHIFT
}
func INT2FIX(v: any) {
    return(v) << Sane.FIXED_SCALE_SHIFT
}

// #ifdef FIX
// #undef FIX

func FIX(v: any) {
    (lround((v) * (1 << Sane.FIXED_SCALE_SHIFT)))
}


class SaneDevice {

    private var devicelist: Sane.Device
    private var saneversion: Int
    private var currentDevice: Int
    private var sanehandles: map <Int, Sane.Handle>
    private var optionIndex: map <std.string, Int>

    private var datasource: DataSource
    private var userinterface: UserInterface
    private var image: Image


    func Sane.constrain_value(opt: Sane.Option_Descriptor, value: any, info: Sane.Word) -> Sane.Status

    let commandProcessEvent: EventTypeSpec = [ kEventClassCommand, kEventCommandProcess ]


    static func AlertEventHandler(inHandlerCallRef: EventHandlerCallRef, inEvent: EventRef,
                                    inUserData: any) -> OSStatus {

        var osstat: OSStatus

        var cmd: HICommandExtended
        osstat = GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, nil,
                                    sizeof(HICommandExtended), nil, &cmd)
        assert(osstat == noErr)

        switch(cmd.commandID) {
            case kHICommandOK:
                osstat = QuitAppModalLoopForWindow(WindowRef(inUserData))
                assert(osstat == noErr)
                return noErr
                break
            default:
                return eventNotHandledErr
                break
        }
    }


    public func SaneDevice(ds: DataSource) {
        currentDevice(-1)
        datasource(ds)
        userinterface(nil)
        image(nil)

        var status: Sane.Status

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        let sanelocalization: String =
            CFBundleCopyLocalizedString(bundle, CFSTR("sane-localization"), nil, nil)
        var locale: String
        CFStringGetCString(sanelocalization, locale, 16, kCFStringEncodingUTF8)
        CFRelease(sanelocalization)
        setenv("LANG", locale, 1)

        let SANELocaleDir: String =
            String(CFBundleGetValueForInfoDictionaryKey(bundle, CFSTR("SANELocaleDir")))
        var localedir: String
        CFStringGetCString(SANELocaleDir, localedir, 64, kCFStringEncodingUTF8)
        bindtextdomain("sane-backends", localedir)
        bind_textdomain_codeset("sane-backends", "UTF-8")

        status = Sane.init(&saneversion, SaneAuthCallback)
        assert(status == Sane.STATUS_GOOD)

        status = Sane.get_devices(&devicelist, false)
        assert(status == Sane.STATUS_GOOD)

        if(!devicelist || !(*devicelist)) {
            return
        }

        var firstDevice: Int = -1
        var deviceString: String =
            String(CFPreferencesCopyAppValue(CFSTR("Current Device"), BNDLNAME))
        if(deviceString) {
            if(CFGetTypeID(deviceString) == CFStringGetTypeID()) {
                for device in devicelist {
                    var deviceListString: String = CreateName(device)
                    if(CFStringCompare(deviceString, deviceListString,
                                        kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        firstDevice = device
                    }
                    CFRelease(deviceListString)
                    if firstDevice != -1 {
                        break
                    }
                }
            }
            CFRelease(deviceString)
        }
        if(firstDevice == -1) {
            firstDevice = 0
        }
        var newDevice: Int = ChangeDevice(firstDevice)
        for device in devicelist {
            if(device == firstDevice) {
                continue
            }
            newDevice = ChangeDevice(device)
            if newDevice != -1 {
                break
            }
        }
    }


    // public func ~SaneDevice() {

    //     HideUI()
    //     DequeueImage()

    //     if(currentDevice != -1) {
    //         String deviceString = CreateName()
    //         CFPreferencesSetAppValue(CFSTR("Current Device"), deviceString, BNDLNAME)
    //         CFRelease(deviceString)
    //     }

    //     for(std.map <Int, Sane.Handle>.iterator svsh = sanehandles.begin()
    //         svsh != sanehandles.end(); svsh++) {

    //         currentDevice = svsh.first

    //         String deviceString = CreateName()
    //         String deviceKey =
    //             CFStringCreateWithFormat(nil, nil, CFSTR("Device %@"), deviceString)
    //         CFRelease(deviceString)
    //         CFDictionaryRef optionDictionary = CreateOptionDictionary()
    //         CFPreferencesSetAppValue(deviceKey, optionDictionary, BNDLNAME)
    //         CFRelease(deviceKey)
    //         CFRelease(optionDictionary)

    //         Sane.close(GetSaneHandle())
    //     }

    //     Sane.exit()

    //     CFPreferencesAppSynchronize(BNDLNAME)
    // }



    public func CallBack(MSG: TW_UINT16) {

        datasource.CallBack(MSG)
    }



    public func CreateName(device: Int = -1) -> String {

        if(device == -1) {
            device = currentDevice
        }

        if(!devicelist[device]) {
            return nil
        }

        let constvendor: String = CFStringCreateWithCString(nil, devicelist[device].vendor, kCFStringEncodingUTF8)
        var vendor: CFMutableStringRef = CFStringCreateMutableCopy(nil, 0, constvendor)
        CFRelease(constvendor)
        CFStringTrimWhitespace(vendor)

        let constmodel: String = CFStringCreateWithCString(nil, devicelist[device].model, kCFStringEncodingUTF8)
        var model: CFMutableStringRef = CFStringCreateMutableCopy(nil, 0, constmodel)
        CFRelease(constmodel)
        CFStringTrimWhitespace(model)

        var backend: String = String(devicelist[device].name)
        var end: String = strchr(backend, ":")
        if(strncmp(backend, "net:", 4) == 0) {
            // IPv6 addresses should be between brackets
            if(*(end + 1) == "[") {
                end = strchr(end + 1, "]")
            }
            if(end) {
                end = strchr(end + 1, ":")
            }
            if(end) {
                backend = end + 1
            }
            if(end) {
                end = strchr(end + 1, ":")
            }
        }
        if(end && strncmp(backend, "test:", 5) == 0) {
            end = strchr(end + 1, ":")
        }
        let len: Int = (end ? end - devicelist[device].name : strlen(devicelist[device].name))

        let n: String = String[len + 1]
        strncpy(n, devicelist[device].name, len)
        n[len] = "\0"
        let name: String = CFStringCreateWithCString(nil, n, kCFStringEncodingUTF8)
        // delete[] n

        let text: String = CFStringCreateWithFormat(nil, nil, CFSTR("%@ %@ (%@)"), vendor, model, name)

        CFRelease(name)
        CFRelease(vendor)
        CFRelease(model)

        return text
    }


    public func ChangeDevice(device: Int) -> Int {

        var status: Sane.Status

        let oldDevice: Int = currentDevice
        currentDevice = device

        if(!GetSaneHandle()) {
            var sanehandle: Sane.Handle

            var result: UInt32
            do {
                SaneCallbackDevice(this)
                status = Sane.open(devicelist[currentDevice].name, &sanehandle)
                result = SaneCallbackResult()
            }
            while(status != Sane.STATUS_GOOD && result == kHICommandOK)

            if(status != Sane.STATUS_GOOD) {
                if(HasUI()) {
                    OpenDeviceFailed()
                }
                currentDevice = oldDevice
                return currentDevice
            }

            assert(status == Sane.STATUS_GOOD)
            assert(sanehandle)
            sanehandles[currentDevice] = sanehandle

            let deviceString: String = CreateName()
            let deviceKey: String =
                CFStringCreateWithFormat(nil, nil, CFSTR("Device %@"), deviceString)
            CFRelease(deviceString)
            let optionDictionary: CFDictionaryRef =
                CFDictionaryRef(CFPreferencesCopyAppValue(deviceKey, BNDLNAME))
            CFRelease(deviceKey)
            if(optionDictionary) {
                if(CFGetTypeID(optionDictionary) == CFDictionaryGetTypeID()) {
                    ApplyOptionDictionary(optionDictionary)
                }
                CFRelease(optionDictionary)
            }
        }

        optionIndex.clear()

        var option: Int = 1
        var optdesc: Sane.Option_Descriptor
        while(optdesc = Sane.get_option_descriptor(GetSaneHandle(), option)) {
            if(optdesc.type != Sane.TYPE_GROUP) {
                optionIndex[optdesc.name] = option
            }
            option++
        }

        return currentDevice
    }


    public func ShowUI(uionly: Bool) {

        userinterface = UserInterface(this, currentDevice, uionly)
    }


    public func HideUI() {

        if(userinterface) {
            delete(userinterface)
        }
        userinterface = nil
    }


    public func HasUI() -> Bool {

        return(userinterface != nil)
    }


    public func ShowSheetWindow(window: WindowRef) {

        if(userinterface) {
            userinterface.ShowSheetWindow(window)
        }
    }


    public func OpenDeviceFailed() {

        var osstat: OSStatus
        var oserr: OSErr

        var text: String

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(CFSTR("se.ellert.twain-sane"))

        var windowrect: Rect = [ 0, 0, 100, 500 ]
        var window: WindowRef

        if(HasUI()) {
            osstat = CreateNewWindow(kSheetWindowClass,
                                    kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                    &windowrect, &window)
            assert(osstat == noErr)

            osstat = SetThemeWindowBackground(window, kThemeBrushSheetBackgroundOpaque, true)
            assert(osstat == noErr)
        } else {
            osstat = CreateNewWindow(kMovableModalWindowClass,
                                    kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                    &windowrect, &window)
            assert(osstat == noErr)

            osstat = SetThemeWindowBackground(window, kThemeBrushMovableModalBackground, true)
            assert(osstat == noErr)

            text = String(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey))
            osstat = SetWindowTitleWithCFString(window, text)
            assert(osstat == noErr)
        }

        var rootcontrol: ControlRef
        oserr = GetRootControl(window, &rootcontrol)
        assert(oserr == noErr)

        var controlrect: Rect

        controlrect.top = 20
        controlrect.left = 20
        controlrect.bottom = controlrect.top + 64
        controlrect.right = controlrect.left + 64

        var icon: IconRef
        var contentinfo: ControlButtonContentInfo
        var iconcontrol: ControlRef

        oserr = GetIconRef(kOnSystemDisk, kSystemIconsCreator, kAlertStopIcon, &icon)
        assert(oserr == noErr)

        contentinfo.contentType = kControlContentIconRef
        contentinfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentinfo, true, &iconcontrol)
        assert(osstat == noErr)

        oserr = EmbedControl(iconcontrol, rootcontrol)
        assert(oserr == noErr)

        controlrect.top += 32
        controlrect.left += 32

        oserr = GetIconRef(kOnSystemDisk, "SANE", "APPL", &icon)
        assert(oserr == noErr)

        contentinfo.contentType = kControlContentIconRef
        contentinfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentinfo, true, &iconcontrol)
        assert(osstat == noErr)

        oserr = EmbedControl(iconcontrol, rootcontrol)
        assert(oserr == noErr)

        let bottom: Int = controlrect.bottom

        controlrect.top = 20
        controlrect.left = controlrect.right + 20
        controlrect.right = windowrect.right - windowrect.left - 20

        let dev: String = CreateName()
        let format: String =
            CFBundleCopyLocalizedString(bundle, CFSTR("Could not open the image source %@"), nil, nil)
        text = CFStringCreateWithFormat(nil, nil, format, dev)
        CFRelease(format)
        CFRelease(dev)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
        CFRelease(text)

        controlrect.top = std.max(controlrect.bottom + 20, bottom - 20)

        text = CFBundleCopyLocalizedString(bundle, CFSTR("OK"), nil, nil)
        MakeButtonControl(rootcontrol, &controlrect, text, kHICommandOK, true, nil, 0)
        CFRelease(text)

        windowrect.bottom = controlrect.bottom + 20

        osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
        assert(osstat == noErr)

        osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
        assert(osstat == noErr)

        let AlertEventHandlerUPP: EventHandlerUPP = NewEventHandlerUPP(AlertEventHandler)
        osstat = InstallWindowEventHandler(window, AlertEventHandlerUPP,
                                            GetEventTypeCount(commandProcessEvent), commandProcessEvent,
                                            window, nil)
        assert(osstat == noErr)

        if(HasUI()) {
            ShowSheetWindow(window)
        } else {
            osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
            assert(osstat == noErr)

            ShowWindow(window)
        }

        osstat = RunAppModalLoopForWindow(window)
        assert(osstat == noErr)

        if(HasUI()) {
            HideSheetWindow(window)
        } else {
            HideWindow(window)
        }

        DisposeEventHandlerUPP(AlertEventHandlerUPP)

        DisposeWindow(window)
    }


    public func SaneError(status: Sane.Status) {

        var osstat: OSStatus
        var oserr: OSErr

        var text: String

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(CFSTR("se.ellert.twain-sane"))

        var windowrect: Rect = [ 0, 0, 100, 500 ]
        var window: WindowRef

        if(HasUI()) {
            osstat = CreateNewWindow(kSheetWindowClass,
                                    kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                    &windowrect, &window)
            assert(osstat == noErr)

            osstat = SetThemeWindowBackground(window, kThemeBrushSheetBackgroundOpaque, true)
            assert(osstat == noErr)
        } else {
            osstat = CreateNewWindow(kMovableModalWindowClass,
                                    kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                    &windowrect, &window)
            assert(osstat == noErr)

            osstat = SetThemeWindowBackground(window, kThemeBrushMovableModalBackground, true)
            assert(osstat == noErr)

            text = String(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey))
            osstat = SetWindowTitleWithCFString(window, text)
            assert(osstat == noErr)
        }

        var rootcontrol: ControlRef
        oserr = GetRootControl(window, &rootcontrol)
        assert(oserr == noErr)

        var controlrect: Rect

        controlrect.top = 20
        controlrect.left = 20
        controlrect.bottom = controlrect.top + 64
        controlrect.right = controlrect.left + 64

        var icon: IconRef
        var contentinfo: ControlButtonContentInfo
        var iconcontrol: ControlRef

        oserr = GetIconRef(kOnSystemDisk, kSystemIconsCreator, kAlertStopIcon, &icon)
        assert(oserr == noErr)

        contentinfo.contentType = kControlContentIconRef
        contentinfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentinfo, true, &iconcontrol)
        assert(osstat == noErr)

        oserr = EmbedControl(iconcontrol, rootcontrol)
        assert(oserr == noErr)

        controlrect.top += 32
        controlrect.left += 32

        oserr = GetIconRef(kOnSystemDisk, "SANE", "APPL", &icon)
        assert(oserr == noErr)

        contentinfo.contentType = kControlContentIconRef
        contentinfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentinfo, true, &iconcontrol)
        assert(osstat == noErr)

        oserr = EmbedControl(iconcontrol, rootcontrol)
        assert(oserr == noErr)

        let bottom: Int = controlrect.bottom

        controlrect.top = 20
        controlrect.left = controlrect.right + 20
        controlrect.right = windowrect.right - windowrect.left - 20

        text = CFStringCreateWithCString(nil, Sane.strstatus(status), kCFStringEncodingUTF8)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
        CFRelease(text)

        controlrect.top = std.max(controlrect.bottom + 20, bottom - 20)

        text = CFBundleCopyLocalizedString(bundle, CFSTR("OK"), nil, nil)
        MakeButtonControl(rootcontrol, &controlrect, text, kHICommandOK, true, nil, 0)
        CFRelease(text)

        windowrect.bottom = controlrect.bottom + 20

        osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
        assert(osstat == noErr)

        osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
        assert(osstat == noErr)

        let AlertEventHandlerUPP: EventHandlerUPP = NewEventHandlerUPP(AlertEventHandler)
        osstat = InstallWindowEventHandler(window, AlertEventHandlerUPP,
                                            GetEventTypeCount(commandProcessEvent), commandProcessEvent,
                                            window, nil)
        assert(osstat == noErr)

        if(HasUI()) {
            ShowSheetWindow(window)
        } else {
            osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
            assert(osstat == noErr)

            ShowWindow(window)
        }

        osstat = RunAppModalLoopForWindow(window)
        assert(osstat == noErr)

        if(HasUI()) {
            HideSheetWindow(window)
        } else {
            HideWindow(window)
        }

        DisposeEventHandlerUPP(AlertEventHandlerUPP)

        DisposeWindow(window)
    }



    public func GetCustomData(customdata: pTW_CUSTOMDSDATA) -> TW_UINT16 {

        var dataDictionary: CFMutableDictionaryRef =
            CFDictionaryCreateMutable(nil, 0, &kCFTypeDictionaryKeyCallBacks,
                                    &kCFTypeDictionaryValueCallBacks)
        let deviceString: String = CreateName()
        CFDictionaryAddValue(dataDictionary, CFSTR("Current Device"), deviceString)
        let deviceKey: String = CFStringCreateWithFormat(nil, nil, CFSTR("Device %@"), deviceString)
        CFRelease(deviceString)
        var optionDictionary: CFDictionaryRef = CreateOptionDictionary()
        CFDictionaryAddValue(dataDictionary, deviceKey, optionDictionary)
        CFRelease(deviceKey)
        CFRelease(optionDictionary)

        var xml: CFDataRef = CFPropertyListCreateXMLData(nil, dataDictionary)
        CFRelease(dataDictionary)

        customdata.InfoLength = CFDataGetLength(xml)
        customdata.hData = TW_HANDLE(NewHandle(customdata.InfoLength))
        HLock(Handle(customdata.hData))
        CFDataGetBytes(xml, CFRangeMake(0, customdata.InfoLength), UInt8(Handle(customdata.hData)))
        HUnlock(Handle(customdata.hData))

        CFRelease(xml)

        return TWRC_SUCCESS
    }


    public func SetCustomData(customdata: pTW_CUSTOMDSDATA) -> TW_UINT16 {

        var done: Bool = false

        HLock(Handle(customdata.hData))
        var xml: CFDataRef = CFDataCreate(nil, Handle(customdata.hData), customdata.InfoLength)
        HUnlock(Handle(customdata.hData))
        var dataDictionary: CFDictionaryRef =
            CFDictionaryRef(CFPropertyListCreateFromXMLData(nil, xml, kCFPropertyListImmutable, nil))
        CFRelease(xml)

        if(dataDictionary) {
            if(CFGetTypeID(dataDictionary) == CFDictionaryGetTypeID()) {
                var deviceString: String =
                    String(CFDictionaryGetValue(dataDictionary, CFSTR("Current Device")))
                if(deviceString && CFGetTypeID(deviceString) == CFStringGetTypeID()) {
                    for device in devicelist {
                        var deviceListString: String = CreateName(device)
                        if(CFStringCompare(deviceString, deviceListString,
                                            kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                            if(ChangeDevice(device) == device) {
                                let deviceKey: String =
                                    CFStringCreateWithFormat(nil, nil, CFSTR("Device %@"), deviceString)
                                let optionDictictionary: CFDictionaryRef =
                                    CFDictionaryRef(CFDictionaryGetValue(dataDictionary, deviceKey))
                                CFRelease(deviceKey)
                                if(optionDictictionary &&
                                    CFGetTypeID(optionDictictionary) == CFDictionaryGetTypeID()) {
                                    ApplyOptionDictionary(optionDictictionary)
                                    done = true
                                }
                            }
                        }
                        CFRelease(deviceListString)
                    }
                }
            }
            CFRelease(dataDictionary)
        }

        return(done ? TWRC_SUCCESS : datasource.SetStatus(TWCC_OPERATIONERROR))
    }


    private func CreateOptionDictionary() -> CFDictionaryRef {

        var status: Sane.Status

        var dict: CFMutableDictionaryRef =
            CFDictionaryCreateMutable(nil, 0, &kCFTypeDictionaryKeyCallBacks,
                                    &kCFTypeDictionaryValueCallBacks)

        var option: Int = 1
        var optdesc: Sane.Option_Descriptor
        while optdesc = Sane.get_option_descriptor(GetSaneHandle(), option) {

            if(optdesc.type != Sane.TYPE_GROUP &&
                Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {

                let key: String = CFStringCreateWithCString(nil, optdesc.name, kCFStringEncodingUTF8)

                switch(optdesc.type) {

                    case Sane.TYPE_BOOL:

                        let optval: Bool
                        status = Sane.control_option(GetSaneHandle(), option,
                                                    Sane.ACTION_GET_VALUE, &optval, nil)
                        assert(status == Sane.STATUS_GOOD)
                        CFDictionaryAddValue(dict, key, (optval ? kCFBooleanTrue : kCFBooleanFalse))

                    case Sane.TYPE_INT:

                        if(optdesc.size > sizeof(Sane.Word)) {
                            Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                            status = Sane.control_option(GetSaneHandle(), option,
                                                        Sane.ACTION_GET_VALUE, optval, nil)
                            assert(status == Sane.STATUS_GOOD)
                            let cfarray: CFMutableArrayRef =
                                CFArrayCreateMutable(nil, 0, &kCFTypeArrayCallBacks)
                            for i in optdesc.size / sizeof(Sane.Word) {
                                let cfvalue: CFNumberRef =
                                    CFNumberCreate(nil, kCFNumberIntType, &optval[i])
                                CFArrayAppendValue(cfarray, cfvalue)
                                CFRelease(cfvalue)
                            }
                            // delete[] optval
                            CFDictionaryAddValue(dict, key, cfarray)
                            CFRelease(cfarray)
                        }
                        else {
                            let optval: Sane.Word
                            status = Sane.control_option(GetSaneHandle(), option,
                                                        Sane.ACTION_GET_VALUE, &optval, nil)
                            assert(status == Sane.STATUS_GOOD)
                            let cfvalue: CFNumberRef = CFNumberCreate(nil, kCFNumberIntType, &optval)
                            CFDictionaryAddValue(dict, key, cfvalue)
                            CFRelease(cfvalue)
                        }

                    case Sane.TYPE_FIXED:

                        if(optdesc.size > sizeof(Sane.Word)) {
                            Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                            status = Sane.control_option(GetSaneHandle(), option,
                                                        Sane.ACTION_GET_VALUE, optval, nil)
                            assert(status == Sane.STATUS_GOOD)
                            let cfarray: CFMutableArrayRef =
                                CFArrayCreateMutable(nil, 0, &kCFTypeArrayCallBacks)
                            for i in optdesc.size / sizeof(Sane.Word) {
                                let val: Float = Sane.UNFIX(optval[i])
                                let cfvalue: CFNumberRef = CFNumberCreate(nil, kCFNumberDoubleType, &val)
                                CFArrayAppendValue(cfarray, cfvalue)
                                CFRelease(cfvalue)
                            }
                            // delete[] optval
                            CFDictionaryAddValue(dict, key, cfarray)
                            CFRelease(cfarray)
                        }
                        else {
                            var optval: Sane.Word
                            status = Sane.control_option(GetSaneHandle(), option,
                                                        Sane.ACTION_GET_VALUE, &optval, nil)
                            assert(status == Sane.STATUS_GOOD)
                            let val: Float = Sane.UNFIX(optval)
                            let cfvalue: FNumberRef = CFNumberCreate(nil, kCFNumberDoubleType, &val)
                            CFDictionaryAddValue(dict, key, cfvalue)
                            CFRelease(cfvalue)
                        }

                    case Sane.TYPE_STRING: {

                        let optval: String = String[optdesc.size]
                        status = Sane.control_option(GetSaneHandle(), option,
                                                    Sane.ACTION_GET_VALUE, optval, nil)
                        assert(status == Sane.STATUS_GOOD)
                        let cfvalue: String = CFStringCreateWithCString(nil, optval,
                                                                        kCFStringEncodingUTF8)
                        // delete[] optval
                        CFDictionaryAddValue(dict, key, cfvalue)
                        CFRelease(cfvalue)
                    }

                    default:
                        break
                }

                CFRelease(key)
            }
            option++
        }

        return dict
    }



    private func ApplyOptionDictionary(optionDictionary: CFDictionaryRef) {

        var status: Sane.Status

        var option: Int = 1
        var optdesc: Sane.Option_Descriptor
        while optdesc = Sane.get_option_descriptor(GetSaneHandle(), option) {

            if(optdesc.type != Sane.TYPE_GROUP &&
                Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {

                let key: String = CFStringCreateWithCString(nil, optdesc.name, kCFStringEncodingUTF8)

                switch(optdesc.type) {

                    case Sane.TYPE_BOOL: {

                        let cfvalue: CFBooleanRef = CFBooleanRef(CFDictionaryGetValue(dict, key))
                        if(cfvalue && CFGetTypeID(cfvalue) == CFBooleanGetTypeID()) {
                            let optval: Bool = CFBooleanGetValue(cfvalue)
                            status = Sane.control_option(GetSaneHandle(), option,
                                                        Sane.ACTION_SET_VALUE, &optval, nil)
                            assert(status == Sane.STATUS_GOOD)
                        }
                        break
                    }

                    case Sane.TYPE_INT:

                        if(optdesc.size > sizeof(Sane.Word)) {
                            let cfarray: CFArrayRef = CFArrayRef(CFDictionaryGetValue(dict, key))
                            if(cfarray && CFGetTypeID(cfarray) == CFArrayGetTypeID() &&
                                CFArrayGetCount(cfarray) == optdesc.size / sizeof(Sane.Word)) {
                                Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                                status = Sane.control_option(GetSaneHandle(), option,
                                                            Sane.ACTION_GET_VALUE, optval, nil)
                                assert(status == Sane.STATUS_GOOD)
                                for i in optdesc.size / sizeof(Sane.Word) {
                                    let cfvalue: CFNumberRef =
                                        CFNumberRef(CFArrayGetValueAtIndex(cfarray, i))
                                    if(cfvalue && CFGetTypeID(cfvalue) == CFNumberGetTypeID()) {
                                        CFNumberGetValue(cfvalue, kCFNumberIntType, &optval[i])
                                    }
                                }
                                status = Sane.control_option(GetSaneHandle(), option,
                                                            Sane.ACTION_SET_VALUE, optval, nil)
                                assert(status == Sane.STATUS_GOOD)
                                // delete[] optval
                            }
                        }
                        else {
                            let cfvalue: CFNumberRef = CFNumberRef(CFDictionaryGetValue(dict, key))
                            if(cfvalue && CFGetTypeID(cfvalue) == CFNumberGetTypeID()) {
                                let optval: Sane.Word
                                CFNumberGetValue(cfvalue, kCFNumberIntType, &optval)
                                status = Sane.control_option(GetSaneHandle(), option,
                                                            Sane.ACTION_SET_VALUE, &optval, nil)
                                assert(status == Sane.STATUS_GOOD)
                            }
                        }
                        break

                    case Sane.TYPE_FIXED:

                        if(optdesc.size > sizeof(Sane.Word)) {
                            let cfarray: CFArrayRef = CFArrayRef(CFDictionaryGetValue(dict, key))
                            if(cfarray && CFGetTypeID(cfarray) == CFArrayGetTypeID() &&
                                CFArrayGetCount(cfarray) == optdesc.size / sizeof(Sane.Word)) {
                                Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                                status = Sane.control_option(GetSaneHandle(), option,
                                                            Sane.ACTION_GET_VALUE, optval, nil)
                                assert(status == Sane.STATUS_GOOD)
                                for i in optdesc.size / sizeof(Sane.Word) {
                                    let cfvalue: CFNumberRef =
                                        CFNumberRef(CFArrayGetValueAtIndex(cfarray, i))
                                    if(cfvalue && CFGetTypeID(cfvalue) == CFNumberGetTypeID()) {
                                        var val: Float
                                        CFNumberGetValue(cfvalue, kCFNumberDoubleType, &val)
                                        optval[i] = FIX(val)
                                    }
                                }
                                status = Sane.control_option(GetSaneHandle(), option,
                                                            Sane.ACTION_SET_VALUE, optval, nil)
                                assert(status == Sane.STATUS_GOOD)
                                // delete[] optval
                            }
                        }
                        else {
                            let cfvalue: CFNumberRef = CFNumberRef(CFDictionaryGetValue(dict, key))
                            if(cfvalue && CFGetTypeID(cfvalue) == CFNumberGetTypeID()) {
                                var val: Float
                                CFNumberGetValue(cfvalue, kCFNumberDoubleType, &val)
                                let optval: Sane.Word = FIX(val)
                                status = Sane.control_option(GetSaneHandle(), option,
                                                            Sane.ACTION_SET_VALUE, &optval, nil)
                                assert(status == Sane.STATUS_GOOD)
                            }
                        }
                        break

                    case Sane.TYPE_STRING: {

                        let cfvalue: String = String(CFDictionaryGetValue(dict, key))
                        if(cfvalue && CFGetTypeID(cfvalue) == CFStringGetTypeID()) {
                            let optval: String = String[optdesc.size]
                            CFStringGetCString(cfvalue, optval, optdesc.size, kCFStringEncodingUTF8)
                            status = Sane.control_option(GetSaneHandle(), option,
                                                        Sane.ACTION_SET_VALUE, optval, nil)
                            assert(status == Sane.STATUS_GOOD)
                            // delete[] optval
                        }
                        break
                    }

                    default:
                        break
                }

                CFRelease(key)
            }
            option++
        }
    }



    public func GetRect(viewrect: Rect) {

        var option: Int
        var optdesc: Sane.Option_Descriptor
        var status: Sane.Status

        option = optionIndex[Sane.NAME_SCAN_TL_Y]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                        &rect.top, nil)
            assert(status == Sane.STATUS_GOOD)
            rect.type = optdesc.type
            rect.unit = optdesc.unit
        } else {
            rect.top = -1
            rect.type = Sane.TYPE_FIXED
            rect.unit = Sane.UNIT_MM
        }

        option = optionIndex[Sane.NAME_SCAN_TL_X]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                        &rect.left, nil)
            assert(status == Sane.STATUS_GOOD)
        } else {
            rect.left = -1
        }

        option = optionIndex[Sane.NAME_SCAN_BR_Y]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                        &rect.bottom, nil)
            assert(status == Sane.STATUS_GOOD)
        } else {
            rect.bottom = -1
        }

        option = optionIndex[Sane.NAME_SCAN_BR_X]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                        &rect.right, nil)
            assert(status == Sane.STATUS_GOOD)
        } else {
            rect.right = -1
        }
    }


    public func SetRect(viewrect: Rect) {

        var option: Int
        var optdesc: Sane.Option_Descriptor
        var status: Sane.Status
        var info: Int

        var oldrect: Rect
        GetRect(&oldrect)

        if(rect.top < oldrect.bottom) {

            option = optionIndex[Sane.NAME_SCAN_TL_Y]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.top, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.top, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.top, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }

            option = optionIndex[Sane.NAME_SCAN_BR_Y]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.bottom, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.bottom, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.bottom, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }
        }

        else {

            option = optionIndex[Sane.NAME_SCAN_BR_Y]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.bottom, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.bottom, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.bottom, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }

            option = optionIndex[Sane.NAME_SCAN_TL_Y]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.top, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.top, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.top, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }
        }

        if(rect.left < oldrect.right) {

            option = optionIndex[Sane.NAME_SCAN_TL_X]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.left, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.left, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.left, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }

            option = optionIndex[Sane.NAME_SCAN_BR_X]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.right, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.right, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.right, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }
        }

        else {

            option = optionIndex[Sane.NAME_SCAN_BR_X]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.right, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.right, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.right, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }

            option = optionIndex[Sane.NAME_SCAN_TL_X]
            optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
            if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
                status = Sane.constrain_value(optdesc, &rect.left, nil)
                assert(status == Sane.STATUS_GOOD)
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                            &rect.left, &info)
                assert(status == Sane.STATUS_GOOD)
                if(info & Sane.INFO_INEXACT) {
                    status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                &rect.left, nil)
                    assert(status == Sane.STATUS_GOOD)
                }
            }
        }
    }


    public func GetMaxRect(rect: Rect) {

        var option: Int
        var optdesc: Sane.Option_Descriptor

        option = optionIndex[Sane.NAME_SCAN_TL_Y]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            switch(optdesc.constraint_type) {
                case Sane.CONSTRAINT_RANGE:
                    rect.top = optdesc.constraint.range.min
                    break
                case Sane.CONSTRAINT_WORD_LIST:
                    rect.top = optdesc.constraint.word_list[1]
                    break
                default:
                    rect.top = -1
                    break
            }
            rect.type = optdesc.type
            rect.unit = optdesc.unit
        } else {
            rect.top = -1
        }

        option = optionIndex[Sane.NAME_SCAN_TL_X]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            switch(optdesc.constraint_type) {
                case Sane.CONSTRAINT_RANGE:
                    rect.left = optdesc.constraint.range.min
                    break
                case Sane.CONSTRAINT_WORD_LIST:
                    rect.left = optdesc.constraint.word_list[1]
                    break
                default:
                    rect.left = -1
                    break
            }
        } else {
            rect.left = -1
        }

        option = optionIndex[Sane.NAME_SCAN_BR_Y]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            switch(optdesc.constraint_type) {
                case Sane.CONSTRAINT_RANGE:
                    rect.bottom = optdesc.constraint.range.max
                    break
                case Sane.CONSTRAINT_WORD_LIST:
                    rect.bottom = optdesc.constraint.word_list[optdesc.constraint.word_list[0]]
                    break
                default:
                    rect.bottom = -1
                    break
            }
        } else {
            rect.bottom = -1
        }

        option = optionIndex[Sane.NAME_SCAN_BR_X]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            switch(optdesc.constraint_type) {
                case Sane.CONSTRAINT_RANGE:
                    rect.right = optdesc.constraint.range.max
                    break
                case Sane.CONSTRAINT_WORD_LIST:
                    rect.right = optdesc.constraint.word_list[optdesc.constraint.word_list[0]]
                    break
                default:
                    rect.right = -1
                    break
            }
        } else {
            rect.right = -1
        }
    }


    public func GetResolution(res: Resolution) {

        var option: Int
        var optdesc: Sane.Option_Descriptor
        var status: Sane.Status

        option = optionIndex[Sane.NAME_SCAN_X_RESOLUTION]
        if(!option) {
            option = optionIndex[Sane.NAME_SCAN_RESOLUTION]
        }
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                        &res.h, nil)
            assert(status == Sane.STATUS_GOOD)
            res.type = optdesc.type
        } else {
            res.h = 72
            res.type = Sane.TYPE_INT
        }

        option = optionIndex[Sane.NAME_SCAN_Y_RESOLUTION]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && OPTION_IS_GETTABLE(optdesc.cap)) {
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                        &res.v, nil)
            assert(status == Sane.STATUS_GOOD)
        } else {
            res.v = res.h
        }
    }


    public func SetResolution(res: Resolution) {

        var option: Int
        var optdesc: Sane.Option_Descriptor
        var status: Sane.Status
        var info: Int

        option = optionIndex[Sane.NAME_SCAN_X_RESOLUTION]
        if(!option) {
            option = optionIndex[Sane.NAME_SCAN_RESOLUTION]
        }
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            status = Sane.constrain_value(optdesc, &res.h, nil)
            assert(status == Sane.STATUS_GOOD)
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                        &res.h, &info)
            assert(status == Sane.STATUS_GOOD)
            if(info & Sane.INFO_INEXACT) {
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                            &res.h, nil)
                assert(status == Sane.STATUS_GOOD)
            }
        }

        option = optionIndex[Sane.NAME_SCAN_Y_RESOLUTION]
        optdesc = (option ? Sane.get_option_descriptor(GetSaneHandle(), option) : nil)
        if(optdesc && Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            status = Sane.constrain_value(optdesc, &res.v, nil)
            assert(status == Sane.STATUS_GOOD)
            status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                        &res.v, &info)
            assert(status == Sane.STATUS_GOOD)
            if(info & Sane.INFO_INEXACT) {
                status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                            &res.v, nil)
                assert(status == Sane.STATUS_GOOD)
            }
        }
    }



    public func GetPixelType(capability: pTW_CAPABILITY, onlyone: Bool) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_MODE]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_STRING) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var pixeltype: TW_UINT16 = TW_UINT16(-1)

        var optval: String = String[optdesc.size]
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE, optval, nil)
        assert(status == Sane.STATUS_GOOD)

        if(strncasecmp(optval, "binary", 6) == 0 ||
            strncasecmp(optval, "lineart", 7) == 0 ||
            strncasecmp(optval, "halftone", 8) == 0) {
                pixeltype = TWPT_BW
        } else if(strncasecmp(optval, "gray", 4) == 0) {
            pixeltype = TWPT_GRAY
        } else if(strncasecmp(optval, "color", 5) == 0) {
            pixeltype = TWPT_RGB
        }

        // delete[] optval

        if pixeltype == TW_UINT16(-1) {
            return datasource.SetStatus(TWCC_BADVALUE)
        }

        if(onlyone) {
            return datasource.BuildOneValue(capability, TWTY_UINT16, pixeltype)
        }

        switch(optdesc.constraint_type) {

            case Sane.CONSTRAINT_STRING_LIST: {

                var havebw: Bool = false
                var havegray: Bool = false
                var havergb: Bool = false

                var i: Int = 0
                while optdesc.constraint.string_list[i] {
                    if(strncasecmp(optdesc.constraint.string_list[i], "binary", 6) == 0 ||
                        strncasecmp(optdesc.constraint.string_list[i], "lineart", 7) == 0 ||
                        strncasecmp(optdesc.constraint.string_list[i], "halftone", 8) == 0) {
                            havebw = true
                    } else if(strncasecmp(optdesc.constraint.string_list[i], "gray", 4) == 0) {
                        havegray = true
                    } else if(strncasecmp(optdesc.constraint.string_list[i], "color", 5) == 0) {
                        havergb = true
                    }
                    i++
                }

                var pixeltypes: TW_UINT16 = []

                var numitems: TW_UINT32 = 0
                var currentindex: TW_UINT32 = 0
                if(havebw) {
                    pixeltypes[numitems] = TWPT_BW
                    if(pixeltype == TWPT_BW) {
                        currentindex = numitems
                    }
                    numitems++
                }
                if(havegray) {
                    pixeltypes[numitems] = TWPT_GRAY
                    if(pixeltype == TWPT_GRAY) {
                        currentindex = numitems
                    }
                    numitems++
                }
                if(havergb) {
                    pixeltypes[numitems] = TWPT_RGB
                    if(pixeltype == TWPT_RGB) {
                        currentindex = numitems
                    }
                    numitems++
                }

                return datasource.BuildEnumeration(capability, TWTY_UINT16, numitems, currentindex, 0, pixeltypes)
            }

            default:
                return datasource.BuildOneValue(capability, TWTY_UINT16, pixeltype)
        }
    }


    public func GetPixelTypeDefault(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_MODE]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.constraint_type != Sane.CONSTRAINT_STRING_LIST) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var havebw: Bool = false
        var havegray: Bool = false
        var havergb: Bool = false

        var i: Int = 0
        while optdesc.constraint.string_list[i] {
            if(strncasecmp(optdesc.constraint.string_list[i], "binary", 6) == 0 ||
                strncasecmp(optdesc.constraint.string_list[i], "lineart", 7) == 0 ||
                strncasecmp(optdesc.constraint.string_list[i], "halftone", 8) == 0) {
                havebw = true
            } else if(strncasecmp(optdesc.constraint.string_list[i], "gray", 4) == 0) {
                havegray = true
            } else if(strncasecmp(optdesc.constraint.string_list[i], "color", 5) == 0) {
                havergb = true
            }
            i++
        }

        var pixeltype: TW_UINT16

        if havebw {
            pixeltype = TWPT_BW
        } else if havegray {
            pixeltype = TWPT_GRAY
        } else if havergb {
            pixeltype = TWPT_RGB
        } else {
            return datasource.SetStatus(TWCC_BADVALUE)
        }

        return datasource.BuildOneValue(capability, TWTY_UINT16, pixeltype)
    }


    public func SetPixelType(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_MODE]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.constraint_type != Sane.CONSTRAINT_STRING_LIST) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var havebw: Bool = false
        var havegray: Bool = false
        var havergb: Bool = false

        var i: Int = 0
        while optdesc.constraint.string_list[i] {
            if(strncasecmp(optdesc.constraint.string_list[i], "binary", 6) == 0 ||
                strncasecmp(optdesc.constraint.string_list[i], "lineart", 7) == 0 ||
                strncasecmp(optdesc.constraint.string_list[i], "halftone", 8) == 0) {
                havebw = true
            } else if(strncasecmp(optdesc.constraint.string_list[i], "gray", 4) == 0) {
                havegray = true
            } else if(strncasecmp(optdesc.constraint.string_list[i], "color", 5) == 0) {
                havergb = true
            }
            i++
        }

        var pixeltype: TW_UINT16
        var inexact: Bool = false

        if capability {
            if(capability.ConType != TWON_ONEVALUE) {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
            pixeltype = pTW_ONEVALUE((Handle(capability.hContainer))).Item
            // fallback to gray if binary/lineart/halftone does not exist
            if(pixeltype == TWPT_BW && !havebw) {
                pixeltype = TWPT_GRAY
                inexact = true
            }
        } else {
            if havebw {
                pixeltype = TWPT_BW
            } else if havegray {
                pixeltype = TWPT_GRAY
            } else if havergb {
                pixeltype = TWPT_RGB
            } else {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
        }

        var i: Int = 0
        while optdesc.constraint.string_list[i] {

            if((pixeltype == TWPT_BW && (strncasecmp(optdesc.constraint.string_list[i], "binary", 6) == 0 ||
                                        strncasecmp(optdesc.constraint.string_list[i], "lineart", 7) == 0 ||
                                        strncasecmp(optdesc.constraint.string_list[i], "halftone", 8) == 0)) ||
                (pixeltype == TWPT_GRAY && strncasecmp(optdesc.constraint.string_list[i], "gray", 4) == 0) ||
                (pixeltype == TWPT_RGB && strncasecmp(optdesc.constraint.string_list[i], "color", 5) == 0)) {

                var optval: String = String[optdesc.size]
                strcpy(optval, optdesc.constraint.string_list[i])
                var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE,
                                                        optval, nil)
                assert(status == Sane.STATUS_GOOD)
                // delete[] optval
                return(inexact ? TWRC_CHECKSTATUS : TWRC_SUCCESS)
            }
            i++
        }

        return datasource.SetStatus(TWCC_BADVALUE)
    }


    public func GetBitDepth(capability: pTW_CAPABILITY, onlyone: Bool) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_BIT_DEPTH]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var bitdepth: Int
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE, &bitdepth, nil)
        assert(status == Sane.STATUS_GOOD)

        if(onlyone) {
            return datasource.BuildOneValue(capability, TWTY_UINT16, bitdepth)
        }

        switch(optdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE: {
                return datasource.BuildRange(capability, TWTY_UINT16,
                                            optdesc.constraint.range.min,
                                            optdesc.constraint.range.max,
                                            std.max(optdesc.constraint.range.quant, 1),
                                            optdesc.constraint.range.min,
                                            bitdepth)
            }

            case Sane.CONSTRAINT_WORD_LIST: {
                let itemlist: pTW_UINT16 = TW_UINT16 [optdesc.constraint.word_list[0]]
                var currentindex: TW_UINT32 = 0
                for i in optdesc.constraint.word_list[0] {
                    itemlist[i] = optdesc.constraint.word_list[i + 1]
                    if(bitdepth == optdesc.constraint.word_list[i + 1]) {
                        currentindex = i
                    }
                }
                let retval: TW_UINT16 = datasource.BuildEnumeration(capability, TWTY_UINT16,
                                                                optdesc.constraint.word_list[0],
                                                                currentindex, 0, itemlist)
                // delete[] itemlist
                return retval
            }

            default:
                return datasource.BuildOneValue(capability, TWTY_UINT16, bitdepth)
        }
    }


    public func GetBitDepthDefault(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_BIT_DEPTH]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        switch(optdesc.constraint_type) {
            case Sane.CONSTRAINT_RANGE:
                return datasource.BuildOneValue(capability, TWTY_UINT16, optdesc.constraint.range.min)

            case Sane.CONSTRAINT_WORD_LIST:
                return datasource.BuildOneValue(capability, TWTY_UINT16, optdesc.constraint.word_list[1])

            default:
                return datasource.SetStatus(TWCC_BADVALUE)
        }
    }


    public func SetBitDepth(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_BIT_DEPTH]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var bitdepth: Int

        if(capability) {
            if(capability.ConType != TWON_ONEVALUE) {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
            bitdepth = pTW_ONEVALUE(Handle(capability.hContainer)).Item
        } else {
            switch(optdesc.constraint_type) {
                case Sane.CONSTRAINT_RANGE:
                    bitdepth = optdesc.constraint.range.min
                case Sane.CONSTRAINT_WORD_LIST:
                    bitdepth = optdesc.constraint.word_list[1]
                default:
                    return datasource.SetStatus(TWCC_BADVALUE)
            }
        }

        var info: Int
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE, &bitdepth, &info)
        assert(status == Sane.STATUS_GOOD)
        return(info ? TWRC_CHECKSTATUS : TWRC_SUCCESS)
    }


    public func GetXNativeResolution(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_X_RESOLUTION]
        if(!option) {
            option = optionIndex[Sane.NAME_SCAN_RESOLUTION]
        }
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        switch(optdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE: {

                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32,
                                                    S2T(Sane.INT2FIX(optdesc.constraint.range.max)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(optdesc.constraint.range.max))
                }

            }

            case Sane.CONSTRAINT_WORD_LIST: {
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32,
                                                    S2T(Sane.INT2FIX(optdesc.constraint.word_list[optdesc.constraint.word_list[0]])))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32,
                                                    S2T(optdesc.constraint.word_list[optdesc.constraint.word_list[0]]))
                }
            }

            default:

                var xres: Sane.Word
                var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                        &xres, nil)
                assert(status == Sane.STATUS_GOOD)

                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(xres)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(xres))
                }
        }
    }


    public func GetYNativeResolution(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_Y_RESOLUTION]
        if(!option) {
            return GetXNativeResolution(capability)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        switch(optdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE: {
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32,
                                                    S2T(Sane.INT2FIX(optdesc.constraint.range.max)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(optdesc.constraint.range.max))
                }
            }

            case Sane.CONSTRAINT_WORD_LIST: {
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32,
                                                    S2T(Sane.INT2FIX(optdesc.constraint.word_list[optdesc.constraint.word_list[0]])))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32,
                                                    S2T(optdesc.constraint.word_list[optdesc.constraint.word_list[0]]))
                }
            }

            default:

                var yres: Sane.Word
                var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE,
                                                        &yres, nil)
                assert(status == Sane.STATUS_GOOD)

                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(yres)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(yres))
                }
        }
    }


    public func GetXResolution(capability: pTW_CAPABILITY, onlyone: Bool) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_X_RESOLUTION]
        if(!option) {
            option = optionIndex[Sane.NAME_SCAN_RESOLUTION]
        }
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var xres: Sane.Word
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE, &xres, nil)
        assert(status == Sane.STATUS_GOOD)

        if(onlyone) {
            if(optdesc.type == Sane.TYPE_INT) {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(xres)))
            } else {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(xres))
            }
        }

        switch(optdesc.constraint_type) {
            case Sane.CONSTRAINT_RANGE: {
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.min)),
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.max)),
                                                S2T(Sane.INT2FIX(std.max(optdesc.constraint.range.quant, 1))),
                                                S2T(Sane.INT2FIX(72)),
                                                S2T(Sane.INT2FIX(xres)))
                } else {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(optdesc.constraint.range.min),
                                                S2T(optdesc.constraint.range.max),
                                                S2T(std.max(optdesc.constraint.range.quant, 1)),
                                                S2T(Sane.INT2FIX(72)),
                                                S2T(xres))
                }
            }

            case Sane.CONSTRAINT_WORD_LIST: {
                let itemlist: pTW_FIX32 = TW_FIX32 [optdesc.constraint.word_list[0]]
                var currentindex: TW_UINT32 = 0
                var defaultindex: TW_UINT32 = 0
                for i in optdesc.constraint.word_list[0] {
                    if(optdesc.type == Sane.TYPE_INT) {
                        itemlist[i] = S2T(Sane.INT2FIX(optdesc.constraint.word_list[i + 1]))
                    } else {
                        itemlist[i] = S2T(optdesc.constraint.word_list[i + 1])
                    }
                    if(std.abs(T2S(itemlist[i]) - INT2FIX(72)) <
                        std.abs(T2S(itemlist[defaultindex]) - INT2FIX(72))) {
                            defaultindex = i
                    }
                    if(xres == optdesc.constraint.word_list[i + 1]) {
                        currentindex = i
                    }
                }
                let retval: TW_UINT16 = datasource.BuildEnumeration(capability, TWTY_FIX32,
                                                                optdesc.constraint.word_list[0],
                                                                currentindex, defaultindex, itemlist)
                // delete[] itemlist
                return retval
            }

            default:
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(xres)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(xres))
                }
        }
    }


    public func GetXResolutionDefault(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_X_RESOLUTION]
        if(!option) {
            option = optionIndex[Sane.NAME_SCAN_RESOLUTION]
        }
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(72)))
    }


    public func SetXResolution(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_X_RESOLUTION]
        if(!option) {
            option = optionIndex[Sane.NAME_SCAN_RESOLUTION]
        }
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var xres: Sane.Word

        if(capability) {
            if(capability.ConType != TWON_ONEVALUE) {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
            if(optdesc.type == Sane.TYPE_INT) {
                xres = FIX2INT(T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item)))
            } else {
                xres = T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item))
            }
        } else {
            if(optdesc.type == Sane.TYPE_INT) {
                xres = 72
            } else {
                xres = INT2FIX(72)
            }
        }

        var info: Int
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE, &xres, &info)
        assert(status == Sane.STATUS_GOOD)
        return(info ? TWRC_CHECKSTATUS : TWRC_SUCCESS)
    }


    public func GetYResolution(capability: pTW_CAPABILITY, onlyone: Bool) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_Y_RESOLUTION]
        if(!option) {
            return GetXResolution(capability, onlyone)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var yres: Sane.Word
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE, &yres, nil)
        assert(status == Sane.STATUS_GOOD)

        if(onlyone) {
            if(optdesc.type == Sane.TYPE_INT) {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(yres)))
            } else {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(yres))
            }
        }

        switch(optdesc.constraint_type) {
            case Sane.CONSTRAINT_RANGE: {
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.min)),
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.max)),
                                                S2T(Sane.INT2FIX(std.max(optdesc.constraint.range.quant, 1))),
                                                S2T(Sane.INT2FIX(72)),
                                                S2T(Sane.INT2FIX(yres)))
                } else {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(optdesc.constraint.range.min),
                                                S2T(optdesc.constraint.range.max),
                                                S2T(std.max(optdesc.constraint.range.quant, 1)),
                                                S2T(Sane.INT2FIX(72)),
                                                S2T(yres))
                }
            }

            case Sane.CONSTRAINT_WORD_LIST: {
                let itemlist: pTW_FIX32 = TW_FIX32 [optdesc.constraint.word_list[0]]
                var currentindex: TW_UINT32 = 0
                var defaultindex: TW_UINT32 = 0
                for i in optdesc.constraint.word_list[0] {
                    if(optdesc.type == Sane.TYPE_INT) {
                        itemlist[i] = S2T(Sane.INT2FIX(optdesc.constraint.word_list[i + 1]))
                    } else {
                        itemlist[i] = S2T(optdesc.constraint.word_list[i + 1])
                    }
                    if(std.abs(T2S(itemlist[i]) - INT2FIX(72)) <
                        std.abs(T2S(itemlist[defaultindex]) - INT2FIX(72))) {
                            defaultindex = i
                        }
                    if(yres == optdesc.constraint.word_list[i + 1]) {
                        currentindex = i
                    }
                }
                let retval: TW_UINT16 = datasource.BuildEnumeration(capability, TWTY_FIX32,
                                                                optdesc.constraint.word_list[0],
                                                                currentindex, defaultindex, itemlist)
                // delete[] itemlist
                return retval
            }

            default:
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(yres)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(yres))
                }
        }
    }


    public func GetYResolutionDefault(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_Y_RESOLUTION]
        if(!option) {
            GetXResolutionDefault(capability)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(72)))
    }


    public func SetYResolution(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_SCAN_Y_RESOLUTION]
        if(!option) {
            return TWRC_SUCCESS // Just ignore it....
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var yres: Sane.Word

        if(capability) {
            if(capability.ConType != TWON_ONEVALUE) {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
            if(optdesc.type == Sane.TYPE_INT) {
                yres = FIX2INT(T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item)))
            } else {
                yres = T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item))
            }
        } else {
            if(optdesc.type == Sane.TYPE_INT) {
                yres = 72
            } else {
                yres = INT2FIX(72)
            }
        }

        var info: Int
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE, &yres, &info)
        assert(status == Sane.STATUS_GOOD)
        return(info ? TWRC_CHECKSTATUS : TWRC_SUCCESS)
    }


    public func GetPhysicalWidth(capability: pTW_CAPABILITY) -> TW_UINT16 {

        let loption: Int = optionIndex[Sane.NAME_SCAN_TL_X]
        let roption: Int = optionIndex[Sane.NAME_SCAN_BR_X]
        if(!loption || !roption) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        let loptdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), loption)
        let roptdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), roption)

        if(!Sane.OPTION_IS_ACTIVE(loptdesc.cap) || !Sane.OPTION_IS_ACTIVE(roptdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(roptdesc.type != Sane.TYPE_INT && roptdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var unitsPerInch: Float
        if(roptdesc.unit == Sane.UNIT_MM) {
            unitsPerInch = 25.4
        } else {
            unitsPerInch = 72.0
        }

        switch(roptdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE: {

                var maxwidth: TW_FIX32
                if(roptdesc.type == Sane.TYPE_INT) {
                    maxwidth = S2T(Sane.FIX((roptdesc.constraint.range.max -
                                            loptdesc.constraint.range.min) / unitsPerInch))
                } else {
                    maxwidth = S2T(lround((roptdesc.constraint.range.max -
                                            loptdesc.constraint.range.min) / unitsPerInch))
                }

                // Compensate for rounding errors...
                if((maxwidth.Frac & 0x7FFF) + 0x0400 > 0x8000) {
                    if(maxwidth.Frac < 0x8000) {
                        maxwidth.Frac = 0x8000
                    } else {
                        maxwidth.Whole++
                        maxwidth.Frac = 0
                    }
                }

                return datasource.BuildOneValue(capability, TWTY_FIX32, maxwidth)
                break
            }

            default:
                return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
                break
        }
    }


    public func GetPhysicalHeight(capability: pTW_CAPABILITY) -> TW_UINT16 {

        let toption: Int = optionIndex[Sane.NAME_SCAN_TL_Y]
        let boption: Int = optionIndex[Sane.NAME_SCAN_BR_Y]
        if(!toption || !boption) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        let toptdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), toption)
        let boptdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), boption)

        if(!Sane.OPTION_IS_ACTIVE(toptdesc.cap) || !Sane.OPTION_IS_ACTIVE(boptdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(boptdesc.type != Sane.TYPE_INT && boptdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var unitsPerInch: Float
        if(boptdesc.unit == Sane.UNIT_MM) {
            unitsPerInch = 25.4
        } else {
            unitsPerInch = 72.0
        }

        switch(boptdesc.constraint_type) {
            case Sane.CONSTRAINT_RANGE: {

                var maxheight: TW_FIX32
                if(boptdesc.type == Sane.TYPE_INT) {
                    maxheight = S2T(Sane.FIX((boptdesc.constraint.range.max -
                                                toptdesc.constraint.range.min) / unitsPerInch))
                } else {
                    maxheight = S2T(lround((boptdesc.constraint.range.max -
                                            toptdesc.constraint.range.min) / unitsPerInch))
                }

                // Compensate for rounding errors...
                if((maxheight.Frac & 0x7FFF) + 0x0400 > 0x8000) {
                    if(maxheight.Frac < 0x8000) {
                        maxheight.Frac = 0x8000
                    } else {
                        maxheight.Whole++
                        maxheight.Frac = 0
                    }
                }

                return datasource.BuildOneValue(capability, TWTY_FIX32, maxheight)
            }

            default:
                return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }
    }


    public func GetBrightness(capability: pTW_CAPABILITY, onlyone: Bool) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_BRIGHTNESS]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var brightness: Sane.Word
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE, &brightness, nil)
        assert(status == Sane.STATUS_GOOD)

        if(onlyone) {
            if(optdesc.type == Sane.TYPE_INT) {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(brightness)))
            } else {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(brightness))
            }
        }

        switch(optdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE: {

                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.min)),
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.max)),
                                                S2T(Sane.INT2FIX(std.max(optdesc.constraint.range.quant, 1))),
                                                S2T(0),
                                                S2T(Sane.INT2FIX(brightness)))
                } else {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(optdesc.constraint.range.min),
                                                S2T(optdesc.constraint.range.max),
                                                S2T(std.max(optdesc.constraint.range.quant, 1)),
                                                S2T(0),
                                                S2T(brightness))
                }
            }

            case Sane.CONSTRAINT_WORD_LIST: {

                let itemlist: pTW_FIX32 = TW_FIX32 [optdesc.constraint.word_list[0]]
                var currentindex: TW_UINT32 = 0
                var defaultindex: TW_UINT32 = 0
                for i in optdesc.constraint.word_list[0] {
                    if(optdesc.type == Sane.TYPE_INT) {
                        itemlist[i] = S2T(Sane.INT2FIX(optdesc.constraint.word_list[i + 1]))
                    } else {
                        itemlist[i] = S2T(optdesc.constraint.word_list[i + 1])
                    }
                    if(optdesc.constraint.word_list[i + 1] == 0) {
                        defaultindex = i
                    }
                    if(optdesc.constraint.word_list[i + 1] == brightness) {
                        currentindex = i
                    }
                }
                let retval: TW_UINT16 = datasource.BuildEnumeration(capability, TWTY_FIX32,
                                                                optdesc.constraint.word_list[0],
                                                                currentindex, defaultindex, itemlist)
                // delete[] itemlist
                return retval
            }

            default:
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(brightness)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(brightness))
                }
        }
    }


    public func GetBrightnessDefault(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_BRIGHTNESS]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(0))
    }


    public func SetBrightness(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_BRIGHTNESS]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var brightness: Sane.Word

        if(capability) {
            if(capability.ConType != TWON_ONEVALUE) {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
            if(optdesc.type == Sane.TYPE_INT) {
                brightness = FIX2INT(T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item)))
            } else {
                brightness = T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item))
            }
        } else {
            brightness = 0
        }

        var info: Int
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE, &brightness, &info)
        assert(status == Sane.STATUS_GOOD)
        return(info ? TWRC_CHECKSTATUS : TWRC_SUCCESS)
    }


    public func GetContrast(capability: pTW_CAPABILITY, onlyone: Bool) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_CONTRAST]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_GETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var contrast: Sane.Word
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_GET_VALUE, &contrast, nil)
        assert(status == Sane.STATUS_GOOD)

        if(onlyone) {
            if(optdesc.type == Sane.TYPE_INT) {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(contrast)))
            } else {
                return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(contrast))
            }
        }

        switch(optdesc.constraint_type) {
            case Sane.CONSTRAINT_RANGE: {
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.min)),
                                                S2T(Sane.INT2FIX(optdesc.constraint.range.max)),
                                                S2T(Sane.INT2FIX(std.max(optdesc.constraint.range.quant, 1))),
                                                S2T(0),
                                                S2T(Sane.INT2FIX(contrast)))
                } else {
                    return datasource.BuildRange(capability, TWTY_FIX32,
                                                S2T(optdesc.constraint.range.min),
                                                S2T(optdesc.constraint.range.max),
                                                S2T(std.max(optdesc.constraint.range.quant, 1)),
                                                S2T(0),
                                                S2T(contrast))
                }
            }

            case Sane.CONSTRAINT_WORD_LIST: {
                let itemlist: pTW_FIX32 = TW_FIX32 [optdesc.constraint.word_list[0]]
                var currentindex: TW_UINT32 = 0
                var defaultindex: TW_UINT32 = 0
                for i in optdesc.constraint.word_list[0] {
                    if(optdesc.type == Sane.TYPE_INT) {
                        itemlist[i] = S2T(Sane.INT2FIX(optdesc.constraint.word_list[i + 1]))
                    } else {
                        itemlist[i] = S2T(optdesc.constraint.word_list[i + 1])
                    }
                    if(optdesc.constraint.word_list[i + 1] == 0) {
                        defaultindex = i
                    }
                    if(optdesc.constraint.word_list[i + 1] == contrast) {
                        currentindex = i
                    }
                }
                let retval: TW_UINT16 = datasource.BuildEnumeration(capability, TWTY_FIX32,
                                                                optdesc.constraint.word_list[0],
                                                                currentindex, defaultindex, itemlist)
                // delete[] itemlist
                return retval
            }

            default:
                if(optdesc.type == Sane.TYPE_INT) {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(Sane.INT2FIX(contrast)))
                } else {
                    return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(contrast))
                }
        }
    }


    public func GetContrastDefault(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_CONTRAST]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        return datasource.BuildOneValue(capability, TWTY_FIX32, S2T(0))
    }


    public func SetContrast(capability: pTW_CAPABILITY) -> TW_UINT16 {

        var option: Int = optionIndex[Sane.NAME_CONTRAST]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(!Sane.OPTION_IS_ACTIVE(optdesc.cap) || !Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            return datasource.SetStatus(TWCC_CAPSEQERROR)
        }

        if(optdesc.type != Sane.TYPE_INT && optdesc.type != Sane.TYPE_FIXED) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        var contrast: Sane.Word

        if(capability) {
            if(capability.ConType != TWON_ONEVALUE) {
                return datasource.SetStatus(TWCC_BADVALUE)
            }
            if(optdesc.type == Sane.TYPE_INT) {
                contrast = FIX2INT(T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item)))
            } else {
                contrast = T2S(TW_FIX32(pTW_ONEVALUE(Handle(capability.hContainer)).Item))
            }
        } else {
            contrast = 0
        }

        var info: Int
        var status: Sane.Status = Sane.control_option(GetSaneHandle(), option, Sane.ACTION_SET_VALUE, &contrast, &info)
        assert(status == Sane.STATUS_GOOD)
        return(info ? TWRC_CHECKSTATUS : TWRC_SUCCESS)
    }


    public func GetLayout(imagelayout: pTW_IMAGELAYOUT) -> TW_UINT16 {

        var bounds: Rect

        GetRect(&bounds)

        var unitsPerInch: Float
        if(bounds.unit == Sane.UNIT_MM) {
            unitsPerInch = 25.4
        } else {
            unitsPerInch = 72.0
        }

        if(bounds.type == Sane.TYPE_INT) {
            imagelayout.Frame.Top    = S2T(Sane.FIX(bounds.top    / unitsPerInch))
            imagelayout.Frame.Left   = S2T(Sane.FIX(bounds.left   / unitsPerInch))
            imagelayout.Frame.Bottom = S2T(Sane.FIX(bounds.bottom / unitsPerInch))
            imagelayout.Frame.Right  = S2T(Sane.FIX(bounds.right  / unitsPerInch))
        } else {
            imagelayout.Frame.Top    = S2T(lround(bounds.top    / unitsPerInch))
            imagelayout.Frame.Left   = S2T(lround(bounds.left   / unitsPerInch))
            imagelayout.Frame.Bottom = S2T(lround(bounds.bottom / unitsPerInch))
            imagelayout.Frame.Right  = S2T(lround(bounds.right  / unitsPerInch))
        }

        imagelayout.DocumentNumber = 1
        imagelayout.PageNumber = 1
        imagelayout.FrameNumber = 1

        return TWRC_SUCCESS
    }


    public func SetLayout(imagelayout: pTW_IMAGELAYOUT) -> TW_UINT16 {

        var bounds: Rect

        var option: Int = optionIndex[Sane.NAME_SCAN_TL_Y]
        if(!option) {
            return datasource.SetStatus(TWCC_CAPUNSUPPORTED)
        }

        bounds.type = Sane.get_option_descriptor(GetSaneHandle(), option).type
        bounds.unit = Sane.get_option_descriptor(GetSaneHandle(), option).unit

        var unitsPerInch: Float
        if(bounds.unit == Sane.UNIT_MM) {
            unitsPerInch = 25.4
        } else {
            unitsPerInch = 72.0
        }

        if(bounds.type == Sane.TYPE_INT) {
            bounds.top    = lround(Sane.UNFIX(T2S(imagelayout.Frame.Top))    * unitsPerInch)
            bounds.left   = lround(Sane.UNFIX(T2S(imagelayout.Frame.Left))   * unitsPerInch)
            bounds.bottom = lround(Sane.UNFIX(T2S(imagelayout.Frame.Bottom)) * unitsPerInch)
            bounds.right  = lround(Sane.UNFIX(T2S(imagelayout.Frame.Right))  * unitsPerInch)
        } else {
            bounds.top    = lround(T2S(imagelayout.Frame.Top)    * unitsPerInch)
            bounds.left   = lround(T2S(imagelayout.Frame.Left)   * unitsPerInch)
            bounds.bottom = lround(T2S(imagelayout.Frame.Bottom) * unitsPerInch)
            bounds.right  = lround(T2S(imagelayout.Frame.Right)  * unitsPerInch)
        }

        SetRect(&bounds)

        return TWRC_SUCCESS
    }



    public func Scan(queue: Bool = true, indicators: Bool = true) -> Image {

        Image * scanImage = Image

        var status: Sane.Status
        var osstat: OSStatus
        var oserr: OSErr

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        GetRect(&scanImage.bounds)
        GetResolution(&scanImage.res)

        var dataBuffer: Buffer

        var cancelled: Bool = false
        var iframe: Int = 0
        while true {

            status = Sane.start(GetSaneHandle())

            if(status != Sane.STATUS_GOOD) {
                if(HasUI()) {
                    SaneError(status)
                }
                cancelled = true
                break
            }

            status = Sane.get_parameters(GetSaneHandle(), &scanImage.param)

            if(status != Sane.STATUS_GOOD) {
                if(HasUI()) {
                    SaneError(status)
                }
                cancelled = true
                break
            }

            scanImage.frame[scanImage.param.format] = iframe

            if(iframe == 0) {
                // If we don't know the height, allocate memory for 12 inches
                var lines: Int
                if(scanImage.param.lines > 0) {
                    lines = scanImage.param.lines
                } else if(scanImage.res.type == Sane.TYPE_INT) {
                    lines = 12 * scanImage.res.v
                } else {
                    lines = lround(ceil(Sane.UNFIX(12 * scanImage.res.v)))
                }

                // Add one extra line so we don't trigger a resizing of the handle
                if(scanImage.param.format == Sane.FRAME_GRAY ||
                    scanImage.param.format == Sane.FRAME_RGB) {
                    dataBuffer.SetSize((lines + 1) * scanImage.param.bytes_per_line)
                } else {
                    dataBuffer.SetSize((lines + 1) * scanImage.param.bytes_per_line * 3)
                }
            }

            var window: WindowRef = nil

            if(HasUI() || indicators) {

                var windowrect: Rect = [ 0, 0, 100, 300 ]

                if(HasUI()) {
                    osstat = CreateNewWindow(kSheetWindowClass,
                                            kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                            &windowrect, &window)
                    assert(osstat == noErr)

                    osstat = SetThemeWindowBackground(window, kThemeBrushSheetBackgroundOpaque, true)
                    assert(osstat == noErr)
                } else {
                    osstat = CreateNewWindow(kMovableModalWindowClass,
                                            kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                            &windowrect, &window)
                    assert(osstat == noErr)

                    osstat = SetThemeWindowBackground(window, kThemeBrushMovableModalBackground, true)
                    assert(osstat == noErr)

                    let text: String = String(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey))
                    osstat = SetWindowTitleWithCFString(window, text)
                    assert(osstat == noErr)
                }

                var rootcontrol: ControlRef
                oserr = GetRootControl(window, &rootcontrol)
                assert(oserr == noErr)

                var controlrect: Rect

                controlrect.top = 20
                controlrect.left = 20
                controlrect.right = windowrect.right - windowrect.left - 20

                let text: String = CFBundleCopyLocalizedString(bundle, CFSTR("Scanning Image..."), nil, nil)
                MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
                CFRelease(text)

                controlrect.top = controlrect.bottom + 20
                controlrect.bottom = controlrect.top + 16

                var progressControl: ControlRef
                osstat = CreateProgressBarControl(nil, &controlrect, 0, 0, 0, true, &progressControl)
                assert(osstat == noErr)

                oserr = EmbedControl(progressControl, rootcontrol)
                assert(oserr == noErr)

                windowrect.bottom = controlrect.bottom + 20

                osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
                assert(osstat == noErr)

                if(HasUI()) {
                    userinterface.ShowSheetWindow(window)
                } else {
                    osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
                    assert(osstat == noErr)

                    ShowWindow(window)
                }
            }

            while(status == Sane.STATUS_GOOD) {
                let maxlength: Size = dataBuffer.CheckSize()
                let p: Ptr = dataBuffer.GetPtr()
                assert(p)
                let length: Int
                status = Sane.read(GetSaneHandle(), Sane.Byte(p), maxlength, &length)
                dataBuffer.ReleasePtr(length)
            }

            if(window) {

                if(HasUI()) {
                    HideSheetWindow(window)
                } else {
                    HideWindow(window)
                }

                DisposeWindow(window)
            }

            if(status != Sane.STATUS_GOOD && status != Sane.STATUS_EOF) {
                if(HasUI()) {
                    SaneError(status)
                }
                cancelled = true
                break
            }

            if(scanImage.param.last_frame) {
                break
            }

            iframe++
        }

        Sane.cancel(GetSaneHandle())

        if(cancelled) {
            return nil
        }

        scanImage.imagedata = dataBuffer.Claim()
        assert(scanImage.imagedata)

        let lines: Int = GetHandleSize(scanImage.imagedata) / scanImage.param.bytes_per_line
        if(scanImage.param.format != Sane.FRAME_GRAY &&
            scanImage.param.format != Sane.FRAME_RGB) {
            lines /= 3
        }

        if(scanImage.param.lines < 0) {
            scanImage.param.lines = lines
        }

        if(queue) {
            if(image) {
                // delete image
            }
            image = scanImage
        }

        return scanImage
    }


    public func SetPreview(preview: Bool) {

        var option: Int = optionIndex[Sane.NAME_PREVIEW]
        if(!option) {
            return
        }

        var optdesc: Sane.Option_Descriptor = Sane.get_option_descriptor(GetSaneHandle(), option)

        if(optdesc && optdesc.type == Sane.TYPE_BOOL &&
            Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_SETTABLE(optdesc.cap)) {
            var status: Sane.Status = Sane.control_option(GetSaneHandle(), option,
                                                    Sane.ACTION_SET_VALUE, &preview, nil)
            assert(status == Sane.STATUS_GOOD)
        }
    }


    public func GetImage() -> Image {
        return image
    }


    public func DequeueImage() {
        if(image) {
            // delete image
        }
        image = nil
    }


    public func GetSaneHandle() -> Sane.Handle {
        if(sanehandles.find(currentDevice) == sanehandles.end()) {
            return nil
        }
        return sanehandles[currentDevice]
    }


    public func GetSaneVersion() -> Int {
        return saneversion
    }



    public func GetAreaOptions(top: Int = nil, left: Int = nil, bottom: Int = nil, right: Int = nil) {
        if(top) {
            *top    = optionIndex[Sane.NAME_SCAN_TL_Y]
        }
        if(left) {
            *left   = optionIndex[Sane.NAME_SCAN_TL_X]
        }
        if(bottom) {
            *bottom = optionIndex[Sane.NAME_SCAN_BR_Y]
        }
        if(right) {
            *right  = optionIndex[Sane.NAME_SCAN_BR_X]
        }
    }
}