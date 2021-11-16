/* sane - Scanner Access Now Easy.

   ScanMaker 3840 Backend
   Copyright (C) 2005 Earle F. Philhower, III
   earle@ziplabel.com - http://www.ziplabel.com

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

*/

#include <stdio.h>
#include <stdarg.h>
import sm3840_lib

#ifndef BACKENDNAME
static void setup_scan (p_usb_dev_handle udev, SM3840_Params * p,
			char *stname, Int raw, Int nohead);
#else
static void setup_scan (p_usb_dev_handle udev, SM3840_Params * p);
#endif


#ifndef BACKENDNAME

import sm3840_lib.c"

func Int main (Int argc, char *argv[])
{
  var i: Int;

  Int gray = 0;
  Int dpi = 1200;
  Int bpp16 = 0;
  Int raw = 0;
  Int nohead = 0;
  double gain = 3.5;
  Int offset = 1800;
  usb_dev_handle *udev;

  char *stname;
  double topin, botin, leftin, rightin;
  Int topline, scanlines, leftpix, scanpix;

  stname = NULL;
  topin = 0.0;
  botin = 11.7;
  leftin = 0.0;
  rightin = 8.5;
  for (i = 1; i < argc; i++)
    {
      if (!strcmp (argv[i], "-300"))
	dpi = 300;
      else if (!strcmp (argv[i], "-600"))
	dpi = 600;
      else if (!strcmp (argv[i], "-1200"))
	dpi = 1200;
      else if (!strcmp (argv[i], "-150"))
	dpi = 150;
      else if (!strcmp (argv[i], "-top"))
	topin = atof (argv[++i]);
      else if (!strcmp (argv[i], "-bot"))
	botin = atof (argv[++i]);
      else if (!strcmp (argv[i], "-left"))
	leftin = atof (argv[++i]);
      else if (!strcmp (argv[i], "-right"))
	rightin = atof (argv[++i]);
      else if (!strcmp (argv[i], "-gain"))
	gain = atof (argv[++i]);
      else if (!strcmp (argv[i], "-offset"))
	offset = atoi (argv[++i]);
      else if (!strcmp (argv[i], "-gray"))
	gray = 1;
      else if (!strcmp (argv[i], "-16bpp"))
	bpp16 = 1;
      else if (!strcmp (argv[i], "-raw"))
	raw = 1;
      else if (!strcmp (argv[i], "-nohead"))
	nohead = 1;
      else
	stname = argv[i];
    }

  SM3840_Params params;
  params.gray = gray;
  params.dpi = dpi;
  params.bpp = bpp16 ? 16 : 8;
  params.gain = gain;
  params.offset = offset;
  params.lamp = 15;
  params.top = topin;
  params.left = leftin;
  params.height = botin - topin;
  params.width = rightin - leftin;

  prepare_params (&params);
  udev = find_device (0x05da, 0x30d4); /* 3840 */
  if (!udev)
    udev = find_device (0x05da, 0x30cf); /* 4800 */
  if (!udev)
    fprintf (stderr, "Unable to open scanner.\n");
  else
    setup_scan (udev, &params, stname, raw, nohead);

  return 0;
}
#endif

#ifndef BACKENDNAME
static void
setup_scan (p_usb_dev_handle udev, SM3840_Params * p,
	    char *stname, Int raw, Int nohead)
#else
static void
setup_scan (p_usb_dev_handle udev, SM3840_Params * p)
#endif
{
  Int gray = p->gray ? 1 : 0;
  Int dpi = p->dpi;
  Int bpp16 = (p->bpp == 16) ? 1 : 0;
  double gain = p->gain;
  Int offset = p->offset;
  Int topline = p->topline;
  Int scanlines = p->scanlines;
  Int leftpix = p->leftpix;
  Int scanpix = p->scanpix;
  unsigned char hello[2] = { 0x55, 0xaa ]
  unsigned char howdy[3];
  unsigned short *whitebalance;
  Int whitebalancesize = (dpi == 1200) ? 12672 : 6528;
  unsigned short *whitemap;
  Int whitemapsize = (dpi == 1200) ? 29282 : 14642;
  unsigned short *whitescan;
  unsigned short *lightmap;
  unsigned Int topreg, botreg;
  Int redreg, greenreg, bluereg, donered, donegreen, doneblue;
  Int rgreg = 0x00;
  Int ggreg = 0x00;
  Int bgreg = 0x00;
  var i: Int, j;
  Int red, green, blue;
  unsigned char rd_byte;
  unsigned short GRAYMASK = 0xc000;


#ifndef BACKENDNAME
  char fname[64];
  char head[128];

  usb_set_configuration (udev, 1);
  usb_claim_interface (udev, 0);
  usb_clear_halt (udev, 1);
  usb_clear_halt (udev, 2);
  usb_clear_halt (udev, 3);
#endif
  DBG (2, "params.gray = %d;\n", p->gray);
  DBG (2, "params.dpi = %d\n", p->dpi);
  DBG (2, "params.bpp = %d\n", p->bpp);
  DBG (2, "params.gain = %f\n", p->gain);
  DBG (2, "params.offset = %d\n", p->offset);
  DBG (2, "params.lamp = %d\n", p->lamp);
  DBG (2, "params.top = %f\n", p->top);
  DBG (2, "params.left = %f\n", p->left);
  DBG (2, "params.height = %f\n", p->height);
  DBG (2, "params.width = %f\n", p->width);

  DBG (2, "params.topline = %d\n", p->topline);
  DBG (2, "params.scanlines = %d\n", p->scanlines);
  DBG (2, "params.leftpix = %d\n", p->leftpix);
  DBG (2, "params.scanpix = %d\n", p->scanpix);

  DBG (2, "params.linelen = %d\n", p->linelen);

  reset_scanner (udev);

  idle_ab (udev);
  write_regs (udev, 4, 0x83, 0x00, 0xa3, 0x00, 0xa4, 0x00, 0x97, 0x0a);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0b);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0f);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x05);
  write_vctl (udev, 0x0b, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 7, 0xa8, 0x80, 0x83, 0xa2, 0x85, 0x01, 0x83, 0x82, 0x85,
	      0x00, 0x83, 0x00, 0x93, 0x00);
  write_regs (udev, 1, 0xa8, 0x80);
  write_regs (udev, 4, 0x83, 0x00, 0xa3, 0x00, 0xa4, 0x00, 0x97, 0x0a);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0b);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0f);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x05);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 4, 0x83, 0x20, 0x8d, 0xfe, 0x83, 0x00, 0x8d, 0xff);
  write_regs (udev, 1, 0x97, 0x00);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 8, 0x80, 0x00, 0x84, 0x00, 0xbe, 0x00, 0xc0, 0x00, 0x86,
	      0x00, 0x89, 0x00, 0x94, 0x00, 0x01, 0x02);
  write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
  write_regs (udev, 1, 0x94, 0x51);
  write_regs (udev, 1, 0xb0, 0x00);
  write_regs (udev, 1, 0xb1, 0x00);
  write_regs (udev, 1, 0xb2, 0x00);
  write_regs (udev, 1, 0xb3, 0x00);
  write_regs (udev, 1, 0xb4, 0x10);
  write_regs (udev, 1, 0xb5, 0x1f);
  write_regs (udev, 1, 0xb0, 0x00);
  write_regs (udev, 1, 0xb1, 0x00);
  write_regs (udev, 1, 0xb2, 0x00);
  write_vctl (udev, 0x0c, 0x0002, 0x0002, 0x00);
  usb_bulk_write (udev, 2, hello, 2, wr_timeout);
  write_regs (udev, 1, 0xb0, 0x00);
  write_regs (udev, 1, 0xb1, 0x00);
  write_regs (udev, 1, 0xb2, 0x00);
  write_vctl (udev, 0x0c, 0x0003, 0x0003, 0x00);
  usb_bulk_read (udev, 1, howdy, 3, rd_timeout);
  write_regs (udev, 4, 0x83, 0x00, 0xa3, 0x00, 0xa4, 0x00, 0x97, 0x0a);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0b);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0f);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x05);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 4, 0x83, 0x20, 0x8d, 0xfe, 0x83, 0x00, 0x8d, 0xff);
  write_regs (udev, 1, 0x97, 0x00);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 8, 0x80, 0x00, 0x84, 0x00, 0xbe, 0x00, 0xc0, 0x00, 0x86,
	      0x00, 0x89, 0x00, 0x94, 0x00, 0x01, 0x02);
  write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
  write_regs (udev, 16, 0xbe, 0x18, 0x80, 0x00, 0x84, 0x00, 0x89, 0x00, 0x88,
	      0x00, 0x86, 0x00, 0x90, 0x00, 0xc1, 0x00, 0xc2, 0x00, 0xc3,
	      0x00, 0xc4, 0x00, 0xc5, 0x00, 0xc6, 0x00, 0xc7, 0x00, 0xc8,
	      0x00, 0xc0, 0x00);
  write_regs (udev, 4, 0x83, 0x20, 0x8d, 0xff, 0x83, 0x00, 0x8d, 0xff);
  write_regs (udev, 5, 0x83, 0x00, 0xa3, 0xff, 0xa4, 0xff, 0xa1, 0xff, 0xa2,
	      0xf7);
  write_regs (udev, 4, 0x83, 0x22, 0x87, 0x01, 0x83, 0x02, 0x87, 0x16);
  write_regs (udev, 11, 0xa0, 0x00, 0x9c, 0x00, 0x9f, 0x00, 0x9d, 0x00, 0x9e,
	      0x00, 0xa0, 0x00, 0xce, 0x0c, 0x83, 0x20, 0xa5, 0x00, 0xa6,
	      0x00, 0xa7, 0x00);

  set_gain_black (udev, 0x01, 0x01, 0x01, 0xaa, 0xaa, 0xaa);

  write_regs (udev, 16, 0x9b, 0x00, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
	      0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b, 0x02, 0x98,
	      0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b, 0x03, 0x98, 0x00, 0x99,
	      0x00, 0x9a, 0x00);
  write_regs (udev, 4, 0x83, 0xa2, 0x85, 0x98, 0x83, 0x82, 0x85, 0x3a);
  write_regs (udev, 1, 0x9d, 0x80);
  write_regs (udev, 1, 0x9d, 0x00);

  if (dpi == 1200)
    write_regs (udev, 1, 0x94, 0x51);
  else
    write_regs (udev, 1, 0x94, 0x61);

  whitemap = (unsigned short *) malloc (whitemapsize);

  set_lightmap_white (whitemap, dpi, 0);
  if (dpi == 1200)
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x80, 0xb2, 0x06, 0xb3, 0xff, 0xb4,
		0xff, 0xb5, 0x06);
  else
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x40, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0x7f, 0xb5, 0x07);
  write_vctl (udev, 0x0c, 0x0002, whitemapsize, 0x00);
  usb_bulk_write (udev, 2, (unsigned char *) whitemap, whitemapsize,
                  wr_timeout);

  set_lightmap_white (whitemap, dpi, 1);
  if (dpi == 1200)
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0x7f, 0xb5, 0x07);
  else
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x80, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0xbf, 0xb5, 0x07);
  write_vctl (udev, 0x0c, 0x0002, whitemapsize, 0x00);
  usb_bulk_write (udev, 2, (unsigned char *) whitemap, whitemapsize,
                  wr_timeout);

  set_lightmap_white (whitemap, dpi, 2);
  if (dpi == 1200)
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x80, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0xff, 0xb5, 0x07);
  else
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0xc0, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0xff, 0xb5, 0x07);
  write_vctl (udev, 0x0c, 0x0002, whitemapsize, 0x00);
  usb_bulk_write (udev, 2, (unsigned char *) whitemap, whitemapsize,
                  wr_timeout);

  free (whitemap);

  /* Move to head... */
  idle_ab (udev);
  write_regs (udev, 1, 0x97, 0x00);
  idle_ab (udev);
  write_regs (udev, 16, 0xbe, 0x18, 0x80, 0x00, 0x84, 0x00, 0x89, 0x00, 0x88,
	      0x00, 0x86, 0x00, 0x90, 0x00, 0xc1, 0x00, 0xc2, 0x00, 0xc3,
	      0x00, 0xc4, 0x00, 0xc5, 0x00, 0xc6, 0x00, 0xc7, 0x00, 0xc8,
	      0x00, 0xc0, 0x00);
  idle_ab (udev);
  write_regs (udev, 16, 0x84, 0x94, 0x80, 0xd1, 0x80, 0xc1, 0x82, 0x7f, 0xcf,
	      0x04, 0xc1, 0x02, 0xc2, 0x00, 0xc3, 0x06, 0xc4, 0xff, 0xc5,
	      0x40, 0xc6, 0x8c, 0xc7, 0xdc, 0xc8, 0x20, 0xc0, 0x72, 0x89,
	      0xff, 0x86, 0xff);
  poll1 (udev);

  write_regs (udev, 4, 0x83, 0xa2, 0x85, 0x01, 0x83, 0x82, 0x85, 0x00);
  write_regs (udev, 1, 0x9d, 0x80);
  write_regs (udev, 1, 0x9d, 0x00);
  if (dpi == 1200)
    write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8, 0x77,
		0xb9, 0x1e);
  else
    write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8, 0x3b,
		0xb9, 0x1f);
  write_regs (udev, 5, 0xc0, 0x00, 0x84, 0x00, 0x80, 0xa1, 0xcf, 0x04, 0x82,
	      0x00);
  if (dpi == 1200)
    write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x02, 0x83, 0x82, 0x85, 0x00,
		0xbc, 0x01, 0xbd, 0x01, 0x88, 0xa4, 0xc1, 0x02, 0xc2, 0x00,
		0xc3, 0x02, 0xc4, 0x01, 0xc5, 0x01, 0xc6, 0xa3, 0xc7, 0xa4,
		0xc8, 0x04, 0xc0, 0xd2, 0x89, 0x05, 0x86, 0x00);
  else
    write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x04, 0x83, 0x82, 0x85, 0x00,
		0xbc, 0x01, 0xbd, 0x01, 0x88, 0xd0, 0xc1, 0x01, 0xc2, 0x00,
		0xc3, 0x04, 0xc4, 0x01, 0xc5, 0x01, 0xc6, 0xcf, 0xc7, 0xd0,
		0xc8, 0x14, 0xc0, 0xd1, 0x89, 0x0a, 0x86, 0x00);
  write_regs (udev, 8, 0xbb, 0x01, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80, 0xbf,
	      0x00, 0x90, 0x40, 0x91, 0x00, 0x83, 0x82);
  write_regs (udev, 1, 0xbe, 0x0d);
  write_vctl (udev, 0x0c, 0x0003, 0x0001, 0x00);
  whitebalance = (unsigned short *) malloc (whitebalancesize);
  usb_bulk_read (udev, 1, &rd_byte, 1, rd_timeout);
  write_vctl (udev, 0x0c, 0x0001, 0x0000, 0x00);
  usb_bulk_read (udev, 1, (unsigned char *) whitebalance, whitebalancesize,
                 rd_timeout);
  write_regs (udev, 2, 0xbe, 0x00, 0x84, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
  redreg = greenreg = bluereg = 0x80;
  red = green = blue = 0;
  donered = donegreen = doneblue = 0;
  DBG (2, "setting blackpoint\n");
  for (j = 0; (j < 16) && !(donered && donegreen && doneblue); j++)
    {
      set_gain_black (udev, 0x01, 0x01, 0x01, redreg, greenreg, bluereg);

      if (dpi == 1200)
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0x77, 0xb9, 0x1e);
      else
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0x3b, 0xb9, 0x1f);
      write_regs (udev, 8, 0xbb, 0x01, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		  0xbf, 0x00, 0x90, 0x40, 0x91, 0x00, 0x83, 0x82);
      write_regs (udev, 1, 0xbe, 0x0d);
      write_vctl (udev, 0x0c, 0x0003, 0x0001, 0x00);
      usb_bulk_read (udev, 1, &rd_byte, 1, rd_timeout);
      write_vctl (udev, 0x0c, 0x0001, 0x0000, 0x00);
      usb_bulk_read (udev, 1, (unsigned char *) whitebalance,
                     whitebalancesize, rd_timeout);
      fix_endian_short (whitebalance, whitebalancesize/2);
      if (!donered)
	{
	  red = (whitebalance[0] + whitebalance[3] + whitebalance[6]) / 3;
	  if (red > 0x1000)
	    redreg += 0x10;
	  else if (red > 0x500)
	    redreg += 0x08;
	  else if (red > 0x0010)
	    redreg++;
	  else
	    donered = 1;
	}
      if (!donegreen)
	{
	  green = (whitebalance[1] + whitebalance[4] + whitebalance[7]) / 3;
	  if (green > 0x1000)
	    greenreg += 0x10;
	  else if (green > 0x0500)
	    greenreg += 0x08;
	  else if (green > 0x0010)
	    greenreg++;
	  else
	    donegreen = 1;
	}
      if (!doneblue)
	{
	  blue = (whitebalance[2] + whitebalance[5] + whitebalance[8]) / 3;
	  if (blue > 0x1000)
	    bluereg += 0x10;
	  else if (blue > 0x0500)
	    bluereg += 0x08;
	  else if (blue > 0x0010)
	    bluereg++;
	  else
	    doneblue = 1;
	}
      DBG (2, "red=%d(%d)%02x, green=%d(%d)%02x, blue=%d(%d)%02x\n",
	   red, donered, redreg, green, donegreen, greenreg,
	   blue, doneblue, bluereg);
      write_regs (udev, 2, 0xbe, 0x00, 0x84, 0x00);
      write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
      write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
    }
  DBG (2, "setting whitepoint\n");
  donegreen = donered = doneblue = 0;
  for (j = 0; (j < 16) && !(donered && donegreen && doneblue); j++)
    {
      set_gain_black (udev, rgreg, ggreg, bgreg, redreg, greenreg, bluereg);

      if (dpi == 1200)
	idle_ab (udev);
      write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		  0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8, 0x3b,
		  0xb9, 0x1f);
      if (dpi == 1200)
	idle_ab (udev);
      write_regs (udev, 8, 0xbb, 0x01, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		  0xbf, 0x00, 0x90, 0x40, 0x91, 0x00, 0x83, 0x82);
      write_regs (udev, 1, 0xbe, 0x0d);
      write_vctl (udev, 0x0c, 0x0003, 0x0001, 0x00);
      usb_bulk_read (udev, 1, &rd_byte, 1, rd_timeout);
      write_vctl (udev, 0x0c, 0x0001, 0x0000, 0x00);
      usb_bulk_read (udev, 1, (unsigned char *) whitebalance,
                     whitebalancesize, rd_timeout);
      fix_endian_short (whitebalance, whitebalancesize/2);
      if (!donered)
	{
	  red =
	    (whitebalance[180 * 3 + 0] + whitebalance[180 * 3 + 3] +
	     whitebalance[180 * 3 + 6]) / 3;
	  if (red < 0x5000)
	    rgreg += 0x02;
	  else if (red < 0x8000)
	    rgreg += 0x01;
	  else
	    donered = 1;
	}
      if (!donegreen)
	{
	  green =
	    (whitebalance[180 * 3 + 1] + whitebalance[180 * 3 + 4] +
	     whitebalance[180 * 3 + 7]) / 3;
	  if (green < 0x5000)
	    ggreg += 0x02;
	  else if (green < 0x8000)
	    ggreg += 0x01;
	  else
	    donegreen = 1;
	}
      if (!doneblue)
	{
	  blue =
	    (whitebalance[180 * 3 + 2] + whitebalance[180 * 3 + 5] +
	     whitebalance[180 * 3 + 8]) / 3;
	  if (blue < 0x5000)
	    bgreg += 0x02;
	  else if (blue < 0x8000)
	    bgreg += 0x01;
	  else
	    doneblue = 1;
	}
      DBG (2, "red=%d(%d)%02x, green=%d(%d)%02x, blue=%d(%d)%02x\n",
	   red, donered, rgreg, green, donegreen, ggreg, blue, doneblue,
	   bgreg);
      write_regs (udev, 2, 0xbe, 0x00, 0x84, 0x00);
      write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
      write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
    }
  free (whitebalance);

  /* One step down for optimal contrast... */
  if (rgreg)
    rgreg--;
  if (bgreg)
    bgreg--;
  if (ggreg)
    ggreg--;


  write_regs (udev, 8, 0x80, 0x00, 0x84, 0x00, 0xbe, 0x00, 0xc0, 0x00, 0x86,
	      0x00, 0x89, 0x00, 0x94, 0x00, 0x01, 0x02);
  write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
  write_regs (udev, 16, 0xbe, 0x18, 0x80, 0x00, 0x84, 0x00, 0x89, 0x00, 0x88,
	      0x00, 0x86, 0x00, 0x90, 0x00, 0xc1, 0x00, 0xc2, 0x00, 0xc3,
	      0x00, 0xc4, 0x00, 0xc5, 0x00, 0xc6, 0x00, 0xc7, 0x00, 0xc8,
	      0x00, 0xc0, 0x00);
  write_regs (udev, 4, 0x83, 0x20, 0x8d, 0xff, 0x83, 0x00, 0x8d, 0xff);
  write_regs (udev, 5, 0x83, 0x00, 0xa3, 0xff, 0xa4, 0xff, 0xa1, 0xff, 0xa2,
	      0xf7);
  write_regs (udev, 4, 0x83, 0x22, 0x87, 0x01, 0x83, 0x02, 0x87, 0x16);
  write_regs (udev, 11, 0xa0, 0x00, 0x9c, 0x00, 0x9f, 0x00, 0x9d, 0x00, 0x9e,
	      0x00, 0xa0, 0x00, 0xce, 0x0c, 0x83, 0x20, 0xa5, 0x00, 0xa6,
	      0x00, 0xa7, 0x00);
  set_gain_black (udev, rgreg, ggreg, bgreg, redreg, greenreg, bluereg);

  write_regs (udev, 16, 0x9b, 0x00, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
	      0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b, 0x02, 0x98,
	      0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b, 0x03, 0x98, 0x00, 0x99,
	      0x00, 0x9a, 0x00);
  write_regs (udev, 4, 0x83, 0xa2, 0x85, 0x98, 0x83, 0x82, 0x85, 0x3a);
  write_regs (udev, 1, 0x9d, 0x80);
  write_regs (udev, 1, 0x9d, 0x00);
  if (dpi == 1200)
    write_regs (udev, 1, 0x94, 0x71);
  else
    write_regs (udev, 1, 0x94, 0x61);

  write_regs (udev, 4, 0x83, 0xa2, 0x85, 0x01, 0x83, 0x82, 0x85, 0x00);
  write_regs (udev, 1, 0x9d, 0x80);
  write_regs (udev, 1, 0x9d, 0x00);
  if (dpi == 1200)
    write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8, 0xbf,
		0xb9, 0x17);
  else
    write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8, 0xdf,
		0xb9, 0x1b);
  write_regs (udev, 6, 0xc0, 0x00, 0x84, 0x00, 0x84, 0xb4, 0x80, 0xe1, 0xcf,
	      0x04, 0x82, 0x00);
  if (dpi == 1200)
    write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x02, 0x83, 0x82, 0x85, 0x00,
		0xbc, 0x20, 0xbd, 0x08, 0x88, 0xa4, 0xc1, 0x02, 0xc2, 0x00,
		0xc3, 0x02, 0xc4, 0x20, 0xc5, 0x08, 0xc6, 0x96, 0xc7, 0xa4,
		0xc8, 0x06, 0xc0, 0xd2, 0x89, 0x24, 0x86, 0x01);
  else
    write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x04, 0x83, 0x82, 0x85, 0x00,
		0xbc, 0x20, 0xbd, 0x10, 0x88, 0xd0, 0xc1, 0x01, 0xc2, 0x00,
		0xc3, 0x04, 0xc4, 0x20, 0xc5, 0x10, 0xc6, 0xc3, 0xc7, 0xd0,
		0xc8, 0x1c, 0xc0, 0xd1, 0x89, 0x24, 0x86, 0x01);
  write_regs (udev, 8, 0xbb, 0x05, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80, 0xbf,
	      0x00, 0x90, 0x40, 0x91, 0x00, 0x83, 0x82);
  write_regs (udev, 1, 0xbe, 0x1d);
  write_vctl (udev, 0x0c, 0x0003, 0x0001, 0x00);
  usb_bulk_read (udev, 1, &rd_byte, 1, rd_timeout);
  write_vctl (udev, 0x0c, 0x0001, 0x0000, 0x00);
  record_mem (udev, (unsigned char **) (void *)&whitescan,
	      (5632 * 2 * 3 * (dpi == 1200 ? 2 : 1)) * 4);
  fix_endian_short (whitescan, (5632 * 2 * 3 * (dpi == 1200 ? 2 : 1)) * 2);
  write_regs (udev, 5, 0x83, 0x00, 0xa3, 0xff, 0xa4, 0xff, 0xa1, 0xff, 0xa2,
	      0xff);
  write_vctl (udev, 0x0c, 0x0001, 0x0000, 0x00);
  write_regs (udev, 2, 0xbe, 0x00, 0x84, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
  write_regs (udev, 4, 0x83, 0x00, 0xa3, 0x00, 0xa4, 0x00, 0x97, 0x0a);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0b);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x0f);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x05);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 4, 0x83, 0x20, 0x8d, 0xff, 0x83, 0x00, 0x8d, 0xff);
  write_regs (udev, 1, 0x97, 0x00);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 1, 0x97, 0x00);
  write_vctl (udev, 0x0c, 0x0004, 0x008b, 0x00);
  read_vctl (udev, 0x0c, 0x0007, 0x0000, &rd_byte);
  write_regs (udev, 16, 0xbe, 0x18, 0x80, 0x00, 0x84, 0x00, 0x89, 0x00, 0x88,
	      0x00, 0x86, 0x00, 0x90, 0x00, 0xc1, 0x00, 0xc2, 0x00, 0xc3,
	      0x00, 0xc4, 0x00, 0xc5, 0x00, 0xc6, 0x00, 0xc7, 0x00, 0xc8,
	      0x00, 0xc0, 0x00);
  write_regs (udev, 16, 0x84, 0x94, 0x80, 0xd1, 0x80, 0xc1, 0x82, 0x7f, 0xcf,
	      0x04, 0xc1, 0x02, 0xc2, 0x00, 0xc3, 0x06, 0xc4, 0xff, 0xc5,
	      0x40, 0xc6, 0x8c, 0xc7, 0xdc, 0xc8, 0x20, 0xc0, 0x72, 0x89,
	      0xff, 0x86, 0xff);
  poll1 (udev);

  /* ready scan position */
  /* 1/3" of unscannable area at top... */
  if (dpi == 300)
    topreg = 120 * 4;
  else if (dpi == 600)
    topreg = 139 * 4;
  else if (dpi == 1200)
    topreg = 152 * 4;
  else				/*if (dpi == 150) */
    topreg = 120 * 4;
  topreg += topline * (1200 / dpi);

  write_regs (udev, 16, 0xbe, 0x18, 0x80, 0x00, 0x84, 0x00, 0x89, 0x00, 0x88,
	      0x00, 0x86, 0x00, 0x90, 0x00, 0xc1, 0x00, 0xc2, 0x00, 0xc3,
	      0x00, 0xc4, 0x00, 0xc5, 0x00, 0xc6, 0x00, 0xc7, 0x00, 0xc8,
	      0x00, 0xc0, 0x00);
  write_regs (udev, 14, 0x84, 0xb4, 0x80, 0xe1, 0xcf, 0x04, 0xc1, 0x02, 0xc2,
	      0x00, 0xc3, 0x07, 0xc4, 0xff, 0xc5, 0x40, 0xc6, 0x8c, 0xc7,
	      0xdc, 0xc8, 0x20, 0xc0, 0x72, 0x89, topreg & 255, 0x86,
	      255 & (topreg >> 8));
  write_regs (udev, 1, 0x97, 0x00);
  poll2 (udev);

  write_regs (udev, 8, 0x80, 0x00, 0x84, 0x00, 0xbe, 0x00, 0xc0, 0x00, 0x86,
	      0x00, 0x89, 0x00, 0x94, 0x00, 0x01, 0x02);
  write_vctl (udev, 0x0c, 0x00c0, 0x8406, 0x00);
  write_vctl (udev, 0x0c, 0x00c0, 0x0406, 0x00);
  write_regs (udev, 16, 0xbe, 0x18, 0x80, 0x00, 0x84, 0x00, 0x89, 0x00, 0x88,
	      0x00, 0x86, 0x00, 0x90, 0x00, 0xc1, 0x00, 0xc2, 0x00, 0xc3,
	      0x00, 0xc4, 0x00, 0xc5, 0x00, 0xc6, 0x00, 0xc7, 0x00, 0xc8,
	      0x00, 0xc0, 0x00);
  if (dpi == 1200)
    write_regs (udev, 4, 0x83, 0x20, 0x8d, 0x24, 0x83, 0x00, 0x8d, 0xff);
  else
    write_regs (udev, 4, 0x83, 0x20, 0x8d, 0xff, 0x83, 0x00, 0x8d, 0xff);
  if (dpi != 1200)
    write_regs (udev, 5, 0x83, 0x00, 0xa3, 0xff, 0xa4, 0xff, 0xa1, 0xff, 0xa2,
		0xf7);
  if (dpi == 1200)
    write_regs (udev, 4, 0x83, 0x22, 0x87, 0x01, 0x83, 0x02, 0x87, 0x2c);
  else
    write_regs (udev, 4, 0x83, 0x22, 0x87, 0x01, 0x83, 0x02, 0x87, 0x16);
  if (dpi == 1200)
    write_regs (udev, 11, 0xa0, 0x00, 0x9c, 0x00, 0x9f, 0x40, 0x9d, 0x00,
		0x9e, 0x00, 0xa0, 0x00, 0xce, 0x0c, 0x83, 0x20, 0xa5, 0x00,
		0xa6, 0x00, 0xa7, 0x00);
  else
    write_regs (udev, 11, 0xa0, 0x00, 0x9c, 0x00, 0x9f, 0x00, 0x9d, 0x00,
		0x9e, 0x00, 0xa0, 0x00, 0xce, 0x0c, 0x83, 0x20, 0xa5, 0x00,
		0xa6, 0x00, 0xa7, 0x00);

  set_gain_black (udev, rgreg, ggreg, bgreg, redreg, greenreg, bluereg);
  if (!bpp16)
    {
      if (dpi == 1200)
	write_regs (udev, 16, 0x9b, 0x00, 0x98, 0xc7, 0x99, 0x99, 0x9a, 0xd5,
		    0x9b, 0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
		    0x02, 0x98, 0xc8, 0x99, 0x99, 0x9a, 0xd3, 0x9b, 0x03,
		    0x98, 0x00, 0x99, 0x00, 0x9a, 0x00);
      else if (dpi == 150)
	write_regs (udev, 16, 0x9b, 0x00, 0x98, 0x94, 0x99, 0x67, 0x9a, 0x83,
		    0x9b, 0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
		    0x02, 0x98, 0x7e, 0x99, 0x5d, 0x9a, 0x7d, 0x9b, 0x03,
		    0x98, 0x00, 0x99, 0x00, 0x9a, 0x00);
      else
	write_regs (udev, 16, 0x9b, 0x00, 0x98, 0xb3, 0x99, 0x72, 0x9a, 0x9d,
		    0x9b, 0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
		    0x02, 0x98, 0xa3, 0x99, 0x6f, 0x9a, 0x94, 0x9b, 0x03,
		    0x98, 0x00, 0x99, 0x00, 0x9a, 0x00);
    }
  else
    {
      if (dpi == 1200)
	write_regs (udev, 16, 0x9b, 0x00, 0x98, 0xb9, 0x99, 0x7a, 0x9a, 0xd6,
		    0x9b, 0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
		    0x02, 0x98, 0xbc, 0x99, 0x7c, 0x9a, 0xd3, 0x9b, 0x03,
		    0x98, 0x00, 0x99, 0x00, 0x9a, 0x00);
      else if (dpi == 150)
	write_regs (udev, 16, 0x9b, 0x00, 0x98, 0x9c, 0x99, 0x5f, 0x9a, 0x87,
		    0x9b, 0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
		    0x02, 0x98, 0x97, 0x99, 0x58, 0x9a, 0x81, 0x9b, 0x03,
		    0x98, 0x00, 0x99, 0x00, 0x9a, 0x00);
      else
	write_regs (udev, 16, 0x9b, 0x00, 0x98, 0x9d, 0x99, 0x79, 0x9a, 0x8e,
		    0x9b, 0x01, 0x98, 0x00, 0x99, 0x00, 0x9a, 0x00, 0x9b,
		    0x02, 0x98, 0x89, 0x99, 0x71, 0x9a, 0x80, 0x9b, 0x03,
		    0x98, 0x00, 0x99, 0x00, 0x9a, 0x00);
    }
  write_regs (udev, 4, 0x83, 0xa2, 0x85, 0x98, 0x83, 0x82, 0x85, 0x3a);
  write_regs (udev, 1, 0x9d, 0x80);
  write_regs (udev, 1, 0x9d, 0x00);
  if (!bpp16)
    {
      if (dpi == 1200)
	write_regs (udev, 1, 0x94, 0x51);
      else
	write_regs (udev, 1, 0x94, 0x41);
    }
  else
    {
      if (dpi == 1200)
	write_regs (udev, 1, 0x94, 0x71);
      else
	write_regs (udev, 1, 0x94, 0x61);
    }
  lightmap = (unsigned short *) malloc (whitemapsize);
  calc_lightmap (whitescan, lightmap, 0, dpi, gain, offset);
  select_pixels (lightmap, dpi, leftpix, scanpix);
  if (dpi == 1200)
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x80, 0xb2, 0x06, 0xb3, 0xff, 0xb4,
		0xff, 0xb5, 0x06);
  else
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x40, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0x7f, 0xb5, 0x07);
  write_vctl (udev, 0x0c, 0x0002, whitemapsize, 0x00);
  usb_bulk_write (udev, 2, (unsigned char *) lightmap, whitemapsize,
                  wr_timeout);

  calc_lightmap (whitescan, lightmap, 1, dpi, gain, offset);
  if (dpi == 1200)
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0x7f, 0xb5, 0x07);
  else
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x80, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0xbf, 0xb5, 0x07);
  write_vctl (udev, 0x0c, 0x0002, whitemapsize, 0x00);
  fix_endian_short (&GRAYMASK, 1);
  if (gray)
    for (i = 0; i < whitemapsize / 2; i++)
      lightmap[i] |= GRAYMASK;
  usb_bulk_write (udev, 2, (unsigned char *) lightmap, whitemapsize,
                  wr_timeout);

  calc_lightmap (whitescan, lightmap, 2, dpi, gain, offset);
  if (dpi == 1200)
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0x80, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0xff, 0xb5, 0x07);
  else
    write_regs (udev, 6, 0xb0, 0x00, 0xb1, 0xc0, 0xb2, 0x07, 0xb3, 0xff, 0xb4,
		0xff, 0xb5, 0x07);
  write_vctl (udev, 0x0c, 0x0002, whitemapsize, 0x00);
  usb_bulk_write (udev, 2, (unsigned char *) lightmap, whitemapsize,
                  wr_timeout);

  free (whitescan);
  free (lightmap);

  if (!bpp16)
    download_lut8 (udev, dpi, gray ? 0 : 1);

  write_regs (udev, 4, 0x83, 0xa2, 0x85, 0x01, 0x83, 0x82, 0x85, 0x00);
  write_regs (udev, 1, 0x9d, 0x80);
  write_regs (udev, 1, 0x9d, 0x00);

  if (!bpp16)
    {
      if (dpi == 1200)
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0x1f, 0xb5, 0x06, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0x43, 0xb9, 0x2d);
      else if (dpi == 150)
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0x0f, 0xb5, 0x07, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0xe0, 0xb9, 0x37);
      else
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0x0f, 0xb5, 0x07, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0x90, 0xb9, 0x37);
    }
  else
    {
      if (dpi == 1200)
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0x87, 0xb9, 0x18);
      else if (dpi == 150)
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0xc1, 0xb9, 0x1e);
      else
	write_regs (udev, 10, 0xb0, 0x00, 0xb1, 0x00, 0xb2, 0x00, 0xb3, 0xff,
		    0xb4, 0xff, 0xb5, 0x03, 0xb6, 0x01, 0xb7, 0x00, 0xb8,
		    0x21, 0xb9, 0x1e);
    }

  /* [86,89] controls number of 300dpi steps to scan */
  botreg = scanlines * (1200 / dpi) + 400;
  write_regs (udev, 6, 0xc0, 0x00, 0x84, 0x00, 0x84, 0xb4, 0x80, 0xe1, 0xcf,
	      0x04, 0x82, 0x00);

  if (!bpp16)
    {
      if (dpi == 300)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x04, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x20, 0xbd, 0x10, 0x88, 0xd0, 0xc1, 0x01, 0xc2,
		    0x00, 0xc3, 0x04, 0xc4, 0x20, 0xc5, 0x10, 0xc6, 0xc3,
		    0xc7, 0xd0, 0xc8, 0x12, 0xc0, 0xd1, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));
      else if (dpi == 600)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x04, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x20, 0xbd, 0x10, 0x88, 0xd0, 0xc1, 0x01, 0xc2,
		    0x00, 0xc3, 0x04, 0xc4, 0x20, 0xc5, 0x10, 0xc6, 0xc3,
		    0xc7, 0xd0, 0xc8, 0x16, 0xc0, 0xd1, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));
      else if (dpi == 1200)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x02, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x20, 0xbd, 0x08, 0x88, 0xa4, 0xc1, 0x02, 0xc2,
		    0x00, 0xc3, 0x02, 0xc4, 0x20, 0xc5, 0x08, 0xc6, 0x96,
		    0xc7, 0xa4, 0xc8, 0x06, 0xc0, 0xd2, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));
      else if (dpi == 150)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x06, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x1c, 0xbd, 0x08, 0x88, 0xe0, 0xc1, 0x01, 0xc2,
		    0x00, 0xc3, 0x03, 0xc4, 0x1c, 0xc5, 0x08, 0xc6, 0xd7,
		    0xc7, 0xe0, 0xc8, 0x11, 0xc0, 0xd1, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));

      if (dpi == 300)
	write_regs (udev, 8, 0xbb, 0x01, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x20, 0x91, 0x00, 0x83, 0x82);
      else if (dpi == 600)
	write_regs (udev, 8, 0xbb, 0x02, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x20, 0x91, 0x00, 0x83, 0x82);
      else if (dpi == 1200)
	write_regs (udev, 8, 0xbb, 0x02, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x20, 0x91, 0x00, 0x83, 0x82);
      else if (dpi == 150)
	write_regs (udev, 8, 0xbb, 0x00, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x20, 0x91, 0x00, 0x83, 0x82);
    }
  else
    {
      if (dpi == 300)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x04, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x20, 0xbd, 0x10, 0x88, 0xd0, 0xc1, 0x01, 0xc2,
		    0x00, 0xc3, 0x04, 0xc4, 0x20, 0xc5, 0x10, 0xc6, 0xc3,
		    0xc7, 0xd0, 0xc8, 0x13, 0xc0, 0xd1, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));
      else if (dpi == 150)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x06, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x1c, 0xbd, 0x08, 0x88, 0xe0, 0xc1, 0x01, 0xc2,
		    0x00, 0xc3, 0x03, 0xc4, 0x1c, 0xc5, 0x08, 0xc6, 0xd7,
		    0xc7, 0xe0, 0xc8, 0x12, 0xc0, 0xd1, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));
      else if (dpi == 1200)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x02, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x20, 0xbd, 0x08, 0x88, 0xa4, 0xc1, 0x02, 0xc2,
		    0x00, 0xc3, 0x02, 0xc4, 0x20, 0xc5, 0x08, 0xc6, 0x96,
		    0xc7, 0xa4, 0xc8, 0x0c, 0xc0, 0xd2, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));
      else if (dpi == 600)
	write_regs (udev, 18, 0x83, 0xa2, 0x85, 0x04, 0x83, 0x82, 0x85, 0x00,
		    0xbc, 0x20, 0xbd, 0x10, 0x88, 0xd0, 0xc1, 0x01, 0xc2,
		    0x00, 0xc3, 0x04, 0xc4, 0x20, 0xc5, 0x10, 0xc6, 0xc3,
		    0xc7, 0xd0, 0xc8, 0x1a, 0xc0, 0xd1, 0x89, botreg & 255,
		    0x86, 255 & (botreg >> 8));

      if (dpi == 300)
	write_regs (udev, 8, 0xbb, 0x02, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x70, 0x91, 0x00, 0x83, 0x82);
      else if (dpi == 150)
	write_regs (udev, 8, 0xbb, 0x01, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x70, 0x91, 0x00, 0x83, 0x82);
      else if (dpi == 1200)
	write_regs (udev, 8, 0xbb, 0x05, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x70, 0x91, 0x00, 0x83, 0x82);
      else if (dpi == 600)
	write_regs (udev, 8, 0xbb, 0x04, 0x9b, 0x24, 0x8b, 0x00, 0x8e, 0x80,
		    0xbf, 0x00, 0x90, 0x70, 0x91, 0x00, 0x83, 0x82);


    }

  if (gray)
    write_regs (udev, 1, 0xbe, 0x05);
  else
    write_regs (udev, 1, 0xbe, 0x0d);
  write_vctl (udev, 0x0c, 0x0003, 0x0001, 0x00);
  usb_bulk_read (udev, 1, &rd_byte, 1, rd_timeout);
  write_vctl (udev, 0x0c, 0x0001, 0x0000, 0x00);

#ifndef BACKENDNAME
  sprintf (fname, "%d.%s", dpi, gray ? "pgm" : "ppm");
  if (stname)
    strcpy (fname, stname);
  sprintf (head, "P%d\n%d %d\n%d\n", gray ? 5 : 6, scanpix, scanlines,
	   bpp16 ? 65535 : 255);
  if (nohead)
    head[0] = 0;
  if (!raw)
    record_image (udev, fname, dpi, scanpix, scanlines, gray, head, bpp16);
  else
    record_head (udev, fname,
		 scanpix * (gray ? 1 : 3) * (bpp16 ? 2 : 1) * scanlines, "");

  reset_scanner (udev);
  idle_ab (udev);
  set_lamp_timer (udev, 5);
#endif
}
