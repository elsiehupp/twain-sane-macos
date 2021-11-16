/*
   Copyright (C) 2009, Panasonic Russia Ltd.
   Copyright (C) 2010,2011, m. allan noah
*/
/*
   Panasonic KV-S40xx USB-SCSI scanner driver.
*/
import Sane.config
import string

#define DEBUG_DECLARE_ONLY
#define BACKEND_NAME kvs40xx

import Sane.sanei_backend
import Sane.saneopts
import Sane.sanei
import Sane.Sanei_usb
import Sane.sanei_scsi
import Sane.sanei_config

import kvs40xx

import Sane.sanei_debug

#define COMMAND_BLOCK	1
#define DATA_BLOCK	2
#define RESPONSE_BLOCK	3

#define COMMAND_CODE	0x9000
#define DATA_CODE	0xb000
#define RESPONSE_CODE	0xa000
#define STATUS_SIZE 4

struct bulk_header
{
  u32 length
  u16 type
  u16 code
  u32 transaction_id
]

#define TEST_UNIT_READY        0x00
#define INQUIRY                0x12
#define SET_WINDOW             0x24
#define SCAN                   0x1B
#define SEND_10                0x2A
#define READ_10                0x28
#define REQUEST_SENSE          0x03
#define GET_BUFFER_STATUS      0x34
#define SET_TIMEOUT	    	0xE1
#define GET_ADJUST_DATA	    	0xE0
#define HOPPER_DOWN	    	0xE1
#define STOP_ADF		0xE1



#define SUPPORT_INFO		0x93


#define GOOD 0
#define CHECK_CONDITION 2

typedef enum
{
  CMD_NONE = 0,
  CMD_IN = 0x81,		/* scanner to pc */
  CMD_OUT = 0x02		/* pc to scanner */
} CMD_DIRECTION;		/* equals to endpoint address */

#define RESPONSE_SIZE	0x12
#define MAX_CMD_SIZE	12
struct cmd
{
  unsigned char cmd[MAX_CMD_SIZE]
  Int cmd_size
  void *data
  Int data_size
  Int dir
]
struct response
{
  Int status
  unsigned char data[RESPONSE_SIZE]
]

static Sane.Status
usb_send_command (struct scanner *s, struct cmd *c, struct response *r,
		  void *buf)
{
  Sane.Status st
  struct bulk_header *h = (struct bulk_header *) buf
  u8 resp[sizeof (*h) + STATUS_SIZE]
  size_t sz = sizeof (*h) + MAX_CMD_SIZE
  memset (h, 0, sz)
  h.length = cpu2be32 (sz)
  h.type = cpu2be16 (COMMAND_BLOCK)
  h.code = cpu2be16 (COMMAND_CODE)
  memcpy (h + 1, c.cmd, c.cmd_size)

  st = sanei_usb_write_bulk (s.file, (const Sane.Byte *) h, &sz)
  if (st)
    return st

  if (sz != sizeof (*h) + MAX_CMD_SIZE)
    return Sane.STATUS_IO_ERROR

  if (c.dir == CMD_IN)
    {
      unsigned l
      sz = sizeof (*h) + c.data_size
      c.data_size = 0
      st = sanei_usb_read_bulk (s.file, (Sane.Byte *) h, &sz)
      for (l = sz; !st && l != be2cpu32 (h.length); l += sz)
	{
	  DBG (DBG_WARN, "usb wrong read (%d instead %d)\n",
	       c.data_size, be2cpu32 (h.length))
	  sz = be2cpu32 (h.length) - l
	  st = sanei_usb_read_bulk (s.file, ((Sane.Byte *) h) + l, &sz)

	}

      c.data = h + 1

      if (st)
	{
	  st = sanei_usb_release_interface (s.file, 0)
	  if (st)
	    return st
	  st = sanei_usb_claim_interface (s.file, 0)

	  if (st)
	    return st

	  r.status = CHECK_CONDITION
	  return Sane.STATUS_GOOD
	}

      c.data_size = sz - sizeof (*h)


    }
  else if (c.dir == CMD_OUT)
    {
      sz = sizeof (*h) + c.data_size
      memset (h, 0, sizeof (*h))
      h.length = cpu2be32 (sizeof (*h) + c.data_size)
      h.type = cpu2be16 (DATA_BLOCK)
      h.code = cpu2be16 (DATA_CODE)
      memcpy (h + 1, c.data, c.data_size)
      st = sanei_usb_write_bulk (s.file, (const Sane.Byte *) h, &sz)
      if (st)
	return st
    }
  sz = sizeof (resp)
  st = sanei_usb_read_bulk (s.file, resp, &sz)
  if (st || sz != sizeof (resp))
    return Sane.STATUS_IO_ERROR

  r.status = be2cpu32 (*((u32 *) (resp + sizeof (*h))))
  return st
}

#define END_OF_MEDIUM			(1<<6)
#define INCORRECT_LENGTH_INDICATOR	(1<<5)
static const struct
{
  unsigned sense, asc, ascq
  Sane.Status st
} s_errors[] =
{
  {
  2, 0, 0, Sane.STATUS_DEVICE_BUSY},
  {
  2, 4, 1, Sane.STATUS_DEVICE_BUSY},
  {
  2, 4, 0x80, Sane.STATUS_COVER_OPEN},
  {
  2, 4, 0x81, Sane.STATUS_COVER_OPEN},
  {
  2, 4, 0x82, Sane.STATUS_COVER_OPEN},
  {
  2, 4, 0x83, Sane.STATUS_COVER_OPEN},
  {
  2, 4, 0x84, Sane.STATUS_COVER_OPEN},
  {
  2, 0x80, 1, Sane.STATUS_CANCELLED},
  {
  2, 0x80, 2, Sane.STATUS_CANCELLED},
  {
  3, 0x3a, 0, Sane.STATUS_NO_DOCS},
  {
  3, 0x80, 1, Sane.STATUS_JAMMED},
  {
  3, 0x80, 2, Sane.STATUS_JAMMED},
  {
  3, 0x80, 3, Sane.STATUS_JAMMED},
  {
  3, 0x80, 4, Sane.STATUS_JAMMED},
  {
  3, 0x80, 5, Sane.STATUS_JAMMED},
  {
  3, 0x80, 6, Sane.STATUS_JAMMED},
  {
  3, 0x80, 7, Sane.STATUS_JAMMED},
  {
  3, 0x80, 8, Sane.STATUS_JAMMED},
  {
  3, 0x80, 9, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0xa, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0xb, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0xc, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0xd, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0xe, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0xf, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0x10, Sane.STATUS_JAMMED},
  {
  3, 0x80, 0x11, Sane.STATUS_JAMMED},
  {
  5, 0x1a, 0x0, Sane.STATUS_INVAL},
  {
  5, 0x20, 0x0, Sane.STATUS_INVAL},
  {
  5, 0x24, 0x0, Sane.STATUS_INVAL},
  {
  5, 0x25, 0x0, Sane.STATUS_INVAL},
  {
  5, 0x26, 0x0, Sane.STATUS_INVAL},
  {
  5, 0x2c, 0x01, Sane.STATUS_INVAL},
  {
  5, 0x2c, 0x02, Sane.STATUS_INVAL},
  {
  5, 0x2c, 0x80, Sane.STATUS_INVAL},
  {
  5, 0x2c, 0x81, Sane.STATUS_INVAL},
  {
  5, 0x2c, 0x82, Sane.STATUS_INVAL},
  {
5, 0x2c, 0x83, Sane.STATUS_INVAL},]

Sane.Status
kvs40xx_sense_handler (Int __Sane.unused__ fd,
		       u_char * sense_buffer, void __Sane.unused__ * arg)
{
  unsigned i
  Sane.Status st = Sane.STATUS_GOOD
  if (sense_buffer[2] & 0xf)
    {				/*error */
      for (i = 0; i < sizeof (s_errors) / sizeof (s_errors[0]); i++)
	{
	  if ((sense_buffer[2] & 0xf) == s_errors[i].sense
	      && sense_buffer[12] == s_errors[i].asc
	      && sense_buffer[13] == s_errors[i].ascq)
	    {
	      st = s_errors[i].st
	      break
	    }
	}
      if (i == sizeof (s_errors) / sizeof (s_errors[0]))
	st = Sane.STATUS_IO_ERROR
    }
  else
    {
      if (sense_buffer[2] & END_OF_MEDIUM)
	st = Sane.STATUS_EOF
      else if (sense_buffer[2] & INCORRECT_LENGTH_INDICATOR)
	st = INCORRECT_LENGTH
    }

  DBG (DBG_ERR,
       "send_command: CHECK_CONDITION: sense:0x%x ASC:0x%x ASCQ:0x%x\n",
       sense_buffer[2], sense_buffer[12], sense_buffer[13])

  return st
}

static Sane.Status
send_command (struct scanner * s, struct cmd * c)
{
  Sane.Status st = Sane.STATUS_GOOD
  if (s.bus == USB)
    {
      struct response r
      memset (&r, 0, sizeof (r))
      st = usb_send_command (s, c, &r, s.buffer)
      if (st)
	return st
      if (r.status)
	{
	  u8 b[sizeof (struct bulk_header) + RESPONSE_SIZE]
	  struct cmd c2 = {
            {0}, 6,
	    NULL, RESPONSE_SIZE,
	    CMD_IN
	  ]
	  c2.cmd[0] = REQUEST_SENSE
	  c2.cmd[4] = RESPONSE_SIZE

	  st = usb_send_command (s, &c2, &r, b)
	  if (st)
	    return st
	  st = kvs40xx_sense_handler (0, b + sizeof (struct bulk_header), NULL)
	}
    }
  else
    {
      if (c.dir == CMD_OUT)
	{
	  memcpy (s.buffer, c.cmd, c.cmd_size)
	  memcpy (s.buffer + c.cmd_size, c.data, c.data_size)
	  st = sanei_scsi_cmd (s.file, s.buffer,
			       c.cmd_size + c.data_size, NULL, NULL)
	}
      else if (c.dir == CMD_IN)
	{
	  c.data = s.buffer
	  st = sanei_scsi_cmd (s.file, c.cmd, c.cmd_size,
			       c.data, (size_t *) & c.data_size)
	}
      else
	{
	  st = sanei_scsi_cmd (s.file, c.cmd, c.cmd_size, NULL, NULL)
	}
    }
  return st
}

Sane.Status
kvs40xx_test_unit_ready (struct scanner * s)
{
  struct cmd c = {
    {0}, 6,
    NULL, 0,
    CMD_NONE
  ]
  c.cmd[0] = TEST_UNIT_READY
  if (send_command (s, &c))
    return Sane.STATUS_DEVICE_BUSY

  return Sane.STATUS_GOOD
}

Sane.Status
kvs40xx_set_timeout (struct scanner * s, Int timeout)
{
  u16 t = cpu2be16 ((u16) timeout)
  struct cmd c = {
    {0}, 10,
    NULL, 0,
    CMD_OUT
  ]
  c.data = &t
  c.data_size = sizeof (t)
  c.cmd[0] = SET_TIMEOUT
  c.cmd[2] = 0x8d
  copy16 (c.cmd + 7, cpu2be16 (sizeof (t)))
  if (s.bus == USB)
    sanei_usb_set_timeout (timeout * 1000)

  return send_command (s, &c)
}

Sane.Status
kvs40xx_set_window (struct scanner * s, Int wnd_id)
{
  struct window wnd
  struct cmd c = {
    {0}, 10,
    NULL, 0,
    CMD_OUT
  ]
  c.data = &wnd
  c.data_size = sizeof (wnd)
  c.cmd[0] = SET_WINDOW
  copy16 (c.cmd + 7, cpu2be16 (sizeof (wnd)))
  kvs40xx_init_window (s, &wnd, wnd_id)

  return send_command (s, &c)
}

Sane.Status
kvs40xx_reset_window (struct scanner * s)
{
  struct cmd c = {
    {0}, 10,
    NULL, 0,
    CMD_NONE
  ]
  c.cmd[0] = SET_WINDOW

  return send_command (s, &c)
}

Sane.Status
kvs40xx_scan (struct scanner * s)
{
  struct cmd c = {
    {0}, 6,
    NULL, 0,
    CMD_NONE
  ]
  c.cmd[0] = SCAN
  return send_command (s, &c)
}

Sane.Status
hopper_down (struct scanner * s)
{
  struct cmd c = {
    {0}, 10,
    NULL, 0,
    CMD_NONE
  ]
  c.cmd[0] = HOPPER_DOWN
  c.cmd[2] = 5

  if (s.id == KV_S7075C)
    return Sane.STATUS_GOOD
  return send_command (s, &c)
}

Sane.Status
stop_adf (struct scanner * s)
{
  struct cmd c = {
    {0}, 10,
    NULL, 0,
    CMD_NONE
  ]
  c.cmd[0] = STOP_ADF
  c.cmd[2] = 0x8b
  return send_command (s, &c)
}

Sane.Status
kvs40xx_document_exist (struct scanner * s)
{
  Sane.Status status
  struct cmd c = {
    {0}, 10,
    NULL, 6,
    CMD_IN
  ]
  u8 *d
  c.cmd[0] = READ_10
  c.cmd[2] = 0x81
  set24 (c.cmd + 6, c.data_size)
  status = send_command (s, &c)
  if (status)
    return status
  d = c.data
  if (d[0] & 0x20)
    return Sane.STATUS_GOOD

  return Sane.STATUS_NO_DOCS
}

Sane.Status
kvs40xx_read_picture_element (struct scanner * s, unsigned side,
			      Sane.Parameters * p)
{
  Sane.Status status
  struct cmd c = {
     {0}, 10,
     NULL, 16,
     CMD_IN
  ]
  u32 *data
  c.cmd[0] = READ_10
  c.cmd[2] = 0x80
  c.cmd[5] = side
  set24 (c.cmd + 6, c.data_size)

  status = send_command (s, &c)
  if (status)
    return status
  data = (u32 *) c.data
  p.pixels_per_line = be2cpu32 (data[0])
  p.lines = be2cpu32 (data[1])

  return Sane.STATUS_GOOD
}

Sane.Status
get_buffer_status (struct scanner * s, unsigned *data_avalible)
{
  Sane.Status status
  struct cmd c = {
    {0}, 10,
    NULL, 12,
    CMD_IN
  ]
  c.cmd[0] = GET_BUFFER_STATUS
  c.cmd[7] = 12

  status = send_command (s, &c)
  if (status)
    return status
  *data_avalible = get24 ((unsigned char *)c.data + 9)
  return Sane.STATUS_GOOD
}

Sane.Status
kvs40xx_read_image_data (struct scanner * s, unsigned page, unsigned side,
			 void *buf, unsigned max_size, unsigned *size)
{
  Sane.Status status
  struct cmd c = {
    {0}, 10,
    NULL, 0,
    CMD_IN
  ]
  c.data_size = max_size < MAX_READ_DATA_SIZE ? max_size : MAX_READ_DATA_SIZE
  c.cmd[0] = READ_10
  c.cmd[4] = page
  c.cmd[5] = side

  set24 (c.cmd + 6, c.data_size)
  *size = 0
  status = send_command (s, &c)

  if (status && status != Sane.STATUS_EOF && status != INCORRECT_LENGTH)
    return status

  *size = c.data_size
  memcpy (buf, c.data, *size)
  return status
}

Sane.Status
read_support_info (struct scanner * s, struct support_info * inf)
{
  Sane.Status st
  struct cmd c = {
    {0}, 10,
    NULL, sizeof (*inf),
    CMD_IN
  ]

  c.cmd[0] = READ_10
  c.cmd[2] = SUPPORT_INFO
  set24 (c.cmd + 6, c.data_size)

  st = send_command (s, &c)
  if (st)
    return st
  memcpy (inf, c.data, sizeof (*inf))
  return Sane.STATUS_GOOD
}

Sane.Status
inquiry (struct scanner * s, char *id)
{
  var i: Int
  Sane.Status st
  struct cmd c = {
    {0}, 5,
    NULL, 0x60,
    CMD_IN
  ]

  c.cmd[0] = INQUIRY
  c.cmd[4] = c.data_size

  st = send_command (s, &c)
  if (st)
    return st
  memcpy (id, (unsigned char *)c.data + 16, 16)
  for (i = 0; i < 15 && id[i] != ' '; i++)
  id[i] = 0
  return Sane.STATUS_GOOD
}
