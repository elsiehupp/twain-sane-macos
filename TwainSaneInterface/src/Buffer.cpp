#include <Carbon/Carbon.h>

#include "Buffer.h"


Buffer::Buffer () : handle (NULL), size (0), delta (0), offset (0), memError (noErr),
                    claimed (false) {}


Buffer::Buffer (Size insize) : size (insize), delta (insize), offset (0), claimed (false) {

    handle = NewHandle (size);
    memError = MemError ();
}


Buffer::~Buffer () {

    if (handle && !claimed) DisposeHandle (handle);
}


void Buffer::SetSize (Size insize) {

    if (handle) return;
    size = insize;
    delta = insize;
    handle = NewHandle (size);
    memError = MemError ();
}


Size Buffer::CheckSize () {

    if (!handle) return 0;
    if (claimed) return 0;
    if (memError) return 0;
    if (size == offset) {
        size += delta;
        SetHandleSize (handle, size);
        memError = MemError ();
        if (memError) return 0;
    }
    return size - offset;
}


Ptr Buffer::GetPtr (Size datasize) {

    if (!handle) return NULL;
    if (claimed) return NULL;
    while (!memError && size < offset + datasize) {
        size += delta;
        SetHandleSize (handle, size);
        memError = MemError ();
    }
    if (memError) return NULL;
    HLock (handle);
    return & ((*handle) [offset]);
}


void Buffer::ReleasePtr (Size datasize) {

    if (!handle) return;
    if (claimed) return;
    if (memError) return;
    HUnlock (handle);
    offset += datasize;
}


void Buffer::Write (void * data, Size datasize) {

    if (!handle) return;
    if (claimed) return;
    while (!memError && size < offset + datasize) {
        size += delta;
        SetHandleSize (handle, size);
        memError = MemError ();
    }
    if (memError) return;
    HLock (handle);
    memcpy (& ((*handle) [offset]), data, datasize);
    HUnlock (handle);
    offset += datasize;
}


Handle Buffer::Claim () {

    if (!handle) return NULL;
    if (claimed) return NULL;
    if (memError) return NULL;
    if (size != offset) {
        size = offset;
        SetHandleSize (handle, size);
        memError = MemError ();
        if (memError) return NULL;
    }
    claimed = true;
    return handle;
}
