/* sane - Scanner Access Now Easy.
   Copyright (C) 1996, 1997 David Mosberger-Tang and Andreas Beck
   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your
   option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

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
   If you do not wish that, delete this exception notice.

   This file declares common option names, titles, and descriptions.  A
   backend is not limited to these options but for the sake of
   consistency it's better to use options declared here when appropriate.
*/

/* This file defines several option NAMEs, TITLEs and DESCs
   that are (or should be) used by several backends.

   All well known options should be listed here. But this does
   not mean that all options that are listed here are well known options.
   To find out if an option is a well known option and how well known
   options have to be defined please take a look at the sane standard!!!
 */
#ifndef saneopts_h
#define saneopts_h

#ifndef Sane.I18N
#define Sane.I18N(text) text
#endif

/* This _must_ be the first option (index 0): */
#define Sane.NAME_NUM_OPTIONS		""	/* never settable */

/* The common option groups */
#define Sane.NAME_STANDARD   		"standard"
#define Sane.NAME_GEOMETRY   		"geometry"
#define Sane.NAME_ENHANCEMENT		"enhancement"
#define Sane.NAME_ADVANCED   		"advanced"
#define Sane.NAME_SENSORS    		"sensors"

#define Sane.NAME_PREVIEW		"preview"
#define Sane.NAME_GRAY_PREVIEW		"preview-in-gray"
#define Sane.NAME_BIT_DEPTH		"depth"
#define Sane.NAME_SCAN_MODE		"mode"
#define Sane.NAME_SCAN_SPEED		"speed"
#define Sane.NAME_SCAN_SOURCE		"source"
#define Sane.NAME_BACKTRACK		"backtrack"
/* Most user-interfaces will let the user specify the scan area as the
   top-left corner and the width/height of the scan area.  The reason
   the backend interface uses the top-left/bottom-right corner is so
   that the scan area values can be properly constraint independent of
   any other option value.  */
#define Sane.NAME_SCAN_TL_X		"tl-x"
#define Sane.NAME_SCAN_TL_Y		"tl-y"
#define Sane.NAME_SCAN_BR_X		"br-x"
#define Sane.NAME_SCAN_BR_Y		"br-y"
#define Sane.NAME_SCAN_RESOLUTION	"resolution"
#define Sane.NAME_SCAN_X_RESOLUTION	"x-resolution"
#define Sane.NAME_SCAN_Y_RESOLUTION	"y-resolution"
#define Sane.NAME_PAGE_WIDTH  		"page-width"
#define Sane.NAME_PAGE_HEIGHT 		"page-height"
#define Sane.NAME_CUSTOM_GAMMA		"custom-gamma"
#define Sane.NAME_GAMMA_VECTOR		"gamma-table"
#define Sane.NAME_GAMMA_VECTOR_R	"red-gamma-table"
#define Sane.NAME_GAMMA_VECTOR_G	"green-gamma-table"
#define Sane.NAME_GAMMA_VECTOR_B	"blue-gamma-table"
#define Sane.NAME_BRIGHTNESS		"brightness"
#define Sane.NAME_CONTRAST		"contrast"
#define Sane.NAME_GRAIN_SIZE		"grain"
#define Sane.NAME_HALFTONE		"halftoning"
#define Sane.NAME_BLACK_LEVEL           "black-level"
#define Sane.NAME_WHITE_LEVEL           "white-level"
#define Sane.NAME_WHITE_LEVEL_R         "white-level-r"
#define Sane.NAME_WHITE_LEVEL_G         "white-level-g"
#define Sane.NAME_WHITE_LEVEL_B         "white-level-b"
#define Sane.NAME_SHADOW		"shadow"
#define Sane.NAME_SHADOW_R		"shadow-r"
#define Sane.NAME_SHADOW_G		"shadow-g"
#define Sane.NAME_SHADOW_B		"shadow-b"
#define Sane.NAME_HIGHLIGHT		"highlight"
#define Sane.NAME_HIGHLIGHT_R		"highlight-r"
#define Sane.NAME_HIGHLIGHT_G		"highlight-g"
#define Sane.NAME_HIGHLIGHT_B		"highlight-b"
#define Sane.NAME_HUE			"hue"
#define Sane.NAME_SATURATION		"saturation"
#define Sane.NAME_FILE			"filename"
#define Sane.NAME_HALFTONE_DIMENSION	"halftone-size"
#define Sane.NAME_HALFTONE_PATTERN	"halftone-pattern"
#define Sane.NAME_RESOLUTION_BIND	"resolution-bind"
#define Sane.NAME_NEGATIVE		"negative"
#define Sane.NAME_QUALITY_CAL		"quality-cal"
#define Sane.NAME_DOR			"double-res"
#define Sane.NAME_RGB_BIND		"rgb-bind"
#define Sane.NAME_THRESHOLD		"threshold"
#define Sane.NAME_ANALOG_GAMMA		"analog-gamma"
#define Sane.NAME_ANALOG_GAMMA_R	"analog-gamma-r"
#define Sane.NAME_ANALOG_GAMMA_G	"analog-gamma-g"
#define Sane.NAME_ANALOG_GAMMA_B	"analog-gamma-b"
#define Sane.NAME_ANALOG_GAMMA_BIND	"analog-gamma-bind"
#define Sane.NAME_WARMUP		"warmup"
#define Sane.NAME_CAL_EXPOS_TIME	"cal-exposure-time"
#define Sane.NAME_CAL_EXPOS_TIME_R	"cal-exposure-time-r"
#define Sane.NAME_CAL_EXPOS_TIME_G	"cal-exposure-time-g"
#define Sane.NAME_CAL_EXPOS_TIME_B	"cal-exposure-time-b"
#define Sane.NAME_SCAN_EXPOS_TIME	"scan-exposure-time"
#define Sane.NAME_SCAN_EXPOS_TIME_R	"scan-exposure-time-r"
#define Sane.NAME_SCAN_EXPOS_TIME_G	"scan-exposure-time-g"
#define Sane.NAME_SCAN_EXPOS_TIME_B	"scan-exposure-time-b"
#define Sane.NAME_SELECT_EXPOSURE_TIME	"select-exposure-time"
#define Sane.NAME_CAL_LAMP_DEN		"cal-lamp-density"
#define Sane.NAME_SCAN_LAMP_DEN		"scan-lamp-density"
#define Sane.NAME_SELECT_LAMP_DENSITY	"select-lamp-density"
#define Sane.NAME_LAMP_OFF_AT_EXIT	"lamp-off-at-exit"
#define Sane.NAME_FOCUS			"focus"
#define Sane.NAME_AUTOFOCUS		"autofocus"

/* well known options from 'SENSORS' group*/
#define Sane.NAME_SCAN			"scan"
#define Sane.NAME_EMAIL			"email"
#define Sane.NAME_FAX			"fax"
#define Sane.NAME_COPY			"copy"
#define Sane.NAME_PDF			"pdf"
#define Sane.NAME_CANCEL		"cancel"
#define Sane.NAME_PAGE_LOADED		"page-loaded"
#define Sane.NAME_COVER_OPEN		"cover-open"

#define Sane.TITLE_NUM_OPTIONS		Sane.I18N("Number of options")

#define Sane.TITLE_STANDARD   		Sane.I18N("Standard")
#define Sane.TITLE_GEOMETRY   		Sane.I18N("Geometry")
#define Sane.TITLE_ENHANCEMENT		Sane.I18N("Enhancement")
#define Sane.TITLE_ADVANCED   		Sane.I18N("Advanced")
#define Sane.TITLE_SENSORS    		Sane.I18N("Sensors")

#define Sane.TITLE_PREVIEW		Sane.I18N("Preview")
#define Sane.TITLE_GRAY_PREVIEW		Sane.I18N("Force monochrome preview")
#define Sane.TITLE_BIT_DEPTH		Sane.I18N("Bit depth")
#define Sane.TITLE_SCAN_MODE		Sane.I18N("Scan mode")
#define Sane.TITLE_SCAN_SPEED		Sane.I18N("Scan speed")
#define Sane.TITLE_SCAN_SOURCE		Sane.I18N("Scan source")
#define Sane.TITLE_BACKTRACK		Sane.I18N("Force backtracking")
#define Sane.TITLE_SCAN_TL_X		Sane.I18N("Top-left x")
#define Sane.TITLE_SCAN_TL_Y		Sane.I18N("Top-left y")
#define Sane.TITLE_SCAN_BR_X		Sane.I18N("Bottom-right x")
#define Sane.TITLE_SCAN_BR_Y		Sane.I18N("Bottom-right y")
#define Sane.TITLE_SCAN_RESOLUTION	Sane.I18N("Scan resolution")
#define Sane.TITLE_SCAN_X_RESOLUTION	Sane.I18N("X-resolution")
#define Sane.TITLE_SCAN_Y_RESOLUTION	Sane.I18N("Y-resolution")
#define Sane.TITLE_PAGE_WIDTH  		Sane.I18N("Page width")
#define Sane.TITLE_PAGE_HEIGHT 		Sane.I18N("Page height")
#define Sane.TITLE_CUSTOM_GAMMA		Sane.I18N("Use custom gamma table")
#define Sane.TITLE_GAMMA_VECTOR		Sane.I18N("Image intensity")
#define Sane.TITLE_GAMMA_VECTOR_R	Sane.I18N("Red intensity")
#define Sane.TITLE_GAMMA_VECTOR_G	Sane.I18N("Green intensity")
#define Sane.TITLE_GAMMA_VECTOR_B	Sane.I18N("Blue intensity")
#define Sane.TITLE_BRIGHTNESS		Sane.I18N("Brightness")
#define Sane.TITLE_CONTRAST		Sane.I18N("Contrast")
#define Sane.TITLE_GRAIN_SIZE		Sane.I18N("Grain size")
#define Sane.TITLE_HALFTONE		Sane.I18N("Halftoning")
#define Sane.TITLE_BLACK_LEVEL          Sane.I18N("Black level")
#define Sane.TITLE_WHITE_LEVEL          Sane.I18N("White level")
#define Sane.TITLE_WHITE_LEVEL_R        Sane.I18N("White level for red")
#define Sane.TITLE_WHITE_LEVEL_G        Sane.I18N("White level for green")
#define Sane.TITLE_WHITE_LEVEL_B        Sane.I18N("White level for blue")
#define Sane.TITLE_SHADOW		Sane.I18N("Shadow")
#define Sane.TITLE_SHADOW_R		Sane.I18N("Shadow for red")
#define Sane.TITLE_SHADOW_G		Sane.I18N("Shadow for green")
#define Sane.TITLE_SHADOW_B		Sane.I18N("Shadow for blue")
#define Sane.TITLE_HIGHLIGHT		Sane.I18N("Highlight")
#define Sane.TITLE_HIGHLIGHT_R		Sane.I18N("Highlight for red")
#define Sane.TITLE_HIGHLIGHT_G		Sane.I18N("Highlight for green")
#define Sane.TITLE_HIGHLIGHT_B		Sane.I18N("Highlight for blue")
#define Sane.TITLE_HUE			Sane.I18N("Hue")
#define Sane.TITLE_SATURATION		Sane.I18N("Saturation")
#define Sane.TITLE_FILE			Sane.I18N("Filename")
#define Sane.TITLE_HALFTONE_DIMENSION	Sane.I18N("Halftone pattern size")
#define Sane.TITLE_HALFTONE_PATTERN	Sane.I18N("Halftone pattern")
#define Sane.TITLE_RESOLUTION_BIND	Sane.I18N("Bind X and Y resolution")
#define Sane.TITLE_NEGATIVE		Sane.I18N("Negative")
#define Sane.TITLE_QUALITY_CAL		Sane.I18N("Quality calibration")
#define Sane.TITLE_DOR			Sane.I18N("Double Optical Resolution")
#define Sane.TITLE_RGB_BIND		Sane.I18N("Bind RGB")
#define Sane.TITLE_THRESHOLD		Sane.I18N("Threshold")
#define Sane.TITLE_ANALOG_GAMMA		Sane.I18N("Analog gamma correction")
#define Sane.TITLE_ANALOG_GAMMA_R	Sane.I18N("Analog gamma red")
#define Sane.TITLE_ANALOG_GAMMA_G	Sane.I18N("Analog gamma green")
#define Sane.TITLE_ANALOG_GAMMA_B	Sane.I18N("Analog gamma blue")
#define Sane.TITLE_ANALOG_GAMMA_BIND    Sane.I18N("Bind analog gamma")
#define Sane.TITLE_WARMUP		Sane.I18N("Warmup lamp")
#define Sane.TITLE_CAL_EXPOS_TIME	Sane.I18N("Cal. exposure-time")
#define Sane.TITLE_CAL_EXPOS_TIME_R	Sane.I18N("Cal. exposure-time for red")
#define Sane.TITLE_CAL_EXPOS_TIME_G	Sane.I18N("Cal. exposure-time for " \
"green")
#define Sane.TITLE_CAL_EXPOS_TIME_B	Sane.I18N("Cal. exposure-time for blue")
#define Sane.TITLE_SCAN_EXPOS_TIME	Sane.I18N("Scan exposure-time")
#define Sane.TITLE_SCAN_EXPOS_TIME_R	Sane.I18N("Scan exposure-time for red")
#define Sane.TITLE_SCAN_EXPOS_TIME_G	Sane.I18N("Scan exposure-time for " \
"green")
#define Sane.TITLE_SCAN_EXPOS_TIME_B	Sane.I18N("Scan exposure-time for blue")
#define Sane.TITLE_SELECT_EXPOSURE_TIME	Sane.I18N("Set exposure-time")
#define Sane.TITLE_CAL_LAMP_DEN		Sane.I18N("Cal. lamp density")
#define Sane.TITLE_SCAN_LAMP_DEN	Sane.I18N("Scan lamp density")
#define Sane.TITLE_SELECT_LAMP_DENSITY	Sane.I18N("Set lamp density")
#define Sane.TITLE_LAMP_OFF_AT_EXIT	Sane.I18N("Lamp off at exit")
#define Sane.TITLE_FOCUS		Sane.I18N("Focus position")
#define Sane.TITLE_AUTOFOCUS		Sane.I18N("Autofocus")

/* well known options from 'SENSORS' group*/
#define Sane.TITLE_SCAN			"Scan button"
#define Sane.TITLE_EMAIL		"Email button"
#define Sane.TITLE_FAX			"Fax button"
#define Sane.TITLE_COPY			"Copy button"
#define Sane.TITLE_PDF			"PDF button"
#define Sane.TITLE_CANCEL		"Cancel button"
#define Sane.TITLE_PAGE_LOADED		"Page loaded"
#define Sane.TITLE_COVER_OPEN		"Cover open"

/* Descriptive/help strings for above options: */
#define Sane.DESC_NUM_OPTIONS \
Sane.I18N("Read-only option that specifies how many options a specific " \
"device supports.")

#define Sane.DESC_STANDARD    Sane.I18N("Source, mode and resolution options")
#define Sane.DESC_GEOMETRY    Sane.I18N("Scan area and media size options")
#define Sane.DESC_ENHANCEMENT Sane.I18N("Image modification options")
#define Sane.DESC_ADVANCED    Sane.I18N("Hardware specific options")
#define Sane.DESC_SENSORS     Sane.I18N("Scanner sensors and buttons")

#define Sane.DESC_PREVIEW \
Sane.I18N("Request a preview-quality scan.")

#define Sane.DESC_GRAY_PREVIEW \
Sane.I18N("Request that all previews are done in monochrome mode.  On a " \
"three-pass scanner this cuts down the number of passes to one and on a " \
"one-pass scanner, it reduces the memory requirements and scan-time of the " \
"preview.")

#define Sane.DESC_BIT_DEPTH \
Sane.I18N("Number of bits per sample, typical values are 1 for \"line-art\" " \
"and 8 for multibit scans.")

#define Sane.DESC_SCAN_MODE \
Sane.I18N("Selects the scan mode (e.g., lineart, monochrome, or color).")

#define Sane.DESC_SCAN_SPEED \
Sane.I18N("Determines the speed at which the scan proceeds.")

#define Sane.DESC_SCAN_SOURCE \
Sane.I18N("Selects the scan source (such as a document-feeder).")

#define Sane.DESC_BACKTRACK \
Sane.I18N("Controls whether backtracking is forced.")

#define Sane.DESC_SCAN_TL_X \
Sane.I18N("Top-left x position of scan area.")

#define Sane.DESC_SCAN_TL_Y \
Sane.I18N("Top-left y position of scan area.")

#define Sane.DESC_SCAN_BR_X \
Sane.I18N("Bottom-right x position of scan area.")

#define Sane.DESC_SCAN_BR_Y \
Sane.I18N("Bottom-right y position of scan area.")

#define Sane.DESC_SCAN_RESOLUTION \
Sane.I18N("Sets the resolution of the scanned image.")

#define Sane.DESC_SCAN_X_RESOLUTION \
Sane.I18N("Sets the horizontal resolution of the scanned image.")

#define Sane.DESC_SCAN_Y_RESOLUTION \
Sane.I18N("Sets the vertical resolution of the scanned image.")

#define Sane.DESC_PAGE_WIDTH \
Sane.I18N("Specifies the width of the media.  Required for automatic " \
"centering of sheet-fed scans.")

#define Sane.DESC_PAGE_HEIGHT \
Sane.I18N("Specifies the height of the media.")

#define Sane.DESC_CUSTOM_GAMMA \
Sane.I18N("Determines whether a builtin or a custom gamma-table should be " \
"used.")

#define Sane.DESC_GAMMA_VECTOR \
Sane.I18N("Gamma-correction table.  In color mode this option equally " \
"affects the red, green, and blue channels simultaneously (i.e., it is an " \
"intensity gamma table).")

#define Sane.DESC_GAMMA_VECTOR_R \
Sane.I18N("Gamma-correction table for the red band.")

#define Sane.DESC_GAMMA_VECTOR_G \
Sane.I18N("Gamma-correction table for the green band.")

#define Sane.DESC_GAMMA_VECTOR_B \
Sane.I18N("Gamma-correction table for the blue band.")

#define Sane.DESC_BRIGHTNESS \
Sane.I18N("Controls the brightness of the acquired image.")

#define Sane.DESC_CONTRAST \
Sane.I18N("Controls the contrast of the acquired image.")

#define Sane.DESC_GRAIN_SIZE \
Sane.I18N("Selects the \"graininess\" of the acquired image.  Smaller values " \
"result in sharper images.")

#define Sane.DESC_HALFTONE \
Sane.I18N("Selects whether the acquired image should be halftoned (dithered).")

#define Sane.DESC_BLACK_LEVEL \
Sane.I18N("Selects what radiance level should be considered \"black\".")

#define Sane.DESC_WHITE_LEVEL \
Sane.I18N("Selects what radiance level should be considered \"white\".")

#define Sane.DESC_WHITE_LEVEL_R \
Sane.I18N("Selects what red radiance level should be considered \"white\".")

#define Sane.DESC_WHITE_LEVEL_G \
Sane.I18N("Selects what green radiance level should be considered \"white\".")

#define Sane.DESC_WHITE_LEVEL_B \
Sane.I18N("Selects what blue radiance level should be considered \"white\".")

#define Sane.DESC_SHADOW \
Sane.I18N("Selects what radiance level should be considered \"black\".")
#define Sane.DESC_SHADOW_R \
Sane.I18N("Selects what red radiance level should be considered \"black\".")
#define Sane.DESC_SHADOW_G \
Sane.I18N("Selects what green radiance level should be considered \"black\".")
#define Sane.DESC_SHADOW_B \
Sane.I18N("Selects what blue radiance level should be considered \"black\".")

#define Sane.DESC_HIGHLIGHT \
Sane.I18N("Selects what radiance level should be considered \"white\".")
#define Sane.DESC_HIGHLIGHT_R \
Sane.I18N("Selects what red radiance level should be considered \"full red\".")
#define Sane.DESC_HIGHLIGHT_G \
Sane.I18N("Selects what green radiance level should be considered \"full " \
"green\".")
#define Sane.DESC_HIGHLIGHT_B \
Sane.I18N("Selects what blue radiance level should be considered \"full " \
"blue\".")

#define Sane.DESC_HUE \
Sane.I18N("Controls the \"hue\" (blue-level) of the acquired image.")

#define Sane.DESC_SATURATION \
Sane.I18N("The saturation level controls the amount of \"blooming\" that " \
"occurs when acquiring an image with a camera. Larger values cause more " \
"blooming.")

#define Sane.DESC_FILE \
Sane.I18N("The filename of the image to be loaded.")

#define Sane.DESC_HALFTONE_DIMENSION \
Sane.I18N("Sets the size of the halftoning (dithering) pattern used when " \
"scanning halftoned images.")

#define Sane.DESC_HALFTONE_PATTERN \
Sane.I18N("Defines the halftoning (dithering) pattern for scanning " \
"halftoned images.")

#define Sane.DESC_RESOLUTION_BIND \
Sane.I18N("Use same values for X and Y resolution")
#define Sane.DESC_NEGATIVE \
Sane.I18N("Swap black and white")
#define Sane.DESC_QUALITY_CAL \
Sane.I18N("Do a quality white-calibration")
#define Sane.DESC_DOR \
Sane.I18N("Use lens that doubles optical resolution")
#define Sane.DESC_RGB_BIND \
Sane.I18N("In RGB-mode use same values for each color")
#define Sane.DESC_THRESHOLD \
Sane.I18N("Select minimum-brightness to get a white point")
#define Sane.DESC_ANALOG_GAMMA \
Sane.I18N("Analog gamma-correction")
#define Sane.DESC_ANALOG_GAMMA_R \
Sane.I18N("Analog gamma-correction for red")
#define Sane.DESC_ANALOG_GAMMA_G \
Sane.I18N("Analog gamma-correction for green")
#define Sane.DESC_ANALOG_GAMMA_B \
Sane.I18N("Analog gamma-correction for blue")
#define Sane.DESC_ANALOG_GAMMA_BIND \
Sane.I18N("In RGB-mode use same values for each color")
#define Sane.DESC_WARMUP \
Sane.I18N("Warm up lamp before scanning")
#define Sane.DESC_CAL_EXPOS_TIME \
Sane.I18N("Define exposure-time for calibration")
#define Sane.DESC_CAL_EXPOS_TIME_R \
Sane.I18N("Define exposure-time for red calibration")
#define Sane.DESC_CAL_EXPOS_TIME_G \
Sane.I18N("Define exposure-time for green calibration")
#define Sane.DESC_CAL_EXPOS_TIME_B \
Sane.I18N("Define exposure-time for blue calibration")
#define Sane.DESC_SCAN_EXPOS_TIME \
Sane.I18N("Define exposure-time for scan")
#define Sane.DESC_SCAN_EXPOS_TIME_R \
Sane.I18N("Define exposure-time for red scan")
#define Sane.DESC_SCAN_EXPOS_TIME_G \
Sane.I18N("Define exposure-time for green scan")
#define Sane.DESC_SCAN_EXPOS_TIME_B \
Sane.I18N("Define exposure-time for blue scan")
#define Sane.DESC_SELECT_EXPOSURE_TIME \
Sane.I18N("Enable selection of exposure-time")
#define Sane.DESC_CAL_LAMP_DEN \
Sane.I18N("Define lamp density for calibration")
#define Sane.DESC_SCAN_LAMP_DEN \
Sane.I18N("Define lamp density for scan")
#define Sane.DESC_SELECT_LAMP_DENSITY \
Sane.I18N("Enable selection of lamp density")
#define Sane.DESC_LAMP_OFF_AT_EXIT \
Sane.I18N("Turn off lamp when program exits")
#define Sane.DESC_FOCUS \
Sane.I18N("Focus position for manual focus")
#define Sane.DESC_AUTOFOCUS \
Sane.I18N("Perform autofocus before scan")

/* well known options from 'SENSORS' group*/
#define Sane.DESC_SCAN		Sane.I18N("Scan button")
#define Sane.DESC_EMAIL		Sane.I18N("Email button")
#define Sane.DESC_FAX		Sane.I18N("Fax button")
#define Sane.DESC_COPY		Sane.I18N("Copy button")
#define Sane.DESC_PDF		Sane.I18N("PDF button")
#define Sane.DESC_CANCEL	Sane.I18N("Cancel button")
#define Sane.DESC_PAGE_LOADED	Sane.I18N("Page loaded")
#define Sane.DESC_COVER_OPEN	Sane.I18N("Cover open")

/* Typical values for stringlists (to keep the backends consistent) */
#define Sane.VALUE_SCAN_MODE_COLOR		Sane.I18N("Color")
#define Sane.VALUE_SCAN_MODE_COLOR_LINEART	Sane.I18N("Color Lineart")
#define Sane.VALUE_SCAN_MODE_COLOR_HALFTONE     Sane.I18N("Color Halftone")
#define Sane.VALUE_SCAN_MODE_GRAY		Sane.I18N("Gray")
#define Sane.VALUE_SCAN_MODE_HALFTONE           Sane.I18N("Halftone")
#define Sane.VALUE_SCAN_MODE_LINEART		Sane.I18N("Lineart")

#endif /* saneopts_h */
