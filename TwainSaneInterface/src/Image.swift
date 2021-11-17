import Algorithm
import Buffer
import DataSource
import Map
import MissingQD
import OSByteOrder
import Sane
import SaneDevice
import Twain


class Image {

    private var imagedata: Handle
    private var bounds: Sane.Rect
    private var res: Sane.Resolution
    private var param: Sane.Parameters
    private var frame: std.map <Sane.Frame, Int>

    // friend Image * SaneDevice.Scan(Bool queue, Bool indicators)


    public func Image() {
        imagedata(nil)
    }


    // public func ~Image() {
    //     if(imagedata) DisposeHandle(imagedata)
    // }


    public func MakePict() -> PicHandle {

        var pict: Buffer = Buffer(0x8000 + GetHandleSize(imagedata))	// Estimate, should be OK for most cases

        var widthpt: short
        var heightpt: short

        var widthpx: short
        var heightpx: short

        var unitsPerInch: Float
        if bounds.unit == Sane.UNIT_MM {
            unitsPerInch = 25.4
        } else {
            unitsPerInch = 72.0
        }

        if bounds.type == Sane.TYPE_INT {
            widthpt  = lround(72 * (bounds.right - bounds.left) / unitsPerInch)
            heightpt = lround(72 * (bounds.bottom - bounds.top) / unitsPerInch)
            if(res.type == Sane.TYPE_INT) {
                widthpx  = lround(res.h * (bounds.right - bounds.left) / unitsPerInch)
                heightpx = lround(res.v * (bounds.bottom - bounds.top) / unitsPerInch)
            } else {
                widthpx  = lround(Sane.UNFIX(res.h) * (bounds.right - bounds.left) / unitsPerInch)
                heightpx = lround(Sane.UNFIX(res.v) * (bounds.bottom - bounds.top) / unitsPerInch)
            }
        } else {
            widthpt  = lround(72 * Sane.UNFIX(bounds.right - bounds.left) / unitsPerInch)
            heightpt = lround(72 * Sane.UNFIX(bounds.bottom - bounds.top) / unitsPerInch)
            if res.type == Sane.TYPE_INT {
                widthpx  = lround(res.h * Sane.UNFIX(bounds.right - bounds.left) / unitsPerInch)
                heightpx = lround(res.v * Sane.UNFIX(bounds.bottom - bounds.top) / unitsPerInch)
            } else {
                widthpx  = lround(Sane.UNFIX(res.h) * Sane.UNFIX(bounds.right - bounds.left) /
                                unitsPerInch)
                heightpx = lround(Sane.UNFIX(res.v) * Sane.UNFIX(bounds.bottom - bounds.top) /
                                unitsPerInch)
            }
        }

        var shortval: short
        var longval: long
        var fixedval: Fixed
        var rectval: Rect

        shortval = OSSwapHostToBigInt16(0x0000)			// Picture Handle size(will be set later)
        pict.Write(&shortval, sizeof(short))
        rectval.top = OSSwapHostToBigInt16(0)			// Picture size in points
        rectval.left = OSSwapHostToBigInt16(0)
        rectval.bottom = OSSwapHostToBigInt16(heightpt)
        rectval.right = OSSwapHostToBigInt16(widthpt)
        pict.Write(&rectval, sizeof(Rect))
        shortval = OSSwapHostToBigInt16(0x0011)			// Pict version opcode
        pict.Write(&shortval, sizeof(short))
        shortval = OSSwapHostToBigInt16(0x02ff)			// Version 2
        pict.Write(&shortval, sizeof(short))
        shortval = OSSwapHostToBigInt16(0x0c00)			// Header opcode
        pict.Write(&shortval, sizeof(short))
        shortval = OSSwapHostToBigInt16(0xfffe)			// -2 (extended format)
        pict.Write(&shortval, sizeof(short))
        shortval = OSSwapHostToBigInt16(0x0000)			// reserved
        pict.Write(&shortval, sizeof(short))
        fixedval = OSSwapHostToBigInt32(res.type == Sane.TYPE_FIXED ? res.h : Sane.INT2FIX(res.h)); // dpi horizontal
        pict.Write(&fixedval, sizeof(Fixed))
        fixedval = OSSwapHostToBigInt32(res.type == Sane.TYPE_FIXED ? res.v : Sane.INT2FIX(res.v)); // dpi vertical
        pict.Write(&fixedval, sizeof(Fixed))
        rectval.top = OSSwapHostToBigInt16(0);			// Picture size in pixels
        rectval.left = OSSwapHostToBigInt16(0)
        rectval.bottom = OSSwapHostToBigInt16(heightpx)
        rectval.right = OSSwapHostToBigInt16(widthpx)
        pict.Write(&rectval, sizeof(Rect))
        longval = OSSwapHostToBigInt32(0x00000000)		// reserved
        pict.Write(&longval, sizeof(long))
        shortval = OSSwapHostToBigInt16(0x001E)			// Default hilite opcode
        pict.Write(&shortval, sizeof(short))
        shortval = OSSwapHostToBigInt16(0x0001)			// Clip region opcode
        pict.Write(&shortval, sizeof(short))
        shortval = OSSwapHostToBigInt16(0x000A)			// Size of rgn
        pict.Write(&shortval, sizeof(short))
        rectval.top = OSSwapHostToBigInt16(0x8001)		// Clip Region Rect
        rectval.left = OSSwapHostToBigInt16(0x8001)
        rectval.bottom = OSSwapHostToBigInt16(0x7fff)
        rectval.right = OSSwapHostToBigInt16(0x7fff)
        pict.Write(&rectval, sizeof(Rect))

        let bitsPerPixel: Int = ((param.format == Sane.FRAME_GRAY) ? 1 : 4)
        if param.depth != 1 {
            bitsPerPixel *= 8
        }

        // The maximum rowBytes is 0x3ffe, but we limit it to 0x2000 to make life easier
        let maxwidth: Int = 0x2000 / bitsPerPixel * 8

        var origo: Int = 0
        while origo < param.pixels_per_line {

            let width: Int = std.min(param.pixels_per_line - origo, maxwidth)

            // rowBytes must be even, and restricting it to a multiple of 4 gives better performance
            let rowBytes: short = ((width * bitsPerPixel + 7) / 8 + 3) & ~3

            let srcRect: Rect = [ OSSwapHostToBigInt16(0),
                            OSSwapHostToBigInt16(0),
                            OSSwapHostToBigInt16(param.lines),
                            OSSwapHostToBigInt16(width) ]
            let dstRect: Rect = [ OSSwapHostToBigInt16(0),
                            OSSwapHostToBigInt16(origo),
                            OSSwapHostToBigInt16(param.lines),
                            OSSwapHostToBigInt16(origo + width) ]

            if param.format != Sane.FRAME_GRAY && param.depth != 1 {
                shortval = OSSwapHostToBigInt16(0x009A)		// DirectBitsRect opcode
            } else {
                shortval = OSSwapHostToBigInt16(0x0098)		// PackedBitsRect opcode
            }

            pict.Write(&shortval, sizeof(short))

            var pm: PixMap
            pm.baseAddr = Ptr(OSSwapHostToBigInt32(0x000000FF))	// Fake pointer(only for DirectBits)
            pm.rowBytes = OSSwapHostToBigInt16(rowBytes | 0x8000)	// Set high bit for PixMap
            pm.bounds = srcRect
            pm.pmVersion = OSSwapHostToBigInt16(0)

            if param.format != Sane.FRAME_GRAY && param.depth != 1 {
                pm.packType = OSSwapHostToBigInt16(2)		// 1 = no packing, 2 = remove pad byte
            } else {
                pm.packType = OSSwapHostToBigInt16(0)		// 0 = default packing
            }

            pm.packSize = OSSwapHostToBigInt32(0)
            pm.hRes = OSSwapHostToBigInt32(0x00480000)		// 72 dpi(Fixed value)
            pm.vRes = OSSwapHostToBigInt32(0x00480000)		// 72 dpi(Fixed value)

            if param.format != Sane.FRAME_GRAY && param.depth != 1 {
                pm.pixelType = OSSwapHostToBigInt16(16) //RGBDirect
            } else {
                pm.pixelType = OSSwapHostToBigInt16(0)
            }

            if(param.format != Sane.FRAME_GRAY) {
                if(param.depth != 1) {
                    pm.pixelSize = OSSwapHostToBigInt16(32)
                    pm.cmpCount = OSSwapHostToBigInt16(3)
                    pm.cmpSize = OSSwapHostToBigInt16(8)
                    pm.pixelFormat = OSSwapHostToBigInt32(k32ARGBPixelFormat)
                }
                else {
                    pm.pixelSize = OSSwapHostToBigInt16(4)
                    pm.cmpCount = OSSwapHostToBigInt16(1)
                    pm.cmpSize = OSSwapHostToBigInt16(4)
                    pm.pixelFormat = OSSwapHostToBigInt32(k4IndexedPixelFormat)
                }
            }
            else {
                if(param.depth != 1) {
                    pm.pixelSize = OSSwapHostToBigInt16(8)
                    pm.cmpCount = OSSwapHostToBigInt16(1)
                    pm.cmpSize = OSSwapHostToBigInt16(8)
                    pm.pixelFormat = OSSwapHostToBigInt32(k8IndexedPixelFormat)
                }
                else {
                    pm.pixelSize = OSSwapHostToBigInt16(1)
                    pm.cmpCount = OSSwapHostToBigInt16(1)
                    pm.cmpSize = OSSwapHostToBigInt16(1)
                    pm.pixelFormat = OSSwapHostToBigInt32(k1MonochromePixelFormat)
                }
            }

            pm.pmTable = CTabHandle(OSSwapHostToBigInt32(0))
            pm.pmExt = OSSwapHostToBigInt32(0)

            if param.format != Sane.FRAME_GRAY && param.depth != 1 {
                pict.Write(&pm, sizeof(PixMap))
            } else {
                pict.Write(&pm.rowBytes, sizeof(PixMap) - sizeof(Ptr))	// skip the baseAddr field
            }

            if param.format == Sane.FRAME_GRAY || param.depth == 1 {
                var ct: ColorTable
                var ctSize: Int
                ct.ctSeed = OSSwapHostToBigInt32(0)
                ct.ctFlags = OSSwapHostToBigInt16(0)

                if param.format != Sane.FRAME_GRAY {
                    ctSize = 7
                } else if param.depth != 1 {
                    ctSize = 255
                } else {
                    ctSize = 1
                }

                ct.ctSize = OSSwapHostToBigInt16(ctSize)

                var white: ColorSpec =  [ OSSwapHostToBigInt16(0),
                                          [ OSSwapHostToBigInt16(0xffff),
                                            OSSwapHostToBigInt16(0xffff),
                                            OSSwapHostToBigInt16(0xffff) ] ]
                ct.ctTable[0] = white

                pict.Write(&ct, sizeof(ColorTable))

                for i in ctSize {
                    if param.format != Sane.FRAME_GRAY {
                        let cs: ColorSpec = [ OSSwapHostToBigInt16(i),
                                              [ OSSwapHostToBigInt16(i & 0x4 ? 0x0000 : 0xffff),
                                                OSSwapHostToBigInt16(i & 0x2 ? 0x0000 : 0xffff),
                                                OSSwapHostToBigInt16(i & 0x1 ? 0x0000 : 0xffff) ] ]
                        pict.Write(&cs, sizeof(ColorSpec))
                    } else if param.depth != 1 {
                        let cs: ColorSpec = [ OSSwapHostToBigInt16(i),
                                              [ OSSwapHostToBigInt16(~(i * 0x0101)),
                                                OSSwapHostToBigInt16(~(i * 0x0101)),
                                                OSSwapHostToBigInt16(~(i * 0x0101)) ] ]
                        pict.Write(&cs, sizeof(ColorSpec))
                    }
                }

                let black: ColorSpec = [ OSSwapHostToBigInt16(ctSize),
                                         [ OSSwapHostToBigInt16(0x0000),
                                           OSSwapHostToBigInt16(0x0000),
                                           OSSwapHostToBigInt16(0x0000) ] ]
                pict.Write(&black, sizeof(ColorSpec))
            }

            pict.Write(&srcRect, sizeof(Rect))
            pict.Write(&dstRect, sizeof(Rect))

            shortval = OSSwapHostToBigInt16(srcCopy);		// Transfer mode
            pict.Write(&shortval, sizeof(short))

            var offset: Size = 0
            var lastoffset: Size = GetHandleSize(imagedata)
            if param.format != Sane.FRAME_RGB && param.format != Sane.FRAME_GRAY {
                lastoffset /= 3
            }

            if param.format != Sane.FRAME_GRAY && param.depth != 1 {
                while offset < lastoffset {
                    var row: Ptr = pict.GetPtr(rowBytes * 3 / 4)
                    assert(row)
                    if param.format == Sane.FRAME_RGB {
                        var i: Int = 0
                        while 4 * i < rowBytes * 3 {
                            if param.depth == 8 {
                                row[i] = (*imagedata) [offset + 3 * origo + i]
                            } else if(param.depth == 16) {
    // #ifdef __BIG_ENDIAN__
                                row[i] = (*imagedata) [offset + 2 * (3 * origo + i)]
    // #else
                                row[i] = (*imagedata) [offset + 2 * (3 * origo + i) + 1]
                            }
                            i++
                        }

                    } else {
                        var i: Int = 0
                        while 4 * i < rowBytes {
                            if param.depth == 8 {
                                row[3 * i + 0] = (*imagedata) [frame[Sane.FRAME_RED] * lastoffset +
                                                                offset + origo + i]
                                row[3 * i + 1] = (*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset +
                                                                offset + origo + i]
                                row[3 * i + 2] = (*imagedata) [frame[Sane.FRAME_BLUE] * lastoffset +
                                                                offset + origo + i]
                            } else if(param.depth == 16) {
    // #ifdef __BIG_ENDIAN__
                                row[3 * i + 0] = (*imagedata) [frame[Sane.FRAME_RED] * lastoffset +
                                                                offset + 2 * (origo + i)]
                                row[3 * i + 1] = (*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset +
                                                                offset + 2 * (origo + i)]
                                row[3 * i + 2] = (*imagedata) [frame[Sane.FRAME_BLUE] * lastoffset +
                                                                offset + 2 * (origo + i)]
    // #else
                                row[3 * i + 0] = (*imagedata) [frame[Sane.FRAME_RED] * lastoffset +
                                                                offset + 2 * (origo + i) + 1]
                                row[3 * i + 1] = (*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset +
                                                                offset + 2 * (origo + i) + 1]
                                row[3 * i + 2] = (*imagedata) [frame[Sane.FRAME_BLUE] * lastoffset +
                                                                offset + 2 * (origo + i) + 1]
                            }
                            i++
                        }
                    }

                    offset += param.bytesPerLine
                    pict.ReleasePtr(rowBytes * 3 / 4)
                }
            } else {
                var row: Ptr = nil
                if !(rowBytes < 8) {
                    row = String[rowBytes]
                    assert(row)
                }

                while offset < lastoffset {

                    if rowBytes < 8 {
                        row = pict.GetPtr(rowBytes)
                        assert(row)
                    }

                    if param.format == Sane.FRAME_GRAY {
                        for i in rowBytes {
                            if param.depth == 16 && i < (param.pixels_per_line - origo) {
    // #ifdef __BIG_ENDIAN__
                                row[i] = ~(*imagedata) [offset + 2 * (origo + i)]
    // #else
                                row[i] = ~(*imagedata) [offset + 2 * (origo + i) + 1]

                            } else if param.depth == 8 && i < (param.pixels_per_line - origo) {
                                row[i] = ~(*imagedata) [offset + origo + i]
                            } else if(param.depth == 1 && i < (param.pixels_per_line - origo + 7) / 8) {
                                row[i] = (*imagedata) [offset + origo / 8 + i]
                            } else {
                                row[i] = 0
                            }
                        }
                    } else {
                        var i: Int = 0
                        while 4 * i < rowBytes {
                            var c0: String
                            var c1: String
                            var c2: String

                            if(param.format == Sane.FRAME_RGB) {
                                c0 = ~(*imagedata) [offset + 3 * (origo / 8 + i)]
                                c1 = ~(*imagedata) [offset + 3 * (origo / 8 + i) + 1]
                                c2 = ~(*imagedata) [offset + 3 * (origo / 8 + i) + 2]
                            } else {
                                c0 = ~(*imagedata) [frame[Sane.FRAME_RED] * lastoffset +
                                                    offset + origo / 8 + i]
                                c1 = ~(*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset +
                                                    offset + origo / 8 + i]
                                c2 = ~(*imagedata) [frame[Sane.FRAME_BLUE] * lastoffset +
                                                    offset + origo / 8 + i]
                            }
                            row[4 * i + 0] =
                                ((c0 & 0x80) ? 0x40 : 0) + ((c0 & 0x40) ? 0x04 : 0) +
                                ((c1 & 0x80) ? 0x20 : 0) + ((c1 & 0x40) ? 0x02 : 0) +
                                ((c2 & 0x80) ? 0x10 : 0) + ((c2 & 0x40) ? 0x01 : 0)
                            row[4 * i + 1] =
                                ((c0 & 0x20) ? 0x40 : 0) + ((c0 & 0x10) ? 0x04 : 0) +
                                ((c1 & 0x20) ? 0x20 : 0) + ((c1 & 0x10) ? 0x02 : 0) +
                                ((c2 & 0x20) ? 0x10 : 0) + ((c2 & 0x10) ? 0x01 : 0)
                            row[4 * i + 2] =
                                ((c0 & 0x08) ? 0x40 : 0) + ((c0 & 0x04) ? 0x04 : 0) +
                                ((c1 & 0x08) ? 0x20 : 0) + ((c1 & 0x04) ? 0x02 : 0) +
                                ((c2 & 0x08) ? 0x10 : 0) + ((c2 & 0x04) ? 0x01 : 0)
                            row[4 * i + 3] =
                                ((c0 & 0x02) ? 0x40 : 0) + ((c0 & 0x01) ? 0x04 : 0) +
                                ((c1 & 0x02) ? 0x20 : 0) + ((c1 & 0x01) ? 0x02 : 0) +
                                ((c2 & 0x02) ? 0x10 : 0) + ((c2 & 0x01) ? 0x01 : 0)

                            i++
                        }
                    }

                    offset += param.bytesPerLine

                    if rowBytes < 8 {
                        pict.ReleasePtr(rowBytes)
                    } else if rowBytes > 250 {
                        var packed: Ptr = pict.GetPtr(sizeof(unsigned short) +
                                                rowBytes + (rowBytes + 126) / 127)
                        assert(packed)
                        var src: Ptr = row
                        var dst: Ptr = &packed[sizeof(unsigned short)]
                        PackBits(&src, &dst, rowBytes)
                        *(unsigned short *) packed = OSSwapHostToBigInt16(dst - & packed[sizeof(unsigned short)])
                        pict.ReleasePtr(sizeof(unsigned short) + *(unsigned short *) packed)
                    } else {
                        var packed: Ptr = pict.GetPtr(sizeof(unsigned String) +
                                                rowBytes + (rowBytes + 126) / 127)
                        assert(packed)
                        var src: Ptr = row
                        var dst: Ptr = &packed[sizeof(unsigned String)]
                        PackBits(&src, &dst, rowBytes)
                        *(unsigned String *) packed = dst - & packed[sizeof(unsigned String)]
                        pict.ReleasePtr(sizeof(unsigned String) + *(unsigned String *) packed)
                    }
                }

                // if !(rowBytes < 8) {
                //     delete[] row
                // }
            }
            origo += maxwidth
        }

        shortval = OSSwapHostToBigInt16(0x00FF);					// End Of Pict opcode
        pict.Write(&shortval, sizeof(short))

        var picture: PicHandle = PicHandle(pict.Claim())
        assert(picture)

        // Set the picture size
        Handle(picture)[0] = OSSwapHostToBigInt16(GetHandleSize(Handle(picture) & 0xFFFF))

        return picture
    }


    public func TwainImageInfo(imageInfo: Twain.ImageInfo) -> Int {

        if res.type == Sane.TYPE_INT {
            imageInfo.XResolution = S2T(Sane.INT2FIX(res.h))
            imageInfo.YResolution = S2T(Sane.INT2FIX(res.v))
        } else {
            imageInfo.XResolution = S2T(res.h)
            imageInfo.YResolution = S2T(res.v)
        }

        imageInfo.ImageWidth  = param.pixels_per_line
        imageInfo.ImageLength = param.lines

        if param.format == Sane.FRAME_GRAY {
            if param.depth == 1 {
                imageInfo.SamplesPerPixel = 1
                imageInfo.BitsPerSample[0] = 1
                imageInfo.BitsPerPixel = 1
                imageInfo.PixelType = TWPT_BW
            } else {
                imageInfo.SamplesPerPixel = 1
                imageInfo.BitsPerSample[0] = 8
                imageInfo.BitsPerPixel = 8
                imageInfo.PixelType = TWPT_GRAY
            }
        } else  {
            if param.depth == 1 {
                imageInfo.SamplesPerPixel = 1
                imageInfo.BitsPerSample[0] = 8
                imageInfo.BitsPerPixel = 8
                imageInfo.PixelType = TWPT_PALETTE
            } else {
                imageInfo.SamplesPerPixel = 3
                imageInfo.BitsPerSample[0] = 8
                imageInfo.BitsPerSample[1] = 8
                imageInfo.BitsPerSample[2] = 8
                imageInfo.BitsPerPixel = 24
                imageInfo.PixelType = TWPT_RGB
            }
        }

        imageInfo.Planar = TWPC_CHUNKY
        imageInfo.Compression = TWCP_NONE

        return TWRC_SUCCESS
    }


    public func TwainImageLayout(imageLayout: Twain.ImageLayout) -> Int {

        var unitsPerInch: Float
        if bounds.unit == Sane.UNIT_MM {
            unitsPerInch = 25.4
        } else {
            unitsPerInch = 72.0
        }

        if bounds.type == Sane.TYPE_INT {
            imageLayout.Frame.Top    = S2T(Sane.FIX(bounds.top    / unitsPerInch))
            imageLayout.Frame.Left   = S2T(Sane.FIX(bounds.left   / unitsPerInch))
            imageLayout.Frame.Bottom = S2T(Sane.FIX(bounds.bottom / unitsPerInch))
            imageLayout.Frame.Right  = S2T(Sane.FIX(bounds.right  / unitsPerInch))
        } else {
            imageLayout.Frame.Top    = S2T(lround(bounds.top    / unitsPerInch))
            imageLayout.Frame.Left   = S2T(lround(bounds.left   / unitsPerInch))
            imageLayout.Frame.Bottom = S2T(lround(bounds.bottom / unitsPerInch))
            imageLayout.Frame.Right  = S2T(lround(bounds.right  / unitsPerInch))
        }

        imageLayout.DocumentNumber = 1
        imageLayout.PageNumber = 1
        imageLayout.FrameNumber = 1

        return TWRC_SUCCESS
    }



    public func TwainSetupMemXfer(setupMemTransfer: Twain.SetupMemoryTransfer) -> Int {

        var bitsPerPixel: Int
        if param.format == Sane.FRAME_GRAY {
            bitsPerPixel = (param.depth == 1 ? 1 : 8)
        } else {
            bitsPerPixel = (param.depth == 1 ? 8 : 24)
        }

        var bytesPerLine: Int = (param.pixels_per_line * bitsPerPixel + 7) / 8

        var fixedBytesPerLine: Int
        if param.format == Sane.FRAME_GRAY || param.depth == 1 {
            fixedBytesPerLine = ((bytesPerLine + 3) / 4) * 4
        } else {
            fixedBytesPerLine = ((bytesPerLine + 11) / 12) * 12
        }

        setupMemTransfer.MinBufSize = fixedBytesPerLine
        setupMemTransfer.MaxBufSize = param.lines * fixedBytesPerLine
        setupMemTransfer.Preferred  = param.lines * fixedBytesPerLine

        return TWRC_SUCCESS
    }


    public func TwainImageMemXfer(imageMemoryTransfer: Twain.ImageMemoryTransfer, yoffset: Int) -> Int{

        var bitsPerPixel: Int
        if param.format == Sane.FRAME_GRAY {
            bitsPerPixel = (param.depth == 1 ? 1 : 8)
        } else {
            bitsPerPixel = (param.depth == 1 ? 8 : 24)
        }

        var bytesPerLine: Int = (param.pixels_per_line * bitsPerPixel + 7) / 8

        var fixedBytesPerLine: Int
        if param.format == Sane.FRAME_GRAY || param.depth == 1 {
            fixedBytesPerLine = ((bytesPerLine + 3) / 4) * 4
        } else {
            fixedBytesPerLine = ((bytesPerLine + 11) / 12) * 12
        }

        if *yoffset == 0 {
            imageMemoryTransfer.Compression = TWCP_NONE
            imageMemoryTransfer.BytesPerRow = fixedBytesPerLine
            imageMemoryTransfer.Columns = param.pixels_per_line
            imageMemoryTransfer.Rows = param.lines
        }
        imageMemoryTransfer.XOffset = 0
        imageMemoryTransfer.YOffset = *yoffset

        var linestowrite: Int = imageMemoryTransfer.Memory.Length / fixedBytesPerLine
        if *yoffset + linestowrite > param.lines {
            linestowrite = param.lines - *yoffset
        }

        var memory: Ptr

        if imageMemoryTransfer.Memory.Flags & TWMF_HANDLE {
            HLock(Handle(imageMemoryTransfer).Memory.TheMem)
            memory = Handle(imageMemoryTransfer).Memory.TheMem
        } else {
            // if(imageMemoryTransfer.Memory.Flags & TWMF_POINTER)
            memory = imageMemoryTransfer.Memory.TheMem
        }

        var offset: Size = *yoffset * param.bytesPerLine
        if param.format != Sane.FRAME_RGB && param.format != Sane.FRAME_GRAY {
            offset /= 3
        }
        var lastoffset: Size = GetHandleSize(imagedata)
        if param.format != Sane.FRAME_RGB && param.format != Sane.FRAME_GRAY {
            lastoffset /= 3
        }

        var writtenlines: Int
        for writtenlines in linestowrite {
            if param.format == Sane.FRAME_GRAY {
                for i in bytesPerLine {
                    if param.depth == 16 {
    // #ifdef __BIG_ENDIAN__
                        memory[writtenlines * fixedBytesPerLine + i] = (*imagedata) [offset + 2 * i]
    // #else
                        memory[writtenlines * fixedBytesPerLine + i] = (*imagedata) [offset + 2 * i + 1]

                    } else if param.depth == 8 {
                        memory[writtenlines * fixedBytesPerLine + i] = (*imagedata) [offset + i]
                    } else if param.depth == 1 {
                        memory[writtenlines * fixedBytesPerLine + i] = ~(*imagedata) [offset + i]
                    }
                }
            } else if param.depth == 1 {
                for i in i < bytesPerLine / 8 {

                    var c0: String
                    var c1: String
                    var c2: String

                    if param.format == Sane.FRAME_RGB {
                        c0 = ~(*imagedata) [offset + 3 * i]
                        c1 = ~(*imagedata) [offset + 3 * i + 1]
                        c2 = ~(*imagedata) [offset + 3 * i + 2]
                    } else {
                        c0 = ~(*imagedata) [frame[Sane.FRAME_RED]   * lastoffset + offset + i]
                        c1 = ~(*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset + offset + i]
                        c2 = ~(*imagedata) [frame[Sane.FRAME_BLUE]  * lastoffset + offset + i]
                    }

                    var j: Int = 0
                    while j < 8 && 8 * i + j < bytesPerLine {
                        memory[writtenlines * fixedBytesPerLine + 8 * i + j] =
                            (((c0 << j) & 0x80) ? 4 : 0) +
                            (((c1 << j) & 0x80) ? 2 : 0) +
                            (((c2 << j) & 0x80) ? 1 : 0)
                        j++
                    }
                }
            } else if param.format == Sane.FRAME_RGB {
                for i in bytesPerLine {
                    if param.depth == 8 {
                        memory[writtenlines * fixedBytesPerLine + i] = (*imagedata) [offset + i]
                    } else if param.depth == 16 {
    // #ifdef __BIG_ENDIAN__
                        memory[writtenlines * fixedBytesPerLine + i] = (*imagedata) [offset + 2 * i]
    // #else
                        memory[writtenlines * fixedBytesPerLine + i] = (*imagedata) [offset + 2 * i + 1]
                    }
                }
            } else {
                for i in bytesPerLine / 3 {
                    if param.depth == 8 {
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 0] =
                            (*imagedata) [frame[Sane.FRAME_RED]   * lastoffset + offset + i]
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 1] =
                            (*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset + offset + i]
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 2] =
                            (*imagedata) [frame[Sane.FRAME_BLUE]  * lastoffset + offset + i]
                    } else if(param.depth == 16) {
    // #ifdef __BIG_ENDIAN__
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 0] =
                            (*imagedata) [frame[Sane.FRAME_RED]   * lastoffset + offset + 2 * i]
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 1] =
                            (*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset + offset + 2 * i]
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 2] =
                            (*imagedata) [frame[Sane.FRAME_BLUE]  * lastoffset + offset + 2 * i]
    // #else
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 0] =
                            (*imagedata) [frame[Sane.FRAME_RED]   * lastoffset + offset + 2 * i + 1]
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 1] =
                            (*imagedata) [frame[Sane.FRAME_GREEN] * lastoffset + offset + 2 * i + 1]
                        memory[writtenlines * fixedBytesPerLine + 3 * i + 2] =
                            (*imagedata) [frame[Sane.FRAME_BLUE]  * lastoffset + offset + 2 * i + 1]
                    }
                }
            }

            var i: Int = bytesPerLine
            while i < fixedBytesPerLine {
                memory[writtenlines * fixedBytesPerLine + i] = 0
                i++
            }

            offset += param.bytesPerLine
        }

        if imageMemoryTransfer.Memory.Flags & TWMF_HANDLE {
            HUnlock(Handle(imageMemoryTransfer).Memory.TheMem)
        }

        imageMemoryTransfer.BytesWritten = fixedBytesPerLine * writtenlines
        *yoffset += writtenlines

        return((*yoffset == param.lines) ? TWRC_XFERDONE : TWRC_SUCCESS)
    }


    public func TwainPalette8(palette8: Twain.Palette8, twainStatus: Twain.UINT16) -> Int {
        if param.format != Sane.FRAME_GRAY && param.depth == 1 {
            palette8.NumColors = 256
            palette8.PaletteType = TWPA_RGB
            for i in 8 {
                palette8.Colors[i].Index = i
                palette8.Colors[i].Channel1 = (i & 4 ? 0 : 255)
                palette8.Colors[i].Channel2 = (i & 2 ? 0 : 255)
                palette8.Colors[i].Channel3 = (i & 1 ? 0 : 255)
            }
            var i: Int = 8
            while i < 256 {
                palette8.Colors[i].Index = i
                palette8.Colors[i].Channel1 = 0
                palette8.Colors[i].Channel2 = 0
                palette8.Colors[i].Channel3 = 0
                i++
            }
            return TWRC_SUCCESS
        } else {
            *twainStatus = TWCC_BADPROTOCOL
            return Twain.RcFailure
        }
    }
}
