#ifndef SANE_DS_IMAGE_H
#define SANE_DS_IMAGE_H

#include <Carbon/Carbon.h>
#include <TWAIN/TWAIN.h>

#include <sane/sane.h>

#include <map>

#include "SaneDevice.h"


class Image {

public:
    Image ();
    ~Image ();
    PicHandle MakePict ();
    TW_UINT16 TwainImageInfo (pTW_IMAGEINFO imageinfo);
    TW_UINT16 TwainImageLayout (pTW_IMAGELAYOUT imagelayout);
    TW_UINT16 TwainSetupMemXfer (pTW_SETUPMEMXFER setupmemxfer);
    TW_UINT16 TwainImageMemXfer (pTW_IMAGEMEMXFER imagememxfer, pTW_UINT32 yoffset);
    TW_UINT16 TwainPalette8 (pTW_PALETTE8 palette8, pTW_UINT16 twainstatus);

private:
    Handle imagedata;
    SANE_Rect bounds;
    SANE_Resolution res;
    SANE_Parameters param;
    std::map <SANE_Frame, int> frame;

    friend Image * SaneDevice::Scan (bool queue, bool indicators);
};

#endif
