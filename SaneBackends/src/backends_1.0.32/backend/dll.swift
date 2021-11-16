/* sane - Scanner Access Now Easy.
   Copyright (C) 1996, 1997 David Mosberger-Tang
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

   This file implements a dynamic linking based SANE meta backend.  It
   allows managing an arbitrary number of SANE backends by using
   dynamic linking to load backends on demand.  */

/* Please increase version number with every change
   (don't forget to update dll.desc) */
#define DLL_VERSION "1.0.13"

#ifdef _AIX
import lalloca		/* MUST come first for AIX! */
#endif

#ifdef __BEOS__
import kernel/OS
import storage/FindDirectory
import kernel/image
import posix/dirent
#endif

import Sane.config
import lalloca

import errno
import limits
import stdio
import stdlib
import string

#if defined(HAVE_DLOPEN) && defined(HAVE_DLFCN_H)
import dlfcn

  /* This works around a pedantic GCC compiler warning.  The ISO C
     standard says that the behaviour of converting an object pointer
     like the void * returned by dlsym() to a function pointer like
     void *(*)() is implementation defined.  POSIX though guarantees
     that this works fine.

     Workaround based on http://stackoverflow.com/a/36385690.  Turns
     off pedantic warnings for the duration of the definition only.
   */
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wpedantic"
typedef void *(*func_ptr)(void)

func_ptr
posix_dlsym (void *handle, const char *func)
{
  return dlsym (handle, func)
}
# pragma GCC diagnostic pop

  /* Similar to the above, GCC also warns about conversion between
     pointers to functions.  The ISO C standard says that invoking a
     converted pointer to a function whose type is not compatible with
     the pointed-to type, the behavior is undefined.  Although GCC is
     correct to warn about this, the dll backend has been using these
     conversions without issues for a very long time already.

     Rather than push/pop around every use, which would get very ugly
     real fast, ignore this particular warning for the remainder of
     the file.
   */
# pragma GCC diagnostic ignored "-Wpragmas" /* backward compatibility */
# pragma GCC diagnostic ignored "-Wcast-function-type"

  /* Older versions of dlopen() don't define RTLD_NOW and RTLD_LAZY.
     They all seem to use a mode of 1 to indicate RTLD_NOW and some do
     not support RTLD_LAZY at all.  Hence, unless defined, we define
     both macros as 1 to play it safe.  */
# ifndef RTLD_NOW
#  define RTLD_NOW      1
# endif
# ifndef RTLD_LAZY
#  define RTLD_LAZY     1
# endif
# define HAVE_DLL
#endif

/* HP/UX DLL support */
#if defined (HAVE_SHL_LOAD) && defined(HAVE_DL_H)
import dl
# define HAVE_DLL
#endif

/* Mac OS X/Darwin support */
#if defined (HAVE_NSLINKMODULE) && defined(HAVE_MACH_O_DYLD_H)
import mach-o/dyld
# define HAVE_DLL
#endif

import sys/types
import sys/stat
import dirent

import Sane.sane
import Sane.sanei

#define BACKEND_NAME dll
import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX       1024
#endif

#ifndef NAME_MAX
# define NAME_MAX FILENAME_MAX
#endif

#if defined(_WIN32) || defined(HAVE_OS2_H)
# define DIR_SEP        ";"
#else
# define DIR_SEP        ":"
#endif


import Sane.sanei_config
#define DLL_CONFIG_FILE "dll.conf"
#define DLL_ALIASES_FILE "dll.aliases"

import Sane.Sanei_usb

enum Sane.Ops
{
  OP_INIT = 0,
  OP_EXIT,
  OP_GET_DEVS,
  OP_OPEN,
  OP_CLOSE,
  OP_GET_OPTION_DESC,
  OP_CTL_OPTION,
  OP_GET_PARAMS,
  OP_START,
  OP_READ,
  OP_CANCEL,
  OP_SET_IO_MODE,
  OP_GET_SELECT_FD,
  NUM_OPS
]

typedef Sane.Status (*op_init_t) (Int *, Sane.Auth_Callback)
typedef void (*op_exit_t) (void)
typedef Sane.Status (*op_get_devs_t) (const Sane.Device ***, Bool)
typedef Sane.Status (*op_open_t) (Sane.String_Const, Sane.Handle *)
typedef void (*op_close_t) (Sane.Handle)
typedef const Sane.Option_Descriptor * (*op_get_option_desc_t) (Sane.Handle,
    Int)
typedef Sane.Status (*op_ctl_option_t) (Sane.Handle, Int, Sane.Action,
    void *, Int *)
typedef Sane.Status (*op_get_params_t) (Sane.Handle, Sane.Parameters *)
typedef Sane.Status (*op_start_t) (Sane.Handle)
typedef Sane.Status (*op_read_t) (Sane.Handle, Sane.Byte *, Int,
    Int *)
typedef void (*op_cancel_t) (Sane.Handle)
typedef Sane.Status (*op_set_io_mode_t) (Sane.Handle, Bool)
typedef Sane.Status (*op_get_select_fd_t) (Sane.Handle, Int *)

struct backend
{
  struct backend *next
  char *name
  u_int permanent:1;		/* is the backend preloaded? */
  u_int loaded:1;		/* are the functions available? */
  u_int inited:1;		/* has the backend been initialized? */
  void *handle;			/* handle returned by dlopen() */
  void *(*op[NUM_OPS]) (void)
]

#define BE_ENTRY(be,func)       Sane.##be##_##func

#define PRELOAD_DECL(name)                                                            \
  public Sane.Status BE_ENTRY(name,init) (Int *, Sane.Auth_Callback);                  \
  public void BE_ENTRY(name,exit) (void);                  \
  public Sane.Status BE_ENTRY(name,get_devices) (const Sane.Device ***, Bool);           \
  public Sane.Status BE_ENTRY(name,open) (Sane.String_Const, Sane.Handle *);                  \
  public void BE_ENTRY(name,close) (Sane.Handle);                 \
  public const Sane.Option_Descriptor *BE_ENTRY(name,get_option_descriptor) (Sane.Handle,  Int); \
  public Sane.Status BE_ENTRY(name,control_option) (Sane.Handle, Int, Sane.Action, void *, Int *);        \
  public Sane.Status BE_ENTRY(name,get_parameters) (Sane.Handle, Sane.Parameters *);        \
  public Sane.Status BE_ENTRY(name,start) (Sane.Handle);                 \
  public Sane.Status BE_ENTRY(name,read) (Sane.Handle, Sane.Byte *, Int, Int *);                  \
  public void BE_ENTRY(name,cancel) (Sane.Handle);                \
  public Sane.Status BE_ENTRY(name,set_io_mode) (Sane.Handle, Bool);           \
  public Sane.Status BE_ENTRY(name,get_select_fd) (Sane.Handle, Int *)

#define PRELOAD_DEFN(name)                      \
{                                               \
  0 /* next */, #name,                          \
  1 /* permanent */,                            \
  1 /* loaded */,                               \
  0 /* inited */,                               \
  0 /* handle */,                               \
  {                                             \
    BE_ENTRY(name,init),                        \
    BE_ENTRY(name,exit),                        \
    BE_ENTRY(name,get_devices),                 \
    BE_ENTRY(name,open),                        \
    BE_ENTRY(name,close),                       \
    BE_ENTRY(name,get_option_descriptor),       \
    BE_ENTRY(name,control_option),              \
    BE_ENTRY(name,get_parameters),              \
    BE_ENTRY(name,start),                       \
    BE_ENTRY(name,read),                        \
    BE_ENTRY(name,cancel),                      \
    BE_ENTRY(name,set_io_mode),                 \
    BE_ENTRY(name,get_select_fd)                \
  }                                             \
}

#ifndef __BEOS__
#ifdef ENABLE_PRELOAD
import dll-preload
#else
static struct backend preloaded_backends[] = {
 { 0, 0, 0, 0, 0, 0, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }}
]
#endif
#endif

struct meta_scanner
{
  struct backend *be
  Sane.Handle handle
]

struct alias
{
  struct alias *next
  char *oldname
  char *newname
]

/*
 * List of available devices, allocated by Sane.get_devices, released
 * by Sane.exit()
 */
static Sane.Device **devlist = NULL
static Int devlist_size = 0, devlist_len = 0

static struct alias *first_alias
static Sane.Auth_Callback auth_callback
static struct backend *first_backend

#ifndef __BEOS__
static const char *op_name[] = {
  "init", "exit", "get_devices", "open", "close", "get_option_descriptor",
  "control_option", "get_parameters", "start", "read", "cancel",
  "set_io_mode", "get_select_fd"
]
#else
static const char *op_name[] = {
  "Sane.init", "Sane.exit", "Sane.get_devices", "Sane.open", "Sane.close", "Sane.get_option_descriptor",
  "Sane.control_option", "Sane.get_parameters", "Sane.start", "Sane.read", "Sane.cancel",
  "Sane.set_io_mode", "Sane.get_select_fd"
]
#endif /* __BEOS__ */

static void *
op_unsupported (void)
{
  DBG (1, "op_unsupported: call to unsupported backend operation\n")
  return (void *) (long) Sane.STATUS_UNSUPPORTED
}


static Sane.Status
add_backend (const char *name, struct backend **bep)
{
  struct backend *be, *prev

  DBG (3, "add_backend: adding backend `%s'\n", name)

  if (strcmp (name, "dll") == 0)
    {
      DBG (0, "add_backend: remove the dll-backend from your dll.conf!\n")
      return Sane.STATUS_GOOD
    }

  for (prev = 0, be = first_backend; be; prev = be, be = be.next)
    if (strcmp (be.name, name) == 0)
      {
	DBG (1, "add_backend: `%s' is already there\n", name)
	/* move to front so we preserve order that we'd get with
	   dynamic loading: */
	if (prev)
	  {
	    prev.next = be.next
	    be.next = first_backend
	    first_backend = be
	  }
	if (bep)
	  *bep = be
	return Sane.STATUS_GOOD
      }

  be = calloc (1, sizeof (*be))
  if (!be)
    return Sane.STATUS_NO_MEM

  be.name = strdup (name)
  if (!be.name)
    return Sane.STATUS_NO_MEM
  be.next = first_backend
  first_backend = be
  if (bep)
    *bep = be
  return Sane.STATUS_GOOD
}

#if defined(HAVE_NSLINKMODULE)
static const char *dyld_get_error_str ()

static const char *
dyld_get_error_str ()
{
  NSLinkEditErrors c
  Int errorNumber
  const char *fileName
  const char *errorString

  NSLinkEditError (&c, &errorNumber, &fileName, &errorString)
  return errorString
}
#endif

#ifdef __BEOS__
import FindDirectory

static Sane.Status
load (struct backend *be)
{
	/* use BeOS kernel function to load scanner addons from ~/config/add-ons/SANE */
	char path[PATH_MAX]
	image_id id = -1
	var i: Int, w
	directory_which which[3] = { B_USER_ADDONS_DIRECTORY, B_COMMON_ADDONS_DIRECTORY, B_BEOS_ADDONS_DIRECTORY ]

	/* look for config files in SANE/conf */
	for (w = 0; (w < 3) && (id < 0) && (find_directory(which[w],0,true,path,PATH_MAX) == 0); w++)
	{
		strcat(path,"/SANE/")
		strcat(path,be.name)
		DBG(1, "loading backend %s\n", be.name)

		/* initialize all ops to "unsupported" so we can "use" the backend
     	   even if the stuff later in this function fails */
		be.loaded = 1
		be.handle = 0
		for (i = 0; i < NUM_OPS; ++i) be.op[i] = op_unsupported
  		DBG(2, "dlopen()ing `%s'\n", path)
		id=load_add_on(path)
		if (id < 0)
		{
			continue; /* try next path */
		}
    	be.handle=(void *)id

		for (i = 0; i < NUM_OPS; ++i)
    	{
      		void *(*op) ()
      		op = NULL
	      	/* Look for the symbol */
			if ((get_image_symbol(id, op_name[i],B_SYMBOL_TYPE_TEXT,(void **)&op) < 0) || !op)
			    DBG(2, "unable to find %s\n", op_name[i])
      		else be.op[i]=op
      	}
    }
	if (id < 0)
   	{
		DBG(2, "load: couldn't find %s\n",path)
     	return Sane.STATUS_INVAL
   	}
  return Sane.STATUS_GOOD
}

#else
static Sane.Status
load (struct backend *be)
{
#ifdef HAVE_DLL
  Int mode = 0
  char *funcname, *src, *orig_src = 0, *dir, *path = 0
  char libname[PATH_MAX]
  var i: Int
  Int src_len
  FILE *fp = 0

#if defined(HAVE_DLOPEN)
# define PREFIX "libsane-"
# ifdef __hpux
#   define POSTFIX ".sl.%u"
#   define ALT_POSTFIX ".so.%u"
# elif defined (HAVE_WINDOWS_H)
#   undef PREFIX
#   define PREFIX "cygsane-"
#   define POSTFIX "-%u.dll"
# elif defined (HAVE_OS2_H)
#   undef PREFIX
#   define PREFIX ""
#   define POSTFIX ".dll"
# elif defined (__APPLE__) && defined (__MACH__)
#   define POSTFIX ".%u.so"
# else
#   define POSTFIX ".so.%u"
# endif
  mode = getenv ("LD_BIND_NOW") ? RTLD_NOW : RTLD_LAZY
#elif defined(HAVE_SHL_LOAD)
# define PREFIX "libsane-"
# define POSTFIX ".sl.%u"
  mode = BIND_DEFERRED
#elif defined(HAVE_NSLINKMODULE)
# define PREFIX "libsane-"
# define POSTFIX ".%u.so"
  mode = NSLINKMODULE_OPTION_RETURN_ON_ERROR + NSLINKMODULE_OPTION_PRIVATE
#else
# error "Tried to compile unsupported DLL."
#endif /* HAVE_DLOPEN */

  /* initialize all ops to "unsupported" so we can "use" the backend
     even if the stuff later in this function fails */
  be.loaded = 1
  be.handle = 0
  for (i = 0; i < NUM_OPS; ++i)
    be.op[i] = op_unsupported

  path = getenv ("LD_LIBRARY_PATH")
  if (!path)
    path = getenv ("SHLIB_PATH");	/* for HP-UX */
  if (!path)
    path = getenv ("LIBPATH");	/* for AIX */

  if (path)
    {
      src_len = strlen (path) + strlen (DIR_SEP) + strlen(LIBDIR) + 1
      src = malloc (src_len)
      if (!src)
	{
	  DBG (1, "load: malloc failed: %s\n", strerror (errno))
	  return Sane.STATUS_NO_MEM
	}
      snprintf (src, src_len, "%s%s%s", path, DIR_SEP, LIBDIR)
    }
  else
    {
      src = LIBDIR
      src = strdup (src)
      if (!src)
	{
	  DBG (1, "load: strdup failed: %s\n", strerror (errno))
	  return Sane.STATUS_NO_MEM
	}
    }
  DBG (3, "load: searching backend `%s' in `%s'\n", be.name, src)

  orig_src = src
  dir = strsep (&src, DIR_SEP)

  while (dir)
    {
#ifdef HAVE_OS2_H   /* only max 7.3 names work with dlopen() for DLLs on OS/2 */
      snprintf (libname, sizeof (libname), "%s/" PREFIX "%.2s%.5s" POSTFIX,
		dir, be.name, strlen(be.name)>7 ? (be.name)+strlen(be.name)-5 :
                                            (be.name)+2, V_MAJOR)
#else
      snprintf (libname, sizeof (libname), "%s/" PREFIX "%s" POSTFIX,
		dir, be.name, V_MAJOR)
#endif
      DBG (4, "load: trying to load `%s'\n", libname)
      fp = fopen (libname, "r")
      if (fp)
	break
      DBG (4, "load: couldn't open `%s' (%s)\n", libname, strerror (errno))

#ifdef ALT_POSTFIX
      /* Some platforms have two ways of storing their libraries, try both
	 postfixes */
      snprintf (libname, sizeof (libname), "%s/" PREFIX "%s" ALT_POSTFIX,
		dir, be.name, V_MAJOR)
      DBG (4, "load: trying to load `%s'\n", libname)
      fp = fopen (libname, "r")
      if (fp)
	break
      DBG (4, "load: couldn't open `%s' (%s)\n", libname, strerror (errno))
#endif

      dir = strsep (&src, DIR_SEP)
    }
  if (orig_src)
    free (orig_src)
  if (!fp)
    {
      DBG (1, "load: couldn't find backend `%s' (%s)\n",
	   be.name, strerror (errno))
      return Sane.STATUS_INVAL
    }
  fclose (fp)
  DBG (3, "load: dlopen()ing `%s'\n", libname)

#ifdef HAVE_DLOPEN
  be.handle = dlopen (libname, mode)
#elif defined(HAVE_SHL_LOAD)
  be.handle = (shl_t) shl_load (libname, mode, 0L)
#elif defined(HAVE_NSLINKMODULE)
  {
    NSObjectFileImage objectfile_img = NULL
    if (NSCreateObjectFileImageFromFile (libname, &objectfile_img)
	== NSObjectFileImageSuccess)
      {
	be.handle = NSLinkModule (objectfile_img, libname, mode)
	NSDestroyObjectFileImage (objectfile_img)
      }
  }
#else
# error "Tried to compile unsupported DLL."
#endif /* HAVE_DLOPEN */
  if (!be.handle)
    {
#ifdef HAVE_DLOPEN
      DBG (1, "load: dlopen() failed (%s)\n", dlerror ())
#elif defined(HAVE_NSLINKMODULE)
      DBG (1, "load: dyld error (%s)\n", dyld_get_error_str ())
#else
      DBG (1, "load: dlopen() failed (%s)\n", strerror (errno))
#endif
      return Sane.STATUS_INVAL
    }

  /* all is dandy---lookup and fill in backend ops: */
  funcname = alloca (strlen (be.name) + 64)
  for (i = 0; i < NUM_OPS; ++i)
    {
      void *(*op) (void)

      sprintf (funcname, "_Sane.%s_%s", be.name, op_name[i])

      /* First try looking up the symbol without a leading underscore. */
#ifdef HAVE_DLOPEN
      op = posix_dlsym (be.handle, funcname + 1)
#elif defined(HAVE_SHL_LOAD)
      shl_findsym ((shl_t *) & (be.handle), funcname + 1, TYPE_UNDEFINED,
		   &op)
#elif defined(HAVE_NSLINKMODULE)
      {
	NSSymbol *nssym = NSLookupSymbolInModule (be.handle, funcname)
	if (!nssym)
	  {
	    DBG (15, "dyld error: %s\n", dyld_get_error_str ())
	  }
	else
	  {
	    op = (void *(*)(void)) NSAddressOfSymbol (nssym)
	  }
      }
#else
# error "Tried to compile unsupported DLL."
#endif /* HAVE_DLOPEN */
      if (op)
	be.op[i] = op
      else
	{
	  /* Try again, with an underscore prepended. */
#ifdef HAVE_DLOPEN
	  op = posix_dlsym (be.handle, funcname)
#elif defined(HAVE_SHL_LOAD)
	  shl_findsym (be.handle, funcname, TYPE_UNDEFINED, &op)
#elif defined(HAVE_NSLINKMODULE)
	  {
	    NSSymbol *nssym = NSLookupSymbolInModule (be.handle, funcname)
	    if (!nssym)
	      {
		DBG (15, "dyld error: %s\n", dyld_get_error_str ())
	      }
	    else
	      {
		op = (void *(*)(void)) NSAddressOfSymbol (nssym)
	      }
	  }
#else
# error "Tried to compile unsupported DLL."
#endif /* HAVE_DLOPEN */
	  if (op)
	    be.op[i] = op
	}
      if (NULL == op)
	DBG (1, "load: unable to find %s\n", funcname)
    }

  return Sane.STATUS_GOOD

# undef PREFIX
# undef POSTFIX
#else /* HAVE_DLL */
  DBG (1,
       "load: ignoring attempt to load `%s'; compiled without dl support\n",
       be.name)
  return Sane.STATUS_UNSUPPORTED
#endif /* HAVE_DLL */
}
#endif /* __BEOS__ */

static Sane.Status
init (struct backend *be)
{
  Sane.Status status
  Int version

  if (!be.loaded)
    {
      status = load (be)
      if (status != Sane.STATUS_GOOD)
	return status
    }

  DBG (3, "init: initializing backend `%s'\n", be.name)

  status = (*(op_init_t)be.op[OP_INIT]) (&version, auth_callback)
  if (status != Sane.STATUS_GOOD)
    return status

  if (Sane.VERSION_MAJOR (version) != Sane.CURRENT_MAJOR)
    {
      DBG (1,
	   "init: backend `%s' has a wrong major version (%d instead of %d)\n",
	   be.name, Sane.VERSION_MAJOR (version), Sane.CURRENT_MAJOR)
      return Sane.STATUS_INVAL
    }
  DBG (4, "init: backend `%s' is version %d.%d.%d\n", be.name,
       Sane.VERSION_MAJOR (version), Sane.VERSION_MINOR (version),
       Sane.VERSION_BUILD (version))

  be.inited = 1

  return Sane.STATUS_GOOD
}


static void
add_alias (const char *line_param)
{
#ifndef __BEOS__
  const char *command
  enum
  { CMD_ALIAS, CMD_HIDE }
  cmd
  const char *oldname, *oldend, *newname
  size_t oldlen, newlen
  struct alias *alias
  char *line

  command = sanei_config_skip_whitespace (line_param)
  if (!*command)
    return

  line = strchr (command, '#')
  if (line)
    *line = '\0'

  line = strpbrk (command, " \t")
  if (!line)
    return
  *line++ = '\0'

  if (strcmp (command, "alias") == 0)
    cmd = CMD_ALIAS
  else if (strcmp (command, "hide") == 0)
    cmd = CMD_HIDE
  else
    return

  newlen = 0
  newname = NULL
  if (cmd == CMD_ALIAS)
    {
      char *newend

      newname = sanei_config_skip_whitespace (line)
      if (!*newname)
	return
      if (*newname == '\"')
	{
	  ++newname
	  newend = strchr (newname, '\"')
	}
      else
	newend = strpbrk (newname, " \t")
      if (!newend)
	return

      newlen = newend - newname
      line = (char *) (newend + 1)
    }

  oldname = sanei_config_skip_whitespace (line)
  if (!*oldname)
    return
  oldend = oldname + strcspn (oldname, " \t")

  oldlen = oldend - oldname

  alias = malloc (sizeof (struct alias))
  if (alias)
    {
      alias.oldname = malloc (oldlen + newlen + 2)
      if (alias.oldname)
	{
	  strncpy (alias.oldname, oldname, oldlen)
	  alias.oldname[oldlen] = '\0'
	  if (cmd == CMD_ALIAS)
	    {
	      alias.newname = alias.oldname + oldlen + 1
	      strncpy (alias.newname, newname, newlen)
	      alias.newname[newlen] = '\0'
	    }
	  else
	    alias.newname = NULL

	  alias.next = first_alias
	  first_alias = alias
	  return
	}
      free (alias)
    }
  return
#endif
}


static void
read_config (const char *conffile)
{
  FILE *fp
  char config_line[PATH_MAX]
  char *backend_name

  fp = sanei_config_open (conffile)
  if (!fp)
    {
      DBG (1, "Sane.init/read_config: Couldn't open config file (%s): %s\n",
           conffile, strerror (errno))
      return; /* don't insist on config file */
    }

  DBG (5, "Sane.init/read_config: reading %s\n", conffile)
  while (sanei_config_read (config_line, sizeof (config_line), fp))
    {
      char *comment
      Sane.String_Const cp

      cp = sanei_config_get_string (config_line, &backend_name)
      /* ignore empty lines */
      if (!backend_name || cp == config_line)
        {
          if (backend_name)
            free (backend_name)
          continue
        }
      /* ignore line comments */
      if (backend_name[0] == '#')
        {
          free (backend_name)
          continue
        }
      /* ignore comments after backend names */
      comment = strchr (backend_name, '#')
      if (comment)
        *comment = '\0'
      add_backend (backend_name, 0)
      free (backend_name)
    }
  fclose (fp)
}

static void
read_dlld (void)
{
  DIR *dlld
  struct dirent *dllconf
  struct stat st
  char dlldir[PATH_MAX]
  char conffile[PATH_MAX + strlen("/") + NAME_MAX]
  size_t len, plen
  const char *dir_list
  char *copy, *next, *dir

  dir_list = sanei_config_get_paths ()
  if (!dir_list)
    {
      DBG(2, "Sane.init/read_dlld: Unable to detect configuration directories\n")
      return
    }

  copy = strdup (dir_list)

  for (next = copy; (dir = strsep (&next, DIR_SEP)) != NULL;)
    {
      snprintf (dlldir, sizeof (dlldir), "%s%s", dir, "/dll.d")

      DBG(4, "Sane.init/read_dlld: attempting to open directory `%s'\n", dlldir)

      dlld = opendir (dlldir)
      if (dlld)
	{
	  /* length of path to parent dir of dll.d/ */
	  plen = strlen (dir) + 1

	  DBG(3, "Sane.init/read_dlld: using config directory `%s'\n", dlldir)
	  break
	}
    }
  free (copy)

  if (dlld == NULL)
    {
      DBG (1, "Sane.init/read_dlld: opendir failed: %s\n",
           strerror (errno))
      return
    }

  while ((dllconf = readdir (dlld)) != NULL)
    {
      /* dotfile (or directory) */
      if (dllconf.d_name[0] == '.')
        continue

      len = strlen (dllconf.d_name)

      /* backup files */
      if ((dllconf.d_name[len-1] == '~')
          || (dllconf.d_name[len-1] == '#'))
        continue

      snprintf (conffile, sizeof(conffile), "%s/%s", dlldir, dllconf.d_name)

      DBG (5, "Sane.init/read_dlld: considering %s\n", conffile)

      if (stat (conffile, &st) != 0)
        continue

      if (!S_ISREG (st.st_mode))
        continue

      /* expects a path relative to PATH_Sane.CONFIG_DIR */
      read_config (conffile+plen)
    }

  closedir (dlld)

  DBG (5, "Sane.init/read_dlld: done.\n")
}

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback authorize)
{
#ifndef __BEOS__
  char config_line[PATH_MAX]
  size_t len
  FILE *fp
  var i: Int
#else
  DIR *dir
  struct dirent *dirent
  char path[1024]
  directory_which which[3] = { B_USER_ADDONS_DIRECTORY, B_COMMON_ADDONS_DIRECTORY, B_BEOS_ADDONS_DIRECTORY ]
  var i: Int
#endif

  DBG_INIT ()

  auth_callback = authorize

  DBG (1, "Sane.init: SANE dll backend version %s from %s\n", DLL_VERSION,
       PACKAGE_STRING)

#ifndef __BEOS__
  /* chain preloaded backends together: */
  for (i = 0; i < NELEMS (preloaded_backends); ++i)
    {
      if (!preloaded_backends[i].name)
	continue
      DBG (3, "Sane.init: adding backend `%s' (preloaded)\n", preloaded_backends[i].name)
      preloaded_backends[i].next = first_backend
      first_backend = &preloaded_backends[i]
    }

  /* Return the version number of the sane-backends package to allow
     the frontend to print them. This is done only for net and dll,
     because these backends are usually called by the frontend. */
  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.DLL_V_MAJOR, Sane.DLL_V_MINOR,
				       Sane.DLL_V_BUILD)

  /*
   * Read dll.conf & dll.d
   * Read dll.d first, so that the extras backends will be tried last
   */
  read_dlld ()
  read_config (DLL_CONFIG_FILE)

  fp = sanei_config_open (DLL_ALIASES_FILE)
  if (!fp)
    return Sane.STATUS_GOOD;	/* don't insist on aliases file */

  DBG (5, "Sane.init: reading %s\n", DLL_ALIASES_FILE)
  while (sanei_config_read (config_line, sizeof (config_line), fp))
    {
      if (config_line[0] == '#')	/* ignore line comments */
	continue

      len = strlen (config_line)
      if (!len)
	continue;		/* ignore empty lines */

      add_alias (config_line)
    }
  fclose (fp)

#else
	/* no ugly config files, just get scanners from their ~/config/add-ons/SANE */
	/* look for drivers */
	for (i = 0; i < 3; i++)
	{
		if (find_directory(which[i],0,true,path,1024) < B_OK)
			continue
		strcat(path,"/SANE/")
		dir=opendir(path)
		if(!dir) continue

		while((dirent=readdir(dir)))
		{
			if((strcmp(dirent.d_name,".")==0) || (strcmp(dirent.d_name,"..")==0)) continue
			if((strcmp(dirent.d_name,"dll")==0)) continue
			add_backend(dirent.d_name,0)
		}
		closedir(dir)
	}
#endif /* __BEOS__ */

  return Sane.STATUS_GOOD
}

void
Sane.exit (void)
{
  struct backend *be, *next
  struct alias *alias

  DBG (2, "Sane.exit: exiting\n")

  for (be = first_backend; be; be = next)
    {
      next = be.next
      if (be.loaded)
	{
	  if (be.inited)
	    {
	      DBG (3, "Sane.exit: calling backend `%s's exit function\n",
		   be.name)
	      (*(op_exit_t)be.op[OP_EXIT]) ()
	    }
#ifdef __BEOS__
	  /* use BeOS kernel functions to unload add-ons */
	  if(be.handle) unload_add_on((image_id)be.handle)
#else
#ifdef HAVE_DLL

#ifdef HAVE_DLOPEN
	  if (be.handle)
	    dlclose (be.handle)
#elif defined(HAVE_SHL_LOAD)
	  if (be.handle)
	    shl_unload (be.handle)
#elif defined(HAVE_NSLINKMODULE)
	  if (be.handle)
	    NSUnLinkModule (be.handle, NSUNLINKMODULE_OPTION_NONE
# ifdef __ppc__
			    | NSUNLINKMODULE_OPTION_RESET_LAZY_REFERENCES
# endif
	      )
#else
# error "Tried to compile unsupported DLL."
#endif /* HAVE_DLOPEN */

#endif /* HAVE_DLL */
#endif /* __BEOS__ */
	}
      if (!be.permanent)
	{
	  if (be.name)
	    free ((void *) be.name)
	  free (be)
	}
      else
	{
	  be.inited = 0
	}
    }
  first_backend = 0

  while ((alias = first_alias) != NULL)
    {
      first_alias = first_alias.next
      free (alias.oldname)
      free (alias)
    }

  if (NULL != devlist)
    {				/* Release memory allocated by Sane.get_devices(). */
      var i: Int = 0
      while (devlist[i])
	free (devlist[i++])
      free (devlist)

      devlist = NULL
      devlist_size = 0
      devlist_len = 0
    }
  DBG (3, "Sane.exit: finished\n")
}

/* Note that a call to get_devices() implies that we'll have to load
   all backends.  To avoid this, you can call Sane.open() directly
   (assuming you know the name of the backend/device).  This is
   appropriate for the command-line interface of SANE, for example.
 */
Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool local_only)
{
  const Sane.Device **be_list
  struct backend *be
  Sane.Status status
  char *full_name
  var i: Int, num_devs
  size_t len
#define ASSERT_SPACE(n)                                                    \
  {                                                                        \
    if (devlist_len + (n) > devlist_size)                                  \
      {                                                                    \
        devlist_size += (n) + 15;                                          \
        if (devlist)                                                       \
          devlist = realloc (devlist, devlist_size * sizeof (devlist[0])); \
        else                                                               \
          devlist = malloc (devlist_size * sizeof (devlist[0]));           \
        if (!devlist)                                                      \
          return Sane.STATUS_NO_MEM;                                       \
      }                                                                    \
  }

  DBG (3, "Sane.get_devices\n")

  if (devlist)
    for (i = 0; i < devlist_len; ++i)
      free ((void *) devlist[i])
  devlist_len = 0

  for (be = first_backend; be; be = be.next)
    {
      if (!be.inited)
	if (init (be) != Sane.STATUS_GOOD)
	  continue

      status = (*(op_get_devs_t)be.op[OP_GET_DEVS]) (&be_list, local_only)
      if (status != Sane.STATUS_GOOD || !be_list)
	continue

      /* count the number of devices for this backend: */
      for (num_devs = 0; be_list[num_devs]; ++num_devs)

      ASSERT_SPACE (num_devs)

      for (i = 0; i < num_devs; ++i)
	{
	  Sane.Device *dev
	  char *mem
	  struct alias *alias

	  for (alias = first_alias; alias != NULL; alias = alias.next)
	    {
	      len = strlen (be.name)
	      if (strlen (alias.oldname) <= len)
		continue
	      if (strncmp (alias.oldname, be.name, len) == 0
		  && alias.oldname[len] == ':'
		  && strcmp (&alias.oldname[len + 1], be_list[i]->name) == 0)
		break
	    }

	  if (alias)
	    {
	      if (!alias.newname)	/* hidden device */
		continue

	      len = strlen (alias.newname)
	      mem = malloc (sizeof (*dev) + len + 1)
	      if (!mem)
		return Sane.STATUS_NO_MEM

	      full_name = mem + sizeof (*dev)
	      strcpy (full_name, alias.newname)
	    }
	  else
	    {
	      /* create a new device entry with a device name that is the
	         sum of the backend name a colon and the backend's device
	         name: */
	      len = strlen (be.name) + 1 + strlen (be_list[i]->name)
	      mem = malloc (sizeof (*dev) + len + 1)
	      if (!mem)
		return Sane.STATUS_NO_MEM

	      full_name = mem + sizeof (*dev)
	      strcpy (full_name, be.name)
	      strcat (full_name, ":")
	      strcat (full_name, be_list[i]->name)
	    }

	  dev = (Sane.Device *) mem
	  dev.name = full_name
	  dev.vendor = be_list[i]->vendor
	  dev.model = be_list[i]->model
	  dev.type = be_list[i]->type

	  devlist[devlist_len++] = dev
	}
    }

  /* terminate device list with NULL entry: */
  ASSERT_SPACE (1)
  devlist[devlist_len++] = 0

  *device_list = (const Sane.Device **) devlist
  DBG (3, "Sane.get_devices: found %d devices\n", devlist_len - 1)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const full_name, Sane.Handle * meta_handle)
{
  char *be_name
  const char *dev_name
  struct meta_scanner *s
  Sane.Handle handle
  struct backend *be
  Sane.Status status
  struct alias *alias

  DBG (3, "Sane.open: trying to open `%s'\n", full_name)

  for (alias = first_alias; alias != NULL; alias = alias.next)
    {
      if (!alias.newname)
	continue
      if (strcmp (alias.newname, full_name) == 0)
	{
	  full_name = alias.oldname
	  break
	}
    }

  dev_name = strchr (full_name, ':')

  Int is_fakeusb = 0, is_fakeusbdev = 0, is_fakeusbout = 0

  if (dev_name)
    {
      is_fakeusb = strncmp(full_name, "fakeusb", dev_name - full_name) == 0 &&
          dev_name - full_name == 7
      is_fakeusbdev = strncmp(full_name, "fakeusbdev", dev_name - full_name) == 0 &&
          dev_name - full_name == 10
      is_fakeusbout = strncmp(full_name, "fakeusbout", dev_name - full_name) == 0 &&
          dev_name - full_name == 10
    }

  if (is_fakeusb || is_fakeusbdev)
    {
      ++dev_name; // skip colon
      status = sanei_usb_testing_enable_replay(dev_name, is_fakeusbdev)
      if (status != Sane.STATUS_GOOD)
        return status

      be_name = sanei_usb_testing_get_backend()
      if (be_name == NULL)
        {
          DBG (0, "%s: unknown backend for testing\n", __func__)
          return Sane.STATUS_ACCESS_DENIED
        }
    }
  else
    {
      char* fakeusbout_path = NULL
      if (is_fakeusbout)
      {
        ++dev_name; // skip colon

        const char* path_end = strchr(dev_name, ':')
        if (path_end == NULL)
          {
            DBG (0, "%s: the device name does not contain path\n", __func__)
            return Sane.STATUS_INVAL
          }
        fakeusbout_path = strndup(dev_name, path_end - dev_name)

        full_name = path_end + 1; // skip colon
        dev_name = strchr(full_name, ':')
      }

      if (dev_name)
        {
          be_name = strndup(full_name, dev_name - full_name)
          ++dev_name;		/* skip colon */
        }
      else
        {
          /* if no colon interpret full_name as the backend name; an empty
             backend device name will cause us to open the first device of
             that backend.  */
          be_name = strdup(full_name)
          dev_name = ""
        }

      if (is_fakeusbout)
        {
          status = sanei_usb_testing_enable_record(fakeusbout_path, be_name)
          free(fakeusbout_path)
          if (status != Sane.STATUS_GOOD)
            return status
        }
    }

  if (!be_name)
    return Sane.STATUS_NO_MEM

  if (!be_name[0])
    be = first_backend
  else
    for (be = first_backend; be; be = be.next)
      if (strcmp (be.name, be_name) == 0)
	break

  if (!be)
    {
      status = add_backend (be_name, &be)
      if (status != Sane.STATUS_GOOD)
        {
          free(be_name)
          return status
        }
    }
  free(be_name)

  if (!be.inited)
    {
      status = init (be)
      if (status != Sane.STATUS_GOOD)
	return status
    }

  status = (*(op_open_t)be.op[OP_OPEN]) (dev_name, &handle)
  if (status != Sane.STATUS_GOOD)
    return status

  s = calloc (1, sizeof (*s))
  if (!s)
    return Sane.STATUS_NO_MEM

  s.be = be
  s.handle = handle
  *meta_handle = s

  DBG (3, "Sane.open: open successful\n")
  return Sane.STATUS_GOOD
}

void
Sane.close (Sane.Handle handle)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.close(handle=%p)\n", handle)
  (*(op_close_t)s.be.op[OP_CLOSE]) (s.handle)
  free (s)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.get_option_descriptor(handle=%p,option=%d)\n", handle,
       option)
  return (*(op_get_option_desc_t)s.be.op[OP_GET_OPTION_DESC]) (s.handle, option)
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *value, Sane.Word * info)
{
  struct meta_scanner *s = handle

  DBG (3,
       "Sane.control_option(handle=%p,option=%d,action=%d,value=%p,info=%p)\n",
       handle, option, action, value, (void *) info)
  return (*(op_ctl_option_t)s.be.op[OP_CTL_OPTION]) (s.handle, option, action, value,
					     info)
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.get_parameters(handle=%p,params=%p)\n", handle, (void *) params)
  return (*(op_get_params_t)s.be.op[OP_GET_PARAMS]) (s.handle, params)
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.start(handle=%p)\n", handle)
  return (*(op_start_t)s.be.op[OP_START]) (s.handle)
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * data, Int max_length,
	   Int * length)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.read(handle=%p,data=%p,maxlen=%d,lenp=%p)\n",
       handle, data, max_length, (void *) length)
  return (*(op_read_t)s.be.op[OP_READ]) (s.handle, data, max_length, length)
}

void
Sane.cancel (Sane.Handle handle)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.cancel(handle=%p)\n", handle)
  (*(op_cancel_t)s.be.op[OP_CANCEL]) (s.handle)
}

Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.set_io_mode(handle=%p,nonblocking=%d)\n", handle,
       non_blocking)
  return (*(op_set_io_mode_t)s.be.op[OP_SET_IO_MODE]) (s.handle, non_blocking)
}

Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int * fd)
{
  struct meta_scanner *s = handle

  DBG (3, "Sane.get_select_fd(handle=%p,fdp=%p)\n", handle, (void *) fd)
  return (*(op_get_select_fd_t)s.be.op[OP_GET_SELECT_FD]) (s.handle, fd)
}
