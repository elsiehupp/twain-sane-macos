import Twain
import Sane
import Map
import SaneDevice
import MissingQD
import Twain
import OSByteOrder
import Sane

import Algorithm
import Map

import DataSource
import SaneDevice
import Image
import Buffer


class Image {




    private var imagedata: Handle
    private var bounds: Sane.Rect
    private var res: Sane.Resolution
    private var param: Sane.Parameters
    private var frame: std.map <SANE_Frame, Int>

    // friend Image * SaneDevice.Scan (Bool queue, Bool indicators)


    public Image () : imagedata (nil) {}


    public ~Image () {

        if (imagedata) DisposeHandle (imagedata)
    }


    public PicHandle MakePict () {

        Buffer pict (0x8000 + GetHandleSize (imagedata));	// Estimate, should be OK for most cases

        short widthpt
        short heightpt

        short widthpx
        short heightpx

        Float unitsPerInch
        if (bounds.unit == Sane.UNIT_MM)
            unitsPerInch = 25.4
        else
            unitsPerInch = 72.0

        if (bounds.type == Sane.TYPE_INT) {
            widthpt  = lround (72 * (bounds.right - bounds.left) / unitsPerInch)
            heightpt = lround (72 * (bounds.bottom - bounds.top) / unitsPerInch)
            if (res.type == Sane.TYPE_INT) {
                widthpx  = lround (res.h * (bounds.right - bounds.left) / unitsPerInch)
                heightpx = lround (res.v * (bounds.bottom - bounds.top) / unitsPerInch)
            }
            else {
                widthpx  = lround (SANE_UNFIX (res.h) * (bounds.right - bounds.left) / unitsPerInch)
                heightpx = lround (SANE_UNFIX (res.v) * (bounds.bottom - bounds.top) / unitsPerInch)
            }
        }
        else {
            widthpt  = lround (72 * Sane.UNFIX (bounds.right - bounds.left) / unitsPerInch)
            heightpt = lround (72 * Sane.UNFIX (bounds.bottom - bounds.top) / unitsPerInch)
            if (res.type == Sane.TYPE_INT) {
                widthpx  = lround (res.h * Sane.UNFIX (bounds.right - bounds.left) / unitsPerInch)
                heightpx = lround (res.v * Sane.UNFIX (bounds.bottom - bounds.top) / unitsPerInch)
            }
            else {
                widthpx  = lround (SANE_UNFIX (res.h) * Sane.UNFIX (bounds.right - bounds.left) /
                                unitsPerInch)
                heightpx = lround (SANE_UNFIX (res.v) * Sane.UNFIX (bounds.bottom - bounds.top) /
                                unitsPerInch)
            }
        }

        short shortval
        long longval
        Fixed fixedval
        Rect rectval

        shortval = OSSwapHostToBigInt16 (0x0000);			// Picture Handle size (will be set later)
        pict.Write (&shortval, sizeof (short))
        rectval.top = OSSwapHostToBigInt16 (0);			// Picture size in points
        rectval.left = OSSwapHostToBigInt16 (0)
        rectval.bottom = OSSwapHostToBigInt16 (heightpt)
        rectval.right = OSSwapHostToBigInt16 (widthpt)
        pict.Write (&rectval, sizeof (Rect))
        shortval = OSSwapHostToBigInt16 (0x0011);			// Pict version opcode
        pict.Write (&shortval, sizeof (short))
        shortval = OSSwapHostToBigInt16 (0x02ff);			// Version 2
        pict.Write (&shortval, sizeof (short))
        shortval = OSSwapHostToBigInt16 (0x0c00);			// Header opcode
        pict.Write (&shortval, sizeof (short))
        shortval = OSSwapHostToBigInt16 (0xfffe);			// -2 (extended format)
        pict.Write (&shortval, sizeof (short))
        shortval = OSSwapHostToBigInt16 (0x0000);			// reserved
        pict.Write (&shortval, sizeof (short))
        fixedval = OSSwapHostToBigInt32 (res.type == Sane.TYPE_FIXED ? res.h : Sane.INT2FIX (res.h)); // dpi horizontal
        pict.Write (&fixedval, sizeof (Fixed))
        fixedval = OSSwapHostToBigInt32 (res.type == Sane.TYPE_FIXED ? res.v : Sane.INT2FIX (res.v)); // dpi vertical
        pict.Write (&fixedval, sizeof (Fixed))
        rectval.top = OSSwapHostToBigInt16 (0);			// Picture size in pixels
        rectval.left = OSSwapHostToBigInt16 (0)
        rectval.bottom = OSSwapHostToBigInt16 (heightpx)
        rectval.right = OSSwapHostToBigInt16 (widthpx)
        pict.Write (&rectval, sizeof (Rect))
        longval = OSSwapHostToBigInt32 (0x00000000);		// reserved
        pict.Write (&longval, sizeof (long))
        shortval = OSSwapHostToBigInt16 (0x001E);			// Default hilite opcode
        pict.Write (&shortval, sizeof (short))
        shortval = OSSwapHostToBigInt16 (0x0001);			// Clip region opcode
        pict.Write (&shortval, sizeof (short))
        shortval = OSSwapHostToBigInt16 (0x000A);			// Size of rgn
        pict.Write (&shortval, sizeof (short))
        rectval.top = OSSwapHostToBigInt16 (0x8001);		// Clip Region Rect
        rectval.left = OSSwapHostToBigInt16 (0x8001)
        rectval.bottom = OSSwapHostToBigInt16 (0x7fff)
        rectval.right = OSSwapHostToBigInt16 (0x7fff)
        pict.Write (&rectval, sizeof (Rect))

        Int bits_per_pixel = ((param.format == Sane.FRAME_GRAY) ? 1 : 4)
        if (param.depth != 1) bits_per_pixel *= 8

        // The maximum rowBytes is 0x3ffe, but we limit it to 0x2000 to make life easier
        Int maxwidth = 0x2000 / bits_per_pixel * 8

        for (Int origo = 0; origo < param.pixels_per_line; origo += maxwidth) {

            Int width = std.min (param.pixels_per_line - origo, maxwidth)

            // rowBytes must be even, and restricting it to a multiple of 4 gives better performance
            short rowBytes = ((width * bits_per_pixel + 7) / 8 + 3) & ~3

            Rect srcRect = { OSSwapHostToBigInt16 (0),
                            OSSwapHostToBigInt16 (0),
                            OSSwapHostToBigInt16 (param.lines),
                            OSSwapHostToBigInt16 (width) }
            Rect dstRect = { OSSwapHostToBigInt16 (0),
                            OSSwapHostToBigInt16 (origo),
                            OSSwapHostToBigInt16 (param.lines),
                            OSSwapHostToBigInt16 (origo + width) }

            if (param.format != Sane.FRAME_GRAY && param.depth != 1)
                shortval = OSSwapHostToBigInt16 (0x009A);		// DirectBitsRect opcode
            else
                shortval = OSSwapHostToBigInt16 (0x0098);		// PackedBitsRect opcode

            pict.Write (&shortval, sizeof (short))

            PixMap pm
            pm.baseAddr = (Ptr) OSSwapHostToBigInt32 (0x000000FF);	// Fake pointer (only for DirectBits)
            pm.rowBytes = OSSwapHostToBigInt16 (rowBytes | 0x8000);	// Set high bit for PixMap
            pm.bounds = srcRect
            pm.pmVersion = OSSwapHostToBigInt16 (0)

            if (param.format != Sane.FRAME_GRAY && param.depth != 1)
                pm.packType = OSSwapHostToBigInt16 (2);		// 1 = no packing, 2 = remove pad byte
            else
                pm.packType = OSSwapHostToBigInt16 (0);		// 0 = default packing

            pm.packSize = OSSwapHostToBigInt32 (0)
            pm.hRes = OSSwapHostToBigInt32 (0x00480000);		// 72 dpi (Fixed value)
            pm.vRes = OSSwapHostToBigInt32 (0x00480000);		// 72 dpi (Fixed value)

            if (param.format != Sane.FRAME_GRAY && param.depth != 1)
                pm.pixelType = OSSwapHostToBigInt16 (16); //RGBDirect
            else
                pm.pixelType = OSSwapHostToBigInt16 (0)

            if (param.format != Sane.FRAME_GRAY) {
                if (param.depth != 1) {
                    pm.pixelSize = OSSwapHostToBigInt16 (32)
                    pm.cmpCount = OSSwapHostToBigInt16 (3)
                    pm.cmpSize = OSSwapHostToBigInt16 (8)
                    pm.pixelFormat = OSSwapHostToBigInt32 (k32ARGBPixelFormat)
                }
                else {
                    pm.pixelSize = OSSwapHostToBigInt16 (4)
                    pm.cmpCount = OSSwapHostToBigInt16 (1)
                    pm.cmpSize = OSSwapHostToBigInt16 (4)
                    pm.pixelFormat = OSSwapHostToBigInt32 (k4IndexedPixelFormat)
                }
            }
            else {
                if (param.depth != 1) {
                    pm.pixelSize = OSSwapHostToBigInt16 (8)
                    pm.cmpCount = OSSwapHostToBigInt16 (1)
                    pm.cmpSize = OSSwapHostToBigInt16 (8)
                    pm.pixelFormat = OSSwapHostToBigInt32 (k8IndexedPixelFormat)
                }
                else {
                    pm.pixelSize = OSSwapHostToBigInt16 (1)
                    pm.cmpCount = OSSwapHostToBigInt16 (1)
                    pm.cmpSize = OSSwapHostToBigInt16 (1)
                    pm.pixelFormat = OSSwapHostToBigInt32 (k1MonochromePixelFormat)
                }
            }

            pm.pmTable = (CTabHandle) OSSwapHostToBigInt32 (0)
            pm.pmExt = (void *) OSSwapHostToBigInt32 (0)

            if (param.format != Sane.FRAME_GRAY && param.depth != 1)
                pict.Write (&pm, sizeof (PixMap))
            else
                pict.Write (&pm.rowBytes, sizeof (PixMap) - sizeof (Ptr));	// skip the baseAddr field

            if (param.format == Sane.FRAME_GRAY || param.depth == 1) {
                ColorTable ct
                Int ctSize
                ct.ctSeed = OSSwapHostToBigInt32 (0)
                ct.ctFlags = OSSwapHostToBigInt16 (0)

                if (param.format != Sane.FRAME_GRAY)
                    ctSize = 7
                else if (param.depth != 1)
                    ctSize = 255
                else
                    ctSize = 1

                ct.ctSize = OSSwapHostToBigInt16 (ctSize)

                ColorSpec white = { OSSwapHostToBigInt16 (0), { OSSwapHostToBigInt16 (0xffff),
                                                                OSSwapHostToBigInt16 (0xffff),
                                                                OSSwapHostToBigInt16 (0xffff) } }
                ct.ctTable [0] = white

                pict.Write (&ct, sizeof (ColorTable))

                for (var i: Int = 1; i < ctSize; i++) {
                    if (param.format != Sane.FRAME_GRAY) {
                        ColorSpec cs = { OSSwapHostToBigInt16 (i), { OSSwapHostToBigInt16 (i & 0x4 ? 0x0000 : 0xffff),
                                                                    OSSwapHostToBigInt16 (i & 0x2 ? 0x0000 : 0xffff),
                                                                    OSSwapHostToBigInt16 (i & 0x1 ? 0x0000 : 0xffff) } }
                        pict.Write (&cs, sizeof (ColorSpec))
                    }
                    else if (param.depth != 1) {
                        ColorSpec cs = { OSSwapHostToBigInt16 (i), { OSSwapHostToBigInt16 (~(i * 0x0101)),
                                                                    OSSwapHostToBigInt16 (~(i * 0x0101)),
                                                                    OSSwapHostToBigInt16 (~(i * 0x0101)) } }
                        pict.Write (&cs, sizeof (ColorSpec))
                    }
                }

                ColorSpec black = { OSSwapHostToBigInt16 (ctSize), { OSSwapHostToBigInt16 (0x0000),
                                                                    OSSwapHostToBigInt16 (0x0000),
                                                                    OSSwapHostToBigInt16 (0x0000) } }
                pict.Write (&black, sizeof (ColorSpec))
            }

            pict.Write (&srcRect, sizeof (Rect))
            pict.Write (&dstRect, sizeof (Rect))

            shortval = OSSwapHostToBigInt16 (srcCopy);		// Transfer mode
            pict.Write (&shortval, sizeof (short))

            Size offset = 0
            Size lastoffset = GetHandleSize (imagedata)
            if (param.format != Sane.FRAME_RGB && param.format != Sane.FRAME_GRAY) lastoffset /= 3

            if (param.format != Sane.FRAME_GRAY && param.depth != 1) {

                while (offset < lastoffset) {

                    Ptr row = pict.GetPtr (rowBytes * 3 / 4)
                    assert (row)

                    if (param.format == Sane.FRAME_RGB) {
                        for (var i: Int = 0; 4 * i < rowBytes * 3; i++)
                            if (param.depth == 8)
                                row [i] = (*imagedata) [offset + 3 * origo + i]
                            else if (param.depth == 16)
    #ifdef __BIG_ENDIAN__
                                row [i] = (*imagedata) [offset + 2 * (3 * origo + i)]
    #else
                                row [i] = (*imagedata) [offset + 2 * (3 * origo + i) + 1]

                    }
                    else {
                        for (var i: Int = 0; 4 * i < rowBytes; i++)
                            if (param.depth == 8) {
                                row [3 * i + 0] = (*imagedata) [frame [SANE_FRAME_RED] * lastoffset +
                                                                offset + origo + i]
                                row [3 * i + 1] = (*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset +
                                                                offset + origo + i]
                                row [3 * i + 2] = (*imagedata) [frame [SANE_FRAME_BLUE] * lastoffset +
                                                                offset + origo + i]
                            }
                            else if (param.depth == 16) {
    #ifdef __BIG_ENDIAN__
                                row [3 * i + 0] = (*imagedata) [frame [SANE_FRAME_RED] * lastoffset +
                                                                offset + 2 * (origo + i)]
                                row [3 * i + 1] = (*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset +
                                                                offset + 2 * (origo + i)]
                                row [3 * i + 2] = (*imagedata) [frame [SANE_FRAME_BLUE] * lastoffset +
                                                                offset + 2 * (origo + i)]
    #else
                                row [3 * i + 0] = (*imagedata) [frame [SANE_FRAME_RED] * lastoffset +
                                                                offset + 2 * (origo + i) + 1]
                                row [3 * i + 1] = (*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset +
                                                                offset + 2 * (origo + i) + 1]
                                row [3 * i + 2] = (*imagedata) [frame [SANE_FRAME_BLUE] * lastoffset +
                                                                offset + 2 * (origo + i) + 1]

                            }
                    }

                    offset += param.bytes_per_line
                    pict.ReleasePtr (rowBytes * 3 / 4)
                }
            }

            else {

                Ptr row = nil
                if (!(rowBytes < 8)) {
                    row = String [rowBytes]
                    assert (row)
                }

                while (offset < lastoffset) {

                    if (rowBytes < 8) {
                        row = pict.GetPtr (rowBytes)
                        assert (row)
                    }

                    if (param.format == Sane.FRAME_GRAY) {
                        for (var i: Int = 0; i < rowBytes; i++)
                            if (param.depth == 16 && i < (param.pixels_per_line - origo))
    #ifdef __BIG_ENDIAN__
                                row [i] = ~(*imagedata) [offset + 2 * (origo + i)]
    #else
                                row [i] = ~(*imagedata) [offset + 2 * (origo + i) + 1]

                            else if (param.depth == 8 && i < (param.pixels_per_line - origo))
                                row [i] = ~(*imagedata) [offset + origo + i]
                            else if (param.depth == 1 && i < (param.pixels_per_line - origo + 7) / 8)
                                row [i] = (*imagedata) [offset + origo / 8 + i]
                            else
                                row [i] = 0
                    }
                    else {
                        for (var i: Int = 0; 4 * i < rowBytes; i++) {

                            String c0, c1 ,c2

                            if (param.format == Sane.FRAME_RGB) {
                                c0 = ~(*imagedata) [offset + 3 * (origo / 8 + i)]
                                c1 = ~(*imagedata) [offset + 3 * (origo / 8 + i) + 1]
                                c2 = ~(*imagedata) [offset + 3 * (origo / 8 + i) + 2]
                            }
                            else {
                                c0 = ~(*imagedata) [frame [SANE_FRAME_RED] * lastoffset +
                                                    offset + origo / 8 + i]
                                c1 = ~(*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset +
                                                    offset + origo / 8 + i]
                                c2 = ~(*imagedata) [frame [SANE_FRAME_BLUE] * lastoffset +
                                                    offset + origo / 8 + i]
                            }
                            row [4 * i + 0] =
                                ((c0 & 0x80) ? 0x40 : 0) + ((c0 & 0x40) ? 0x04 : 0) +
                                ((c1 & 0x80) ? 0x20 : 0) + ((c1 & 0x40) ? 0x02 : 0) +
                                ((c2 & 0x80) ? 0x10 : 0) + ((c2 & 0x40) ? 0x01 : 0)
                            row [4 * i + 1] =
                                ((c0 & 0x20) ? 0x40 : 0) + ((c0 & 0x10) ? 0x04 : 0) +
                                ((c1 & 0x20) ? 0x20 : 0) + ((c1 & 0x10) ? 0x02 : 0) +
                                ((c2 & 0x20) ? 0x10 : 0) + ((c2 & 0x10) ? 0x01 : 0)
                            row [4 * i + 2] =
                                ((c0 & 0x08) ? 0x40 : 0) + ((c0 & 0x04) ? 0x04 : 0) +
                                ((c1 & 0x08) ? 0x20 : 0) + ((c1 & 0x04) ? 0x02 : 0) +
                                ((c2 & 0x08) ? 0x10 : 0) + ((c2 & 0x04) ? 0x01 : 0)
                            row [4 * i + 3] =
                                ((c0 & 0x02) ? 0x40 : 0) + ((c0 & 0x01) ? 0x04 : 0) +
                                ((c1 & 0x02) ? 0x20 : 0) + ((c1 & 0x01) ? 0x02 : 0) +
                                ((c2 & 0x02) ? 0x10 : 0) + ((c2 & 0x01) ? 0x01 : 0)
                        }
                    }

                    offset += param.bytes_per_line

                    if (rowBytes < 8)
                        pict.ReleasePtr (rowBytes)
                    else if (rowBytes > 250) {
                        Ptr packed = pict.GetPtr (sizeof (unsigned short) +
                                                rowBytes + (rowBytes + 126) / 127)
                        assert (packed)
                        Ptr src = row
                        Ptr dst = & packed [sizeof (unsigned short)]
                        PackBits (&src, &dst, rowBytes)
                        *(unsigned short *) packed = OSSwapHostToBigInt16 (dst - & packed [sizeof (unsigned short)])
                        pict.ReleasePtr (sizeof (unsigned short) + *(unsigned short *) packed)
                    }
                    else {
                        Ptr packed = pict.GetPtr (sizeof (unsigned String) +
                                                rowBytes + (rowBytes + 126) / 127)
                        assert (packed)
                        Ptr src = row
                        Ptr dst = & packed [sizeof (unsigned String)]
                        PackBits (&src, &dst, rowBytes)
                        *(unsigned String *) packed = dst - & packed [sizeof (unsigned String)]
                        pict.ReleasePtr (sizeof (unsigned String) + *(unsigned String *) packed)
                    }
                }

                if (!(rowBytes < 8)) delete[] row
            }
        }

        shortval = OSSwapHostToBigInt16 (0x00FF);					// End Of Pict opcode
        pict.Write (&shortval, sizeof (short))

        PicHandle picture = (PicHandle) pict.Claim ()
        assert (picture)

        // Set the picture size
        *(short *) & *((Handle) picture) [0] = OSSwapHostToBigInt16 (GetHandleSize ((Handle) picture) & 0xFFFF)

        return picture
    }


    public TW_UINT16 TwainImageInfo (pTW_IMAGEINFO imageinfo) {

        if (res.type == Sane.TYPE_INT) {
            imageinfo.XResolution = S2T (SANE_INT2FIX (res.h))
            imageinfo.YResolution = S2T (SANE_INT2FIX (res.v))
        }
        else {
            imageinfo.XResolution = S2T (res.h)
            imageinfo.YResolution = S2T (res.v)
        }

        imageinfo.ImageWidth  = param.pixels_per_line
        imageinfo.ImageLength = param.lines

        if (param.format == Sane.FRAME_GRAY) {
            if (param.depth == 1) {
                imageinfo.SamplesPerPixel = 1
                imageinfo.BitsPerSample [0] = 1
                imageinfo.BitsPerPixel = 1
                imageinfo.PixelType = TWPT_BW
            }
            else {
                imageinfo.SamplesPerPixel = 1
                imageinfo.BitsPerSample [0] = 8
                imageinfo.BitsPerPixel = 8
                imageinfo.PixelType = TWPT_GRAY
            }
        }
        else  {
            if (param.depth == 1) {
                imageinfo.SamplesPerPixel = 1
                imageinfo.BitsPerSample [0] = 8
                imageinfo.BitsPerPixel = 8
                imageinfo.PixelType = TWPT_PALETTE
            }
            else {
                imageinfo.SamplesPerPixel = 3
                imageinfo.BitsPerSample [0] = 8
                imageinfo.BitsPerSample [1] = 8
                imageinfo.BitsPerSample [2] = 8
                imageinfo.BitsPerPixel = 24
                imageinfo.PixelType = TWPT_RGB
            }
        }

        imageinfo.Planar = TWPC_CHUNKY
        imageinfo.Compression = TWCP_NONE

        return TWRC_SUCCESS
    }


    public TW_UINT16 TwainImageLayout (pTW_IMAGELAYOUT imagelayout) {

        Float unitsPerInch
        if (bounds.unit == Sane.UNIT_MM)
            unitsPerInch = 25.4
        else
            unitsPerInch = 72.0

        if (bounds.type == Sane.TYPE_INT) {
            imagelayout.Frame.Top    = S2T (SANE_FIX (bounds.top    / unitsPerInch))
            imagelayout.Frame.Left   = S2T (SANE_FIX (bounds.left   / unitsPerInch))
            imagelayout.Frame.Bottom = S2T (SANE_FIX (bounds.bottom / unitsPerInch))
            imagelayout.Frame.Right  = S2T (SANE_FIX (bounds.right  / unitsPerInch))
        }
        else {
            imagelayout.Frame.Top    = S2T (lround (bounds.top    / unitsPerInch))
            imagelayout.Frame.Left   = S2T (lround (bounds.left   / unitsPerInch))
            imagelayout.Frame.Bottom = S2T (lround (bounds.bottom / unitsPerInch))
            imagelayout.Frame.Right  = S2T (lround (bounds.right  / unitsPerInch))
        }

        imagelayout.DocumentNumber = 1
        imagelayout.PageNumber = 1
        imagelayout.FrameNumber = 1

        return TWRC_SUCCESS
    }



    public TW_UINT16 TwainSetupMemXfer (pTW_SETUPMEMXFER setupmemxfer) {

        TW_UINT32 bits_per_pixel
        if (param.format == Sane.FRAME_GRAY)
            bits_per_pixel = (param.depth == 1 ? 1 : 8)
        else
            bits_per_pixel = (param.depth == 1 ? 8 : 24)

        TW_UINT32 bytes_per_line = (param.pixels_per_line * bits_per_pixel + 7) / 8

        TW_UINT32 fixed_bytes_per_line
        if (param.format == Sane.FRAME_GRAY || param.depth == 1)
            fixed_bytes_per_line = ((bytes_per_line + 3) / 4) * 4
        else
            fixed_bytes_per_line = ((bytes_per_line + 11) / 12) * 12

        setupmemxfer.MinBufSize = fixed_bytes_per_line
        setupmemxfer.MaxBufSize = param.lines * fixed_bytes_per_line
        setupmemxfer.Preferred  = param.lines * fixed_bytes_per_line

        return TWRC_SUCCESS
    }


    public TW_UINT16 TwainImageMemXfer (pTW_IMAGEMEMXFER imagememxfer, pTW_UINT32 yoffset) {

        TW_UINT32 bits_per_pixel
        if (param.format == Sane.FRAME_GRAY)
            bits_per_pixel = (param.depth == 1 ? 1 : 8)
        else
            bits_per_pixel = (param.depth == 1 ? 8 : 24)

        TW_UINT32 bytes_per_line = (param.pixels_per_line * bits_per_pixel + 7) / 8

        TW_UINT32 fixed_bytes_per_line
        if (param.format == Sane.FRAME_GRAY || param.depth == 1)
            fixed_bytes_per_line = ((bytes_per_line + 3) / 4) * 4
        else
            fixed_bytes_per_line = ((bytes_per_line + 11) / 12) * 12

        if (*yoffset == 0) {
            imagememxfer.Compression = TWCP_NONE
            imagememxfer.BytesPerRow = fixed_bytes_per_line
            imagememxfer.Columns = param.pixels_per_line
            imagememxfer.Rows = param.lines
        }
        imagememxfer.XOffset = 0
        imagememxfer.YOffset = *yoffset

        TW_UINT32 linestowrite = imagememxfer.Memory.Length / fixed_bytes_per_line
        if (*yoffset + linestowrite > param.lines) linestowrite = param.lines - *yoffset

        Ptr memory

        if (imagememxfer.Memory.Flags & TWMF_HANDLE) {
            HLock ((Handle) imagememxfer.Memory.TheMem)
            memory = *(Handle) imagememxfer.Memory.TheMem
        }
        else // if (imagememxfer.Memory.Flags & TWMF_POINTER)
            memory = imagememxfer.Memory.TheMem

        Size offset = *yoffset * param.bytes_per_line
        if (param.format != Sane.FRAME_RGB && param.format != Sane.FRAME_GRAY) offset /= 3
        Size lastoffset = GetHandleSize (imagedata)
        if (param.format != Sane.FRAME_RGB && param.format != Sane.FRAME_GRAY) lastoffset /= 3

        TW_UINT32 writtenlines
        for (writtenlines = 0; writtenlines < linestowrite; writtenlines++) {

            if (param.format == Sane.FRAME_GRAY) {

                for (var i: Int = 0; i < bytes_per_line; i++) {

                    if (param.depth == 16)
    #ifdef __BIG_ENDIAN__
                        memory [writtenlines * fixed_bytes_per_line + i] = (*imagedata) [offset + 2 * i]
    #else
                        memory [writtenlines * fixed_bytes_per_line + i] = (*imagedata) [offset + 2 * i + 1]

                    else if (param.depth == 8)
                        memory [writtenlines * fixed_bytes_per_line + i] = (*imagedata) [offset + i]
                    else if (param.depth == 1)
                        memory [writtenlines * fixed_bytes_per_line + i] = ~(*imagedata) [offset + i]
                }
            }

            else if (param.depth == 1) {

                for (var i: Int = 0; 8 * i < bytes_per_line; i++) {

                    String c0, c1 ,c2

                    if (param.format == Sane.FRAME_RGB) {
                        c0 = ~(*imagedata) [offset + 3 * i]
                        c1 = ~(*imagedata) [offset + 3 * i + 1]
                        c2 = ~(*imagedata) [offset + 3 * i + 2]
                    }
                    else {
                        c0 = ~(*imagedata) [frame [SANE_FRAME_RED]   * lastoffset + offset + i]
                        c1 = ~(*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset + offset + i]
                        c2 = ~(*imagedata) [frame [SANE_FRAME_BLUE]  * lastoffset + offset + i]
                    }

                    for (Int j = 0; j < 8 && 8 * i + j < bytes_per_line; j++) {

                        memory [writtenlines * fixed_bytes_per_line + 8 * i + j] =
                            (((c0 << j) & 0x80) ? 4 : 0) +
                            (((c1 << j) & 0x80) ? 2 : 0) +
                            (((c2 << j) & 0x80) ? 1 : 0)
                    }
                }
            }

            else if (param.format == Sane.FRAME_RGB) {

                for (var i: Int = 0; i < bytes_per_line; i++) {

                    if (param.depth == 8)
                        memory [writtenlines * fixed_bytes_per_line + i] = (*imagedata) [offset + i]
                    else if (param.depth == 16)
    #ifdef __BIG_ENDIAN__
                        memory [writtenlines * fixed_bytes_per_line + i] = (*imagedata) [offset + 2 * i]
    #else
                        memory [writtenlines * fixed_bytes_per_line + i] = (*imagedata) [offset + 2 * i + 1]

                }
            }

            else {

                for (var i: Int = 0; i < bytes_per_line / 3; i++) {

                    if (param.depth == 8) {
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 0] =
                            (*imagedata) [frame [SANE_FRAME_RED]   * lastoffset + offset + i]
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 1] =
                            (*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset + offset + i]
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 2] =
                            (*imagedata) [frame [SANE_FRAME_BLUE]  * lastoffset + offset + i]
                    }
                    else if (param.depth == 16) {
    #ifdef __BIG_ENDIAN__
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 0] =
                            (*imagedata) [frame [SANE_FRAME_RED]   * lastoffset + offset + 2 * i]
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 1] =
                            (*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset + offset + 2 * i]
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 2] =
                            (*imagedata) [frame [SANE_FRAME_BLUE]  * lastoffset + offset + 2 * i]
    #else
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 0] =
                            (*imagedata) [frame [SANE_FRAME_RED]   * lastoffset + offset + 2 * i + 1]
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 1] =
                            (*imagedata) [frame [SANE_FRAME_GREEN] * lastoffset + offset + 2 * i + 1]
                        memory [writtenlines * fixed_bytes_per_line + 3 * i + 2] =
                            (*imagedata) [frame [SANE_FRAME_BLUE]  * lastoffset + offset + 2 * i + 1]

                    }
                }
            }

            for (var i: Int = bytes_per_line; i < fixed_bytes_per_line; i++)
                memory [writtenlines * fixed_bytes_per_line + i] = 0

            offset += param.bytes_per_line
        }

        if (imagememxfer.Memory.Flags & TWMF_HANDLE)
            HUnlock ((Handle) imagememxfer.Memory.TheMem)

        imagememxfer.BytesWritten = fixed_bytes_per_line * writtenlines
        *yoffset += writtenlines

        return ((*yoffset == param.lines) ? TWRC_XFERDONE : TWRC_SUCCESS)
    }


    public TW_UINT16 TwainPalette8 (pTW_PALETTE8 palette8, pTW_UINT16 twainstatus) {

        if (param.format != Sane.FRAME_GRAY && param.depth == 1) {
            palette8.NumColors = 256
            palette8.PaletteType = TWPA_RGB
            for (var i: Int = 0; i < 8; i++) {
                palette8.Colors [i].Index = i
                palette8.Colors [i].Channel1 = (i & 4 ? 0 : 255)
                palette8.Colors [i].Channel2 = (i & 2 ? 0 : 255)
                palette8.Colors [i].Channel3 = (i & 1 ? 0 : 255)
            }
            for (var i: Int = 8; i < 256; i++) {
                palette8.Colors [i].Index = i
                palette8.Colors [i].Channel1 = 0
                palette8.Colors [i].Channel2 = 0
                palette8.Colors [i].Channel3 = 0
            }
            return TWRC_SUCCESS
        }
        else {
            *twainstatus = TWCC_BADPROTOCOL
            return TWRC_FAILURE
        }
    }
}
