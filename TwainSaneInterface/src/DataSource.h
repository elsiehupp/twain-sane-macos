#ifndef SANE_DS_DATASOURCE_H
#define SANE_DS_DATASOURCE_H

#include <TWAIN/TWAIN.h>

class SaneDevice;

class DataSource {

public:
    DataSource ();
    ~DataSource ();
    TW_UINT16 Entry (pTW_IDENTITY pOrigin,
                     TW_UINT32    DG,
                     TW_UINT16    DAT,
                     TW_UINT16    MSG,
                     TW_MEMREF    pData);
    TW_UINT16 CallBack (TW_UINT16 MSG);

    TW_UINT16 SetStatus (TW_UINT16 status, TW_UINT16 retval = TWRC_FAILURE);
    TW_UINT16 BuildEnumeration (pTW_CAPABILITY capability, TW_UINT16 type, TW_UINT32 numItems,
                                TW_UINT32 currentIndex, TW_UINT32 defaultIndex, void * values);
    TW_UINT16 BuildArray (pTW_CAPABILITY capability, TW_UINT16 type, TW_UINT32 numItems,
                          void * values);
    TW_UINT16 BuildRange (pTW_CAPABILITY capability, TW_UINT16 type, TW_UINT32 min, TW_UINT32 max,
                          TW_UINT32 step, TW_UINT32 defvalue, TW_UINT32 value);
    TW_UINT16 BuildRange (pTW_CAPABILITY capability, TW_UINT16 type, TW_FIX32 min, TW_FIX32 max,
                          TW_FIX32 step, TW_FIX32 defvalue, TW_FIX32 value);
    TW_UINT16 BuildOneValue (pTW_CAPABILITY capability, TW_UINT16 type, TW_UINT32 value);
    TW_UINT16 BuildOneValue (pTW_CAPABILITY capability, TW_UINT16 type, TW_FIX32 value);

private:
    TW_UINT16 Capability (TW_UINT16 MSG, pTW_CAPABILITY capability);
    TW_UINT16 Identity (TW_UINT16 MSG, pTW_IDENTITY identity);
    TW_UINT16 PendingXfers (TW_UINT16 MSG, pTW_PENDINGXFERS pendingxfers);
    TW_UINT16 SetupMemXfer (TW_UINT16 MSG, pTW_SETUPMEMXFER setupmemxfer);
    TW_UINT16 Status (TW_UINT16 MSG, pTW_STATUS status);
    TW_UINT16 UserInterface (TW_UINT16 MSG, pTW_USERINTERFACE userinterface);
    TW_UINT16 XferGroup (TW_UINT16 MSG, pTW_UINT32 xfergroup);
    TW_UINT16 CustomDSData (TW_UINT16 MSG, pTW_CUSTOMDSDATA customdsdata);
    TW_UINT16 ImageInfo (TW_UINT16 MSG, pTW_IMAGEINFO imageinfo);
    TW_UINT16 ImageLayout (TW_UINT16 MSG, pTW_IMAGELAYOUT imagelayout);
    TW_UINT16 ImageMemXfer (TW_UINT16 MSG, pTW_IMAGEMEMXFER imagememxfer);
    TW_UINT16 ImageNativeXfer (TW_UINT16 MSG, pTW_UINT32 handle);
    TW_UINT16 Palette8 (TW_UINT16 MSG, pTW_PALETTE8 palette8);

    pTW_IDENTITY origin;
    SaneDevice * sanedevice;
    TW_UINT16 twainstatus;

    enum State {
        STATE_3 = 3,
        STATE_4 = 4,
        STATE_5 = 5,
        STATE_6 = 6,
        STATE_7 = 7
    } state;

    TW_UINT16 cap_XferMech;

    TW_UINT32 writtenlines;
    bool uionly;
    bool indicators;
};

#endif
