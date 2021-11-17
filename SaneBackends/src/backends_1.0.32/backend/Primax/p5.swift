/* sane - Scanner Access Now Easy.

   Copyright(C) 2009-12 Stéphane Voltz <stef.dev@free.fr>

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
*/
/*   --------------------------------------------------------------------------

*/

/* ------------------------------------------------------------------------- */
/*! \mainpage Primax PagePartner Parallel Port scanner Index Page
 *
 * \section intro_sec Introduction
 *
 * This backend provides support for the Prima PagePartner sheet fed parallel
 * port scanner.
 *
 * \section Sane.api SANE API
 *
 * \subsection Sane.flow sane flow
   SANE FLOW
   - Sane.init() : initialize backend, attach scanners.
   	- Sane.get_devices() : query list of scanner devices, backend must
                           	probe for new devices.
   	- Sane.open() : open a particular scanner device, adding a handle
   		     	to the opened device
		- Sane.set_io_mode() : set blocking mode
		- Sane.get_select_fd() : get scanner fd
		- Sane.get_option_descriptor() : get option information
		- Sane.control_option() : change option values
		- Sane.start() : start image acquisition
			- Sane.get_parameters() : returns actual scan parameters for the ongoing scan
			- Sane.read() : read image data
		- Sane.cancel() : cancel operation, end scan
   	- Sane.close() : close opened scanner device, freeing scanner handle
   - Sane.exit() : terminate use of backend, freeing all resources for attached
   		   devices when last frontend quits
 */

/**
 * the build number allow to know which version of the backend is running.
 */
#define BUILD 2301

import p5

/**
 * Import directly the low level part needed to
 * operate scanner. The alternative is to prefix all public functions
 * with sanei_p5_ ,and have all the functions prototyped in
 * p5_device.h .
 */
import p5_device.c"

/**
 * number of time the backend has been loaded by Sane.init.
 */
static Int init_count = 0

/**
 * NULL terminated list of opened frontend sessions. Sessions are
 * inserted here on Sane.open() and removed on Sane.close().
 */
static P5_Session *sessions = NULL

/**
 * NULL terminated list of detected physical devices.
 * The same device may be opened several time by different sessions.
 * Entry are inserted here by the attach() function.
 * */
static P5_Device *devices = NULL

/**
 * NULL terminated list of devices needed by Sane.get_devices(), since
 * the result returned must stay consistent until next call.
 */
static const Sane.Device **devlist = 0

/**
 * list of possible color modes
 */
static Sane.String_Const mode_list[] = {
  Sane.I18N(COLOR_MODE),
  Sane.I18N(GRAY_MODE),
  /* Sane.I18N(LINEART_MODE), not supported yet */
  0
]

static Sane.Range x_range = {
  Sane.FIX(0.0),		/* minimum */
  Sane.FIX(216.0),		/* maximum */
  Sane.FIX(0.0)		/* quantization */
]

static Sane.Range y_range = {
  Sane.FIX(0.0),		/* minimum */
  Sane.FIX(299.0),		/* maximum */
  Sane.FIX(0.0)		/* no quantization */
]

/**
 * finds the maximum string length in a string array.
 */
static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}

/**> placeholders for decoded configuration values */
static P5_Config p5cfg


/* ------------------------------------------------------------------------- */

/*
 * SANE Interface
 */


/**
 * Called by SANE initially.
 *
 * From the SANE spec:
 * This function must be called before any other SANE function can be
 * called. The behavior of a SANE backend is undefined if this
 * function is not called first. The version code of the backend is
 * returned in the value pointed to by version_code. If that pointer
 * is NULL, no version code is returned. Argument authorize is either
 * a pointer to a function that is invoked when the backend requires
 * authentication for a specific resource or NULL if the frontend does
 * not support authentication.
 */
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  Sane.Status status

  authorize = authorize;	/* get rid of compiler warning */

  init_count++

  /* init backend debug */
  DBG_INIT()
  DBG(DBG_info, "SANE P5 backend version %d.%d-%d\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD)
  DBG(DBG_proc, "Sane.init: start\n")
  DBG(DBG_trace, "Sane.init: init_count=%d\n", init_count)

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  /* cold-plugging case : probe for already plugged devices */
  status = probe_p5_devices()

  DBG(DBG_proc, "Sane.init: exit\n")
  return status
}


/**
 * Called by SANE to find out about supported devices.
 *
 * From the SANE spec:
 * This function can be used to query the list of devices that are
 * available. If the function executes successfully, it stores a
 * pointer to a NULL terminated array of pointers to Sane.Device
 * structures in *device_list. The returned list is guaranteed to
 * remain unchanged and valid until(a) another call to this function
 * is performed or(b) a call to Sane.exit() is performed. This
 * function can be called repeatedly to detect when new devices become
 * available. If argument local_only is true, only local devices are
 * returned(devices directly attached to the machine that SANE is
 * running on). If it is false, the device list includes all remote
 * devices that are accessible to the SANE library.
 *
 * SANE does not require that this function is called before a
 * Sane.open() call is performed. A device name may be specified
 * explicitly by a user which would make it unnecessary and
 * undesirable to call this function first.
 * @param device_list pointer where to store the device list
 * @param local_only Sane.TRUE if only local devices are required.
 * @return Sane.STATUS_GOOD when successful
 */
Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Int dev_num, devnr
  struct P5_Device *device
  Sane.Device *Sane.device
  var i: Int

  DBG(DBG_proc, "Sane.get_devices: start: local_only = %s\n",
       local_only == Sane.TRUE ? "true" : "false")

  /* free existing devlist first */
  if(devlist)
    {
      for(i = 0; devlist[i] != NULL; i++)
	free((void *)devlist[i])
      free(devlist)
      devlist = NULL
    }

  /**
   * Since Sane.get_devices() may be called repeatedly to detect new devices,
   * the device detection must be run at each call. We are handling
   * hot-plugging : we probe for devices plugged since Sane.init() was called.
   */
  probe_p5_devices()

  /* if no devices detected, just return an empty list */
  if(devices == NULL)
    {
      devlist = malloc(sizeof(devlist[0]))
      if(!devlist)
	return Sane.STATUS_NO_MEM
      devlist[0] = NULL
      *device_list = devlist
      DBG(DBG_proc, "Sane.get_devices: exit with no device\n")
      return Sane.STATUS_GOOD
    }

  /* count physical devices */
  devnr = 1
  device = devices
  while(device.next)
    {
      devnr++
      device = device.next
    }

  /* allocate room for the list, plus 1 for the NULL terminator */
  devlist = malloc((devnr + 1) * sizeof(devlist[0]))
  if(!devlist)
    return Sane.STATUS_NO_MEM

  *device_list = devlist

  dev_num = 0
  device = devices

  /* we build a list of Sane.Device from the list of attached devices */
  for(i = 0; i < devnr; i++)
    {
      /* add device according to local only flag */
      if((local_only == Sane.TRUE && device.local == Sane.TRUE)
	  || local_only == Sane.FALSE)
	{
	  /* allocate memory to add the device */
	  Sane.device = malloc(sizeof(*Sane.device))
	  if(!Sane.device)
	    {
	      return Sane.STATUS_NO_MEM
	    }

	  /* copy data */
	  Sane.device.name = device.name
	  Sane.device.vendor = device.model.vendor
	  Sane.device.model = device.model.product
	  Sane.device.type = device.model.type
	  devlist[dev_num] = Sane.device

	  /* increment device counter */
	  dev_num++
	}

      /* go to next detected device */
      device = device.next
    }
  devlist[dev_num] = 0

  *device_list = devlist

  DBG(DBG_proc, "Sane.get_devices: exit\n")

  return Sane.STATUS_GOOD
}


/**
 * Called to establish connection with the session. This function will
 * also establish meaningful defaults and initialize the options.
 *
 * From the SANE spec:
 * This function is used to establish a connection to a particular
 * device. The name of the device to be opened is passed in argument
 * name. If the call completes successfully, a handle for the device
 * is returned in *h. As a special case, specifying a zero-length
 * string as the device requests opening the first available device
 * (if there is such a device). Another special case is to only give
 * the name of the backend as the device name, in this case the first
 * available device will also be used.
 * @param name name of the device to open
 * @param handle opaque pointer where to store the pointer of
 *        the opened P5_Session
 * @return Sane.STATUS_GOOD on success
 */
Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * handle)
{
  struct P5_Session *session = NULL
  struct P5_Device *device = NULL

  DBG(DBG_proc, "Sane.open: start(devicename=%s)\n", name)

  /* check there is at least a device */
  if(devices == NULL)
    {
      DBG(DBG_proc, "Sane.open: exit, no device to open!\n")
      return Sane.STATUS_INVAL
    }

  if(name[0] == 0 || strncmp(name, "p5", strlen("p5")) == 0)
    {
      DBG(DBG_info,
	   "Sane.open: no specific device requested, using default\n")
      if(devices)
	{
	  device = devices
	  DBG(DBG_info, "Sane.open: device %s used as default device\n",
	       device.name)
	}
    }
  else
    {
      DBG(DBG_info, "Sane.open: device %s requested\n", name)
      /* walk the device list until we find a matching name */
      device = devices
      while(device && strcmp(device.name, name) != 0)
	{
	  DBG(DBG_trace, "Sane.open: device %s doesn"t match\n",
	       device.name)
	  device = device.next
	}
    }

  /* check whether we have found a match or reach the end of the device list */
  if(!device)
    {
      DBG(DBG_info, "Sane.open: no device found\n")
      return Sane.STATUS_INVAL
    }

  /* now we have a device, duplicate it and return it in handle */
  DBG(DBG_info, "Sane.open: device %s found\n", name)

  /* device initialization */
  if(device.initialized == Sane.FALSE)
    {
      /**
       * call to hardware initialization function here.
       */
      device.fd = open_pp(device.name)
      if(device.fd < 0)
	{
	  DBG(DBG_error, "Sane.open: failed to open "%s" device!\n",
	       device.name)
	  return Sane.STATUS_INVAL
	}

      /* now try to connect to scanner */
      if(connect(device.fd) != Sane.TRUE)
	{
	  DBG(DBG_error, "Sane.open: failed to connect!\n")
	  close_pp(device.fd)
	  return Sane.STATUS_INVAL
	}

      /* load calibration data */
      restore_calibration(device)

      /* device link is OK now */
      device.initialized = Sane.TRUE
    }
  device.buffer = NULL
  device.gain = NULL
  device.offset = NULL

  /* prepare handle to return */
  session = (P5_Session *) malloc(sizeof(P5_Session))
  if(session == NULL)
    {
      DBG(DBG_proc, "Sane.open: exit OOM\n")
      return Sane.STATUS_NO_MEM
    }

  /* initialize session */
  session.dev = device
  session.scanning = Sane.FALSE
  session.non_blocking = Sane.FALSE

  /* initialize SANE options for this session */
  init_options(session)

  /* add the handle to the linked list of sessions */
  session.next = sessions
  sessions = session

  /* store result */
  *handle = session

  /* exit success */
  DBG(DBG_proc, "Sane.open: exit\n")
  return Sane.STATUS_GOOD
}


/**
 * Set non blocking mode. In this mode, read return immediately when
 * no data is available within Sane.read(), instead of polling the scanner.
 */
Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  P5_Session *session = (P5_Session *) handle

  DBG(DBG_proc, "Sane.set_io_mode: start\n")
  if(session.scanning != Sane.TRUE)
    {
      DBG(DBG_error, "Sane.set_io_mode: called out of a scan\n")
      return Sane.STATUS_INVAL
    }
  session.non_blocking = non_blocking
  DBG(DBG_info, "Sane.set_io_mode: I/O mode set to %sblocking.\n",
       non_blocking ? "non " : " ")
  DBG(DBG_proc, "Sane.set_io_mode: exit\n")
  return Sane.STATUS_GOOD
}


/**
 * An advanced method we don"t support but have to define. At SANE API
 * level this function is meant to provide a file descriptor on which the
 * frontend can do select()/poll() to wait for data.
 */
Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fdp)
{
  /* make compiler happy ... */
  handle = handle
  fdp = fdp

  DBG(DBG_proc, "Sane.get_select_fd: start\n")
  DBG(DBG_warn, "Sane.get_select_fd: unsupported ...\n")
  DBG(DBG_proc, "Sane.get_select_fd: exit\n")
  return Sane.STATUS_UNSUPPORTED
}


/**
 * Returns the options we know.
 *
 * From the SANE spec:
 * This function is used to access option descriptors. The function
 * returns the option descriptor for option number n of the device
 * represented by handle h. Option number 0 is guaranteed to be a
 * valid option. Its value is an integer that specifies the number of
 * options that are available for device handle h(the count includes
 * option 0). If n is not a valid option index, the function returns
 * NULL. The returned option descriptor is guaranteed to remain valid
 * (and at the returned address) until the device is closed.
 */
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  struct P5_Session *session = handle

  DBG(DBG_proc, "Sane.get_option_descriptor: start\n")

  if((unsigned) option >= NUM_OPTIONS)
    return NULL

  DBG(DBG_info, "Sane.get_option_descriptor: \"%s\"\n",
       session.options[option].descriptor.name)

  DBG(DBG_proc, "Sane.get_option_descriptor: exit\n")
  return &(session.options[option].descriptor)
}

/**
 * sets automatic value for an option , called by Sane.control_option after
 * all checks have been done */
static Sane.Status
set_automatic_value(P5_Session * s, Int option, Int * myinfo)
{
  Sane.Status status = Sane.STATUS_GOOD
  Int i, min
  Sane.Word *dpi_list

  switch(option)
    {
    case OPT_TL_X:
      s.options[OPT_TL_X].value.w = x_range.min
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    case OPT_TL_Y:
      s.options[OPT_TL_Y].value.w = y_range.min
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    case OPT_BR_X:
      s.options[OPT_BR_X].value.w = x_range.max
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    case OPT_BR_Y:
      s.options[OPT_BR_Y].value.w = y_range.max
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    case OPT_RESOLUTION:
      /* we set up to the lowest available dpi value */
      dpi_list =
	(Sane.Word *) s.options[OPT_RESOLUTION].descriptor.constraint.
	word_list
      min = 65536
      for(i = 1; i < dpi_list[0]; i++)
	{
	  if(dpi_list[i] < min)
	    min = dpi_list[i]
	}
      s.options[OPT_RESOLUTION].value.w = min
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    case OPT_PREVIEW:
      s.options[OPT_PREVIEW].value.w = Sane.FALSE
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    case OPT_MODE:
      if(s.options[OPT_MODE].value.s)
	free(s.options[OPT_MODE].value.s)
      s.options[OPT_MODE].value.s = strdup(mode_list[0])
      *myinfo |= Sane.INFO_RELOAD_OPTIONS
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break
    default:
      DBG(DBG_warn, "set_automatic_value: can"t set unknown option %d\n",
	   option)
    }

  return status
}

/**
 * sets an option , called by Sane.control_option after all
 * checks have been done */
static Sane.Status
set_option_value(P5_Session * s, Int option, void *val, Int * myinfo)
{
  Sane.Status status = Sane.STATUS_GOOD
  Sane.Word tmpw

  switch(option)
    {
    case OPT_TL_X:
    case OPT_BR_X:
    case OPT_TL_Y:
    case OPT_BR_Y:
      s.options[option].value.w = *(Sane.Word *) val
      /* we ensure geometry is coherent */
      /* this happens when user drags TL corner right or below the BR point */
      if(s.options[OPT_BR_Y].value.w < s.options[OPT_TL_Y].value.w)
	{
	  tmpw = s.options[OPT_BR_Y].value.w
	  s.options[OPT_BR_Y].value.w = s.options[OPT_TL_Y].value.w
	  s.options[OPT_TL_Y].value.w = tmpw
	}
      if(s.options[OPT_BR_X].value.w < s.options[OPT_TL_X].value.w)
	{
	  tmpw = s.options[OPT_BR_X].value.w
	  s.options[OPT_BR_X].value.w = s.options[OPT_TL_X].value.w
	  s.options[OPT_TL_X].value.w = tmpw
	}

      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break

    case OPT_RESOLUTION:
    case OPT_PREVIEW:
      s.options[option].value.w = *(Sane.Word *) val
      *myinfo |= Sane.INFO_RELOAD_PARAMS
      break

    case OPT_MODE:
      if(s.options[option].value.s)
	free(s.options[option].value.s)
      s.options[option].value.s = strdup(val)
      *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
      break

    case OPT_CALIBRATE:
      status = sheetfed_calibration(s.dev)
      *myinfo |= Sane.INFO_RELOAD_OPTIONS
      break

    case OPT_CLEAR_CALIBRATION:
      cleanup_calibration(s.dev)
      *myinfo |= Sane.INFO_RELOAD_OPTIONS
      break

    default:
      DBG(DBG_warn, "set_option_value: can"t set unknown option %d\n",
	   option)
    }
  return status
}

/**
 * gets an option , called by Sane.control_option after all checks
 * have been done */
static Sane.Status
get_option_value(P5_Session * s, Int option, void *val)
{
  Sane.Status status

  switch(option)
    {
      /* word or word equivalent options: */
    case OPT_NUM_OPTS:
    case OPT_RESOLUTION:
    case OPT_PREVIEW:
    case OPT_TL_X:
    case OPT_TL_Y:
    case OPT_BR_X:
    case OPT_BR_Y:
      *(Sane.Word *) val = s.options[option].value.w
      break

      /* string options: */
    case OPT_MODE:
      strcpy(val, s.options[option].value.s)
      break

      /* sensor options */
    case OPT_PAGE_LOADED_SW:
      status = test_document(s.dev.fd)
      if(status == Sane.STATUS_GOOD)
	s.options[option].value.b = Sane.TRUE
      else
	s.options[option].value.b = Sane.FALSE
      *(Bool *) val = s.options[option].value.b
      break

    case OPT_NEED_CALIBRATION_SW:
      *(Bool *) val = !s.dev.calibrated
      break


      /* unhandled options */
    default:
      DBG(DBG_warn, "get_option_value: can"t get unknown option %d\n",
	   option)
    }

  return Sane.STATUS_GOOD
}

/**
 * Gets or sets an option value.
 *
 * From the SANE spec:
 * This function is used to set or inquire the current value of option
 * number n of the device represented by handle h. The manner in which
 * the option is controlled is specified by parameter action. The
 * possible values of this parameter are described in more detail
 * below.  The value of the option is passed through argument val. It
 * is a pointer to the memory that holds the option value. The memory
 * area pointed to by v must be big enough to hold the entire option
 * value(determined by member size in the corresponding option
 * descriptor).
 *
 * The only exception to this rule is that when setting the value of a
 * string option, the string pointed to by argument v may be shorter
 * since the backend will stop reading the option value upon
 * encountering the first NUL terminator in the string. If argument i
 * is not NULL, the value of *i will be set to provide details on how
 * well the request has been met.
 * action is Sane.ACTION_GET_VALUE, Sane.ACTION_SET_VALUE or Sane.ACTION_SET_AUTO
 */
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  P5_Session *s = handle
  Sane.Status status
  Sane.Word cap
  Int myinfo = 0

  DBG(DBG_io2,
       "Sane.control_option: start: action = %s, option = %s(%d)\n",
       (action == Sane.ACTION_GET_VALUE) ? "get" : (action ==
						    Sane.ACTION_SET_VALUE) ?
       "set" : (action == Sane.ACTION_SET_AUTO) ? "set_auto" : "unknown",
       s.options[option].descriptor.name, option)

  if(info)
    *info = 0

  /* do checks before trying to apply action */

  if(s.scanning)
    {
      DBG(DBG_warn, "Sane.control_option: don"t call this function while "
	   "scanning(option = %s(%d))\n",
	   s.options[option].descriptor.name, option)
      return Sane.STATUS_DEVICE_BUSY
    }

  /* option must be within existing range */
  if(option >= NUM_OPTIONS || option < 0)
    {
      DBG(DBG_warn,
	   "Sane.control_option: option %d >= NUM_OPTIONS || option < 0\n",
	   option)
      return Sane.STATUS_INVAL
    }

  /* don"t access an inactive option */
  cap = s.options[option].descriptor.cap
  if(!Sane.OPTION_IS_ACTIVE(cap))
    {
      DBG(DBG_warn, "Sane.control_option: option %d is inactive\n", option)
      return Sane.STATUS_INVAL
    }

  /* now checks have been done, apply action */
  switch(action)
    {
    case Sane.ACTION_GET_VALUE:
      status = get_option_value(s, option, val)
      break

    case Sane.ACTION_SET_VALUE:
      if(!Sane.OPTION_IS_SETTABLE(cap))
	{
	  DBG(DBG_warn, "Sane.control_option: option %d is not settable\n",
	       option)
	  return Sane.STATUS_INVAL
	}

      status =
	sanei_constrain_value(&s.options[option].descriptor, val, &myinfo)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_warn,
	       "Sane.control_option: sanei_constrain_value returned %s\n",
	       Sane.strstatus(status))
	  return status
	}

      /* return immediately if no change */
      if(s.options[option].descriptor.type == Sane.TYPE_INT
	  && *(Sane.Word *) val == s.options[option].value.w)
	{
	  status = Sane.STATUS_GOOD
	}
      else
	{			/* apply change */
	  status = set_option_value(s, option, val, &myinfo)
	}
      break

    case Sane.ACTION_SET_AUTO:
      /* sets automatic values */
      if(!(cap & Sane.CAP_AUTOMATIC))
	{
	  DBG(DBG_warn,
	       "Sane.control_option: option %d is not autosettable\n",
	       option)
	  return Sane.STATUS_INVAL
	}

      status = set_automatic_value(s, option, &myinfo)
      break

    default:
      DBG(DBG_error, "Sane.control_option: invalid action %d\n", action)
      status = Sane.STATUS_INVAL
      break
    }

  if(info)
    *info = myinfo

  DBG(DBG_io2, "Sane.control_option: exit\n")
  return status
}

/**
 * Called by SANE when a page acquisition operation is to be started.
 * @param handle opaque handle to a frontend session
 * @return Sane.STATUS_GOOD on success, Sane.STATUS_BUSY if the device is
 * in use by another session or Sane.STATUS_WARMING_UP if the device is
 * warming up. In this case the fronted as to call Sane.start again until
 * warming up is done. Any other values returned are error status.
 */
Sane.Status
Sane.start(Sane.Handle handle)
{
  struct P5_Session *session = handle
  status: Int = Sane.STATUS_GOOD
  P5_Device *dev = session.dev

  DBG(DBG_proc, "Sane.start: start\n")

  /* if already scanning, tell we"re busy */
  if(session.scanning == Sane.TRUE)
    {
      DBG(DBG_info, "Sane.start: device is already scanning\n")
      return Sane.STATUS_DEVICE_BUSY
    }

  /* check that the device has been initialized */
  if(dev.initialized == Sane.FALSE)
    {
      DBG(DBG_error, "Sane.start: device is not initialized\n")
      return Sane.STATUS_INVAL
    }

  /* check if there is a document */
  status = test_document(dev.fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error, "Sane.start: device is already scanning\n")
      return status
    }

  /* we compute all the scan parameters so that */
  /* we will be able to set up the registers correctly */
  compute_parameters(session)

  /* move to scan area if needed */
  if(dev.ystart > 0)
    {
      status = move(dev)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_error, "Sane.start: failed to move to scan area\n")
	  return Sane.STATUS_INVAL
	}
    }

  /* send scan command */
  status = start_scan(dev, dev.mode, dev.ydpi, dev.xstart, dev.pixels)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error, "Sane.start: failed to start scan\n")
      return Sane.STATUS_INVAL
    }

  /* allocates work buffer */
  if(dev.buffer != NULL)
    {
      free(dev.buffer)
    }

  dev.position = 0
  dev.top = 0
  /* compute amount of lines needed for lds correction */
  dev.bottom = dev.bytesPerLine * 2 * dev.lds
  /* computes buffer size, 66 color lines plus eventual amount needed for lds */
  dev.size = dev.pixels * 3 * 66 + dev.bottom
  dev.buffer = (uint8_t *) malloc(dev.size)
  if(dev.buffer == NULL)
    {
      DBG(DBG_error, "Sane.start: failed to allocate %lu bytes\n", (unsigned long)dev.size)
      Sane.cancel(handle)
      return Sane.STATUS_NO_MEM
    }

  /* return now the scan has been initiated */
  session.scanning = Sane.TRUE
  session.sent = 0

  DBG(DBG_io, "Sane.start: to_send=%d\n", session.to_send)
  DBG(DBG_io, "Sane.start: size=%lu\n", (unsigned long)dev.size)
  DBG(DBG_io, "Sane.start: top=%lu\n", (unsigned long)dev.top)
  DBG(DBG_io, "Sane.start: bottom=%lu\n", (unsigned long)dev.bottom)
  DBG(DBG_io, "Sane.start: position=%lu\n", (unsigned long)dev.position)

  DBG(DBG_proc, "Sane.start: exit\n")
  return status
}

/** @brief compute scan parameters
 * This function computes two set of parameters. The one for the SANE"s standard
 * and the other for the hardware. Among these parameters are the bit depth, total
 * number of lines, total number of columns, extra line to read for data reordering...
 * @param session fronted session to compute final scan parameters
 * @return Sane.STATUS_GOOD on success
 */
static Sane.Status
compute_parameters(P5_Session * session)
{
  P5_Device *dev = session.dev
  Int dpi;			/* dpi for scan */
  String mode
  Sane.Status status = Sane.STATUS_GOOD

  Int tl_x, tl_y, br_x, br_y

  mode = session.options[OPT_MODE].value.s
  dpi = session.options[OPT_RESOLUTION].value.w

  /* scan coordinates */
  tl_x = Sane.UNFIX(session.options[OPT_TL_X].value.w)
  tl_y = Sane.UNFIX(session.options[OPT_TL_Y].value.w)
  br_x = Sane.UNFIX(session.options[OPT_BR_X].value.w)
  br_y = Sane.UNFIX(session.options[OPT_BR_Y].value.w)

  /* only single pass scanning supported */
  session.params.last_frame = Sane.TRUE

  /* gray modes */
  if(strcmp(mode, GRAY_MODE) == 0)
    {
      session.params.format = Sane.FRAME_GRAY
      dev.mode = MODE_GRAY
      dev.lds = 0
    }
  else if(strcmp(mode, LINEART_MODE) == 0)
    {
      session.params.format = Sane.FRAME_GRAY
      dev.mode = MODE_LINEART
      dev.lds = 0
    }
  else
    {
      /* Color */
      session.params.format = Sane.FRAME_RGB
      dev.mode = MODE_COLOR
      dev.lds = (dev.model.lds * dpi) / dev.model.max_ydpi
    }

  /* SANE level values */
  session.params.lines = ((br_y - tl_y) * dpi) / MM_PER_INCH
  if(session.params.lines == 0)
    session.params.lines = 1
  session.params.pixels_per_line = ((br_x - tl_x) * dpi) / MM_PER_INCH
  if(session.params.pixels_per_line == 0)
    session.params.pixels_per_line = 1

  DBG(DBG_data, "compute_parameters: pixels_per_line   =%d\n",
       session.params.pixels_per_line)

  if(strcmp(mode, LINEART_MODE) == 0)
    {
      session.params.depth = 1
      /* in lineart, having pixels multiple of 8 avoids a costly test */
      /* at each bit to see we must go to the next byte               */
      /* TODO : implement this requirement in Sane.control_option */
      session.params.pixels_per_line =
	((session.params.pixels_per_line + 7) / 8) * 8
    }
  else
    session.params.depth = 8

  /* width needs to be even */
  if(session.params.pixels_per_line & 1)
    session.params.pixels_per_line++

  /* Hardware settings : they can differ from the ones at SANE level */
  /* for instance the effective DPI used by a sensor may be higher   */
  /* than the one needed for the SANE scan parameters                */
  dev.lines = session.params.lines
  dev.pixels = session.params.pixels_per_line

  /* motor and sensor DPI */
  dev.xdpi = dpi
  dev.ydpi = dpi

  /* handle bounds of motor"s dpi range */
  if(dev.ydpi > dev.model.max_ydpi)
    {
      dev.ydpi = dev.model.max_ydpi
      dev.lines = (dev.lines * dev.model.max_ydpi) / dpi
      if(dev.lines == 0)
	dev.lines = 1

      /* round number of lines */
      session.params.lines =
	(session.params.lines / dev.lines) * dev.lines
      if(session.params.lines == 0)
	session.params.lines = 1
    }
  if(dev.ydpi < dev.model.min_ydpi)
    {
      dev.ydpi = dev.model.min_ydpi
      dev.lines = (dev.lines * dev.model.min_ydpi) / dpi
    }

  /* hardware values */
  dev.xstart =
    ((Sane.UNFIX(dev.model.x_offset) + tl_x) * dpi) / MM_PER_INCH
  dev.ystart =
    ((Sane.UNFIX(dev.model.y_offset) + tl_y) * dev.ydpi) / MM_PER_INCH

  /* take lds correction into account when moving to scan area */
  if(dev.ystart > 2 * dev.lds)
    dev.ystart -= 2 * dev.lds


  /* computes bytes per line */
  session.params.bytesPerLine = session.params.pixels_per_line
  dev.bytesPerLine = dev.pixels
  if(session.params.format == Sane.FRAME_RGB)
    {
      dev.bytesPerLine *= 3
    }

  /* in lineart mode we adjust bytesPerLine needed by frontend */
  /* we do that here because we needed sent/to_send to be as if  */
  /* there was no lineart                                        */
  if(session.params.depth == 1)
    {
      session.params.bytesPerLine =
	(session.params.bytesPerLine + 7) / 8
    }

  session.params.bytesPerLine = dev.bytesPerLine
  session.to_send = session.params.bytesPerLine * session.params.lines
  session.params.bytesPerLine = dev.bytesPerLine

  DBG(DBG_data, "compute_parameters: bytesPerLine    =%d\n",
       session.params.bytesPerLine)
  DBG(DBG_data, "compute_parameters: depth             =%d\n",
       session.params.depth)
  DBG(DBG_data, "compute_parameters: lines             =%d\n",
       session.params.lines)
  DBG(DBG_data, "compute_parameters: image size        =%d\n",
       session.to_send)

  DBG(DBG_data, "compute_parameters: xstart            =%d\n", dev.xstart)
  DBG(DBG_data, "compute_parameters: ystart            =%d\n", dev.ystart)
  DBG(DBG_data, "compute_parameters: dev lines         =%d\n", dev.lines)
  DBG(DBG_data, "compute_parameters: dev bytes per line=%d\n",
       dev.bytesPerLine)
  DBG(DBG_data, "compute_parameters: dev pixels        =%d\n", dev.pixels)
  DBG(DBG_data, "compute_parameters: lds               =%d\n", dev.lds)

  return status
}


/**
 * Called by SANE to retrieve information about the type of data
 * that the current scan will return.
 *
 * From the SANE spec:
 * This function is used to obtain the current scan parameters. The
 * returned parameters are guaranteed to be accurate between the time
 * a scan has been started(Sane.start() has been called) and the
 * completion of that request. Outside of that window, the returned
 * values are best-effort estimates of what the parameters will be
 * when Sane.start() gets invoked.
 *
 * Calling this function before a scan has actually started allows,
 * for example, to get an estimate of how big the scanned image will
 * be. The parameters passed to this function are the handle of the
 * device for which the parameters should be obtained and a pointer
 * to a parameter structure.
 */
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Sane.Status status
  struct P5_Session *session = (struct P5_Session *) handle

  DBG(DBG_proc, "Sane.get_parameters: start\n")

  /* call parameters computing function */
  status = compute_parameters(session)
  if(status == Sane.STATUS_GOOD && params)
    *params = session.params

  DBG(DBG_proc, "Sane.get_parameters: exit\n")
  return status
}


/**
 * Called by SANE to read data.
 *
 * From the SANE spec:
 * This function is used to read image data from the device
 * represented by handle h.  Argument buf is a pointer to a memory
 * area that is at least maxlen bytes long.  The number of bytes
 * returned is stored in *len. A backend must set this to zero when
 * the call fails(i.e., when a status other than Sane.STATUS_GOOD is
 * returned).
 *
 * When the call succeeds, the number of bytes returned can be
 * anywhere in the range from 0 to maxlen bytes.
 *
 * Returned data is read from working buffer.
 */
Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf,
	   Int max_len, Int * len)
{
  struct P5_Session *session = (struct P5_Session *) handle
  struct P5_Device *dev = session.dev
  Sane.Status status = Sane.STATUS_GOOD
  Int count
  Int size, lines
  Bool x2
  Int i

  DBG(DBG_proc, "Sane.read: start\n")
  DBG(DBG_io, "Sane.read: up to %d bytes required by frontend\n", max_len)

  /* some sanity checks first to protect from would be buggy frontends */
  if(!session)
    {
      DBG(DBG_error, "Sane.read: handle is null!\n")
      return Sane.STATUS_INVAL
    }

  if(!buf)
    {
      DBG(DBG_error, "Sane.read: buf is null!\n")
      return Sane.STATUS_INVAL
    }

  if(!len)
    {
      DBG(DBG_error, "Sane.read: len is null!\n")
      return Sane.STATUS_INVAL
    }

  /* no data read yet */
  *len = 0

  /* check if session is scanning */
  if(!session.scanning)
    {
      DBG(DBG_warn,
	   "Sane.read: scan was cancelled, is over or has not been initiated yet\n")
      return Sane.STATUS_CANCELLED
    }

  /* check for EOF, must be done before any physical read */
  if(session.sent >= session.to_send)
    {
      DBG(DBG_io, "Sane.read: end of scan reached\n")
      return Sane.STATUS_EOF
    }

  /* if working buffer is empty, we do a physical data read */
  if(dev.top <= dev.bottom)
    {
      DBG(DBG_io, "Sane.read: physical data read\n")
      /* check is there is data available. In case of non-blocking mode we return
       * as soon it is detected there is no data yet. Reads must by done line by
       * line, so we read only when count is bigger than bytes per line
       * */
      count = available_bytes(dev.fd)
      DBG(DBG_io, "Sane.read: count=%d bytes\n", count)
      if(count < dev.bytesPerLine && session.non_blocking == Sane.TRUE)
	{
	  DBG(DBG_io, "Sane.read: scanner hasn"t enough data available\n")
	  DBG(DBG_proc, "Sane.read: exit\n")
	  return Sane.STATUS_GOOD
	}

      /* now we can wait for data here */
      while(count < dev.bytesPerLine)
	{
	  /* test if document left the feeder, so we have to terminate the scan */
	  status = test_document(dev.fd)
	  if(status == Sane.STATUS_NO_DOCS)
	    {
	      session.to_send = session.sent
	      return Sane.STATUS_EOF
	    }

	  /* don"t call scanner too often */
	  usleep(10000)
	  count = available_bytes(dev.fd)
	}

      /** compute size of physical data to read
       * on first read, position will be 0, while it will be "bottom"
       * for the subsequent reads.
       * We try to read a complete buffer */
      size = dev.size - dev.position

      if(session.to_send - session.sent < size)
	{
	  /* not enough data left, so read remainder of scan */
	  size = session.to_send - session.sent
	}

      /* 600 dpi is 300x600 physical, and 400 is 200x400 */
      if(dev.ydpi > dev.model.max_xdpi)
	{
	  x2 = Sane.TRUE
	}
      else
	{
	  x2 = Sane.FALSE
	}
      lines = read_line(dev,
			 dev.buffer + dev.position,
			 dev.bytesPerLine,
			 size / dev.bytesPerLine,
			 Sane.TRUE, x2, dev.mode, dev.calibrated)

      /* handle document end detection TODO try to recover the partial
       * buffer already read before EOD */
      if(lines == -1)
	{
	  DBG(DBG_io, "Sane.read: error reading line\n")
	  return Sane.STATUS_IO_ERROR
	}

      /* gather lines until we have more than needed for lds */
      dev.position += lines * dev.bytesPerLine
      dev.top = dev.position
      if(dev.position > dev.bottom)
	{
	  dev.position = dev.bottom
	}
      DBG(DBG_io, "Sane.read: size    =%lu\n", (unsigned long)dev.size)
      DBG(DBG_io, "Sane.read: bottom  =%lu\n", (unsigned long)dev.bottom)
      DBG(DBG_io, "Sane.read: position=%lu\n", (unsigned long)dev.position)
      DBG(DBG_io, "Sane.read: top     =%lu\n", (unsigned long)dev.top)
    }				/* end of physical data reading */

  /* logical data reading */
  /* check if there data available in working buffer */
  if(dev.position < dev.top && dev.position >= dev.bottom)
    {
      DBG(DBG_io, "Sane.read: logical data read\n")
      /* we have more data in internal buffer than asked ,
       * then send only max data */
      size = dev.top - dev.position
      if(max_len < size)
	{
	  *len = max_len
	}
      else
	/* if we don"t have enough, send all what we have */
	{
	  *len = dev.top - dev.position
	}

      /* data copy */
      if(dev.lds == 0)
	{
	  memcpy(buf, dev.buffer + dev.position, *len)
	}
      else
	{
	  /* compute count of bytes for lds */
	  count = dev.lds * dev.bytesPerLine

	  /* adjust for lds as we copy data to frontend */
	  for(i = 0; i < *len; i++)
	    {
	      switch((dev.position + i) % 3)
		{
		  /* red */
		case 0:
		  buf[i] = dev.buffer[dev.position + i - 2 * count]
		  break
		  /* green */
		case 1:
		  buf[i] = dev.buffer[dev.position + i - count]
		  break
		  /* blue */
		default:
		  buf[i] = dev.buffer[dev.position + i]
		  break
		}
	    }
	}
      dev.position += *len

      /* update byte accounting */
      session.sent += *len
      DBG(DBG_io, "Sane.read: sent %d bytes from buffer to frontend\n",
	   *len)
      return Sane.STATUS_GOOD
    }

  /* check if we exhausted working buffer */
  if(dev.position >= dev.top && dev.position >= dev.bottom)
    {
      /* copy extra lines needed for lds in next buffer */
      if(dev.position > dev.bottom && dev.lds > 0)
	{
	  memcpy(dev.buffer,
		  dev.buffer + dev.position - dev.bottom, dev.bottom)
	}

      /* restart buffer */
      dev.position = dev.bottom
      dev.top = 0
    }

  DBG(DBG_io, "Sane.read: size    =%lu\n", (unsigned long)dev.size)
  DBG(DBG_io, "Sane.read: bottom  =%lu\n", (unsigned long)dev.bottom)
  DBG(DBG_io, "Sane.read: position=%lu\n", (unsigned long)dev.position)
  DBG(DBG_io, "Sane.read: top     =%lu\n", (unsigned long)dev.top)

  DBG(DBG_proc, "Sane.read: exit\n")
  return status
}


/**
 * Cancels a scan.
 *
 * From the SANE spec:
 * This function is used to immediately or as quickly as possible
 * cancel the currently pending operation of the device represented by
 * handle h.  This function can be called at any time(as long as
 * handle h is a valid handle) but usually affects long-running
 * operations only(such as image is acquisition). It is safe to call
 * this function asynchronously(e.g., from within a signal handler).
 * It is important to note that completion of this operation does not
 * imply that the currently pending operation has been cancelled. It
 * only guarantees that cancellation has been initiated. Cancellation
 * completes only when the cancelled call returns(typically with a
 * status value of Sane.STATUS_CANCELLED).  Since the SANE API does
 * not require any other operations to be re-entrant, this implies
 * that a frontend must not call any other operation until the
 * cancelled operation has returned.
 */
void
Sane.cancel(Sane.Handle handle)
{
  P5_Session *session = handle

  DBG(DBG_proc, "Sane.cancel: start\n")

  /* if scanning, abort and park head */
  if(session.scanning == Sane.TRUE)
    {
      /* detects if we are called after the scan is finished,
       * or if the scan is aborted */
      if(session.sent < session.to_send)
	{
	  DBG(DBG_info, "Sane.cancel: aborting scan.\n")
	  /* device hasn"t finished scan, we are aborting it
	   * and we may have to do something specific for it here */
	}
      else
	{
	  DBG(DBG_info, "Sane.cancel: cleaning up after scan.\n")
	}
      session.scanning = Sane.FALSE
    }
  eject(session.dev.fd)

  DBG(DBG_proc, "Sane.cancel: exit\n")
}


/**
 * Ends use of the session.
 *
 * From the SANE spec:
 * This function terminates the association between the device handle
 * passed in argument h and the device it represents. If the device is
 * presently active, a call to Sane.cancel() is performed first. After
 * this function returns, handle h must not be used anymore.
 *
 * Handle resources are free"d before disposing the handle. But devices
 * resources must not be mdofied, since it could be used or reused until
 * Sane.exit() is called.
 */
void
Sane.close(Sane.Handle handle)
{
  P5_Session *prev, *session

  DBG(DBG_proc, "Sane.close: start\n")

  /* remove handle from list of open handles: */
  prev = NULL
  for(session = sessions; session; session = session.next)
    {
      if(session == handle)
	break
      prev = session
    }
  if(!session)
    {
      DBG(DBG_error0, "close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  /* cancel any active scan */
  if(session.scanning == Sane.TRUE)
    {
      Sane.cancel(handle)
    }

  if(prev)
    prev.next = session.next
  else
    sessions = session.next

  /* close low level device */
  if(session.dev.initialized == Sane.TRUE)
    {
      if(session.dev.calibrated == Sane.TRUE)
	{
	  save_calibration(session.dev)
	}
      disconnect(session.dev.fd)
      close_pp(session.dev.fd)
      session.dev.fd = -1
      session.dev.initialized = Sane.FALSE

      /* free device data */
      if(session.dev.buffer != NULL)
	{
	  free(session.dev.buffer)
	}
      if(session.dev.buffer != NULL)
	{
	  free(session.dev.gain)
	  free(session.dev.offset)
	}
      if(session.dev.calibrated == Sane.TRUE)
	{
	  cleanup_calibration(session.dev)
	}
    }

  /* free per session data */
  free(session.options[OPT_MODE].value.s)
  free((void *)session.options[OPT_RESOLUTION].descriptor.constraint.word_list)

  free(session)

  DBG(DBG_proc, "Sane.close: exit\n")
}


/**
 * Terminates the backend.
 *
 * From the SANE spec:
 * This function must be called to terminate use of a backend. The
 * function will first close all device handles that still might be
 * open(it is recommended to close device handles explicitly through
 * a call to Sane.close(), but backends are required to release all
 * resources upon a call to this function). After this function
 * returns, no function other than Sane.init() may be called
 * (regardless of the status value returned by Sane.exit(). Neglecting
 * to call this function may result in some resources not being
 * released properly.
 */
void
Sane.exit(void)
{
  struct P5_Session *session, *next
  struct P5_Device *dev, *nextdev
  var i: Int

  DBG(DBG_proc, "Sane.exit: start\n")
  init_count--

  if(init_count > 0)
    {
      DBG(DBG_info,
	   "Sane.exit: still %d fronteds to leave before effective exit.\n",
	   init_count)
      return
    }

  /* free session structs */
  for(session = sessions; session; session = next)
    {
      next = session.next
      Sane.close((Sane.Handle *) session)
      free(session)
    }
  sessions = NULL

  /* free devices structs */
  for(dev = devices; dev; dev = nextdev)
    {
      nextdev = dev.next
      free(dev.name)
      free(dev)
    }
  devices = NULL

  /* now list of devices */
  if(devlist)
    {
      i = 0
      while((Sane.Device *) devlist[i])
	{
	  free((Sane.Device *) devlist[i])
	  i++
	}
      free(devlist)
      devlist = NULL
    }

  DBG(DBG_proc, "Sane.exit: exit\n")
}


/** @brief probe for all supported devices
 * This functions tries to probe if any of the supported devices of
 * the backend is present. Each detected device will be added to the
 * "devices" list
 */
static Sane.Status
probe_p5_devices(void)
{
  /**> configuration structure used during attach */
  SANEI_Config config
  /**> list of configuration options */
  Sane.Option_Descriptor *cfg_options[NUM_CFG_OPTIONS]
  /**> placeholders pointers for option values */
  void *values[NUM_CFG_OPTIONS]
  var i: Int
  Sane.Status status

  DBG(DBG_proc, "probe_p5_devices: start\n")

  /* initialize configuration options */
  cfg_options[CFG_MODEL_NAME] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  cfg_options[CFG_MODEL_NAME]->name = "modelname"
  cfg_options[CFG_MODEL_NAME]->desc = "user provided scanner"s model name"
  cfg_options[CFG_MODEL_NAME]->type = Sane.TYPE_INT
  cfg_options[CFG_MODEL_NAME]->unit = Sane.UNIT_NONE
  cfg_options[CFG_MODEL_NAME]->size = sizeof(Sane.Word)
  cfg_options[CFG_MODEL_NAME]->cap = Sane.CAP_SOFT_SELECT
  cfg_options[CFG_MODEL_NAME]->constraint_type = Sane.CONSTRAINT_NONE
  values[CFG_MODEL_NAME] = &p5cfg.modelname

  /* set configuration options structure */
  config.descriptors = cfg_options
  config.values = values
  config.count = NUM_CFG_OPTIONS

  /* generic configure and attach function */
  status = sanei_configure_attach(P5_CONFIG_FILE, &config,
                                   config_attach, NULL)
  /* free allocated options */
  for(i = 0; i < NUM_CFG_OPTIONS; i++)
    {
      free(cfg_options[i])
    }

  DBG(DBG_proc, "probe_p5_devices: end\n")
  return status
}

/** This function is called by sanei_configure_attach to try
 * to attach the backend to a device specified by the configuration file.
 *
 * @param config configuration structure filled with values read
 * 	         from configuration file
 * @param devname name of the device to try to attach to, it is
 * 	          the unprocessed line of the configuration file
 *
 * @return status Sane.STATUS_GOOD if no errors(even if no matching
 * 	    devices found)
 * 	   Sane.STATUS_INVAL in case of error
 */
static Sane.Status
config_attach(SANEI_Config __Sane.unused__ * config, const char *devname,
               void __Sane.unused__ *data)
{
  /* currently, the config is a global variable so config is useless here */
  /* the correct thing would be to have a generic sanei_attach_matching_devices
   * using an attach function with a config parameter */
  config = config

  /* the devname has been processed and is ready to be used
   * directly. The config struct contains all the configuration data for
   * the corresponding device. Since there is no resources common to each
   * backends regarding parallel port, we can directly call the attach
   * function. */
  attach_p5 (devname, config)

  return Sane.STATUS_GOOD
}

/** @brief try to attach to a device by its name
 * The attach tries to open the given device and match it
 * with devices handled by the backend. The configuration parameter
 * contains the values of the already parsed configuration options
 * from the conf file.
 * @param config configuration structure filled with values read
 * 	         from configuration file
 * @param devicename name of the device to try to attach to, it is
 * 	          the unprocessed line of the configuration file
 *
 * @return status Sane.STATUS_GOOD if no errors(even if no matching
 * 	    devices found)
 * 	   Sane.STATUS_NOM_MEM if there isn"t enough memory to allocate the
 * 	   			device structure
 * 	   Sane.STATUS_UNSUPPORTED if the device if unknown by the backend
 * 	   Sane.STATUS_INVAL in case of other error
 */
static Sane.Status
attach_p5 (const char *devicename, SANEI_Config * config)
{
  struct P5_Device *device
  struct P5_Model *model

  DBG(DBG_proc, "attach(%s): start\n", devicename)
  if(config==NULL)
    {
      DBG(DBG_warn, "attach: config is NULL\n")
    }

  /* search if we already have it attached */
  for(device = devices; device; device = device.next)
    {
      if(strcmp(device.name, devicename) == 0)
	{
	  DBG(DBG_info, "attach: device already attached\n")
	  DBG(DBG_proc, "attach: exit\n")
	  return Sane.STATUS_GOOD
	}
    }

  /**
   * do physical probe of the device here. In case the device is recognized,
   * we allocate a device struct and give it options and model.
   * Else we return Sane.STATUS_UNSUPPORTED.
   */
  model = probe(devicename)
  if(model == NULL)
    {
      DBG(DBG_info,
	   "attach: device %s is not managed by the backend\n", devicename)
      DBG(DBG_proc, "attach: exit\n")
      return Sane.STATUS_UNSUPPORTED
    }

  /* allocate device struct */
  device = malloc(sizeof(*device))
  if(device == NULL)
    {
      return Sane.STATUS_NO_MEM
      DBG(DBG_proc, "attach: exit\n")
    }
  memset(device, 0, sizeof(*device))
  device.model = model

  /* name of the device */
  device.name = strdup(devicename)

  DBG(DBG_info, "attach: found %s %s %s at %s\n",
       device.model.vendor, device.model.product, device.model.type,
       device.name)

  /* we insert new device at start of the chained list */
  /* head of the list becomes the next, and start is replaced */
  /* with the new session struct */
  device.next = devices
  devices = device

  /* initialization is done at Sane.open */
  device.initialized = Sane.FALSE
  device.calibrated = Sane.FALSE

  DBG(DBG_proc, "attach: exit\n")
  return Sane.STATUS_GOOD
}


/** @brief set initial value for the scanning options
 * for each sessions, control options are initialized based on the capability
 * of the model of the physical device.
 * @param session scanner session to initialize options
 * @return Sane.STATUS_GOOD on success
 */
static Sane.Status
init_options(struct P5_Session *session)
{
  Int option, i, min, idx
  Sane.Word *dpi_list
  P5_Model *model = session.dev.model

  DBG(DBG_proc, "init_options: start\n")

  /* we first initialize each options with a default value */
  memset(session.options, 0, sizeof(session.options[OPT_NUM_OPTS]))
  for(option = 0; option < NUM_OPTIONS; option++)
    {
      session.options[option].descriptor.size = sizeof(Sane.Word)
      session.options[option].descriptor.cap =
	Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  /* we set up all the options listed in the P5_Option enum */

  /* last option / end of list marker */
  session.options[OPT_NUM_OPTS].descriptor.name = Sane.NAME_NUM_OPTIONS
  session.options[OPT_NUM_OPTS].descriptor.title = Sane.TITLE_NUM_OPTIONS
  session.options[OPT_NUM_OPTS].descriptor.desc = Sane.DESC_NUM_OPTIONS
  session.options[OPT_NUM_OPTS].descriptor.type = Sane.TYPE_INT
  session.options[OPT_NUM_OPTS].descriptor.cap = Sane.CAP_SOFT_DETECT
  session.options[OPT_NUM_OPTS].value.w = NUM_OPTIONS

  /* "Standard" group: */
  session.options[OPT_STANDARD_GROUP].descriptor.title = Sane.TITLE_STANDARD
  session.options[OPT_STANDARD_GROUP].descriptor.name = Sane.NAME_STANDARD
  session.options[OPT_STANDARD_GROUP].descriptor.desc = Sane.DESC_STANDARD
  session.options[OPT_STANDARD_GROUP].descriptor.type = Sane.TYPE_GROUP
  session.options[OPT_STANDARD_GROUP].descriptor.size = 0
  session.options[OPT_STANDARD_GROUP].descriptor.cap = 0
  session.options[OPT_STANDARD_GROUP].descriptor.constraint_type =
    Sane.CONSTRAINT_NONE

  /* scan mode */
  session.options[OPT_MODE].descriptor.name = Sane.NAME_SCAN_MODE
  session.options[OPT_MODE].descriptor.title = Sane.TITLE_SCAN_MODE
  session.options[OPT_MODE].descriptor.desc = Sane.DESC_SCAN_MODE
  session.options[OPT_MODE].descriptor.type = Sane.TYPE_STRING
  session.options[OPT_MODE].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_MODE].descriptor.constraint_type =
    Sane.CONSTRAINT_STRING_LIST
  session.options[OPT_MODE].descriptor.size = max_string_size(mode_list)
  session.options[OPT_MODE].descriptor.constraint.string_list = mode_list
  session.options[OPT_MODE].value.s = strdup(mode_list[0])

  /* preview */
  session.options[OPT_PREVIEW].descriptor.name = Sane.NAME_PREVIEW
  session.options[OPT_PREVIEW].descriptor.title = Sane.TITLE_PREVIEW
  session.options[OPT_PREVIEW].descriptor.desc = Sane.DESC_PREVIEW
  session.options[OPT_PREVIEW].descriptor.type = Sane.TYPE_BOOL
  session.options[OPT_PREVIEW].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_PREVIEW].descriptor.unit = Sane.UNIT_NONE
  session.options[OPT_PREVIEW].descriptor.constraint_type =
    Sane.CONSTRAINT_NONE
  session.options[OPT_PREVIEW].value.w = Sane.FALSE

  /** @brief build resolution list
   * We merge xdpi and ydpi list to provide only one resolution option control.
   * This is the most common case for backends and fronteds and give "square"
   * pixels. The SANE API allow to control x and y dpi independently, but this is
   * rarely done and may confuse both frontends and users. In case a dpi value exists
   * for one but not for the other, the backend will have to crop data so that the
   * frontend is unaffected. A common case is that motor resolution(ydpi) is higher
   * than sensor resolution(xdpi), so scan lines must be scaled up to keep square
   * pixel when doing Sane.read().
   * TODO this deserves a dedicated function and some unit testing
   */

  /* find minimum first */
  min = 65535
  for(i = 0; i < MAX_RESOLUTIONS && model.xdpi_values[i] > 0; i++)
    {
      if(model.xdpi_values[i] < min)
	min = model.xdpi_values[i]
    }
  for(i = 0; i < MAX_RESOLUTIONS && model.ydpi_values[i] > 0; i++)
    {
      if(model.ydpi_values[i] < min)
	min = model.ydpi_values[i]
    }

  dpi_list = malloc((MAX_RESOLUTIONS * 2 + 1) * sizeof(Sane.Word))
  if(!dpi_list)
    return Sane.STATUS_NO_MEM
  dpi_list[1] = min
  idx = 2

  /* find any value greater than the last used min and
   * less than the max value
   */
  do
    {
      min = 65535
      for(i = 0; i < MAX_RESOLUTIONS && model.xdpi_values[i] > 0; i++)
	{
	  if(model.xdpi_values[i] < min
	      && model.xdpi_values[i] > dpi_list[idx - 1])
	    min = model.xdpi_values[i]
	}
      for(i = 0; i < MAX_RESOLUTIONS && model.ydpi_values[i] > 0; i++)
	{
	  if(model.ydpi_values[i] < min
	      && model.ydpi_values[i] > dpi_list[idx - 1])
	    min = model.ydpi_values[i]
	}
      if(min < 65535)
	{
	  dpi_list[idx] = min
	  idx++
	}
    }
  while(min != 65535)
  dpi_list[idx] = 0
  /* the count of different resolution is put at the beginning */
  dpi_list[0] = idx - 1

  session.options[OPT_RESOLUTION].descriptor.name =
    Sane.NAME_SCAN_RESOLUTION
  session.options[OPT_RESOLUTION].descriptor.title =
    Sane.TITLE_SCAN_RESOLUTION
  session.options[OPT_RESOLUTION].descriptor.desc =
    Sane.DESC_SCAN_RESOLUTION
  session.options[OPT_RESOLUTION].descriptor.type = Sane.TYPE_INT
  session.options[OPT_RESOLUTION].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_RESOLUTION].descriptor.unit = Sane.UNIT_DPI
  session.options[OPT_RESOLUTION].descriptor.constraint_type =
    Sane.CONSTRAINT_WORD_LIST
  session.options[OPT_RESOLUTION].descriptor.constraint.word_list = dpi_list

  /* initial value is lowest available dpi */
  session.options[OPT_RESOLUTION].value.w = min

  /* "Geometry" group: */
  session.options[OPT_GEOMETRY_GROUP].descriptor.title = Sane.TITLE_GEOMETRY
  session.options[OPT_GEOMETRY_GROUP].descriptor.name = Sane.NAME_GEOMETRY
  session.options[OPT_GEOMETRY_GROUP].descriptor.desc = Sane.DESC_GEOMETRY
  session.options[OPT_GEOMETRY_GROUP].descriptor.type = Sane.TYPE_GROUP
  session.options[OPT_GEOMETRY_GROUP].descriptor.cap = Sane.CAP_ADVANCED
  session.options[OPT_GEOMETRY_GROUP].descriptor.size = 0
  session.options[OPT_GEOMETRY_GROUP].descriptor.constraint_type =
    Sane.CONSTRAINT_NONE

  /* adapt the constraint range to the detected model */
  x_range.max = model.x_size
  y_range.max = model.y_size

  /* top-left x */
  session.options[OPT_TL_X].descriptor.name = Sane.NAME_SCAN_TL_X
  session.options[OPT_TL_X].descriptor.title = Sane.TITLE_SCAN_TL_X
  session.options[OPT_TL_X].descriptor.desc = Sane.DESC_SCAN_TL_X
  session.options[OPT_TL_X].descriptor.type = Sane.TYPE_FIXED
  session.options[OPT_TL_X].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_TL_X].descriptor.unit = Sane.UNIT_MM
  session.options[OPT_TL_X].descriptor.constraint_type =
    Sane.CONSTRAINT_RANGE
  session.options[OPT_TL_X].descriptor.constraint.range = &x_range
  session.options[OPT_TL_X].value.w = 0

  /* top-left y */
  session.options[OPT_TL_Y].descriptor.name = Sane.NAME_SCAN_TL_Y
  session.options[OPT_TL_Y].descriptor.title = Sane.TITLE_SCAN_TL_Y
  session.options[OPT_TL_Y].descriptor.desc = Sane.DESC_SCAN_TL_Y
  session.options[OPT_TL_Y].descriptor.type = Sane.TYPE_FIXED
  session.options[OPT_TL_Y].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_TL_Y].descriptor.unit = Sane.UNIT_MM
  session.options[OPT_TL_Y].descriptor.constraint_type =
    Sane.CONSTRAINT_RANGE
  session.options[OPT_TL_Y].descriptor.constraint.range = &y_range
  session.options[OPT_TL_Y].value.w = 0

  /* bottom-right x */
  session.options[OPT_BR_X].descriptor.name = Sane.NAME_SCAN_BR_X
  session.options[OPT_BR_X].descriptor.title = Sane.TITLE_SCAN_BR_X
  session.options[OPT_BR_X].descriptor.desc = Sane.DESC_SCAN_BR_X
  session.options[OPT_BR_X].descriptor.type = Sane.TYPE_FIXED
  session.options[OPT_BR_X].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_BR_X].descriptor.unit = Sane.UNIT_MM
  session.options[OPT_BR_X].descriptor.constraint_type =
    Sane.CONSTRAINT_RANGE
  session.options[OPT_BR_X].descriptor.constraint.range = &x_range
  session.options[OPT_BR_X].value.w = x_range.max

  /* bottom-right y */
  session.options[OPT_BR_Y].descriptor.name = Sane.NAME_SCAN_BR_Y
  session.options[OPT_BR_Y].descriptor.title = Sane.TITLE_SCAN_BR_Y
  session.options[OPT_BR_Y].descriptor.desc = Sane.DESC_SCAN_BR_Y
  session.options[OPT_BR_Y].descriptor.type = Sane.TYPE_FIXED
  session.options[OPT_BR_Y].descriptor.cap |= Sane.CAP_AUTOMATIC
  session.options[OPT_BR_Y].descriptor.unit = Sane.UNIT_MM
  session.options[OPT_BR_Y].descriptor.constraint_type =
    Sane.CONSTRAINT_RANGE
  session.options[OPT_BR_Y].descriptor.constraint.range = &y_range
  session.options[OPT_BR_Y].value.w = y_range.max

  /* sensor group */
  session.options[OPT_SENSOR_GROUP].descriptor.name = Sane.NAME_SENSORS
  session.options[OPT_SENSOR_GROUP].descriptor.title = Sane.TITLE_SENSORS
  session.options[OPT_SENSOR_GROUP].descriptor.desc = Sane.DESC_SENSORS
  session.options[OPT_SENSOR_GROUP].descriptor.type = Sane.TYPE_GROUP
  session.options[OPT_SENSOR_GROUP].descriptor.constraint_type =
    Sane.CONSTRAINT_NONE

  /* page loaded sensor */
  session.options[OPT_PAGE_LOADED_SW].descriptor.name =
    Sane.NAME_PAGE_LOADED
  session.options[OPT_PAGE_LOADED_SW].descriptor.title =
    Sane.TITLE_PAGE_LOADED
  session.options[OPT_PAGE_LOADED_SW].descriptor.desc =
    Sane.DESC_PAGE_LOADED
  session.options[OPT_PAGE_LOADED_SW].descriptor.type = Sane.TYPE_BOOL
  session.options[OPT_PAGE_LOADED_SW].descriptor.unit = Sane.UNIT_NONE
  session.options[OPT_PAGE_LOADED_SW].descriptor.cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  session.options[OPT_PAGE_LOADED_SW].value.b = 0

  /* calibration needed */
  session.options[OPT_NEED_CALIBRATION_SW].descriptor.name =
    "need-calibration"
  session.options[OPT_NEED_CALIBRATION_SW].descriptor.title =
    Sane.I18N("Need calibration")
  session.options[OPT_NEED_CALIBRATION_SW].descriptor.desc =
    Sane.I18N("The scanner needs calibration for the current settings")
  session.options[OPT_NEED_CALIBRATION_SW].descriptor.type = Sane.TYPE_BOOL
  session.options[OPT_NEED_CALIBRATION_SW].descriptor.unit = Sane.UNIT_NONE
  session.options[OPT_NEED_CALIBRATION_SW].descriptor.cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  session.options[OPT_NEED_CALIBRATION_SW].value.b = 0

  /* button group */
  session.options[OPT_BUTTON_GROUP].descriptor.name = "Buttons"
  session.options[OPT_BUTTON_GROUP].descriptor.title = Sane.I18N("Buttons")
  session.options[OPT_BUTTON_GROUP].descriptor.desc = Sane.I18N("Buttons")
  session.options[OPT_BUTTON_GROUP].descriptor.type = Sane.TYPE_GROUP
  session.options[OPT_BUTTON_GROUP].descriptor.constraint_type =
    Sane.CONSTRAINT_NONE

  /* calibrate button */
  session.options[OPT_CALIBRATE].descriptor.name = "calibrate"
  session.options[OPT_CALIBRATE].descriptor.title = Sane.I18N("Calibrate")
  session.options[OPT_CALIBRATE].descriptor.desc =
    Sane.I18N("Start calibration using special sheet")
  session.options[OPT_CALIBRATE].descriptor.type = Sane.TYPE_BUTTON
  session.options[OPT_CALIBRATE].descriptor.unit = Sane.UNIT_NONE
  session.options[OPT_CALIBRATE].descriptor.cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED |
    Sane.CAP_AUTOMATIC
  session.options[OPT_CALIBRATE].value.b = 0

  /* clear calibration cache button */
  session.options[OPT_CLEAR_CALIBRATION].descriptor.name = "clear"
  session.options[OPT_CLEAR_CALIBRATION].descriptor.title =
    Sane.I18N("Clear calibration")
  session.options[OPT_CLEAR_CALIBRATION].descriptor.desc =
    Sane.I18N("Clear calibration cache")
  session.options[OPT_CLEAR_CALIBRATION].descriptor.type = Sane.TYPE_BUTTON
  session.options[OPT_CLEAR_CALIBRATION].descriptor.unit = Sane.UNIT_NONE
  session.options[OPT_CLEAR_CALIBRATION].descriptor.cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED |
    Sane.CAP_AUTOMATIC
  session.options[OPT_CLEAR_CALIBRATION].value.b = 0

  /* until work on calibration isfinished */
  DISABLE(OPT_CALIBRATE)
  DISABLE(OPT_CLEAR_CALIBRATION)

  DBG(DBG_proc, "init_options: exit\n")
  return Sane.STATUS_GOOD
}

/** @brief physical probe of a device
 * This function probes for a scanning device using the given name. If the
 * device is managed, a model structure describing the device will be returned.
 * @param devicename low level device to access to probe hardware
 * @return NULL is the device is unsupported, or a model struct describing the
 * device.
 */
P5_Model *
probe(const char *devicename)
{
  Int fd

  /* open parallel port device */
  fd = open_pp(devicename)
  if(fd < 0)
    {
      DBG(DBG_error, "probe: failed to open "%s" device!\n", devicename)
      return NULL
    }

  /* now try to connect to scanner */
  if(connect(fd) != Sane.TRUE)
    {
      DBG(DBG_error, "probe: failed to connect!\n")
      close_pp(fd)
      return NULL
    }

  /* set up for memory test */
  write_reg(fd, REG1, 0x00)
  write_reg(fd, REG7, 0x00)
  write_reg(fd, REG0, 0x00)
  write_reg(fd, REG1, 0x00)
  write_reg(fd, REGF, 0x80)
  if(memtest(fd, 0x0100) != Sane.TRUE)
    {
      disconnect(fd)
      close_pp(fd)
      DBG(DBG_error, "probe: memory test failed!\n")
      return NULL
    }
  else
    {
      DBG(DBG_info, "memtest() OK...\n")
    }
  write_reg(fd, REG7, 0x00)

  /* check for document presence 0xC6: present, 0xC3 no document */
  test_document(fd)

  /* release device and parport for next uses */
  disconnect(fd)
  close_pp(fd)

  /* for there is only one supported model, so we use hardcoded values */
  DBG(DBG_proc, "probe: exit\n")
  return &pagepartner_model
}


/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */
