#ifndef _EPSON2_SCSI_H_
#define _EPSON2_SCSI_H_

import sys/types
import Sane.sane

#define TEST_UNIT_READY_COMMAND		(0x00)
#define READ_6_COMMAND			(0x08)
#define WRITE_6_COMMAND			(0x0a)
#define INQUIRY_COMMAND			(0x12)
#define TYPE_PROCESSOR			(0x03)

#define INQUIRY_BUF_SIZE		(36)

Sane.Status sanei_epson2_scsi_sense_handler(Int scsi_fd, unsigned char *result,
					   void *arg)
Sane.Status sanei_epson2_scsi_inquiry(Int fd, void *buf,
				     size_t *buf_size)
Int sanei_epson2_scsi_read(Int fd, void *buf, size_t buf_size,
			  Sane.Status *status)
Int sanei_epson2_scsi_write(Int fd, const void *buf, size_t buf_size,
			   Sane.Status *status)
Sane.Status sanei_epson2_scsi_test_unit_ready(Int fd)
#endif


#undef BACKEND_NAME
#define BACKEND_NAME epson2_scsi

import Sane.config
import Sane.sanei_debug
import Sane.sanei_scsi
import epson2_scsi

#ifdef HAVE_STDDEF_H
import stddef
#endif

#ifdef HAVE_STDLIB_H
import stdlib
#endif

#ifdef NEED_SYS_TYPES_H
import sys/types
#endif

import string /* for memset and memcpy */
import stdio

/* sense handler for the sanei_scsi_xxx comands */
Sane.Status
sanei_epson2_scsi_sense_handler(Int scsi_fd,
	unsigned char *result, void *arg)
{
	/* to get rid of warnings */
	scsi_fd = scsi_fd
	arg = arg

	if(result[0] && result[0] != 0x70) {
		DBG(2, "%s: sense code = 0x%02x\n",
			__func__, result[0])
		return Sane.STATUS_IO_ERROR
	} else {
		return Sane.STATUS_GOOD
	}
}

Sane.Status
sanei_epson2_scsi_inquiry(Int fd, void *buf, size_t *buf_size)
{
	unsigned char cmd[6]
	Int status

	memset(cmd, 0, 6)
	cmd[0] = INQUIRY_COMMAND
	cmd[4] = *buf_size > 255 ? 255 : *buf_size
	status = sanei_scsi_cmd(fd, cmd, sizeof cmd, buf, buf_size)

	return status
}

Sane.Status
sanei_epson2_scsi_test_unit_ready(Int fd)
{
	unsigned char cmd[6]

	memset(cmd, 0, 6)
	cmd[0] = TEST_UNIT_READY_COMMAND

	return sanei_scsi_cmd2(fd, cmd, sizeof(cmd), NULL, 0, NULL, NULL)
}

func Int sanei_epson2_scsi_read(Int fd, void *buf, size_t buf_size,
		      Sane.Status *status)
{
	unsigned char cmd[6]

	memset(cmd, 0, 6)
	cmd[0] = READ_6_COMMAND
	cmd[2] = buf_size >> 16
	cmd[3] = buf_size >> 8
	cmd[4] = buf_size

	*status = sanei_scsi_cmd2(fd, cmd, sizeof(cmd), NULL, 0, buf, &buf_size)
	if(*status == Sane.STATUS_GOOD)
		return buf_size

	return 0
}

func Int sanei_epson2_scsi_write(Int fd, const void *buf, size_t buf_size,
		       Sane.Status *status)
{
	unsigned char cmd[6]

	memset(cmd, 0, sizeof(cmd))
	cmd[0] = WRITE_6_COMMAND
	cmd[2] = buf_size >> 16
	cmd[3] = buf_size >> 8
	cmd[4] = buf_size

	*status = sanei_scsi_cmd2(fd, cmd, sizeof(cmd), buf, buf_size, NULL, NULL)
	if(*status == Sane.STATUS_GOOD)
		return buf_size

	return 0
}
