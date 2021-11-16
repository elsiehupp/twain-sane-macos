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

struct idle
{
    char *memory
    size_t size
]

/**
 * \fn static size_t memory_callback_s(void *contents, size_t size, size_t nmemb, void *userp)
 * \brief Callback function that stocks in memory the content of the scanner status.
 *
 * \return realsize(size of the content needed -> the scanner status)
 */
static size_t
memory_callback_s(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb
    struct idle *mem = (struct idle *)userp

    char *str = realloc(mem.memory, mem.size + realsize + 1)
    if(str == NULL) {
        DBG(1, "not enough memory(realloc returned NULL)\n")
        return(0)
    }
    mem.memory = str
    memcpy(&(mem.memory[mem.size]), contents, realsize)
    mem.size = mem.size + realsize
    mem.memory[mem.size] = 0
    return(realsize)
}

/**
 * \fn static Int find_nodes_s(xmlNode *node)
 * \brief Function that browses the xml file and parses it, to find the xml children node.
 *        --> to recover the scanner status.
 *
 * \return 0 if a xml child node is found, 1 otherwise
 */
static Int
find_nodes_s(xmlNode *node)
{
    xmlNode *child = node.children

    while(child) {
        if(child.type == XML_ELEMENT_NODE)
            return(0)
        child = child.next
    }
    return(1)
}

static void
print_xml_job_status(xmlNode *node,
                     Sane.Status *job,
                     Int *image)
{
    while(node) {
        if(node.type == XML_ELEMENT_NODE) {
            if(find_nodes_s(node)) {
                if(strcmp((const char *)node.name, "JobState") == 0) {
                    const char *state = (const char *)xmlNodeGetContent(node)
                    if(!strcmp(state, "Processing")) {
                        *job = Sane.STATUS_DEVICE_BUSY
                        DBG(10, "jobId Processing Sane.STATUS_DEVICE_BUSY\n")
                    }
                    else if(!strcmp(state, "Completed")) {
                        *job = Sane.STATUS_GOOD
                        DBG(10, "jobId Completed Sane.STATUS_GOOD\n")
                    }
                    else if(strcmp((const char *)node.name, "ImagesToTransfer") == 0) {
	                const char *state = (const char *)xmlNodeGetContent(node)
	                *image = atoi(state)
	            }
                }
            }
        }
        print_xml_job_status(node.children, job, image)
        node = node.next
    }
}

static void
print_xml_platen_and_adf_status(xmlNode *node,
                                Sane.Status *platen,
                                Sane.Status *adf,
                                const char* jobId,
                                Sane.Status *job,
                                Int *image)
{
    while(node) {
        if(node.type == XML_ELEMENT_NODE) {
            if(find_nodes_s(node)) {
                if(strcmp((const char *)node.name, "State") == 0) {
	            DBG(10, "State\t")
                    const char *state = (const char *)xmlNodeGetContent(node)
                    if(!strcmp(state, "Idle")) {
			DBG(10, "Idle Sane.STATUS_GOOD\n")
                        *platen = Sane.STATUS_GOOD
                    } else if(!strcmp(state, "Processing")) {
			DBG(10, "Processing Sane.STATUS_DEVICE_BUSY\n")
                        *platen = Sane.STATUS_DEVICE_BUSY
                    } else {
			DBG(10, "%s Sane.STATUS_UNSUPPORTED\n", state)
                        *platen = Sane.STATUS_UNSUPPORTED
                    }
                }
                // Thank's Alexander Pevzner(pzz@apevzner.com)
                else if(adf && strcmp((const char *)node.name, "AdfState") == 0) {
                    const char *state = (const char *)xmlNodeGetContent(node)
                    if(!strcmp(state, "ScannerAdfLoaded")){
			DBG(10, "ScannerAdfLoaded Sane.STATUS_GOOD\n")
                        *adf = Sane.STATUS_GOOD
                    } else if(!strcmp(state, "ScannerAdfJam")) {
                        DBG(10, "ScannerAdfJam Sane.STATUS_JAMMED\n")
                        *adf = Sane.STATUS_JAMMED
                    } else if(!strcmp(state, "ScannerAdfDoorOpen")) {
                        DBG(10, "ScannerAdfDoorOpen Sane.STATUS_COVER_OPEN\n")
                        *adf = Sane.STATUS_COVER_OPEN
                    } else if(!strcmp(state, "ScannerAdfProcessing")) {
                        /* Kyocera version */
                        DBG(10, "ScannerAdfProcessing Sane.STATUS_NO_DOC\n")
                        *adf = Sane.STATUS_NO_DOCS
                    } else if(!strcmp(state, "ScannerAdfEmpty")) {
                        DBG(10, "ScannerAdfEmpty Sane.STATUS_NO_DOCS\n")
                        /* Cannon TR4500, EPSON XP-7100 */
                        *adf = Sane.STATUS_NO_DOCS
                    } else {
                        DBG(10, "%s Sane.STATUS_NO_DOCS\n", state)
                        *adf = Sane.STATUS_UNSUPPORTED
                    }
                }
                else if(jobId && job && strcmp((const char *)node.name, "JobUri") == 0) {
                    if(strstr((const char *)xmlNodeGetContent(node), jobId)) {
						print_xml_job_status(node, job, image)
					}
                }
            }
        }
        print_xml_platen_and_adf_status(node.children,
                                        platen,
                                        adf,
                                        jobId,
                                        job,
                                        image)
        node = node.next
    }
}

/**
 * \fn Sane.Status escl_status(const ESCL_Device *device)
 * \brief Function that finally recovers the scanner status('Idle', or not), using curl.
 *        This function is called in the 'Sane.open' function and it's the equivalent of
 *        the following curl command : "curl http(s)://'ip':'port'/eSCL/ScannerStatus".
 *
 * \return status(if everything is OK, status = Sane.STATUS_GOOD, otherwise, Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
escl_status(const ESCL_Device *device,
            Int source,
            const char* jobId,
            Sane.Status *job)
{
    Sane.Status status = Sane.STATUS_DEVICE_BUSY
    Sane.Status platen= Sane.STATUS_DEVICE_BUSY
    Sane.Status adf= Sane.STATUS_DEVICE_BUSY
    CURL *curl_handle = NULL
    struct idle *var = NULL
    xmlDoc *data = NULL
    xmlNode *node = NULL
    const char *scanner_status = "/eSCL/ScannerStatus"
    Int image = -1
    Int pass = 0
reload:

    if(device == NULL)
        return(Sane.STATUS_NO_MEM)
    status = Sane.STATUS_DEVICE_BUSY
    platen= Sane.STATUS_DEVICE_BUSY
    adf= Sane.STATUS_DEVICE_BUSY
    var = (struct idle*)calloc(1, sizeof(struct idle))
    if(var == NULL)
        return(Sane.STATUS_NO_MEM)
    var.memory = malloc(1)
    var.size = 0
    curl_handle = curl_easy_init()

    escl_curl_url(curl_handle, device, scanner_status)
    curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, memory_callback_s)
    curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, (void *)var)
    CURLcode res = curl_easy_perform(curl_handle)
    if(res != CURLE_OK) {
        DBG( 1, "The scanner didn't respond: %s\n", curl_easy_strerror(res))
        status = Sane.STATUS_INVAL
        goto clean_data
    }
    DBG( 10, "eSCL : Status : %s.\n", var.memory)
    data = xmlReadMemory(var.memory, var.size, "file.xml", NULL, 0)
    if(data == NULL) {
        status = Sane.STATUS_NO_MEM
        goto clean_data
    }
    node = xmlDocGetRootElement(data)
    if(node == NULL) {
        status = Sane.STATUS_NO_MEM
        goto clean
    }
    /* Decode Job status */
    // Thank's Alexander Pevzner(pzz@apevzner.com)
    print_xml_platen_and_adf_status(node, &platen, &adf, jobId, job, &image)
    if(platen != Sane.STATUS_GOOD &&
        platen != Sane.STATUS_UNSUPPORTED) {
        status = platen
    } else if(source == PLATEN) {
        status = platen
    } else {
        status = adf
    }
    DBG(10, "STATUS : %s\n", Sane.strstatus(status))
clean:
    xmlFreeDoc(data)
clean_data:
    xmlCleanupParser()
    xmlMemoryDump()
    curl_easy_cleanup(curl_handle)
    free(var.memory)
    free(var)
    if(pass == 0 &&
        source != PLATEN &&
        image == 0 &&
        (status == Sane.STATUS_GOOD ||
         status == Sane.STATUS_UNSUPPORTED ||
         status == Sane.STATUS_DEVICE_BUSY)) {
       pass = 1
       goto reload
    }
    return(status)
}
