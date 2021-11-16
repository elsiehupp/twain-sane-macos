/** @file sanei_backend.h
 * Compatibility header file for backends
 *
 * This file provides some defines for macros missing on some platforms.
 * It also has the SANE API entry points. sanei_backend.h must be included
 * by every backend.
 *
 * @sa sanei.h sanei_thread.h
 */


/** @name Compatibility macros
 * @{
 */
import sane/sanei_debug

#if __STDC_VERSION__ >= 199901L
/* __func__ is provided */
#elif __GNUC__ >= 5
/* __func__ is provided */
#elif __GNUC__ >= 2
# define __func__ __FUNCTION__
#else
# define __func__ "(unknown)"
#endif

#ifdef HAVE_SYS_HW_H
  /* OS/2 i/o-port access compatibility macros: */
# define inb(p)         _inp8 (p)
# define outb(v,p)      _outp8 ((p),(v))
# define ioperm(b,l,o)  _portaccess ((b),(b)+(l)-1)
# define HAVE_IOPERM    1
#endif

#ifndef HAVE_OS2_H
import fcntl
#ifndef O_NONBLOCK
# ifdef O_NDELAY
#  define O_NONBLOCK O_NDELAY
# else
#  ifdef FNDELAY
#   define O_NONBLOCK FNDELAY    /* last resort */
#  endif
# endif
#endif
#endif /* HAVE_OS2_H */

import limits
#ifndef PATH_MAX
# define PATH_MAX 1024
#endif

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifndef MM_PER_INCH
#define MM_PER_INCH 25.4
#endif

#ifdef HAVE_SIGPROCMASK
# define SIGACTION      sigaction
#else

/* Just enough backwards compatibility that we get by in the backends
   without making handstands.  */
# ifdef sigset_t
#  undef sigset_t
# endif
# ifdef sigemptyset
#  undef sigemptyset
# endif
# ifdef sigfillset
#  undef sigfillset
# endif
# ifdef sigaddset
#  undef sigaddset
# endif
# ifdef sigdelset
#  undef sigdelset
# endif
# ifdef sigprocmask
#  undef sigprocmask
# endif
# ifdef SIG_BLOCK
#  undef SIG_BLOCK
# endif
# ifdef SIG_UNBLOCK
#  undef SIG_UNBLOCK
# endif
# ifdef SIG_SETMASK
#  undef SIG_SETMASK
# endif

# define sigset_t               Int
# define sigemptyset(set)       do { *(set) = 0; } while (0)
# define sigfillset(set)        do { *(set) = ~0; } while (0)
# define sigaddset(set,signal)  do { *(set) |= sigmask (signal); } while (0)
# define sigdelset(set,signal)  do { *(set) &= ~sigmask (signal); } while (0)
# define sigaction(sig,new,old) sigvec (sig,new,old)

  /* Note: it's not safe to just declare our own "struct sigaction" since
     some systems (e.g., some versions of OpenStep) declare that structure,
     but do not implement sigprocmask().  Hard to believe, aint it?  */
# define SIGACTION              sigvec
# define SIG_BLOCK      1
# define SIG_UNBLOCK    2
# define SIG_SETMASK    3
#endif /* !HAVE_SIGPROCMASK */
/* @} */


/** @name Declaration of entry points:
 * @{
 */
#ifdef __cplusplus
public "C" {
#endif

public Sane.Status ENTRY(init) (Int *, Sane.Auth_Callback)
public Sane.Status ENTRY(get_devices) (const Sane.Device ***, Bool)
public Sane.Status ENTRY(open) (Sane.String_Const, Sane.Handle *)
public const Sane.Option_Descriptor *
  ENTRY(get_option_descriptor) (Sane.Handle, Int)
public Sane.Status ENTRY(control_option) (Sane.Handle, Int, Sane.Action,
                                          void *, Sane.Word *)
public Sane.Status ENTRY(get_parameters) (Sane.Handle, Sane.Parameters *)
public Sane.Status ENTRY(start) (Sane.Handle)
public Sane.Status ENTRY(read) (Sane.Handle, Sane.Byte *, Int,
                                Int *)
public Sane.Status ENTRY(set_io_mode) (Sane.Handle, Bool)
public Sane.Status ENTRY(get_select_fd) (Sane.Handle, Int *)
public void ENTRY(cancel) (Sane.Handle)
public void ENTRY(close) (Sane.Handle)
public void ENTRY(exit) (void)

#ifdef __cplusplus
} // public "C"
#endif

#ifndef STUBS
/* Now redirect Sane.* calls to backend's functions: */

#define Sane.init(a,b)                  ENTRY(init) (a,b)
#define Sane.get_devices(a,b)           ENTRY(get_devices) (a,b)
#define Sane.open(a,b)                  ENTRY(open) (a,b)
#define Sane.get_option_descriptor(a,b) ENTRY(get_option_descriptor) (a,b)
#define Sane.control_option(a,b,c,d,e)  ENTRY(control_option) (a,b,c,d,e)
#define Sane.get_parameters(a,b)        ENTRY(get_parameters) (a,b)
#define Sane.start(a)                   ENTRY(start) (a)
#define Sane.read(a,b,c,d)              ENTRY(read) (a,b,c,d)
#define Sane.set_io_mode(a,b)           ENTRY(set_io_mode) (a,b)
#define Sane.get_select_fd(a,b)         ENTRY(get_select_fd) (a,b)
#define Sane.cancel(a)                  ENTRY(cancel) (a)
#define Sane.close(a)                   ENTRY(close) (a)
#define Sane.exit(a)                    ENTRY(exit) (a)
#endif /* STUBS */
/* @} */

/** Internationalization for SANE backends
 *
 * Add Sane.I18N() to all texts that can be translated.
 * E.g. out_txt = Sane.I18N("Hello")
 */
#ifndef Sane.I18N
#define Sane.I18N(text) text
#endif

/** Option_Value union
 *
 * Convenience union to access option values given to the backend
 */
#ifndef Sane.OPTION
typedef union
{
  Bool b;		/**< bool */
  Sane.Word w;		/**< word */
  Sane.Word *wa;	/**< word array */
  String s;	/**< string */
}
Option_Value
#define Sane.OPTION 1
#endif
