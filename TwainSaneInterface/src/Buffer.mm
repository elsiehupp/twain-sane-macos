#ifndef SANE_DS_BUFFER_H
#define SANE_DS_BUFFER_H

#include <Carbon/Carbon.h>

class Buffer {

public:
    Buffer ();
    Buffer (Size insize);
    ~Buffer ();
    void SetSize (Size insize);
    Size CheckSize ();
    Ptr GetPtr (Size datasize = 0);
    void ReleasePtr (Size datasize);
    void Write (void * data, Size datasize);
    Handle Claim ();
private:
    Handle handle;
    Size size;
    Size delta;
    Size offset;
    OSErr memError;
    bool claimed;
};

#endif
