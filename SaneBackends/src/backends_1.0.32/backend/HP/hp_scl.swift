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

#ifndef HP_SCL_INCLUDED
#define HP_SCL_INCLUDED

#define HP_SCL_PACK(id, group, char) \
        ((Sane.Word)(id) << 16 | ((group) & 0xFF) << 8 | ((char) & 0xFF))
#define SCL_INQ_ID(code)		((code) >> 16)
#define SCL_GROUP_CHAR(code)		((char)(((code) >> 8) & 0xFF))
#define SCL_PARAM_CHAR(code)		((char)((code) & 0xFF))

#define HP_SCL_CONTROL(id,g,c)		HP_SCL_PACK(id,g,c)
#define HP_SCL_COMMAND(g,c)		HP_SCL_PACK(0,g,c)
#define HP_SCL_PARAMETER(id)		HP_SCL_PACK(id, 0, 0)
#define HP_SCL_DATA_TYPE(id)		HP_SCL_PACK(id, 1, 0)

#define IS_SCL_CONTROL(scl)	(SCL_INQ_ID(scl) && SCL_PARAM_CHAR(scl))
#define IS_SCL_COMMAND(scl)	(!SCL_INQ_ID(scl) && SCL_PARAM_CHAR(scl))
#define IS_SCL_PARAMETER(scl)	(SCL_INQ_ID(scl) && !SCL_PARAM_CHAR(scl))
#define IS_SCL_DATA_TYPE(scl)	(SCL_GROUP_CHAR(scl) == "\001")

#define SCL_AUTO_BKGRND		HP_SCL_CONTROL(10307, "a", "B")
#define SCL_COMPRESSION		HP_SCL_CONTROL(10308, "a", "C")
#define SCL_DOWNLOAD_TYPE	HP_SCL_CONTROL(10309, "a", "D")
#define SCL_X_SCALE		HP_SCL_CONTROL(10310, "a", "E")
#define SCL_Y_SCALE		HP_SCL_CONTROL(10311, "a", "F")
#define SCL_DATA_WIDTH		HP_SCL_CONTROL(10312, "a", "G")
#define SCL_INVERSE_IMAGE	HP_SCL_CONTROL(10314, "a", "I")
#define SCL_BW_DITHER		HP_SCL_CONTROL(10315, "a", "J")
#define SCL_CONTRAST		HP_SCL_CONTROL(10316, "a", "K")
#define SCL_BRIGHTNESS		HP_SCL_CONTROL(10317, "a", "L")
#define SCL_MIRROR_IMAGE        HP_SCL_CONTROL(10318, "a", "M")
#define SCL_SHARPENING		HP_SCL_CONTROL(10319, "a", "N")
#define SCL_RESERVED1           HP_SCL_CONTROL(10320, "a", "O")
#define SCL_X_RESOLUTION	HP_SCL_CONTROL(10323, "a", "R")
#define SCL_Y_RESOLUTION	HP_SCL_CONTROL(10324, "a", "S")
#define SCL_OUTPUT_DATA_TYPE	HP_SCL_CONTROL(10325, "a", "T")
#define SCL_DOWNLOAD_LENGTH	HP_SCL_CONTROL(10328, "a", "W")
#define SCL_PRELOAD_ADF         HP_SCL_CONTROL(10468, "f", "C")
#define SCL_MEDIA               HP_SCL_CONTROL(10469, "f", "D")
#define SCL_10470               HP_SCL_CONTROL(10470, "f", "E")
#define SCL_LAMPTEST            HP_SCL_CONTROL(10477, "f", "L")
#define SCL_X_EXTENT		HP_SCL_CONTROL(10481, "f", "P")
#define SCL_Y_EXTENT		HP_SCL_CONTROL(10482, "f", "Q")
#define SCL_START_SCAN		HP_SCL_COMMAND("f", "S")
#define SCL_10485               HP_SCL_CONTROL(10485, "f", "T")
#define SCL_10488               HP_SCL_CONTROL(10488, "f", "W")
#define SCL_X_POS		HP_SCL_CONTROL(10489, "f", "X")
#define SCL_Y_POS		HP_SCL_CONTROL(10490, "f", "Y")
#define SCL_XPA_SCAN		HP_SCL_COMMAND("u", "D")
#define SCL_SPEED		HP_SCL_CONTROL(10950, "u", "E")
#define SCL_FILTER		HP_SCL_CONTROL(10951, "u", "F")
#define SCL_10952		HP_SCL_CONTROL(10952, "u", "G")
#define SCL_XPA_DISABLE         HP_SCL_CONTROL(10953, "u", "H")
#define SCL_TONE_MAP		HP_SCL_CONTROL(10956, "u", "K")
#define SCL_CALIBRATE		HP_SCL_COMMAND("u", "R")
#define SCL_ADF_SCAN		HP_SCL_COMMAND("u", "S")
#define SCL_MATRIX		HP_SCL_CONTROL(10965, "u", "T")
#define SCL_UNLOAD		HP_SCL_CONTROL(10966, "u", "U")
#define SCL_10967		HP_SCL_CONTROL(10967, "u", "V")
#define SCL_CHANGE_DOC		HP_SCL_CONTROL(10969, "u", "X")
#define SCL_ADF_BFEED		HP_SCL_CONTROL(10970, "u", "Y")
/* Clear Errors does not follow command syntax Esc*o0E, it is only Esc*oE */
/* #define SCL_CLEAR_ERRORS	HP_SCL_COMMAND("o", "E")  */

#define SCL_INQUIRE_PRESENT_VALUE	HP_SCL_COMMAND("s", "R")
#define SCL_INQUIRE_MINIMUM_VALUE	HP_SCL_COMMAND("s", "L")
#define SCL_INQUIRE_MAXIMUM_VALUE	HP_SCL_COMMAND("s", "H")
#define SCL_INQUIRE_DEVICE_PARAMETER	HP_SCL_COMMAND("s", "E")
#define SCL_UPLOAD_BINARY_DATA		HP_SCL_COMMAND("s", "U")

#define SCL_HP_MODEL_1		HP_SCL_PARAMETER(3)
#define SCL_HP_MODEL_2		HP_SCL_PARAMETER(10)
#define SCL_HP_MODEL_3		HP_SCL_PARAMETER(9)
#define SCL_HP_MODEL_4		HP_SCL_PARAMETER(11)
#define SCL_HP_MODEL_5		HP_SCL_PARAMETER(12)
#define SCL_HP_MODEL_6		HP_SCL_PARAMETER(14)
#define SCL_HP_MODEL_8		HP_SCL_PARAMETER(15)
#define SCL_HP_MODEL_9		HP_SCL_PARAMETER(16)
#define SCL_HP_MODEL_10		HP_SCL_PARAMETER(17)
#define SCL_HP_MODEL_11		HP_SCL_PARAMETER(18)
#define SCL_HP_MODEL_12		HP_SCL_PARAMETER(19)
#define SCL_HP_MODEL_14		HP_SCL_PARAMETER(21)
#define SCL_HP_MODEL_16		HP_SCL_PARAMETER(31)
#define SCL_HP_MODEL_17		HP_SCL_PARAMETER(32)

#define SCL_ADF_CAPABILITY      HP_SCL_PARAMETER(24)
#define SCL_ADF_BIN		HP_SCL_PARAMETER(25)
#define SCL_ADF_RDY_UNLOAD	HP_SCL_PARAMETER(27)

#define SCL_CURRENT_ERROR_STACK	HP_SCL_PARAMETER(257)
#define SCL_CURRENT_ERROR	HP_SCL_PARAMETER(259)
#define SCL_OLDEST_ERROR	HP_SCL_PARAMETER(261)
#define SCL_PIXELS_PER_LINE	HP_SCL_PARAMETER(1024)
#define SCL_BYTES_PER_LINE	HP_SCL_PARAMETER(1025)
#define SCL_NUMBER_OF_LINES	HP_SCL_PARAMETER(1026)
#define SCL_ADF_READY		HP_SCL_PARAMETER(1027)

#define SCL_DEVPIX_RESOLUTION	HP_SCL_PARAMETER(1028)

#define SCL_AUTO_SPEED		HP_SCL_PARAMETER(1040)

#define SCL_FRONT_BUTTON        HP_SCL_PARAMETER(1044)

#define SCL_PRELOADED		HP_SCL_PARAMETER(1045)

/* The following is not documented */
#define SCL_SECONDARY_SCANDIR   HP_SCL_PARAMETER(1047)

#define SCL_BW8x8DITHER		HP_SCL_DATA_TYPE(0)
#define SCL_8x8TONE_MAP		HP_SCL_DATA_TYPE(1)
#define SCL_8x9MATRIX_COEFF	HP_SCL_DATA_TYPE(2)
#define SCL_8x8DITHER		HP_SCL_DATA_TYPE(3)
#define SCL_CAL_STRIP		HP_SCL_DATA_TYPE(4)
#define SCL_BW16x16DITHER	HP_SCL_DATA_TYPE(5)
#define SCL_10x8TONE_MAP	HP_SCL_DATA_TYPE(6)
#define SCL_10x3MATRIX_COEFF	HP_SCL_DATA_TYPE(8)
#define SCL_10x9MATRIX_COEFF	HP_SCL_DATA_TYPE(9)
#define SCL_7x12TONE_MAP	HP_SCL_DATA_TYPE(10)
#define SCL_BW7x12TONE_MAP	HP_SCL_DATA_TYPE(11)
#define SCL_RGB_GAINS     	HP_SCL_DATA_TYPE(11)
#define SCL_CALIB_MAP     	HP_SCL_DATA_TYPE(14)

#endif /*  HP_SCL_INCLUDED */


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

/*
   Revision 1.15  2008/03/28 14:37:36  kitno-guest
   add usleep to improve usb performance, from jim a t meyering d o t net

   Revision 1.14  2004-10-04 18:09:05  kig-guest
   Rename global function hp_init_openfd to sanei_hp_init_openfd

   Revision 1.13  2004/03/27 13:52:39  kig-guest
   Keep USB-connection open(was problem with Linux 2.6.x)

   Revision 1.12  2003/10/09 19:34:57  kig-guest
   Redo when TEST UNIT READY failed
   Redo when read returns with 0 bytes(non-SCSI only)
*/

/*
#define STUBS
public Int sanei_debug_hp;*/
#define DEBUG_DECLARE_ONLY
import Sane.config
import ../include/lalloca		/* Must be first */

#ifdef HAVE_UNISTD_H
import unistd
#endif
import stdlib
import ctype
import stdio
import string
import errno
import ../include/lassert
import signal
import sys/types
import sys/stat
import fcntl
import Sane.sanei_scsi
import Sane.Sanei_usb
import Sane.sanei_pio

import hp

import Sane.sanei_backend

import hp-option
import hp-scsi
import hp-scl
import hp-device

#define HP_SCSI_INQ_LEN		(36)
#define HP_SCSI_CMD_LEN		(6)
#define HP_SCSI_BUFSIZ	(HP_SCSI_MAX_WRITE + HP_SCSI_CMD_LEN)

#define HP_MAX_OPEN_FD 16
static struct hp_open_fd_s  /* structure to save info about open file descriptor */
{
    char *devname
    HpConnect connect
    Int fd
} asHpOpenFd[HP_MAX_OPEN_FD]


/*
 *
 */
struct hp_scsi_s
{
    Int		fd
    char      * devname

    /* Output buffering */
    hp_byte_t	buf[HP_SCSI_BUFSIZ]
    hp_byte_t *	bufp

    hp_byte_t	inq_data[HP_SCSI_INQ_LEN]
]

#define HP_TMP_BUF_SIZE(1024*4)
#define HP_WR_BUF_SIZE(1024*4)

typedef struct
{
  HpProcessData procdata

  Int outfd
  const unsigned char *map

  unsigned char *image_buf; /* Buffer to store complete image(if req.) */
  unsigned char *image_ptr
  Int image_buf_size

  unsigned char *tmp_buf; /* Buffer for scan data to get even number of bytes */
  Int tmp_buf_size
  Int tmp_buf_len

  unsigned char wr_buf[HP_WR_BUF_SIZE]
  unsigned char *wr_ptr
  Int wr_buf_size
  Int wr_left
} PROCDATA_HANDLE


/* Initialize structure where we remember out open file descriptors */
void
sanei_hp_init_openfd()
{Int iCount
 memset(asHpOpenFd, 0, sizeof(asHpOpenFd))

 for(iCount = 0; iCount < HP_MAX_OPEN_FD; iCount++)
     asHpOpenFd[iCount].fd = -1
}


/* Look if the device is still open */
static Sane.Status
hp_GetOpenDevice(const char *devname, HpConnect connect, Int *pfd)

{Int iCount

 for(iCount = 0; iCount < HP_MAX_OPEN_FD; iCount++)
     {
     if(!asHpOpenFd[iCount].devname) continue
     if(   (strcmp(asHpOpenFd[iCount].devname, devname) == 0)
         && (asHpOpenFd[iCount].connect == connect) )
         {
         if(pfd) *pfd = asHpOpenFd[iCount].fd
         DBG(3, "hp_GetOpenDevice: device %s is open with fd=%d\n", devname,
             asHpOpenFd[iCount].fd)
         return Sane.STATUS_GOOD
         }
     }
 DBG(3, "hp_GetOpenDevice: device %s not open\n", devname)
 return Sane.STATUS_INVAL
}

/* Add an open file descriptor. This also decides */
/* if we keep a connection open or not. */
static Sane.Status
hp_AddOpenDevice(const char *devname, HpConnect connect, Int fd)

{Int iCount, iKeepOpen
 static Int iInitKeepFlags = 1

 /* The default values which connections to keep open or not */
 static Int iKeepOpenSCSI = 0
 static Int iKeepOpenUSB = 1
 static Int iKeepOpenDevice = 0
 static Int iKeepOpenPIO = 0

 if(iInitKeepFlags) /* Change the defaults by environment */
     {char *eptr

     iInitKeepFlags = 0

     eptr = getenv("Sane.HP_KEEPOPEN_SCSI")
     if( (eptr != NULL) && ((*eptr == "0") || (*eptr == "1")) )
         iKeepOpenSCSI = (*eptr == "1")

     eptr = getenv("Sane.HP_KEEPOPEN_USB")
     if( (eptr != NULL) && ((*eptr == "0") || (*eptr == "1")) )
         iKeepOpenUSB = (*eptr == "1")

     eptr = getenv("Sane.HP_KEEPOPEN_DEVICE")
     if( (eptr != NULL) && ((*eptr == "0") || (*eptr == "1")) )
         iKeepOpenDevice = (*eptr == "1")

     eptr = getenv("Sane.HP_KEEPOPEN_PIO")
     if( (eptr != NULL) && ((*eptr == "0") || (*eptr == "1")) )
         iKeepOpenPIO = (*eptr == "1")
     }

 /* Look if we should keep it open or not */
 iKeepOpen = 0
 switch(connect)
     {
     case HP_CONNECT_SCSI: iKeepOpen = iKeepOpenSCSI
                           break
     case HP_CONNECT_PIO : iKeepOpen = iKeepOpenPIO
                           break
     case HP_CONNECT_USB : iKeepOpen = iKeepOpenUSB
                           break
     case HP_CONNECT_DEVICE : iKeepOpen = iKeepOpenDevice
                           break
     case HP_CONNECT_RESERVE:
                           break
     }
 if(!iKeepOpen)
     {
     DBG(3, "hp_AddOpenDevice: %s should not be kept open\n", devname)
     return Sane.STATUS_INVAL
     }

 for(iCount = 0; iCount < HP_MAX_OPEN_FD; iCount++)
     {
     if(!asHpOpenFd[iCount].devname)  /* Is this entry free ? */
         {
         asHpOpenFd[iCount].devname = sanei_hp_strdup(devname)
         if(!asHpOpenFd[iCount].devname) return Sane.STATUS_NO_MEM
         DBG(3, "hp_AddOpenDevice: added device %s with fd=%d\n", devname, fd)
         asHpOpenFd[iCount].connect = connect
         asHpOpenFd[iCount].fd = fd
         return Sane.STATUS_GOOD
         }
     }
 DBG(3, "hp_AddOpenDevice: %s not added\n", devname)
 return Sane.STATUS_NO_MEM
}


/* Check if we have remembered an open file descriptor */
static Sane.Status
hp_IsOpenFd(Int fd, HpConnect connect)

{Int iCount

 for(iCount = 0; iCount < HP_MAX_OPEN_FD; iCount++)
     {
     if(   (asHpOpenFd[iCount].devname != NULL)
         && (asHpOpenFd[iCount].fd == fd)
         && (asHpOpenFd[iCount].connect == connect) )
         {
         DBG(3, "hp_IsOpenFd: %d is open\n", fd)
         return Sane.STATUS_GOOD
         }
     }
 DBG(3, "hp_IsOpenFd: %d not open\n", fd)
 return Sane.STATUS_INVAL
}


static Sane.Status
hp_RemoveOpenFd(Int fd, HpConnect connect)

{Int iCount

 for(iCount = 0; iCount < HP_MAX_OPEN_FD; iCount++)
     {
     if(   (asHpOpenFd[iCount].devname != NULL)
         && (asHpOpenFd[iCount].fd == fd)
         && (asHpOpenFd[iCount].connect == connect) )
         {
         sanei_hp_free(asHpOpenFd[iCount].devname)
         asHpOpenFd[iCount].devname = NULL
         DBG(3, "hp_RemoveOpenFd: removed %d\n", asHpOpenFd[iCount].fd)
         asHpOpenFd[iCount].fd = -1
         return Sane.STATUS_GOOD
         }
     }
 DBG(3, "hp_RemoveOpenFd: %d not removed\n", fd)
 return Sane.STATUS_INVAL
}


static Sane.Status
hp_nonscsi_write(HpScsi this, hp_byte_t *data, size_t len, HpConnect connect)

{Int n = -1
 size_t loc_len
 Sane.Status status = Sane.STATUS_GOOD

 if(len <= 0) return Sane.STATUS_GOOD

 switch(connect)
 {
   case HP_CONNECT_DEVICE:   /* direct device-io */
     n = write(this.fd, data, len)
     break

   case HP_CONNECT_PIO:      /* Use sanepio interface */
     n = sanei_pio_write(this.fd, data, len)
     break

   case HP_CONNECT_USB:      /* Not supported */
     loc_len = len
     status = sanei_usb_write_bulk((Int)this.fd, data, &loc_len)
     n = loc_len
     break

   case HP_CONNECT_RESERVE:
     n = -1
     break

   default:
     n = -1
     break
 }

 if(n == 0) return Sane.STATUS_EOF
 else if(n < 0) return Sane.STATUS_IO_ERROR

 return status
}

static Sane.Status
hp_nonscsi_read(HpScsi this, hp_byte_t *data, size_t *len, HpConnect connect,
  Int __Sane.unused__ isResponse)

{Int n = -1
 static Int retries = -1
 size_t save_len = *len
 Sane.Status status = Sane.STATUS_GOOD

 if(*len <= 0) return Sane.STATUS_GOOD

 if(retries < 0)  /* Read environment */
 {char *eptr = getenv("Sane.HP_RDREDO")

   retries = 1;       /* Set default value */
   if(eptr != NULL)
   {
     if(sscanf(eptr, "%d", &retries) != 1) retries = 1; /* Restore default */
     else if(retries < 0) retries = 0; /* Allow no retries here */
   }
 }

 for(;;) /* Retry on EOF */
 {
   switch(connect)
   {
     case HP_CONNECT_DEVICE:
       n = read(this.fd, data, *len)
       break

     case HP_CONNECT_PIO:
       n = sanei_pio_read(this.fd, data, *len)
       break

     case HP_CONNECT_USB:
       status = sanei_usb_read_bulk((Int)this.fd, (Sane.Byte *)data, len)
       n = *len
       break

     case HP_CONNECT_RESERVE:
       n = -1
       break

     default:
       n = -1
       break
   }
   if((n != 0) || (retries <= 0)) break
   retries--
   usleep(100*1000);  /* sleep 0.1 seconds */
   *len = save_len;    /* Restore value */
 }

 if(n == 0) return Sane.STATUS_EOF
 else if(n < 0) return Sane.STATUS_IO_ERROR

 *len = n
 return status
}

static Sane.Status
hp_nonscsi_open(const char *devname, Int *fd, HpConnect connect)

{Int lfd, flags
 Int dn
 Sane.Status status = Sane.STATUS_INVAL

#ifdef _O_RDWR
 flags = _O_RDWR
#else
 flags = O_RDWR
#endif
#ifdef _O_EXCL
 flags |= _O_EXCL
#else
 flags |= O_EXCL
#endif
#ifdef _O_BINARY
 flags |= _O_BINARY
#endif
#ifdef O_BINARY
 flags |= O_BINARY
#endif

 switch(connect)
 {
   case HP_CONNECT_DEVICE:
     lfd = open(devname, flags)
     if(lfd < 0)
     {
        DBG(1, "hp_nonscsi_open: open device %s failed(%s)\n", devname,
            strerror(errno) )
       status = (errno == EACCES) ? Sane.STATUS_ACCESS_DENIED : Sane.STATUS_INVAL
     }
     else
       status = Sane.STATUS_GOOD
     break

   case HP_CONNECT_PIO:
     status = sanei_pio_open(devname, &lfd)
     break

   case HP_CONNECT_USB:
     DBG(17, "hp_nonscsi_open: open usb with \"%s\"\n", devname)
     status = sanei_usb_open(devname, &dn)
     lfd = (Int)dn
     break

   case HP_CONNECT_RESERVE:
     status = Sane.STATUS_INVAL
     break

   default:
     status = Sane.STATUS_INVAL
     break
 }

 if(status != Sane.STATUS_GOOD)
 {
    DBG(1, "hp_nonscsi_open: open device %s failed\n", devname)
 }
 else
 {
    DBG(17,"hp_nonscsi_open: device %s opened, fd=%d\n", devname, lfd)
 }

 if(fd) *fd = lfd

 return status
}

static void
hp_nonscsi_close(Int fd, HpConnect connect)

{
 switch(connect)
 {
   case HP_CONNECT_DEVICE:
     close(fd)
     break

   case HP_CONNECT_PIO:
     sanei_pio_close(fd)
     break

   case HP_CONNECT_USB:
     sanei_usb_close(fd)
     break

   case HP_CONNECT_RESERVE:
     break

   default:
     break
 }
 DBG(17,"hp_nonscsi_close: closed fd=%d\n", fd)
}

Sane.Status
sanei_hp_nonscsi_new(HpScsi * newp, const char * devname, HpConnect connect)
{
 HpScsi new
 Sane.Status status
 Int iAlreadyOpen = 0

  new = sanei_hp_allocz(sizeof(*new))
  if(!new)
    return Sane.STATUS_NO_MEM

  /* Is the device already open ? */
  if( hp_GetOpenDevice(devname, connect, &new.fd) == Sane.STATUS_GOOD )
  {
    iAlreadyOpen = 1
  }
  else
  {
    status = hp_nonscsi_open(devname, &new.fd, connect)
    if(FAILED(status))
    {
      DBG(1, "nonscsi_new: open failed(%s)\n", Sane.strstatus(status))
      sanei_hp_free(new)
      return Sane.STATUS_IO_ERROR
    }
  }

  /* For SCSI-devices we would have the inquire command here */
  memcpy(new.inq_data, "\003zzzzzzzHP      ------          R000",
          sizeof(new.inq_data))

  new.bufp = new.buf + HP_SCSI_CMD_LEN
  new.devname = sanei_hp_alloc( strlen( devname ) + 1 )
  if( new.devname ) strcpy(new.devname, devname)

  *newp = new

  /* Remember the open device */
  if(!iAlreadyOpen) hp_AddOpenDevice(devname, connect, new.fd)

  return Sane.STATUS_GOOD
}

static void
hp_scsi_close(HpScsi this, Int completely)
{HpConnect connect

 DBG(3, "scsi_close: closing fd %ld\n", (long)this.fd)

 connect = sanei_hp_scsi_get_connect(this)

 if(!completely)  /* May we keep the device open ? */
 {
   if( hp_IsOpenFd(this.fd, connect) == Sane.STATUS_GOOD )
   {
     DBG(3, "scsi_close: not closing. Keep open\n")
     return
   }

 }
 assert(this.fd >= 0)

 if(connect != HP_CONNECT_SCSI)
   hp_nonscsi_close(this.fd, connect)
 else
   sanei_scsi_close(this.fd)

 DBG(3,"scsi_close: really closed\n")

 /* Remove a remembered open device */
 hp_RemoveOpenFd(this.fd, connect)
}


Sane.Status
sanei_hp_scsi_new(HpScsi * newp, const char * devname)
{
  static hp_byte_t inq_cmd[] = { 0x12, 0, 0, 0, HP_SCSI_INQ_LEN, 0]
  static hp_byte_t tur_cmd[] = { 0x00, 0, 0, 0, 0, 0]
  size_t	inq_len		= HP_SCSI_INQ_LEN
  HpScsi	new
  HpConnect     connect
  Sane.Status	status
  Int iAlreadyOpen = 0

  connect = sanei_hp_get_connect(devname)

  if(connect != HP_CONNECT_SCSI)
    return sanei_hp_nonscsi_new(newp, devname, connect)

  new = sanei_hp_allocz(sizeof(*new))
  if(!new)
      return Sane.STATUS_NO_MEM

  /* Is the device still open ? */
  if( hp_GetOpenDevice(devname, connect, &new.fd) == Sane.STATUS_GOOD )
  {
    iAlreadyOpen = 1
  }
  else
  {
    status = sanei_scsi_open(devname, &new.fd, 0, 0)
    if(FAILED(status))
      {
        DBG(1, "scsi_new: open failed(%s)\n", Sane.strstatus(status))
        sanei_hp_free(new)
        return Sane.STATUS_IO_ERROR
      }
  }

  DBG(3, "scsi_inquire: sending INQUIRE\n")
  status = sanei_scsi_cmd(new.fd, inq_cmd, 6, new.inq_data, &inq_len)
  if(FAILED(status))
    {
      DBG(1, "scsi_inquire: inquiry failed: %s\n", Sane.strstatus(status))
      sanei_scsi_close(new.fd)
      sanei_hp_free(new)
      return status
    }

  {char vendor[9], model[17], rev[5]
   memset(vendor, 0, sizeof(vendor))
   memset(model, 0, sizeof(model))
   memset(rev, 0, sizeof(rev))
   memcpy(vendor, new.inq_data + 8, 8)
   memcpy(model, new.inq_data + 16, 16)
   memcpy(rev, new.inq_data + 32, 4)

   DBG(3, "vendor=%s, model=%s, rev=%s\n", vendor, model, rev)
  }

  DBG(3, "scsi_new: sending TEST_UNIT_READY\n")
  status = sanei_scsi_cmd(new.fd, tur_cmd, 6, 0, 0)
  if(FAILED(status))
    {
      DBG(1, "hp_scsi_open: test unit ready failed(%s)\n",
	  Sane.strstatus(status))
      usleep(500*1000); /* Wait 0.5 seconds */
      DBG(3, "scsi_new: sending TEST_UNIT_READY second time\n")
      status = sanei_scsi_cmd(new.fd, tur_cmd, 6, 0, 0)
    }

  if(FAILED(status))
    {
      DBG(1, "hp_scsi_open: test unit ready failed(%s)\n",
	  Sane.strstatus(status))

      sanei_scsi_close(new.fd)
      sanei_hp_free(new)
      return status; /* Fix problem with non-scanner devices */
    }

  new.bufp = new.buf + HP_SCSI_CMD_LEN
  new.devname = sanei_hp_alloc( strlen( devname ) + 1 )
  if( new.devname ) strcpy(new.devname, devname)

  *newp = new

  /* Remember the open device */
  if(!iAlreadyOpen) hp_AddOpenDevice(devname, connect, new.fd)

  return Sane.STATUS_GOOD
}



/* The "completely" parameter was added for OfficeJet support.
 * For JetDirect connections, closing and re-opening the scan
 * channel is very time consuming.  Also, the OfficeJet G85
 * unloads a loaded document in the ADF when the scan channel
 * gets closed.  The solution is to "completely" destroy the
 * connection, including closing and deallocating the PTAL
 * channel, when initially probing the device in hp-device.c,
 * but leave it open while the frontend is actually using the
 * device(from hp-handle.c), and "completely" destroy it when
 * the frontend closes its handle. */
void
sanei_hp_scsi_destroy(HpScsi this,Int completely)
{
  /* Moved to hp_scsi_close():
   * assert(this.fd >= 0)
   * DBG(3, "scsi_close: closing fd %d\n", this.fd)
   */

  hp_scsi_close(this, completely)
  if( this.devname ) sanei_hp_free(this.devname)
  sanei_hp_free(this)
}

hp_byte_t *
sanei_hp_scsi_inq(HpScsi this)
{
  return this.inq_data
}

const char *
sanei_hp_scsi_vendor(HpScsi this)
{
  static char buf[9]
  memcpy(buf, sanei_hp_scsi_inq(this) + 8, 8)
  buf[8] = "\0"
  return buf
}

const char *
sanei_hp_scsi_model(HpScsi this)
{

  static char buf[17]
  memcpy(buf, sanei_hp_scsi_inq(this) + 16, 16)
  buf[16] = "\0"
  return buf
}

const char *
sanei_hp_scsi_devicename(HpScsi this)
{
  return this.devname
}

hp_bool_t
sanei_hp_is_active_xpa(HpScsi scsi)
{HpDeviceInfo *info
 Int model_num

 info = sanei_hp_device_info_get( sanei_hp_scsi_devicename  (scsi) )
 if(info.active_xpa < 0)
 {
   model_num = sanei_hp_get_max_model(scsi)
   info.active_xpa = (model_num >= 17)
   DBG(5,"sanei_hp_is_active_xpa: model=%d, active_xpa=%d\n",
       model_num, info.active_xpa)
 }
 return info.active_xpa
}

func Int sanei_hp_get_max_model(HpScsi scsi)

{HpDeviceInfo *info

 info = sanei_hp_device_info_get( sanei_hp_scsi_devicename  (scsi) )
 if(info.max_model < 0)
 {enum hp_device_compat_e compat
  Int model_num

   if( sanei_hp_device_probe_model( &compat, scsi, &model_num, 0)
            == Sane.STATUS_GOOD )
     info.max_model = model_num
 }
 return info.max_model
}


func Int sanei_hp_is_flatbed_adf(HpScsi scsi)

{Int model = sanei_hp_get_max_model(scsi)

 return((model == 2) || (model == 4) || (model == 5) || (model == 8))
}


HpConnect
sanei_hp_get_connect(const char *devname)

{const HpDeviceInfo *info
 HpConnect connect = HP_CONNECT_SCSI
 Int got_connect_type = 0

 info = sanei_hp_device_info_get(devname)
 if(!info)
 {
   DBG(1, "sanei_hp_get_connect: Could not get info for %s. Assume SCSI\n",
       devname)
   connect = HP_CONNECT_SCSI
 }
 else
 if( !(info.config_is_up) )
 {
   DBG(1, "sanei_hp_get_connect: Config not initialized for %s. Assume SCSI\n",
       devname)
   connect = HP_CONNECT_SCSI
 }
 else
 {
   connect = info.config.connect
   got_connect_type = info.config.got_connect_type
 }

 /* Beware of using a USB-device as a SCSI-device(not 100% perfect) */
 if((connect == HP_CONNECT_SCSI) && !got_connect_type)
 {Int maybe_usb

   maybe_usb = (   strstr(devname, "usb")
                || strstr(devname, "uscanner")
                || strstr(devname, "ugen"))
   if(maybe_usb)
   {static Int print_warning = 1

     if(print_warning)
     {
       print_warning = 0
       DBG(1,"sanei_hp_get_connect: WARNING\n")
       DBG(1,"  Device %s assumed to be SCSI, but device name\n",devname)
       DBG(1,"  looks like USB. Will continue with USB.\n")
       DBG(1,"  If you really want it as SCSI, add the following\n")
       DBG(1,"  to your file .../etc/sane.d/hp.conf:\n")
       DBG(1,"    %s\n", devname)
       DBG(1,"      option connect-scsi\n")
       DBG(1,"  The same warning applies to other device names containing\n")
       DBG(1,"  \"usb\", \"uscanner\" or \"ugen\".\n")
     }
     connect = HP_CONNECT_DEVICE
   }
 }
 return connect
}

HpConnect
sanei_hp_scsi_get_connect(HpScsi this)

{
 return sanei_hp_get_connect(sanei_hp_scsi_devicename(this))
}


static Sane.Status
hp_scsi_flush(HpScsi this)
{
  hp_byte_t *	data	= this.buf + HP_SCSI_CMD_LEN
  size_t 	len 	= this.bufp - data
  HpConnect     connect

  assert(len < HP_SCSI_MAX_WRITE)
  if(len == 0)
      return Sane.STATUS_GOOD

  this.bufp = this.buf

  DBG(16, "scsi_flush: writing %lu bytes:\n", (unsigned long) len)
  DBGDUMP(16, data, len)

  *this.bufp++ = 0x0A
  *this.bufp++ = 0
  *this.bufp++ = len >> 16
  *this.bufp++ = len >> 8
  *this.bufp++ = len
  *this.bufp++ = 0

  connect = sanei_hp_scsi_get_connect(this)
  if(connect == HP_CONNECT_SCSI)
    return sanei_scsi_cmd(this.fd, this.buf, HP_SCSI_CMD_LEN + len, 0, 0)
  else
    return hp_nonscsi_write(this, this.buf+HP_SCSI_CMD_LEN, len, connect)
}

static size_t
hp_scsi_room(HpScsi this)
{
  return this.buf + HP_SCSI_BUFSIZ - this.bufp
}

static Sane.Status
hp_scsi_need(HpScsi this, size_t need)
{
  assert(need < HP_SCSI_MAX_WRITE)

  if(need > hp_scsi_room(this))
      RETURN_IF_FAIL( hp_scsi_flush(this) )

  return Sane.STATUS_GOOD
}

static Sane.Status
hp_scsi_write(HpScsi this, const void *data, size_t len)
{
  if( len < HP_SCSI_MAX_WRITE )
    {
      RETURN_IF_FAIL( hp_scsi_need(this, len) )
      memcpy(this.bufp, data, len)
      this.bufp += len
    }
  else
    {size_t maxwrite = HP_SCSI_MAX_WRITE - 16
     const char *c_data = (const char *)data

      while( len > 0 )
        {
          if( maxwrite > len ) maxwrite = len
          RETURN_IF_FAIL( hp_scsi_write(this, c_data, maxwrite) )
          c_data += maxwrite
          len -= maxwrite
        }
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
hp_scsi_scl(HpScsi this, HpScl scl, Int val)
{
  char	group	= tolower(SCL_GROUP_CHAR(scl))
  char	param	= toupper(SCL_PARAM_CHAR(scl))
  Int	count

  assert(IS_SCL_CONTROL(scl) || IS_SCL_COMMAND(scl))
  assert(isprint(group) && isprint(param))

  RETURN_IF_FAIL( hp_scsi_need(this, 10) )

  /* Don"t try to optimize SCL-commands like using <ESC>*a1b0c5T */
  /* Some scanners have problems with it(e.g. HP Photosmart Photoscanner */
  /* with window position/extent, resolution) */
  count = sprintf((char *)this.bufp, "\033*%c%d%c", group, val, param)
  this.bufp += count

  assert(count > 0 && this.bufp < this.buf + HP_SCSI_BUFSIZ)

  return hp_scsi_flush(this)
}

/* Read it bytewise */
static Sane.Status
hp_scsi_read_slow(HpScsi this, void * dest, size_t *len)
{static hp_byte_t read_cmd[6] = { 0x08, 0, 0, 0, 0, 0 ]
 size_t leftover = *len
 Sane.Status status = Sane.STATUS_GOOD
 unsigned char *start_dest = (unsigned char *)dest
 unsigned char *next_dest = start_dest

 DBG(16, "hp_scsi_read_slow: Start reading %d bytes bytewise\n", (Int)*len)

 while(leftover > 0)  /* Until we got all the bytes */
 {size_t one = 1

   read_cmd[2] = 0
   read_cmd[3] = 0
   read_cmd[4] = 1;   /* Read one byte */

   status = sanei_scsi_cmd(this.fd, read_cmd, sizeof(read_cmd),
                            next_dest, &one)
   if((status != Sane.STATUS_GOOD) || (one != 1))
   {
     DBG(250,"hp_scsi_read_slow: Reading byte %d: status=%s, len=%d\n",
         (Int)(next_dest-start_dest), Sane.strstatus(status), (Int)one)
   }

   if(status != Sane.STATUS_GOOD) break;  /* Finish on error */

   next_dest++
   leftover--
 }

 *len = next_dest-start_dest; /* This is the number of bytes we got */

 DBG(16, "hp_scsi_read_slow: Got %d bytes\n", (Int)*len)

 if((status != Sane.STATUS_GOOD) && (*len > 0))
 {
   DBG(16, "We got some data. Ignore the error \"%s\"\n",
       Sane.strstatus(status))
   status = Sane.STATUS_GOOD
 }
 return status
}

/* The OfficeJets tend to return inquiry responses containing array
 * data in two packets.  The added "isResponse" parameter tells
 * whether we should keep reading until we get
 * a well-formed response.  Naturally, this parameter would be zero
 * when reading scan data. */
static Sane.Status
hp_scsi_read(HpScsi this, void * dest, size_t *len, Int isResponse)
{
  HpConnect connect

  RETURN_IF_FAIL( hp_scsi_flush(this) )

  connect = sanei_hp_scsi_get_connect(this)
  if(connect == HP_CONNECT_SCSI)
  {Int read_bytewise = 0

    if(*len <= 32)   /* Is it a candidate for reading bytewise ? */
    {const HpDeviceInfo *info

      info = sanei_hp_device_info_get(sanei_hp_scsi_devicename(this))
      if((info != NULL) && (info.config_is_up) && info.config.dumb_read)
        read_bytewise = 1
    }

    if( ! read_bytewise )
    {static hp_byte_t read_cmd[6] = { 0x08, 0, 0, 0, 0, 0 ]
      read_cmd[2] = *len >> 16
      read_cmd[3] = *len >> 8
      read_cmd[4] = *len

      RETURN_IF_FAIL( sanei_scsi_cmd(this.fd, read_cmd,
                                      sizeof(read_cmd), dest, len) )
    }
    else
    {
      RETURN_IF_FAIL(hp_scsi_read_slow(this, dest, len))
    }
  }
  else
  {
    RETURN_IF_FAIL( hp_nonscsi_read(this, dest, len, connect, isResponse) )
  }
  DBG(16, "scsi_read:  %lu bytes:\n", (unsigned long) *len)
  DBGDUMP(16, dest, *len)
  return Sane.STATUS_GOOD
}


static Int signal_caught = 0

static void
signal_catcher(Int sig)
{
  DBG(1,"signal_catcher(sig=%d): old signal_caught=%d\n",sig,signal_caught)
  if(!signal_caught)
      signal_caught = sig
}

static void
hp_data_map(register const unsigned char *map, register Int count,
             register unsigned char *data)
{
  if(count <= 0) return
  while(count--)
  {
    *data = map[*data]
    data++
  }
}

static const unsigned char *
hp_get_simulation_map(const char *devname, const HpDeviceInfo *info)
{
 hp_bool_t     sim_gamma, sim_brightness, sim_contrast
 Int           k, ind
 const unsigned char *map = NULL
 static unsigned char map8x8[256]

  sim_gamma = info.simulate.gamma_simulate
  sim_brightness = sanei_hp_device_simulate_get(devname, SCL_BRIGHTNESS)
  sim_contrast = sanei_hp_device_simulate_get(devname, SCL_CONTRAST)

  if( sim_gamma )
  {
    map = &(info.simulate.gamma_map[0])
  }
  else if( sim_brightness && sim_contrast )
  {
    for(k = 0; k < 256; k++)
    {
      ind = info.simulate.contrast_map[k]
      map8x8[k] = info.simulate.brightness_map[ind]
    }
    map = &(map8x8[0])
  }
  else if( sim_brightness )
    map = &(info.simulate.brightness_map[0])
  else if( sim_contrast )
    map = &(info.simulate.contrast_map[0])

  return map
}


/* Check the native byte order on the local machine */
static hp_bool_t
is_lowbyte_first_byteorder(void)

{unsigned short testvar = 1
 unsigned char *testptr = (unsigned char *)&testvar

 if(sizeof(unsigned short) == 2)
   return(testptr[0] == 1)
 else if(sizeof(unsigned short) == 4)
   return((testptr[0] == 1) || (testptr[2] == 1))
 else
   return(   (testptr[0] == 1) || (testptr[2] == 1)
           || (testptr[4] == 1) || (testptr[6] == 1))
}

/* The SANE standard defines that 2-byte data must use the full 16 bit range.
 * Byte order returned by the backend must be native byte order.
 * Scaling to 16 bit and byte order is achieved by hp_scale_to_16bit.
 * for >8 bits data, take the two data bytes and scale their content
 * to the full 16 bit range, using
 *     scaled = unscaled << (newlen - oldlen) +
 *              unscaled >> (oldlen - (newlen - oldlen)),
 * with newlen=16 and oldlen the original bit depth.
 */
static void
hp_scale_to_16bit(Int count, register unsigned char *data, Int depth,
                  hp_bool_t invert)
{
    register unsigned Int tmp
    register unsigned Int mask
    register hp_bool_t lowbyte_first = is_lowbyte_first_byteorder()
    unsigned Int shift1 = 16 - depth
    unsigned Int shift2 = 2*depth - 16
    Int k

    if(count <= 0) return

    mask = 1
    for(k = 1; k < depth; k++) mask |= (1 << k)

    if(lowbyte_first)
    {
      while(count--) {
         tmp = ((((unsigned Int)data[0])<<8) | ((unsigned Int)data[1])) & mask
         tmp = (tmp << shift1) + (tmp >> shift2)
         if(invert) tmp = ~tmp
         *data++ = tmp & 255U
         *data++ = (tmp >> 8) & 255U
      }
    }
    else  /* Highbyte first */
    {
      while(count--) {
         tmp = ((((unsigned Int)data[0])<<8) | ((unsigned Int)data[1])) & mask
         tmp = (tmp << shift1) + (tmp >> shift2)
         if(invert) tmp = ~tmp
         *data++ = (tmp >> 8) & 255U
         *data++ = tmp & 255U
      }
    }
}


static void
hp_scale_to_8bit(Int count, register unsigned char *data, Int depth,
                 hp_bool_t invert)
{
    register unsigned Int tmp, mask
    register hp_bool_t lowbyte_first = is_lowbyte_first_byteorder()
    unsigned Int shift1 = depth-8
    Int k
    unsigned char *dataout = data

    if((count <= 0) || (shift1 <= 0)) return

    mask = 1
    for(k = 1; k < depth; k++) mask |= (1 << k)

    if(lowbyte_first)
    {
      while(count--) {
         tmp = ((((unsigned Int)data[0])<<8) | ((unsigned Int)data[1])) & mask
         tmp >>= shift1
         if(invert) tmp = ~tmp
         *(dataout++) = tmp & 255U
         data += 2
      }
    }
    else  /* Highbyte first */
    {
      while(count--) {
         tmp = ((((unsigned Int)data[0])<<8) | ((unsigned Int)data[1])) & mask
         tmp >>= shift1
         if(invert) tmp = ~tmp
         *(dataout++) = tmp & 255U
         data += 2
      }
    }
}

static void
hp_soft_invert(Int count, register unsigned char *data) {
	while(count>0) {
		*data = ~(*data)
		data++
		count--
	}
}

static PROCDATA_HANDLE *
process_data_init(HpProcessData *procdata, const unsigned char *map,
                   Int outfd, hp_bool_t use_imgbuf)

{PROCDATA_HANDLE *ph = sanei_hp_alloc(sizeof(PROCDATA_HANDLE))
 Int tsz

 if(ph == NULL) return NULL

 memset(ph, 0, sizeof(*ph))
 memcpy(&(ph.procdata), procdata, sizeof(*procdata))
 procdata = &(ph.procdata)

 tsz = (HP_TMP_BUF_SIZE <= 0) ? procdata.bytesPerLine : HP_TMP_BUF_SIZE
 ph.tmp_buf = sanei_hp_alloc(tsz)
 if(ph.tmp_buf == NULL)
 {
   sanei_hp_free(ph)
   return NULL
 }
 ph.tmp_buf_size = tsz
 ph.tmp_buf_len = 0

 ph.map = map
 ph.outfd = outfd

 if( procdata.mirror_vertical || use_imgbuf)
 {
   tsz = procdata.lines*procdata.bytesPerLine
   if(procdata.out8) tsz /= 2
   ph.image_ptr = ph.image_buf = sanei_hp_alloc(tsz)
   if( !ph.image_buf )
   {
     procdata.mirror_vertical = 0
     ph.image_buf_size = 0
     DBG(1, "process_scanline_init: Not enough memory to mirror image\n")
   }
   else
     ph.image_buf_size = tsz
 }

 ph.wr_ptr = ph.wr_buf
 ph.wr_buf_size = ph.wr_left = sizeof(ph.wr_buf)

 return ph
}


static Sane.Status
process_data_write(PROCDATA_HANDLE *ph, unsigned char *data, Int nbytes)

{Int ncopy

 if(ph == NULL) return Sane.STATUS_INVAL

 /* Fill up write buffer */
 ncopy = ph.wr_left
 if(ncopy > nbytes) ncopy = nbytes

 memcpy(ph.wr_ptr, data, ncopy)
 ph.wr_ptr += ncopy
 ph.wr_left -= ncopy
 data += ncopy
 nbytes -= ncopy

 if( ph.wr_left > 0 )  /* Did not fill up the write buffer ? Finished */
   return Sane.STATUS_GOOD

 DBG(12, "process_data_write: write %d bytes\n", ph.wr_buf_size)
 /* Don"t write data if we got a signal in the meantime */
 if(   signal_caught
     || (write(ph.outfd, ph.wr_buf, ph.wr_buf_size) != ph.wr_buf_size))
 {
   DBG(1, "process_data_write: write failed: %s\n",
       signal_caught ? "signal caught" : strerror(errno))
   return Sane.STATUS_IO_ERROR
 }
 ph.wr_ptr = ph.wr_buf
 ph.wr_left = ph.wr_buf_size

 /* For large amount of data write it from data-buffer */
 while( nbytes > ph.wr_buf_size )
 {
   if(   signal_caught
       || (write(ph.outfd, data, ph.wr_buf_size) != ph.wr_buf_size))
   {
     DBG(1, "process_data_write: write failed: %s\n",
         signal_caught ? "signal caught" : strerror(errno))
     return Sane.STATUS_IO_ERROR
   }
   nbytes -= ph.wr_buf_size
   data += ph.wr_buf_size
 }

 if( nbytes > 0 ) /* Something left ? Save it to(empty) write buffer */
 {
   memcpy(ph.wr_ptr, data, nbytes)
   ph.wr_ptr += nbytes
   ph.wr_left -= nbytes
 }
 return Sane.STATUS_GOOD
}

static Sane.Status
process_scanline(PROCDATA_HANDLE *ph, unsigned char *linebuf,
                  Int bytesPerLine)

{Int out_bytes_per_line = bytesPerLine
 HpProcessData *procdata

 if(ph == NULL) return Sane.STATUS_INVAL
 procdata = &(ph.procdata)

 if( ph.map )
   hp_data_map(ph.map, bytesPerLine, linebuf)

 if(procdata.bits_per_channel > 8)
 {
   if(procdata.out8)
   {
     hp_scale_to_8bit( bytesPerLine/2, linebuf,
                       procdata.bits_per_channel,
                       procdata.invert)
     out_bytes_per_line /= 2
   }
   else
   {
     hp_scale_to_16bit( bytesPerLine/2, linebuf,
                        procdata.bits_per_channel,
                        procdata.invert)
   }
 } else if(procdata.invert) {
   hp_soft_invert(bytesPerLine,linebuf)
 }

 if( ph.image_buf )
 {
   DBG(5, "process_scanline: save in memory\n")

   if(    ph.image_ptr+out_bytes_per_line-1
        <= ph.image_buf+ph.image_buf_size-1 )
   {
     memcpy(ph.image_ptr, linebuf, out_bytes_per_line)
     ph.image_ptr += out_bytes_per_line
   }
   else
   {
     DBG(1, "process_scanline: would exceed image buffer\n")
   }
 }
 else /* Save scanlines in a bigger buffer. */
 {    /* Otherwise we will get performance problems */

   RETURN_IF_FAIL( process_data_write(ph, linebuf, out_bytes_per_line) )
 }
 return Sane.STATUS_GOOD
}


static Sane.Status
process_data(PROCDATA_HANDLE *ph, unsigned char *read_ptr, Int nread)

{Int bytes_left

 if(nread <= 0) return Sane.STATUS_GOOD

 if(ph == NULL) return Sane.STATUS_INVAL

 if( ph.tmp_buf_len > 0 )  /* Something left ? */
 {
   bytes_left = ph.tmp_buf_size - ph.tmp_buf_len
   if(nread < bytes_left)  /* All to buffer ? */
   {
     memcpy(ph.tmp_buf+ph.tmp_buf_len, read_ptr, nread)
     ph.tmp_buf_len += nread
     return Sane.STATUS_GOOD
   }
   memcpy(ph.tmp_buf+ph.tmp_buf_len, read_ptr, bytes_left)
   read_ptr += bytes_left
   nread -= bytes_left
   RETURN_IF_FAIL( process_scanline(ph, ph.tmp_buf, ph.tmp_buf_size) )
   ph.tmp_buf_len = 0
 }
 while(nread > 0)
 {
   if(nread >= ph.tmp_buf_size)
   {
     RETURN_IF_FAIL( process_scanline(ph, read_ptr, ph.tmp_buf_size) )
     read_ptr += ph.tmp_buf_size
     nread -= ph.tmp_buf_size
   }
   else
   {
     memcpy(ph.tmp_buf, read_ptr, nread)
     ph.tmp_buf_len = nread
     nread = 0
   }
 }
 return Sane.STATUS_GOOD
}


static Sane.Status
process_data_flush(PROCDATA_HANDLE *ph)

{Sane.Status status = Sane.STATUS_GOOD
 HpProcessData *procdata
 unsigned char *image_data
 size_t image_len
 Int num_lines, bytesPerLine
 Int nbytes

 if(ph == NULL) return Sane.STATUS_INVAL

 if( ph.tmp_buf_len > 0 )
   process_scanline(ph, ph.tmp_buf, ph.tmp_buf_len)

 if( ph.wr_left != ph.wr_buf_size ) /* Something in write buffer ? */
 {
   nbytes = ph.wr_buf_size - ph.wr_left
   if( signal_caught || (write(ph.outfd, ph.wr_buf, nbytes) != nbytes))
   {
     DBG(1, "process_data_flush: write failed: %s\n",
         signal_caught ? "signal caught" : strerror(errno))
     return Sane.STATUS_IO_ERROR
   }
   ph.wr_ptr = ph.wr_buf
   ph.wr_left = ph.wr_buf_size
 }

 procdata = &(ph.procdata)
 if( ph.image_buf )
 {
   bytesPerLine = procdata.bytesPerLine
   if(procdata.out8) bytesPerLine /= 2
   image_len = (size_t) (ph.image_ptr - ph.image_buf)
   num_lines = ((Int)(image_len + bytesPerLine-1)) / bytesPerLine

   DBG(3, "process_data_finish: write %d bytes from memory...\n",
       (Int)image_len)

   if( procdata.mirror_vertical )
   {
     image_data = ph.image_buf + (num_lines-1) * bytesPerLine
     while(num_lines > 0 )
     {
       if(   signal_caught
           || (write(ph.outfd, image_data, bytesPerLine) != bytesPerLine))
       {
         DBG(1,"process_data_finish: write from memory failed: %s\n",
             signal_caught ? "signal caught" : strerror(errno))
         status = Sane.STATUS_IO_ERROR
         break
       }
       num_lines--
       image_data -= bytesPerLine
     }
   }
   else
   {
     image_data = ph.image_buf
     while(num_lines > 0 )
     {
       if(   signal_caught
           || (write(ph.outfd, image_data, bytesPerLine) != bytesPerLine))
       {
         DBG(1,"process_data_finish: write from memory failed: %s\n",
             signal_caught ? "signal caught" : strerror(errno))
         status = Sane.STATUS_IO_ERROR
         break
       }
       num_lines--
       image_data += bytesPerLine
     }
   }
 }
 return status
}


static void
process_data_finish(PROCDATA_HANDLE *ph)

{
 DBG(12, "process_data_finish called\n")

 if(ph == NULL) return

 if(ph.image_buf != NULL) sanei_hp_free(ph.image_buf)

 sanei_hp_free(ph.tmp_buf)
 sanei_hp_free(ph)
}


Sane.Status
sanei_hp_scsi_pipeout(HpScsi this, Int outfd, HpProcessData *procdata)
{
  /* We will catch these signals, and rethrow them after cleaning up,
   * anything not in this list, we will ignore. */
  static Int kill_sig[] = {
      SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGPIPE, SIGALRM, SIGTERM,
      SIGUSR1, SIGUSR2, SIGBUS,
#ifdef SIGSTKFLT
      SIGSTKFLT,
#endif
#ifdef SIGIO
      SIGIO,
#else
# ifdef SIGPOLL
      SIGPOLL,
# endif
#endif
#ifdef SIGXCPU
      SIGXCPU,
#endif
#ifdef SIGXFSZ
      SIGXFSZ,
#endif
#ifdef SIGVTALRM
      SIGVTALRM,
#endif
#ifdef SIGPWR
      SIGPWR,
#endif
  ]
#define HP_NSIGS(sizeof(kill_sig)/sizeof(kill_sig[0]))
  struct SIGACTION old_handler[HP_NSIGS]
  struct SIGACTION sa
  sigset_t	old_set, sig_set
  Int		i
  Int           bits_per_channel = procdata.bits_per_channel

#define HP_PIPEBUF	32768
  Sane.Status	status	= Sane.STATUS_GOOD
  struct {
      size_t	len
      void *	id
      hp_byte_t	cmd[6]
      hp_byte_t	data[HP_PIPEBUF]
  } 	buf[2], *req = NULL

  Int		reqs_completed = 0
  Int		reqs_issued = 0
  char          *image_buf = 0
  char          *read_buf = 0
  const HpDeviceInfo *info
  const char    *devname = sanei_hp_scsi_devicename(this)
  Int           enable_requests = 1
  Int           enable_image_buffering = 0
  const unsigned char *map = NULL
  HpConnect     connect
  PROCDATA_HANDLE *ph = NULL
  size_t count = procdata.lines * procdata.bytesPerLine

  RETURN_IF_FAIL( hp_scsi_flush(this) )

  connect = sanei_hp_get_connect(devname)
  info = sanei_hp_device_info_get(devname)

  assert(info)

  if( info.config_is_up )
  {
    enable_requests = info.config.use_scsi_request
    enable_image_buffering = info.config.use_image_buffering
  }
  else
  {
    enable_requests = 0
  }

  if(connect != HP_CONNECT_SCSI)
    enable_requests = 0

  /* Currently we can only simulate 8 bits mapping */
  if(bits_per_channel == 8)
    map = hp_get_simulation_map(devname, info)

  sigfillset(&sig_set)
  sigprocmask(SIG_BLOCK, &sig_set, &old_set)

  memset(&sa, 0, sizeof(sa))
  sa.sa_handler = signal_catcher
  sigfillset(&sa.sa_mask)

  sigemptyset(&sig_set)
  for(i = 0; i < (Int)(HP_NSIGS); i++)
    {
      sigaction(kill_sig[i], &sa, &old_handler[i])
      sigaddset(&sig_set, kill_sig[i])
    }
  signal_caught = 0
  sigprocmask(SIG_UNBLOCK, &sig_set, 0)

  /* Wait for front button push ? */
  if( procdata.startscan )
  {
    for(;;)
    {Int val = 0

       if(signal_caught) goto quit
       sanei_hp_scl_inquire(this, SCL_FRONT_BUTTON, &val, 0, 0)
       if(val) break
       usleep((unsigned long)333*1000); /* Wait 1/3 second */
    }
    status = sanei_hp_scl_startScan(this, procdata.startscan)
    if(status != Sane.STATUS_GOOD )
    {
      DBG(1, "do_read: Error starting scan in reader process\n")
      goto quit
    }
  }
  ph = process_data_init(procdata, map, outfd, enable_image_buffering)

  if( ph == NULL )
  {
    DBG(1, "do_read: Error with process_data_init()\n")
    goto quit
  }

  DBG(1, "do_read: Start reading data from scanner\n")

  if(enable_requests)   /* Issue SCSI-requests ? */
  {
    while(count > 0 || reqs_completed < reqs_issued)
    {
      while(count > 0 && reqs_issued < reqs_completed + 2)
	{
	  req = buf + (reqs_issued++ % 2)

	  req.len = HP_PIPEBUF
	  if(count < req.len)
	      req.len = count
	  count -= req.len

	  req.cmd[0] = 0x08
	  req.cmd[1] = 0
	  req.cmd[2] = req.len >> 16
	  req.cmd[3] = req.len >> 8
	  req.cmd[4] = req.len
	  req.cmd[5] = 0

	  DBG(3, "do_read: entering request to read %lu bytes\n",
	      (unsigned long) req.len)

	  status = sanei_scsi_req_enter(this.fd, req.cmd, 6,
				      req.data, &req.len, &req.id)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(1, "do_read: Error from scsi_req_enter: %s\n",
		  Sane.strstatus(status))
	      goto quit
	    }
	  if(signal_caught)
	      goto quit
	}

      if(signal_caught)
	  goto quit

      assert(reqs_completed < reqs_issued)
      req = buf + (reqs_completed++ % 2)

      DBG(3, "do_read: waiting for data\n")
      status = sanei_scsi_req_wait(req.id)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "do_read: Error from scsi_req_wait: %s\n",
	      Sane.strstatus(status))
	  goto quit
	}
      if(signal_caught)
	  goto quit

      status = process_data(ph, (unsigned char *)req.data, (Int)req.len)
      if( status != Sane.STATUS_GOOD )
      {
        DBG(1,"do_read: Error in process_data\n")
        goto quit
      }
    }
  }
  else  /* Read directly */
  {
    read_buf = sanei_hp_alloc( HP_PIPEBUF )
    if(!read_buf)
    {
      DBG(1, "do_read: not enough memory for read buffer\n")
      goto quit
    }

    while(count > 0)
    {size_t nread

      if(signal_caught)
	  goto quit

      DBG(5, "do_read: %lu bytes left to read\n", (unsigned long)count)

      nread = HP_PIPEBUF
      if(nread > count) nread = count

      DBG(3, "do_read: try to read data(%lu bytes)\n", (unsigned long)nread)

      status = hp_scsi_read(this, read_buf, &nread, 0)
      if(status != Sane.STATUS_GOOD)
      {
        DBG(1, "do_read: Error from scsi_read: %s\n",Sane.strstatus(status))
        goto quit
      }

      DBG(3, "do_read: got %lu bytes\n", (unsigned long)nread)

      if(nread <= 0)
      {
        DBG(1, "do_read: Nothing read\n")
        continue
      }

      status = process_data(ph, (unsigned char *)read_buf, (Int)nread)
      if( status != Sane.STATUS_GOOD )
      {
        DBG(1,"do_read: Error in process_data\n")
        goto quit
      }
      count -= nread
    }
  }

  process_data_flush(ph)

quit:

  process_data_finish(ph)

  if( image_buf ) sanei_hp_free( image_buf )
  if( read_buf ) sanei_hp_free( read_buf )

  if(enable_requests && (reqs_completed < reqs_issued))
    {
      DBG(1, "do_read: cleaning up leftover requests\n")
      while(reqs_completed < reqs_issued)
	{
	  req = buf + (reqs_completed++ % 2)
	  sanei_scsi_req_wait(req.id)
	}
    }

  sigfillset(&sig_set)
  sigprocmask(SIG_BLOCK, &sig_set, 0)
  for(i = 0; i < (Int)(HP_NSIGS); i++)
      sigaction(kill_sig[i], &old_handler[i], 0)
  sigprocmask(SIG_SETMASK, &old_set, 0)

  if(signal_caught)
    {
      DBG(1, "do_read: caught signal %d\n", signal_caught)
      raise(signal_caught)
      return Sane.STATUS_CANCELLED
    }

  return status
}



/*
 *
 */

static Sane.Status
_hp_scl_inq(HpScsi scsi, HpScl scl, HpScl inq_cmnd,
	     void *valp, size_t *lengthp)
{
  size_t	bufsize	= 16 + (lengthp ? *lengthp: 0)
  char *	buf	= alloca(bufsize)
  char		expect[16], expect_char
  Int		val, count
  Sane.Status	status

  if(!buf)
      return Sane.STATUS_NO_MEM

  /* Flush data before sending inquiry. */
  /* Otherwise scanner might not generate a response. */
  RETURN_IF_FAIL( hp_scsi_flush(scsi)) 

  RETURN_IF_FAIL( hp_scsi_scl(scsi, inq_cmnd, SCL_INQ_ID(scl)) )
  usleep(1000); /* 500 works, too, but not 100 */

  status =  hp_scsi_read(scsi, buf, &bufsize, 1)
  if(FAILED(status))
    {
      DBG(1, "scl_inq: read failed(%s)\n", Sane.strstatus(status))
      return status
    }

  if(SCL_PARAM_CHAR(inq_cmnd) == "R")
      expect_char = "p"
  else
      expect_char = tolower(SCL_PARAM_CHAR(inq_cmnd) - 1)

  count = sprintf(expect, "\033*s%d%c", SCL_INQ_ID(scl), expect_char)
  if(memcmp(buf, expect, count) != 0)
    {
      DBG(1, "scl_inq: malformed response: expected "%s", got "%.*s"\n",
	  expect, count, buf)
      return Sane.STATUS_IO_ERROR
    }
  buf += count

  if(buf[0] == "N")
    {				/* null response */
      DBG(3, "scl_inq: parameter %d unsupported\n", SCL_INQ_ID(scl))
      return Sane.STATUS_UNSUPPORTED
    }

  if(sscanf(buf, "%d%n", &val, &count) != 1)
    {
      DBG(1, "scl_inq: malformed response: expected Int, got "%.8s"\n", buf)
      return Sane.STATUS_IO_ERROR
    }
  buf += count

  expect_char = lengthp ? "W" : "V"
  if(*buf++ != expect_char)
    {
      DBG(1, "scl_inq: malformed response: expected "%c", got "%.4s"\n",
	  expect_char, buf - 1)
      return Sane.STATUS_IO_ERROR
    }

  if(!lengthp)
      *(Int *)valp = val; /* Get integer value */
  else
    {
      if(val > (Int)*lengthp)
	{
	  DBG(1, "scl_inq: inquiry returned %d bytes, expected <= %lu\n",
	      val, (unsigned long) *lengthp)
	  return Sane.STATUS_IO_ERROR
	}
      *lengthp = val
      memcpy(valp, buf , *lengthp); /* Get binary data */
    }

  return Sane.STATUS_GOOD
}


Sane.Status
sanei_hp_scl_upload_binary(HpScsi scsi, HpScl scl, size_t *lengthhp,
                            char **bufhp)
{
  size_t	bufsize	= 16, sv
  char *	buf	= alloca(bufsize)
  char *        bufstart = buf
  char *        hpdata
  char		expect[16], expect_char
  Int		n, val, count
  Sane.Status	status

  if(!buf)
      return Sane.STATUS_NO_MEM

  assert( IS_SCL_DATA_TYPE(scl) )

  /* Flush data before sending inquiry. */
  /* Otherwise scanner might not generate a response. */
  RETURN_IF_FAIL( hp_scsi_flush(scsi)) 

  RETURN_IF_FAIL( hp_scsi_scl(scsi, SCL_UPLOAD_BINARY_DATA, SCL_INQ_ID(scl)) )

  status =  hp_scsi_read(scsi, buf, &bufsize, 0)
  if(FAILED(status))
    {
      DBG(1, "scl_upload_binary: read failed(%s)\n", Sane.strstatus(status))
      return status
    }

  expect_char = "t"
  count = sprintf(expect, "\033*s%d%c", SCL_INQ_ID(scl), expect_char)
  if(memcmp(buf, expect, count) != 0)
    {
      DBG(1, "scl_upload_binary: malformed response: expected "%s", got "%.*s"\n",
	  expect, count, buf)
      return Sane.STATUS_IO_ERROR
    }
  buf += count

  if(buf[0] == "N")
    {				/* null response */
      DBG(1, "scl_upload_binary: parameter %d unsupported\n", SCL_INQ_ID(scl))
      return Sane.STATUS_UNSUPPORTED
    }

  if(sscanf(buf, "%d%n", &val, &count) != 1)
    {
      DBG(1, "scl_inq: malformed response: expected Int, got "%.8s"\n", buf)
      return Sane.STATUS_IO_ERROR
    }
  buf += count

  expect_char = "W"
  if(*buf++ != expect_char)
    {
      DBG(1, "scl_inq: malformed response: expected "%c", got "%.4s"\n",
	  expect_char, buf - 1)
      return Sane.STATUS_IO_ERROR
    }

  *lengthhp = val
  *bufhp = hpdata = sanei_hp_alloc( val )
  if(!hpdata)
      return Sane.STATUS_NO_MEM

  if(buf < bufstart + bufsize)
    {
       n = bufsize - (buf - bufstart)
       if(n > val) n = val
       memcpy(hpdata, buf, n)
       hpdata += n
       val -= n
    }

  status = Sane.STATUS_GOOD
  if( val > 0 )
    {
      sv = val
      status = hp_scsi_read(scsi, hpdata, &sv, 0)
      if(status != Sane.STATUS_GOOD)
        sanei_hp_free( *bufhp )
    }

  return status
}


Sane.Status
sanei_hp_scl_set(HpScsi scsi, HpScl scl, Int val)
{
  RETURN_IF_FAIL( hp_scsi_scl(scsi, scl, val) )


#ifdef PARANOID
  RETURN_IF_FAIL( sanei_hp_scl_errcheck(scsi) )
#endif

  return Sane.STATUS_GOOD
}

Sane.Status
sanei_hp_scl_inquire(HpScsi scsi, HpScl scl, Int * valp, Int * minp, Int * maxp)
{
  HpScl	inquiry = ( IS_SCL_CONTROL(scl)
		    ? SCL_INQUIRE_PRESENT_VALUE
		    : SCL_INQUIRE_DEVICE_PARAMETER )

  assert(IS_SCL_CONTROL(scl) || IS_SCL_PARAMETER(scl))
  assert(IS_SCL_CONTROL(scl) || (!minp && !maxp))

  if(valp)
      RETURN_IF_FAIL( _hp_scl_inq(scsi, scl, inquiry, valp, 0) )
  if(minp)
      RETURN_IF_FAIL( _hp_scl_inq(scsi, scl,
				  SCL_INQUIRE_MINIMUM_VALUE, minp, 0) )
  if(maxp)
      RETURN_IF_FAIL( _hp_scl_inq(scsi, scl,
				  SCL_INQUIRE_MAXIMUM_VALUE, maxp, 0) )
  return Sane.STATUS_GOOD
}

#ifdef _HP_NOT_USED
static Sane.Status
hp_scl_get_bounds(HpScsi scsi, HpScl scl, Int * minp, Int * maxp)
{
  assert(IS_SCL_CONTROL(scl))
  RETURN_IF_FAIL( _hp_scl_inq(scsi, scl, SCL_INQUIRE_MINIMUM_VALUE, minp, 0) )
  return _hp_scl_inq(scsi, scl, SCL_INQUIRE_MAXIMUM_VALUE, maxp, 0)
}
#endif

#ifdef _HP_NOT_USED
static Sane.Status
hp_scl_get_bounds_and_val(HpScsi scsi, HpScl scl,
			  Int * minp, Int * maxp, Int * valp)
{
  assert(IS_SCL_CONTROL(scl))
  RETURN_IF_FAIL( _hp_scl_inq(scsi, scl, SCL_INQUIRE_MINIMUM_VALUE, minp, 0) )
  RETURN_IF_FAIL( _hp_scl_inq(scsi, scl, SCL_INQUIRE_MAXIMUM_VALUE, maxp, 0) )
  return    _hp_scl_inq(scsi, scl, SCL_INQUIRE_PRESENT_VALUE, valp, 0)
}
#endif

Sane.Status
sanei_hp_scl_download(HpScsi scsi, HpScl scl, const void * valp, size_t len)
{
  assert(IS_SCL_DATA_TYPE(scl))

  sanei_hp_scl_clearErrors( scsi )
  RETURN_IF_FAIL( hp_scsi_need(scsi, 16) )
  RETURN_IF_FAIL( hp_scsi_scl(scsi, SCL_DOWNLOAD_TYPE, SCL_INQ_ID(scl)) )
                            /* Download type not supported ? */
  RETURN_IF_FAIL( sanei_hp_scl_errcheck(scsi) )
  RETURN_IF_FAIL( hp_scsi_scl(scsi, SCL_DOWNLOAD_LENGTH, len) )
  RETURN_IF_FAIL( hp_scsi_write(scsi, valp, len) )

#ifdef PARANOID
  RETURN_IF_FAIL( sanei_hp_scl_errcheck(scsi) )
#endif

  return Sane.STATUS_GOOD
}

Sane.Status
sanei_hp_scl_upload(HpScsi scsi, HpScl scl, void * valp, size_t len)
{
  size_t	nread = len
  HpScl		inquiry = ( IS_SCL_DATA_TYPE(scl)
			    ? SCL_UPLOAD_BINARY_DATA
			    : SCL_INQUIRE_DEVICE_PARAMETER )

  assert(IS_SCL_DATA_TYPE(scl) || IS_SCL_PARAMETER(scl))

  RETURN_IF_FAIL( _hp_scl_inq(scsi, scl, inquiry, valp, &nread) )
  if(IS_SCL_PARAMETER(scl) && nread < len)
      ((char *)valp)[nread] = "\0"
  else if(len != nread)
    {
      DBG(1, "scl_upload: requested %lu bytes, got %lu\n",
	  (unsigned long) len, (unsigned long) nread)
      return Sane.STATUS_IO_ERROR
    }
  return Sane.STATUS_GOOD
}

Sane.Status
sanei_hp_scl_calibrate(HpScsi scsi)
{
  RETURN_IF_FAIL( hp_scsi_scl(scsi, SCL_CALIBRATE, 0) )
  return hp_scsi_flush(scsi)
}

Sane.Status
sanei_hp_scl_startScan(HpScsi scsi, HpScl scl)
{
  char *msg = ""

  if(scl == SCL_ADF_SCAN) msg = " (ADF)"
  else if(scl == SCL_XPA_SCAN) msg = " (XPA)"
  else scl = SCL_START_SCAN

  DBG(1, "sanei_hp_scl_startScan: Start scan%s\n", msg)

  /* For active XPA we must not use XPA scan */
  if((scl == SCL_XPA_SCAN) && sanei_hp_is_active_xpa(scsi))
  {
    DBG(3,"Map XPA scan to scan because of active XPA\n")
    scl = SCL_START_SCAN
  }

  RETURN_IF_FAIL( hp_scsi_scl(scsi, scl, 0) )
  return hp_scsi_flush(scsi)
}

Sane.Status
sanei_hp_scl_reset(HpScsi scsi)
{
  RETURN_IF_FAIL( hp_scsi_write(scsi, "\033E", 2) )
  RETURN_IF_FAIL( hp_scsi_flush(scsi) )
  return sanei_hp_scl_errcheck(scsi)
}

Sane.Status
sanei_hp_scl_clearErrors(HpScsi scsi)
{
  RETURN_IF_FAIL( hp_scsi_flush(scsi) )
  RETURN_IF_FAIL( hp_scsi_write(scsi, "\033*oE", 4) )
  return hp_scsi_flush(scsi)
}

static const char *
hp_scl_strerror(Int errnum)
{
  static const char * errlist[] = {
      "Command Format Error",
      "Unrecognized Command",
      "Parameter Error",
      "Illegal Window",
      "Scaling Error",
      "Dither ID Error",
      "Tone Map ID Error",
      "Lamp Error",
      "Matrix ID Error",
      "Cal Strip Param Error",
      "Gross Calibration Error"
  ]

  if(errnum >= 0 && errnum < (Int)(sizeof(errlist)/sizeof(errlist[0])))
      return errlist[errnum]
  else
      switch(errnum) {
      case 1024: return "ADF Paper Jam"
      case 1025: return "Home Position Missing"
      case 1026: return "Paper Not Loaded"
      default: return "??Unknown Error??"
      }
}

/* Check for SCL errors */
Sane.Status
sanei_hp_scl_errcheck(HpScsi scsi)
{
  Int		errnum
  Int		nerrors
  Sane.Status	status

  status = sanei_hp_scl_inquire(scsi, SCL_CURRENT_ERROR_STACK, &nerrors,0,0)
  if(!FAILED(status) && nerrors)
      status = sanei_hp_scl_inquire(scsi, SCL_OLDEST_ERROR, &errnum,0,0)
  if(FAILED(status))
    {
      DBG(1, "scl_errcheck: Can"t read SCL error stack: %s\n",
	  Sane.strstatus(status))
      return Sane.STATUS_IO_ERROR
    }

  if(nerrors)
    {
      DBG(1, "Scanner issued SCL error: (%d) %s\n",
	  errnum, hp_scl_strerror(errnum))

      sanei_hp_scl_clearErrors(scsi)
      return Sane.STATUS_IO_ERROR
    }

  return Sane.STATUS_GOOD
}
