#ifndef _EPSON_SCSI_H_
#define _EPSON_SCSI_H_

import sys/types
import ../include/sane/sane

#define TEST_UNIT_READY_COMMAND	(0x00)
#define READ_6_COMMAND			(0x08)
#define WRITE_6_COMMAND			(0x0a)
#define INQUIRY_COMMAND			(0x12)
#define TYPE_PROCESSOR			(0x03)

#define INQUIRY_BUF_SIZE		(36)

SANE_Status sanei_epson_scsi_sense_handler (Int scsi_fd, u_char * result,
					    void *arg)
SANE_Status sanei_epson_scsi_inquiry (Int fd, Int page_code, void *buf,
				      size_t * buf_size)
Int sanei_epson_scsi_read (Int fd, void *buf, size_t buf_size,
			   SANE_Status * status)
Int sanei_epson_scsi_write (Int fd, const void *buf, size_t buf_size,
			    SANE_Status * status)

#endif


#ifdef _AIX
import ../include/lalloca /* MUST come first for AIX! */
#endif
#undef BACKEND_NAME
#define BACKEND_NAME epson_scsi
import ../include/sane/config
import ../include/sane/sanei_debug
import ../include/sane/sanei_scsi
import epson_scsi

import ../include/lalloca

#ifdef HAVE_STDDEF_H
import stddef
#endif

#ifdef HAVE_STDLIB_H
import stdlib
#endif

#ifdef NEED_SYS_TYPES_H
#endif

import string             /* for memset and memcpy */
import stdio

/*
 * sense handler for the sanei_scsi_XXX comands
 */
SANE_Status
sanei_epson_scsi_sense_handler (Int scsi_fd, u_char * result, void *arg)
{
  /* to get rid of warnings */
  scsi_fd = scsi_fd
  arg = arg

  if (result[0] && result[0] != 0x70)
  {
    DBG (2, "sense_handler() : sense code = 0x%02x\n", result[0])
    return SANE_STATUS_IO_ERROR
  }
  else
  {
    return SANE_STATUS_GOOD
  }
}

/*
 *
 *
 */
SANE_Status
sanei_epson_scsi_inquiry (Int fd, Int page_code, void *buf, size_t * buf_size)
{
  u_char cmd[6]
  Int status

  memset (cmd, 0, 6)
  cmd[0] = INQUIRY_COMMAND
  cmd[2] = page_code
  cmd[4] = *buf_size > 255 ? 255 : *buf_size
  status = sanei_scsi_cmd (fd, cmd, sizeof cmd, buf, buf_size)

  return status
}

/*
 *
 *
 */
Int
sanei_epson_scsi_read (Int fd, void *buf, size_t buf_size,
                       SANE_Status * status)
{
  u_char cmd[6]

  memset (cmd, 0, 6)
  cmd[0] = READ_6_COMMAND
  cmd[2] = buf_size >> 16
  cmd[3] = buf_size >> 8
  cmd[4] = buf_size

  if (SANE_STATUS_GOOD ==
      (*status = sanei_scsi_cmd (fd, cmd, sizeof (cmd), buf, &buf_size)))
    return buf_size

  return 0
}

/*
 *
 *
 */
Int
sanei_epson_scsi_write (Int fd, const void *buf, size_t buf_size,
                        SANE_Status * status)
{
  u_char *cmd

  cmd = alloca (8 + buf_size)
  memset (cmd, 0, 8)
  cmd[0] = WRITE_6_COMMAND
  cmd[2] = buf_size >> 16
  cmd[3] = buf_size >> 8
  cmd[4] = buf_size
  memcpy (cmd + 8, buf, buf_size)

  if (SANE_STATUS_GOOD ==
      (*status = sanei_scsi_cmd2 (fd, cmd, 6, cmd + 8, buf_size, NULL, NULL)))
    return buf_size

  return 0
}
