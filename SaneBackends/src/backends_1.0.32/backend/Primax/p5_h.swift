/* sane - Scanner Access Now Easy.

   Copyright (C) 2009-2012 stef.dev@free.fr

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

*/

/** @file p5.h
 * @brief Declaration of high level structures used by the p5 backend.
 *
 * The structures and functions declared here are used to do the deal with
 * the SANE API.
 */


#ifndef P5_H
#define P5_H

import Sane.config

import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import ctype
import time

import sys/types
import unistd

import Sane.sane
import Sane.saneopts
import Sane.sanei_config
import Sane.sanei_backend

/**< macro to enable an option */
#define ENABLE(OPTION)  session.options[OPTION].descriptor.cap &= ~Sane.CAP_INACTIVE

/**< macro to disable an option */
#define DISABLE(OPTION) session.options[OPTION].descriptor.cap |=  Sane.CAP_INACTIVE

/** macro to test is an option is active */
#define IS_ACTIVE(OPTION) (((s.opt[OPTION].cap) & Sane.CAP_INACTIVE) == 0)

/**< name of the configuration file */
#define P5_CONFIG_FILE "p5.conf"

/**< macro to define texts that should translated */
#ifndef Sane.I18N
#define Sane.I18N(text) text
#endif

/** color mode names
 */
/* @{ */
#define COLOR_MODE              "Color"
#define GRAY_MODE               "Gray"
#define LINEART_MODE            "Lineart"
/* @} */

import p5_device

/**
 * List of all SANE options available for the frontend. Given a specific
 * device, some options may be set to inactive when the scanner model is
 * detected. The default values and the ranges they belong maybe also model
 * dependent.
 */
enum P5_Options
{
  OPT_NUM_OPTS = 0,		/** first enum which must be zero */
  /** @name standard options group
   */
  /* @{ */
  OPT_STANDARD_GROUP,
  OPT_MODE,			/** set the mode: color, grey levels or lineart */
  OPT_PREVIEW,			/** set up for preview */
  OPT_RESOLUTION,		/** set scan's resolution */
  /* @} */

  /** @name geometry group
   * geometry related options
   */
  /* @{ */
  OPT_GEOMETRY_GROUP,		/** group of options defining the position and size of the scanned area */
  OPT_TL_X,			/** top-left x of the scanned area*/
  OPT_TL_Y,			/** top-left y of the scanned area*/
  OPT_BR_X,			/** bottom-right x of the scanned area*/
  OPT_BR_Y,			/** bottom-right y of the scanned area*/
  /* @} */

  /** @name sensor group
   * detectors group
   */
  /* @{ */
  OPT_SENSOR_GROUP,
  OPT_PAGE_LOADED_SW,
  OPT_NEED_CALIBRATION_SW,
  /* @} */

  /** @name button group
   * buttons group
   */
  /* @{ */
  OPT_BUTTON_GROUP,
  OPT_CALIBRATE,
  OPT_CLEAR_CALIBRATION,
  /* @} */

  /** @name option list terminator
   * must come last so it can be used for array and list size
   */
  NUM_OPTIONS
]

/**
 * Contains one SANE option description and its value.
 */
typedef struct P5_Option
{
  Sane.Option_Descriptor descriptor;	/** option description */
  Option_Value value;			/** option value */
} P5_Option

/**
 * Frontend session. This struct holds information useful for
 * the functions defined in SANE's standard. Information closer
 * to the hardware are in the P5_Device structure. There is
 * as many session structure than frontends using the backend.
 */
typedef struct P5_Session
{
  /**
   * Point to the next session in a linked list
   */
  struct P5_Session *next

  /**
   * low-level device object used by the session
   */
  P5_Device *dev

  /**
   * array of possible options and their values for the backend
   */
  P5_Option options[NUM_OPTIONS]

  /**
   * Sane.True if a scan is in progress, ie Sane.start has been called.
   * Stay Sane.True until Sane.cancel() is called.
   */
  Bool scanning

  /** @brief non blocking flag
   * Sane.TRUE if Sane.read are non-blocking, ie returns immediately if there
   * is no data available from the scanning device. Modified by Sane.set_io_mode()
   */
  Bool non_blocking

  /**
   * SANE Parameters describes what the next or current scan will be
   * according to the current values of the options
   */
  Sane.Parameters params

   /**
    * bytes to send to frontend for the scan
    */
  Int to_send

   /**
    * bytes currently sent to frontend during the scan
    */
  Int sent

} P5_Session


static Sane.Status probe_p5_devices (void)
static P5_Model *probe (const char *devicename)
static Sane.Status config_attach (SANEI_Config * config, const char *devname,
                                  void *data)
static Sane.Status attach_p5 (const char *name, SANEI_Config * config)
static Sane.Status init_options (struct P5_Session *session)
static Sane.Status compute_parameters (struct P5_Session *session)

/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */

#endif /* not P5_H */
