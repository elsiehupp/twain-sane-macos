/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Touboul Nathane
   Copyright (C) 2019 Thierry HUCHARD <thierry@ordissimo.com>

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your
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
import unistd

#ifdef PATH_MAX
# undef PATH_MAX
#endif

#define PATH_MAX 4096

struct downloading
{
    char *memory
    size_t size
]

static const char settings[] =
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"                        \
    "<scan:ScanSettings xmlns:pwg=\"http://www.pwg.org/schemas/2010/12/sm\" xmlns:scan=\"http://schemas.hp.com/imaging/escl/2011/05/03\">" \
    "   <pwg:Version>2.0</pwg:Version>" \
    "   <pwg:ScanRegions>" \
    "      <pwg:ScanRegion>" \
    "          <pwg:ContentRegionUnits>escl:ThreeHundredthsOfInches</pwg:ContentRegionUnits>" \
    "          <pwg:Height>%d</pwg:Height>" \
    "          <pwg:Width>%d</pwg:Width>" \
    "          <pwg:XOffset>%d</pwg:XOffset>" \
    "          <pwg:YOffset>%d</pwg:YOffset>" \
    "      </pwg:ScanRegion>" \
    "   </pwg:ScanRegions>" \
    "   <pwg:DocumentFormat>%s</pwg:DocumentFormat>" \
    "%s" \
    "   <scan:ColorMode>%s</scan:ColorMode>" \
    "   <scan:XResolution>%d</scan:XResolution>" \
    "   <scan:YResolution>%d</scan:YResolution>" \
    "   <pwg:InputSource>%s</pwg:InputSource>" \
    "   <scan:InputSource>%s</scan:InputSource>" \
    "%s" \
    "%s" \
    "</scan:ScanSettings>"

/**
 * \fn static size_t download_callback(void *str, size_t size, size_t nmemb, void *userp)
 * \brief Callback function that stocks in memory the content of the 'job'. Example below :
 *        "Trying 192.168.14.150...
 *         TCP_NODELAY set
 *         Connected to 192.168.14.150 (192.168.14.150) port 80
 *         POST /eSCL/ScanJobs HTTP/1.1
 *         Host: 192.168.14.150
 *         User-Agent: curl/7.55.1
 *         Accept: /
 *         Content-Length: 605
 *         Content-Type: application/x-www-form-urlencoded
 *         upload completely sent off: 605 out of 605 bytes
 *         < HTTP/1.1 201 Created
 *         < MIME-Version: 1.0
 *         < Location: http://192.168.14.150/eSCL/ScanJobs/22b54fd0-027b-1000-9bd0-f4a99726e2fa
 *         < Content-Length: 0
 *         < Connection: close
 *         <
 *         Closing connection 0"
 *
 * \return realsize (size of the content needed -> the 'job')
 */
static size_t
download_callback(void *str, size_t size, size_t nmemb, void *userp)
{
    struct downloading *download = (struct downloading *)userp
    size_t realsize = size * nmemb
    char *content = realloc(download.memory, download.size + realsize + 1)

    if (content == NULL) {
        DBG( 1, "Not enough memory (realloc returned NULL)\n")
        return (0)
    }
    download.memory = content
    memcpy(&(download.memory[download.size]), str, realsize)
    download.size = download.size + realsize
    download.memory[download.size] = 0
    return (realsize)
}

static char*
add_support_option(char *key, Int val)
{
   Int size = (strlen(key) * 3) +  10
   char *tmp = (char*)calloc(1, size)
   snprintf (tmp, size, "<scan:%s>%d</scan:%s>\n", key, val, key)
   return tmp
}

/**
 * \fn char *escl_newjob (capabilities_t *scanner, const ESCL_Device *device, Sane.Status *status)
 * \brief Function that, using curl, uploads the data (composed by the scanner capabilities) to the
 *        server to download the 'job' and recover the 'new job' (char *result), in LOCATION.
 *        This function is called in the 'Sane.start' function and it's the equivalent of the
 *        following curl command : "curl -v POST -d cap.xml http(s)://'ip':'port'/eSCL/ScanJobs".
 *
 * \return result (the 'new job', situated in LOCATION)
 */
char *
escl_newjob (capabilities_t *scanner, const ESCL_Device *device, Sane.Status *status)
{
    CURL *curl_handle = NULL
    Int off_x = 0, off_y = 0
    struct downloading *upload = NULL
    struct downloading *download = NULL
    const char *scan_jobs = "/eSCL/ScanJobs"
    char cap_data[PATH_MAX] = { 0 ]
    char *location = NULL
    char *result = NULL
    char *temporary = NULL
    char *f_ext = ""
    char *format_ext = NULL
    char duplex_mode[1024] = { 0 ]
    Int wakup_count = 0

    *status = Sane.STATUS_GOOD
    if (device == NULL || scanner == NULL) {
        *status = Sane.STATUS_NO_MEM
        DBG( 1, "Create NewJob : the name or the scan are invalid.\n")
        return (NULL)
    }
    upload = (struct downloading *)calloc(1, sizeof(struct downloading))
    if (upload == NULL) {
        *status = Sane.STATUS_NO_MEM
        DBG( 1, "Create NewJob : memory allocation failure\n")
        return (NULL)
    }
    download = (struct downloading *)calloc(1, sizeof(struct downloading))
    if (download == NULL) {
        free(upload)
        DBG( 1, "Create NewJob : memory allocation failure\n")
        *status = Sane.STATUS_NO_MEM
        return (NULL)
    }
    if (scanner.caps[scanner.source].default_format)
        free(scanner.caps[scanner.source].default_format)
    scanner.caps[scanner.source].default_format = NULL
    Int have_png = scanner.caps[scanner.source].have_png
    Int have_jpeg = scanner.caps[scanner.source].have_jpeg
    Int have_tiff = scanner.caps[scanner.source].have_tiff
    Int have_pdf = scanner.caps[scanner.source].have_pdf

    if ((scanner.source == PLATEN && have_pdf == -1) ||
        (scanner.source > PLATEN)) {
	    if (have_tiff != -1) {
		    scanner.caps[scanner.source].default_format =
			    strdup(scanner.caps[scanner.source].DocumentFormats[have_tiff])
	    }
	    else if (have_png != -1) {
		    scanner.caps[scanner.source].default_format =
			    strdup(scanner.caps[scanner.source].DocumentFormats[have_png])
	    }
	    else if (have_jpeg != -1) {
		    scanner.caps[scanner.source].default_format =
			    strdup(scanner.caps[scanner.source].DocumentFormats[have_jpeg])
	    }
    }
    else {
	    scanner.caps[scanner.source].default_format =
		    strdup(scanner.caps[scanner.source].DocumentFormats[have_pdf])
    }
    if (scanner.caps[scanner.source].format_ext == 1)
    {
        char f_ext_tmp[1024]
        snprintf(f_ext_tmp, sizeof(f_ext_tmp),
			"   <scan:DocumentFormatExt>%s</scan:DocumentFormatExt>",
    			scanner.caps[scanner.source].default_format)
        format_ext = f_ext_tmp
    }
    else
      format_ext = f_ext
    if(scanner.source > PLATEN && scanner.Sources[ADFDUPLEX]) {
       snprintf(duplex_mode, sizeof(duplex_mode),
		       "   <scan:Duplex>%s</scan:Duplex>",
		       scanner.source == ADFDUPLEX ? "true" : "false")
    }
    DBG( 1, "Create NewJob : %s\n", scanner.caps[scanner.source].default_format)
    if (scanner.caps[scanner.source].pos_x > scanner.caps[scanner.source].width)
         off_x = (scanner.caps[scanner.source].pos_x > scanner.caps[scanner.source].width) / 2
    if (scanner.caps[scanner.source].pos_y > scanner.caps[scanner.source].height)
         off_y = (scanner.caps[scanner.source].pos_y > scanner.caps[scanner.source].height) / 2

    char support_options[1024]
    memset(support_options, 0, 1024)
    char *source = (scanner.source == PLATEN ? "Platen" : "Feeder")
    if (scanner.use_threshold)
    {
       char *tmp = add_support_option("ThresholdSupport", scanner.val_threshold)
       if (support_options[0])
          strcat(support_options, tmp)
       else
          strcpy(support_options, tmp)
       free(tmp)
    }
    if (scanner.use_sharpen)
    {
       char *tmp = add_support_option("SharpenSupport", scanner.val_sharpen)
       if (support_options[0])
          strcat(support_options, tmp)
       else
          strcpy(support_options, tmp)
       free(tmp)
    }
    if (scanner.use_contrast)
    {
       char *tmp = add_support_option("ContrastSupport", scanner.val_contrast)
       if (support_options[0])
          strcat(support_options, tmp)
       else
          strcpy(support_options, tmp)
       free(tmp)
    }
    if (scanner.use_brightness)
    {
       char *tmp = add_support_option("BrightnessSupport", scanner.val_brightness)
       if (support_options[0])
          strcat(support_options, tmp)
       else
          strcpy(support_options, tmp)
       free(tmp)
    }
    snprintf(cap_data, sizeof(cap_data), settings,
    		scanner.caps[scanner.source].height,
    		scanner.caps[scanner.source].width,
    		off_x,
    		off_y,
    		scanner.caps[scanner.source].default_format,
    		format_ext,
    		scanner.caps[scanner.source].default_color,
    		scanner.caps[scanner.source].default_resolution,
    		scanner.caps[scanner.source].default_resolution,
    		source,
    		source,
    		duplex_mode[0] == 0 ? " " : duplex_mode,
                support_options[0] == 0 ? " " : support_options)
    upload.memory = strdup(cap_data)
    upload.size = strlen(cap_data)
wake_up_device:
    DBG( 1, "Create NewJob : %s\n", cap_data)
    download.memory = malloc(1)
    download.size = 0
    curl_handle = curl_easy_init()
    if (curl_handle != NULL) {
        escl_curl_url(curl_handle, device, scan_jobs)
        curl_easy_setopt(curl_handle, CURLOPT_POST, 1L)
        curl_easy_setopt(curl_handle, CURLOPT_POSTFIELDS, (const char*)upload.memory)
        curl_easy_setopt(curl_handle, CURLOPT_POSTFIELDSIZE, upload.size)
        curl_easy_setopt(curl_handle, CURLOPT_HEADERFUNCTION, download_callback)
        curl_easy_setopt(curl_handle, CURLOPT_HEADERDATA, (void *)download)
        CURLcode res = curl_easy_perform(curl_handle)
        if (res != CURLE_OK) {
            DBG( 1, "Create NewJob : the scanner responded incorrectly: %s\n", curl_easy_strerror(res))
            *status = Sane.STATUS_INVAL
        }
        else {
            if (download.memory != NULL) {
                char *tmp_location = strstr(download.memory, "Location:")
                if (tmp_location) {
                    temporary = strchr(tmp_location, '\r')
                    if (temporary == NULL)
                        temporary = strchr(tmp_location, '\n')
                    if (temporary != NULL) {
                       *temporary = '\0'
                       location = strrchr(tmp_location,'/')
                       if (location) {
                          result = strdup(location)
                          DBG( 1, "Create NewJob : %s\n", result)
                          *temporary = '\n'
                          wakup_count = 0
                       }
                    }
                    if (result == NULL) {
                        DBG( 1, "Error : Create NewJob, no location: %s\n", download.memory)
                        *status = Sane.STATUS_INVAL
                    }
                    free(download.memory)
                    download.memory = NULL
                }
                else {
                    DBG( 1, "Create NewJob : The creation of the failed job: %s\n", download.memory)
                    // If "409 Conflict" appear it means that there is no paper in feeder
                    if (strstr(download.memory, "409 Conflict") != NULL)
                        *status = Sane.STATUS_NO_DOCS
                    // If "503 Service Unavailable" appear, it means that device is busy (scanning in progress)
                    else if (strstr(download.memory, "503 Service Unavailable") != NULL) {
                        wakup_count += 1
                        *status = Sane.STATUS_DEVICE_BUSY
		    }
                    else
                        *status = Sane.STATUS_INVAL
                }
            }
            else {
                *status = Sane.STATUS_NO_MEM
                DBG( 1, "Create NewJob : The creation of the failed job\n")
                return (NULL)
            }
        }
        curl_easy_cleanup(curl_handle)
    }
    if (wakup_count > 0 && wakup_count < 4) {
        free(download.memory)
        download.memory = NULL
        download.size = 0
        *status = Sane.STATUS_GOOD
        usleep(250)
        goto wake_up_device
    }
    if (upload != NULL) {
        free(upload.memory)
        free(upload)
    }
    if (download != NULL)
        free(download)
    return (result)
}
