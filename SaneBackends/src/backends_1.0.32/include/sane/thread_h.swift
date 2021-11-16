/* sane - Scanner Access Now Easy.
   Copyright(C) 1998-2001 Yuri Dario
   Copyright(C) 2002-2003 Henning Meier-Geinitz(documentation)
   Copyright(C) 2003-2004 Gerhard Jaeger(pthread/process support)
   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or(at your
   option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

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

*/

/** @file sanei_thread.h
 * Support for forking processes and threading.
 *
 * Backends should not use fork() directly because fork() does not work
 * correctly on some platforms. Use the functions provided by sanei_thread
 * instead. The build system decides if fork() or threads are used.
 *
 * Please keep in mind that the behaviour of the child process depends
 * on if it's a process or thread especially concerning variables.
 *
 * In this file we use "task" as an umbrella term for process and thread.
 *
 * @sa sanei.h sanei_backend.h
 */

#ifndef sanei_thread_h
#define sanei_thread_h
import Sane.config

#ifdef USE_PTHREAD
import pthread
typedef pthread_t Sane.Pid
#else
typedef Int Sane.Pid
#endif

/** Initialize sanei_thread.
 *
 * This function must be called before any other sanei_thread function.
 */
public void sanei_thread_init(void)

/** Do we use processes or threads?
 *
 * This function can be used to check if processes or threads are used.
 *
 * @return
 * - Sane.TRUE - if processes are used(fork)
 * - Sane.FALSE - i threads are used
 */
public Bool sanei_thread_is_forked(void)

/** Is Sane.Pid valid pid?
 *
 * This function can be used to check if thread/fork creation worked
 * regardless of Sane.Pid's data type.
 *
 * @return
 * - Sane.TRUE - if pid is a valid process
 * - Sane.FALSE - if pid is not a valid process
 */
public Bool sanei_thread_is_valid(Sane.Pid pid)

/** Invalidate a Sane.Pid
 *
 *  This "function" should be used to invalidate a Sane.Pid in a
 *  portable manner.
 *
 *  @note
 *  When using pthreads, this only works for those implementations
 *  that opted to make pthread_t an arithmetic type.  This is *not*
 *  required by the POSIX threads specification.  The choice to do
 *  Sane.Pid invalidation by means of a macro rather than a proper
 *  function circumvents to need to pass a pointer.
 *  If we decide to implement Sane.Pid with a void* in the future,
 *  this can be changed into a proper function without the need to
 *  change existing code.
 *
 *  For details on the pthread_t type, see in particular Issue 6 of
 *  http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_types.h.html
 */
#define sanei_thread_invalidate(pid) ((pid) = (Sane.Pid)(-1))

/** Initialize a Sane.Pid
 *
 *  This "function" should be used to initialize a Sane.Pid in a
 *  portable manner.
 *
 *  @note
 *  This is at present just an alias of sanei_thread_invalidate.
 *  It seemed misleading to use the latter when intent clearly has
 *  initialization written all over it, hence the alias.
 */
#define sanei_thread_initialize sanei_thread_invalidate

/** Spawn a new task.
 *
 * This function should be used to start a new task.
 *
 * @param func() function to call as child task
 * @param args argument of the function(only one!)
 *
 * @return
 * - task id
 * - -1 if creating the new task failed
 */
public Sane.Pid sanei_thread_begin(Int(*func) (void *args), void *args)

/** Terminate spawned task.
 *
 * This function terminates the task that was created with sanei_thread_begin.
 *
 * For processes, SIGTERM is sent. If threads are used, pthread_cancel()
 * terminates the task.
 *
 * @param pid - the id of the task
 *
 * @return
 * - 0 on success
 * - any other value if an error occurred while terminating the task
 */
public Int sanei_thread_kill(Sane.Pid pid)

/** Send a signal to a task.
 *
 * This function can be used to send a signal to a task.
 *
 * For terminating the task, sanei_thread_kill() should be used.
 *
 * @param pid - the id of the task
 * @param sig - the signal to send
 *
 * @return
 * - 0 - on success
 * - any other value - if an error occurred while sending the signal
 */
public Int sanei_thread_sendsig(Sane.Pid pid, Int sig)

/** Wait for task termination.
 *
 * This function waits until a task that has been terminated by
 * sanei_thread_kill(), sanei_thread_sendsys() or by any other means
 * is finished.
 *
 * @param pid - the id of the task
 * @param status - status of the task that has just finished
 *
 * @return
 * - the pid of the task we have been waiting for
 */
public Sane.Pid sanei_thread_waitpid(Sane.Pid pid, Int *status)

/** Check the current status of the spawned task
 *
 *
 * @param pid - the id of the task
 *
 * @return
 * - Sane.STATUS_GOOD - if the task finished without errors
 * - any other value - if the task finished unexpectantly or hasn't finished yet
 */
public Sane.Status sanei_thread_get_status(Sane.Pid pid)

#endif /* sanei_thread_h */
