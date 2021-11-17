import Twain
import Twain

import DataSource
import SaneDevice
import Image
import Alerts


class DataSource {

    private var origin: Twain.Identity
    private var saneDevice: SaneDevice
    private var twainStatus: Int

    private enum state: State {
        STATE_3 = 3,
        STATE_4 = 4,
        STATE_5 = 5,
        STATE_6 = 6,
        STATE_7 = 7
    }

    private var cap_XferMech: Int

    private var writtenlines: Int
    private var uionly: Bool
    private var indicators: Bool


    public func DataSource() {
        origin(nil)
        saneDevice(nil)
        twainStatus(TWCC_SUCCESS)
        state(STATE_3)
        cap_XferMech(TWSX_NATIVE)
        indicators(true)
    }


    // public func ~DataSource() {
    //     if(saneDevice) delete saneDevice
    // }


    public func Entry(
        pOrigin: Twain.Identity,
        DG: Int,
        DAT: Int,
        message: Int,
        pData: Twain.MemoryReference) -> Int {

        self.origin = pOrigin

        if DG != DG_CONTROL || DAT != DAT_STATUS {
            self.twainStatus = TWCC_SUCCESS
        }

        switch DG {

            case DG_CONTROL:

                switch DAT {

                    case DAT_CAPABILITY:
                        return Capability(message, Twain.Capability(pData))

                    // case DAT_EVENT:
                    //     // Not applicable to Mac OS X
                    //     return SetStatus(TWCC_BADPROTOCOL)

                    case DAT_IDENTITY:
                        return Identity(message, Twain.Identity(pData))

                    case DAT_PENDINGXFERS:
                        return PendingTransfers(message, Twain.PendingTransfers(pData))

                    case DAT_SETUPMEMXFER:
                        return SetupMemoryTransfer(message, Twain.SetupMemoryTransfer(pData))

                    case DAT_STATUS:
                        return Status(message, Twain.Status(pData))

                    case DAT_USERINTERFACE:
                        return UserInterface(message, Twain.UserInterface(pData))

                    case DAT_XFERGROUP:
                        return TransferGroup(message, Int(pData))

                    case DAT_CUSTOMDSDATA:
                        return CustomDSData(message, Twain.CustomDSData(pData))

                    default:
                        return SetStatus(TWCC_BADPROTOCOL)
                }
                break

            case DG_IMAGE:

                switch DAT {

                    case DAT_IMAGEINFO:
                        return ImageInfo(message, Twain.ImageInfo(pData))

                    case DAT_IMAGELAYOUT:
                        return ImageLayout(message, Twain.ImageLayout(pData))

                    case DAT_IMAGEMEMXFER:
                        return ImageMemoryTransfer(message, Twain.ImageMemoryTransfer(pData))

                    case DAT_IMAGENATIVEXFER:
                        return ImageNativeTransfer(message, Int(pData))

                    case DAT_PALETTE8:
                        return Palette8(message, Twain.Palette8(pData))

                    default:
                        return SetStatus(TWCC_BADPROTOCOL)
                }

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    public func CallBack(message: Int) -> Int {

        var callback: TW_CALLBACK = [ nil, 0, message ]

        switch message {

            case MSG_XFERREADY:
                if state != STATE_5 {
                    return SetStatus(TWCC_SEQERROR)
                }
                state = STATE_6
                return DSM_Entry(
                    origin,
                    nil,
                    DG_CONTROL,
                    DAT_CALLBACK,
                    MSG_INVOKE_CALLBACK,
                    Twain.MemoryReference(callback))

            case MSG_CLOSEDSREQ:
                if state < STATE_5 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if self.uionly {
                    saneDevice.HideUI()
                    state = STATE_4
                } else {
                    state = STATE_5
                }
                return DSM_Entry(
                    origin,
                    nil,
                    DG_CONTROL,
                    DAT_CALLBACK,
                    MSG_INVOKE_CALLBACK,
                    Twain.MemoryReference(callback))

            case MSG_CLOSEDSOK:
                if state != STATE_5 {
                    return SetStatus(TWCC_SEQERROR)
                }
                saneDevice.HideUI()
                state = STATE_4
                return DSM_Entry(
                    origin,
                    nil,
                    DG_CONTROL,
                    DAT_CALLBACK,
                    MSG_INVOKE_CALLBACK,
                    Twain.MemoryReference(callback))

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func Capability(message: Int, capability: Twain.Capability) -> Int {

        switch message  {
            case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT || MSG_QUERYSUPPORT:
                if state < STATE_4 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }

            case MSG_SET || MSG_RESET:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }

        switch capability.Cap {
            case CAP_XFERCOUNT:
                switch message  {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT || MSG_RESET:
                        return BuildOneValue(capability, TWTY_INT16, Int(-1))

                    case MSG_SET:
                        if capability.ConType != TWON_ONEVALUE {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        if Twain.ONEVALUE(Handle(capability.hContainer).Item) != Int(-1) {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        return TWRC_SUCCESS

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_COMPRESSION:
                switch message {

                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            TWCP_NONE)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_PIXELTYPE:
                switch message {
                    case MSG_GET:
                        return saneDevice.GetPixelType(capability, false)

                    case MSG_GETCURRENT:
                        return saneDevice.GetPixelType(capability, true)

                    case MSG_GETDEFAULT:
                        return saneDevice.GetPixelTypeDefault(capability)

                    case MSG_SET:
                        return saneDevice.SetPixelType(capability)

                    case MSG_RESET:
                        return saneDevice.SetPixelType(nil)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_UNITS:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT || MSG_RESET:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            TWUN_INCHES)

                    case MSG_SET:
                        if capability.ConType != TWON_ONEVALUE {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        if Twain.ONEVALUE(Handle(capability.hContainer).Item) != TWUN_INCHES {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        return TWRC_SUCCESS

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_XFERMECH:
                switch message {
                    case MSG_GET: {
                        let mechs: Int = [ TWSX_NATIVE, TWSX_MEMORY ]
                        return BuildEnumeration(
                            capability,
                            TWTY_UINT16,
                            sizeof(mechs) / sizeof(Int),
                            (cap_XferMech == TWSX_NATIVE ? 0 : 1),
                            0,
                            mechs)
                    }

                    case MSG_GETCURRENT:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            cap_XferMech)

                    case MSG_GETDEFAULT:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            TWSX_NATIVE)

                    case MSG_SET:
                        if capability.ConType != TWON_ONEVALUE {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        self.cap_XferMech = Twain.ONEVALUE(Handle(capability.hContainer).Item)
                        if self.cap_XferMech != TWSX_NATIVE && self.cap_XferMech != TWSX_MEMORY {
                            self.cap_XferMech = TWSX_NATIVE
                            return TWRC_CHECKSTATUS
                        }
                        return TWRC_SUCCESS

                    case MSG_RESET:
                        self.cap_XferMech = TWSX_NATIVE
                        return BuildOneValue(
                            capability,
                            TWTY_INT16,
                            cap_XferMech)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case CAP_SUPPORTEDCAPS:
                switch message {
                    case MSG_GET: {
                        let caps: Int = [
                            CAP_XFERCOUNT,
                            ICAP_COMPRESSION,
                            ICAP_PIXELTYPE,
                            ICAP_UNITS,
                            ICAP_XFERMECH,
                            CAP_SUPPORTEDCAPS,
                            CAP_INDICATORS,
                            CAP_UICONTROLLABLE,
                            CAP_DEVICEONLINE,
                            CAP_ENABLEDSUIONLY,
                            ICAP_BRIGHTNESS,
                            ICAP_CONTRAST,
                            ICAP_PHYSICALWIDTH,
                            ICAP_PHYSICALHEIGHT,
                            ICAP_XNATIVERESOLUTION,
                            ICAP_YNATIVERESOLUTION,
                            ICAP_XRESOLUTION,
                            ICAP_YRESOLUTION,
                            ICAP_BITORDER,
                            ICAP_PIXELFLAVOR,
                            ICAP_PLANARCHUNKY,
                            ICAP_BITDEPTH
                        ]
                        return BuildArray(
                            capability,
                            TWTY_UINT16,
                            sizeof(caps) / sizeof(Int),
                            caps)
                    }

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case CAP_INDICATORS:
                switch message {
                    case MSG_GET || MSG_GETCURRENT:
                        return BuildOneValue(
                            capability,
                            TWTY_BOOL,
                            indicators)

                    case MSG_GETDEFAULT:
                        return BuildOneValue(
                            capability,
                            TWTY_BOOL,
                            true)

                    case MSG_SET:
                        if capability.ConType != TWON_ONEVALUE {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        self.indicators = Twain.ONEVALUE(Handle(capability.hContainer).Item)
                        return TWRC_SUCCESS

                    case MSG_RESET:
                        self.indicators = true
                        return BuildOneValue(
                            capability,
                            TWTY_BOOL,
                            indicators)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case CAP_UICONTROLLABLE:
                switch message {
                    case MSG_GET:
                        return BuildOneValue(
                            capability,
                            TWTY_BOOL,
                            true)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case CAP_DEVICEONLINE:
                switch message {
                    case MSG_GET:
                        return BuildOneValue(
                            capability,
                            TWTY_BOOL,
                            true)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case CAP_ENABLEDSUIONLY:
                switch message {
                    case MSG_GET:
                        return BuildOneValue(
                            capability,
                            TWTY_BOOL,
                            true)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_BRIGHTNESS:
                switch message {
                    case MSG_GET:
                        return saneDevice.GetBrightness(capability, false)

                    case MSG_GETCURRENT:
                        return saneDevice.GetBrightness(capability, true)

                    case MSG_GETDEFAULT:
                        return saneDevice.GetBrightnessDefault(capability)

                    case MSG_SET:
                        return saneDevice.SetBrightness(capability)

                    case MSG_RESET:
                        return saneDevice.SetBrightness(nil)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_CONTRAST:
                switch message {
                    case MSG_GET:
                        return saneDevice.GetContrast(capability, false)

                    case MSG_GETCURRENT:
                        return saneDevice.GetContrast(capability, true)

                    case MSG_GETDEFAULT:
                        return saneDevice.GetContrastDefault(capability)

                    case MSG_SET:
                        return saneDevice.SetContrast(capability)

                    case MSG_RESET:
                        return saneDevice.SetContrast(nil)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_PHYSICALWIDTH:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return saneDevice.GetPhysicalWidth(capability)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_PHYSICALHEIGHT:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return saneDevice.GetPhysicalHeight(capability)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_XNATIVERESOLUTION:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return saneDevice.GetXNativeResolution(capability)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_YNATIVERESOLUTION:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return saneDevice.GetYNativeResolution(capability)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_XRESOLUTION:
                switch message {
                    case MSG_GET:
                        return saneDevice.GetXResolution(capability, false)

                    case MSG_GETCURRENT:
                        return saneDevice.GetXResolution(capability, true)

                    case MSG_GETDEFAULT:
                        return saneDevice.GetXResolutionDefault(capability)

                    case MSG_SET:
                        return saneDevice.SetXResolution(capability)

                    case MSG_RESET:
                        return saneDevice.SetXResolution(nil)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_YRESOLUTION:
                switch(message) {
                    case MSG_GET:
                        return saneDevice.GetYResolution(capability, false)

                    case MSG_GETCURRENT:
                        return saneDevice.GetYResolution(capability, true)

                    case MSG_GETDEFAULT:
                        return saneDevice.GetYResolutionDefault(capability)

                    case MSG_SET:
                        return saneDevice.SetYResolution(capability)

                    case MSG_RESET:
                        return saneDevice.SetYResolution(nil)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_BITORDER:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT || MSG_RESET:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            TWBO_MSBFIRST)

                    case MSG_SET:
                        if capability.ConType != TWON_ONEVALUE {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        if Twain.ONEVALUE(Handle(capability.hContainer).Item) != TWBO_MSBFIRST {
                            return SetStatus(TWCC_BADVALUE)
                        }
                        return TWRC_SUCCESS

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            case ICAP_PIXELFLAVOR:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            TWPF_CHOCOLATE)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_PLANARCHUNKY:
                switch message {
                    case MSG_GET || MSG_GETCURRENT || MSG_GETDEFAULT:
                        return BuildOneValue(
                            capability,
                            TWTY_UINT16,
                            TWPC_CHUNKY)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_GETDEFAULT | TWQC_GETCURRENT)

                    default:
                        return SetStatus(TWCC_CAPBADOPERATION)
                }

            case ICAP_BITDEPTH:
                switch message {
                    case MSG_GET:
                        return saneDevice.GetBitDepth(capability, false)

                    case MSG_GETCURRENT:
                        return saneDevice.GetBitDepth(capability, true)

                    case MSG_GETDEFAULT:
                        return saneDevice.GetBitDepthDefault(capability)

                    case MSG_SET:
                        return saneDevice.SetBitDepth(capability)

                    case MSG_RESET:
                        return saneDevice.SetBitDepth(nil)

                    case MSG_QUERYSUPPORT:
                        return BuildOneValue(
                            capability,
                            TWTY_INT32,
                            TWQC_GET | TWQC_SET | TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET)

                    default:
                        // All cases handled
                        break
                }

            default:
                return SetStatus(TWCC_CAPUNSUPPORTED)
        }
    }


    private func Identity(message: Int, identity: Twain.Identity) -> Int {

        switch message {
            case MSG_GET:
                if state < STATE_3 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }

                var text: String

                let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

                var version: Int
                version = CFBundleGetVersionNumber(bundle)
                identity.Version.MajorNum =
                    10 * ((version & 0xF0000000) >> 28) + ((version & 0x0F000000) >> 24)
                identity.Version.MinorNum = (version & 0x00F00000) >> 20

                text = CFBundleCopyLocalizedString(bundle, CFSTR("twain-language"), nil, nil)
                identity.Version.Language = CFStringGetIntValue(text)
                CFRelease(text)
                text = CFBundleCopyLocalizedString(bundle, CFSTR("twain-country"), nil, nil)
                identity.Version.Country = CFStringGetIntValue(text)
                CFRelease(text)

                text = String(CFBundleGetValueForInfoDictionaryKey(bundle, CFSTR("CFBundleVersion")))
                CFStringGetPascalString(text, identity.Version.Info, sizeof(TW_STR32), kCFStringEncodingASCII)

                identity.ProtocolMajor = TWON_PROTOCOLMAJOR
                identity.ProtocolMinor = TWON_PROTOCOLMINOR
                identity.SupportedGroups = DG_CONTROL | DG_IMAGE

                // These can’t be localized and can only use ASCII
                // ... or the TWAINBridge used by Image Capture will refuse to use the interface
                // According to the TWAIN standard any string is localizable(using the locale’s default encoding)
                // ... but I guess Apple doesn’t read the standard the same way I do
                identity.Manufacturer = "Mattias Ellert"
                identity.ProductFamily = "SANE"
                identity.ProductName = "SANE" // This one is in the DeviceInfo.plist file

                return TWRC_SUCCESS

            case MSG_OPENDS:
                if state != STATE_3 {
                    return SetStatus(TWCC_SEQERROR)
                }
                self.saneDevice = SaneDevice(this)
                if !saneDevice {
                    return SetStatus(TWCC_LOWMEMORY)
                }
                if !saneDevice.GetSaneHandle() {
                    // Don’t put up the No Device alert when called from TWAINBridge
                    if !origin || strncasecmp(String(origin.ProductName), String("TWAINBridge"), 12) != 0 {
                        NoDevice()
                    }
                    // delete saneDevice
                    self.saneDevice = nil
                    return SetStatus(TWCC_OPERATIONERROR)
                }
                state = STATE_4
                return TWRC_SUCCESS

            case MSG_CLOSEDS:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }
                // if self.saneDevice {
                //     delete saneDevice
                // }
                self.saneDevice = nil
                state = STATE_3
                return TWRC_SUCCESS

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func PendingTransfers(message: Int, pendingTransfers: Twain.PendingTransfers) -> Int {
        switch message {
            case MSG_ENDXFER:
                if state < STATE_6 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if state == STATE_7 {
                    saneDevice.DequeueImage()
                }
                pendingTransfers.Count = (saneDevice.GetImage() ? 1 : 0)
                if pendingTransfers.Count != 0 {
                    state = STATE_6
                } else {
                    state = STATE_5
                }
                return TWRC_SUCCESS

            case MSG_GET:
                if state < STATE_4 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }
                pendingTransfers.Count = (saneDevice.GetImage() ? 1 : 0)
                return TWRC_SUCCESS

            case MSG_RESET:
                if state != STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                pendingTransfers.Count = 0
                state = STATE_5
                return TWRC_SUCCESS

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func SetupMemoryTransfer(message: Int, setupMemTransfer: Twain.SetupMemoryTransfer) -> Int {
        switch message {
            case MSG_GET:
                if state < STATE_4 || state > STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if state != STATE_6 {
                    setupMemTransfer.MinBufSize = TWON_DONTCARE32
                    setupMemTransfer.MaxBufSize = TWON_DONTCARE32
                    setupMemTransfer.Preferred = TWON_DONTCARE32
                    return TWRC_SUCCESS
                } else {
                    return saneDevice.GetImage().TwainSetupMemXfer(setupMemTransfer)
                }

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func Status(message: Int, status: Twain.Status) -> Int {
        switch message {
            case MSG_GET:
                if state < STATE_4 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }
                status.ConditionCode = twainStatus
                status.Reserved = 0
                self.twainStatus = TWCC_SUCCESS
                return TWRC_SUCCESS

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func UserInterface(message: Int, userInterface: Twain.UserInterface) -> Int {
        switch message {
            case MSG_DISABLEDS:
                if state != STATE_5 {
                    return SetStatus(TWCC_SEQERROR)
                }
                saneDevice.HideUI()
                state = STATE_4
                return TWRC_SUCCESS

            case MSG_ENABLEDS:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }
                self.uionly = false
                if userInterface.ShowUI {
                    saneDevice.ShowUI(uionly)
                    userInterface.ModalUI = false
                }
                state = STATE_5
                if !userInterface.ShowUI {
                    if saneDevice.Scan(true, indicators) {
                        CallBack(MSG_XFERREADY)
                    } else {
                        return SetStatus(TWCC_OPERATIONERROR)
                    }
                }
                return TWRC_SUCCESS

            case MSG_ENABLEDSUIONLY:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }
                self.uionly = true
                saneDevice.ShowUI(uionly)
                userInterface.ModalUI = false
                state = STATE_5
                return TWRC_SUCCESS

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func TransferGroup(message: Int, transferGroup: Int) -> Int {
        switch message {
            case MSG_GET:
                if state < STATE_4 || state > STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                *transferGroup = DG_IMAGE
                return TWRC_SUCCESS

            case MSG_SET:
                if state != STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if *transferGroup != DG_IMAGE {
                    return SetStatus(TWCC_BADPROTOCOL)
                }
                return TWRC_SUCCESS

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func CustomDSData(message: Int, customDSData: Twain.CustomDSData) -> Int {
        switch message {
            case MSG_GET:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }
                return saneDevice.GetCustomData(customDSData)

            case MSG_SET:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }
                return saneDevice.SetCustomData(customDSData)

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func ImageInfo(message: Int, imageInfo: Twain.ImageInfo) -> Int {
        switch(message) {
            case MSG_GET:
                if state < STATE_6 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }
                return saneDevice.GetImage().TwainImageInfo(imageInfo)

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func ImageLayout(message: Int, imageLayout: Twain.ImageLayout) -> Int {
        switch message {
            case MSG_GET:
                if state < STATE_4 || state > STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if saneDevice.GetImage() {
                    return saneDevice.GetImage().TwainImageLayout(imageLayout)
                }
                return saneDevice.GetLayout(imageLayout)

            case MSG_SET:
                if state != STATE_4 {
                    return SetStatus(TWCC_SEQERROR)
                }
                return saneDevice.SetLayout(imageLayout)

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func ImageMemoryTransfer(message: Int, imageMemoryTransfer: Twain.ImageMemoryTransfer) -> Int {
        switch message {
            case MSG_GET:
                if state < STATE_6 || state > STATE_7 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if state == STATE_6 {
                    state = STATE_7
                    self.writtenlines = 0
                }
                return saneDevice.GetImage().TwainImageMemXfer(imageMemoryTransfer, &writtenlines)

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func ImageNativeTransfer(message: Int, handle: Int) -> Int {
        switch message {
            case MSG_GET:
                if state != STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                if !saneDevice.GetImage() {
                    return SetStatus(TWCC_SEQERROR)
                }
                handle = Int(saneDevice.GetImage().MakePict())
                state = STATE_7
                return TWRC_XFERDONE

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    private func Palette8(message: Int, palette8: Twain.Palette8) -> Int {
        switch message {
            case MSG_GET:
                if state < STATE_4 || state > STATE_6 {
                    return SetStatus(TWCC_SEQERROR)
                }
                return saneDevice.GetImage().TwainPalette8(palette8, &twainStatus)

            default:
                return SetStatus(TWCC_BADPROTOCOL)
        }
    }


    static let ItemSize: Int = [
        sizeof(TW_INT8),
        sizeof(TW_INT16),
        sizeof(TWTY_INT8),
        sizeof(TWTY_INT16),
        sizeof(TWTY_INT32),
        sizeof(TWTY_UINT8),
        sizeof(TWTY_UINT16),
        sizeof(TWTY_UINT32),
        sizeof(TWTY_BOOL),
        sizeof(TWTY_FIX32),
        sizeof(TWTY_FRAME),
        sizeof(TWTY_STR32),
        sizeof(TWTY_STR64),
        sizeof(TWTY_STR128),
        sizeof(TWTY_STR255),
        sizeof(TWTY_STR1024),
        sizeof(TWTY_UNI512),
    ]


    public func BuildArray(capability: Twain.Capability, type: Int, numItems: Int,
                            values: any) -> Int {

        capability.hContainer = TW_HANDLE(NewHandle(sizeof(TW_ARRAY) - sizeof(TW_UINT8) +
                                            numItems * ItemSize[type]))
        if !capability.hContainer {
            return SetStatus(TWCC_LOWMEMORY)
        }

        capability.ConType = TWON_ARRAY

        HLock(Handle(capability).hContainer)
        let pArray: Twain.ARRAY = Twain.ARRAY(Handle(capability.hContainer))
        pArray.ItemType = type
        pArray.NumItems = numItems
        memcpy(pArray.ItemList, values, numItems * ItemSize[type])
        HUnlock(Handle(capability).hContainer)

        return TWRC_SUCCESS
    }


    public func BuildEnumeration(capability: Twain.Capability, type: Int, numItems: Int,
                                    currentIndex: Int, defaultIndex: Int, values: any) -> Int {

        capability.hContainer = TW_HANDLE(NewHandle(sizeof(TW_ENUMERATION) - sizeof(TW_UINT8) +
                                            numItems * ItemSize[type]))
        if !capability.hContainer {
            return SetStatus(TWCC_LOWMEMORY)
        }

        capability.ConType = TWON_ENUMERATION

        HLock(Handle(capability).hContainer)
        var pEnumeration: Twain.ENUMERATION = Twain.ENUMERATION(Handle(capability).hContainer)
        pEnumeration.ItemType = type
        pEnumeration.NumItems = numItems
        pEnumeration.CurrentIndex = currentIndex
        pEnumeration.DefaultIndex = defaultIndex
        memcpy(pEnumeration.ItemList, values, numItems * ItemSize[type])
        HUnlock(Handle(capability).hContainer)

        return TWRC_SUCCESS
    }


    public func BuildOneValue(capability: Twain.Capability, type: Int, value: Int) -> Int {

        capability.hContainer = TW_HANDLE(NewHandle(sizeof(TW_ONEVALUE)))
        if !capability.hContainer {
            return SetStatus(TWCC_LOWMEMORY)
        }

        capability.ConType = TWON_ONEVALUE

        HLock(Handle(capability).hContainer)
        var pOneValue: Twain.ONEVALUE = Twain.ONEVALUE(Handle(capability).hContainer)
        pOneValue.ItemType = type
        pOneValue.Item = value
        HUnlock(Handle(capability).hContainer)

        return TWRC_SUCCESS
    }


    public func BuildOneValue(capability: Twain.Capability, type: Int, value: Twain.Fix32) -> Int {
        capability.hContainer = TW_HANDLE(NewHandle(sizeof(TW_ONEVALUE)))
        if !capability.hContainer {
            return SetStatus(TWCC_LOWMEMORY)
        }

        capability.ConType = TWON_ONEVALUE

        HLock(Handle(capability).hContainer)
        var pOneValue: Twain.ONEVALUE = Twain.ONEVALUE(Handle(capability).hContainer)
        pOneValue.ItemType = type
        pOneValue.Item = Int(value)
        HUnlock(Handle(capability).hContainer)

        return TWRC_SUCCESS
    }


    public func BuildRange(capability: Twain.Capability, type: Int, min: Int, max: Int,
                            step: Int, defaultValue: Int, value: Int) -> Int {

        capability.hContainer = TW_HANDLE(NewHandle(sizeof(TW_RANGE)))
        if !capability.hContainer {
            return SetStatus(TWCC_LOWMEMORY)
        }

        capability.ConType = TWON_RANGE

        HLock(Handle(capability).hContainer)
        var pRange: Twain.RANGE = Twain.RANGE(Handle(capability).hContainer)
        pRange.ItemType = type
        pRange.MinValue = min
        pRange.MaxValue = max
        pRange.StepSize = step
        pRange.DefaultValue = defaultValue
        pRange.CurrentValue = value
        HUnlock(Handle(capability).hContainer)

        return TWRC_SUCCESS
    }


    public func BuildRange(capability: Twain.Capability, type: Int, min: Twain.Fix32, max: Twain.Fix32,
                            step: Twain.Fix32, defaultValue: Twain.Fix32, value: Twain.Fix32) -> Int {

        capability.hContainer = TW_HANDLE(NewHandle(sizeof(TW_RANGE)))
        if !capability.hContainer {
            return SetStatus(TWCC_LOWMEMORY)
        }

        capability.ConType = TWON_RANGE

        HLock(Handle(capability).hContainer)
        var pRange: Twain.RANGE = Twain.RANGE(Handle(capability).hContainer)
        pRange.ItemType = type
        pRange.MinValue = Int(min)
        pRange.MaxValue = Int(max)
        pRange.StepSize = Int(step)
        pRange.DefaultValue = Int(defaultValue)
        pRange.CurrentValue = Int(value)
        HUnlock(Handle(capability).hContainer)

        return TWRC_SUCCESS
    }


    public func SetStatus(status: Int, returnValue: Int = Twain.RcFailure) -> Int {
        self.twainStatus = status
        return returnValue
    }

}