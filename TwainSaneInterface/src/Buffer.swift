class Buffer {

    private var handle: Handle
    private var size: Size
    private var delta: Size
    private var offset: Size
    private var memError: OSErr
    private var claimed: Bool

    public func Buffer() {
        handle(nil)
        size(0)
        delta(0)
        offset(0)
        memError(noErr)
        claimed(false)
    }


    public func Buffer(insize: Size) {
        size(insize)
        delta(insize)
        offset(0)
        claimed(false)

        handle = NewHandle(size)
        memError = MemError()
    }


    // public func ~Buffer() {
    //     if handle && !claimed {
    //         DisposeHandle(handle)
    //     }
    // }


    public func SetSize(insize: Size) {

        if self.handle {
            return
        }
        self.size = insize
        self.delta = insize
        self.handle = NewHandle(self.size)
        self.memError = MemError()
    }


    public func CheckSize() -> Size {

        if !self.handle {
            return 0
        }
        if self.claimed {
            return 0
        }
        if self.memError {
            return 0
        }
        if self.size == self.offset {
            self.size += self.delta
            SetHandleSize(self.handle, self.size)
            self.memError = MemError()
            if memError {
                return 0
            }
        }
        return size - offset
    }


    public func GetPtr(datasize: Size = 0) -> Ptr {

        if !self.handle {
            return nil
        }
        if self.claimed {
            return nil
        }
        while !self.memError && self.size < self.offset + self.datasize {
            self.size += self.delta
            SetHandleSize(self.handle, self.size)
            self.memError = MemError()
        }
        if self.memError {
            return nil
        }
        HLock(self.handle)
        return self.handle[self.offset]
    }


    public func ReleasePtr(datasize: Size) {

        if !self.handle {
            return
        }
        if self.claimed {
            return
        }
        if self.memError {
            return
        }
        HUnlock(self.handle)
        self.offset += self.datasize
    }


    public func Write(data: any, datasize: Size) {

        if !self.handle {
            return
        }
        if self.claimed {
            return
        }
        while !self.memError && self.size < self.offset + self.datasize {
            self.size += self.delta
            SetHandleSize(self.handle, self.size)
            self.memError = MemError()
        }
        if self.memError {
            return
        }
        HLock(self.handle)
        memcpy(self.handle[self.offset], self.data, self.datasize)
        HUnlock(self.handle)
        self.offset += self.datasize
    }


    public func Claim() -> Handle {
        if !self.handle {
            return nil
        }
        if self.claimed {
            return nil
        }
        if self.memError {
            return nil
        }
        if self.size != self.offset {
            self.size = self.offset
            SetHandleSize(self.handle, self.size)
            self.memError = MemError()
            if self.memError {
                return nil
            }
        }
        self.claimed = true
        return self.handle
    }
}