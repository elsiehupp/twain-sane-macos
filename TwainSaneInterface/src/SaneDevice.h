#ifndef SANE_DS_DEVICE_H
#define SANE_DS_DEVICE_H

#include <Carbon/Carbon.h>
#include <TWAIN/TWAIN.h>

#include <sane/sane.h>

#include <map>
#include <string>

inline TW_FIX32 S2T (SANE_Fixed s) {

    TW_FIX32 t;
    t.Whole = s >> 16;
    t.Frac = s & 0xFFFF;
    return t;
}

inline SANE_Fixed T2S (TW_FIX32 t) {

    return (t.Whole << 16) + t.Frac;
}

struct SANE_Rect {
    SANE_Word top;
    SANE_Word left;
    SANE_Word bottom;
    SANE_Word right;
    SANE_Value_Type type;
    SANE_Unit unit;
};

struct SANE_Resolution {
    SANE_Word h;
    SANE_Word v;
    SANE_Value_Type type;
};


#define SANE_OPTION_IS_GETTABLE(cap) (((cap) & SANE_CAP_SOFT_DETECT) != 0)

#define SANE_FIX2INT(v) (((v) + 0x8000) >> SANE_FIXED_SCALE_SHIFT)
#define SANE_INT2FIX(v) ((v) << SANE_FIXED_SCALE_SHIFT)

#ifdef SANE_FIX
#undef SANE_FIX
#endif
#define SANE_FIX(v) (lround ((v) * (1 << SANE_FIXED_SCALE_SHIFT)))

#define BNDLNAME CFSTR ("se.ellert.twain-sane")


class DataSource;
class UserInterface;
class Image;


class SaneDevice {

public:
    SaneDevice (DataSource * ds);
    ~SaneDevice ();

    void CallBack (TW_UINT16 MSG);

    CFStringRef CreateName (int device = -1);
    int ChangeDevice (int device);
    void ShowUI (bool uionly);
    void HideUI ();
    bool HasUI ();
    void ShowSheetWindow (WindowRef window);
    void OpenDeviceFailed ();
    void SaneError (SANE_Status status);

    TW_UINT16 GetCustomData (pTW_CUSTOMDSDATA customdata);
    TW_UINT16 SetCustomData (pTW_CUSTOMDSDATA customdata);

    void GetRect (SANE_Rect * viewrect);
    void SetRect (SANE_Rect * viewrect);
    void GetMaxRect (SANE_Rect * rect);
    void GetResolution (SANE_Resolution * res);
    void SetResolution (SANE_Resolution * res);

    TW_UINT16 GetPixelType (pTW_CAPABILITY capability, bool onlyone);
    TW_UINT16 GetPixelTypeDefault (pTW_CAPABILITY capability);
    TW_UINT16 SetPixelType (pTW_CAPABILITY capability);
    TW_UINT16 GetBitDepth (pTW_CAPABILITY capability, bool onlyone);
    TW_UINT16 GetBitDepthDefault (pTW_CAPABILITY capability);
    TW_UINT16 SetBitDepth (pTW_CAPABILITY capability);
    TW_UINT16 GetXNativeResolution (pTW_CAPABILITY capability);
    TW_UINT16 GetYNativeResolution (pTW_CAPABILITY capability);
    TW_UINT16 GetXResolution (pTW_CAPABILITY capability, bool onlyone);
    TW_UINT16 GetXResolutionDefault (pTW_CAPABILITY capability);
    TW_UINT16 SetXResolution (pTW_CAPABILITY capability);
    TW_UINT16 GetYResolution (pTW_CAPABILITY capability, bool onlyone);
    TW_UINT16 GetYResolutionDefault (pTW_CAPABILITY capability);
    TW_UINT16 SetYResolution (pTW_CAPABILITY capability);
    TW_UINT16 GetPhysicalWidth (pTW_CAPABILITY capability);
    TW_UINT16 GetPhysicalHeight (pTW_CAPABILITY capability);
    TW_UINT16 GetBrightness (pTW_CAPABILITY capability, bool onlyone);
    TW_UINT16 GetBrightnessDefault (pTW_CAPABILITY capability);
    TW_UINT16 SetBrightness (pTW_CAPABILITY capability);
    TW_UINT16 GetContrast (pTW_CAPABILITY capability, bool onlyone);
    TW_UINT16 GetContrastDefault (pTW_CAPABILITY capability);
    TW_UINT16 SetContrast (pTW_CAPABILITY capability);
    TW_UINT16 GetLayout (pTW_IMAGELAYOUT imagelayout);
    TW_UINT16 SetLayout (pTW_IMAGELAYOUT imagelayout);

    Image * Scan (bool queue = true, bool indicators = true);
    void SetPreview (SANE_Bool preview);
    Image * GetImage ();
    void DequeueImage ();

    const SANE_Handle GetSaneHandle ();
    const SANE_Int GetSaneVersion ();
    void GetAreaOptions (int * top = NULL, int * left = NULL, int * bottom = NULL, int * right = NULL);

private:
    CFDictionaryRef CreateOptionDictionary ();
    void ApplyOptionDictionary (CFDictionaryRef optionDictionary);

    const SANE_Device ** devicelist;
    SANE_Int saneversion;
    int currentDevice;
    std::map <int, SANE_Handle> sanehandles;
    std::map <std::string, int> optionIndex;

    DataSource * datasource;
    UserInterface * userinterface;
    Image * image;
};

#endif
