class Buffer {

public:
    Buffer()
    Buffer(Size insize)
    ~Buffer()
    void SetSize(Size insize)
    Size CheckSize()
    Ptr GetPtr(Size datasize = 0)
    void ReleasePtr(Size datasize)
    void Write(void * data, Size datasize)
    Handle Claim()
private:
    Handle handle
    Size size
    Size delta
    Size offset
    OSErr memError
    Bool claimed
}







Buffer.Buffer() : handle(nil), size(0), delta(0), offset(0), memError(noErr),
                    claimed(false) {}


Buffer.Buffer(Size insize) : size(insize), delta(insize), offset(0), claimed(false) {

    handle = NewHandle(size)
    memError = MemError()
}


Buffer.~Buffer() {

    if(handle && !claimed) DisposeHandle(handle)
}


func void Buffer.SetSize(Size insize) {

    if(handle) return
    size = insize
    delta = insize
    handle = NewHandle(size)
    memError = MemError()
}


Size Buffer.CheckSize() {

    if(!handle) return 0
    if(claimed) return 0
    if(memError) return 0
    if(size == offset) {
        size += delta
        SetHandleSize(handle, size)
        memError = MemError()
        if(memError) return 0
    }
    return size - offset
}


Ptr Buffer.GetPtr(Size datasize) {

    if(!handle) return nil
    if(claimed) return nil
    while(!memError && size < offset + datasize) {
        size += delta
        SetHandleSize(handle, size)
        memError = MemError()
    }
    if(memError) return nil
    HLock(handle)
    return & ((*handle) [offset])
}


func void Buffer.ReleasePtr(Size datasize) {

    if(!handle) return
    if(claimed) return
    if(memError) return
    HUnlock(handle)
    offset += datasize
}


func void Buffer.Write(void * data, Size datasize) {

    if(!handle) return
    if(claimed) return
    while(!memError && size < offset + datasize) {
        size += delta
        SetHandleSize(handle, size)
        memError = MemError()
    }
    if(memError) return
    HLock(handle)
    memcpy(& ((*handle) [offset]), data, datasize)
    HUnlock(handle)
    offset += datasize
}


Handle Buffer.Claim() {

    if(!handle) return nil
    if(claimed) return nil
    if(memError) return nil
    if(size != offset) {
        size = offset
        SetHandleSize(handle, size)
        memError = MemError()
        if(memError) return nil
    }
    claimed = true
    return handle
}
