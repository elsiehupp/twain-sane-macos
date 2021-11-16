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

import Sane.sanei

/**
 * \fn static size_t write_callback(void *str, size_t size, size_t nmemb, void *userp)
 * \brief Callback function that writes the image scanned into the temporary file.
 *
 * \return to_write(the result of the fwrite function)
 */
static size_t
write_callback(void *str, size_t size, size_t nmemb, void *userp)
{
    capabilities_t *scanner = (capabilities_t *)userp
    size_t to_write = fwrite(str, size, nmemb, scanner.tmp)
    scanner.real_read += to_write
    return(to_write)
}

/**
 * \fn Sane.Status escl_scan(capabilities_t *scanner, const ESCL_Device *device, char *result)
 * \brief Function that, after recovering the 'new job', scans the image writed in the
 *        temporary file, using curl.
 *        This function is called in the 'Sane.start' function and it's the equivalent of
 *        the following curl command : "curl -s http(s)://'ip:'port'/eSCL/ScanJobs/'new job'/NextDocument > image.jpg".
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
escl_scan(capabilities_t *scanner, const ESCL_Device *device, char *result)
{
    CURL *curl_handle = NULL
    const char *scan_jobs = "/eSCL/ScanJobs"
    const char *scanner_start = "/NextDocument"
    char scan_cmd[PATH_MAX] = { 0 ]
    Sane.Status status = Sane.STATUS_GOOD

    if(device == NULL)
        return(Sane.STATUS_NO_MEM)
    scanner.real_read = 0
    curl_handle = curl_easy_init()
    if(curl_handle != NULL) {
        snprintf(scan_cmd, sizeof(scan_cmd), "%s%s%s",
                 scan_jobs, result, scanner_start)
        escl_curl_url(curl_handle, device, scan_cmd)
        curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, write_callback)
        if(scanner.tmp)
            fclose(scanner.tmp)
        scanner.tmp = tmpfile()
        if(scanner.tmp != NULL) {
            curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, scanner)
            CURLcode res = curl_easy_perform(curl_handle)
            if(res != CURLE_OK) {
                DBG( 1, "Unable to scan: %s\n", curl_easy_strerror(res))
                fclose(scanner.tmp)
                scanner.tmp = NULL
                status = Sane.STATUS_INVAL
		goto cleanup
            }
            fseek(scanner.tmp, 0, SEEK_SET)
        }
        else
            status = Sane.STATUS_NO_MEM
cleanup:
        curl_easy_cleanup(curl_handle)
    }
    DBG(10, "eSCL scan : [%s]\treal read(%ld)\n", Sane.strstatus(status), scanner.real_read)
    if(scanner.real_read == 0)
    {
       fclose(scanner.tmp)
       scanner.tmp = NULL
       return Sane.STATUS_NO_DOCS
    }
    return(status)
}
