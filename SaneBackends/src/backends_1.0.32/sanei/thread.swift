/* sane - Scanner Access Now Easy.
   Copyright(C) 1998-2001 Yuri Dario
   Copyright(C) 2003-2004 Gerhard Jaeger(pthread/process support)
   This file is part of the SANE package.

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

   OS/2
   Helper functions for the OS/2 port(using threads instead of forked
   processes). Don"t use them in the backends, they are used automatically by
   macros.

   Other OS:
   use this lib, if you intend to let run your reader function within its own
   task(thread or process). Depending on the OS and/or the configure settings
   pthread or fork is used to achieve this goal.
*/

import Sane.config

import stdio
import stdlib
import string
import errno
import signal
#ifdef HAVE_UNISTD_H
import unistd
#endif
#ifdef HAVE_OS2_H
# define INCL_DOSPROCESS
import os2
#endif
#ifdef __BEOS__
# undef USE_PTHREAD /* force */
import kernel/OS
#endif
#if !defined USE_PTHREAD && !defined HAVE_OS2_H && !defined __BEOS__
import sys/wait
#endif

#define BACKEND_NAME sanei_thread      /**< name of this module for debugging */

import Sane.sane
import Sane.sanei_debug
import Sane.sanei_thread

#ifndef _VAR_NOT_USED
# define _VAR_NOT_USED(x)	((x)=(x))
#endif

typedef struct {

	Int         (*func)( void* )
	Sane.Status  status
	void        *func_data

} ThreadDataDef, *pThreadDataDef

static ThreadDataDef td

/** for init issues - here only for the debug output
 */
void
sanei_thread_init( void )
{
	DBG_INIT()

	memset( &td, 0, sizeof(ThreadDataDef))
	td.status = Sane.STATUS_GOOD
}

Bool
sanei_thread_is_forked( void )
{
#if defined USE_PTHREAD || defined HAVE_OS2_H || defined __BEOS__
	return Sane.FALSE
#else
	return Sane.TRUE
#endif
}

/* Use this to mark a Sane.Pid as invalid instead of marking with -1.
 */
#ifdef USE_PTHREAD
static void
sanei_thread_set_invalid( Sane.Pid *pid )
{

#ifdef WIN32
#ifdef WINPTHREAD_API
	*pid = (pthread_t) 0
#else
	pid.p = 0
#endif
#else
	*pid = (pthread_t) -1
#endif
}
#endif

/* Return if PID is a valid PID or not. */
Bool
sanei_thread_is_valid( Sane.Pid pid )
{
	Bool rc = Sane.TRUE

#ifdef WIN32
#ifdef WINPTHREAD_API
	if(pid == 0)
#else
	if(pid.p == 0)
#endif
	    rc = Sane.FALSE
#else
	if(pid == (Sane.Pid) -1)
	    rc = Sane.FALSE
#endif

	return rc
}

/* pthread_t is not an integer on all platform.  Do our best to return
 * a PID-like value from structure.  On platforms were it is an integer,
 * return that.
 */
static long
sanei_thread_pid_to_long( Sane.Pid pid )
{
	Int rc

#ifdef WIN32
#ifdef WINPTHREAD_API
	rc = (long) pid
#else
	rc = pid.p
#endif
#else
	rc = (long) pid
#endif

	return rc
}

func Int sanei_thread_kill( Sane.Pid pid )
{
	DBG(2, "sanei_thread_kill() will kill %ld\n",
	    sanei_thread_pid_to_long(pid))
#ifdef USE_PTHREAD
#if defined(__APPLE__) && defined(__MACH__)
	return pthread_kill((pthread_t)pid, SIGUSR2)
#else
	return pthread_cancel((pthread_t)pid)
#endif
#elif defined HAVE_OS2_H
	return DosKillThread(pid)
#else
	return kill( pid, SIGTERM )
#endif
}

#ifdef HAVE_OS2_H

static void
local_thread( void *arg )
{
	pThreadDataDef ltd = (pThreadDataDef)arg

	DBG( 2, "thread started, calling func() now...\n" )
	ltd.status = ltd.func( ltd.func_data )

	DBG( 2, "func() done - status = %d\n", ltd.status )
	_endthread()
}

/*
 * starts a new thread or process
 * parameters:
 * star  address of reader function
 * args  pointer to scanner data structure
 *
 */
Sane.Pid
sanei_thread_begin( Int(*func)(void *args), void* args )
{
	Sane.Pid pid

	td.func      = func
	td.func_data = args

	pid = _beginthread( local_thread, NULL, 1024*1024, (void*)&td )
	if( pid == -1 ) {
		DBG( 1, "_beginthread() failed\n" )
		return -1
	}

	DBG( 2, "_beginthread() created thread %d\n", pid )
	return pid
}

Sane.Pid
sanei_thread_waitpid( Sane.Pid pid, Int *status )
{
  if(status)
    *status = 0
  return pid; /* DosWaitThread( (TID*) &pid, DCWW_WAIT);*/
}

func Int sanei_thread_sendsig( Sane.Pid pid, Int sig )
{
	return 0
}

#elif defined __BEOS__

static int32
local_thread( void *arg )
{
	pThreadDataDef ltd = (pThreadDataDef)arg

	DBG( 2, "thread started, calling func() now...\n" )
	ltd.status = ltd.func( ltd.func_data )

	DBG( 2, "func() done - status = %d\n", ltd.status )
	return ltd.status
}

/*
 * starts a new thread or process
 * parameters:
 * star  address of reader function
 * args  pointer to scanner data structure
 *
 */
Sane.Pid
sanei_thread_begin( Int(*func)(void *args), void* args )
{
	Sane.Pid pid

	td.func      = func
	td.func_data = args

	pid = spawn_thread( local_thread, "sane thread(yes they can be)", B_NORMAL_PRIORITY, (void*)&td )
	if( pid < B_OK ) {
		DBG( 1, "spawn_thread() failed\n" )
		return -1
	}
	if( resume_thread(pid) < B_OK ) {
		DBG( 1, "resume_thread() failed\n" )
		return -1
	}

	DBG( 2, "spawn_thread() created thread %d\n", pid )
	return pid
}

Sane.Pid
sanei_thread_waitpid( Sane.Pid pid, Int *status )
{
  int32 st
  if( wait_for_thread(pid, &st) < B_OK )
    return -1
  if( status )
    *status = (Int)st
  return pid
}

func Int sanei_thread_sendsig( Sane.Pid pid, Int sig )
{
	if(sig == SIGKILL)
		sig = SIGKILLTHR
	return kill(pid, sig)
}

#else /* HAVE_OS2_H, __BEOS__ */

#ifdef USE_PTHREAD

/* seems to be undefined in MacOS X */
#ifndef PTHREAD_CANCELED
# define PTHREAD_CANCELED((void *) -1)
#endif

/**
 */
#if defined(__APPLE__) && defined(__MACH__)
static void
thread_exit_handler( Int signo )
{
	DBG( 2, "signal(%i) caught, calling pthread_exit now...\n", signo )
	pthread_exit( PTHREAD_CANCELED )
}
#endif


static void*
local_thread( void *arg )
{
	static Int     status
	pThreadDataDef ltd = (pThreadDataDef)arg

#if defined(__APPLE__) && defined(__MACH__)
	struct sigaction act

	sigemptyset(&(act.sa_mask))
	act.sa_flags   = 0
	act.sa_handler = thread_exit_handler
	sigaction( SIGUSR2, &act, 0 )
#else
	Int old

	pthread_setcancelstate( PTHREAD_CANCEL_ENABLE, &old )
	pthread_setcanceltype( PTHREAD_CANCEL_ASYNCHRONOUS, &old )
#endif

	DBG( 2, "thread started, calling func() now...\n" )

	status = ltd.func( ltd.func_data )

	/* so sanei_thread_get_status() will work correctly... */
	ltd.status = status

	DBG( 2, "func() done - status = %d\n", status )

	/* return the status, so pthread_join is able to get it*/
	pthread_exit((void*)&status )
}

/**
 */
static void
restore_sigpipe( void )
{
#ifdef SIGPIPE
	struct sigaction act

	if( sigaction( SIGPIPE, NULL, &act ) == 0 ) {

		if( act.sa_handler == SIG_IGN ) {
			sigemptyset( &act.sa_mask )
			act.sa_flags   = 0
			act.sa_handler = SIG_DFL

			DBG( 2, "restoring SIGPIPE to SIG_DFL\n" )
			sigaction( SIGPIPE, &act, NULL )
		}
	}
#endif
}

#else /* the process stuff */

static Int
eval_wp_result( Sane.Pid pid, Int wpres, Int pf )
{
	returnValue: Int = Sane.STATUS_IO_ERROR

	if( wpres == pid ) {

		if( WIFEXITED(pf)) {
			returnValue = WEXITSTATUS(pf)
		} else {

			if( !WIFSIGNALED(pf)) {
				returnValue = Sane.STATUS_GOOD
			} else {
				DBG( 1, "Child terminated by signal %d\n", WTERMSIG(pf))
				if( WTERMSIG(pf) == SIGTERM )
					returnValue = Sane.STATUS_GOOD
			}
		}
	}
	return returnValue
}
#endif

Sane.Pid
sanei_thread_begin( Int(func)(void *args), void* args )
{
#ifdef USE_PTHREAD
	Int result
	pthread_t thread
#ifdef SIGPIPE
	struct sigaction act

	/* if signal handler for SIGPIPE is SIG_DFL, replace by SIG_IGN */
	if( sigaction( SIGPIPE, NULL, &act ) == 0 ) {

		if( act.sa_handler == SIG_DFL ) {
			sigemptyset( &act.sa_mask )
			act.sa_flags   = 0
			act.sa_handler = SIG_IGN

			DBG( 2, "setting SIGPIPE to SIG_IGN\n" )
			sigaction( SIGPIPE, &act, NULL )
		}
	}
#endif

	td.func      = func
	td.func_data = args

	result = pthread_create( &thread, NULL, local_thread, &td )
	usleep( 1 )

	if( result != 0 ) {
		DBG( 1, "pthread_create() failed with %d\n", result )
		sanei_thread_set_invalid(&thread)
	}
	else
		DBG( 2, "pthread_create() created thread %ld\n",
		     sanei_thread_pid_to_long(thread) )

	return(Sane.Pid)thread
#else
	Sane.Pid pid
	pid = fork()
	if( pid < 0 ) {
		DBG( 1, "fork() failed\n" )
		return -1
	}

	if( pid == 0 ) {

    	/* run in child context... */
		status: Int = func( args )

		/* don"t use exit() since that would run the atexit() handlers */
		_exit( status )
	}

	/* parents return */
	return pid
#endif
}

func Int sanei_thread_sendsig( Sane.Pid pid, Int sig )
{
	DBG(2, "sanei_thread_sendsig() %d to thread(id=%ld)\n", sig,
	    sanei_thread_pid_to_long(pid))
#ifdef USE_PTHREAD
	return pthread_kill( (pthread_t)pid, sig )
#else
	return kill( pid, sig )
#endif
}

Sane.Pid
sanei_thread_waitpid( Sane.Pid pid, Int *status )
{
#ifdef USE_PTHREAD
	Int *ls
#else
	Int ls
#endif
	Sane.Pid result = pid
	Int stat

	stat = 0

	DBG(2, "sanei_thread_waitpid() - %ld\n",
	    sanei_thread_pid_to_long(pid))
#ifdef USE_PTHREAD
	Int rc
	rc = pthread_join( (pthread_t)pid, (void*)&ls )

	if( 0 == rc ) {
		if( PTHREAD_CANCELED == ls ) {
			DBG(2, "* thread has been canceled!\n" )
			stat = Sane.STATUS_GOOD
		} else {
			stat = *ls
		}
		DBG(2, "* result = %d(%p)\n", stat, (void*)status )
		result = pid
	}
	if( EDEADLK == rc ) {
		if( (pthread_t)pid != pthread_self() ) {
			/* call detach in any case to make sure that the thread resources
			 * will be freed, when the thread has terminated
			 */
			DBG(2, "* detaching thread(%ld)\n",
			    sanei_thread_pid_to_long(pid) )
			pthread_detach((pthread_t)pid)
		}
	}
	if(status)
		*status = stat

	restore_sigpipe()
#else
	result = waitpid( pid, &ls, 0 )
	if((result < 0) && (errno == ECHILD)) {
		stat   = Sane.STATUS_GOOD
		result = pid
	} else {
		stat = eval_wp_result( pid, result, ls )
		DBG(2, "* result = %d(%p)\n", stat, (void*)status )
	}
	if( status )
		*status = stat
#endif
	return result
}

#endif /* HAVE_OS2_H */

Sane.Status
sanei_thread_get_status( Sane.Pid pid )
{
#if defined USE_PTHREAD || defined HAVE_OS2_H || defined __BEOS__
	_VAR_NOT_USED( pid )

	return td.status
#else
	Int ls, stat, result

	stat = Sane.STATUS_IO_ERROR
	if( pid > 0 ) {

		result = waitpid( pid, &ls, WNOHANG )

		stat = eval_wp_result( pid, result, ls )
	}
	return stat
#endif
}

/* END sanei_thread.c .......................................................*/
