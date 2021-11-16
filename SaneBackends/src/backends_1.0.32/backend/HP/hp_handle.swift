/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 Geoffrey T. Dairiki
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

   This file is part of a SANE backend for HP Scanners supporting
   HP Scanner Control Language(SCL).
*/

#ifndef HP_HANDLE_INCLUDED
#define HP_HANDLE_INCLUDED
import hp

HpHandle sanei_hp_handle_new(HpDevice dev)

void sanei_hp_handle_destroy(HpHandle this)
const Sane.Option_Descriptor * sanei_hp_handle_saneoption(HpHandle this,
                         Int optnum)
Sane.Status sanei_hp_handle_control(HpHandle this, Int optnum,
                         Sane.Action action, void *valp, Int *info)
Sane.Status sanei_hp_handle_getParameters(HpHandle this,
                         Sane.Parameters *params)
Sane.Status sanei_hp_handle_startScan(HpHandle this)
Sane.Status sanei_hp_handle_read(HpHandle this, void * buf, size_t *lengthp)
void        sanei_hp_handle_cancel(HpHandle this)
Sane.Status sanei_hp_handle_setNonblocking(HpHandle this,
                         hp_bool_t non_blocking)
Sane.Status sanei_hp_handle_getPipefd(HpHandle this, Int *fd)

#endif /*  HP_HANDLE_INCLUDED */


/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 Geoffrey T. Dairiki
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

   This file is part of a SANE backend for HP Scanners supporting
   HP Scanner Control Language(SCL).
*/

/* #define STUBS
public Int sanei_debug_hp; */
#define DEBUG_DECLARE_ONLY
import Sane.config

#ifdef HAVE_UNISTD_H
import unistd
#endif
import string
import signal
import ../include/lassert
import errno
import fcntl
import sys/wait

import hp-handle

import Sane.sanei_backend
import Sane.sanei_thread

import hp-device
import hp-option
import hp-accessor
import hp-scsi
import hp-scl

struct hp_handle_s
{
    HpData		data
    HpDevice		dev
    Sane.Parameters	scan_params

    Sane.Pid		reader_pid
    Int			child_forked; /* Flag if we used fork() or not */
    size_t		bytes_left
    Int			pipe_read_fd
    sigset_t            sig_set

    sig_atomic_t	cancelled

    /* These data are used by the child */
    HpScsi      scsi
    HpProcessData procdata
    Int			pipe_write_fd
]


static hp_bool_t
hp_handle_isScanning(HpHandle this)
{
  return this.reader_pid != 0
}

/*
 * reader thread. Used when threads are used
 */
static Int
reader_thread(void *data)
{
  struct hp_handle_s *this = (struct hp_handle_s *) data
  struct SIGACTION	act
  Sane.Status status

  DBG(1, "reader_thread: thread started\n"
   "  parameters: scsi = 0x%08lx, pipe_write_fd = %d\n",
          (long) this.scsi, this.pipe_write_fd)

  memset(&act, 0, sizeof(act))
  sigaction(SIGTERM, &act, 0)

  DBG(1, "Starting sanei_hp_scsi_pipeout()\n")
  status = sanei_hp_scsi_pipeout(this.scsi, this.pipe_write_fd,
                                  &(this.procdata))
  DBG(1, "sanei_hp_scsi_pipeout finished with %s\n", Sane.strstatus(status))

  close(this.pipe_write_fd)
  this.pipe_write_fd = -1
  sanei_hp_scsi_destroy(this.scsi, 0)
  return status
}

/*
 * reader process. Used when forking child.
 */
static Int
reader_process(void *data)
{
  struct hp_handle_s *this = (struct hp_handle_s *) data
  struct SIGACTION	sa
  Sane.Status status

  /* Here we are in a forked child. The thread will not come up to here. */
  /* Forked child must close read end of pipe */
  close(this.pipe_read_fd)
  this.pipe_read_fd = -1

  memset(&sa, 0, sizeof(sa))
  sa.sa_handler = SIG_DFL
  sigaction(SIGTERM, &sa, 0)
  sigdelset(&(this.sig_set), SIGTERM)
  sigprocmask(SIG_SETMASK, &(this.sig_set), 0)

  /* not closing writing end of pipe gives an infinite loop on Digital UNIX */
  status = sanei_hp_scsi_pipeout(this.scsi, this.pipe_write_fd,
                                  &(this.procdata))
  close(this.pipe_write_fd)
  this.pipe_write_fd = -1
  DBG(3,"reader_process: Exiting child(%s)\n",Sane.strstatus(status))
  return(status)
}

static Sane.Status
hp_handle_startReader(HpHandle this, HpScsi scsi)
{
  Int	fds[2]
  sigset_t 		old_set

  assert(this.reader_pid == 0)
  this.cancelled = 0
  this.pipe_write_fd = this.pipe_read_fd = -1

  if(pipe(fds))
      return Sane.STATUS_IO_ERROR

  sigfillset(&(this.sig_set))
  sigprocmask(SIG_BLOCK, &(this.sig_set), &old_set)

  this.scsi = scsi
  this.pipe_write_fd = fds[1]
  this.pipe_read_fd = fds[0]

  /* Will child be forked ? */
  this.child_forked = sanei_thread_is_forked()

  /* Start a thread or fork a child. None of them will return here. */
  /* Returning means to be in the parent or thread/fork failed */
  this.reader_pid = sanei_thread_begin(this.child_forked ? reader_process :
                                         reader_thread, (void *) this)
  if(this.reader_pid != 0)
    {
      /* Here we are in the parent */
      sigprocmask(SIG_SETMASK, &old_set, 0)

      if( this.child_forked )
      { /* After fork(), parent must close writing end of pipe */
        DBG(3, "hp_handle_startReader: parent closes write end of pipe\n")
        close(this.pipe_write_fd)
        this.pipe_write_fd = -1
      }

      if(!sanei_thread_is_valid(this.reader_pid))
	{
          if( !this.child_forked )
          {
            close(this.pipe_write_fd)
            this.pipe_write_fd = -1
          }
	  close(this.pipe_read_fd)
          this.pipe_read_fd = -1

          DBG(1, "hp_handle_startReader: fork() failed\n")

	  return Sane.STATUS_IO_ERROR
	}

      DBG(1, "start_reader: reader process %ld started\n", (long) this.reader_pid)
      return Sane.STATUS_GOOD
    }

  DBG(3, "Unexpected return from sanei_thread_begin()\n")
  return Sane.STATUS_INVAL
}

static Sane.Status
hp_handle_stopScan(HpHandle this)
{
  HpScsi	scsi

  this.cancelled = 0
  this.bytes_left = 0

  if(this.reader_pid)
    {
      Int info
      DBG(3, "hp_handle_stopScan: killing child(%ld)\n", (long) this.reader_pid)
      sanei_thread_kill(this.reader_pid)
      sanei_thread_waitpid(this.reader_pid, &info)

      DBG(1, "hp_handle_stopScan: child %s = %d\n",
	  WIFEXITED(info) ? "exited, status" : "signalled, signal",
	  WIFEXITED(info) ? WEXITSTATUS(info) : WTERMSIG(info))
      close(this.pipe_read_fd)
      this.reader_pid = 0

      if( !FAILED( sanei_hp_scsi_new(&scsi, this.dev.sanedev.name)) )
      {
        if(WIFSIGNALED(info))
	{
	  /*
	  sanei_hp_scl_set(scsi, SCL_CLEAR_ERRORS, 0)
	  sanei_hp_scl_errcheck(scsi)
	  */
	  sanei_hp_scl_reset(scsi)
        }
	sanei_hp_scsi_destroy(scsi,0)
      }
    }
    else
    {
      DBG(3, "hp_handle_stopScan: no pid for child\n")
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
hp_handle_uploadParameters(HpHandle this, HpScsi scsi, Int *scan_depth,
                            hp_bool_t *soft_invert, hp_bool_t *out8)
{
  Sane.Parameters * p	 = &this.scan_params
  Int data_width
  enum hp_device_compat_e compat

  assert(scsi)

  *soft_invert = 0
  *out8 = 0

  p.last_frame = Sane.TRUE
  /* inquire resulting size of image after setting it up */
  RETURN_IF_FAIL( sanei_hp_scl_inquire(scsi, SCL_PIXELS_PER_LINE,
				 &p.pixels_per_line,0,0) )
  RETURN_IF_FAIL( sanei_hp_scl_inquire(scsi, SCL_BYTES_PER_LINE,
				 &p.bytes_per_line,0,0) )
  RETURN_IF_FAIL( sanei_hp_scl_inquire(scsi, SCL_NUMBER_OF_LINES,
				 &p.lines,0,0))
  RETURN_IF_FAIL( sanei_hp_scl_inquire(scsi, SCL_DATA_WIDTH,
                                &data_width,0,0))

  switch(sanei_hp_optset_scanmode(this.dev.options, this.data)) {
  case HP_SCANMODE_LINEART: /* Lineart */
  case HP_SCANMODE_HALFTONE: /* Halftone */
      p.format = Sane.FRAME_GRAY
      p.depth  = 1
      *scan_depth = 1

      /* The OfficeJets don't seem to handle SCL_INVERSE_IMAGE, so we'll
       * have to invert in software. */
      if((sanei_hp_device_probe(&compat, scsi) == Sane.STATUS_GOOD)
          && (compat & HP_COMPAT_OJ_1150C)) {
           *soft_invert=1
      }

      break
  case HP_SCANMODE_GRAYSCALE: /* Grayscale */
      p.format = Sane.FRAME_GRAY
      p.depth  = (data_width > 8) ? 16 : 8
      *scan_depth = data_width

      /* 8 bit output forced ? */
      if( *scan_depth > 8 )
      {
        *out8 = sanei_hp_optset_output_8bit(this.dev.options, this.data)
        DBG(1,"hp_handle_uploadParameters: out8=%d\n", (Int)*out8)
        if(*out8)
        {
          p.depth = 8
          p.bytes_per_line /= 2
        }
      }
      break
  case HP_SCANMODE_COLOR: /* RGB */
      p.format = Sane.FRAME_RGB
      p.depth  = (data_width > 24) ? 16 : 8
      *scan_depth = data_width / 3

      /* 8 bit output forced ? */
      if( *scan_depth > 8 )
      {
        *out8 = sanei_hp_optset_output_8bit(this.dev.options, this.data)
        DBG(1,"hp_handle_uploadParameters: out8=%d\n", (Int)*out8)
        if(*out8)
        {
          p.depth = 8
          p.bytes_per_line /= 2
        }
      }
      /* HP PhotoSmart does not invert when depth > 8. Lets do it by software */
      if(   (*scan_depth > 8)
          && (sanei_hp_device_probe(&compat, scsi) == Sane.STATUS_GOOD)
          && (compat & HP_COMPAT_PS) )
        *soft_invert = 1
      DBG(1, "hp_handle_uploadParameters: data width %d\n", data_width)
      break
  default:
      assert(!"Aack")
      return Sane.STATUS_INVAL
  }

  return Sane.STATUS_GOOD
}



HpHandle
sanei_hp_handle_new(HpDevice dev)
{
  HpHandle new	= sanei_hp_allocz(sizeof(*new))

  if(!new)
      return 0

  if(!(new.data = sanei_hp_data_dup(dev.data)))
    {
      sanei_hp_free(new)
      return 0
    }

  new.dev = dev
  return new
}

void
sanei_hp_handle_destroy(HpHandle this)
{
  HpScsi scsi=0

  DBG(3,"sanei_hp_handle_destroy: stop scan\n")

  hp_handle_stopScan(this)

  if(sanei_hp_scsi_new(&scsi,this.dev.sanedev.name)==Sane.STATUS_GOOD &&
      scsi) {
	sanei_hp_scsi_destroy(scsi,1)
  }

  sanei_hp_data_destroy(this.data)
  sanei_hp_free(this)
}

const Sane.Option_Descriptor *
sanei_hp_handle_saneoption(HpHandle this, Int optnum)
{
  if(this.cancelled)
  {
    DBG(1, "sanei_hp_handle_saneoption: cancelled. Stop scan\n")
    hp_handle_stopScan(this)
  }
  return sanei_hp_optset_saneoption(this.dev.options, this.data, optnum)
}

Sane.Status
sanei_hp_handle_control(HpHandle this, Int optnum,
		  Sane.Action action, void *valp, Int *info)
{
  Sane.Status status
  HpScsi  scsi
  hp_bool_t immediate

  if(this.cancelled)
  {
    DBG(1, "sanei_hp_handle_control: cancelled. Stop scan\n")
    RETURN_IF_FAIL( hp_handle_stopScan(this) )
  }

  if(hp_handle_isScanning(this))
    return Sane.STATUS_DEVICE_BUSY

  RETURN_IF_FAIL( sanei_hp_scsi_new(&scsi, this.dev.sanedev.name) )

  immediate = sanei_hp_optset_isImmediate(this.dev.options, optnum)

  status = sanei_hp_optset_control(this.dev.options, this.data,
                                   optnum, action, valp, info, scsi,
                                   immediate)
  sanei_hp_scsi_destroy( scsi,0 )

  return status
}

Sane.Status
sanei_hp_handle_getParameters(HpHandle this, Sane.Parameters *params)
{
  Sane.Status   status

  if(!params)
      return Sane.STATUS_GOOD

  if(this.cancelled)
  {
    DBG(1, "sanei_hp_handle_getParameters: cancelled. Stop scan\n")
    RETURN_IF_FAIL( hp_handle_stopScan(this) )
  }

  if(hp_handle_isScanning(this))
    {
      *params = this.scan_params
      return Sane.STATUS_GOOD
    }

  status = sanei_hp_optset_guessParameters(this.dev.options,
                                           this.data, params)
#ifdef INQUIRE_AFTER_SCAN
  /* Photosmart: this gives the correct number of lines when doing
     an update of the SANE parameters right after a preview */
  if(!strcmp("C5100A", this.dev.sanedev.model)) {
      HpScsi        scsi
      Sane.Parameters * p    = &this.scan_params

    if(!FAILED( sanei_hp_scsi_new(&scsi, this.dev.sanedev.name) )) {
      RETURN_IF_FAIL( sanei_hp_scl_inquire(scsi, SCL_NUMBER_OF_LINES,
           &p.lines,0,0))
      sanei_hp_scsi_destroy(scsi,0)
      *params = this.scan_params
    }
  }
#endif
  return status
}

Sane.Status
sanei_hp_handle_startScan(HpHandle this)
{
  Sane.Status	status
  HpScsi	scsi
  HpScl         scl
  HpProcessData *procdata = &(this.procdata)
  Int           adfscan

  /* FIXME: setup preview mode stuff? */

  if(hp_handle_isScanning(this))
  {
      DBG(3,"sanei_hp_handle_startScan: Stop current scan\n")
      RETURN_IF_FAIL( hp_handle_stopScan(this) )
  }

  RETURN_IF_FAIL( sanei_hp_scsi_new(&scsi, this.dev.sanedev.name) )

  status = sanei_hp_optset_download(this.dev.options, this.data, scsi)

  if(!FAILED(status))
     status = hp_handle_uploadParameters(this, scsi,
                                         &(procdata.bits_per_channel),
                                         &(procdata.invert),
                                         &(procdata.out8))

  if(FAILED(status))
    {
      sanei_hp_scsi_destroy(scsi,0)
      return status
    }

  procdata.mirror_vertical =
     sanei_hp_optset_mirror_vert(this.dev.options, this.data, scsi)
  DBG(1, "start: %s to mirror image vertically\n", procdata.mirror_vertical ?
         "Request" : "No request" )

  scl = sanei_hp_optset_scan_type(this.dev.options, this.data)
  adfscan = (scl ==  SCL_ADF_SCAN)

  /* For ADF scan we should check if there is paper available */
  if( adfscan )
  {Int adfstat = 0
   Int can_check_paper = 0
   Int is_flatbed = 0
   Int minval, maxval

    /* For ADF-support, we have three different types of scanners:
     * ScanJet, ScanJet+, IIp, 3p:
     *   scroll feed, no support for inquire paper in ADF, unload document
     *   and preload document
     * IIc, IIcx, 3c, 4c, 6100C, 4p:
     *   flatbed, no support for preload document
     * 5100C, 5200C, 6200C, 6300C:
     *   scroll feed.
     * For all scroll feed types, we use the usual scan window command.
     * For flatbed types, use a sequence of special commands.
     */

    /* Check the IIp group */
    if(   (sanei_hp_device_support_get(this.dev.sanedev.name,
                                       SCL_UNLOAD, &minval, &maxval)
              != Sane.STATUS_GOOD )
        && (sanei_hp_device_support_get(this.dev.sanedev.name,
                                       SCL_CHANGE_DOC, &minval, &maxval)
              != Sane.STATUS_GOOD ) )
    {
      DBG(3, "start: Request for ADF scan without support of unload doc\n")
      DBG(3, "       and change doc. Seems to be something like a IIp.\n")
      DBG(3, "       Use standard scan window command.\n")

      scl = SCL_START_SCAN
      can_check_paper = 0
      is_flatbed = 0
    }
/*
    else if( sanei_hp_device_support_get(this.dev.sanedev.name,
                                       SCL_PRELOAD_ADF, &minval, &maxval)
              != Sane.STATUS_GOOD )
*/
    else if( sanei_hp_is_flatbed_adf(scsi) )
    {
      DBG(3, "start: Request for ADF scan without support of preload doc.\n")
      DBG(3, "       Seems to be a flatbed ADF.\n")
      DBG(3, "       Use ADF scan window command.\n")

      can_check_paper = 1
      is_flatbed = 1
    }
    else
    {
      DBG(3, "start: Request for ADF scan with support of preload doc.\n")
      DBG(3, "       Seems to be a scroll feed ADF.\n")
      DBG(3, "       Use standard scan window command.\n")

      scl = SCL_START_SCAN
      can_check_paper = 1
      is_flatbed = 0
    }

    /* Check if the ADF is ready */
    if(  sanei_hp_scl_inquire(scsi, SCL_ADF_READY, &adfstat, 0, 0)
            != Sane.STATUS_GOOD )
    {
      DBG(1, "start: Error checking if ADF is ready\n")
      sanei_hp_scsi_destroy(scsi,0)
      return Sane.STATUS_UNSUPPORTED
    }

    if( adfstat != 1 )
    {
      DBG(1, "start: ADF is not ready. Finished.\n")
      sanei_hp_scsi_destroy(scsi,0)
      return Sane.STATUS_NO_DOCS
    }

    /* Check paper in ADF */
    if( can_check_paper )
    {
      if(  sanei_hp_scl_inquire(scsi, SCL_ADF_BIN, &adfstat, 0, 0)
              != Sane.STATUS_GOOD )
      {
        DBG(1, "start: Error checking if paper in ADF\n")
        sanei_hp_scsi_destroy(scsi,0)
        return Sane.STATUS_UNSUPPORTED
      }

      if( adfstat != 1 )
      {
        DBG(1, "start: No paper in ADF bin. Finished.\n")
        sanei_hp_scsi_destroy(scsi,0)
        return Sane.STATUS_NO_DOCS
      }

      if( is_flatbed )
      {
        if( sanei_hp_scl_set(scsi, SCL_CHANGE_DOC, 0) != Sane.STATUS_GOOD )
        {
          DBG(1, "start: Error changing document\n")
          sanei_hp_scsi_destroy(scsi,0)
          return Sane.STATUS_UNSUPPORTED
        }
      }
    }
  }

  DBG(1, "start: %s to mirror image vertically\n", procdata.mirror_vertical ?
         "Request" : "No request" )

  this.bytes_left = ( this.scan_params.bytes_per_line
  		       * this.scan_params.lines )

  DBG(1, "start: %d pixels per line, %d bytes per line, %d lines high\n",
      this.scan_params.pixels_per_line, this.scan_params.bytes_per_line,
      this.scan_params.lines)
  procdata.bytes_per_line = (Int)this.scan_params.bytes_per_line
  if(procdata.out8)
  {
    procdata.bytes_per_line *= 2
    DBG(1,"(scanner will send %d bytes per line, 8 bit output forced)\n",
        procdata.bytes_per_line)
  }
  procdata.lines = this.scan_params.lines

  /* Wait for front-panel button push ? */
  status = sanei_hp_optset_start_wait(this.dev.options, this.data)

  if(status)   /* Wait for front button push ? Start scan in reader process */
  {
    procdata.startscan = scl
    status = Sane.STATUS_GOOD
  }
  else
  {
    procdata.startscan = 0
    status = sanei_hp_scl_startScan(scsi, scl)
  }

  if(!FAILED( status ))
  {
      status = hp_handle_startReader(this, scsi)
  }

  /* Close SCSI-connection in forked environment */
  if(this.child_forked)
    sanei_hp_scsi_destroy(scsi,0)

  return status
}


Sane.Status
sanei_hp_handle_read(HpHandle this, void * buf, size_t *lengthp)
{
  ssize_t	nread
  Sane.Status	status

  DBG(3, "sanei_hp_handle_read: trying to read %lu bytes\n",
      (unsigned long) *lengthp)

  if(!hp_handle_isScanning(this))
    {
      DBG(1, "sanei_hp_handle_read: not scanning\n")
      return Sane.STATUS_INVAL
    }

  if(this.cancelled)
    {
      DBG(1, "sanei_hp_handle_read: cancelled. Stop scan\n")
      RETURN_IF_FAIL( hp_handle_stopScan(this) )
      return Sane.STATUS_CANCELLED
    }

  if(*lengthp == 0)
      return Sane.STATUS_GOOD

  if(*lengthp > this.bytes_left)
      *lengthp = this.bytes_left

  if((nread = read(this.pipe_read_fd, buf, *lengthp)) < 0)
    {
      *lengthp = 0
      if(errno == EAGAIN)
	  return Sane.STATUS_GOOD
      DBG(1, "sanei_hp_handle_read: read from pipe: %s. Stop scan\n",
          strerror(errno))
      hp_handle_stopScan(this)
      return Sane.STATUS_IO_ERROR
    }

  this.bytes_left -= (*lengthp = nread)

  if(nread > 0)
    {
      DBG(3, "sanei_hp_handle_read: read %lu bytes\n", (unsigned long) nread)
      return Sane.STATUS_GOOD
    }

  DBG(1, "sanei_hp_handle_read: EOF from pipe. Stop scan\n")
  status = this.bytes_left ? Sane.STATUS_IO_ERROR : Sane.STATUS_EOF
  RETURN_IF_FAIL( hp_handle_stopScan(this) )

  /* Switch off lamp and check unload after scan */
  if(status == Sane.STATUS_EOF)
  {
    const HpDeviceInfo *hpinfo
    HpScsi scsi

    if( sanei_hp_scsi_new(&scsi, this.dev.sanedev.name) == Sane.STATUS_GOOD )
    {
      hpinfo = sanei_hp_device_info_get( this.dev.sanedev.name )

      if( hpinfo )
      {
        if( hpinfo.unload_after_scan )
          sanei_hp_scl_set(scsi, SCL_UNLOAD, 0)
      }

      sanei_hp_scsi_destroy(scsi,0)
    }
  }
  return status
}

void
sanei_hp_handle_cancel(HpHandle this)
{
  this.cancelled = 1
  /* The OfficeJet K series may not deliver enough data. */
  /* Therefore the read might not return until it is interrupted. */
  DBG(3,"sanei_hp_handle_cancel: compat flags: 0x%04x\n",
      (Int)this.dev.compat)
  if(    (this.reader_pid)
       && (this.dev.compat & HP_COMPAT_OJ_1150C) )
  {
     DBG(3,"sanei_hp_handle_cancel: send SIGTERM to child(%ld)\n",
         (long) this.reader_pid)
     sanei_thread_kill(this.reader_pid)
  }
}

Sane.Status
sanei_hp_handle_setNonblocking(HpHandle this, hp_bool_t non_blocking)
{
  if(!hp_handle_isScanning(this))
      return Sane.STATUS_INVAL

  if(this.cancelled)
    {
      DBG(3,"sanei_hp_handle_setNonblocking: cancelled. Stop scan\n")
      RETURN_IF_FAIL( hp_handle_stopScan(this) )
      return Sane.STATUS_CANCELLED
    }

  if(fcntl(this.pipe_read_fd, F_SETFL, non_blocking ? O_NONBLOCK : 0) < 0)
      return Sane.STATUS_IO_ERROR

  return Sane.STATUS_GOOD
}

Sane.Status
sanei_hp_handle_getPipefd(HpHandle this, Int *fd)
{
  if(! hp_handle_isScanning(this))
      return Sane.STATUS_INVAL

  if(this.cancelled)
    {
      DBG(3,"sanei_hp_handle_getPipefd: cancelled. Stop scan\n")
      RETURN_IF_FAIL( hp_handle_stopScan(this) )
      return Sane.STATUS_CANCELLED
    }

  *fd = this.pipe_read_fd
  return Sane.STATUS_GOOD
}
