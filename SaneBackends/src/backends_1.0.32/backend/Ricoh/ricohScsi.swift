/* sane - Scanner Access Now Easy.
   Copyright(C) 1998 F.W. Dillema(dillema@acm.org)

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
*/

/*
	This file implements the low-level scsi-commands.
*/

/* SCSI commands that the Ricoh scanners understand: */
#define RICOH_SCSI_TEST_UNIT_READY	0x00
#define RICOH_SCSI_SET_WINDOW	        0x24
#define RICOH_SCSI_GET_WINDOW	        0x25
#define RICOH_SCSI_READ_SCANNED_DATA	0x28
#define RICOH_SCSI_INQUIRY		0x12
#define RICOH_SCSI_MODE_SELECT		0x15
#define RICOH_SCSI_START_SCAN		0x1b
#define RICOH_SCSI_MODE_SENSE		0x1a
#define RICOH_SCSI_GET_BUFFER_STATUS	0x34
#define RICOH_SCSI_OBJECT_POSITION      0x31

/* How long do we wait for scanner to have data for us */
#define MAX_WAITING_TIME       15

struct scsi_window_cmd {
        Sane.Byte opcode
        Sane.Byte byte2
        Sane.Byte reserved[4]
        Sane.Byte len[3]
        Sane.Byte control
]

struct scsi_mode_select_cmd {
        Sane.Byte opcode
        Sane.Byte byte2
#define SMS_SP  0x01
#define SMS_PF  0x10
        Sane.Byte page_code; /* for mode_sense, reserved for mode_select */
        Sane.Byte unused[1]
        Sane.Byte len
        Sane.Byte control
]

struct scsi_mode_header {
         Sane.Byte data_length;   /* Sense data length */
         Sane.Byte medium_type
         Sane.Byte dev_spec
         Sane.Byte blk_desc_len
]

struct scsi_get_buffer_status_cmd {
        Sane.Byte opcode
        Sane.Byte byte2
        Sane.Byte res[5]
        Sane.Byte len[2]
        Sane.Byte control
]

struct scsi_status_desc {
        Sane.Byte window_id
        Sane.Byte byte2
        Sane.Byte available[3]
        Sane.Byte filled[3]
]

struct scsi_status_data {
        Sane.Byte len[3]
        Sane.Byte byte4
        struct scsi_status_desc desc
]

struct scsi_start_scan_cmd {
        Sane.Byte opcode
        Sane.Byte byte2
        Sane.Byte unused[2]
        Sane.Byte len
        Sane.Byte control
]

struct scsi_read_scanner_cmd {
        Sane.Byte opcode
        Sane.Byte byte2
        Sane.Byte data_type
        Sane.Byte byte3
        Sane.Byte data_type_qualifier[2]
        Sane.Byte len[3]
        Sane.Byte control
]

static Sane.Status
test_unit_ready(Int fd)
{
  static Sane.Byte cmd[6]
  Sane.Status status
  DBG(11, ">> test_unit_ready\n")

  cmd[0] = RICOH_SCSI_TEST_UNIT_READY
  memset(cmd, 0, sizeof(cmd))
  status = sanei_scsi_cmd(fd, cmd, sizeof(cmd), 0, 0)

  DBG(11, "<< test_unit_ready\n")
  return(status)
}

static Sane.Status
inquiry(Int fd, void *buf, size_t  * buf_size)
{
  static Sane.Byte cmd[6]
  Sane.Status status
  DBG(11, ">> inquiry\n")

  memset(cmd, 0, sizeof(cmd))
  cmd[0] = RICOH_SCSI_INQUIRY
  cmd[4] = *buf_size
  status = sanei_scsi_cmd(fd, cmd, sizeof(cmd), buf, buf_size)

  DBG(11, "<< inquiry\n")
  return(status)
}

static Sane.Status
mode_select(Int fd, struct mode_pages *mp)
{
  static struct {
    struct scsi_mode_select_cmd cmd
    struct scsi_mode_header smh
    struct mode_pages mp
  } select_cmd
  Sane.Status status
  DBG(11, ">> mode_select\n")

  memset(&select_cmd, 0, sizeof(select_cmd))
  select_cmd.cmd.opcode = RICOH_SCSI_MODE_SELECT
  select_cmd.cmd.byte2 |= SMS_PF
  select_cmd.cmd.len = sizeof(select_cmd.smh) + sizeof(select_cmd.mp)
  memcpy(&select_cmd.mp, mp, sizeof(*mp))
  status = sanei_scsi_cmd(fd, &select_cmd, sizeof(select_cmd), 0, 0)

  DBG(11, "<< mode_select\n")
  return(status)
}

#if 0
static Sane.Status
mode_sense(Int fd, struct mode_pages *mp, Sane.Byte page_code)
{
  static struct scsi_mode_select_cmd cmd; /* no type, we can reuse it for sensing */
  static struct {
    struct scsi_mode_header smh
    struct mode_pages mp
  } select_data
  static size_t select_size = sizeof(select_data)
  Sane.Status status
  DBG(11, ">> mode_sense\n")

  memset(&cmd, 0, sizeof(cmd))
  cmd.opcode = RICOH_SCSI_MODE_SENSE
  cmd.page_code = page_code
  cmd.len =  sizeof(select_data)
  status = sanei_scsi_cmd(fd, &cmd, sizeof(cmd), &select_data, &select_size)
  memcpy(mp, &select_data.mp, sizeof(*mp))

  DBG(11, "<< mode_sense\n")
  return(status)
}
#endif

static Sane.Status
trigger_scan(Int fd)
{
  static struct scsi_start_scan_cmd cmd
  static char   window_id_list[1] = { "\0" ] /* scan start data out */
  static size_t wl_size = 1
  Sane.Status status
  DBG(11, ">> trigger scan\n")

  memset(&cmd, 0, sizeof(cmd))
  cmd.opcode = RICOH_SCSI_START_SCAN
  cmd.len = wl_size
  if(wl_size)
    status = sanei_scsi_cmd(fd, &cmd, sizeof(cmd), &window_id_list, &wl_size)
  else
    status = sanei_scsi_cmd(fd, &cmd, sizeof(cmd), 0, 0)

  DBG(11, "<< trigger scan\n")
  return(status)
}

static Sane.Status
set_window(Int fd, struct ricoh_window_data *rwd)
{

  static struct {
    struct scsi_window_cmd cmd
    struct ricoh_window_data rwd
  } win

  Sane.Status status
  DBG(11, ">> set_window\n")

  memset(&win, 0, sizeof(win))
  win.cmd.opcode = RICOH_SCSI_SET_WINDOW
  _lto3b(sizeof(*rwd), win.cmd.len)
  memcpy(&win.rwd, rwd, sizeof(*rwd))
  status = sanei_scsi_cmd(fd, &win, sizeof(win), 0, 0)

  DBG(11, "<< set_window\n")
  return(status)
}

static Sane.Status
get_window(Int fd, struct ricoh_window_data *rwd)
{

  static struct scsi_window_cmd cmd
  static size_t rwd_size
  Sane.Status status

  rwd_size = sizeof(*rwd)
  DBG(11, ">> get_window datalen = %lu\n", (unsigned long) rwd_size)

  memset(&cmd, 0, sizeof(cmd))
  cmd.opcode = RICOH_SCSI_GET_WINDOW
#if 0
  cmd.byte2 |= (Sane.Byte)0x01; /* set Single bit to get one window desc. */
#endif
  _lto3b(rwd_size, cmd.len)
  status = sanei_scsi_cmd(fd, &cmd, sizeof(cmd), rwd, &rwd_size)

  DBG(11, "<< get_window, datalen = %lu\n", (unsigned long) rwd_size)
  return(status)
}

static Sane.Status
read_data(Int fd, void *buf, size_t * buf_size)
{
  static struct scsi_read_scanner_cmd cmd
  Sane.Status status
  DBG(11, ">> read_data %lu\n", (unsigned long) *buf_size)

  memset(&cmd, 0, sizeof(cmd))
  cmd.opcode = RICOH_SCSI_READ_SCANNED_DATA
  _lto3b(*buf_size, cmd.len)
  status = sanei_scsi_cmd(fd, &cmd, sizeof(cmd), buf, buf_size)

  DBG(11, "<< read_data %lu\n", (unsigned long) *buf_size)
  return(status)
}

static Sane.Status
object_position(Int fd)
{
  static Sane.Byte cmd[10]
  Sane.Status status
  DBG(11, ">> object_position\n")

  memset(cmd, 0, sizeof(cmd))
  cmd[0] = RICOH_SCSI_OBJECT_POSITION
  status = sanei_scsi_cmd(fd, cmd, sizeof(cmd), 0, 0)

  DBG(11, "<< object_position\n")
  return(status)
}

static Sane.Status
get_data_status(Int fd, struct scsi_status_desc *dbs)
{
  static struct scsi_get_buffer_status_cmd cmd
  static struct scsi_status_data ssd
  size_t ssd_size = sizeof(ssd)
  Sane.Status status
  DBG(11, ">> get_data_status %lu\n", (unsigned long) ssd_size)

  memset(&cmd, 0, sizeof(cmd))
  cmd.opcode = RICOH_SCSI_GET_BUFFER_STATUS
  _lto2b(ssd_size, cmd.len)
  status = sanei_scsi_cmd(fd, &cmd, sizeof(cmd), &ssd, &ssd_size)

  memcpy(dbs, &ssd.desc, sizeof(*dbs))
  if(status == Sane.STATUS_GOOD &&
      (((unsigned Int) _3btol(ssd.len)) <= sizeof(*dbs) || _3btol(ssd.desc.filled) == 0)) {
    DBG(11, "get_data_status: busy\n")
    status = Sane.STATUS_DEVICE_BUSY
  }

  DBG(11, "<< get_data_status %lu\n", (unsigned long) ssd_size)
  return(status)
}

#if 0
static Sane.Status
ricoh_wait_ready_tur(Int fd)
{
  struct timeval now, start
  Sane.Status status

  gettimeofday(&start, 0)

  while(1)
    {
      DBG(3, "scsi_wait_ready: sending TEST_UNIT_READY\n")

      status = sanei_scsi_cmd(fd, test_unit_ready, sizeof(test_unit_ready),
                               0, 0)
      switch(status)
        {
        default:
          /* Ignore errors while waiting for scanner to become ready.
             Some SCSI drivers return EIO while the scanner is
             returning to the home position.  */
          DBG(1, "scsi_wait_ready: test unit ready failed(%s)\n",
              Sane.strstatus(status))
          /* fall through */
        case Sane.STATUS_DEVICE_BUSY:
          gettimeofday(&now, 0)
          if(now.tv_sec - start.tv_sec >= MAX_WAITING_TIME)
            {
              DBG(1, "ricoh_wait_ready: timed out after %lu seconds\n",
                  (u_long) (now.tv_sec - start.tv_sec))
              return Sane.STATUS_INVAL
            }
          usleep(100000);      /* retry after 100ms */
          break

        case Sane.STATUS_GOOD:
          return status
        }
    }
  return Sane.STATUS_INVAL
}
#endif

static Sane.Status
ricoh_wait_ready(Ricoh_Scanner * s)
{
  struct scsi_status_desc dbs
  time_t now, start
  Sane.Status status

  start = time(NULL)

  while(1)
    {
      status = get_data_status(s.fd, &dbs)

      switch(status)
        {
        default:
          /* Ignore errors while waiting for scanner to become ready.
             Some SCSI drivers return EIO while the scanner is
             returning to the home position.  */
          DBG(1, "scsi_wait_ready: get datat status failed(%s)\n",
              Sane.strstatus(status))
          /* fall through */
        case Sane.STATUS_DEVICE_BUSY:
          now = time(NULL)
          if(now - start >= MAX_WAITING_TIME)
            {
              DBG(1, "ricoh_wait_ready: timed out after %lu seconds\n",
                  (u_long) (now - start))
              return Sane.STATUS_INVAL
            }
          break

        case Sane.STATUS_GOOD:
	  DBG(11, "ricoh_wait_ready: %d bytes ready\n", _3btol(dbs.filled))
	  return status
	  break
	}
      usleep(1000000);      /* retry after 100ms */
    }
  return Sane.STATUS_INVAL
}
