#include <TWAIN/TWAIN.h>
#include "DataSource.h"

DataSource datasource;

TW_UINT16 DS_Entry (pTW_IDENTITY pOrigin,
                    TW_UINT32    DG,
                    TW_UINT16    DAT,
                    TW_UINT16    MSG,
                    TW_MEMREF    pData) {

    return datasource.Entry (pOrigin, DG, DAT, MSG, pData);
}
