/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 Andreas Beck
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

   This file implements a simple SANE frontend(well it rather is a
   transport layer, but seen from libsane it is a frontend) which acts
   as a NETSANE server. The NETSANE specifications should have come
   with this package.
   Feel free to enhance this program ! It needs extension especially
   regarding crypto-support and authentication.
 */

import ctype
import limits
import stdio
import stdlib
import string
import unistd

import sys/socket
import sys/types

import netdb
import netinet/in

import Sane.sane

void
auth_callback(Sane.String_Const domain,
	       Sane.Char *username,
	       Sane.Char *password)
{
  printf("Client '%s' requested authorization.\nUser:\n", domain)
  scanf("%s", username)
  printf("Password:\n")
  scanf("%s", password)
  return
}

void
testsane(const char *dev_name)
{
  Int hlp, x
  Sane.Status bla
  Int blubb
  Sane.Handle hand
  Sane.Parameters pars
  const Sane.Option_Descriptor *sod
  const Sane.Device **device_list
  char buffer[2048]

  bla = Sane.init(&blubb, auth_callback)
  fprintf(stderr, "Init : stat=%d ver=%x\nPress Enter to continue...",
	   bla, blubb)
  getchar()
  if(bla != Sane.STATUS_GOOD)
    return

  bla = Sane.get_devices(&device_list, Sane.FALSE)
  fprintf(stderr, "GetDev : stat=%s\n", Sane.strstatus(bla))
  if(bla != Sane.STATUS_GOOD)
    return

  bla = Sane.open(dev_name, &hand)
  fprintf(stderr, "Open : stat=%s hand=%p\n", Sane.strstatus(bla), hand)
  if(bla != Sane.STATUS_GOOD)
    return

  bla = Sane.set_io_mode(hand, 0)
  fprintf(stderr, "SetIoMode : stat=%s\n", Sane.strstatus(bla))

  for(hlp = 0; hlp < 9999; hlp++)
    {
      sod = Sane.get_option_descriptor(hand, hlp)
      if(sod == NULL)
	break
      fprintf(stderr, "Gopt(%d) : stat=%p\n", hlp, sod)
      fprintf(stderr, "name : %s\n", sod.name)
      fprintf(stderr, "title: %s\n", sod.title)
      fprintf(stderr, "desc : %s\n", sod.desc)

      fprintf(stderr, "type : %d\n", sod.type)
      fprintf(stderr, "unit : %d\n", sod.unit)
      fprintf(stderr, "size : %d\n", sod.size)
      fprintf(stderr, "cap  : %d\n", sod.cap)
      fprintf(stderr, "ctyp : %d\n", sod.constraint_type)
      switch(sod.constraint_type)
	{
	case Sane.CONSTRAINT_NONE:
	  break
	case Sane.CONSTRAINT_STRING_LIST:
	  fprintf(stderr, "stringlist:\n")
	  break
	case Sane.CONSTRAINT_WORD_LIST:
	  fprintf(stderr, "wordlist(%d) : ", sod.constraint.word_list[0])
	  for(x = 1; x <= sod.constraint.word_list[0]; x++)
	    fprintf(stderr, " %d ", sod.constraint.word_list[x])
	  fprintf(stderr, "\n")
	  break
	case Sane.CONSTRAINT_RANGE:
	  fprintf(stderr, "range: %d-%d %d \n", sod.constraint.range.min,
		   sod.constraint.range.max, sod.constraint.range.quant)
	  break
	}
    }

  bla = Sane.get_parameters(hand, &pars)
  fprintf(stderr,
	   "Parm : stat=%s form=%d,lf=%d,bpl=%d,pixpl=%d,lin=%d,dep=%d\n",
	   Sane.strstatus(bla),
	   pars.format, pars.last_frame,
	   pars.bytes_per_line, pars.pixels_per_line,
	   pars.lines, pars.depth)
  if(bla != Sane.STATUS_GOOD)
    return

  bla = Sane.start(hand)
  fprintf(stderr, "Start : stat=%s\n", Sane.strstatus(bla))
  if(bla != Sane.STATUS_GOOD)
    return

  do
    {
      bla = Sane.read(hand, buffer, sizeof(buffer), &blubb)
      /*printf("Read : stat=%s len=%d\n",Sane.strstatus(bla),blubb); */
      if(bla != Sane.STATUS_GOOD)
	{
	  if(bla == Sane.STATUS_EOF)
	    break
	  return
	}
      fwrite(buffer, 1, blubb, stdout)
    }
  while(1)

  Sane.cancel(hand)
  fprintf(stderr, "Cancel.\n")

  Sane.close(hand)
  fprintf(stderr, "Close\n")

  for(hlp = 0; hlp < 20; hlp++)
    fprintf(stderr, "STRS %d=%s\n", hlp, Sane.strstatus(hlp))

  fprintf(stderr, "Exit.\n")
}

func Int main(Int argc, char *argv[])
{
  if(argc != 2 && argc != 3)
    {
      fprintf(stderr, "Usage: %s devicename[hostname]\n", argv[0])
      exit(0)
    }
  if(argc == 3)
    {
      char envbuf[1024]
      sprintf(envbuf, "Sane.NET_HOST=%s", argv[2])
      putenv(envbuf)
    }

  fprintf(stderr, "This is a SANE test application.\n"
	   "Now connecting to device %s.\n", argv[1])
  testsane(argv[1])
  Sane.exit()
  return 0
}
