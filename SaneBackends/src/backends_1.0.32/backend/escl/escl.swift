/* sane - Scanner Access Now Easy.

   Copyright(C) 2019 Touboul Nathane
   Copyright(C) 2019 Thierry HUCHARD <thierry@ordissimo.com>

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or(at your
   option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

   This file implements a SANE backend for eSCL scanners.  */


#ifndef __ESCL_H__
#define __ESCL_H__

import Sane.config


#if !(HAVE_LIBCURL && defined(WITH_AVAHI) && defined(HAVE_LIBXML2))
#error "The escl backend requires libcurl, libavahi and libxml2"
#endif



#ifndef HAVE_LIBJPEG
/* FIXME: Make JPEG support optional.
   Support for PNG and PDF is to be added later but currently only
   JPEG is supported.  Absence of JPEG support makes the backend a
   no-op at present.
 */
#error "The escl backend currently requires libjpeg"
#endif

import Sane.sane

import stdio
import math

import curl/curl

#ifndef BACKEND_NAME
#define BACKEND_NAME escl
#endif

#define DEBUG_NOT_STATIC
import Sane.sanei_debug

#ifndef DBG_LEVEL
#define DBG_LEVEL       PASTE(sanei_debug_, BACKEND_NAME)
#endif
#ifndef NDEBUG
# define DBGDUMP(level, buf, size) \
    do { if(DBG_LEVEL >= (level)) sanei_escl_dbgdump(buf, size); } while(0)
#else
# define DBGDUMP(level, buf, size)
#endif

#define ESCL_CONFIG_FILE "escl.conf"


enum {
   PLATEN = 0,
   ADFSIMPLEX,
   ADFDUPLEX
]


typedef struct {
    Int             p1_0
    Int             p2_0
    Int             p3_3
    Int             DocumentType
    Int             p4_0
    Int             p5_0
    Int             p6_1
    Int             reserve[11]
} ESCL_SCANOPTS


typedef struct ESCL_Device {
    struct ESCL_Device *next

    char     *model_name
    Int       port_nb
    char     *ip_address
    char     *is
    char     *uuid
    char     *type
    Bool https
    struct curl_slist *hack
    char     *unix_socket
} ESCL_Device

typedef struct capst
{
    Int height
    Int width
    Int pos_x
    Int pos_y
    String default_color
    String default_format
    Int default_resolution
    Int MinWidth
    Int MaxWidth
    Int MinHeight
    Int MaxHeight
    Int MaxScanRegions
    Sane.String_Const *ColorModes
    Int ColorModesSize
    Sane.String_Const *ContentTypes
    Int ContentTypesSize
    Sane.String_Const *DocumentFormats
    Int DocumentFormatsSize
    Int format_ext
    Int *SupportedResolutions
    Int SupportedResolutionsSize
    Sane.String_Const *SupportedIntents
    Int SupportedIntentsSize
    Sane.String_Const SupportedIntentDefault
    Int MaxOpticalXResolution
    Int RiskyLeftMargin
    Int RiskyRightMargin
    Int RiskyTopMargin
    Int RiskyBottomMargin
    Int duplex
    Int have_jpeg
    Int have_png
    Int have_tiff
    Int have_pdf
} caps_t

typedef struct support
{
    Int min
    Int max
    Int normal
    step: Int
} support_t

typedef struct capabilities
{
    caps_t caps[3]
    Int source
    Sane.String_Const *Sources
    Int SourcesSize
    FILE *tmp
    unsigned char *img_data
    long img_size
    long img_read
    size_t real_read
    Bool work
    support_t *brightness
    support_t *contrast
    support_t *sharpen
    support_t *threshold
    Int use_brightness
    Int val_brightness
    Int use_contrast
    Int val_contrast
    Int use_sharpen
    Int val_sharpen
    Int use_threshold
    Int val_threshold
} capabilities_t

typedef struct {
    Int                             XRes
    Int                             YRes
    Int                             Left
    Int                             Top
    Int                             Right
    Int                             Bottom
    Int                             ScanMode
    Int                             ScanMethod
    ESCL_SCANOPTS  opts
} ESCL_ScanParam


enum
{
    OPT_NUM_OPTS = 0,
    OPT_MODE_GROUP,
    OPT_MODE,
    OPT_RESOLUTION,
    OPT_SCAN_SOURCE,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,
    OPT_TL_Y,
    OPT_BR_X,
    OPT_BR_Y,

    OPT_ENHANCEMENT_GROUP,
    OPT_PREVIEW,
    OPT_GRAY_PREVIEW,
    OPT_BRIGHTNESS,
    OPT_CONTRAST,
    OPT_SHARPEN,
    OPT_THRESHOLD,

    NUM_OPTIONS
]

#define PIXEL_TO_MM(pixels, dpi) Sane.FIX((double)pixels * 25.4 / (dpi))
#define MM_TO_PIXEL(millimeters, dpi) (Sane.Word)round(Sane.UNFIX(millimeters) * (dpi) / 25.4)

ESCL_Device *escl_devices(Sane.Status *status)
Sane.Status escl_device_add(Int port_nb,
                            const char *model_name,
                            char *ip_address,
                            const char *is,
                            const char *uuid,
                            char *type)

Sane.Status escl_status(const ESCL_Device *device,
                        Int source,
                        const char* jobId,
                        Sane.Status *job)

capabilities_t *escl_capabilities(ESCL_Device *device,
                                  Sane.Status *status)

char *escl_newjob(capabilities_t *scanner,
                  const ESCL_Device *device,
                  Sane.Status *status)

Sane.Status escl_scan(capabilities_t *scanner,
                      const ESCL_Device *device,
                      char *result)

void escl_scanner(const ESCL_Device *device,
                  char *result)

typedef void CURL

void escl_curl_url(CURL *handle,
                   const ESCL_Device *device,
                   Sane.String_Const path)

unsigned char *escl_crop_surface(capabilities_t *scanner,
                                 unsigned char *surface,
                                 Int w,
                                 Int h,
                                 Int bps,
                                 Int *width,
                                 Int *height)

// JPEG
Sane.Status get_JPEG_data(capabilities_t *scanner,
                          Int *width,
                          Int *height,
                          Int *bps)

// PNG
Sane.Status get_PNG_data(capabilities_t *scanner,
                         Int *width,
                         Int *height,
                         Int *bps)

// TIFF
Sane.Status get_TIFF_data(capabilities_t *scanner,
                          Int *width,
                          Int *height,
                          Int *bps)

// PDF
Sane.Status get_PDF_data(capabilities_t *scanner,
                         Int *width,
                         Int *height,
                         Int *bps)

#endif


/* sane - Scanner Access Now Easy.

   Copyright(C) 2019 Touboul Nathane
   Copyright(C) 2019 Thierry HUCHARD <thierry@ordissimo.com>

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or(at your
   option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

   This file implements a SANE backend for eSCL scanners.  */

import escl

import stdio
import stdlib
import string

import setjmp

import Sane.saneopts
import Sane.sanei
import Sane.sanei_backend
import Sane.sanei_config


#ifndef Sane.NAME_SHARPEN
# define Sane.NAME_SHARPEN "sharpen"
# define Sane.TITLE_SHARPEN Sane.I18N("Sharpen")
# define Sane.DESC_SHARPEN Sane.I18N("Set sharpen value.")
#endif

#ifndef Sane.NAME_THRESHOLD
# define Sane.NAME_THRESHOLD "threshold"
#endif
#ifndef Sane.TITLE_THRESHOLD
# define Sane.TITLE_THRESHOLD Sane.I18N("Threshold")
#endif
#ifndef Sane.DESC_THRESHOLD
# define Sane.DESC_THRESHOLD \
    Sane.I18N("Set threshold for line-art scans.")
#endif

#define min(A,B) (((A)<(B)) ? (A) : (B))
#define max(A,B) (((A)>(B)) ? (A) : (B))
#define IS_ACTIVE(OPTION) (((handler.opt[OPTION].cap) & Sane.CAP_INACTIVE) == 0)
#define INPUT_BUFFER_SIZE 4096

static const Sane.Device **devlist = NULL
static ESCL_Device *list_devices_primary = NULL
static Int num_devices = 0

typedef struct Handled {
    struct Handled *next
    ESCL_Device *device
    char *result
    ESCL_ScanParam param
    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]
    capabilities_t *scanner
    Sane.Range x_range1
    Sane.Range x_range2
    Sane.Range y_range1
    Sane.Range y_range2
    Sane.Range brightness_range
    Sane.Range contrast_range
    Sane.Range sharpen_range
    Sane.Range thresold_range
    Bool cancel
    Bool write_scan_data
    Bool decompress_scan_data
    Bool end_read
    Sane.Parameters ps
} escl_Sane.t

static ESCL_Device *
escl_free_device(ESCL_Device *current)
{
    if(!current) return NULL
    free((void*)current.ip_address)
    free((void*)current.model_name)
    free((void*)current.type)
    free((void*)current.is)
    free((void*)current.uuid)
    free((void*)current.unix_socket)
    curl_slist_free_all(current.hack)
    free(current)
    return NULL
}

void
escl_free_handler(escl_Sane.t *handler)
{
    if(handler == NULL)
        return

    escl_free_device(handler.device)
    free(handler)
}

Sane.Status escl_parse_name(Sane.String_Const name, ESCL_Device *device)

static Sane.Status
escl_check_and_add_device(ESCL_Device *current)
{
    if(!current) {
      DBG(10, "ESCL_Device *current us null.\n")
      return(Sane.STATUS_NO_MEM)
    }
    if(!current.ip_address) {
      DBG(10, "Ip Address allocation failure.\n")
      return(Sane.STATUS_NO_MEM)
    }
    if(current.port_nb == 0) {
      DBG(10, "No port defined.\n")
      return(Sane.STATUS_NO_MEM)
    }
    if(!current.model_name) {
      DBG(10, "Modele Name allocation failure.\n")
      return(Sane.STATUS_NO_MEM)
    }
    if(!current.type) {
      DBG(10, "Scanner Type allocation failure.\n")
      return(Sane.STATUS_NO_MEM)
    }
    if(!current.is) {
      DBG(10, "Scanner Is allocation failure.\n")
      return(Sane.STATUS_NO_MEM)
    }
    ++num_devices
    current.next = list_devices_primary
    list_devices_primary = current
    return(Sane.STATUS_GOOD)
}

/**
 * \fn static Sane.Status escl_add_in_list(ESCL_Device *current)
 * \brief Function that adds all the element needed to my list :
 *        the port number, the model name, the ip address, and the type of url(http/https).
 *        Moreover, this function counts the number of devices found.
 *
 * \return Sane.STATUS_GOOD if everything is OK.
 */
static Sane.Status
escl_add_in_list(ESCL_Device *current)
{
    if(!current) {
      DBG(10, "ESCL_Device *current us null.\n")
      return(Sane.STATUS_NO_MEM)
    }

    if(Sane.STATUS_GOOD ==
        escl_check_and_add_device(current)) {
        list_devices_primary = current
        return(Sane.STATUS_GOOD)
    }
    current = escl_free_device(current)
    return(Sane.STATUS_NO_MEM)
}

/**
 * \fn Sane.Status escl_device_add(Int port_nb, const char *model_name, char *ip_address, char *type)
 * \brief Function that browses my list("for" loop) and returns the "escl_add_in_list" function to
 *        adds all the element needed to my list :
 *        the port number, the model name, the ip address and the type of the url(http / https).
 *
 * \return escl_add_in_list(current)
 */
Sane.Status
escl_device_add(Int port_nb,
                const char *model_name,
                char *ip_address,
                const char *is,
                const char *uuid,
                char *type)
{
    char tmp[PATH_MAX] = { 0 ]
    char *model = NULL
    ESCL_Device *current = NULL
    DBG(10, "escl_device_add\n")
    for(current = list_devices_primary; current; current = current.next) {
	if((strcmp(current.ip_address, ip_address) == 0) ||
            (uuid && current.uuid && !strcmp(current.uuid, uuid)))
           {
	      if(strcmp(current.type, type))
                {
                  if(!strcmp(type, "_uscans._tcp") ||
                     !strcmp(type, "https"))
                    {
                       free(current.type)
                       current.type = strdup(type)
                       if(strcmp(current.ip_address, ip_address)) {
                           free(current.ip_address)
                           current.ip_address = strdup(ip_address)
                       }
                       current.port_nb = port_nb
                       current.https = Sane.TRUE
                    }
	          return(Sane.STATUS_GOOD)
                }
              else if(current.port_nb == port_nb)
	        return(Sane.STATUS_GOOD)
           }
    }
    current = (ESCL_Device*)calloc(1, sizeof(*current))
    if(current == NULL) {
       DBG(10, "New device allocation failure.\n")
       return(Sane.STATUS_NO_MEM)
    }
    current.port_nb = port_nb

    if(strcmp(type, "_uscan._tcp") != 0 && strcmp(type, "http") != 0) {
        snprintf(tmp, sizeof(tmp), "%s SSL", model_name)
        current.https = Sane.TRUE
    } else {
        current.https = Sane.FALSE
    }
    model = (char*)(tmp[0] != 0 ? tmp : model_name)
    current.model_name = strdup(model)
    current.ip_address = strdup(ip_address)
    memset(tmp, 0, PATH_MAX)
    snprintf(tmp, sizeof(tmp), "%s scanner", (is ? is : "flatbed or ADF"))
    current.is = strdup(tmp)
    current.type = strdup(type)
    if(uuid)
       current.uuid = strdup(uuid)
    return escl_add_in_list(current)
}

/**
 * \fn static inline size_t max_string_size(const Sane.String_Const strings[])
 * \brief Function that browses the string("for" loop) and counts the number of character in the string.
 *        --> this allows to know the maximum size of the string.
 *
 * \return max_size + 1 (the size max)
 */
static inline size_t
max_string_size(const Sane.String_Const strings[])
{
    size_t max_size = 0
    var i: Int = 0

    for(i = 0; strings[i]; ++i) {
	size_t size = strlen(strings[i])
	if(size > max_size)
	    max_size = size
    }
    return(max_size + 1)
}

static char *
get_vendor(char *search)
{
	if(strcasestr(search, "Epson"))
		return strdup("Epson")
	else if(strcasestr(search, "Fujitsu"))
		return strdup("Fujitsu")
	else if(strcasestr(search, "HP"))
		return strdup("HP")
	else if(strcasestr(search, "Canon"))
		return strdup("Canon")
	else if(strcasestr(search, "Lexmark"))
		return strdup("Lexmark")
	else if(strcasestr(search, "Samsung"))
		return strdup("Samsung")
	else if(strcasestr(search, "Xerox"))
		return strdup("Xerox")
	else if(strcasestr(search, "OKI"))
		return strdup("OKI")
	else if(strcasestr(search, "Hewlett Packard"))
		return strdup("Hewlett Packard")
	else if(strcasestr(search, "IBM"))
		return strdup("IBM")
	else if(strcasestr(search, "Mustek"))
		return strdup("Mustek")
	else if(strcasestr(search, "Ricoh"))
		return strdup("Ricoh")
	else if(strcasestr(search, "Sharp"))
		return strdup("Sharp")
	else if(strcasestr(search, "UMAX"))
		return strdup("UMAX")
	else if(strcasestr(search, "PINT"))
		return strdup("PINT")
	else if(strcasestr(search, "Brother"))
		return strdup("Brother")
	return NULL
}

/**
 * \fn static Sane.Device *convertFromESCLDev(ESCL_Device *cdev)
 * \brief Function that checks if the url of the received scanner is secured or not(http / https).
 *        --> if the url is not secured, our own url will be composed like "http://"ip":"port"".
 *        --> else, our own url will be composed like "https://"ip":"port"".
 *        AND, it"s in this function that we gather all the information of the url(that were in our list) :
 *        the model_name, the port, the ip, and the type of url.
 *        SO, leaving this function, we have in memory the complete url.
 *
 * \return sdev(structure that contains the elements of the url)
 */
static Sane.Device *
convertFromESCLDev(ESCL_Device *cdev)
{
    char *tmp
    Int len, lv = 0
    char unix_path[PATH_MAX+7] = { 0 ]
    Sane.Device *sdev = (Sane.Device*) calloc(1, sizeof(Sane.Device))
    if(!sdev) {
       DBG(10, "Sane_Device allocation failure.\n")
       return NULL
    }

    if(cdev.unix_socket && strlen(cdev.unix_socket)) {
        snprintf(unix_path, sizeof(unix_path), "unix:%s:", cdev.unix_socket)
    }
    len = snprintf(NULL, 0, "%shttp%s://%s:%d",
             unix_path, cdev.https ? "s" : "", cdev.ip_address, cdev.port_nb)
    len++
    tmp = (char *)malloc(len)
    if(!tmp) {
        DBG(10, "Name allocation failure.\n")
        goto freedev
    }
    snprintf(tmp, len, "%shttp%s://%s:%d",
             unix_path, cdev.https ? "s" : "", cdev.ip_address, cdev.port_nb)
    sdev.name = tmp

    DBG( 1, "Escl add device : %s\n", tmp)
    sdev.vendor = get_vendor(cdev.model_name)

    if(!sdev.vendor)
       sdev.vendor = strdup("ESCL")
    else
       lv = strlen(sdev.vendor) + 1
    if(!sdev.vendor) {
       DBG(10, "Vendor allocation failure.\n")
       goto freemodel
    }
    sdev.model = strdup(lv + cdev.model_name)
    if(!sdev.model) {
       DBG(10, "Model allocation failure.\n")
       goto freename
    }
    sdev.type = strdup(cdev.is)
    if(!sdev.type) {
       DBG(10, "Scanner Type allocation failure.\n")
       goto freevendor
    }
    return(sdev)
freevendor:
    free((void*)sdev.vendor)
freemodel:
    free((void*)sdev.model)
freename:
    free((void*)sdev.name)
freedev:
    free((void*)sdev)
    return NULL
}

/**
 * \fn Sane.Status Sane.init(Int *version_code, Sane.Auth_Callback authorize)
 * \brief Function that"s called before any other SANE function ; it"s the first SANE function called.
 *        --> this function checks the SANE config. and can check the authentication of the user if
 *        "authorize" value is more than Sane.TRUE.
 *        In this case, it will be necessary to define an authentication method.
 *
 * \return Sane.STATUS_GOOD(everything is OK)
 */
Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
    DBG_INIT()
    DBG(10, "escl Sane.init\n")
    Sane.Status status = Sane.STATUS_GOOD
    curl_global_init(CURL_GLOBAL_ALL)
    if(version_code != NULL)
	*version_code = Sane.VERSION_CODE(1, 0, 0)
    if(status != Sane.STATUS_GOOD)
	return(status)
    return(Sane.STATUS_GOOD)
}

/**
 * \fn void Sane.exit(void)
 * \brief Function that must be called to terminate use of a backend.
 *        This function will first close all device handles that still might be open.
 *        --> by freeing all the elements of my list.
 *        After this function, no function other than "Sane.init" may be called.
 */
void
Sane.exit(void)
{
    DBG(10, "escl Sane.exit\n")
    ESCL_Device *next = NULL

    while(list_devices_primary != NULL) {
	next = list_devices_primary.next
	free(list_devices_primary)
	list_devices_primary = next
    }
    if(devlist)
	free(devlist)
    list_devices_primary = NULL
    devlist = NULL
    curl_global_cleanup()
}

/**
 * \fn static Sane.Status attach_one_config(SANEI_Config *config, const char *line)
 * \brief Function that implements a configuration file to the user :
 *        if the user can"t detect some devices, he will be able to force their detection with this config" file to use them.
 *        Thus, this function parses the config" file to use the device of the user with the information below :
 *        the type of protocol(http/https), the ip, the port number, and the model name.
 *
 * \return escl_add_in_list(escl_device) if the parsing worked, Sane.STATUS_GOOD otherwise.
 */
static Sane.Status
attach_one_config(SANEI_Config __Sane.unused__ *config, const char *line,
		  void __Sane.unused__ *data)
{
    Int port = 0
    Sane.Status status
    static ESCL_Device *escl_device = NULL

    if(strncmp(line, "device", 6) == 0) {
        char *name_str = NULL
        char *opt_model = NULL
        char *opt_hack = NULL

        line = sanei_config_get_string(line + 6, &name_str)
        DBG(10, "New Escl_Device URL[%s].\n", (name_str ? name_str : "VIDE"))
        if(!name_str || !*name_str) {
            DBG(1, "Escl_Device URL missing.\n")
            return Sane.STATUS_INVAL
        }
        if(*line) {
            line = sanei_config_get_string(line, &opt_model)
            DBG(10, "New Escl_Device model[%s].\n", opt_model)
        }
        if(*line) {
            line = sanei_config_get_string(line, &opt_hack)
            DBG(10, "New Escl_Device hack[%s].\n", opt_hack)
        }

        escl_free_device(escl_device)
        escl_device = (ESCL_Device*)calloc(1, sizeof(ESCL_Device))
        if(!escl_device) {
           DBG(10, "New Escl_Device allocation failure.\n")
           free(name_str)
           return(Sane.STATUS_NO_MEM)
        }
        status = escl_parse_name(name_str, escl_device)
        free(name_str)
        if(status != Sane.STATUS_GOOD) {
            escl_free_device(escl_device)
            escl_device = NULL
            return status
        }
        escl_device.model_name = opt_model ? opt_model : strdup("Unknown model")
        escl_device.is = strdup("flatbed or ADF scanner")
        escl_device.type = strdup("In url")
        escl_device.uuid = NULL
    }

    if(strncmp(line, "[device]", 8) == 0) {
	escl_device = escl_free_device(escl_device)
	escl_device = (ESCL_Device*)calloc(1, sizeof(ESCL_Device))
	if(!escl_device) {
	   DBG(10, "New Escl_Device allocation failure.")
	   return(Sane.STATUS_NO_MEM)
	}
    }
    else if(strncmp(line, "ip", 2) == 0) {
	const char *ip_space = sanei_config_skip_whitespace(line + 2)
	DBG(10, "New Escl_Device IP[%s].", (ip_space ? ip_space : "VIDE"))
	if(escl_device != NULL && ip_space != NULL) {
	    DBG(10, "New Escl_Device IP Affected.")
	    escl_device.ip_address = strdup(ip_space)
	}
    }
    else if(sscanf(line, "port %i", &port) == 1 && port != 0) {
	DBG(10, "New Escl_Device PORT[%d].", port)
	if(escl_device != NULL) {
	    DBG(10, "New Escl_Device PORT Affected.")
	    escl_device.port_nb = port
	}
    }
    else if(strncmp(line, "model", 5) == 0) {
	const char *model_space = sanei_config_skip_whitespace(line + 5)
	DBG(10, "New Escl_Device MODEL[%s].", (model_space ? model_space : "VIDE"))
	if(escl_device != NULL && model_space != NULL) {
	    DBG(10, "New Escl_Device MODEL Affected.")
	    escl_device.model_name = strdup(model_space)
	}
    }
    else if(strncmp(line, "type", 4) == 0) {
	const char *type_space = sanei_config_skip_whitespace(line + 4)
	DBG(10, "New Escl_Device TYPE[%s].", (type_space ? type_space : "VIDE"))
	if(escl_device != NULL && type_space != NULL) {
	    DBG(10, "New Escl_Device TYPE Affected.")
	    escl_device.type = strdup(type_space)
	}
    }
    escl_device.is = strdup("flatbed or ADF scanner")
    escl_device.uuid = NULL
    status = escl_check_and_add_device(escl_device)
    if(status == Sane.STATUS_GOOD)
       escl_device = NULL
    return status
}

/**
 * \fn Sane.Status Sane.get_devices(const Sane.Device ***device_list, Bool local_only)
 * \brief Function that searches for connected devices and places them in our "device_list". ("for" loop)
 *        If the attribute "local_only" is worth Sane.FALSE, we only returns the connected devices locally.
 *
 * \return Sane.STATUS_GOOD if devlist != NULL ; Sane.STATUS_NO_MEM otherwise.
 */
Sane.Status
Sane.get_devices(const Sane.Device ***device_list, Bool local_only)
{
    if(local_only)             /* eSCL is a network-only protocol */
	return(device_list ? Sane.STATUS_GOOD : Sane.STATUS_INVAL)

    DBG(10, "escl Sane.get_devices\n")
    ESCL_Device *dev = NULL
    static const Sane.Device **devlist = 0
    Sane.Status status

    if(device_list == NULL)
	return(Sane.STATUS_INVAL)
    status = sanei_configure_attach(ESCL_CONFIG_FILE, NULL,
				    attach_one_config, NULL)
    if(status != Sane.STATUS_GOOD)
	return(status)
    escl_devices(&status)
    if(status != Sane.STATUS_GOOD)
	return(status)
    if(devlist)
	free(devlist)
    devlist = (const Sane.Device **) calloc(num_devices + 1, sizeof(devlist[0]))
    if(devlist == NULL)
	return(Sane.STATUS_NO_MEM)
    var i: Int = 0
    for(dev = list_devices_primary; i < num_devices; dev = dev.next) {
	Sane.Device *s_dev = convertFromESCLDev(dev)
	devlist[i] = s_dev
	i++
    }
    devlist[i] = 0
    *device_list = devlist
    return(devlist) ? Sane.STATUS_GOOD : Sane.STATUS_NO_MEM
}

/* Returns the length of the longest string, including the terminating
 * character. */
static size_t
_source_size_max(Sane.String_Const * sources)
{
  size_t size = 0

  while(*sources)
   {
      size_t t = strlen(*sources) + 1
      if(t > size)
          size = t
      sources++
   }
  return size
}

static Int
_get_resolution(escl_Sane.t *handler, Int resol)
{
    Int x = 1
    Int n = handler.scanner.caps[handler.scanner.source].SupportedResolutions[0] + 1
    Int old = -1
    for(; x < n; x++) {
      DBG(10, "SEARCH RESOLUTION[ %d | %d]\n", resol, (Int)handler.scanner.caps[handler.scanner.source].SupportedResolutions[x])
      if(resol == handler.scanner.caps[handler.scanner.source].SupportedResolutions[x])
         return resol
      else if(resol < handler.scanner.caps[handler.scanner.source].SupportedResolutions[x])
      {
          if(old == -1)
             return handler.scanner.caps[handler.scanner.source].SupportedResolutions[1]
          else
             return old
      }
      else
          old = handler.scanner.caps[handler.scanner.source].SupportedResolutions[x]
    }
    return old
}


/**
 * \fn static Sane.Status init_options(Sane.String_Const name, escl_Sane.t *s)
 * \brief Function thzt initializes all the needed options of the received scanner
 *        (the resolution / the color / the margins) thanks to the information received with
 *        the "escl_capabilities" function, called just before.
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD)
 */
static Sane.Status
init_options_small(Sane.String_Const name_source, escl_Sane.t *s)
{
    Int found = 0
    DBG(10, "escl init_options\n")

    Sane.Status status = Sane.STATUS_GOOD
    if(!s.scanner) return Sane.STATUS_INVAL
    if(name_source) {
	   Int source = s.scanner.source
	   if(!strcmp(name_source, Sane.I18N("ADF Duplex")))
	       s.scanner.source = ADFDUPLEX
	   else if(!strncmp(name_source, "A", 1) ||
	            !strcmp(name_source, Sane.I18N("ADF")))
	       s.scanner.source = ADFSIMPLEX
	   else
	       s.scanner.source = PLATEN
	   if(source == s.scanner.source) return status
           s.scanner.caps[s.scanner.source].default_color =
                strdup(s.scanner.caps[source].default_color)
           s.scanner.caps[s.scanner.source].default_resolution =
                _get_resolution(s, s.scanner.caps[source].default_resolution)
    }
    if(s.scanner.caps[s.scanner.source].ColorModes == NULL) {
        if(s.scanner.caps[PLATEN].ColorModes)
            s.scanner.source = PLATEN
        else if(s.scanner.caps[ADFSIMPLEX].ColorModes)
            s.scanner.source = ADFSIMPLEX
        else if(s.scanner.caps[ADFDUPLEX].ColorModes)
            s.scanner.source = ADFDUPLEX
        else
            return Sane.STATUS_INVAL
    }
    if(s.scanner.source == PLATEN) {
        DBG(10, "SOURCE PLATEN.\n")
    }
    else if(s.scanner.source == ADFDUPLEX) {
        DBG(10, "SOURCE ADFDUPLEX.\n")
    }
    else if(s.scanner.source == ADFSIMPLEX) {
        DBG(10, "SOURCE ADFSIMPLEX.\n")
    }
    s.x_range1.min = 0
    s.x_range1.max =
	    PIXEL_TO_MM((s.scanner.caps[s.scanner.source].MaxWidth -
		         s.scanner.caps[s.scanner.source].MinWidth),
			300.0)
    s.x_range1.quant = 0
    s.x_range2.min = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MinWidth, 300.0)
    s.x_range2.max = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MaxWidth, 300.0)
    s.x_range2.quant = 0
    s.y_range1.min = 0
    s.y_range1.max =
	    PIXEL_TO_MM((s.scanner.caps[s.scanner.source].MaxHeight -
	                 s.scanner.caps[s.scanner.source].MinHeight),
			300.0)
    s.y_range1.quant = 0
    s.y_range2.min = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MinHeight, 300.0)
    s.y_range2.max = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MaxHeight, 300.0)
    s.y_range2.quant = 0

    s.opt[OPT_MODE].constraint.string_list = s.scanner.caps[s.scanner.source].ColorModes
    if(s.val[OPT_MODE].s)
        free(s.val[OPT_MODE].s)
    s.val[OPT_MODE].s = NULL

    if(s.scanner.caps[s.scanner.source].default_color) {
        Int x = 0
        if(!strcmp(s.scanner.caps[s.scanner.source].default_color, "Grayscale8"))
           s.val[OPT_MODE].s = (char *)strdup(Sane.VALUE_SCAN_MODE_GRAY)
        else if(!strcmp(s.scanner.caps[s.scanner.source].default_color, "BlackAndWhite1"))
           s.val[OPT_MODE].s = (char *)strdup(Sane.VALUE_SCAN_MODE_LINEART)
        else
           s.val[OPT_MODE].s = (char *)strdup(Sane.VALUE_SCAN_MODE_COLOR)
        for(x = 0; s.scanner.caps[s.scanner.source].ColorModes[x]; x++) {
            if(s.scanner.caps[s.scanner.source].ColorModes[x] &&
              !strcasecmp(s.scanner.caps[s.scanner.source].ColorModes[x], s.val[OPT_MODE].s)) {
              found = 1
              break
            }
        }
    }
    if(!s.scanner.caps[s.scanner.source].default_color || found == 0) {
        if(s.scanner.caps[s.scanner.source].default_color)
           free(s.scanner.caps[s.scanner.source].default_color)
        s.val[OPT_MODE].s = strdup(s.scanner.caps[s.scanner.source].ColorModes[0])
        if(!strcasecmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY))
            s.scanner.caps[s.scanner.source].default_color = strdup("Grayscale8")
        else if(!strcasecmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART))
            s.scanner.caps[s.scanner.source].default_color = strdup("BlackAndWhite1")
        else
            s.scanner.caps[s.scanner.source].default_color = strdup("RGB24")
    }
    if(!s.val[OPT_MODE].s) {
       DBG(10, "Color Mode Default allocation failure.\n")
       return(Sane.STATUS_NO_MEM)
    }
    if(!s.scanner.caps[s.scanner.source].default_color) {
       DBG(10, "Color Mode Default allocation failure.\n")
       return(Sane.STATUS_NO_MEM)
    }
    s.val[OPT_RESOLUTION].w = s.scanner.caps[s.scanner.source].default_resolution
    s.opt[OPT_TL_X].constraint.range = &s.x_range1
    s.opt[OPT_TL_Y].constraint.range = &s.y_range1
    s.opt[OPT_BR_X].constraint.range = &s.x_range2
    s.opt[OPT_BR_Y].constraint.range = &s.y_range2

    if(s.val[OPT_SCAN_SOURCE].s)
      free(s.val[OPT_SCAN_SOURCE].s)
    s.val[OPT_SCAN_SOURCE].s = strdup(s.scanner.Sources[s.scanner.source])

    return(Sane.STATUS_GOOD)
}

/**
 * \fn static Sane.Status init_options(Sane.String_Const name, escl_Sane.t *s)
 * \brief Function thzt initializes all the needed options of the received scanner
 *        (the resolution / the color / the margins) thanks to the information received with
 *        the "escl_capabilities" function, called just before.
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD)
 */
static Sane.Status
init_options(Sane.String_Const name_source, escl_Sane.t *s)
{
    DBG(10, "escl init_options\n")

    Sane.Status status = Sane.STATUS_GOOD
    var i: Int = 0
    if(!s.scanner) return Sane.STATUS_INVAL
    if(name_source) {
	   Int source = s.scanner.source
	   DBG(10, "escl init_options name[%s]\n", name_source)
	   if(!strcmp(name_source, Sane.I18N("ADF Duplex")))
	       s.scanner.source = ADFDUPLEX
	   else if(!strncmp(name_source, "A", 1) ||
	            !strcmp(name_source, Sane.I18N("ADF")))
	       s.scanner.source = ADFSIMPLEX
	   else
	       s.scanner.source = PLATEN
	   if(source == s.scanner.source) return status
    }
    if(s.scanner.caps[s.scanner.source].ColorModes == NULL) {
        if(s.scanner.caps[PLATEN].ColorModes)
            s.scanner.source = PLATEN
        else if(s.scanner.caps[ADFSIMPLEX].ColorModes)
            s.scanner.source = ADFSIMPLEX
        else if(s.scanner.caps[ADFDUPLEX].ColorModes)
            s.scanner.source = ADFDUPLEX
        else
            return Sane.STATUS_INVAL
    }
    if(s.scanner.source == PLATEN) {
        DBG(10, "SOURCE PLATEN.\n")
    }
    else if(s.scanner.source == ADFDUPLEX) {
        DBG(10, "SOURCE ADFDUPLEX.\n")
    }
    else if(s.scanner.source == ADFSIMPLEX) {
        DBG(10, "SOURCE ADFSIMPLEX.\n")
    }
    memset(s.opt, 0, sizeof(s.opt))
    memset(s.val, 0, sizeof(s.val))
    for(i = 0; i < NUM_OPTIONS; ++i) {
	   s.opt[i].size = sizeof(Sane.Word)
	   s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
    s.x_range1.min = 0
    s.x_range1.max =
	    PIXEL_TO_MM((s.scanner.caps[s.scanner.source].MaxWidth -
		         s.scanner.caps[s.scanner.source].MinWidth),
			300.0)
    s.x_range1.quant = 0
    s.x_range2.min = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MinWidth, 300.0)
    s.x_range2.max = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MaxWidth, 300.0)
    s.x_range2.quant = 0
    s.y_range1.min = 0
    s.y_range1.max =
	    PIXEL_TO_MM((s.scanner.caps[s.scanner.source].MaxHeight -
	                 s.scanner.caps[s.scanner.source].MinHeight),
			300.0)
    s.y_range1.quant = 0
    s.y_range2.min = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MinHeight, 300.0)
    s.y_range2.max = PIXEL_TO_MM(s.scanner.caps[s.scanner.source].MaxHeight, 300.0)
    s.y_range2.quant = 0
    s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
    s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
    s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
    s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
    s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

    s.opt[OPT_MODE_GROUP].title = Sane.TITLE_SCAN_MODE
    s.opt[OPT_MODE_GROUP].desc = ""
    s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
    s.opt[OPT_MODE_GROUP].cap = 0
    s.opt[OPT_MODE_GROUP].size = 0
    s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
    s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
    s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
    s.opt[OPT_MODE].type = Sane.TYPE_STRING
    s.opt[OPT_MODE].unit = Sane.UNIT_NONE
    s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    s.opt[OPT_MODE].constraint.string_list = s.scanner.caps[s.scanner.source].ColorModes
    if(s.scanner.caps[s.scanner.source].default_color) {
        if(!strcasecmp(s.scanner.caps[s.scanner.source].default_color, "Grayscale8"))
           s.val[OPT_MODE].s = (char *)strdup(Sane.VALUE_SCAN_MODE_GRAY)
        else if(!strcasecmp(s.scanner.caps[s.scanner.source].default_color, "BlackAndWhite1"))
           s.val[OPT_MODE].s = (char *)strdup(Sane.VALUE_SCAN_MODE_LINEART)
        else
           s.val[OPT_MODE].s = (char *)strdup(Sane.VALUE_SCAN_MODE_COLOR)
    }
    else {
        s.val[OPT_MODE].s = (char *)strdup(s.scanner.caps[s.scanner.source].ColorModes[0])
        if(!strcasecmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY)) {
           s.scanner.caps[s.scanner.source].default_color = strdup("Grayscale8")
        }
        else if(!strcasecmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART)) {
           s.scanner.caps[s.scanner.source].default_color =
                strdup("BlackAndWhite1")
        }
        else {
           s.scanner.caps[s.scanner.source].default_color =
               strdup("RGB24")
       }
    }
    if(!s.val[OPT_MODE].s) {
       DBG(10, "Color Mode Default allocation failure.\n")
       return(Sane.STATUS_NO_MEM)
    }
    DBG(10, "++ Color Mode Default allocation[%s].\n", s.scanner.caps[s.scanner.source].default_color)
    s.opt[OPT_MODE].size = max_string_size(s.scanner.caps[s.scanner.source].ColorModes)
    if(!s.scanner.caps[s.scanner.source].default_color) {
       DBG(10, "Color Mode Default allocation failure.\n")
       return(Sane.STATUS_NO_MEM)
    }
    DBG(10, "Color Mode Default allocation(%s).\n", s.scanner.caps[s.scanner.source].default_color)

    s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
    s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
    s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
    s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
    s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
    s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
    s.opt[OPT_RESOLUTION].constraint.word_list = s.scanner.caps[s.scanner.source].SupportedResolutions
    s.val[OPT_RESOLUTION].w = s.scanner.caps[s.scanner.source].SupportedResolutions[1]
    s.scanner.caps[s.scanner.source].default_resolution = s.scanner.caps[s.scanner.source].SupportedResolutions[1]

    s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
    s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
    s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
    s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
    s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
    s.val[OPT_PREVIEW].w = Sane.FALSE

    s.opt[OPT_GRAY_PREVIEW].name = Sane.NAME_GRAY_PREVIEW
    s.opt[OPT_GRAY_PREVIEW].title = Sane.TITLE_GRAY_PREVIEW
    s.opt[OPT_GRAY_PREVIEW].desc = Sane.DESC_GRAY_PREVIEW
    s.opt[OPT_GRAY_PREVIEW].type = Sane.TYPE_BOOL
    s.val[OPT_GRAY_PREVIEW].w = Sane.FALSE

    s.opt[OPT_GEOMETRY_GROUP].title = Sane.TITLE_GEOMETRY
    s.opt[OPT_GEOMETRY_GROUP].desc = Sane.DESC_GEOMETRY
    s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
    s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
    s.opt[OPT_GEOMETRY_GROUP].size = 0
    s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
    s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
    s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
    s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
    s.opt[OPT_TL_X].size = sizeof(Sane.Fixed)
    s.opt[OPT_TL_X].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    s.opt[OPT_TL_X].unit = Sane.UNIT_MM
    s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
    s.opt[OPT_TL_X].constraint.range = &s.x_range1
    s.val[OPT_TL_X].w = s.x_range1.min

    s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
    s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
    s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
    s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
    s.opt[OPT_TL_Y].size = sizeof(Sane.Fixed)
    s.opt[OPT_TL_Y].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
    s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
    s.opt[OPT_TL_Y].constraint.range = &s.y_range1
    s.val[OPT_TL_Y].w = s.y_range1.min

    s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
    s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
    s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
    s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
    s.opt[OPT_BR_X].size = sizeof(Sane.Fixed)
    s.opt[OPT_BR_X].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    s.opt[OPT_BR_X].unit = Sane.UNIT_MM
    s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
    s.opt[OPT_BR_X].constraint.range = &s.x_range2
    s.val[OPT_BR_X].w = s.x_range2.max

    s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
    s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
    s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
    s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
    s.opt[OPT_BR_Y].size = sizeof(Sane.Fixed)
    s.opt[OPT_BR_Y].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
    s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
    s.opt[OPT_BR_Y].constraint.range = &s.y_range2
    s.val[OPT_BR_Y].w = s.y_range2.max

	/* OPT_SCAN_SOURCE */
    s.opt[OPT_SCAN_SOURCE].name = Sane.NAME_SCAN_SOURCE
    s.opt[OPT_SCAN_SOURCE].title = Sane.TITLE_SCAN_SOURCE
    s.opt[OPT_SCAN_SOURCE].desc = Sane.DESC_SCAN_SOURCE
    s.opt[OPT_SCAN_SOURCE].type = Sane.TYPE_STRING
    s.opt[OPT_SCAN_SOURCE].size = _source_size_max(s.scanner.Sources)
    s.opt[OPT_SCAN_SOURCE].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    s.opt[OPT_SCAN_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    s.opt[OPT_SCAN_SOURCE].constraint.string_list = s.scanner.Sources
    if(s.val[OPT_SCAN_SOURCE].s)
       free(s.val[OPT_SCAN_SOURCE].s)
    s.val[OPT_SCAN_SOURCE].s = strdup(s.scanner.Sources[s.scanner.source])

    /* "Enhancement" group: */
    s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
    s.opt[OPT_ENHANCEMENT_GROUP].desc = "";    /* not valid for a group */
    s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
    s.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
    s.opt[OPT_ENHANCEMENT_GROUP].size = 0
    s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE


    s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
    s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
    s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
    s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
    s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
    s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
    if(s.scanner.brightness) {
       s.opt[OPT_BRIGHTNESS].constraint.range = &s.brightness_range
       s.val[OPT_BRIGHTNESS].w = s.scanner.brightness.normal
       s.brightness_range.quant=1
       s.brightness_range.min=s.scanner.brightness.min
       s.brightness_range.max=s.scanner.brightness.max
    }
    else{
      Sane.Range range = { 0, 255, 0 ]
      s.opt[OPT_BRIGHTNESS].constraint.range = &range
      s.val[OPT_BRIGHTNESS].w = 0
      s.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE
    }
    s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
    s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
    s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
    s.opt[OPT_CONTRAST].type = Sane.TYPE_INT
    s.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
    s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
    if(s.scanner.contrast) {
       s.opt[OPT_CONTRAST].constraint.range = &s.contrast_range
       s.val[OPT_CONTRAST].w = s.scanner.contrast.normal
       s.contrast_range.quant=1
       s.contrast_range.min=s.scanner.contrast.min
       s.contrast_range.max=s.scanner.contrast.max
    }
    else{
      Sane.Range range = { 0, 255, 0 ]
      s.opt[OPT_CONTRAST].constraint.range = &range
      s.val[OPT_CONTRAST].w = 0
      s.opt[OPT_CONTRAST].cap |= Sane.CAP_INACTIVE
    }
    s.opt[OPT_SHARPEN].name = Sane.NAME_SHARPEN
    s.opt[OPT_SHARPEN].title = Sane.TITLE_SHARPEN
    s.opt[OPT_SHARPEN].desc = Sane.DESC_SHARPEN
    s.opt[OPT_SHARPEN].type = Sane.TYPE_INT
    s.opt[OPT_SHARPEN].unit = Sane.UNIT_NONE
    s.opt[OPT_SHARPEN].constraint_type = Sane.CONSTRAINT_RANGE
    if(s.scanner.sharpen) {
       s.opt[OPT_SHARPEN].constraint.range = &s.sharpen_range
       s.val[OPT_SHARPEN].w = s.scanner.sharpen.normal
       s.sharpen_range.quant=1
       s.sharpen_range.min=s.scanner.sharpen.min
       s.sharpen_range.max=s.scanner.sharpen.max
    }
    else{
      Sane.Range range = { 0, 255, 0 ]
      s.opt[OPT_SHARPEN].constraint.range = &range
      s.val[OPT_SHARPEN].w = 0
      s.opt[OPT_SHARPEN].cap |= Sane.CAP_INACTIVE
    }
    /*threshold*/
    s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
    s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
    s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
    s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
    s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
    s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
    if(s.scanner.threshold) {
      s.opt[OPT_THRESHOLD].constraint.range = &s.thresold_range
      s.val[OPT_THRESHOLD].w = s.scanner.threshold.normal
      s.thresold_range.quant=1
      s.thresold_range.min= s.scanner.threshold.min
      s.thresold_range.max=s.scanner.threshold.max
    }
    else{
      Sane.Range range = { 0, 255, 0 ]
      s.opt[OPT_THRESHOLD].constraint.range = &range
      s.val[OPT_THRESHOLD].w = 0
      s.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
    }
    if(!strcasecmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART)) {
       if(s.scanner.threshold)
       	  s.opt[OPT_THRESHOLD].cap  &= ~Sane.CAP_INACTIVE
       if(s.scanner.brightness)
       	  s.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE
       if(s.scanner.contrast)
       	  s.opt[OPT_CONTRAST].cap |= Sane.CAP_INACTIVE
       if(s.scanner.sharpen)
          s.opt[OPT_SHARPEN].cap |= Sane.CAP_INACTIVE
    }
    else {
       if(s.scanner.threshold)
       	  s.opt[OPT_THRESHOLD].cap  |= Sane.CAP_INACTIVE
       if(s.scanner.brightness)
          s.opt[OPT_BRIGHTNESS].cap &= ~Sane.CAP_INACTIVE
       if(s.scanner.contrast)
          s.opt[OPT_CONTRAST].cap   &= ~Sane.CAP_INACTIVE
       if(s.scanner.sharpen)
          s.opt[OPT_SHARPEN].cap   &= ~Sane.CAP_INACTIVE
    }
    return(status)
}

Sane.Status
escl_parse_name(Sane.String_Const name, ESCL_Device *device)
{
    Sane.String_Const host = NULL
    Sane.String_Const port_str = NULL
    DBG(10, "escl_parse_name\n")
    if(name == NULL || device == NULL) {
        return Sane.STATUS_INVAL
    }

    if(strncmp(name, "unix:", 5) == 0) {
        Sane.String_Const socket = name + 5
        name = strchr(socket, ":")
        if(name == NULL)
            return Sane.STATUS_INVAL
        device.unix_socket = strndup(socket, name - socket)
        name++
    }

    if(strncmp(name, "https://", 8) == 0) {
        device.https = Sane.TRUE
        host = name + 8
    } else if(strncmp(name, "http://", 7) == 0) {
        device.https = Sane.FALSE
        host = name + 7
    } else {
        DBG(1, "Unknown URL scheme in %s", name)
        return Sane.STATUS_INVAL
    }

    port_str = strchr(host, ":")
    if(port_str == NULL) {
        DBG(1, "Port missing from URL: %s", name)
        return Sane.STATUS_INVAL
    }
    port_str++
    device.port_nb = atoi(port_str)
    if(device.port_nb < 1 || device.port_nb > 65535) {
        DBG(1, "Invalid port number in URL: %s", name)
        return Sane.STATUS_INVAL
    }

    device.ip_address = strndup(host, port_str - host - 1)
    return Sane.STATUS_GOOD
}

static void
_get_hack(Sane.String_Const name, ESCL_Device *device)
{
  FILE *fp
  Sane.Char line[PATH_MAX]
  DBG(3, "_get_hack: start\n")
  if(device.model_name &&
      (strcasestr(device.model_name, "LaserJet FlowMFP M578") ||
       strcasestr(device.model_name, "LaserJet MFP M630"))) {
       device.hack = curl_slist_append(NULL, "Host: localhost")
       DBG(3, "_get_hack: finish\n")
       return
  }

  /* open configuration file */
  fp = sanei_config_open(ESCL_CONFIG_FILE)
  if(!fp)
    {
      DBG(2, "_get_hack: couldn"t access %s\n", ESCL_CONFIG_FILE)
      DBG(3, "_get_hack: exit\n")
    }

  /* loop reading the configuration file, all line beginning by "option " are
   * parsed for value to store in configuration structure, other line are
   * used are device to try to attach
   */
  while(sanei_config_read(line, PATH_MAX, fp))
    {
       if(strstr(line, name)) {
          DBG(3, "_get_hack: idevice found\n")
	  if(strstr(line, "hack=localhost")) {
              DBG(3, "_get_hack: device found\n")
	      device.hack = curl_slist_append(NULL, "Host: localhost")
	  }
	  goto finish_hack
       }
    }
finish_hack:
  DBG(3, "_get_hack: finish\n")
  fclose(fp)
}



/**
 * \fn Sane.Status Sane.open(Sane.String_Const name, Sane.Handle *h)
 * \brief Function that establishes a connection with the device named by "name",
 *        and returns a "handler" using "Sane.Handle *h", representing it.
 *        Thus, it"s this function that calls the "escl_status" function firstly,
 *        then the "escl_capabilities" function, and, after, the "init_options" function.
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle *h)
{
    DBG(10, "escl Sane.open\n")
    Sane.Status status
    escl_Sane.t *handler = NULL

    if(name == NULL)
        return(Sane.STATUS_INVAL)

    ESCL_Device *device = calloc(1, sizeof(ESCL_Device))
    if(device == NULL) {
        DBG(10, "Handle device allocation failure.\n")
        return Sane.STATUS_NO_MEM
    }
    status = escl_parse_name(name, device)
    if(status != Sane.STATUS_GOOD) {
        escl_free_device(device)
        return status
    }

    handler = (escl_Sane.t *)calloc(1, sizeof(escl_Sane.t))
    if(handler == NULL) {
        escl_free_device(device)
        return(Sane.STATUS_NO_MEM)
    }
    handler.device = device;  // Handler owns device now.
    handler.scanner = escl_capabilities(device, &status)
    if(status != Sane.STATUS_GOOD) {
        escl_free_handler(handler)
        return(status)
    }
    _get_hack(name, device)

    status = init_options(NULL, handler)
    if(status != Sane.STATUS_GOOD) {
        escl_free_handler(handler)
        return(status)
    }
    handler.ps.depth = 8
    handler.ps.last_frame = Sane.TRUE
    handler.ps.format = Sane.FRAME_RGB
    handler.ps.pixels_per_line = MM_TO_PIXEL(handler.val[OPT_BR_X].w, 300.0)
    handler.ps.lines = MM_TO_PIXEL(handler.val[OPT_BR_Y].w, 300.0)
    handler.ps.bytesPerLine = handler.ps.pixels_per_line * 3
    status = Sane.get_parameters(handler, 0)
    if(status != Sane.STATUS_GOOD) {
        escl_free_handler(handler)
        return(status)
    }
    handler.cancel = Sane.FALSE
    handler.write_scan_data = Sane.FALSE
    handler.decompress_scan_data = Sane.FALSE
    handler.end_read = Sane.FALSE
    *h = handler
    return(status)
}

/**
 * \fn void Sane.cancel(Sane.Handle h)
 * \brief Function that"s used to, immediately or as quickly as possible, cancel the currently
 *        pending operation of the device represented by "Sane.Handle h".
 *        This functions calls the "escl_scanner" functions, that resets the scan operations.
 */
void
Sane.cancel(Sane.Handle h)
{
    DBG(10, "escl Sane.cancel\n")
    escl_Sane.t *handler = h
    if(handler.scanner.tmp)
    {
      fclose(handler.scanner.tmp)
      handler.scanner.tmp = NULL
    }
    handler.scanner.work = Sane.FALSE
    handler.cancel = Sane.TRUE
    escl_scanner(handler.device, handler.result)
    free(handler.result)
    handler.result = NULL
}

/**
 * \fn void Sane.close(Sane.Handle h)
 * \brief Function that closes the communication with the device represented by "Sane.Handle h".
 *        This function must release the resources that were allocated to the opening of "h".
 */
void
Sane.close(Sane.Handle h)
{
    DBG(10, "escl Sane.close\n")
    if(h != NULL) {
        escl_free_handler(h)
        h = NULL
    }
}

/**
 * \fn const Sane.Option_Descriptor *Sane.get_option_descriptor(Sane.Handle h, Int n)
 * \brief Function that retrieves a descriptor from the n number option of the scanner
 *        represented by "h".
 *        The descriptor remains valid until the machine is closed.
 *
 * \return s.opt + n
 */
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle h, Int n)
{
    DBG(10, "escl Sane.get_option_descriptor\n")
    escl_Sane.t *s = h

    if((unsigned) n >= NUM_OPTIONS || n < 0)
	return(0)
    return(&s.opt[n])
}

/**
 * \fn Sane.Status Sane.control_option(Sane.Handle h, Int n, Sane.Action a, void *v, Int *i)
 * \brief Function that defines the actions to perform for the "n" option of the machine,
 *        represented by "h", if the action is "a".
 *        There are 3 types of possible actions :
 *        --> Sane.ACTION_GET_VALUE: "v" must be used to provide the value of the option.
 *        --> Sane.ACTION_SET_VALUE: The option must take the "v" value.
 *        --> Sane.ACTION_SET_AUTO: The backend or machine must affect the option with an appropriate value.
 *        Moreover, the parameter "i" is used to provide additional information about the state of
 *        "n" option if Sane.ACTION_SET_VALUE has been performed.
 *
 * \return Sane.STATUS_GOOD if everything is OK, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL
 */
Sane.Status
Sane.control_option(Sane.Handle h, Int n, Sane.Action a, void *v, Int *i)
{
    DBG(10, "escl Sane.control_option\n")
    escl_Sane.t *handler = h

    if(i)
	*i = 0
    if(n >= NUM_OPTIONS || n < 0)
	return(Sane.STATUS_INVAL)
    if(a == Sane.ACTION_GET_VALUE) {
	switch(n) {
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_NUM_OPTS:
	case OPT_PREVIEW:
	case OPT_GRAY_PREVIEW:
	case OPT_RESOLUTION:
        case OPT_BRIGHTNESS:
        case OPT_CONTRAST:
        case OPT_SHARPEN:
	    *(Sane.Word *) v = handler.val[n].w
	    break
	case OPT_SCAN_SOURCE:
	case OPT_MODE:
	    strcpy(v, handler.val[n].s)
	    break
	case OPT_MODE_GROUP:
	default:
	    break
	}
	return(Sane.STATUS_GOOD)
    }
    if(a == Sane.ACTION_SET_VALUE) {
	switch(n) {
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_NUM_OPTS:
	case OPT_PREVIEW:
	case OPT_GRAY_PREVIEW:
        case OPT_BRIGHTNESS:
        case OPT_CONTRAST:
        case OPT_SHARPEN:
	    handler.val[n].w = *(Sane.Word *) v
	    if(i)
		*i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
	    break
	case OPT_SCAN_SOURCE:
	    DBG(10, "SET OPT_SCAN_SOURCE(%s)\n", (Sane.String_Const)v)
	    init_options_small((Sane.String_Const)v, handler)
	    if(i)
		*i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
	    break
	case OPT_MODE:
	    if(handler.val[n].s)
		free(handler.val[n].s)
	    handler.val[n].s = strdup(v)
	    if(!handler.val[n].s) {
	      DBG(10, "OPT_MODE allocation failure.\n")
	      return(Sane.STATUS_NO_MEM)
	    }
	    DBG(10, "SET OPT_MODE(%s)\n", (Sane.String_Const)v)

            if(!strcasecmp(handler.val[n].s, Sane.VALUE_SCAN_MODE_GRAY)) {
              handler.scanner.caps[handler.scanner.source].default_color = strdup("Grayscale8")
	    DBG(10, "SET OPT_MODE(Grayscale8)\n")
            }
            else if(!strcasecmp(handler.val[n].s, Sane.VALUE_SCAN_MODE_LINEART)) {
              handler.scanner.caps[handler.scanner.source].default_color =
                 strdup("BlackAndWhite1")
	    DBG(10, "SET OPT_MODE(BlackAndWhite1)\n")
            }
            else {
              handler.scanner.caps[handler.scanner.source].default_color =
                 strdup("RGB24")
	         DBG(10, "SET OPT_MODE(RGB24)\n")
            }
            DBG(10, "Color Mode allocation(%s).\n", handler.scanner.caps[handler.scanner.source].default_color)
	    if(i)
		*i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
            if(handler.scanner.brightness)
                handler.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE
            if(handler.scanner.contrast)
                handler.opt[OPT_CONTRAST].cap   |= Sane.CAP_INACTIVE
            if(handler.scanner.threshold)
                handler.opt[OPT_THRESHOLD].cap  |= Sane.CAP_INACTIVE
            if(handler.scanner.sharpen)
                handler.opt[OPT_SHARPEN].cap  |= Sane.CAP_INACTIVE
            if(!strcasecmp(handler.val[n].s, Sane.VALUE_SCAN_MODE_LINEART)) {
               if(handler.scanner.threshold)
                  handler.opt[OPT_THRESHOLD].cap  &= ~Sane.CAP_INACTIVE
            }
            else {
               if(handler.scanner.brightness)
                  handler.opt[OPT_BRIGHTNESS].cap &= ~Sane.CAP_INACTIVE
               if(handler.scanner.contrast)
                  handler.opt[OPT_CONTRAST].cap   &= ~Sane.CAP_INACTIVE
               if(handler.scanner.sharpen)
                  handler.opt[OPT_SHARPEN].cap   &= ~Sane.CAP_INACTIVE
            }
	    break
	case OPT_RESOLUTION:
            handler.val[n].w = _get_resolution(handler, (Int)(*(Sane.Word *) v))
	    if(i)
		*i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
	    break
	default:
	    break
	}
    }
    return(Sane.STATUS_GOOD)
}

static Bool
_go_next_page(Sane.Status status,
              Sane.Status job)
{
   // Thank"s Alexander Pevzner(pzz@apevzner.com)
   Sane.Status st = Sane.STATUS_NO_DOCS
   switch(status) {
      case Sane.STATUS_GOOD:
      case Sane.STATUS_UNSUPPORTED:
      case Sane.STATUS_DEVICE_BUSY: {
         DBG(10, "eSCL : Test next page\n")
         if(job != Sane.STATUS_GOOD) {
            DBG(10, "eSCL : Go next page\n")
            st = Sane.STATUS_GOOD
         }
         break
      }
      default:
         DBG(10, "eSCL : No next page\n")
   }
   return st
}

/**
 * \fn Sane.Status Sane.start(Sane.Handle h)
 * \brief Function that initiates acquisition of an image from the device represented by handle "h".
 *        This function calls the "escl_newjob" function and the "escl_scan" function.
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
Sane.start(Sane.Handle h)
{
    DBG(10, "escl Sane.start\n")
    Sane.Status status = Sane.STATUS_GOOD
    escl_Sane.t *handler = h
    Int w = 0
    Int he = 0
    Int bps = 0

    if(handler.device == NULL) {
        DBG(1, "Missing handler device.\n")
        return(Sane.STATUS_INVAL)
    }
    handler.cancel = Sane.FALSE
    handler.write_scan_data = Sane.FALSE
    handler.decompress_scan_data = Sane.FALSE
    handler.end_read = Sane.FALSE
    if(handler.scanner.work == Sane.FALSE) {
       Sane.Status st = escl_status(handler.device,
                                    handler.scanner.source,
                                    NULL,
                                    NULL)
       if(st != Sane.STATUS_GOOD)
          return st
       if(handler.val[OPT_PREVIEW].w == Sane.TRUE)
       {
          var i: Int = 0, val = 9999

          if(handler.scanner.caps[handler.scanner.source].default_color)
             free(handler.scanner.caps[handler.scanner.source].default_color)

          if(handler.val[OPT_GRAY_PREVIEW].w == Sane.TRUE ||
	      !strcasecmp(handler.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY))
	     handler.scanner.caps[handler.scanner.source].default_color =
	          strdup("Grayscale8")
          else
	     handler.scanner.caps[handler.scanner.source].default_color =
	          strdup("RGB24")
          if(!handler.scanner.caps[handler.scanner.source].default_color) {
	     DBG(10, "Default Color allocation failure.\n")
	     return(Sane.STATUS_NO_MEM)
	  }
          for(i = 1; i < handler.scanner.caps[handler.scanner.source].SupportedResolutionsSize; i++)
          {
	     if(val > handler.scanner.caps[handler.scanner.source].SupportedResolutions[i])
	         val = handler.scanner.caps[handler.scanner.source].SupportedResolutions[i]
          }
          handler.scanner.caps[handler.scanner.source].default_resolution = val
       }
       else
       {
          handler.scanner.caps[handler.scanner.source].default_resolution =
	     handler.val[OPT_RESOLUTION].w
          if(!handler.scanner.caps[handler.scanner.source].default_color) {
             if(!strcasecmp(handler.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY))
	        handler.scanner.caps[handler.scanner.source].default_color = strdup("Grayscale8")
             else if(!strcasecmp(handler.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART))
	        handler.scanner.caps[handler.scanner.source].default_color =
	            strdup("BlackAndWhite1")
             else
	        handler.scanner.caps[handler.scanner.source].default_color =
	            strdup("RGB24")
          }
       }
       DBG(10, "Before newjob Color Mode allocation(%s).\n", handler.scanner.caps[handler.scanner.source].default_color)
       handler.scanner.caps[handler.scanner.source].height =
            MM_TO_PIXEL(handler.val[OPT_BR_Y].w, 300.0)
       handler.scanner.caps[handler.scanner.source].width =
            MM_TO_PIXEL(handler.val[OPT_BR_X].w, 300.0)
       if(handler.x_range1.min == handler.val[OPT_TL_X].w)
           handler.scanner.caps[handler.scanner.source].pos_x = 0
       else
           handler.scanner.caps[handler.scanner.source].pos_x =
               MM_TO_PIXEL((handler.val[OPT_TL_X].w - handler.x_range1.min),
               300.0)
       if(handler.y_range1.min == handler.val[OPT_TL_X].w)
           handler.scanner.caps[handler.scanner.source].pos_y = 0
       else
           handler.scanner.caps[handler.scanner.source].pos_y =
               MM_TO_PIXEL((handler.val[OPT_TL_Y].w - handler.y_range1.min),
               300.0)
       DBG(10, "Calculate Size Image[%dx%d|%dx%d]\n",
	        handler.scanner.caps[handler.scanner.source].pos_x,
	        handler.scanner.caps[handler.scanner.source].pos_y,
	        handler.scanner.caps[handler.scanner.source].width,
	        handler.scanner.caps[handler.scanner.source].height)
       if(!handler.scanner.caps[handler.scanner.source].default_color) {
          DBG(10, "Default Color allocation failure.\n")
          return(Sane.STATUS_NO_MEM)
       }

       if(handler.scanner.threshold) {
          DBG(10, "Have Thresold\n")
          if(IS_ACTIVE(OPT_THRESHOLD)) {
            DBG(10, "Use Thresold[%d]\n", handler.val[OPT_THRESHOLD].w)
            handler.scanner.val_threshold = handler.val[OPT_THRESHOLD].w
            handler.scanner.use_threshold = 1
         }
         else  {
            DBG(10, "Not use Thresold\n")
            handler.scanner.use_threshold = 0
         }
       }
       else
          DBG(10, "Don"t have Thresold\n")

       if(handler.scanner.sharpen) {
          DBG(10, "Have Sharpen\n")
           if(IS_ACTIVE(OPT_SHARPEN)) {
             DBG(10, "Use Sharpen[%d]\n", handler.val[OPT_SHARPEN].w)
             handler.scanner.val_sharpen = handler.val[OPT_SHARPEN].w
             handler.scanner.use_sharpen = 1
          }
         else  {
            DBG(10, "Not use Sharpen\n")
            handler.scanner.use_sharpen = 0
         }
       }
       else
          DBG(10, "Don"t have Sharpen\n")

       if(handler.scanner.contrast) {
          DBG(10, "Have Contrast\n")
          if(IS_ACTIVE(OPT_CONTRAST)) {
             DBG(10, "Use Contrast[%d]\n", handler.val[OPT_CONTRAST].w)
             handler.scanner.val_contrast = handler.val[OPT_CONTRAST].w
             handler.scanner.use_contrast = 1
          }
          else  {
             DBG(10, "Not use Contrast\n")
             handler.scanner.use_contrast = 0
          }
       }
       else
          DBG(10, "Don"t have Contrast\n")

       if(handler.scanner.brightness) {
          DBG(10, "Have Brightness\n")
          if(IS_ACTIVE(OPT_BRIGHTNESS)) {
             DBG(10, "Use Brightness[%d]\n", handler.val[OPT_BRIGHTNESS].w)
             handler.scanner.val_brightness = handler.val[OPT_BRIGHTNESS].w
             handler.scanner.use_brightness = 1
          }
          else  {
             DBG(10, "Not use Brightness\n")
             handler.scanner.use_brightness = 0
          }
       }
       else
          DBG(10, "Don"t have Brightness\n")

       handler.result = escl_newjob(handler.scanner, handler.device, &status)
       if(status != Sane.STATUS_GOOD)
          return(status)
    }
    else
    {
       Sane.Status job = Sane.STATUS_UNSUPPORTED
       Sane.Status st = escl_status(handler.device,
                                       handler.scanner.source,
                                       handler.result,
                                       &job)
       DBG(10, "eSCL : command returned status %s\n", Sane.strstatus(st))
       if(_go_next_page(st, job) != Sane.STATUS_GOOD)
       {
         handler.scanner.work = Sane.FALSE
         return Sane.STATUS_NO_DOCS
       }
    }
    status = escl_scan(handler.scanner, handler.device, handler.result)
    if(status != Sane.STATUS_GOOD)
       return(status)
    if(!strcmp(handler.scanner.caps[handler.scanner.source].default_format, "image/jpeg"))
    {
       status = get_JPEG_data(handler.scanner, &w, &he, &bps)
    }
    else if(!strcmp(handler.scanner.caps[handler.scanner.source].default_format, "image/png"))
    {
       status = get_PNG_data(handler.scanner, &w, &he, &bps)
    }
    else if(!strcmp(handler.scanner.caps[handler.scanner.source].default_format, "image/tiff"))
    {
       status = get_TIFF_data(handler.scanner, &w, &he, &bps)
    }
    else if(!strcmp(handler.scanner.caps[handler.scanner.source].default_format, "application/pdf"))
    {
       status = get_PDF_data(handler.scanner, &w, &he, &bps)
    }
    else {
       DBG(10, "Unknown image format\n")
       return Sane.STATUS_INVAL
    }

    DBG(10, "2-Size Image(%ld)[%dx%d|%dx%d]\n", handler.scanner.img_size, 0, 0, w, he)

    if(status != Sane.STATUS_GOOD)
       return(status)
    handler.ps.depth = 8
    handler.ps.pixels_per_line = w
    handler.ps.lines = he
    handler.ps.bytesPerLine = w * bps
    handler.ps.last_frame = Sane.TRUE
    handler.ps.format = Sane.FRAME_RGB
    handler.scanner.work = Sane.FALSE
//    DBG(10, "NEXT Frame[%s]\n", (handler.ps.last_frame ? "Non" : "Oui"))
    DBG(10, "Real Size Image[%dx%d|%dx%d]\n", 0, 0, w, he)
    return(status)
}

/**
 * \fn Sane.Status Sane.get_parameters(Sane.Handle h, Sane.Parameters *p)
 * \brief Function that retrieves the device parameters represented by "h" and stores them in "p".
 *        This function is normally used after "Sane.start".
 *        It"s in this function that we choose to assign the default color. (Color or Monochrome)
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
Sane.get_parameters(Sane.Handle h, Sane.Parameters *p)
{
    DBG(10, "escl Sane.get_parameters\n")
    Sane.Status status = Sane.STATUS_GOOD
    escl_Sane.t *handler = h

    if(status != Sane.STATUS_GOOD)
        return(status)
    if(p != NULL) {
        p.depth = 8
        p.last_frame = handler.ps.last_frame
        p.format = Sane.FRAME_RGB
        p.pixels_per_line = handler.ps.pixels_per_line
        p.lines = handler.ps.lines
        p.bytesPerLine = handler.ps.bytesPerLine
    }
    return(status)
}


/**
 * \fn Sane.Status Sane.read(Sane.Handle h, Sane.Byte *buf, Int maxlen, Int *len)
 * \brief Function that"s used to read image data from the device represented by handle "h".
 *        The argument "buf" is a pointer to a memory area that is at least "maxlen" bytes long.
 *        The number of bytes returned is stored in "*len".
 *        --> When the call succeeds, the number of bytes returned can be anywhere in the range from 0 to "maxlen" bytes.
 *
 * \return Sane.STATUS_GOOD(if everything is OK, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
Sane.read(Sane.Handle h, Sane.Byte *buf, Int maxlen, Int *len)
{
    DBG(10, "escl Sane.read\n")
    escl_Sane.t *handler = h
    Sane.Status status = Sane.STATUS_GOOD
    long readbyte

    if(!handler | !buf | !len)
        return(Sane.STATUS_INVAL)

    if(handler.cancel)
        return(Sane.STATUS_CANCELLED)
    if(!handler.write_scan_data)
        handler.write_scan_data = Sane.TRUE
    if(!handler.decompress_scan_data) {
        if(status != Sane.STATUS_GOOD)
            return(status)
        handler.decompress_scan_data = Sane.TRUE
    }
    if(handler.scanner.img_data == NULL)
        return(Sane.STATUS_INVAL)
    if(!handler.end_read) {
        readbyte = min((handler.scanner.img_size - handler.scanner.img_read), maxlen)
        memcpy(buf, handler.scanner.img_data + handler.scanner.img_read, readbyte)
        handler.scanner.img_read = handler.scanner.img_read + readbyte
        *len = readbyte
        if(handler.scanner.img_read == handler.scanner.img_size)
            handler.end_read = Sane.TRUE
        else if(handler.scanner.img_read > handler.scanner.img_size) {
            *len = 0
            handler.end_read = Sane.TRUE
            free(handler.scanner.img_data)
            handler.scanner.img_data = NULL
            return(Sane.STATUS_INVAL)
        }
    }
    else {
        Sane.Status job = Sane.STATUS_UNSUPPORTED
        *len = 0
        free(handler.scanner.img_data)
        handler.scanner.img_data = NULL
        if(handler.scanner.source != PLATEN) {
	      Bool next_page = Sane.FALSE
          Sane.Status st = escl_status(handler.device,
                                       handler.scanner.source,
                                       handler.result,
                                       &job)
          DBG(10, "eSCL : command returned status %s\n", Sane.strstatus(st))
          if(_go_next_page(st, job) == Sane.STATUS_GOOD)
	     next_page = Sane.TRUE
          handler.scanner.work = Sane.TRUE
          handler.ps.last_frame = !next_page
        }
        return Sane.STATUS_EOF
    }
    return(Sane.STATUS_GOOD)
}

Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ h, Int __Sane.unused__ *fd)
{
    return(Sane.STATUS_UNSUPPORTED)
}

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ handle, Bool __Sane.unused__ non_blocking)
{
    return(Sane.STATUS_UNSUPPORTED)
}

/**
 * \fn void escl_curl_url(CURL *handle, const ESCL_Device *device, Sane.String_Const path)
 * \brief Uses the device info in "device" and the path from "path" to construct
 *        a full URL.  Sets this URL and any necessary connection options into
 *        "handle".
 */
void
escl_curl_url(CURL *handle, const ESCL_Device *device, Sane.String_Const path)
{
    Int url_len
    char *url

    url_len = snprintf(NULL, 0, "%s://%s:%d%s",
                       (device.https ? "https" : "http"), device.ip_address,
                       device.port_nb, path)
    url_len++
    url = (char *)malloc(url_len)
    snprintf(url, url_len, "%s://%s:%d%s",
             (device.https ? "https" : "http"), device.ip_address,
             device.port_nb, path)

    DBG( 1, "escl_curl_url: URL: %s\n", url )
    curl_easy_setopt(handle, CURLOPT_URL, url)
    free(url)
    DBG( 1, "Before use hack\n")
    if(device.hack) {
        DBG( 1, "Use hack\n")
        curl_easy_setopt(handle, CURLOPT_HTTPHEADER, device.hack)
    }
    DBG( 1, "After use hack\n")
    if(device.https) {
        DBG( 1, "Ignoring safety certificates, use https\n")
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 0L)
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 0L)
    }
    if(device.unix_socket != NULL) {
        DBG( 1, "Using local socket %s\n", device.unix_socket )
        curl_easy_setopt(handle, CURLOPT_UNIX_SOCKET_PATH,
                         device.unix_socket)
    }
}
