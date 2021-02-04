#include <Carbon/Carbon.h>
#include <TWAIN/TWAIN.h>

#include "DataSource.h"
#include "SaneDevice.h"
#include "Image.h"
#include "Alerts.h"


DataSource::DataSource () : origin (NULL),
                            sanedevice (NULL),
                            twainstatus (TWCC_SUCCESS),
                            state (STATE_3),
                            cap_XferMech (TWSX_NATIVE),
                            indicators (true) {}


DataSource::~DataSource () {

    if (sanedevice) delete sanedevice;
}


TW_UINT16 DataSource::Entry (pTW_IDENTITY pOrigin,
                             TW_UINT32    DG,
                             TW_UINT16    DAT,
                             TW_UINT16    MSG,
                             TW_MEMREF    pData) {

    origin = pOrigin;

    if (DG != DG_CONTROL || DAT != DAT_STATUS) twainstatus = TWCC_SUCCESS;

    switch (DG) {

        case DG_CONTROL:

            switch (DAT) {

                case DAT_CAPABILITY:

                    return Capability (MSG, (pTW_CAPABILITY) pData);
                    break;
/*
                case DAT_EVENT:

                    // Not applicable to Mac OS X
                    return SetStatus (TWCC_BADPROTOCOL);
                    break;
*/
                case DAT_IDENTITY:

                    return Identity (MSG, (pTW_IDENTITY) pData);
                    break;

                case DAT_PENDINGXFERS:

                    return PendingXfers (MSG, (pTW_PENDINGXFERS) pData);
                    break;

                case DAT_SETUPMEMXFER:

                    return SetupMemXfer (MSG, (pTW_SETUPMEMXFER) pData);
                    break;

                case DAT_STATUS:

                    return Status (MSG, (pTW_STATUS) pData);
                    break;

                case DAT_USERINTERFACE:

                    return UserInterface (MSG, (pTW_USERINTERFACE) pData);
                    break;

                case DAT_XFERGROUP:

                    return XferGroup (MSG, (pTW_UINT32) pData);
                    break;

                case DAT_CUSTOMDSDATA:

                    return CustomDSData (MSG, (pTW_CUSTOMDSDATA) pData);
                    break;

                default:

                    return SetStatus (TWCC_BADPROTOCOL);
                    break;
            }
            break;

        case DG_IMAGE:

            switch (DAT) {

                case DAT_IMAGEINFO:

                    return ImageInfo (MSG, (pTW_IMAGEINFO) pData);
                    break;

                case DAT_IMAGELAYOUT:

                    return ImageLayout (MSG, (pTW_IMAGELAYOUT) pData);
                    break;

                case DAT_IMAGEMEMXFER:

                    return ImageMemXfer (MSG, (pTW_IMAGEMEMXFER) pData);
                    break;

                case DAT_IMAGENATIVEXFER:

                    return ImageNativeXfer (MSG, (pTW_UINT32) pData);
                    break;

                case DAT_PALETTE8:

                    return Palette8 (MSG, (pTW_PALETTE8) pData);
                    break;

                default:

                    return SetStatus (TWCC_BADPROTOCOL);
                    break;
            }
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::CallBack (TW_UINT16 MSG) {

    TW_CALLBACK callback = { NULL, 0, MSG };

    switch (MSG) {

        case MSG_XFERREADY:

            if (state != STATE_5) return SetStatus (TWCC_SEQERROR);
            state = STATE_6;
            return DSM_Entry (origin, NULL, DG_CONTROL, DAT_CALLBACK,
                              MSG_INVOKE_CALLBACK, (TW_MEMREF) &callback);
            break;

        case MSG_CLOSEDSREQ:

            if (state < STATE_5 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            if (uionly) {
                sanedevice->HideUI ();
                state = STATE_4;
            }
            else
                state = STATE_5;
            return DSM_Entry (origin, NULL, DG_CONTROL, DAT_CALLBACK,
                              MSG_INVOKE_CALLBACK, (TW_MEMREF) &callback);
            break;

        case MSG_CLOSEDSOK:

            if (state != STATE_5) return SetStatus (TWCC_SEQERROR);
            sanedevice->HideUI ();
            state = STATE_4;
            return DSM_Entry (origin, NULL, DG_CONTROL, DAT_CALLBACK,
                              MSG_INVOKE_CALLBACK, (TW_MEMREF) &callback);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::Capability (TW_UINT16 MSG, pTW_CAPABILITY capability) {

    switch (MSG) {

        case MSG_GET:
        case MSG_GETCURRENT:
        case MSG_GETDEFAULT:
        case MSG_QUERYSUPPORT:

            if (state < STATE_4 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            break;

        case MSG_SET:
        case MSG_RESET:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }

    switch (capability->Cap) {

        case CAP_XFERCOUNT:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:
                case MSG_RESET:

                    return BuildOneValue (capability, TWTY_INT16, (TW_UINT32) -1);
                    break;

                case MSG_SET:

                    if (capability->ConType != TWON_ONEVALUE) return SetStatus (TWCC_BADVALUE);
                    if (((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item != (TW_UINT32) -1)
                        return SetStatus (TWCC_BADVALUE);
                    return TWRC_SUCCESS;
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_COMPRESSION:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return BuildOneValue (capability, TWTY_UINT16, TWCP_NONE);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_PIXELTYPE:

            switch (MSG) {

                case MSG_GET:

                    return sanedevice->GetPixelType (capability, false);
                    break;

                case MSG_GETCURRENT:

                    return sanedevice->GetPixelType (capability, true);
                    break;

                case MSG_GETDEFAULT:

                    return sanedevice->GetPixelTypeDefault (capability);
                    break;

                case MSG_SET:

                    return sanedevice->SetPixelType (capability);
                    break;

                case MSG_RESET:

                    return sanedevice->SetPixelType (NULL);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_UNITS:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:
                case MSG_RESET:

                    return BuildOneValue (capability, TWTY_UINT16, TWUN_INCHES);
                    break;

                case MSG_SET:

                    if (capability->ConType != TWON_ONEVALUE) return SetStatus (TWCC_BADVALUE);
                    if (((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item != TWUN_INCHES)
                        return SetStatus (TWCC_BADVALUE);
                    return TWRC_SUCCESS;
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_XFERMECH:

            switch (MSG) {

                case MSG_GET: {

                    TW_UINT16 mechs [] =  { TWSX_NATIVE, TWSX_MEMORY };
                    return BuildEnumeration (capability, TWTY_UINT16,
                                             sizeof (mechs) / sizeof (TW_UINT16),
                                             (cap_XferMech == TWSX_NATIVE ? 0 : 1), 0, mechs);
                    break;
                }

                case MSG_GETCURRENT:

                    return BuildOneValue (capability, TWTY_UINT16, cap_XferMech);
                    break;

                case MSG_GETDEFAULT:

                    return BuildOneValue (capability, TWTY_UINT16, TWSX_NATIVE);
                    break;

                case MSG_SET:

                    if (capability->ConType != TWON_ONEVALUE) return SetStatus (TWCC_BADVALUE);
                    cap_XferMech = ((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item;
                    if (cap_XferMech != TWSX_NATIVE && cap_XferMech != TWSX_MEMORY) {
                        cap_XferMech = TWSX_NATIVE;
                        return TWRC_CHECKSTATUS;
                    }
                    return TWRC_SUCCESS;
                    break;

                case MSG_RESET:

                    cap_XferMech = TWSX_NATIVE;
                    return BuildOneValue (capability, TWTY_INT16, cap_XferMech);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case CAP_SUPPORTEDCAPS:

            switch (MSG) {

                case MSG_GET: {

                    TW_UINT16 caps [] = {
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
                    };
                    return BuildArray (capability, TWTY_UINT16,
                                       sizeof (caps) / sizeof (TW_UINT16), caps);
                    break;
                }

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case CAP_INDICATORS:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:

                    return BuildOneValue (capability, TWTY_BOOL, indicators);
                    break;

                case MSG_GETDEFAULT:

                    return BuildOneValue (capability, TWTY_BOOL, true);
                    break;

                case MSG_SET:

                    if (capability->ConType != TWON_ONEVALUE) return SetStatus (TWCC_BADVALUE);
                    indicators = ((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item;
                    return TWRC_SUCCESS;
                    break;

                case MSG_RESET:

                    indicators = true;
                    return BuildOneValue (capability, TWTY_BOOL, indicators);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case CAP_UICONTROLLABLE:

            switch (MSG) {

                case MSG_GET:

                    return BuildOneValue (capability, TWTY_BOOL, true);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case CAP_DEVICEONLINE:

            switch (MSG) {

                case MSG_GET:

                    return BuildOneValue (capability, TWTY_BOOL, true);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case CAP_ENABLEDSUIONLY:

            switch (MSG) {

                case MSG_GET:

                    return BuildOneValue (capability, TWTY_BOOL, true);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_BRIGHTNESS:

            switch (MSG) {

                case MSG_GET:

                    return sanedevice->GetBrightness (capability, false);
                    break;

                case MSG_GETCURRENT:

                    return sanedevice->GetBrightness (capability, true);
                    break;

                case MSG_GETDEFAULT:

                    return sanedevice->GetBrightnessDefault (capability);
                    break;

                case MSG_SET:

                    return sanedevice->SetBrightness (capability);
                    break;

                case MSG_RESET:

                    return sanedevice->SetBrightness (NULL);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_CONTRAST:

            switch (MSG) {

                case MSG_GET:

                    return sanedevice->GetContrast (capability, false);
                    break;

                case MSG_GETCURRENT:

                    return sanedevice->GetContrast (capability, true);
                    break;

                case MSG_GETDEFAULT:

                    return sanedevice->GetContrastDefault (capability);
                    break;

                case MSG_SET:

                    return sanedevice->SetContrast (capability);
                    break;

                case MSG_RESET:

                    return sanedevice->SetContrast (NULL);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_PHYSICALWIDTH:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return sanedevice->GetPhysicalWidth (capability);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_PHYSICALHEIGHT:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return sanedevice->GetPhysicalHeight (capability);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_XNATIVERESOLUTION:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return sanedevice->GetXNativeResolution (capability);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_YNATIVERESOLUTION:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return sanedevice->GetYNativeResolution (capability);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_XRESOLUTION:

            switch (MSG) {

                case MSG_GET:

                    return sanedevice->GetXResolution (capability, false);
                    break;

                case MSG_GETCURRENT:

                    return sanedevice->GetXResolution (capability, true);
                    break;

                case MSG_GETDEFAULT:

                    return sanedevice->GetXResolutionDefault (capability);
                    break;

                case MSG_SET:

                    return sanedevice->SetXResolution (capability);
                    break;

                case MSG_RESET:

                    return sanedevice->SetXResolution (NULL);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_YRESOLUTION:

            switch (MSG) {

                case MSG_GET:

                    return sanedevice->GetYResolution (capability, false);
                    break;

                case MSG_GETCURRENT:

                    return sanedevice->GetYResolution (capability, true);
                    break;

                case MSG_GETDEFAULT:

                    return sanedevice->GetYResolutionDefault (capability);
                    break;

                case MSG_SET:

                    return sanedevice->SetYResolution (capability);
                    break;

                case MSG_RESET:

                    return sanedevice->SetYResolution (NULL);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_BITORDER:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:
                case MSG_RESET:

                    return BuildOneValue (capability, TWTY_UINT16, TWBO_MSBFIRST);
                    break;

                case MSG_SET:

                    if (capability->ConType != TWON_ONEVALUE) return SetStatus (TWCC_BADVALUE);
                    if (((pTW_ONEVALUE) *(Handle) capability->hContainer)->Item != TWBO_MSBFIRST)
                        return SetStatus (TWCC_BADVALUE);
                    return TWRC_SUCCESS;
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        case ICAP_PIXELFLAVOR:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return BuildOneValue (capability, TWTY_UINT16, TWPF_CHOCOLATE);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_PLANARCHUNKY:

            switch (MSG) {

                case MSG_GET:
                case MSG_GETCURRENT:
                case MSG_GETDEFAULT:

                    return BuildOneValue (capability, TWTY_UINT16, TWPC_CHUNKY);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT);
                    break;

                default:

                    return SetStatus (TWCC_CAPBADOPERATION);
                    break;
            }

        case ICAP_BITDEPTH:

            switch (MSG) {

                case MSG_GET:

                    return sanedevice->GetBitDepth (capability, false);
                    break;

                case MSG_GETCURRENT:

                    return sanedevice->GetBitDepth (capability, true);
                    break;

                case MSG_GETDEFAULT:

                    return sanedevice->GetBitDepthDefault (capability);
                    break;

                case MSG_SET:

                    return sanedevice->SetBitDepth (capability);
                    break;

                case MSG_RESET:

                    return sanedevice->SetBitDepth (NULL);
                    break;

                case MSG_QUERYSUPPORT:

                    return BuildOneValue (capability, TWTY_INT32, TWQC_GET | TWQC_SET |
                                          TWQC_GETDEFAULT | TWQC_GETCURRENT | TWQC_RESET);
                    break;

                default:
                    // All cases handled
                    break;
            }

        default:

            return SetStatus (TWCC_CAPUNSUPPORTED);
            break;
    }
}


TW_UINT16 DataSource::Identity (TW_UINT16 MSG, pTW_IDENTITY identity) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_3 || state > STATE_7) return SetStatus (TWCC_SEQERROR);

            CFStringRef text;

            CFBundleRef bundle;
            bundle = CFBundleGetBundleWithIdentifier (BNDLNAME);

            UInt32 version;
            version = CFBundleGetVersionNumber (bundle);
            identity->Version.MajorNum =
                10 * ((version & 0xF0000000) >> 28) + ((version & 0x0F000000) >> 24);
            identity->Version.MinorNum = (version & 0x00F00000) >> 20;

            text = CFBundleCopyLocalizedString (bundle, CFSTR ("twain-language"), NULL, NULL);
            identity->Version.Language = CFStringGetIntValue (text);
            CFRelease (text);
            text = CFBundleCopyLocalizedString (bundle, CFSTR ("twain-country"), NULL, NULL);
            identity->Version.Country = CFStringGetIntValue (text);
            CFRelease (text);

            text = (CFStringRef) CFBundleGetValueForInfoDictionaryKey (bundle, CFSTR ("CFBundleVersion"));
            CFStringGetPascalString (text, identity->Version.Info, sizeof (TW_STR32), kCFStringEncodingASCII);

            identity->ProtocolMajor = TWON_PROTOCOLMAJOR;
            identity->ProtocolMinor = TWON_PROTOCOLMINOR;
            identity->SupportedGroups = DG_CONTROL | DG_IMAGE;

            // These can’t be localized and can only use ASCII
            // ... or the TWAINBridge used by Image Capture will refuse to use the interface
            // According to the TWAIN standard any string is localizable (using the locale’s default encoding)
            // ... but I guess Apple doesn’t read the standard the same way I do
            strcpy ((char *) identity->Manufacturer, (char *) "\pMattias Ellert");
            strcpy ((char *) identity->ProductFamily, (char *) "\pSANE");
            strcpy ((char *) identity->ProductName, (char *) "\pSANE"); // This one is in the DeviceInfo.plist file

            return TWRC_SUCCESS;
            break;

        case MSG_OPENDS:

            if (state != STATE_3) return SetStatus (TWCC_SEQERROR);
            sanedevice = new SaneDevice (this);
            if (!sanedevice) return SetStatus (TWCC_LOWMEMORY);
            if (!sanedevice->GetSaneHandle ()) {
                // Don’t put up the No Device alert when called from TWAINBridge
                if (!origin || strncasecmp ((char *) origin->ProductName, (char *) "\pTWAINBridge", 12) != 0)
                    NoDevice ();
                delete sanedevice;
                sanedevice = NULL;
                return SetStatus (TWCC_OPERATIONERROR);
            }
            state = STATE_4;
            return TWRC_SUCCESS;
            break;

        case MSG_CLOSEDS:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            if (sanedevice) delete sanedevice;
            sanedevice = NULL;
            state = STATE_3;
            return TWRC_SUCCESS;
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::PendingXfers (TW_UINT16 MSG, pTW_PENDINGXFERS pendingxfers) {

    switch (MSG) {

        case MSG_ENDXFER:

            if (state < STATE_6 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            if (state == STATE_7) sanedevice->DequeueImage ();
            pendingxfers->Count = (sanedevice->GetImage () ? 1 : 0);
            if (pendingxfers->Count != 0)
                state = STATE_6;
            else
                state = STATE_5;
            return TWRC_SUCCESS;
            break;

        case MSG_GET:

            if (state < STATE_4 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            pendingxfers->Count = (sanedevice->GetImage () ? 1 : 0);
            return TWRC_SUCCESS;
            break;

        case MSG_RESET:

            if (state != STATE_6) return SetStatus (TWCC_SEQERROR);
            pendingxfers->Count = 0;
            state = STATE_5;
            return TWRC_SUCCESS;
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::SetupMemXfer (TW_UINT16 MSG, pTW_SETUPMEMXFER setupmemxfer) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_4 || state > STATE_6) return SetStatus (TWCC_SEQERROR);
            if (state != STATE_6) {
                setupmemxfer->MinBufSize = TWON_DONTCARE32;
                setupmemxfer->MaxBufSize = TWON_DONTCARE32;
                setupmemxfer->Preferred = TWON_DONTCARE32;
                return TWRC_SUCCESS;
            }
            else
                return sanedevice->GetImage()->TwainSetupMemXfer (setupmemxfer);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::Status (TW_UINT16 MSG, pTW_STATUS status) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_4 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            status->ConditionCode = twainstatus;
            status->Reserved = 0;
            twainstatus = TWCC_SUCCESS;
            return TWRC_SUCCESS;
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::UserInterface (TW_UINT16 MSG, pTW_USERINTERFACE userinterface) {

    switch (MSG) {

        case MSG_DISABLEDS:

            if (state != STATE_5) return SetStatus (TWCC_SEQERROR);
            sanedevice->HideUI ();
            state = STATE_4;
            return TWRC_SUCCESS;
            break;

        case MSG_ENABLEDS:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            uionly = false;
            if (userinterface->ShowUI) {
                sanedevice->ShowUI (uionly);
                userinterface->ModalUI = false;
            }
            state = STATE_5;
            if (!userinterface->ShowUI) {
                if (sanedevice->Scan (true, indicators))
                    CallBack (MSG_XFERREADY);
                else
                    return SetStatus (TWCC_OPERATIONERROR);
            }
            return TWRC_SUCCESS;
            break;

        case MSG_ENABLEDSUIONLY:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            uionly = true;
            sanedevice->ShowUI (uionly);
            userinterface->ModalUI = false;
            state = STATE_5;
            return TWRC_SUCCESS;
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::XferGroup (TW_UINT16 MSG, pTW_UINT32 xfergroup) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_4 || state > STATE_6) return SetStatus (TWCC_SEQERROR);
            *xfergroup = DG_IMAGE;
            return TWRC_SUCCESS;
            break;

        case MSG_SET:

            if (state != STATE_6) return SetStatus (TWCC_SEQERROR);
            if (*xfergroup != DG_IMAGE) return SetStatus (TWCC_BADPROTOCOL);
            return TWRC_SUCCESS;
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::CustomDSData (TW_UINT16 MSG, pTW_CUSTOMDSDATA customdsdata) {

    switch (MSG) {

        case MSG_GET:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            return sanedevice->GetCustomData (customdsdata);
            break;

        case MSG_SET:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            return sanedevice->SetCustomData (customdsdata);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::ImageInfo (TW_UINT16 MSG, pTW_IMAGEINFO imageinfo) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_6 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            return sanedevice->GetImage()->TwainImageInfo (imageinfo);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::ImageLayout (TW_UINT16 MSG, pTW_IMAGELAYOUT imagelayout) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_4 || state > STATE_6) return SetStatus (TWCC_SEQERROR);
            if (sanedevice->GetImage()) return sanedevice->GetImage()->TwainImageLayout (imagelayout);
            return sanedevice->GetLayout (imagelayout);
            break;

        case MSG_SET:

            if (state != STATE_4) return SetStatus (TWCC_SEQERROR);
            return sanedevice->SetLayout (imagelayout);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::ImageMemXfer (TW_UINT16 MSG, pTW_IMAGEMEMXFER imagememxfer) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_6 || state > STATE_7) return SetStatus (TWCC_SEQERROR);
            if (state == STATE_6) {
                state = STATE_7;
                writtenlines = 0;
            }
            return sanedevice->GetImage()->TwainImageMemXfer (imagememxfer, &writtenlines);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::ImageNativeXfer (TW_UINT16 MSG, pTW_UINT32 handle) {

    switch (MSG) {

        case MSG_GET:

            if (state != STATE_6) return SetStatus (TWCC_SEQERROR);
            if (!sanedevice->GetImage ()) return SetStatus (TWCC_SEQERROR);
            *handle = (TW_UINT32) sanedevice->GetImage ()->MakePict ();
            state = STATE_7;
            return TWRC_XFERDONE;
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


TW_UINT16 DataSource::Palette8 (TW_UINT16 MSG, pTW_PALETTE8 palette8) {

    switch (MSG) {

        case MSG_GET:

            if (state < STATE_4 || state > STATE_6) return SetStatus (TWCC_SEQERROR);
            return sanedevice->GetImage()->TwainPalette8 (palette8, &twainstatus);
            break;

        default:

            return SetStatus (TWCC_BADPROTOCOL);
            break;
    }
}


static const short ItemSize[] = {
    sizeof (TW_INT8),
    sizeof (TW_INT16),
    sizeof (TWTY_INT8),
    sizeof (TWTY_INT16),
    sizeof (TWTY_INT32),
    sizeof (TWTY_UINT8),
    sizeof (TWTY_UINT16),
    sizeof (TWTY_UINT32),
    sizeof (TWTY_BOOL),
    sizeof (TWTY_FIX32),
    sizeof (TWTY_FRAME),
    sizeof (TWTY_STR32),
    sizeof (TWTY_STR64),
    sizeof (TWTY_STR128),
    sizeof (TWTY_STR255),
    sizeof (TWTY_STR1024),
    sizeof (TWTY_UNI512),
};


TW_UINT16 DataSource::BuildArray (pTW_CAPABILITY capability, TW_UINT16 type,
                                  TW_UINT32 numItems, void * values) {

    capability->hContainer = (TW_HANDLE) NewHandle (sizeof (TW_ARRAY) - sizeof (TW_UINT8) +
                                        numItems * ItemSize [type]);
    if (!capability->hContainer) return SetStatus (TWCC_LOWMEMORY);

    capability->ConType = TWON_ARRAY;

    HLock ((Handle) capability->hContainer);
    pTW_ARRAY pArray = (pTW_ARRAY) *(Handle) capability->hContainer;
    pArray->ItemType = type;
    pArray->NumItems = numItems;
    memcpy (pArray->ItemList, values, numItems * ItemSize [type]);
    HUnlock ((Handle) capability->hContainer);

    return TWRC_SUCCESS;
}


TW_UINT16 DataSource::BuildEnumeration (pTW_CAPABILITY capability, TW_UINT16 type,
                                        TW_UINT32 numItems, TW_UINT32 currentIndex,
                                        TW_UINT32 defaultIndex, void * values) {

    capability->hContainer = (TW_HANDLE) NewHandle (sizeof (TW_ENUMERATION) - sizeof (TW_UINT8) +
                                        numItems * ItemSize [type]);
    if (!capability->hContainer) return SetStatus (TWCC_LOWMEMORY);

    capability->ConType = TWON_ENUMERATION;

    HLock ((Handle) capability->hContainer);
    pTW_ENUMERATION pEnumeration = (pTW_ENUMERATION) *(Handle) capability->hContainer;
    pEnumeration->ItemType = type;
    pEnumeration->NumItems = numItems;
    pEnumeration->CurrentIndex = currentIndex;
    pEnumeration->DefaultIndex = defaultIndex;
    memcpy (pEnumeration->ItemList, values, numItems * ItemSize [type]);
    HUnlock ((Handle) capability->hContainer);

    return TWRC_SUCCESS;
}


TW_UINT16 DataSource::BuildOneValue (pTW_CAPABILITY capability, TW_UINT16 type, TW_UINT32 value) {

    capability->hContainer = (TW_HANDLE) NewHandle (sizeof (TW_ONEVALUE));
    if (!capability->hContainer) return SetStatus (TWCC_LOWMEMORY);

    capability->ConType = TWON_ONEVALUE;

    HLock ((Handle) capability->hContainer);
    pTW_ONEVALUE pOneValue = (pTW_ONEVALUE) *(Handle) capability->hContainer;
    pOneValue->ItemType = type;
    pOneValue->Item = value;
    HUnlock ((Handle) capability->hContainer);

    return TWRC_SUCCESS;
}


TW_UINT16 DataSource::BuildOneValue (pTW_CAPABILITY capability, TW_UINT16 type, TW_FIX32 value) {

    capability->hContainer = (TW_HANDLE) NewHandle (sizeof (TW_ONEVALUE));
    if (!capability->hContainer) return SetStatus (TWCC_LOWMEMORY);

    capability->ConType = TWON_ONEVALUE;

    HLock ((Handle) capability->hContainer);
    pTW_ONEVALUE pOneValue = (pTW_ONEVALUE) *(Handle) capability->hContainer;
    pOneValue->ItemType = type;
    pOneValue->Item = *((TW_UINT32*) &value);
    HUnlock ((Handle) capability->hContainer);

    return TWRC_SUCCESS;
}


TW_UINT16 DataSource::BuildRange (pTW_CAPABILITY capability, TW_UINT16 type,
                                  TW_UINT32 min, TW_UINT32 max, TW_UINT32 step,
                                  TW_UINT32 defvalue, TW_UINT32 value) {

    capability->hContainer = (TW_HANDLE) NewHandle (sizeof(TW_RANGE));
    if (!capability->hContainer) return SetStatus (TWCC_LOWMEMORY);

    capability->ConType = TWON_RANGE;

    HLock ((Handle) capability->hContainer);
    pTW_RANGE pRange = (pTW_RANGE) *(Handle) capability->hContainer;
    pRange->ItemType = type;
    pRange->MinValue = min;
    pRange->MaxValue = max;
    pRange->StepSize = step;
    pRange->DefaultValue = defvalue;
    pRange->CurrentValue = value;
    HUnlock ((Handle) capability->hContainer);

    return TWRC_SUCCESS;
}


TW_UINT16 DataSource::BuildRange (pTW_CAPABILITY capability, TW_UINT16 type,
                                  TW_FIX32 min, TW_FIX32 max, TW_FIX32 step,
                                  TW_FIX32 defvalue, TW_FIX32 value) {

    capability->hContainer = (TW_HANDLE) NewHandle (sizeof(TW_RANGE));
    if (!capability->hContainer) return SetStatus (TWCC_LOWMEMORY);

    capability->ConType = TWON_RANGE;

    HLock ((Handle) capability->hContainer);
    pTW_RANGE pRange = (pTW_RANGE) *(Handle) capability->hContainer;
    pRange->ItemType = type;
    pRange->MinValue = *((TW_UINT32*) &min);
    pRange->MaxValue = *((TW_UINT32*) &max);
    pRange->StepSize = *((TW_UINT32*) &step);
    pRange->DefaultValue = *((TW_UINT32*) &defvalue);
    pRange->CurrentValue = *((TW_UINT32*) &value);
    HUnlock ((Handle) capability->hContainer);

    return TWRC_SUCCESS;
}


TW_UINT16 DataSource::SetStatus (TW_UINT16 status, TW_UINT16 retval) {

    twainstatus = status;
    return retval;
}
