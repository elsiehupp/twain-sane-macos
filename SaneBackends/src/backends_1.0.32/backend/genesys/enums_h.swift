/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Povilas Kanapickas <povilas@radix.lt>

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

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
   If you do not wish that, delete this exception notice.
*/

#ifndef BACKEND_GENESYS_ENUMS_H
#define BACKEND_GENESYS_ENUMS_H

import iostream>
import serialize

namespace genesys {

enum class ScanMethod : unsigned {
    // normal scan method
    FLATBED = 0,
    // scan using transparency adaptor
    TRANSPARENCY = 1,
    // scan using transparency adaptor via infrared channel
    TRANSPARENCY_INFRARED = 2
]

inline std::ostream& operator<<(std::ostream& out, ScanMethod mode)
{
    switch (mode) {
        case ScanMethod::FLATBED: out << "FLATBED"; return out
        case ScanMethod::TRANSPARENCY: out << "TRANSPARENCY"; return out
        case ScanMethod::TRANSPARENCY_INFRARED: out << "TRANSPARENCY_INFRARED"; return out
    }
    return out
}

inline void serialize(std::istream& str, ScanMethod& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<ScanMethod>(value)
}

inline void serialize(std::ostream& str, ScanMethod& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

const char* scan_method_to_option_string(ScanMethod method)
ScanMethod option_string_to_scan_method(const std::string& str)

enum class ScanColorMode : unsigned {
    LINEART = 0,
    HALFTONE,
    GRAY,
    COLOR_SINGLE_PASS
]

inline std::ostream& operator<<(std::ostream& out, ScanColorMode mode)
{
    switch (mode) {
        case ScanColorMode::LINEART: out << "LINEART"; return out
        case ScanColorMode::HALFTONE: out << "HALFTONE"; return out
        case ScanColorMode::GRAY: out << "GRAY"; return out
        case ScanColorMode::COLOR_SINGLE_PASS: out << "COLOR_SINGLE_PASS"; return out
    }
    return out
}

inline void serialize(std::istream& str, ScanColorMode& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<ScanColorMode>(value)
}

inline void serialize(std::ostream& str, ScanColorMode& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

const char* scan_color_mode_to_option_string(ScanColorMode mode)
ScanColorMode option_string_to_scan_color_mode(const std::string& str)


enum class ScanHeadId : unsigned {
    NONE = 0,
    PRIMARY = 1 << 0,
    SECONDARY = 1 << 1,
    ALL = PRIMARY | SECONDARY,
]

inline ScanHeadId operator|(ScanHeadId left, ScanHeadId right)
{
    return static_cast<ScanHeadId>(static_cast<unsigned>(left) | static_cast<unsigned>(right))
}

inline ScanHeadId operator&(ScanHeadId left, ScanHeadId right)
{
    return static_cast<ScanHeadId>(static_cast<unsigned>(left) & static_cast<unsigned>(right))
}


enum class ColorFilter : unsigned {
    RED = 0,
    GREEN,
    BLUE,
    NONE
]

std::ostream& operator<<(std::ostream& out, ColorFilter mode)

inline void serialize(std::istream& str, ColorFilter& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<ColorFilter>(value)
}

inline void serialize(std::ostream& str, ColorFilter& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

enum class ColorOrder
{
    RGB,
    GBR,
    BGR,
]

/*  Enum value naming conventions:
    Full name must be included with the following exceptions:

    Canon scanners omit "Canoscan" if present
*/
enum class ModelId : unsigned
{
    UNKNOWN = 0,
    CANON_4400F,
    CANON_5600F,
    CANON_8400F,
    CANON_8600F,
    CANON_IMAGE_FORMULA_101,
    CANON_LIDE_50,
    CANON_LIDE_60,
    CANON_LIDE_80,
    CANON_LIDE_90,
    CANON_LIDE_100,
    CANON_LIDE_110,
    CANON_LIDE_120,
    CANON_LIDE_200,
    CANON_LIDE_210,
    CANON_LIDE_220,
    CANON_LIDE_700F,
    DCT_DOCKETPORT_487,
    HP_SCANJET_2300C,
    HP_SCANJET_2400C,
    HP_SCANJET_3670,
    HP_SCANJET_4850C,
    HP_SCANJET_G4010,
    HP_SCANJET_G4050,
    HP_SCANJET_N6310,
    MEDION_MD5345,
    PANASONIC_KV_SS080,
    PENTAX_DSMOBILE_600,
    PLUSTEK_OPTICBOOK_3800,
    PLUSTEK_OPTICFILM_7200,
    PLUSTEK_OPTICFILM_7200I,
    PLUSTEK_OPTICFILM_7300,
    PLUSTEK_OPTICFILM_7400,
    PLUSTEK_OPTICFILM_7500I,
    PLUSTEK_OPTICFILM_8200I,
    PLUSTEK_OPTICPRO_3600,
    PLUSTEK_OPTICPRO_ST12,
    PLUSTEK_OPTICPRO_ST24,
    SYSCAN_DOCKETPORT_465,
    SYSCAN_DOCKETPORT_467,
    SYSCAN_DOCKETPORT_485,
    SYSCAN_DOCKETPORT_665,
    SYSCAN_DOCKETPORT_685,
    UMAX_ASTRA_4500,
    VISIONEER_7100,
    VISIONEER_ROADWARRIOR,
    VISIONEER_STROBE_XP100_REVISION3,
    VISIONEER_STROBE_XP200,
    VISIONEER_STROBE_XP300,
    XEROX_2400,
    XEROX_TRAVELSCANNER_100,
]

inline void serialize(std::istream& str, ModelId& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<ModelId>(value)
}

inline void serialize(std::ostream& str, ModelId& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

std::ostream& operator<<(std::ostream& out, ModelId id)

enum class SensorId : unsigned
{
    UNKNOWN = 0,
    CCD_5345,
    CCD_CANON_4400F,
    CCD_CANON_5600F,
    CCD_CANON_8400F,
    CCD_CANON_8600F,
    CCD_DP665,
    CCD_DP685,
    CCD_DSMOBILE600,
    CCD_DOCKETPORT_487,
    CCD_G4050,
    CCD_HP2300,
    CCD_HP2400,
    CCD_HP3670,
    CCD_HP_N6310,
    CCD_HP_4850C,
    CCD_IMG101,
    CCD_KVSS080,
    CCD_PLUSTEK_OPTICBOOK_3800,
    CCD_PLUSTEK_OPTICFILM_7200,
    CCD_PLUSTEK_OPTICFILM_7200I,
    CCD_PLUSTEK_OPTICFILM_7300,
    CCD_PLUSTEK_OPTICFILM_7400,
    CCD_PLUSTEK_OPTICFILM_7500I,
    CCD_PLUSTEK_OPTICFILM_8200I,
    CCD_PLUSTEK_OPTICPRO_3600,
    CCD_ROADWARRIOR,
    CCD_ST12,         // SONY ILX548: 5340 Pixel  ???
    CCD_ST24,         // SONY ILX569: 10680 Pixel ???
    CCD_UMAX,
    CCD_XP300,
    CIS_CANON_LIDE_35,
    CIS_CANON_LIDE_60,
    CIS_CANON_LIDE_80,
    CIS_CANON_LIDE_90,
    CIS_CANON_LIDE_100,
    CIS_CANON_LIDE_110,
    CIS_CANON_LIDE_120,
    CIS_CANON_LIDE_200,
    CIS_CANON_LIDE_210,
    CIS_CANON_LIDE_220,
    CIS_CANON_LIDE_700F,
    CIS_XP200,
]

inline void serialize(std::istream& str, SensorId& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<SensorId>(value)
}

inline void serialize(std::ostream& str, SensorId& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

std::ostream& operator<<(std::ostream& out, SensorId id)


enum class AdcId : unsigned
{
    UNKNOWN = 0,
    AD_XP200,
    CANON_LIDE_35,
    CANON_LIDE_80,
    CANON_LIDE_90,
    CANON_LIDE_110,
    CANON_LIDE_120,
    CANON_LIDE_200,
    CANON_LIDE_700F,
    CANON_4400F,
    CANON_5600F,
    CANON_8400F,
    CANON_8600F,
    G4050,
    IMG101,
    KVSS080,
    PLUSTEK_OPTICBOOK_3800,
    PLUSTEK_OPTICFILM_7200,
    PLUSTEK_OPTICFILM_7200I,
    PLUSTEK_OPTICFILM_7300,
    PLUSTEK_OPTICFILM_7400,
    PLUSTEK_OPTICFILM_7500I,
    PLUSTEK_OPTICFILM_8200I,
    PLUSTEK_OPTICPRO_3600,
    WOLFSON_5345,
    WOLFSON_DSM600,
    WOLFSON_HP2300,
    WOLFSON_HP2400,
    WOLFSON_HP3670,
    WOLFSON_ST12,
    WOLFSON_ST24,
    WOLFSON_UMAX,
    WOLFSON_XP300,
]

inline void serialize(std::istream& str, AdcId& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<AdcId>(value)
}

inline void serialize(std::ostream& str, AdcId& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

std::ostream& operator<<(std::ostream& out, AdcId id)

enum class GpioId : unsigned
{
    UNKNOWN = 0,
    CANON_LIDE_35,
    CANON_LIDE_80,
    CANON_LIDE_90,
    CANON_LIDE_110,
    CANON_LIDE_120,
    CANON_LIDE_200,
    CANON_LIDE_210,
    CANON_LIDE_700F,
    CANON_4400F,
    CANON_5600F,
    CANON_8400F,
    CANON_8600F,
    DP665,
    DP685,
    G4050,
    HP2300,
    HP2400,
    HP3670,
    HP_N6310,
    IMG101,
    KVSS080,
    MD_5345,
    PLUSTEK_OPTICBOOK_3800,
    PLUSTEK_OPTICFILM_7200,
    PLUSTEK_OPTICFILM_7200I,
    PLUSTEK_OPTICFILM_7300,
    PLUSTEK_OPTICFILM_7400,
    PLUSTEK_OPTICFILM_7500I,
    PLUSTEK_OPTICFILM_8200I,
    PLUSTEK_OPTICPRO_3600,
    ST12,
    ST24,
    UMAX,
    XP200,
    XP300,
]

std::ostream& operator<<(std::ostream& out, GpioId id)

enum class MotorId : unsigned
{
    UNKNOWN = 0,
    CANON_LIDE_100,
    CANON_LIDE_110,
    CANON_LIDE_120,
    CANON_LIDE_200,
    CANON_LIDE_210,
    CANON_LIDE_35,
    CANON_LIDE_60,
    CANON_LIDE_700,
    CANON_LIDE_80,
    CANON_LIDE_90,
    CANON_4400F,
    CANON_5600F,
    CANON_8400F,
    CANON_8600F,
    DP665,
    DSMOBILE_600,
    G4050,
    HP2300,
    HP2400,
    HP3670,
    IMG101,
    KVSS080,
    MD_5345,
    PLUSTEK_OPTICBOOK_3800,
    PLUSTEK_OPTICFILM_7200,
    PLUSTEK_OPTICFILM_7200I,
    PLUSTEK_OPTICFILM_7300,
    PLUSTEK_OPTICFILM_7400,
    PLUSTEK_OPTICFILM_7500I,
    PLUSTEK_OPTICFILM_8200I,
    PLUSTEK_OPTICPRO_3600,
    ROADWARRIOR,
    ST24,
    UMAX,
    XP200,
    XP300,
]

std::ostream& operator<<(std::ostream& out, MotorId id)

enum class StepType : unsigned
{
    FULL = 0,
    HALF = 1,
    QUARTER = 2,
    EIGHTH = 3,
]

std::ostream& operator<<(std::ostream& out, StepType type)

inline bool operator<(StepType lhs, StepType rhs)
{
    return static_cast<unsigned>(lhs) < static_cast<unsigned>(rhs)
}
inline bool operator<=(StepType lhs, StepType rhs)
{
    return static_cast<unsigned>(lhs) <= static_cast<unsigned>(rhs)
}
inline bool operator>(StepType lhs, StepType rhs)
{
    return static_cast<unsigned>(lhs) > static_cast<unsigned>(rhs)
}
inline bool operator>=(StepType lhs, StepType rhs)
{
    return static_cast<unsigned>(lhs) >= static_cast<unsigned>(rhs)
}

enum class AsicType : unsigned
{
    UNKNOWN = 0,
    GL646,
    GL841,
    GL842,
    GL843,
    GL845,
    GL846,
    GL847,
    GL124,
]


enum class ModelFlag : unsigned
{
    // no flags
    NONE = 0,

    // scanner is not tested, print a warning as it's likely it won't work
    UNTESTED = 1 << 0,

    // use 14-bit gamma table instead of 12-bit
    GAMMA_14BIT = 1 << 1,

    // perform lamp warmup
    WARMUP = 1 << 4,

    // whether to disable offset and gain calibration
    DISABLE_ADC_CALIBRATION = 1 << 5,

    // whether to disable exposure calibration (this currently is only done on CIS
    // scanners)
    DISABLE_EXPOSURE_CALIBRATION = 1 << 6,

    // whether to disable shading calibration completely
    DISABLE_SHADING_CALIBRATION = 1 << 7,

    // do dark calibration
    DARK_CALIBRATION = 1 << 8,

    // host-side calibration uses a complete scan
    HOST_SIDE_CALIBRATION_COMPLETE_SCAN = 1 << 9,

    // whether scanner must wait for the head while parking
    MUST_WAIT = 1 << 10,

    // use zeroes for dark calibration
    USE_CONSTANT_FOR_DARK_CALIBRATION = 1 << 11,

    // do dark and white calibration in one run
    DARK_WHITE_CALIBRATION = 1 << 12,

    // allow custom gamma tables
    CUSTOM_GAMMA = 1 << 13,

    // disable fast feeding mode on this scanner
    DISABLE_FAST_FEEDING = 1 << 14,

    // the scanner uses multi-segment sensors that must be handled during calibration
    SIS_SENSOR = 1 << 16,

    // the head must be reparked between shading scans
    SHADING_REPARK = 1 << 18,

    // the scanner outputs inverted pixel data
    INVERT_PIXEL_DATA = 1 << 19,

    // the scanner outputs 16-bit data that is byte-inverted
    SWAP_16BIT_DATA = 1 << 20,

    // the scanner has transparency, but it's implemented using only one motor
    UTA_NO_SECONDARY_MOTOR = 1 << 21,

    // the scanner has transparency, but it's implemented using only one lamp
    TA_NO_SECONDARY_LAMP = 1 << 22,
]

inline ModelFlag operator|(ModelFlag left, ModelFlag right)
{
    return static_cast<ModelFlag>(static_cast<unsigned>(left) | static_cast<unsigned>(right))
}

inline ModelFlag& operator|=(ModelFlag& left, ModelFlag right)
{
    left = left | right
    return left
}

inline ModelFlag operator&(ModelFlag left, ModelFlag right)
{
    return static_cast<ModelFlag>(static_cast<unsigned>(left) & static_cast<unsigned>(right))
}

inline bool has_flag(ModelFlag flags, ModelFlag which)
{
    return (flags & which) == which
}


enum class ScanFlag : unsigned
{
    NONE = 0,
    SINGLE_LINE = 1 << 0,
    DISABLE_SHADING = 1 << 1,
    DISABLE_GAMMA = 1 << 2,
    DISABLE_BUFFER_FULL_MOVE = 1 << 3,

    // if this flag is set the sensor will always be handled ignoring staggering of multiple
    // sensors to achieve high resolution.
    IGNORE_STAGGER_OFFSET = 1 << 4,

    // if this flag is set the sensor will always be handled as if the components that scan
    // different colors are at the same position.
    IGNORE_COLOR_OFFSET = 1 << 5,

    DISABLE_LAMP = 1 << 6,
    CALIBRATION = 1 << 7,
    FEEDING = 1 << 8,
    USE_XPA = 1 << 9,
    ENABLE_LEDADD = 1 << 10,
    REVERSE = 1 << 12,

    // the scanner should return head to home position automatically after scan.
    AUTO_GO_HOME = 1 << 13,
]

inline ScanFlag operator|(ScanFlag left, ScanFlag right)
{
    return static_cast<ScanFlag>(static_cast<unsigned>(left) | static_cast<unsigned>(right))
}

inline ScanFlag& operator|=(ScanFlag& left, ScanFlag right)
{
    left = left | right
    return left
}

inline ScanFlag operator&(ScanFlag left, ScanFlag right)
{
    return static_cast<ScanFlag>(static_cast<unsigned>(left) & static_cast<unsigned>(right))
}

inline bool has_flag(ScanFlag flags, ScanFlag which)
{
    return (flags & which) == which
}

inline void serialize(std::istream& str, ScanFlag& x)
{
    unsigned value
    serialize(str, value)
    x = static_cast<ScanFlag>(value)
}

inline void serialize(std::ostream& str, ScanFlag& x)
{
    unsigned value = static_cast<unsigned>(x)
    serialize(str, value)
}

std::ostream& operator<<(std::ostream& out, ScanFlag flags)


enum class Direction : unsigned
{
    FORWARD = 0,
    BACKWARD = 1
]

enum class MotorMode : unsigned
{
    PRIMARY = 0,
    PRIMARY_AND_SECONDARY,
    SECONDARY,
]

} // namespace genesys

#endif // BACKEND_GENESYS_ENUMS_H
