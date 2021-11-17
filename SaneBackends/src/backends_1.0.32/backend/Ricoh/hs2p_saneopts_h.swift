/* sane - Scanner Access Now Easy.
   Copyright(C) 2007 Jeremy Johnson
   This file is part of a SANE backend for Ricoh IS450
   and IS420 family of HS2P Scanners using the SCSI controller.

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.

   As a special exception, the authors of SANE give permission for
   additional uses of the libraries contained in this release of SANE.

   The exception is that, if you link a SANE library with other files
   to produce an executable, this does not by itself cause the
   resulting executable to be covered by the GNU General Public
   License.  Your use of that executable is in no way restricted on
   account of linking the SANE library code into it.

   This exception does not, however, invalidate any other reasons why
   the executable file might be covered by the GNU General Public
   License.

   If you submit changes to SANE to the maintainers to be included in
   a subsequent release, you agree by submitting the changes that
   those changes may be distributed with this exception intact.

   If you write modifications of your own for SANE, it is your choice
   whether to permit this exception to apply to your modifications.
   If you do not wish that, delete this exception notice. */


#define Sane.NAME_INQUIRY  "inquiry"
#define Sane.TITLE_INQUIRY "Inquiry Data"
#define Sane.DESC_INQUIRY  "Displays scanner inquiry data"

#define Sane.TITLE_SCAN_MODE_GROUP "Scan Mode"
#define Sane.TITLE_GEOMETRY_GROUP "Geometry"
#define Sane.TITLE_FEEDER_GROUP "Feeder"

#define Sane.TITLE_ENHANCEMENT_GROUP "Enhancement"
#define Sane.TITLE_ICON_GROUP "Icon"
#define Sane.TITLE_BARCODE_GROUP "Barcode"

#define Sane.TITLE_MISCELLANEOUS_GROUP "Miscellaneous"

#define Sane.NAME_AUTOBORDER "autoborder"
#define Sane.TITLE_AUTOBORDER "Autoborder"
#define Sane.DESC_AUTOBORDER "Enable Automatic Border Detection"

#define Sane.NAME_COMPRESSION "compression"
#define Sane.TITLE_COMPRESSION "Data Compression"
#define Sane.DESC_COMPRESSION "Sets the compression mode of the scanner"

#define Sane.NAME_ROTATION "rotation"
#define Sane.TITLE_ROTATION "Page Rotation"
#define Sane.DESC_ROTATION "Sets the page rotation mode of the scanner"

#define Sane.NAME_DESKEW "deskew"
#define Sane.TITLE_DESKEW "Page Deskew"
#define Sane.DESC_DESKEW "Enable Deskew Mode"

#define Sane.NAME_TIMEOUT_ADF "timeout-adf"
#define Sane.TITLE_TIMEOUT_ADF "ADF Timeout"
#define Sane.DESC_TIMEOUT_ADF "Sets the timeout in seconds for the ADF"

#define Sane.NAME_TIMEOUT_MANUAL "timeout-manual"
#define Sane.TITLE_TIMEOUT_MANUAL "Manual Timeout"
#define Sane.DESC_TIMEOUT_MANUAL "Sets the timeout in seconds for manual feeder"

#define Sane.NAME_BATCH "batch"
#define Sane.TITLE_BATCH "Batch"
#define Sane.DESC_BATCH "Enable Batch Mode"

#define Sane.NAME_CHECK_ADF "check-adf"
#define Sane.TITLE_CHECK_ADF "Check ADF"
#define Sane.DESC_CHECK_ADF "Check ADF Status prior to starting scan"

#define Sane.NAME_PREFEED "prefeed"
#define Sane.TITLE_PREFEED "Prefeed"
#define Sane.DESC_PREFEED "Prefeed"

#define Sane.NAME_DUPLEX "duplex"
#define Sane.TITLE_DUPLEX "Duplex"
#define Sane.DESC_DUPLEX "Enable Duplex(Dual-Sided) Scanning"

#define Sane.NAME_ENDORSER  "endorser"
#define Sane.TITLE_ENDORSER "Endorser"
#define Sane.DESC_ENDORSER  "Print up to 19 character string on each sheet"

#define Sane.NAME_ENDORSER_STRING  "endorser-string"
#define Sane.TITLE_ENDORSER_STRING "Endorser String"
#define Sane.DESC_ENDORSER_STRING  "valid characters: [0-9][ :#`"-./][A-Z][a-z]"

#define Sane.NAME_BARCODE_SEARCH_COUNT "barcode-search-count"
#define Sane.TITLE_BARCODE_SEARCH_COUNT "Barcode Search Count"
#define Sane.DESC_BARCODE_SEARCH_COUNT "Number of barcodes to search for in the scanned image"

#define Sane.NAME_BARCODE_HMIN "barcode-hmin"
#define Sane.TITLE_BARCODE_HMIN "Barcode Minimum Height"
#define Sane.DESC_BARCODE_HMIN "Sets the Barcode Minimum Height(larger values increase recognition speed)"

#define Sane.NAME_BARCODE_SEARCH_MODE "barcode-search-mode"
#define Sane.TITLE_BARCODE_SEARCH_MODE "Barcode Search Mode"
#define Sane.DESC_BARCODE_SEARCH_MODE "Chooses the orientation of barcodes to be searched"

#define Sane.NAME_BARCODE_SEARCH_TIMEOUT "barcode-search-timeout"
#define Sane.TITLE_BARCODE_SEARCH_TIMEOUT "Barcode Search Timeout"
#define Sane.DESC_BARCODE_SEARCH_TIMEOUT "Sets the timeout for barcode searching"

#define Sane.NAME_BARCODE_SEARCH_BAR "barcode-search-bar"
#define Sane.TITLE_BARCODE_SEARCH_BAR "Barcode Search Bar"
#define Sane.DESC_BARCODE_SEARCH_BAR "Specifies the barcode type to search for"

#define Sane.NAME_SECTION "section"
#define Sane.TITLE_SECTION "Image/Barcode Search Sections"
#define Sane.DESC_SECTION "Specifies an image section and/or a barcode search region"

#define Sane.NAME_BARCODE_RELMAX "barcode-relmax"
#define Sane.TITLE_BARCODE_RELMAX "Barcode RelMax"
#define Sane.DESC_BARCODE_RELMAX "Specifies the maximum relation from the widest to the smallest bar"

#define Sane.NAME_BARCODE_BARMIN "barcode-barmin"
#define Sane.TITLE_BARCODE_BARMIN "Barcode Bar Minimum"
#define Sane.DESC_BARCODE_BARMIN "Specifies the minimum number of bars in Bar/Patch code"

#define Sane.NAME_BARCODE_BARMAX "barcode-barmax"
#define Sane.TITLE_BARCODE_BARMAX "Barcode Bar Maximum"
#define Sane.DESC_BARCODE_BARMAX "Specifies the maximum number of bars in a Bar/Patch code"

#define Sane.NAME_BARCODE_CONTRAST "barcode-contrast"
#define Sane.TITLE_BARCODE_CONTRAST "Barcode Contrast"
#define Sane.DESC_BARCODE_CONTRAST "Specifies the image contrast used in decoding.  Use higher values when " \
"there are more white pixels in the code"

#define Sane.NAME_BARCODE_PATCHMODE "barcode-patchmode"
#define Sane.TITLE_BARCODE_PATCHMODE "Barcode Patch Mode"
#define Sane.DESC_BARCODE_PATCHMODE "Controls Patch Code detection."

#define Sane.NAME_SCAN_WAIT_MODE "scan-wait-mode"
#define Sane.TITLE_SCAN_WAIT_MODE "Scan Wait Mode "
#define Sane.DESC_SCAN_WAIT_MODE "Enables the scanner"s start button"

#define Sane.NAME_ACE_FUNCTION "ace-function"
#define Sane.TITLE_ACE_FUNCTION "ACE Function"
#define Sane.DESC_ACE_FUNCTION "ACE Function"

#define Sane.NAME_ACE_SENSITIVITY "ace-sensitivity"
#define Sane.TITLE_ACE_SENSITIVITY "ACE Sensitivity"
#define Sane.DESC_ACE_SENSITIVITY "ACE Sensitivity"

#define Sane.NAME_ICON_WIDTH "icon-width"
#define Sane.TITLE_ICON_WIDTH "Icon Width"
#define Sane.DESC_ICON_WIDTH "Width of icon(thumbnail) image in pixels"

#define Sane.NAME_ICON_LENGTH "icon-length"
#define Sane.TITLE_ICON_LENGTH "Icon Length"
#define Sane.DESC_ICON_LENGTH "Length of icon(thumbnail) image in pixels"

#define Sane.NAME_ORIENTATION "orientation"
#define Sane.TITLE_ORIENTATION "Paper Orientation"
#define Sane.DESC_ORIENTATION "[Portrait]/Landscape" \

#define Sane.NAME_PAPER_SIZE "paper-size"
#define Sane.TITLE_PAPER_SIZE "Paper Size"
#define Sane.DESC_PAPER_SIZE "Specify the scan window geometry by specifying the paper size " \
"of the documents to be scanned"

#define Sane.NAME_PADDING "padding"
#define Sane.TITLE_PADDING "Padding"
#define Sane.DESC_PADDING "Pad if media length is less than requested"

#define Sane.NAME_AUTO_SIZE "auto-size"
#define Sane.TITLE_AUTO_SIZE "Auto Size"
#define Sane.DESC_AUTO_SIZE "Automatic Paper Size Determination"

#define Sane.NAME_BINARYFILTER "binary-filter"
#define Sane.TITLE_BINARYFILTER "Binary Filter"
#define Sane.DESC_BINARYFILTER "Binary Filter"

#define Sane.NAME_SMOOTHING "smoothing"
#define Sane.TITLE_SMOOTHING "Smoothing"
#define Sane.DESC_SMOOTHING "Binary Smoothing Filter"

#define Sane.NAME_NOISEREMOVAL "noise-removal"
#define Sane.TITLE_NOISEREMOVAL "Noise Removal"
#define Sane.DESC_NOISEREMOVAL "Binary Noise Removal Filter"

#define Sane.NAME_NOISEMATRIX "noise-removal-matrix"
#define Sane.TITLE_NOISEMATRIX "Noise Removal Matrix"
#define Sane.DESC_NOISEMATRIX "Noise Removal Matrix"

#define Sane.NAME_GRAYFILTER "gray-filter"
#define Sane.TITLE_GRAYFILTER "Gray Filter"
#define Sane.DESC_GRAYFILTER "Gray Filter"

#define Sane.NAME_HALFTONE_CODE "halftone-type"
#define Sane.TITLE_HALFTONE_CODE "Halftone Type"
#define Sane.DESC_HALFTONE_CODE  "Dither or Error Diffusion"

/*
#define Sane.NAME_HALFTONE_PATTERN "pattern"
#define Sane.TITLE_HALFTONE_PATTERN "Pattern"
#define Sane.DESC_HALFTONE_PATTERN  "10 built-in halftone patterns + 2 user patterns"
*/

#define Sane.NAME_ERRORDIFFUSION "error-diffusion"
#define Sane.TITLE_ERRORDIFFUSION "Error Diffusion"
#define Sane.DESC_ERRORDIFFUSION  "Useful for documents with both text and images"

/*
#define Sane.NAME_HALFTONE "halftone"
#define Sane.TITLE_HALFTONE "Halftone"
#define Sane.DESC_HALFTONE "Choose a dither pattern or error diffusion"

#define Sane.NAME_NEGATIVE "negative image"
#define Sane.TITLE_NEGATIVE "Negative Image"
#define Sane.DESC_NEGATIVE "Reverse Image Format"

#define Sane.NAME_BRIGHTNESS "brightness"
#define Sane.TITLE_BRIGHTNESS "Brightness"
#define Sane.DESC_BRIGHTNESS "Brightness"

#define Sane.NAME_THRESHOLD "threshold"
#define Sane.TITLE_THRESHOLD "Threshold"
#define Sane.DESC_THRESHOLD "Threshold"
*/

#define Sane.NAME_GAMMA "gamma"
#define Sane.TITLE_GAMMA "Gamma"
#define Sane.DESC_GAMMA "Gamma Correction"

#define Sane.NAME_AUTOSEP "auto-separation"
#define Sane.TITLE_AUTOSEP "Automatic Separation"
#define Sane.DESC_AUTOSEP "Automatic Separation"

#define Sane.NAME_AUTOBIN "auto-binarization"
#define Sane.TITLE_AUTOBIN "Automatic Binarization"
#define Sane.DESC_AUTOBIN "Automatic Binarization"

#define Sane.NAME_WHITE_BALANCE "white-balance"
#define Sane.TITLE_WHITE_BALANCE "White Balance"
#define Sane.DESC_WHITE_BALANCE  "White Balance"

#define Sane.NAME_PADDING_TYPE "padding-type"
#define Sane.TITLE_PADDING_TYPE "Padding Type"
#define Sane.DESC_PADDING_TYPE  "Padding Type"

#define Sane.NAME_BITORDER "bit-order"
#define Sane.TITLE_BITORDER "Bit Order"
#define Sane.DESC_BITORDER  "Bit Order"

#define Sane.NAME_SELF_DIAGNOSTICS "self-diagnostics"
#define Sane.TITLE_SELF_DIAGNOSTICS "Self Diagnostics"
#define Sane.DESC_SELF_DIAGNOSTICS "Self Diagnostics"

#define Sane.NAME_OPTICAL_ADJUSTMENT "optical-adjustment"
#define Sane.TITLE_OPTICAL_ADJUSTMENT "Optical Adjustment"
#define Sane.DESC_OPTICAL_ADJUSTMENT "Optical Adjustment"

typedef enum
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_INQUIRY,			/* inquiry string */
  OPT_PREVIEW,
  OPT_SCAN_MODE,		/* scan mode */
  OPT_RESOLUTION,
  OPT_X_RESOLUTION,
  OPT_Y_RESOLUTION,
  OPT_COMPRESSION,		/* hardware compression */

  OPT_GEOMETRY_GROUP,
  /*OPT_AUTOBORDER,       automatic border detection */
  /*OPT_ROTATION,         hardware rotation */
  /*OPT_DESKEW,           hardware deskew */
  OPT_PAGE_ORIENTATION,		/* portrait, landscape */
  OPT_PAPER_SIZE,		/* paper size */
  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */
  OPT_PADDING,			/* Pad to requested length */
  OPT_AUTO_SIZE,		/* Automatic Size Recognition */

  OPT_FEEDER_GROUP,
  OPT_SCAN_SOURCE,		/* scan source(eg. Flatbed, ADF) */
  OPT_DUPLEX,			/* scan both sides of the page */
  OPT_SCAN_WAIT_MODE,		/* Enables the scanner"s Start Button */
  OPT_PREFEED,
  OPT_ENDORSER,			/* Endorser(off,on) */
  OPT_ENDORSER_STRING,		/* Endorser String */
  /*OPT_BATCH,              scan in batch mode */
  /*OPT_TIMEOUT_MANUAL,     timeout in seconds with manual feed */
  /*OPT_TIMEOUT_ADF,        timeout in seconds with ADF */
  /*OPT_CHECK_ADF,          check for page in ADF before scanning */

  OPT_ENHANCEMENT_GROUP,
  /* OPT_ACE_FUNCTION,
     OPT_ACE_SENSITIVITY, */
  OPT_BRIGHTNESS,		/* Brightness */
  OPT_THRESHOLD,		/* Threshold */
  OPT_CONTRAST,			/* Contrast */
  OPT_NEGATIVE,			/* Negative(reverse image) */
  OPT_GAMMA,			/* Gamma Correction */
  OPT_CUSTOM_GAMMA,
  OPT_GAMMA_VECTOR_GRAY,
  OPT_HALFTONE_CODE,		/* Halftone Code    */
  OPT_HALFTONE_PATTERN,		/* Halftone Pattern */
  OPT_GRAYFILTER,		/* MRIF */
  OPT_SMOOTHING,		/* Smoothing */
  OPT_NOISEREMOVAL,		/* Noise Removal */
  OPT_AUTOSEP,			/* Auto Separation */
  OPT_AUTOBIN,			/* Auto Binarization */
  OPT_WHITE_BALANCE,

  OPT_MISCELLANEOUS_GROUP,
  OPT_PADDING_TYPE,
  /*OPT_BITORDER,      */
  OPT_SELF_DIAGNOSTICS,
  OPT_OPTICAL_ADJUSTMENT,
  /*
     OPT_PARITION_FUNCTION
     OPT_SECTION
   */

  OPT_DATA_GROUP,
  OPT_UPDATE,
  OPT_NREGX_ADF,
  OPT_NREGY_ADF,
  OPT_NREGX_BOOK,
  OPT_NREGY_BOOK,
  OPT_NSCANS_ADF,
  OPT_NSCANS_BOOK,
  OPT_LAMP_TIME,
  OPT_EO_ODD,
  OPT_EO_EVEN,
  OPT_BLACK_LEVEL_ODD,
  OPT_BLACK_LEVEL_EVEN,
  OPT_WHITE_LEVEL_ODD,
  OPT_WHITE_LEVEL_EVEN,
  OPT_DENSITY,
  OPT_FIRST_ADJ_WHITE_ODD,
  OPT_FIRST_ADJ_WHITE_EVEN,
  OPT_NREGX_REVERSE,
  OPT_NREGY_REVERSE,
  OPT_NSCANS_REVERSE_ADF,
  OPT_REVERSE_TIME,
  OPT_NCHARS,

  NUM_OPTIONS			/* must come last: */
} HS2P_Option
