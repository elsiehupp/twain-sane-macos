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

#define DEBUG_DECLARE_ONLY

import enums
import genesys
import iomanip>

namespace genesys {

const char* scan_method_to_option_string(ScanMethod method)
{
    switch (method) {
        case ScanMethod::FLATBED: return STR_FLATBED
        case ScanMethod::TRANSPARENCY: return STR_TRANSPARENCY_ADAPTER
        case ScanMethod::TRANSPARENCY_INFRARED: return STR_TRANSPARENCY_ADAPTER_INFRARED
    }
    throw SaneException("Unknown scan method %d", static_cast<unsigned>(method))
}

ScanMethod option_string_to_scan_method(const std::string& str)
{
    if (str == STR_FLATBED) {
        return ScanMethod::FLATBED
    } else if (str == STR_TRANSPARENCY_ADAPTER) {
        return ScanMethod::TRANSPARENCY
    } else if (str == STR_TRANSPARENCY_ADAPTER_INFRARED) {
        return ScanMethod::TRANSPARENCY_INFRARED
    }
    throw SaneException("Unknown scan method option %s", str.c_str())
}

const char* scan_color_mode_to_option_string(ScanColorMode mode)
{
    switch (mode) {
        case ScanColorMode::COLOR_SINGLE_PASS: return Sane.VALUE_SCAN_MODE_COLOR
        case ScanColorMode::GRAY: return Sane.VALUE_SCAN_MODE_GRAY
        case ScanColorMode::HALFTONE: return Sane.VALUE_SCAN_MODE_HALFTONE
        case ScanColorMode::LINEART: return Sane.VALUE_SCAN_MODE_LINEART
    }
    throw SaneException("Unknown scan mode %d", static_cast<unsigned>(mode))
}

ScanColorMode option_string_to_scan_color_mode(const std::string& str)
{
    if (str == Sane.VALUE_SCAN_MODE_COLOR) {
        return ScanColorMode::COLOR_SINGLE_PASS
    } else if (str == Sane.VALUE_SCAN_MODE_GRAY) {
        return ScanColorMode::GRAY
    } else if (str == Sane.VALUE_SCAN_MODE_HALFTONE) {
        return ScanColorMode::HALFTONE
    } else if (str == Sane.VALUE_SCAN_MODE_LINEART) {
        return ScanColorMode::LINEART
    }
    throw SaneException("Unknown scan color mode %s", str.c_str())
}


std::ostream& operator<<(std::ostream& out, ColorFilter mode)
{
    switch (mode) {
        case ColorFilter::RED: out << "RED"; break
        case ColorFilter::GREEN: out << "GREEN"; break
        case ColorFilter::BLUE: out << "BLUE"; break
        case ColorFilter::NONE: out << "NONE"; break
        default: out << static_cast<unsigned>(mode); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, ModelId id)
{
    switch (id) {
        case ModelId::UNKNOWN: out << "UNKNOWN"; break
        case ModelId::CANON_4400F: out << "CANON_4400F"; break
        case ModelId::CANON_5600F: out << "CANON_5600F"; break
        case ModelId::CANON_8400F: out << "CANON_8400F"; break
        case ModelId::CANON_8600F: out << "CANON_8600F"; break
        case ModelId::CANON_IMAGE_FORMULA_101: out << "CANON_IMAGE_FORMULA_101"; break
        case ModelId::CANON_LIDE_50: out << "CANON_LIDE_50"; break
        case ModelId::CANON_LIDE_60: out << "CANON_LIDE_60"; break
        case ModelId::CANON_LIDE_80: out << "CANON_LIDE_80"; break
        case ModelId::CANON_LIDE_90: out << "CANON_LIDE_90"; break
        case ModelId::CANON_LIDE_100: out << "CANON_LIDE_100"; break
        case ModelId::CANON_LIDE_110: out << "CANON_LIDE_110"; break
        case ModelId::CANON_LIDE_120: out << "CANON_LIDE_120"; break
        case ModelId::CANON_LIDE_200: out << "CANON_LIDE_200"; break
        case ModelId::CANON_LIDE_210: out << "CANON_LIDE_210"; break
        case ModelId::CANON_LIDE_220: out << "CANON_LIDE_220"; break
        case ModelId::CANON_LIDE_700F: out << "CANON_LIDE_700F"; break
        case ModelId::DCT_DOCKETPORT_487: out << "DCT_DOCKETPORT_487"; break
        case ModelId::HP_SCANJET_2300C: out << "HP_SCANJET_2300C"; break
        case ModelId::HP_SCANJET_2400C: out << "HP_SCANJET_2400C"; break
        case ModelId::HP_SCANJET_3670: out << "HP_SCANJET_3670"; break
        case ModelId::HP_SCANJET_4850C: out << "HP_SCANJET_4850C"; break
        case ModelId::HP_SCANJET_G4010: out << "HP_SCANJET_G4010"; break
        case ModelId::HP_SCANJET_G4050: out << "HP_SCANJET_G4050"; break
        case ModelId::HP_SCANJET_N6310: out << "HP_SCANJET_N6310"; break
        case ModelId::MEDION_MD5345: out << "MEDION_MD5345"; break
        case ModelId::PANASONIC_KV_SS080: out << "PANASONIC_KV_SS080"; break
        case ModelId::PENTAX_DSMOBILE_600: out << "PENTAX_DSMOBILE_600"; break
        case ModelId::PLUSTEK_OPTICBOOK_3800: out << "PLUSTEK_OPTICBOOK_3800"; break
        case ModelId::PLUSTEK_OPTICFILM_7200: out << "PLUSTEK_OPTICFILM_7200"; break
        case ModelId::PLUSTEK_OPTICFILM_7200I: out << "PLUSTEK_OPTICFILM_7200I"; break
        case ModelId::PLUSTEK_OPTICFILM_7300: out << "PLUSTEK_OPTICFILM_7300"; break
        case ModelId::PLUSTEK_OPTICFILM_7400: out << "PLUSTEK_OPTICFILM_7400"; break
        case ModelId::PLUSTEK_OPTICFILM_7500I: out << "PLUSTEK_OPTICFILM_7500I"; break
        case ModelId::PLUSTEK_OPTICFILM_8200I: out << "PLUSTEK_OPTICFILM_8200I"; break
        case ModelId::PLUSTEK_OPTICPRO_3600: out << "PLUSTEK_OPTICPRO_3600"; break
        case ModelId::PLUSTEK_OPTICPRO_ST12: out << "PLUSTEK_OPTICPRO_ST12"; break
        case ModelId::PLUSTEK_OPTICPRO_ST24: out << "PLUSTEK_OPTICPRO_ST24"; break
        case ModelId::SYSCAN_DOCKETPORT_465: out << "SYSCAN_DOCKETPORT_465"; break
        case ModelId::SYSCAN_DOCKETPORT_467: out << "SYSCAN_DOCKETPORT_467"; break
        case ModelId::SYSCAN_DOCKETPORT_485: out << "SYSCAN_DOCKETPORT_485"; break
        case ModelId::SYSCAN_DOCKETPORT_665: out << "SYSCAN_DOCKETPORT_665"; break
        case ModelId::SYSCAN_DOCKETPORT_685: out << "SYSCAN_DOCKETPORT_685"; break
        case ModelId::UMAX_ASTRA_4500: out << "UMAX_ASTRA_4500"; break
        case ModelId::VISIONEER_7100: out << "VISIONEER_7100"; break
        case ModelId::VISIONEER_ROADWARRIOR: out << "VISIONEER_ROADWARRIOR"; break
        case ModelId::VISIONEER_STROBE_XP100_REVISION3:
            out << "VISIONEER_STROBE_XP100_REVISION3"; break
        case ModelId::VISIONEER_STROBE_XP200: out << "VISIONEER_STROBE_XP200"; break
        case ModelId::VISIONEER_STROBE_XP300: out << "VISIONEER_STROBE_XP300"; break
        case ModelId::XEROX_2400: out << "XEROX_2400"; break
        case ModelId::XEROX_TRAVELSCANNER_100: out << "XEROX_TRAVELSCANNER_100"; break
        default:
            out << static_cast<unsigned>(id); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, SensorId id)
{
    switch (id) {
        case SensorId::CCD_5345: out << "CCD_5345"; break
        case SensorId::CCD_CANON_4400F: out << "CCD_CANON_4400F"; break
        case SensorId::CCD_CANON_5600F: out << "CCD_CANON_5600F"; break
        case SensorId::CCD_CANON_8400F: out << "CCD_CANON_8400F"; break
        case SensorId::CCD_CANON_8600F: out << "CCD_CANON_8600F"; break
        case SensorId::CCD_DP665: out << "CCD_DP665"; break
        case SensorId::CCD_DP685: out << "CCD_DP685"; break
        case SensorId::CCD_DSMOBILE600: out << "CCD_DSMOBILE600"; break
        case SensorId::CCD_DOCKETPORT_487: out << "CCD_DOCKETPORT_487"; break
        case SensorId::CCD_G4050: out << "CCD_G4050"; break
        case SensorId::CCD_HP2300: out << "CCD_HP2300"; break
        case SensorId::CCD_HP2400: out << "CCD_HP2400"; break
        case SensorId::CCD_HP3670: out << "CCD_HP3670"; break
        case SensorId::CCD_HP_N6310: out << "CCD_HP_N6310"; break
        case SensorId::CCD_HP_4850C: out << "CCD_HP_4850C"; break
        case SensorId::CCD_IMG101: out << "CCD_IMG101"; break
        case SensorId::CCD_KVSS080: out << "CCD_KVSS080"; break
        case SensorId::CCD_PLUSTEK_OPTICBOOK_3800: out << "CCD_PLUSTEK_OPTICBOOK_3800"; break
        case SensorId::CCD_PLUSTEK_OPTICFILM_7200: out << "CCD_PLUSTEK_OPTICFILM_7200"; break
        case SensorId::CCD_PLUSTEK_OPTICFILM_7200I: out << "CCD_PLUSTEK_OPTICFILM_7200I"; break
        case SensorId::CCD_PLUSTEK_OPTICFILM_7300: out << "CCD_PLUSTEK_OPTICFILM_7300"; break
        case SensorId::CCD_PLUSTEK_OPTICFILM_7400: out << "CCD_PLUSTEK_OPTICFILM_7400"; break
        case SensorId::CCD_PLUSTEK_OPTICFILM_7500I: out << "CCD_PLUSTEK_OPTICFILM_7500I"; break
        case SensorId::CCD_PLUSTEK_OPTICFILM_8200I: out << "CCD_PLUSTEK_OPTICFILM_8200I"; break
        case SensorId::CCD_PLUSTEK_OPTICPRO_3600: out << "CCD_PLUSTEK_OPTICPRO_3600"; break
        case SensorId::CCD_ROADWARRIOR: out << "CCD_ROADWARRIOR"; break
        case SensorId::CCD_ST12: out << "CCD_ST12"; break
        case SensorId::CCD_ST24: out << "CCD_ST24"; break
        case SensorId::CCD_UMAX: out << "CCD_UMAX"; break
        case SensorId::CCD_XP300: out << "CCD_XP300"; break
        case SensorId::CIS_CANON_LIDE_35: out << "CIS_CANON_LIDE_35"; break
        case SensorId::CIS_CANON_LIDE_60: out << "CIS_CANON_LIDE_60"; break
        case SensorId::CIS_CANON_LIDE_80: out << "CIS_CANON_LIDE_80"; break
        case SensorId::CIS_CANON_LIDE_90: out << "CIS_CANON_LIDE_90"; break
        case SensorId::CIS_CANON_LIDE_100: out << "CIS_CANON_LIDE_100"; break
        case SensorId::CIS_CANON_LIDE_110: out << "CIS_CANON_LIDE_110"; break
        case SensorId::CIS_CANON_LIDE_120: out << "CIS_CANON_LIDE_120"; break
        case SensorId::CIS_CANON_LIDE_200: out << "CIS_CANON_LIDE_200"; break
        case SensorId::CIS_CANON_LIDE_210: out << "CIS_CANON_LIDE_210"; break
        case SensorId::CIS_CANON_LIDE_220: out << "CIS_CANON_LIDE_220"; break
        case SensorId::CIS_CANON_LIDE_700F: out << "CIS_CANON_LIDE_700F"; break
        case SensorId::CIS_XP200: out << "CIS_XP200"; break
        default:
            out << static_cast<unsigned>(id); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, AdcId id)
{
    switch (id) {
        case AdcId::UNKNOWN: out << "UNKNOWN"; break
        case AdcId::AD_XP200: out << "AD_XP200"; break
        case AdcId::CANON_LIDE_35: out << "CANON_LIDE_35"; break
        case AdcId::CANON_LIDE_80: out << "CANON_LIDE_80"; break
        case AdcId::CANON_LIDE_90: out << "CANON_LIDE_90"; break
        case AdcId::CANON_LIDE_110: out << "CANON_LIDE_110"; break
        case AdcId::CANON_LIDE_120: out << "CANON_LIDE_120"; break
        case AdcId::CANON_LIDE_200: out << "CANON_LIDE_200"; break
        case AdcId::CANON_LIDE_700F: out << "CANON_LIDE_700F"; break
        case AdcId::CANON_4400F: out << "CANON_4400F"; break
        case AdcId::CANON_5600F: out << "CANON_5600F"; break
        case AdcId::CANON_8400F: out << "CANON_8400F"; break
        case AdcId::CANON_8600F: out << "CANON_8600F"; break
        case AdcId::G4050: out << "G4050"; break
        case AdcId::IMG101: out << "IMG101"; break
        case AdcId::KVSS080: out << "KVSS080"; break
        case AdcId::PLUSTEK_OPTICBOOK_3800: out << "PLUSTEK_OPTICBOOK_3800"; break
        case AdcId::PLUSTEK_OPTICFILM_7200: out << "PLUSTEK_OPTICFILM_7200"; break
        case AdcId::PLUSTEK_OPTICFILM_7200I: out << "PLUSTEK_OPTICFILM_7200I"; break
        case AdcId::PLUSTEK_OPTICFILM_7300: out << "PLUSTEK_OPTICFILM_7300"; break
        case AdcId::PLUSTEK_OPTICFILM_7400: out << "PLUSTEK_OPTICFILM_7400"; break
        case AdcId::PLUSTEK_OPTICFILM_7500I: out << "PLUSTEK_OPTICFILM_7500I"; break
        case AdcId::PLUSTEK_OPTICFILM_8200I: out << "PLUSTEK_OPTICFILM_8200I"; break
        case AdcId::PLUSTEK_OPTICPRO_3600: out << "PLUSTEK_OPTICPRO_3600"; break
        case AdcId::WOLFSON_5345: out << "WOLFSON_5345"; break
        case AdcId::WOLFSON_DSM600: out << "WOLFSON_DSM600"; break
        case AdcId::WOLFSON_HP2300: out << "WOLFSON_HP2300"; break
        case AdcId::WOLFSON_HP2400: out << "WOLFSON_HP2400"; break
        case AdcId::WOLFSON_HP3670: out << "WOLFSON_HP3670"; break
        case AdcId::WOLFSON_ST12: out << "WOLFSON_ST12"; break
        case AdcId::WOLFSON_ST24: out << "WOLFSON_ST24"; break
        case AdcId::WOLFSON_UMAX: out << "WOLFSON_UMAX"; break
        case AdcId::WOLFSON_XP300: out << "WOLFSON_XP300"; break
        default:
            out << static_cast<unsigned>(id); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, GpioId id)
{
    switch (id) {
        case GpioId::UNKNOWN: out << "UNKNOWN"; break
        case GpioId::CANON_LIDE_35: out << "CANON_LIDE_35"; break
        case GpioId::CANON_LIDE_80: out << "CANON_LIDE_80"; break
        case GpioId::CANON_LIDE_90: out << "CANON_LIDE_90"; break
        case GpioId::CANON_LIDE_110: out << "CANON_LIDE_110"; break
        case GpioId::CANON_LIDE_120: out << "CANON_LIDE_120"; break
        case GpioId::CANON_LIDE_200: out << "CANON_LIDE_200"; break
        case GpioId::CANON_LIDE_210: out << "CANON_LIDE_210"; break
        case GpioId::CANON_LIDE_700F: out << "CANON_LIDE_700F"; break
        case GpioId::CANON_4400F: out << "CANON_4400F"; break
        case GpioId::CANON_5600F: out << "CANON_5600F"; break
        case GpioId::CANON_8400F: out << "CANON_8400F"; break
        case GpioId::CANON_8600F: out << "CANON_8600F"; break
        case GpioId::DP665: out << "DP665"; break
        case GpioId::DP685: out << "DP685"; break
        case GpioId::G4050: out << "G4050"; break
        case GpioId::HP2300: out << "HP2300"; break
        case GpioId::HP2400: out << "HP2400"; break
        case GpioId::HP3670: out << "HP3670"; break
        case GpioId::HP_N6310: out << "HP_N6310"; break
        case GpioId::IMG101: out << "IMG101"; break
        case GpioId::KVSS080: out << "KVSS080"; break
        case GpioId::MD_5345: out << "MD_5345"; break
        case GpioId::PLUSTEK_OPTICBOOK_3800: out << "PLUSTEK_OPTICBOOK_3800"; break
        case GpioId::PLUSTEK_OPTICFILM_7200I: out << "PLUSTEK_OPTICFILM_7200I"; break
        case GpioId::PLUSTEK_OPTICFILM_7300: out << "PLUSTEK_OPTICFILM_7300"; break
        case GpioId::PLUSTEK_OPTICFILM_7400: out << "PLUSTEK_OPTICFILM_7400"; break
        case GpioId::PLUSTEK_OPTICFILM_7500I: out << "PLUSTEK_OPTICFILM_7500I"; break
        case GpioId::PLUSTEK_OPTICFILM_8200I: out << "PLUSTEK_OPTICFILM_8200I"; break
        case GpioId::PLUSTEK_OPTICPRO_3600: out << "PLUSTEK_OPTICPRO_3600"; break
        case GpioId::ST12: out << "ST12"; break
        case GpioId::ST24: out << "ST24"; break
        case GpioId::UMAX: out << "UMAX"; break
        case GpioId::XP200: out << "XP200"; break
        case GpioId::XP300: out << "XP300"; break
        default: out << static_cast<unsigned>(id); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, MotorId id)
{
    switch (id) {
        case MotorId::UNKNOWN: out << "UNKNOWN"; break
        case MotorId::CANON_LIDE_90: out << "CANON_LIDE_90"; break
        case MotorId::CANON_LIDE_100: out << "CANON_LIDE_100"; break
        case MotorId::CANON_LIDE_110: out << "CANON_LIDE_110"; break
        case MotorId::CANON_LIDE_120: out << "CANON_LIDE_120"; break
        case MotorId::CANON_LIDE_200: out << "CANON_LIDE_200"; break
        case MotorId::CANON_LIDE_210: out << "CANON_LIDE_210"; break
        case MotorId::CANON_LIDE_35: out << "CANON_LIDE_35"; break
        case MotorId::CANON_LIDE_60: out << "CANON_LIDE_60"; break
        case MotorId::CANON_LIDE_700: out << "CANON_LIDE_700"; break
        case MotorId::CANON_LIDE_80: out << "CANON_LIDE_80"; break
        case MotorId::CANON_4400F: out << "CANON_4400F"; break
        case MotorId::CANON_5600F: out << "CANON_5600F"; break
        case MotorId::CANON_8400F: out << "CANON_8400F"; break
        case MotorId::CANON_8600F: out << "CANON_8600F"; break
        case MotorId::DP665: out << "DP665"; break
        case MotorId::DSMOBILE_600: out << "DSMOBILE_600"; break
        case MotorId::G4050: out << "G4050"; break
        case MotorId::HP2300: out << "HP2300"; break
        case MotorId::HP2400: out << "HP2400"; break
        case MotorId::HP3670: out << "HP3670"; break
        case MotorId::IMG101: out << "IMG101"; break
        case MotorId::KVSS080: out << "KVSS080"; break
        case MotorId::MD_5345: out << "MD_5345"; break
        case MotorId::PLUSTEK_OPTICBOOK_3800: out << "PLUSTEK_OPTICBOOK_3800"; break
        case MotorId::PLUSTEK_OPTICFILM_7200: out << "PLUSTEK_OPTICFILM_7200"; break
        case MotorId::PLUSTEK_OPTICFILM_7200I: out << "PLUSTEK_OPTICFILM_7200I"; break
        case MotorId::PLUSTEK_OPTICFILM_7300: out << "PLUSTEK_OPTICFILM_7300"; break
        case MotorId::PLUSTEK_OPTICFILM_7400: out << "PLUSTEK_OPTICFILM_7400"; break
        case MotorId::PLUSTEK_OPTICFILM_7500I: out << "PLUSTEK_OPTICFILM_7500I"; break
        case MotorId::PLUSTEK_OPTICFILM_8200I: out << "PLUSTEK_OPTICFILM_8200I"; break
        case MotorId::PLUSTEK_OPTICPRO_3600: out << "PLUSTEK_OPTICPRO_3600"; break
        case MotorId::ROADWARRIOR: out << "ROADWARRIOR"; break
        case MotorId::ST24: out << "ST24"; break
        case MotorId::UMAX: out << "UMAX"; break
        case MotorId::XP200: out << "XP200"; break
        case MotorId::XP300: out << "XP300"; break
        default: out << static_cast<unsigned>(id); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, StepType type)
{
    switch (type) {
        case StepType::FULL: out << "1/1"; break
        case StepType::HALF: out << "1/2"; break
        case StepType::QUARTER: out << "1/4"; break
        case StepType::EIGHTH: out << "1/8"; break
        default: out << static_cast<unsigned>(type); break
    }
    return out
}

std::ostream& operator<<(std::ostream& out, ScanFlag flags)
{
    StreamStateSaver state_saver{out]
    out << "0x" << std::hex << static_cast<unsigned>(flags)
    return out
}

} // namespace genesys
