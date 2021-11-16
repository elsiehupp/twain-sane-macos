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

#define DEBUG_DECLARE_ONLY
import Sane.config

import escl

import stdio
import stdlib
import string

import libxml/parser

import Sane.saneopts

struct cap
{
    char *memory
    size_t size
]

/**
 * \fn static Sane.String_Const convert_elements(Sane.String_Const str)
 * \brief Function that converts the 'color modes' of the scanner(color/gray) to be understood by SANE.
 *
 * \return Sane.VALUE_SCAN_MODE_GRAY / Sane.VALUE_SCAN_MODE_COLOR / Sane.VALUE_SCAN_MODE_LINEART; NULL otherwise
 */
static Sane.String_Const
convert_elements(Sane.String_Const str)
{
    if(strcmp(str, "Grayscale8") == 0)
        return(Sane.VALUE_SCAN_MODE_GRAY)
    else if(strcmp(str, "RGB24") == 0)
        return(Sane.VALUE_SCAN_MODE_COLOR)
#if(defined HAVE_POPPLER_GLIB)
    else if(strcmp(str, "BlackAndWhite1") == 0)
        return(Sane.VALUE_SCAN_MODE_LINEART)
#endif
    return(NULL)
}

/**
 * \fn static Sane.String_Const *char_to_array(Sane.String_Const *tab, Int *tabsize, Sane.String_Const mode, Int good_array)
 * \brief Function that creates the character arrays to put inside :
 *        the 'color modes', the 'content types', the 'document formats' and the 'supported intents'.
 *
 * \return board(the allocated array)
 */
static Sane.String_Const *
char_to_array(Sane.String_Const *tab, Int *tabsize, Sane.String_Const mode, Int good_array)
{
    Sane.String_Const *board = NULL
    var i: Int = 0
    Sane.String_Const convert = NULL

    if(mode == NULL)
        return(tab)
    if(good_array != 0) {
        convert = convert_elements(mode)
        if(convert == NULL)
            return(tab)
    }
    else
        convert = mode
    for(i = 0; i < (*tabsize); i++) {
        if(strcmp(tab[i], convert) == 0)
            return(tab)
    }
    (*tabsize)++
    if(*tabsize == 1)
        board = (Sane.String_Const *)malloc(sizeof(Sane.String_Const) * ((*tabsize) + 1))
    else
        board = (Sane.String_Const *)realloc(tab, sizeof(Sane.String_Const) * ((*tabsize) + 1))
    board[*tabsize - 1] = (Sane.String_Const)strdup(convert)
    board[*tabsize] = NULL
    return(board)
}

/**
 * \fn static Int *int_to_array(Int *tab, Int *tabsize, Int cont)
 * \brief Function that creates the integer array to put inside the 'supported resolutions'.
 *
 * \return board(the allocated array)
 */
static Int *
int_to_array(Int *tab, Int *tabsize, Int cont)
{
    Int *board = NULL
    var i: Int = 0

    for(i = 0; i < (*tabsize); i++) {
        if(tab[i] == cont)
            return(tab)
    }
    (*tabsize)++
    if(*tabsize == 1) {
        (*tabsize)++
        board = malloc(sizeof(Int *) * (*tabsize) + 1)
    }
    else
        board = realloc(tab, sizeof(Int *) * (*tabsize) + 1)
    board[0] = *tabsize - 1
    board[*tabsize - 1] = cont
    board[*tabsize] = -1
    return(board)
}

/**
 * \fn static size_t memory_callback_c(void *contents, size_t size, size_t nmemb, void *userp)
 * \brief Callback function that stocks in memory the content of the scanner capabilities.
 *
 * \return realsize(size of the content needed -> the scanner capabilities)
 */
static size_t
memory_callback_c(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb
    struct cap *mem = (struct cap *)userp

    char *str = realloc(mem.memory, mem.size + realsize + 1)
    if(str == NULL) {
        DBG(10, "not enough memory(realloc returned NULL)\n")
        return(0)
    }
    mem.memory = str
    memcpy(&(mem.memory[mem.size]), contents, realsize)
    mem.size = mem.size + realsize
    mem.memory[mem.size] = 0
    return(realsize)
}

/**
 * \fn static Int find_nodes_c(xmlNode *node)
 * \brief Function that browses the xml file and parses it, to find the xml children node.
 *        --> to recover the scanner capabilities.
 *
 * \return 0 if a xml child node is found, 1 otherwise
 */
static Int
find_nodes_c(xmlNode *node)
{
    xmlNode *child = node.children

    while(child) {
        if(child.type == XML_ELEMENT_NODE)
            return(0)
        child = child.next
    }
    return(1)
}

/**
 * \fn static Int find_valor_of_array_variables(xmlNode *node, capabilities_t *scanner)
 * \brief Function that searches in the xml file if a scanner capabilitie stocked
 *        in one of the created array(character/integer array) is found.
 *
 * \return 0
 */
static Int
find_valor_of_array_variables(xmlNode *node, capabilities_t *scanner, Int type)
{
    const char *name = (const char *)node.name
    if(strcmp(name, "ColorMode") == 0) {
		const char *color = (Sane.String_Const)xmlNodeGetContent(node)
		if(type == PLATEN || strcmp(color, "BlackAndWhite1"))
          scanner.caps[type].ColorModes = char_to_array(scanner.caps[type].ColorModes, &scanner.caps[type].ColorModesSize, (Sane.String_Const)xmlNodeGetContent(node), 1)
	}
    else if(strcmp(name, "ContentType") == 0)
        scanner.caps[type].ContentTypes = char_to_array(scanner.caps[type].ContentTypes, &scanner.caps[type].ContentTypesSize, (Sane.String_Const)xmlNodeGetContent(node), 0)
    else if(strcmp(name, "DocumentFormat") == 0)
     {
        var i: Int = 0
        Bool have_jpeg = Sane.FALSE, have_png = Sane.FALSE, have_tiff = Sane.FALSE, have_pdf = Sane.FALSE
        scanner.caps[type].DocumentFormats = char_to_array(scanner.caps[type].DocumentFormats, &scanner.caps[type].DocumentFormatsSize, (Sane.String_Const)xmlNodeGetContent(node), 0)
	scanner.caps[type].have_jpeg = -1
	scanner.caps[type].have_png = -1
	scanner.caps[type].have_tiff = -1
	scanner.caps[type].have_pdf = -1
        for(; i < scanner.caps[type].DocumentFormatsSize; i++)
         {
            if(!strcmp(scanner.caps[type].DocumentFormats[i], "image/jpeg"))
            {
			   have_jpeg = Sane.TRUE
			   scanner.caps[type].have_jpeg = i
            }
#if(defined HAVE_LIBPNG)
            else if(!strcmp(scanner.caps[type].DocumentFormats[i], "image/png"))
            {
               have_png = Sane.TRUE
	       scanner.caps[type].have_png = i
            }
#endif
#if(defined HAVE_TIFFIO_H)
            else if(type == PLATEN && !strcmp(scanner.caps[type].DocumentFormats[i], "image/tiff"))
            {
               have_tiff = Sane.TRUE
	       scanner.caps[type].have_tiff = i
            }
#endif
#if(defined HAVE_POPPLER_GLIB)
            else if(type == PLATEN && !strcmp(scanner.caps[type].DocumentFormats[i], "application/pdf"))
            {
               have_pdf = Sane.TRUE
	       scanner.caps[type].have_pdf = i
            }
#endif
         }
	 if(have_pdf)
             scanner.caps[type].default_format = strdup("application/pdf")
         else if(have_tiff)
             scanner.caps[type].default_format = strdup("image/tiff")
         else if(have_png)
             scanner.caps[type].default_format = strdup("image/png")
         else if(have_jpeg)
             scanner.caps[type].default_format = strdup("image/jpeg")
     }
    else if(strcmp(name, "DocumentFormatExt") == 0)
        scanner.caps[type].format_ext = 1
    else if(strcmp(name, "Intent") == 0)
        scanner.caps[type].SupportedIntents = char_to_array(scanner.caps[type].SupportedIntents, &scanner.caps[type].SupportedIntentsSize, (Sane.String_Const)xmlNodeGetContent(node), 0)
    else if(strcmp(name, "XResolution") == 0)
        scanner.caps[type].SupportedResolutions = int_to_array(scanner.caps[type].SupportedResolutions, &scanner.caps[type].SupportedResolutionsSize, atoi((const char *)xmlNodeGetContent(node)))
    return(0)
}

/**
 * \fn static Int find_value_of_int_variables(xmlNode *node, capabilities_t *scanner)
 * \brief Function that searches in the xml file if a integer scanner capabilitie is found.
 *        The integer scanner capabilities that are interesting are :
 *        MinWidth, MaxWidth, MaxHeight, MinHeight, MaxScanRegions, MaxOpticalXResolution,
 *        RiskyLeftMargin, RiskyRightMargin, RiskyTopMargin, RiskyBottomMargin.
 *
 * \return 0
 */
static Int
find_value_of_int_variables(xmlNode *node, capabilities_t *scanner, Int type)
{
    Int MaxWidth = 0
    Int MaxHeight = 0
    const char *name = (const char *)node.name

    if(strcmp(name, "MinWidth") == 0)
        scanner.caps[type].MinWidth = atoi((const char*)xmlNodeGetContent(node))
    else if(strcmp(name, "MaxWidth") == 0) {
        MaxWidth = atoi((const char*)xmlNodeGetContent(node))
        if(scanner.caps[type].MaxWidth == 0 || MaxWidth < scanner.caps[type].MaxWidth)
            scanner.caps[type].MaxWidth = atoi((const char *)xmlNodeGetContent(node))
    }
    else if(strcmp(name, "MinHeight") == 0)
        scanner.caps[type].MinHeight = atoi((const char*)xmlNodeGetContent(node))
    else if(strcmp(name, "MaxHeight") == 0) {
        MaxHeight = atoi((const char*)xmlNodeGetContent(node))
        if(scanner.caps[type].MaxHeight == 0 || MaxHeight < scanner.caps[type].MaxHeight)
            scanner.caps[type].MaxHeight = atoi((const char *)xmlNodeGetContent(node))
    }
    else if(strcmp(name, "MaxScanRegions") == 0)
        scanner.caps[type].MaxScanRegions = atoi((const char *)xmlNodeGetContent(node))
    else if(strcmp(name, "MaxOpticalXResolution") == 0)
        scanner.caps[type].MaxOpticalXResolution = atoi((const char *)xmlNodeGetContent(node))
    else if(strcmp(name, "RiskyLeftMargin") == 0)
        scanner.caps[type].RiskyLeftMargin = atoi((const char *)xmlNodeGetContent(node))
    else if(strcmp(name, "RiskyRightMargin") == 0)
        scanner.caps[type].RiskyRightMargin = atoi((const char *)xmlNodeGetContent(node))
    else if(strcmp(name, "RiskyTopMargin") == 0)
        scanner.caps[type].RiskyTopMargin = atoi((const char *)xmlNodeGetContent(node))
    else if(strcmp(name, "RiskyBottomMargin") == 0)
        scanner.caps[type].RiskyBottomMargin = atoi((const char *)xmlNodeGetContent(node))
    find_valor_of_array_variables(node, scanner, type)
    return(0)
}

static support_t*
print_support(xmlNode *node)
{
    support_t *sup = (support_t*)calloc(1, sizeof(support_t))
    Int cpt = 0
    Int have_norm = 0
    while(node) {
	if(!strcmp((const char *)node.name, "Min")){
            sup.min = atoi((const char *)xmlNodeGetContent(node))
            cpt++
	}
	else if(!strcmp((const char *)node.name, "Max")) {
            sup.max = atoi((const char *)xmlNodeGetContent(node))
            cpt++
	}
	else if(!strcmp((const char *)node.name, "Normal")) {
            sup.normal = atoi((const char *)xmlNodeGetContent(node))
            cpt++
            have_norm = 1
	}
	else if(!strcmp((const char *)node.name, "Step")) {
            sup.step = atoi((const char *)xmlNodeGetContent(node))
            cpt++
        }
        node = node.next
    }
    if(cpt == 4)
        return sup
    if(cpt == 3 && have_norm == 0) {
	sup.normal = (sup.max / 2 )
        return sup
    }
    free(sup)
    return NULL
}

static Int
find_struct_variables(xmlNode *node, capabilities_t *scanner)
{
    const char *name = (const char *)node.name
    if(strcmp(name, "BrightnessSupport") == 0) {
        scanner.brightness =
           print_support(node.children)
        return 1
    }
    else if(strcmp(name, "ContrastSupport") == 0) {
        scanner.contrast =
           print_support(node.children)
        return 1
    }
    else if(strcmp(name, "SharpenSupport") == 0) {
        scanner.sharpen =
           print_support(node.children)
        return 1
    }
    else if(strcmp(name, "ThresholdSupport") == 0) {
        scanner.threshold =
           print_support(node.children)
        return 1
    }
    return(0)
}

/**
 * \fn static Int find_true_variables(xmlNode *node, capabilities_t *scanner)
 * \brief Function that searches in the xml file if we find a scanner capability stored
 *        in one of the created array(character/integer array),
 *        or, if we find a integer scanner capability.
 *
 * \return 0
 */
static Int
find_true_variables(xmlNode *node, capabilities_t *scanner, Int type)
{
    const char *name = (const char *)node.name
    if(strcmp(name, "MinWidth") == 0 ||
        strcmp(name, "MaxWidth") == 0 ||
        strcmp(name, "MinHeight") == 0 ||
        strcmp(name, "MaxHeight") == 0 ||
        strcmp(name, "MaxScanRegions") == 0 ||
        strcmp(name, "ColorMode") == 0 ||
        strcmp(name, "ContentType") == 0 ||
        strcmp(name, "DocumentFormat") == 0 ||
        strcmp(name, "XResolution") == 0 ||
        strcmp(name, "Intent") == 0 ||
        strcmp(name, "MaxOpticalXResolution") == 0 ||
        strcmp(name, "RiskyLeftMargin") == 0 ||
        strcmp(name, "RiskyRightMargin") == 0 ||
        strcmp(name, "RiskyTopMargin") == 0 ||
        strcmp(name, "RiskyBottomMargin") == 0 ||
        strcmp(name, "DocumentFormatExt") == 0)
            find_value_of_int_variables(node, scanner, type)
    return(0)
}

/**
 * \fn static Int print_xml_c(xmlNode *node, capabilities_t *scanner)
 * \brief Function that browses the xml file, node by node.
 *
 * \return 0
 */
static Int
print_xml_c(xmlNode *node, ESCL_Device *device, capabilities_t *scanner, Int type)
{
    while(node) {
        if(node.type == XML_ELEMENT_NODE) {
            if(find_nodes_c(node) && type != -1)
                find_true_variables(node, scanner, type)
        }
        if(!strcmp((const char *)node.name, "MakeAndModel")){
            device.model_name = strdup((const char *)xmlNodeGetContent(node))
	}
	else if(!strcmp((const char *)node.name, "PlatenInputCaps")) {
           scanner.Sources[PLATEN] = (Sane.String_Const)strdup(Sane.I18N("Flatbed"))
           scanner.SourcesSize++
	   scanner.source = PLATEN
           print_xml_c(node.children, device, scanner, PLATEN)
	   scanner.caps[PLATEN].duplex = 0
	}
	else if(!strcmp((const char *)node.name, "AdfSimplexInputCaps")) {
           scanner.Sources[ADFSIMPLEX] = (Sane.String_Const)strdup(Sane.I18N("ADF"))
           scanner.SourcesSize++
	   if(scanner.source == -1) scanner.source = ADFSIMPLEX
           print_xml_c(node.children, device, scanner, ADFSIMPLEX)
	   scanner.caps[ADFSIMPLEX].duplex = 0
	}
	else if(!strcmp((const char *)node.name, "AdfDuplexInputCaps")) {
           scanner.Sources[ADFDUPLEX] = (Sane.String_Const)strdup(Sane.I18N("ADF Duplex"))
           scanner.SourcesSize++
	   if(scanner.source == -1) scanner.source = ADFDUPLEX
           print_xml_c(node.children, device, scanner, ADFDUPLEX)
	   scanner.caps[ADFDUPLEX].duplex = 1
	}
	else if(find_struct_variables(node, scanner) == 0)
           print_xml_c(node.children, device, scanner, type)
        node = node.next
    }
    return(0)
}

static void
_reduce_color_modes(capabilities_t *scanner)
{
    Int type = 0
    for(type = 0; type < 3; type++) {
         if(scanner.caps[type].ColorModesSize) {
	     if(scanner.caps[type].default_format &&
		 strcmp(scanner.caps[type].default_format, "application/pdf")) {
                 if(scanner.caps[type].ColorModesSize == 3) {
	             free(scanner.caps[type].ColorModes)
		     scanner.caps[type].ColorModes = NULL
	             scanner.caps[type].ColorModesSize = 0
                     scanner.caps[type].ColorModes = char_to_array(scanner.caps[type].ColorModes,
			             &scanner.caps[type].ColorModesSize,
				     (Sane.String_Const)Sane.VALUE_SCAN_MODE_GRAY, 0)
                     scanner.caps[type].ColorModes = char_to_array(scanner.caps[type].ColorModes,
			             &scanner.caps[type].ColorModesSize,
				     (Sane.String_Const)Sane.VALUE_SCAN_MODE_COLOR, 0)
                 }
	     }
         }
    }
}

/**
 * \fn capabilities_t *escl_capabilities(const ESCL_Device *device, Sane.Status *status)
 * \brief Function that finally recovers all the capabilities of the scanner, using curl.
 *        This function is called in the 'Sane.open' function and it's the equivalent of
 *        the following curl command : "curl http(s)://'ip':'port'/eSCL/ScannerCapabilities".
 *
 * \return scanner(the structure that stocks all the capabilities elements)
 */
capabilities_t *
escl_capabilities(ESCL_Device *device, Sane.Status *status)
{
    capabilities_t *scanner = (capabilities_t*)calloc(1, sizeof(capabilities_t))
    CURL *curl_handle = NULL
    struct cap *var = NULL
    xmlDoc *data = NULL
    xmlNode *node = NULL
    var i: Int = 0
    const char *scanner_capabilities = "/eSCL/ScannerCapabilities"

    *status = Sane.STATUS_GOOD
    if(device == NULL)
        *status = Sane.STATUS_NO_MEM
    var = (struct cap *)calloc(1, sizeof(struct cap))
    if(var == NULL)
        *status = Sane.STATUS_NO_MEM
    var.memory = malloc(1)
    var.size = 0
    curl_handle = curl_easy_init()
    escl_curl_url(curl_handle, device, scanner_capabilities)
    curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, memory_callback_c)
    curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, (void *)var)
    CURLcode res = curl_easy_perform(curl_handle)
    if(res != CURLE_OK) {
        DBG( 1, "The scanner didn't respond: %s\n", curl_easy_strerror(res))
        *status = Sane.STATUS_INVAL
        goto clean_data
    }
    DBG( 10, "XML Capabilities[\n%s\n]\n", var.memory)
    data = xmlReadMemory(var.memory, var.size, "file.xml", NULL, 0)
    if(data == NULL) {
        *status = Sane.STATUS_NO_MEM
        goto clean_data
    }
    node = xmlDocGetRootElement(data)
    if(node == NULL) {
        *status = Sane.STATUS_NO_MEM
        goto clean
    }

    scanner.source = 0
    scanner.Sources = (Sane.String_Const *)malloc(sizeof(Sane.String_Const) * 4)
    for(i = 0; i < 4; i++)
       scanner.Sources[i] = NULL
    print_xml_c(node, device, scanner, -1)
    _reduce_color_modes(scanner)
clean:
    xmlFreeDoc(data)
clean_data:
    xmlCleanupParser()
    xmlMemoryDump()
    curl_easy_cleanup(curl_handle)
    if(var)
      free(var.memory)
    free(var)
    return(scanner)
}
