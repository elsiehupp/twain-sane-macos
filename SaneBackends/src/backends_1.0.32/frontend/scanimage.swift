/* scanimage -- command line scanning utility
   Uses the SANE library.
   Copyright(C) 2015 Rolf Bensch <rolf at bensch hyphen online dot de>
   Copyright(C) 1996, 1997, 1998 Andreas Beck and David Mosberger

   Copyright(C) 1999 - 2009 by the SANE Project -- See AUTHORS and ChangeLog
   for details.

   For questions and comments contact the sane-devel mailinglist(see
   http://www.sane-project.org/mailing-lists.html).

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
*/

#ifdef _AIX
import ../include/lalloca                /* MUST come first for AIX! */
#endif

import Sane.config
import ../include/lalloca

import assert
import lgetopt
import inttypes
import signal
import stdio
import stdlib
import string
import unistd
import stdarg

import sys/types
import sys/stat

#ifdef HAVE_LIBPNG
import png
#endif

#ifdef HAVE_LIBJPEG
import jpeglib
#endif

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.saneopts

import sicc
import stiff

import ../include/md5

#ifndef PATH_MAX
#define PATH_MAX 1024
#endif

typedef struct
{
  uint8_t *data
  Int width;    /*WARNING: this is in bytes, get pixel width from param*/
  Int height
  Int x
  Int y
  Int num_channels
}
Image

#define OPTION_FORMAT   1001
#define OPTION_MD5	1002
#define OPTION_BATCH_COUNT	1003
#define OPTION_BATCH_START_AT	1004
#define OPTION_BATCH_DOUBLE	1005
#define OPTION_BATCH_INCREMENT	1006
#define OPTION_BATCH_PROMPT    1007
#define OPTION_BATCH_PRINT     1008

#define BATCH_COUNT_UNLIMITED -1

static struct option basic_options[] = {
  {"device-name", required_argument, NULL, "d"},
  {"list-devices", no_argument, NULL, "L"},
  {"formatted-device-list", required_argument, NULL, "f"},
  {"help", no_argument, NULL, "h"},
  {"verbose", no_argument, NULL, "v"},
  {"progress", no_argument, NULL, "p"},
  {"output-file", required_argument, NULL, "o"},
  {"test", no_argument, NULL, "T"},
  {"all-options", no_argument, NULL, "A"},
  {"version", no_argument, NULL, "V"},
  {"buffer-size", optional_argument, NULL, "B"},
  {"batch", optional_argument, NULL, "b"},
  {"batch-count", required_argument, NULL, OPTION_BATCH_COUNT},
  {"batch-start", required_argument, NULL, OPTION_BATCH_START_AT},
  {"batch-double", no_argument, NULL, OPTION_BATCH_DOUBLE},
  {"batch-increment", required_argument, NULL, OPTION_BATCH_INCREMENT},
  {"batch-print", no_argument, NULL, OPTION_BATCH_PRINT},
  {"batch-prompt", no_argument, NULL, OPTION_BATCH_PROMPT},
  {"format", required_argument, NULL, OPTION_FORMAT},
  {"accept-md5-only", no_argument, NULL, OPTION_MD5},
  {"icc-profile", required_argument, NULL, "i"},
  {"dont-scan", no_argument, NULL, "n"},
  {0, 0, NULL, 0}
]

#define OUTPUT_UNKNOWN  0
#define OUTPUT_PNM      1
#define OUTPUT_TIFF     2
#define OUTPUT_PNG      3
#define OUTPUT_JPEG     4

#define BASE_OPTSTRING	"d:hi:Lf:o:B::nvVTAbp"
#define STRIP_HEIGHT	256	/* # lines we increment image height */

static struct option *all_options
static Int option_number_len
static Int *option_number
static Sane.Handle device
static Int verbose
static Int progress = 0
static const char* output_file = NULL
static Int test
static Int all
static Int output_format = OUTPUT_UNKNOWN
static Int help
static Int dont_scan = 0
static const char *prog_name
static Int resolution_optind = -1, resolution_value = 0

/* window(area) related options */
static Sane.Option_Descriptor window_option[4]; /*updated descs for x,y,l,t*/
static Int window[4]; /*index into backend options for x,y,l,t*/
static Sane.Word window_val[2]; /*the value for x,y options*/
static Int window_val_user[2];	/* is x,y user-specified? */

static Int accept_only_md5_auth = 0
static const char *icc_profile = NULL

static void fetch_options(Sane.Device * device)
static void scanimage_exit(Int)

static Sane.Word tl_x = 0
static Sane.Word tl_y = 0
static Sane.Word br_x = 0
static Sane.Word br_y = 0
static Sane.Byte *buffer
static size_t buffer_size


static void
auth_callback(Sane.String_Const resource,
	       Sane.Char * username, Sane.Char * password)
{
  char tmp[3 + 128 + Sane.MAX_USERNAME_LEN + Sane.MAX_PASSWORD_LEN], *wipe
  unsigned char md5digest[16]
  Int md5mode = 0, len, query_user = 1
  FILE *pass_file
  struct stat stat_buf
  char * uname = NULL

  *tmp = 0

  if(getenv("HOME") != NULL)
    {
      if(strlen(getenv("HOME")) < 500)
	{
	  sprintf(tmp, "%s/.sane/pass", getenv("HOME"))
	}
    }

  if((strlen(tmp) > 0) && (stat(tmp, &stat_buf) == 0))
    {

      if((stat_buf.st_mode & 63) != 0)
	{
	  fprintf(stderr, "%s has wrong permissions(use at least 0600)\n",
		   tmp)
	}
      else
	{

	  if((pass_file = fopen(tmp, "r")) != NULL)
	    {

	      if(strstr(resource, "$MD5$") != NULL)
		len = (strstr(resource, "$MD5$") - resource)
	      else
		len = strlen(resource)

	      while(fgets(tmp, sizeof(tmp), pass_file))
		{

		  if((strlen(tmp) > 0) && (tmp[strlen(tmp) - 1] == "\n"))
		    tmp[strlen(tmp) - 1] = 0
		  if((strlen(tmp) > 0) && (tmp[strlen(tmp) - 1] == "\r"))
		    tmp[strlen(tmp) - 1] = 0

		  char *colon1 = strchr(tmp, ":")
		  if(colon1 != NULL)
		    {
		      char *tmp_username = tmp
		      *colon1 = "\0"

		      char *colon2 = strchr(colon1 + 1, ":")
		      if(colon2 != NULL)
			{
			  char *tmp_password = colon1 + 1
			  *colon2 = "\0"

			  if((strncmp(colon2 + 1, resource, len) == 0)
			      && ((Int) strlen(colon2 + 1) == len))
			    {
			      if((strlen(tmp_username) < Sane.MAX_USERNAME_LEN) &&
                                  (strlen(tmp_password) < Sane.MAX_PASSWORD_LEN))
                                {
                                  strncpy(username, tmp_username, Sane.MAX_USERNAME_LEN)
                                  strncpy(password, tmp_password, Sane.MAX_PASSWORD_LEN)

                                  query_user = 0
                                  break
                                }
			    }
			}
		    }
		}

	      fclose(pass_file)
	    }
	}
    }

  if(strstr(resource, "$MD5$") != NULL)
    {
      md5mode = 1
      len = (strstr(resource, "$MD5$") - resource)
      if(query_user == 1)
	fprintf(stderr, "Authentication required for resource %*.*s. "
		 "Enter username: ", len, len, resource)
    }
  else
    {

      if(accept_only_md5_auth != 0)
	{
	  fprintf(stderr, "ERROR: backend requested plain-text password\n")
	  return
	}
      else
	{
	  fprintf(stderr,
		   "WARNING: backend requested plain-text password\n")
	  query_user = 1
	}

      if(query_user == 1)
	fprintf(stderr,
		 "Authentication required for resource %s. Enter username: ",
		 resource)
    }

  if(query_user == 1)
    uname = fgets(username, Sane.MAX_USERNAME_LEN, stdin)

  if(uname != NULL && (strlen(username)) && (username[strlen(username) - 1] == "\n"))
    username[strlen(username) - 1] = 0

  if(query_user == 1)
    {
#ifdef HAVE_GETPASS
      strcpy(password, (wipe = getpass("Enter password: ")))
      memset(wipe, 0, strlen(password))
#else
      printf("OS has no getpass().  User Queries will not work\n")
#endif
    }

  if(md5mode)
    {

      sprintf(tmp, "%.128s%.*s", (strstr(resource, "$MD5$")) + 5,
	       Sane.MAX_PASSWORD_LEN - 1, password)

      md5_buffer(tmp, strlen(tmp), md5digest)

      memset(password, 0, Sane.MAX_PASSWORD_LEN)

      sprintf(password, "$MD5$%02x%02x%02x%02x%02x%02x%02x%02x"
	       "%02x%02x%02x%02x%02x%02x%02x%02x",
	       md5digest[0], md5digest[1],
	       md5digest[2], md5digest[3],
	       md5digest[4], md5digest[5],
	       md5digest[6], md5digest[7],
	       md5digest[8], md5digest[9],
	       md5digest[10], md5digest[11],
	       md5digest[12], md5digest[13], md5digest[14], md5digest[15])
    }
}

static void
sighandler(Int signum)
{
  static Bool first_time = Sane.TRUE

  if(device)
    {
      fprintf(stderr, "%s: received signal %d\n", prog_name, signum)
      if(first_time)
	{
	  first_time = Sane.FALSE
	  fprintf(stderr, "%s: trying to stop scanner\n", prog_name)
	  Sane.cancel(device)
	}
      else
	{
	  fprintf(stderr, "%s: aborting\n", prog_name)
	  _exit(0)
	}
    }
}

static void
print_unit(Sane.Unit unit)
{
  switch(unit)
    {
    case Sane.UNIT_NONE:
      break
    case Sane.UNIT_PIXEL:
      fputs("pel", stdout)
      break
    case Sane.UNIT_BIT:
      fputs("bit", stdout)
      break
    case Sane.UNIT_MM:
      fputs("mm", stdout)
      break
    case Sane.UNIT_DPI:
      fputs("dpi", stdout)
      break
    case Sane.UNIT_PERCENT:
      fputc("%", stdout)
      break
    case Sane.UNIT_MICROSECOND:
      fputs("us", stdout)
      break
    }
}

static void
print_option(Sane.Device * device, Int opt_num, const Sane.Option_Descriptor *opt)
{
  const char *str, *last_break, *start
  Bool not_first = Sane.FALSE
  var i: Int, column

  if(opt.type == Sane.TYPE_GROUP){
    printf("  %s:\n", opt.title)
    return
  }

  /* if both of these are set, option is invalid */
  if((opt.cap & Sane.CAP_SOFT_SELECT) && (opt.cap & Sane.CAP_HARD_SELECT)){
    fprintf(stderr, "%s: invalid option caps, SS+HS\n", prog_name)
    return
  }

  /* invalid to select but not detect */
  if((opt.cap & Sane.CAP_SOFT_SELECT) && !(opt.cap & Sane.CAP_SOFT_DETECT)){
    fprintf(stderr, "%s: invalid option caps, SS!SD\n", prog_name)
    return
  }
  /* standard allows this, though it makes little sense
  if(opt.cap & Sane.CAP_HARD_SELECT && !(opt.cap & Sane.CAP_SOFT_DETECT)){
    fprintf(stderr, "%s: invalid option caps, HS!SD\n", prog_name)
    return
  }*/

  /* if one of these three is not set, option is useless, skip it */
  if(!(opt.cap &
   (Sane.CAP_SOFT_SELECT | Sane.CAP_HARD_SELECT | Sane.CAP_SOFT_DETECT)
  )){
    return
  }

  /* print the option */
  if( !strcmp(opt.name, "x")
    || !strcmp(opt.name, "y")
    || !strcmp(opt.name, "t")
    || !strcmp(opt.name, "l"))
      printf("    -%s", opt.name)
  else
    printf("    --%s", opt.name)

  /* print the option choices */
  if(opt.type == Sane.TYPE_BOOL)
    {
      fputs("[=(", stdout)
      if(opt.cap & Sane.CAP_AUTOMATIC)
	fputs("auto|", stdout)
      fputs("yes|no)]", stdout)
    }
  else if(opt.type != Sane.TYPE_BUTTON)
    {
      fputc(" ", stdout)
      if(opt.cap & Sane.CAP_AUTOMATIC)
	{
	  fputs("auto|", stdout)
	  not_first = Sane.TRUE
	}
      switch(opt.constraint_type)
	{
	case Sane.CONSTRAINT_NONE:
	  switch(opt.type)
	    {
	    case Sane.TYPE_INT:
	      fputs("<Int>", stdout)
	      break
	    case Sane.TYPE_FIXED:
	      fputs("<float>", stdout)
	      break
	    case Sane.TYPE_STRING:
	      fputs("<string>", stdout)
	      break
	    default:
	      break
	    }
	  if(opt.type != Sane.TYPE_STRING
           && opt.size > (Int) sizeof(Sane.Word))
	    fputs(",...", stdout)
	  break

	case Sane.CONSTRAINT_RANGE:
	  // Check for no range - some buggy backends can miss this out.
          if(!opt.constraint.range)
            {
              fputs("{no_range}", stdout)
            }
          else
            {
              if(opt.type == Sane.TYPE_INT)
                {
                  if(!strcmp(opt.name, "x"))
                    {
                      printf("%d..%d", opt.constraint.range.min,
                              opt.constraint.range.max - tl_x)
                    }
                  else if(!strcmp(opt.name, "y"))
                    {
                      printf("%d..%d", opt.constraint.range.min,
                              opt.constraint.range.max - tl_y)
                    }
                  else
                    {
                      printf("%d..%d", opt.constraint.range.min,
                              opt.constraint.range.max)
                    }
                  print_unit(opt.unit)
                  if(opt.size > (Int) sizeof(Sane.Word))
                    fputs(",...", stdout)
                  if(opt.constraint.range.quant)
                    printf(" (in steps of %d)", opt.constraint.range.quant)
                }
              else
                {
                  if(!strcmp(opt.name, "x"))
                    {
                      printf("%g..%g", Sane.UNFIX(opt.constraint.range.min),
                              Sane.UNFIX(opt.constraint.range.max - tl_x))
                    }
                  else if(!strcmp(opt.name, "y"))
                    {
                      printf("%g..%g", Sane.UNFIX(opt.constraint.range.min),
                              Sane.UNFIX(opt.constraint.range.max - tl_y))
                    }
                  else
                    {
                      printf("%g..%g", Sane.UNFIX(opt.constraint.range.min),
                              Sane.UNFIX(opt.constraint.range.max))
                    }
                  print_unit(opt.unit)
                  if(opt.size > (Int) sizeof(Sane.Word))
                    fputs(",...", stdout)
                  if(opt.constraint.range.quant)
                    printf(" (in steps of %g)",
                            Sane.UNFIX(opt.constraint.range.quant))
                }
            }
          break

	case Sane.CONSTRAINT_WORD_LIST:
	  // Check no words in list or no list -  - some buggy backends can miss this out.
	  // Note the check on < 1 as Int is signed.
          if(!opt.constraint.word_list || (opt.constraint.word_list[0] < 1))
            {
              fputs("{no_wordlist}", stdout)
            }
          else
            {
              for(i = 0; i < opt.constraint.word_list[0]; ++i)
                {
                  if(not_first)
                    fputc("|", stdout)

                  not_first = Sane.TRUE

                  if(opt.type == Sane.TYPE_INT)
                    printf("%d", opt.constraint.word_list[i + 1])
                  else
                    printf("%g", Sane.UNFIX(opt.constraint.word_list[i + 1]))
                }
            }

	  print_unit(opt.unit)
	  if(opt.size > (Int) sizeof(Sane.Word))
	    fputs(",...", stdout)
	  break

	case Sane.CONSTRAINT_STRING_LIST:
          // Check for missing strings - some buggy backends can miss this out.
          if(!opt.constraint.string_list || !opt.constraint.string_list[0])
            {
              fputs("{no_stringlist}", stdout)
            }
          else
            {
              for(i = 0; opt.constraint.string_list[i]; ++i)
                {
                  if(i > 0)
                    fputc("|", stdout)

                  fputs(opt.constraint.string_list[i], stdout)
                }
            }
          break
	}
    }

  /* print current option value */
  if(opt.type == Sane.TYPE_STRING || opt.size == sizeof(Sane.Word))
    {
      if(Sane.OPTION_IS_ACTIVE(opt.cap))
	{
	  void *val = alloca(opt.size)
	  Sane.control_option(device, opt_num, Sane.ACTION_GET_VALUE, val,
			       0)
	  fputs(" [", stdout)
	  switch(opt.type)
	    {
	    case Sane.TYPE_BOOL:
	      fputs(*(Bool *) val ? "yes" : "no", stdout)
	      break

	    case Sane.TYPE_INT:
	      if(strcmp(opt.name, "l") == 0)
		{
		  tl_x = (*(Sane.Fixed *) val)
		  printf("%d", tl_x)
		}
	      else if(strcmp(opt.name, "t") == 0)
		{
		  tl_y = (*(Sane.Fixed *) val)
		  printf("%d", tl_y)
		}
	      else if(strcmp(opt.name, "x") == 0)
		{
		  br_x = (*(Sane.Fixed *) val)
		  printf("%d", br_x - tl_x)
		}
	      else if(strcmp(opt.name, "y") == 0)
		{
		  br_y = (*(Sane.Fixed *) val)
		  printf("%d", br_y - tl_y)
		}
	      else
		printf("%d", *(Int *) val)
	      break

	    case Sane.TYPE_FIXED:

	      if(strcmp(opt.name, "l") == 0)
		{
		  tl_x = (*(Sane.Fixed *) val)
		  printf("%g", Sane.UNFIX(tl_x))
		}
	      else if(strcmp(opt.name, "t") == 0)
		{
		  tl_y = (*(Sane.Fixed *) val)
		  printf("%g", Sane.UNFIX(tl_y))
		}
	      else if(strcmp(opt.name, "x") == 0)
		{
		  br_x = (*(Sane.Fixed *) val)
		  printf("%g", Sane.UNFIX(br_x - tl_x))
		}
	      else if(strcmp(opt.name, "y") == 0)
		{
		  br_y = (*(Sane.Fixed *) val)
		  printf("%g", Sane.UNFIX(br_y - tl_y))
		}
	      else
		printf("%g", Sane.UNFIX(*(Sane.Fixed *) val))

	      break

	    case Sane.TYPE_STRING:
	      fputs((char *) val, stdout)
	      break

	    default:
	      break
	    }
	  fputc("]", stdout)
	}
    }

  if(!Sane.OPTION_IS_ACTIVE(opt.cap))
    fputs(" [inactive]", stdout)

  else if(opt.cap & Sane.CAP_HARD_SELECT)
    fputs(" [hardware]", stdout)

  else if(!(opt.cap & Sane.CAP_SOFT_SELECT) && (opt.cap & Sane.CAP_SOFT_DETECT))
    fputs(" [read-only]", stdout)

  fputs("\n        ", stdout)

  column = 8
  last_break = 0
  start = opt.desc
  for(str = opt.desc; *str; ++str)
    {
      ++column
      if(*str == " ")
        last_break = str
      else if(*str == "\n"){
        column=80
        last_break = str
      }
      if(column >= 79 && last_break)
        {
          while(start < last_break)
            fputc(*start++, stdout)
          start = last_break + 1;	/* skip blank */
          fputs("\n        ", stdout)
          column = 8 + (str - start)
        }
    }
  while(*start)
    fputc(*start++, stdout)
  fputc("\n", stdout)
}

/* A scalar has the following syntax:

     V[ U ]

   V is the value of the scalar.  It is either an integer or a
   floating point number, depending on the option type.

   U is an optional unit.  If not specified, the default unit is used.
   The following table lists which units are supported depending on
   what the option"s default unit is:

     Option"s unit:	Allowed units:

     Sane.UNIT_NONE:
     Sane.UNIT_PIXEL:	pel
     Sane.UNIT_BIT:	b(bit), B(byte)
     Sane.UNIT_MM:	mm(millimeter), cm(centimeter), in or " (inches),
     Sane.UNIT_DPI:	dpi
     Sane.UNIT_PERCENT:	%
     Sane.UNIT_PERCENT:	us
 */
static const char *
parse_scalar(const Sane.Option_Descriptor * opt, const char *str,
	      Sane.Word * value)
{
  char *end
  double v

  if(opt.type == Sane.TYPE_FIXED)
    v = strtod(str, &end) * (1 << Sane.FIXED_SCALE_SHIFT)
  else
    v = strtol(str, &end, 10)

  if(str == end)
    {
      fprintf(stderr,
	       "%s: option --%s: bad option value(rest of option: %s)\n",
	       prog_name, opt.name, str)
      scanimage_exit(1)
    }
  str = end

  switch(opt.unit)
    {
    case Sane.UNIT_NONE:
    case Sane.UNIT_PIXEL:
      break

    case Sane.UNIT_BIT:
      if(*str == "b" || *str == "B")
	{
	  if(*str++ == "B")
	    v *= 8
	}
      break

    case Sane.UNIT_MM:
      if(str[0] == "\0")
	v *= 1.0;		/* default to mm */
      else if(strcmp(str, "mm") == 0)
	str += sizeof("mm") - 1
      else if(strcmp(str, "cm") == 0)
	{
	  str += sizeof("cm") - 1
	  v *= 10.0
	}
      else if(strcmp(str, "in") == 0 || *str == """)
	{
	  if(*str++ != """)
	    ++str
	  v *= 25.4;		/* 25.4 mm/inch */
	}
      else
	{
	  fprintf(stderr,
		   "%s: option --%s: illegal unit(rest of option: %s)\n",
		   prog_name, opt.name, str)
	  return 0
	}
      break

    case Sane.UNIT_DPI:
      if(strcmp(str, "dpi") == 0)
	str += sizeof("dpi") - 1
      break

    case Sane.UNIT_PERCENT:
      if(*str == "%")
	++str
      break

    case Sane.UNIT_MICROSECOND:
      if(strcmp(str, "us") == 0)
	str += sizeof("us") - 1
      break
    }

  if(v < 0){
    *value = v - 0.5
  }
  else{
    *value = v + 0.5
  }

  return str
}

/* A vector has the following syntax:

     [ "[" I "]" ] S { [","|"-"] [ "[" I "]" S }

   The number in brackets(I), if present, determines the index of the
   vector element to be set next.  If I is not present, the value of
   last index used plus 1 is used.  The first index value used is 0
   unless I is present.

   S is a scalar value as defined by parse_scalar().

   If two consecutive value specs are separated by a comma(,) their
   values are set independently.  If they are separated by a dash(-),
   they define the endpoints of a line and all vector values between
   the two endpoints are set according to the value of the
   interpolated line.  For example, [0]15-[255]15 defines a vector of
   256 elements whose value is 15.  Similarly, [0]0-[255]255 defines a
   vector of 256 elements whose value starts at 0 and increases to
   255.  */
static void
parse_vector(const Sane.Option_Descriptor * opt, const char *str,
	      Sane.Word * vector, size_t vector_length)
{
  Sane.Word value, prev_value = 0
  Int index = -1, prev_index = 0
  char *end, separator = "\0"

  /* initialize vector to all zeroes: */
  memset(vector, 0, vector_length * sizeof(Sane.Word))

  do
    {
      if(*str == "[")
	{
	  /* read index */
	  index = strtol(++str, &end, 10)
	  if(str == end || *end != "]")
	    {
	      fprintf(stderr, "%s: option --%s: closing bracket missing "
		       "(rest of option: %s)\n", prog_name, opt.name, str)
	      scanimage_exit(1)
	    }
	  str = end + 1
	}
      else
	++index

      if(index < 0 || index >= (Int) vector_length)
	{
	  fprintf(stderr,
		   "%s: option --%s: index %d out of range[0..%ld]\n",
		   prog_name, opt.name, index, (long) vector_length - 1)
	  scanimage_exit(1)
	}

      /* read value */
      str = parse_scalar(opt, str, &value)
      if(!str)
        scanimage_exit(1)

      if(*str && *str != "-" && *str != ",")
	{
	  fprintf(stderr,
		   "%s: option --%s: illegal separator(rest of option: %s)\n",
		   prog_name, opt.name, str)
	  scanimage_exit(1)
	}

      /* store value: */
      vector[index] = value
      if(separator == "-")
	{
	  /* interpolate */
	  double v, slope
	  var i: Int

	  v = (double) prev_value
	  slope = ((double) value - v) / (index - prev_index)

	  for(i = prev_index + 1; i < index; ++i)
	    {
	      v += slope
	      vector[i] = (Sane.Word) v
	    }
	}

      prev_index = index
      prev_value = value
      separator = *str++
    }
  while(separator == "," || separator == "-")

  if(verbose > 2)
    {
      var i: Int

      fprintf(stderr, "%s: value for --%s is: ", prog_name, opt.name)
      for(i = 0; i < (Int) vector_length; ++i)
	if(opt.type == Sane.TYPE_FIXED)
	  fprintf(stderr, "%g ", Sane.UNFIX(vector[i]))
	else
	  fprintf(stderr, "%d ", vector[i])
      fputc("\n", stderr)
    }
}

static void
fetch_options(Sane.Device * device)
{
  const Sane.Option_Descriptor *opt
  Int num_dev_options
  var i: Int, option_count
  Sane.Status status

  opt = Sane.get_option_descriptor(device, 0)
  if(opt == NULL)
    {
      fprintf(stderr, "Could not get option descriptor for option 0\n")
      scanimage_exit(1)
    }

  status = Sane.control_option(device, 0, Sane.ACTION_GET_VALUE,
                                &num_dev_options, 0)
  if(status != Sane.STATUS_GOOD)
    {
      fprintf(stderr, "Could not get value for option 0: %s\n",
               Sane.strstatus(status))
      scanimage_exit(1)
    }

  /* build the full table of long options */
  option_count = 0
  for(i = 1; i < num_dev_options; ++i)
    {
      opt = Sane.get_option_descriptor(device, i)
      if(opt == NULL)
	{
	  fprintf(stderr, "Could not get option descriptor for option %d\n",i)
	  scanimage_exit(1)
	}

      /* create command line option only for settable options */
      if(!Sane.OPTION_IS_SETTABLE(opt.cap) || opt.type == Sane.TYPE_GROUP)
	continue

      option_number[option_count] = i

      all_options[option_count].name = (const char *) opt.name
      all_options[option_count].flag = 0
      all_options[option_count].val = 0

      if(opt.type == Sane.TYPE_BOOL)
	all_options[option_count].has_arg = optional_argument
      else if(opt.type == Sane.TYPE_BUTTON)
	all_options[option_count].has_arg = no_argument
      else
	all_options[option_count].has_arg = required_argument

      /* Look for scan resolution */
      if((opt.type == Sane.TYPE_FIXED || opt.type == Sane.TYPE_INT)
	  && opt.size == sizeof(Int)
	  && (opt.unit == Sane.UNIT_DPI)
	  && (strcmp(opt.name, Sane.NAME_SCAN_RESOLUTION) == 0))
	resolution_optind = i

      /* Keep track of top-left corner options(if they exist at
         all) and replace the bottom-right corner options by a
         width/height option(if they exist at all).  */
      if((opt.type == Sane.TYPE_FIXED || opt.type == Sane.TYPE_INT)
	  && opt.size == sizeof(Int)
	  && (opt.unit == Sane.UNIT_MM || opt.unit == Sane.UNIT_PIXEL))
	{
	  if(strcmp(opt.name, Sane.NAME_SCAN_BR_X) == 0)
	    {
	      window[0] = i
	      all_options[option_count].name = "width"
	      all_options[option_count].val = "x"
	      window_option[0] = *opt
	      window_option[0].title = "Scan width"
	      window_option[0].desc = "Width of scan-area."
	      window_option[0].name = "x"
	    }
	  else if(strcmp(opt.name, Sane.NAME_SCAN_BR_Y) == 0)
	    {
	      window[1] = i
	      all_options[option_count].name = "height"
	      all_options[option_count].val = "y"
	      window_option[1] = *opt
	      window_option[1].title = "Scan height"
	      window_option[1].desc = "Height of scan-area."
	      window_option[1].name = "y"
	    }
	  else if(strcmp(opt.name, Sane.NAME_SCAN_TL_X) == 0)
	    {
	      window[2] = i
	      all_options[option_count].val = "l"
	      window_option[2] = *opt
	      window_option[2].name = "l"
	    }
	  else if(strcmp(opt.name, Sane.NAME_SCAN_TL_Y) == 0)
	    {
	      window[3] = i
	      all_options[option_count].val = "t"
	      window_option[3] = *opt
	      window_option[3].name = "t"
	    }
	}
      ++option_count
    }
  memcpy(all_options + option_count, basic_options, sizeof(basic_options))
  option_count += NELEMS(basic_options)
  memset(all_options + option_count, 0, sizeof(all_options[0]))

  /* Initialize width & height options based on backend default
     values for top-left x/y and bottom-right x/y: */
  for(i = 0; i < 2; ++i)
    {
      if(window[i] && !window_val_user[i])
	{
	  Sane.control_option(device, window[i],
                                Sane.ACTION_GET_VALUE, &window_val[i], 0)
          if(window[i + 2]){
	    Sane.Word pos
	    Sane.control_option(device, window[i + 2],
			       Sane.ACTION_GET_VALUE, &pos, 0)
	    window_val[i] -= pos
          }
	}
    }
}

static void
set_option(Sane.Handle device, Int optnum, void *valuep)
{
  const Sane.Option_Descriptor *opt
  Sane.Status status
  Sane.Word orig = 0
  Int info = 0

  opt = Sane.get_option_descriptor(device, optnum)
  if(!opt)
    {
      if(verbose > 0)
        fprintf(stderr, "%s: ignored request to set invalid option %d\n",
                 prog_name, optnum)
      return
    }

  if(!Sane.OPTION_IS_ACTIVE(opt.cap))
    {
      if(verbose > 0)
	fprintf(stderr, "%s: ignored request to set inactive option %s\n",
		 prog_name, opt.name)
      return
    }

  if(opt.size == sizeof(Sane.Word) && opt.type != Sane.TYPE_STRING)
    orig = *(Sane.Word *) valuep

  status = Sane.control_option(device, optnum, Sane.ACTION_SET_VALUE,
				valuep, &info)
  if(status != Sane.STATUS_GOOD)
    {
      fprintf(stderr, "%s: setting of option --%s failed(%s)\n",
	       prog_name, opt.name, Sane.strstatus(status))
      scanimage_exit(1)
    }

  if((info & Sane.INFO_INEXACT) && opt.size == sizeof(Sane.Word))
    {
      if(opt.type == Sane.TYPE_INT)
	fprintf(stderr, "%s: rounded value of %s from %d to %d\n",
		 prog_name, opt.name, orig, *(Sane.Word *) valuep)
      else if(opt.type == Sane.TYPE_FIXED)
	fprintf(stderr, "%s: rounded value of %s from %g to %g\n",
		 prog_name, opt.name,
		 Sane.UNFIX(orig), Sane.UNFIX(*(Sane.Word *) valuep))
    }

  if(info & Sane.INFO_RELOAD_OPTIONS)
    fetch_options(device)
}

static void
process_backend_option(Sane.Handle device, Int optnum, const char *optarg)
{
  static Sane.Word *vector = 0
  static size_t vector_size = 0
  const Sane.Option_Descriptor *opt
  size_t vector_length
  Sane.Status status
  Sane.Word value
  void *valuep

  opt = Sane.get_option_descriptor(device, optnum)

  if(!Sane.OPTION_IS_ACTIVE(opt.cap))
    {
      fprintf(stderr, "%s: attempted to set inactive option %s\n",
	       prog_name, opt.name)
      scanimage_exit(1)
    }

  if((opt.cap & Sane.CAP_AUTOMATIC) && optarg &&
      strncasecmp(optarg, "auto", 4) == 0)
    {
      status = Sane.control_option(device, optnum, Sane.ACTION_SET_AUTO,
				    0, 0)
      if(status != Sane.STATUS_GOOD)
	{
	  fprintf(stderr,
		   "%s: failed to set option --%s to automatic(%s)\n",
		   prog_name, opt.name, Sane.strstatus(status))
	  scanimage_exit(1)
	}
      return
    }

  valuep = &value
  switch(opt.type)
    {
    case Sane.TYPE_BOOL:
      value = 1;		/* no argument means option is set */
      if(optarg)
	{
	  if(strncasecmp(optarg, "yes", strlen(optarg)) == 0)
	    value = 1
	  else if(strncasecmp(optarg, "no", strlen(optarg)) == 0)
	    value = 0
	  else
	    {
	      fprintf(stderr, "%s: option --%s: bad option value `%s"\n",
		       prog_name, opt.name, optarg)
	      scanimage_exit(1)
	    }
	}
      break

    case Sane.TYPE_INT:
    case Sane.TYPE_FIXED:
      /* ensure vector is long enough: */
      vector_length = opt.size / sizeof(Sane.Word)
      if(vector_size < vector_length)
	{
	  vector_size = vector_length
	  vector = realloc(vector, vector_length * sizeof(Sane.Word))
	  if(!vector)
	    {
	      fprintf(stderr, "%s: out of memory\n", prog_name)
	      scanimage_exit(1)
	    }
	}
      parse_vector(opt, optarg, vector, vector_length)
      valuep = vector
      break

    case Sane.TYPE_STRING:
      valuep = malloc(opt.size)
      if(!valuep)
	{
	  fprintf(stderr, "%s: out of memory\n", prog_name)
	  scanimage_exit(1)
	}
      strncpy(valuep, optarg, opt.size)
      ((char *) valuep)[opt.size - 1] = 0
      break

    case Sane.TYPE_BUTTON:
      value = 0;		/* value doesn"t matter */
      break

    default:
      fprintf(stderr, "%s: duh, got unknown option type %d\n",
	       prog_name, opt.type)
      return
    }
  set_option(device, optnum, valuep)
  if(opt.type == Sane.TYPE_STRING && valuep)
    free(valuep)
}

static void
write_pnm_header(Sane.Frame format, Int width, Int height, Int depth, FILE *ofp)
{
  /* The netpbm-package does not define raw image data with maxval > 255. */
  /* But writing maxval 65535 for 16bit data gives at least a chance */
  /* to read the image. */
  switch(format)
    {
    case Sane.FRAME_RED:
    case Sane.FRAME_GREEN:
    case Sane.FRAME_BLUE:
    case Sane.FRAME_RGB:
      fprintf(ofp, "P6\n# SANE data follows\n%d %d\n%d\n", width, height,
	      (depth <= 8) ? 255 : 65535)
      break

    default:
      if(depth == 1)
       fprintf(ofp, "P4\n# SANE data follows\n%d %d\n", width, height)
      else
       fprintf(ofp, "P5\n# SANE data follows\n%d %d\n%d\n", width, height,
		(depth <= 8) ? 255 : 65535)
      break
    }
#ifdef __EMX__			/* OS2 - write in binary mode. */
  _fsetmode(ofp, "b")
#endif
}

#ifdef HAVE_LIBPNG
static void
write_png_header(Sane.Frame format, Int width, Int height, Int depth, Int dpi, const char * icc_profile, FILE *ofp, png_structp* png_ptr, png_infop* info_ptr)
{
  Int color_type
  /* PNG does not have imperial reference units, so we must convert to metric. */
  /* There are nominally 39.3700787401575 inches in a meter. */
  const double pixels_per_meter = dpi * 39.3700787401575
  size_t icc_size = 0
  void *icc_buffer

  *png_ptr = png_create_write_struct
       (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)
  if(!*png_ptr) {
    fprintf(stderr, "png_create_write_struct failed\n")
    exit(1)
  }
  *info_ptr = png_create_info_struct(*png_ptr)
  if(!*info_ptr) {
    fprintf(stderr, "png_create_info_struct failed\n")
    exit(1)
  }
  png_init_io(*png_ptr, ofp)

  switch(format)
    {
    case Sane.FRAME_RED:
    case Sane.FRAME_GREEN:
    case Sane.FRAME_BLUE:
    case Sane.FRAME_RGB:
      color_type = PNG_COLOR_TYPE_RGB
      break

    default:
      color_type = PNG_COLOR_TYPE_GRAY
      break
    }

  png_set_IHDR(*png_ptr, *info_ptr, width, height,
    depth, color_type, PNG_INTERLACE_NONE,
    PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE)

  png_set_pHYs(*png_ptr, *info_ptr,
    pixels_per_meter, pixels_per_meter,
    PNG_RESOLUTION_METER)

  if(icc_profile)
    {
      icc_buffer = sanei_load_icc_profile(icc_profile, &icc_size)
      if(icc_size > 0)
        {
	  /* libpng will abort if the profile and image colour spaces do not match*/
	  /* The data colour space field is at bytes 16 to 20 in an ICC profile */
	  /* see: ICC.1:2010 § 7.2.6 */
	  Int is_gray_profile = strncmp((char *) icc_buffer + 16, "GRAY", 4) == 0
	  Int is_rgb_profile = strncmp((char *) icc_buffer + 16, "RGB ", 4) == 0
	  if((is_gray_profile && color_type == PNG_COLOR_TYPE_GRAY) ||
	      (is_rgb_profile && color_type == PNG_COLOR_TYPE_RGB))
	    {
	      png_set_iCCP(*png_ptr, *info_ptr, basename(icc_profile), PNG_COMPRESSION_TYPE_BASE, icc_buffer, icc_size)
	    }
	  else
	    {
	      if(is_gray_profile)
	        {
		  fprintf(stderr, "Ignoring "GRAY" space ICC profile because the image is RGB.\n")
	        }
	      if(is_rgb_profile)
	        {
		  fprintf(stderr, "Ignoring "RGB " space ICC profile because the image is Grayscale.\n")
		}
	    }
	  free(icc_buffer)
	}
    }

  png_write_info(*png_ptr, *info_ptr)
}
#endif

#ifdef HAVE_LIBJPEG
static void
write_jpeg_header(Sane.Frame format, Int width, Int height, Int dpi, FILE *ofp,
                   struct jpeg_compress_struct *cinfo,
                   struct jpeg_error_mgr *jerr)
{
  cinfo.err = jpeg_std_error(jerr)
  jpeg_create_compress(cinfo)
  jpeg_stdio_dest(cinfo, ofp)

  cinfo.image_width = width
  cinfo.image_height = height
  switch(format)
    {
    case Sane.FRAME_RED:
    case Sane.FRAME_GREEN:
    case Sane.FRAME_BLUE:
    case Sane.FRAME_RGB:
      cinfo.in_color_space = JCS_RGB
      cinfo.input_components = 3
      break

    default:
      cinfo.in_color_space = JCS_GRAYSCALE
      cinfo.input_components = 1
      break
    }

  jpeg_set_defaults(cinfo)
  /* jpeg_set_defaults overrides density, be careful. */
  cinfo.density_unit = 1;   /* Inches */
  cinfo.X_density = cinfo.Y_density = dpi
  cinfo.write_JFIF_header = TRUE

  jpeg_set_quality(cinfo, 75, TRUE)
  jpeg_start_compress(cinfo, TRUE)
}
#endif

static void *
advance(Image * image)
{
  if(++image.x >= image.width)
    {
      image.x = 0
      if(++image.y >= image.height || !image.data)
	{
	  size_t old_size = 0, new_size

	  if(image.data)
	    old_size = image.height * image.width * image.num_channels

	  image.height += STRIP_HEIGHT
	  new_size = image.height * image.width * image.num_channels

	  if(image.data)
	    image.data = realloc(image.data, new_size)
	  else
	    image.data = malloc(new_size)
	  if(image.data)
	    memset(image.data + old_size, 0, new_size - old_size)
	}
    }
  if(!image.data)
    fprintf(stderr, "%s: can"t allocate image buffer(%dx%d)\n",
	     prog_name, image.width, image.height)
  return image.data
}

static Sane.Status
scan_it(FILE *ofp)
{
  var i: Int, len, first_frame = 1, offset = 0, must_buffer = 0
  uint64_t hundred_percent = 0
  Sane.Byte min = 0xff, max = 0
  Sane.Parameters parm
  Sane.Status status
  Image image = { 0, 0, 0, 0, 0, 0 ]
  static const char *format_name[] = {
    "gray", "RGB", "red", "green", "blue"
  ]
  uint64_t total_bytes = 0, expected_bytes
  Int hang_over = -1
#ifdef HAVE_LIBPNG
  Int pngrow = 0
  png_bytep pngbuf = NULL
  png_structp png_ptr
  png_infop info_ptr
#endif
#ifdef HAVE_LIBJPEG
  Int jpegrow = 0
  JSAMPLE *jpegbuf = NULL
  struct jpeg_compress_struct cinfo
  struct jpeg_error_mgr jerr
#endif

  do
    {
      if(!first_frame)
	{
#ifdef Sane.STATUS_WARMING_UP
          do
	    {
	      status = Sane.start(device)
	    }
	  while(status == Sane.STATUS_WARMING_UP)
#else
	  status = Sane.start(device)
#endif
	  if(status != Sane.STATUS_GOOD)
	    {
	      fprintf(stderr, "%s: Sane.start: %s\n",
		       prog_name, Sane.strstatus(status))
	      goto cleanup
	    }
	}

      status = Sane.get_parameters(device, &parm)
      if(status != Sane.STATUS_GOOD)
	{
	  fprintf(stderr, "%s: Sane.get_parameters: %s\n",
		   prog_name, Sane.strstatus(status))
	  goto cleanup
	}

      if(verbose)
	{
	  if(first_frame)
	    {
	      if(parm.lines >= 0)
		fprintf(stderr, "%s: scanning image of size %dx%d pixels at "
			 "%d bits/pixel\n",
			 prog_name, parm.pixels_per_line, parm.lines,
			 parm.depth * (Sane.FRAME_RGB == parm.format ? 3 : 1))
	      else
		fprintf(stderr, "%s: scanning image %d pixels wide and "
			 "variable height at %d bits/pixel\n",
			 prog_name, parm.pixels_per_line,
			 parm.depth * (Sane.FRAME_RGB == parm.format ? 3 : 1))
	    }

	  fprintf(stderr, "%s: acquiring %s frame\n", prog_name,
	   parm.format <= Sane.FRAME_BLUE ? format_name[parm.format]:"Unknown")
	}

      if(first_frame)
	{
          image.num_channels = 1
	  switch(parm.format)
	    {
	    case Sane.FRAME_RED:
	    case Sane.FRAME_GREEN:
	    case Sane.FRAME_BLUE:
	      assert(parm.depth == 8)
	      must_buffer = 1
	      offset = parm.format - Sane.FRAME_RED
	      image.num_channels = 3
	      break

	    case Sane.FRAME_RGB:
	      assert((parm.depth == 8) || (parm.depth == 16))
	    case Sane.FRAME_GRAY:
	      assert((parm.depth == 1) || (parm.depth == 8)
		      || (parm.depth == 16))
	      if(parm.lines < 0)
		{
		  must_buffer = 1
		  offset = 0
		}
	      else
		  switch(output_format)
		  {
		  case OUTPUT_TIFF:
		    sanei_write_tiff_header(parm.format,
					     parm.pixels_per_line, parm.lines,
					     parm.depth, resolution_value,
					     icc_profile, ofp)
		    break
		  case OUTPUT_PNM:
		    write_pnm_header(parm.format, parm.pixels_per_line,
				      parm.lines, parm.depth, ofp)
		    break
#ifdef HAVE_LIBPNG
		  case OUTPUT_PNG:
		    write_png_header(parm.format, parm.pixels_per_line,
				      parm.lines, parm.depth, resolution_value,
				      icc_profile, ofp, &png_ptr, &info_ptr)
		    break
#endif
#ifdef HAVE_LIBJPEG
		  case OUTPUT_JPEG:
		    write_jpeg_header(parm.format, parm.pixels_per_line,
				       parm.lines, resolution_value,
				       ofp, &cinfo, &jerr)
		    break
#endif
		  }
	      break

            default:
	      break
	    }
#ifdef HAVE_LIBPNG
	  if(output_format == OUTPUT_PNG)
	    pngbuf = malloc(parm.bytesPerLine)
#endif
#ifdef HAVE_LIBJPEG
	  if(output_format == OUTPUT_JPEG)
	    jpegbuf = malloc(parm.bytesPerLine)
#endif

	  if(must_buffer)
	    {
	      /* We"re either scanning a multi-frame image or the
		 scanner doesn"t know what the eventual image height
		 will be(common for hand-held scanners).  In either
		 case, we need to buffer all data before we can write
		 the image.  */
	      image.width = parm.bytesPerLine

	      if(parm.lines >= 0)
		/* See advance(); we allocate one extra line so we
		   don"t end up realloc"ing in when the image has been
		   filled in.  */
		image.height = parm.lines - STRIP_HEIGHT + 1
	      else
		image.height = 0

	      image.x = image.width - 1
	      image.y = -1
	      if(!advance(&image))
		{
		  status = Sane.STATUS_NO_MEM
		  goto cleanup
		}
	    }
	}
      else
	{
	  assert(parm.format >= Sane.FRAME_RED
		  && parm.format <= Sane.FRAME_BLUE)
	  offset = parm.format - Sane.FRAME_RED
	  image.x = image.y = 0
	}
      hundred_percent = ((uint64_t)parm.bytesPerLine) * parm.lines
	* ((parm.format == Sane.FRAME_RGB || parm.format == Sane.FRAME_GRAY) ? 1:3)

      while(1)
	{
	  double progr
	  status = Sane.read(device, buffer, buffer_size, &len)
	  total_bytes += (Sane.Word) len
          progr = ((total_bytes * 100.) / (double) hundred_percent)
          if(progr > 100.)
	    progr = 100.
          if(progress)
            {
              if(parm.lines >= 0)
                fprintf(stderr, "Progress: %3.1f%%\r", progr)
              else
                fprintf(stderr, "Progress: (unknown)\r")
            }

	  if(status != Sane.STATUS_GOOD)
	    {
	      if(verbose && parm.depth == 8)
		fprintf(stderr, "%s: min/max graylevel value = %d/%d\n",
			 prog_name, min, max)
	      if(status != Sane.STATUS_EOF)
		{
		  fprintf(stderr, "%s: Sane.read: %s\n",
			   prog_name, Sane.strstatus(status))
		  return status
		}
	      break
	    }

	  if(must_buffer)
	    {
	      switch(parm.format)
		{
		case Sane.FRAME_RED:
		case Sane.FRAME_GREEN:
		case Sane.FRAME_BLUE:
		  image.num_channels = 3
		  for(i = 0; i < len; ++i)
		    {
		      image.data[offset + 3 * i] = buffer[i]
		      if(!advance(&image))
			{
			  status = Sane.STATUS_NO_MEM
			  goto cleanup
			}
		    }
		  offset += 3 * len
		  break

		case Sane.FRAME_RGB:
		  image.num_channels = 1
		  for(i = 0; i < len; ++i)
		    {
		      image.data[offset + i] = buffer[i]
		      if(!advance(&image))
			  {
			    status = Sane.STATUS_NO_MEM
			    goto cleanup
			  }
		    }
		  offset += len
		  break

		case Sane.FRAME_GRAY:
		  image.num_channels = 1
		  for(i = 0; i < len; ++i)
		    {
		      image.data[offset + i] = buffer[i]
		      if(!advance(&image))
			  {
			    status = Sane.STATUS_NO_MEM
			    goto cleanup
			  }
		    }
		  offset += len
		  break

                default:
		  break
		}
	    }
	  else			/* ! must_buffer */
	    {
#ifdef HAVE_LIBPNG
	      if(output_format == OUTPUT_PNG)
	        {
		  var i: Int = 0
		  Int left = len
		  while(pngrow + left >= parm.bytesPerLine)
		    {
		      memcpy(pngbuf + pngrow, buffer + i, parm.bytesPerLine - pngrow)
		      if(parm.depth == 1)
			{
			  Int j
			  for(j = 0; j < parm.bytesPerLine; j++)
			    pngbuf[j] = ~pngbuf[j]
			}
#ifndef WORDS_BIGENDIAN
                      /* SANE is endian-native, PNG is big-endian, */
                      /* see: https://www.w3.org/TR/2003/REC-PNG-20031110/#7Integers-and-byte-order */
                      if(parm.depth == 16)
                        {
                          Int j
                          for(j = 0; j < parm.bytesPerLine; j += 2)
                            {
                              Sane.Byte LSB
                              LSB = pngbuf[j]
                              pngbuf[j] = pngbuf[j + 1]
                              pngbuf[j + 1] = LSB
                            }
                        }
#endif
		      png_write_row(png_ptr, pngbuf)
		      i += parm.bytesPerLine - pngrow
		      left -= parm.bytesPerLine - pngrow
		      pngrow = 0
		    }
		  memcpy(pngbuf + pngrow, buffer + i, left)
		  pngrow += left
		}
	      else
#endif
#ifdef HAVE_LIBJPEG
	      if(output_format == OUTPUT_JPEG)
	        {
		  var i: Int = 0
		  Int left = len
		  while(jpegrow + left >= parm.bytesPerLine)
		    {
		      memcpy(jpegbuf + jpegrow, buffer + i, parm.bytesPerLine - jpegrow)
		      if(parm.depth == 1)
			{
			  Int col1, col8
			  JSAMPLE *buf8 = malloc(parm.bytesPerLine * 8)
			  for(col1 = 0; col1 < parm.bytesPerLine; col1++)
			    for(col8 = 0; col8 < 8; col8++)
			      buf8[col1 * 8 + col8] = jpegbuf[col1] & (1 << (8 - col8 - 1)) ? 0 : 0xff
		          jpeg_write_scanlines(&cinfo, &buf8, 1)
			  free(buf8)
			} else {
		          jpeg_write_scanlines(&cinfo, &jpegbuf, 1)
			}
		      i += parm.bytesPerLine - jpegrow
		      left -= parm.bytesPerLine - jpegrow
		      jpegrow = 0
		    }
		  memcpy(jpegbuf + jpegrow, buffer + i, left)
		  jpegrow += left
		}
	      else
#endif
	      if((output_format == OUTPUT_TIFF) || (parm.depth != 16))
		fwrite(buffer, 1, len, ofp)
	      else
		{
#if !defined(WORDS_BIGENDIAN)
		  var i: Int, start = 0

		  /* check if we have saved one byte from the last Sane.read */
		  if(hang_over > -1)
		    {
		      if(len > 0)
			{
			  fwrite(buffer, 1, 1, ofp)
			  buffer[0] = (Sane.Byte) hang_over
			  hang_over = -1
			  start = 1
			}
		    }
		  /* now do the byte-swapping */
		  for(i = start; i < (len - 1); i += 2)
		    {
		      unsigned char LSB
		      LSB = buffer[i]
		      buffer[i] = buffer[i + 1]
		      buffer[i + 1] = LSB
		    }
		  /* check if we have an odd number of bytes */
		  if(((len - start) % 2) != 0)
		    {
		      hang_over = buffer[len - 1]
		      len--
		    }
#endif
		  fwrite(buffer, 1, len, ofp)
		}
	    }

	  if(verbose && parm.depth == 8)
	    {
	      for(i = 0; i < len; ++i)
		if(buffer[i] >= max)
		  max = buffer[i]
		else if(buffer[i] < min)
		  min = buffer[i]
	    }
	}
      first_frame = 0
    }
  while(!parm.last_frame)

  if(must_buffer)
    {
      image.height = image.y

      switch(output_format) {
      case OUTPUT_TIFF:
	sanei_write_tiff_header(parm.format, parm.pixels_per_line,
				 image.height, parm.depth, resolution_value,
				 icc_profile, ofp)
      break
      case OUTPUT_PNM:
	write_pnm_header(parm.format, parm.pixels_per_line,
                          image.height, parm.depth, ofp)
      break
#ifdef HAVE_LIBPNG
      case OUTPUT_PNG:
	write_png_header(parm.format, parm.pixels_per_line,
			  image.height, parm.depth, resolution_value,
			  icc_profile, ofp, &png_ptr, &info_ptr)
      break
#endif
#ifdef HAVE_LIBJPEG
      case OUTPUT_JPEG:
	write_jpeg_header(parm.format, parm.pixels_per_line,
			   parm.lines, resolution_value,
			   ofp, &cinfo, &jerr)
      break
#endif
      }

#if !defined(WORDS_BIGENDIAN)
      /* multibyte pnm file may need byte swap to LE */
      /* FIXME: other bit depths? */
      if(output_format != OUTPUT_TIFF && parm.depth == 16)
	{
	  var i: Int
	  for(i = 0; i < image.height * image.width; i += 2)
	    {
	      unsigned char LSB
	      LSB = image.data[i]
	      image.data[i] = image.data[i + 1]
	      image.data[i + 1] = LSB
	    }
	}
#endif

	fwrite(image.data, 1, image.height * image.width * image.num_channels, ofp)
    }
#ifdef HAVE_LIBPNG
    if(output_format == OUTPUT_PNG)
	png_write_end(png_ptr, info_ptr)
#endif
#ifdef HAVE_LIBJPEG
    if(output_format == OUTPUT_JPEG)
	jpeg_finish_compress(&cinfo)
#endif

  /* flush the output buffer */
  fflush( ofp )

cleanup:
#ifdef HAVE_LIBPNG
  if(output_format == OUTPUT_PNG) {
    png_destroy_write_struct(&png_ptr, &info_ptr)
    free(pngbuf)
  }
#endif
#ifdef HAVE_LIBJPEG
  if(output_format == OUTPUT_JPEG) {
    jpeg_destroy_compress(&cinfo)
    free(jpegbuf)
  }
#endif
  if(image.data)
    free(image.data)


  expected_bytes = ((uint64_t)parm.bytesPerLine) * parm.lines *
    ((parm.format == Sane.FRAME_RGB
      || parm.format == Sane.FRAME_GRAY) ? 1 : 3)
  if(parm.lines < 0)
    expected_bytes = 0
  if(total_bytes > expected_bytes && expected_bytes != 0)
    {
      fprintf(stderr,
	       "%s: WARNING: read more data than announced by backend "
               "(%" PRIu64 "/%" PRIu64 ")\n", prog_name, total_bytes, expected_bytes)
    }
  else if(verbose)
    fprintf(stderr, "%s: read %" PRIu64 " bytes in total\n", prog_name, total_bytes)

  return status
}

#define clean_buffer(buf,size)	memset((buf), 0x23, size)

static void
pass_fail(Int max, Int len, Sane.Byte * buffer, Sane.Status status)
{
  if(status != Sane.STATUS_GOOD)
    fprintf(stderr, "FAIL Error: %s\n", Sane.strstatus(status))
  else if(buffer[len] != 0x23)
    {
      while(len <= max && buffer[len] != 0x23)
	++len
      fprintf(stderr, "FAIL Cheat: %d bytes\n", len)
    }
  else if(len > max)
    fprintf(stderr, "FAIL Overflow: %d bytes\n", len)
  else if(len == 0)
    fprintf(stderr, "FAIL No data\n")
  else
    fprintf(stderr, "PASS\n")
}

static Sane.Status
test_it(void)
{
  var i: Int, len
  Sane.Parameters parm
  Sane.Status status
  Image image = { 0, 0, 0, 0, 0, 0 ]
  static const char *format_name[] =
    { "gray", "RGB", "red", "green", "blue" ]

#ifdef Sane.STATUS_WARMING_UP
  do
    {
      status = Sane.start(device)
    }
  while(status == Sane.STATUS_WARMING_UP)
#else
  status = Sane.start(device)
#endif

  if(status != Sane.STATUS_GOOD)
    {
      fprintf(stderr, "%s: Sane.start: %s\n",
	       prog_name, Sane.strstatus(status))
      goto cleanup
    }

  status = Sane.get_parameters(device, &parm)
  if(status != Sane.STATUS_GOOD)
    {
      fprintf(stderr, "%s: Sane.get_parameters: %s\n",
	       prog_name, Sane.strstatus(status))
      goto cleanup
    }

  if(parm.lines >= 0)
    fprintf(stderr, "%s: scanning image of size %dx%d pixels at "
	     "%d bits/pixel\n", prog_name, parm.pixels_per_line, parm.lines,
	     parm.depth * (Sane.FRAME_RGB == parm.format ? 3 : 1))
  else
    fprintf(stderr, "%s: scanning image %d pixels wide and "
	     "variable height at %d bits/pixel\n",
	     prog_name, parm.pixels_per_line,
	     parm.depth * (Sane.FRAME_RGB == parm.format ? 3 : 1))
  fprintf(stderr, "%s: acquiring %s frame, %d bits/sample\n", prog_name,
	   parm.format <= Sane.FRAME_BLUE ? format_name[parm.format]:"Unknown",
           parm.depth)

  image.data = malloc(parm.bytesPerLine * 2)

  clean_buffer(image.data, parm.bytesPerLine * 2)
  fprintf(stderr, "%s: reading one scanline, %d bytes...\t", prog_name,
	   parm.bytesPerLine)
  status = Sane.read(device, image.data, parm.bytesPerLine, &len)
  pass_fail(parm.bytesPerLine, len, image.data, status)
  if(status != Sane.STATUS_GOOD)
    goto cleanup

  clean_buffer(image.data, parm.bytesPerLine * 2)
  fprintf(stderr, "%s: reading one byte...\t\t", prog_name)
  status = Sane.read(device, image.data, 1, &len)
  pass_fail(1, len, image.data, status)
  if(status != Sane.STATUS_GOOD)
    goto cleanup

  for(i = 2; i < parm.bytesPerLine * 2; i *= 2)
    {
      clean_buffer(image.data, parm.bytesPerLine * 2)
      fprintf(stderr, "%s: stepped read, %d bytes... \t", prog_name, i)
      status = Sane.read(device, image.data, i, &len)
      pass_fail(i, len, image.data, status)
      if(status != Sane.STATUS_GOOD)
	goto cleanup
    }

  for(i /= 2; i > 2; i /= 2)
    {
      clean_buffer(image.data, parm.bytesPerLine * 2)
      fprintf(stderr, "%s: stepped read, %d bytes... \t", prog_name, i - 1)
      status = Sane.read(device, image.data, i - 1, &len)
      pass_fail(i - 1, len, image.data, status)
      if(status != Sane.STATUS_GOOD)
	goto cleanup
    }

cleanup:
  Sane.cancel(device)
  if(image.data)
    free(image.data)
  return status
}


static Int
get_resolution(void)
{
  const Sane.Option_Descriptor *resopt
  Int resol = 0
  void *val

  if(resolution_optind < 0)
    return 0
  resopt = Sane.get_option_descriptor(device, resolution_optind)
  if(!resopt)
    return 0

  val = alloca(resopt.size)
  if(!val)
    return 0

  Sane.control_option(device, resolution_optind, Sane.ACTION_GET_VALUE, val,
		       0)
  if(resopt.type == Sane.TYPE_INT)
    resol = *(Int *) val
  else
    resol = (Int) (Sane.UNFIX(*(Sane.Fixed *) val) + 0.5)

  return resol
}

static void
scanimage_exit(status: Int)
{
  if(device)
    {
      if(verbose > 1)
	fprintf(stderr, "Closing device\n")
      Sane.close(device)
    }
  if(verbose > 1)
    fprintf(stderr, "Calling Sane.exit\n")
  Sane.exit()

  if(all_options)
    free(all_options)
  if(option_number)
    free(option_number)
  if(verbose > 1)
    fprintf(stderr, "scanimage: finished\n")
  exit(status)
}

/** @brief print device options to stdout
 *
 * @param device struct of the opened device to describe
 * @param num_dev_options number of device options
 * @param ro Sane.TRUE to print read-only options
 */
static void print_options(Sane.Device * device, Int num_dev_options, Bool ro)
{
  var i: Int, j
  const Sane.Option_Descriptor *opt

  for(i = 1; i < num_dev_options; ++i)
    {
      opt = 0

      /* scan area uses modified option struct */
      for(j = 0; j < 4; ++j)
	if(i == window[j])
	  opt = window_option + j

      if(!opt)
	opt = Sane.get_option_descriptor(device, i)

      if(ro || Sane.OPTION_IS_SETTABLE(opt.cap)
	  || opt.type == Sane.TYPE_GROUP)
	print_option(device, i, opt)
    }
  if(num_dev_options)
    fputc("\n", stdout)
}

static Int guess_output_format(const char* output_file)
{
  if(output_file == NULL)
    {
      fprintf(stderr, "Output format is not set, using pnm as a default.\n")
      return OUTPUT_PNM
    }

  // if the user passes us a path with a known extension then he won"t be surprised if we figure
  // out correct --format option. No warning is necessary in that case.
  const char* extension = strrchr(output_file, ".")
  if(extension != NULL)
    {
      struct {
        const char* extension
        Int output_format
      } formats[] = {
        { ".pnm", OUTPUT_PNM },
        { ".png", OUTPUT_PNG },
        { ".jpg", OUTPUT_JPEG },
        { ".jpeg", OUTPUT_JPEG },
        { ".tiff", OUTPUT_TIFF },
        { ".tif", OUTPUT_TIFF }
      ]
      for(unsigned i = 0; i < sizeof(formats) / sizeof(formats[0]); ++i)
        {
          if(strcmp(extension, formats[i].extension) == 0)
            return formats[i].output_format
        }
    }

  // it would be very confusing if user makes a typo in the filename and the output format changes.
  // This is most likely not what the user wanted.
  fprintf(stderr, "Could not guess output format from the given path and no --format given.\n")
  exit(1)
}

func Int main(Int argc, char **argv)
{
  Int ch, i, index, all_options_len
  const Sane.Device **device_list
  Int num_dev_options = 0
  const char *devname = 0
  const char *defdevname = 0
  const char *format = 0
  char readbuf[2]
  char *readbuf2
  Int batch = 0
  Int batch_print = 0
  Int batch_prompt = 0
  Int batch_count = BATCH_COUNT_UNLIMITED
  Int batch_start_at = 1
  Int batch_increment = 1
  Sane.Status status
  char *full_optstring
  Int version_code
  FILE *ofp = NULL

  buffer_size = (32 * 1024);	/* default size */

  prog_name = strrchr(argv[0], "/")
  if(prog_name)
    ++prog_name
  else
    prog_name = argv[0]

  defdevname = getenv("Sane.DEFAULT_DEVICE")

  Sane.init(&version_code, auth_callback)

  /* make a first pass through the options with error printing and argument
     permutation disabled: */
  opterr = 0
  while((ch = getopt_long(argc, argv, "-" BASE_OPTSTRING, basic_options,
			    &index)) != EOF)
    {
      switch(ch)
	{
	case ":":
	case "?":
	  break;		/* may be an option that we"ll parse later on */
	case "d":
	  devname = optarg
	  break
	case "b":
	  /* This may have already been set by the batch-count flag */
	  batch = 1
	  format = optarg
	  break
	case "h":
	  help = 1
	  break
	case "i":		/* icc profile */
	  icc_profile = optarg
	  break
	case "v":
	  ++verbose
	  break
	case "p":
          progress = 1
	  break
        case "o":
          output_file = optarg
          break
	case "B":
          if(optarg)
	    buffer_size = 1024 * atoi(optarg)
          else
	    buffer_size = (1024 * 1024)
	  break
	case "T":
	  test = 1
	  break
	case "A":
	  all = 1
	  break
	case "n":
	  dont_scan = 1
	  break
	case OPTION_BATCH_PRINT:
	  batch_print = 1
	  break
	case OPTION_BATCH_PROMPT:
	  batch_prompt = 1
	  break
	case OPTION_BATCH_INCREMENT:
	  batch_increment = atoi(optarg)
	  break
	case OPTION_BATCH_START_AT:
	  batch_start_at = atoi(optarg)
	  break
	case OPTION_BATCH_DOUBLE:
	  batch_increment = 2
	  break
	case OPTION_BATCH_COUNT:
	  batch_count = atoi(optarg)
	  batch = 1
	  break
	case OPTION_FORMAT:
	  if(strcmp(optarg, "tiff") == 0)
	    output_format = OUTPUT_TIFF
	  else if(strcmp(optarg, "png") == 0)
	    {
#ifdef HAVE_LIBPNG
	      output_format = OUTPUT_PNG
#else
	      fprintf(stderr, "PNG support not compiled in\n")
	      exit(1)
#endif
	    }
	  else if(strcmp(optarg, "jpeg") == 0)
	    {
#ifdef HAVE_LIBJPEG
	      output_format = OUTPUT_JPEG
#else
	      fprintf(stderr, "JPEG support not compiled in\n")
	      exit(1)
#endif
	    }
          else if(strcmp(optarg, "pnm") == 0)
            {
              output_format = OUTPUT_PNM
            }
          else
            {
              fprintf(stderr, "Unknown output image format "%s".\n", optarg)
              fprintf(stderr, "Supported formats: pnm, tiff")
#ifdef HAVE_LIBPNG
              fprintf(stderr, ", png")
#endif
#ifdef HAVE_LIBJPEG
              fprintf(stderr, ", jpeg")
#endif
              fprintf(stderr, ".\n")
              exit(1)
            }
	  break
	case OPTION_MD5:
	  accept_only_md5_auth = 1
	  break
	case "L":
	case "f":
	  {
	    var i: Int = 0

	    status = Sane.get_devices(&device_list, Sane.FALSE)
	    if(status != Sane.STATUS_GOOD)
	      {
		fprintf(stderr, "%s: Sane.get_devices() failed: %s\n",
			 prog_name, Sane.strstatus(status))
		scanimage_exit(1)
	      }

	    if(ch == "L")
	      {
		for(i = 0; device_list[i]; ++i)
		  {
		    printf("device `%s" is a %s %s %s\n",
			    device_list[i]->name, device_list[i]->vendor,
			    device_list[i]->model, device_list[i]->type)
		  }
	      }
	    else
	      {
		var i: Int = 0, int_arg = 0
		const char *percent, *start
		const char *text_arg = 0
		char ftype

		for(i = 0; device_list[i]; ++i)
		  {
		    start = optarg
		    while(*start && (percent = strchr(start, "%")))
		      {
			Int start_len = percent - start
			percent++
			if(*percent)
			  {
			    switch(*percent)
			      {
			      case "d":
				text_arg = device_list[i]->name
				ftype = "s"
				break
			      case "v":
				text_arg = device_list[i]->vendor
				ftype = "s"
				break
			      case "m":
				text_arg = device_list[i]->model
				ftype = "s"
				break
			      case "t":
				text_arg = device_list[i]->type
				ftype = "s"
				break
			      case "i":
				int_arg = i
				ftype = "i"
				break
			      case "n":
				text_arg = "\n"
				ftype = "s"
				break
			      case "%":
				text_arg = "%"
				ftype = "s"
				break
			      default:
				fprintf(stderr,
					 "%s: unknown format specifier %%%c\n",
					 prog_name, *percent)
                                text_arg = "%"
				ftype = "s"
			      }
			    printf("%.*s", start_len, start)
			    switch(ftype)
			      {
			      case "s":
				printf("%s", text_arg)
				break
			      case "i":
				printf("%i", int_arg)
				break
			      }
			    start = percent + 1
			  }
			else
			  {
			    /* last char of the string is a "%", ignore it */
			    start++
			    break
			  }
		      }
		    if(*start)
		      printf("%s", start)
		  }
	      }
	    if(i == 0 && ch != "f")
	      printf("\nNo scanners were identified. If you were expecting "
                "something different,\ncheck that the scanner is plugged "
		"in, turned on and detected by the\nsane-find-scanner tool "
		"(if appropriate). Please read the documentation\nwhich came "
		"with this software(README, FAQ, manpages).\n")

	    if(defdevname)
	      printf("default device is `%s"\n", defdevname)
	    scanimage_exit(0)
	    break
	  }
	case "V":
	  printf("scanimage(%s) %s; backend version %d.%d.%d\n", PACKAGE,
		  VERSION, Sane.VERSION_MAJOR(version_code),
		  Sane.VERSION_MINOR(version_code),
		  Sane.VERSION_BUILD(version_code))
	  scanimage_exit(0)
	  break
	default:
	  break;		/* ignore device specific options for now */
	}
    }

  if(help)
    {
      printf("Usage: %s[OPTION]...\n\
\n\
Start image acquisition on a scanner device and write image data to\n\
standard output.\n\
\n\
Parameters are separated by a blank from single-character options(e.g.\n\
-d epson) and by a \"=\" from multi-character options(e.g. --device-name=epson).\n\
-d, --device-name=DEVICE   use a given scanner device(e.g. hp:/dev/scanner)\n\
    --format=pnm|tiff|png|jpeg  file format of output file\n\
-i, --icc-profile=PROFILE  include this ICC profile into TIFF file\n", prog_name)
      printf("\
-L, --list-devices         show available scanner devices\n\
-f, --formatted-device-list=FORMAT similar to -L, but the FORMAT of the output\n\
                           can be specified: %%d(device name), %%v(vendor),\n\
                           %%m(model), %%t(type), %%i(index number), and\n\
                           %%n(newline)\n\
-b, --batch[=FORMAT]       working in batch mode, FORMAT is `out%%d.pnm" `out%%d.tif"\n\
                           `out%%d.png" or `out%%d.jpg" by default depending on --format\n\
                           This option is incompatible with --output-file.")
      printf("\
    --batch-start=#        page number to start naming files with\n\
    --batch-count=#        how many pages to scan in batch mode\n\
    --batch-increment=#    increase page number in filename by #\n\
    --batch-double         increment page number by two, same as\n\
                           --batch-increment=2\n\
    --batch-print          print image filenames to stdout\n\
    --batch-prompt         ask for pressing a key before scanning a page\n")
      printf("\
    --accept-md5-only      only accept authorization requests using md5\n\
-p, --progress             print progress messages\n\
-o, --output-file=PATH     save output to the given file instead of stdout.\n\
                           This option is incompatible with --batch.\n\
-n, --dont-scan            only set options, don"t actually scan\n\
-T, --test                 test backend thoroughly\n\
-A, --all-options          list all available backend options\n\
-h, --help                 display this help message and exit\n\
-v, --verbose              give even more status messages\n\
-B, --buffer-size=#        change input buffer size(in kB, default 32)\n")
      printf("\
-V, --version              print version information\n")
    }

  if(batch && output_file != NULL)
    {
      fprintf(stderr, "--batch and --output-file can"t be used together.\n")
      exit(1)
    }

  if(output_format == OUTPUT_UNKNOWN)
    output_format = guess_output_format(output_file)

  if(!devname)
    {
      /* If no device name was specified explicitly, we look at the
         environment variable Sane.DEFAULT_DEVICE.  If this variable
         is not set, we open the first device we find(if any): */
      devname = defdevname
      if(!devname)
	{
	  status = Sane.get_devices(&device_list, Sane.FALSE)
	  if(status != Sane.STATUS_GOOD)
	    {
	      fprintf(stderr, "%s: Sane.get_devices() failed: %s\n",
		       prog_name, Sane.strstatus(status))
	      scanimage_exit(1)
	    }
	  if(!device_list[0])
	    {
	      fprintf(stderr, "%s: no SANE devices found\n", prog_name)
	      scanimage_exit(1)
	    }
	  devname = device_list[0]->name
	}
    }

  status = Sane.open(devname, &device)
  if(status != Sane.STATUS_GOOD)
    {
      fprintf(stderr, "%s: open of device %s failed: %s\n",
	       prog_name, devname, Sane.strstatus(status))
      if(devname[0] == "/")
	fprintf(stderr, "\nYou seem to have specified a UNIX device name, "
		 "or filename instead of selecting\nthe SANE scanner or "
		 "image acquisition device you want to use. As an example,\n"
		 "you might want \"epson:/dev/sg0\" or "
		 "\"hp:/dev/usbscanner0\". If any supported\ndevices are "
		 "installed in your system, you should be able to see a "
		 "list with\n\"scanimage --list-devices\".\n")
      if(help)
	device = 0
      else
        scanimage_exit(1)
    }

  if(device)
    {
      const Sane.Option_Descriptor * desc_ptr

      /* Good form to always get the descriptor once before value */
      desc_ptr = Sane.get_option_descriptor(device, 0)
      if(!desc_ptr)
	{
	  fprintf(stderr, "%s: unable to get option count descriptor\n",
		   prog_name)
	  scanimage_exit(1)
	}

      /* We got a device, find out how many options it has */
      status = Sane.control_option(device, 0, Sane.ACTION_GET_VALUE,
				    &num_dev_options, 0)
      if(status != Sane.STATUS_GOOD)
	{
	  fprintf(stderr, "%s: unable to determine option count\n",
		   prog_name)
	  scanimage_exit(1)
	}

      /* malloc global option lists */
      all_options_len = num_dev_options + NELEMS(basic_options) + 1
      all_options = malloc(all_options_len * sizeof(all_options[0]))
      option_number_len = num_dev_options
      option_number = malloc(option_number_len * sizeof(option_number[0]))
      if(!all_options || !option_number)
	{
	  fprintf(stderr, "%s: out of memory in main()\n",
		   prog_name)
	  scanimage_exit(1)
	}

      /* load global option lists */
      fetch_options(device)

      {
	char *larg, *targ, *xarg, *yarg
	larg = targ = xarg = yarg = ""

	/* Maybe accept t, l, x, and y options. */
	if(window[0])
	  xarg = "x:"

	if(window[1])
	  yarg = "y:"

	if(window[2])
	  larg = "l:"

	if(window[3])
	  targ = "t:"

	/* Now allocate the full option list. */
	full_optstring = malloc(strlen(BASE_OPTSTRING)
				 + strlen(larg) + strlen(targ)
				 + strlen(xarg) + strlen(yarg) + 1)

	if(!full_optstring)
	  {
	    fprintf(stderr, "%s: out of memory\n", prog_name)
	    scanimage_exit(1)
	  }

	strcpy(full_optstring, BASE_OPTSTRING)
	strcat(full_optstring, larg)
	strcat(full_optstring, targ)
	strcat(full_optstring, xarg)
	strcat(full_optstring, yarg)
      }

      /* re-run argument processing with backend-specific options included
       * this time, enable error printing and arg permutation */
      optind = 0
      opterr = 1
      while((ch = getopt_long(argc, argv, full_optstring, all_options,
				&index)) != EOF)
	{
	  switch(ch)
	    {
	    case ":":
	    case "?":
	      scanimage_exit(1);		/* error message is printed by getopt_long() */

	    case "d":
	    case "h":
	    case "p":
            case "o":
	    case "v":
	    case "V":
	    case "T":
	    case "B":
	      /* previously handled options */
	      break

	    case "x":
	      window_val_user[0] = 1
	      parse_vector(&window_option[0], optarg, &window_val[0], 1)
	      break

	    case "y":
	      window_val_user[1] = 1
	      parse_vector(&window_option[1], optarg, &window_val[1], 1)
	      break

	    case "l":		/* tl-x */
	      process_backend_option(device, window[2], optarg)
	      break

	    case "t":		/* tl-y */
	      process_backend_option(device, window[3], optarg)
	      break

	    case 0:
	      process_backend_option(device, option_number[index], optarg)
	      break
	    }
	}
      if(optind < argc)
	{
	  fprintf(stderr, "%s: argument without option: `%s"; ", prog_name,
		   argv[argc - 1])
	  fprintf(stderr, "try %s --help\n", prog_name)
	  scanimage_exit(1)
	}

      free(full_optstring)

      /* convert x/y to br_x/br_y */
      for(index = 0; index < 2; ++index)
	if(window[index])
	  {
            Sane.Word pos = 0
	    Sane.Word val = window_val[index]

	    if(window[index + 2])
	      {
		Sane.control_option(device, window[index + 2],
				     Sane.ACTION_GET_VALUE, &pos, 0)
		val += pos
	      }
	    set_option(device, window[index], &val)
	  }

      /* output device-specific help */
      if(help)
	{
	  printf("\nOptions specific to device `%s":\n", devname)
	  print_options(device, num_dev_options, Sane.FALSE)
	}

      /*  list all device-specific options */
      if(all)
	{
	  printf("\nAll options specific to device `%s":\n", devname)
	  print_options(device, num_dev_options, Sane.TRUE)
	  scanimage_exit(0)
	}
    }

  /* output device list */
  if(help)
    {
      printf("\
Type ``%s --help -d DEVICE"" to get list of all options for DEVICE.\n\
\n\
List of available devices:", prog_name)
      status = Sane.get_devices(&device_list, Sane.FALSE)
      if(status == Sane.STATUS_GOOD)
	{
	  Int column = 80

	  for(i = 0; device_list[i]; ++i)
	    {
	      if(column + strlen(device_list[i]->name) + 1 >= 80)
		{
		  printf("\n    ")
		  column = 4
		}
	      if(column > 4)
		{
		  fputc(" ", stdout)
		  column += 1
		}
	      fputs(device_list[i]->name, stdout)
	      column += strlen(device_list[i]->name)
	    }
	}
      fputc("\n", stdout)
      scanimage_exit(0)
    }

  if(dont_scan)
    scanimage_exit(0)

  if(output_format != OUTPUT_PNM)
    resolution_value = get_resolution()

#ifdef SIGHUP
  signal(SIGHUP, sighandler)
#endif
#ifdef SIGPIPE
  signal(SIGPIPE, sighandler)
#endif
  signal(SIGINT, sighandler)
  signal(SIGTERM, sighandler)

  if(test == 0)
    {
      Int n = batch_start_at

      if(batch && NULL == format)
	{
	  switch(output_format) {
	  case OUTPUT_TIFF:
	    format = "out%d.tif"
	    break
	  case OUTPUT_PNM:
	    format = "out%d.pnm"
	    break
#ifdef HAVE_LIBPNG
	  case OUTPUT_PNG:
	    format = "out%d.png"
	    break
#endif
#ifdef HAVE_LIBJPEG
	  case OUTPUT_JPEG:
	    format = "out%d.jpg"
	    break
#endif
	  }
	}

      if(!batch)
        {
          ofp = stdout
          if(output_file != NULL)
            {
              ofp = fopen(output_file, "w")
              if(ofp == NULL)
                {
                  fprintf(stderr, "%s: could not open output file "%s", "
                          "exiting\n", prog_name, output_file)
                  scanimage_exit(1)
                }
            }
        }

      if(batch)
	{
	  fputs("Scanning ", stderr)
	  if(batch_count == BATCH_COUNT_UNLIMITED)
	    fputs("infinity", stderr)
	  else
	    fprintf(stderr, "%d", batch_count)
	  fprintf(stderr,
		   " page%s, incrementing by %d, numbering from %d\n",
		   batch_count == 1 ? "" : "s", batch_increment, batch_start_at)
	}

      else if(isatty(fileno(ofp))){
	fprintf(stderr,"%s: output is not a file, exiting\n", prog_name)
	scanimage_exit(1)
      }

      buffer = malloc(buffer_size)

      do
	{
	  char path[PATH_MAX]
	  char part_path[PATH_MAX]
	  if(batch)		/* format is NULL unless batch mode */
	    {
	      sprintf(path, format, n);	/* love --(C++) */
	      strcpy(part_path, path)
	      strcat(part_path, ".part")
	    }


	  if(batch)
	    {
	      if(batch_prompt)
		{
		  fprintf(stderr, "Place document no. %d on the scanner.\n",
			   n)
		  fprintf(stderr, "Press <RETURN> to continue.\n")
		  fprintf(stderr, "Press Ctrl + D to terminate.\n")
		  readbuf2 = fgets(readbuf, 2, stdin)

		  if(readbuf2 == NULL)
		    {
		      if(ofp)
			{
			  fclose(ofp)
			  ofp = NULL
			}
		      break;	/* get out of this loop */
		    }
		}
	      fprintf(stderr, "Scanning page %d\n", n)
	    }

#ifdef Sane.STATUS_WARMING_UP
          do
	    {
	      status = Sane.start(device)
	    }
	  while(status == Sane.STATUS_WARMING_UP)
#else
	  status = Sane.start(device)
#endif
	  if(status != Sane.STATUS_GOOD)
	    {
	      fprintf(stderr, "%s: Sane.start: %s\n",
		       prog_name, Sane.strstatus(status))
	      if(ofp)
		{
		  fclose(ofp)
		  ofp = NULL
		}
	      break
	    }


	  /* write to .part file while scanning is in progress */
	  if(batch)
	    {
	      if(NULL == (ofp = fopen(part_path, "w")))
		{
		  fprintf(stderr, "cannot open %s\n", part_path)
		  Sane.cancel(device)
		  return Sane.STATUS_ACCESS_DENIED
		}
	    }

	  status = scan_it(ofp)
	  if(batch)
	    {
	      fprintf(stderr, "Scanned page %d.", n)
	      fprintf(stderr, " (scanner status = %d)\n", status)
	    }

	  switch(status)
	    {
	    case Sane.STATUS_GOOD:
	    case Sane.STATUS_EOF:
	      status = Sane.STATUS_GOOD
	      if(batch)
		{
		  if(!ofp || 0 != fclose(ofp))
		    {
		      fprintf(stderr, "cannot close image file\n")
		      Sane.cancel(device)
		      return Sane.STATUS_ACCESS_DENIED
		    }
		  else
		    {
		      ofp = NULL
		      /* let the fully scanned file show up */
		      if(rename(part_path, path))
			{
			  fprintf(stderr, "cannot rename %s to %s\n",
				part_path, path)
			  Sane.cancel(device)
			  return Sane.STATUS_ACCESS_DENIED
			}
		      if(batch_print)
			{
			  fprintf(stdout, "%s\n", path)
			  fflush(stdout)
			}
		    }
		}
              else
                {
                  if(output_file && ofp)
                    {
                      fclose(ofp)
                      ofp = NULL
                    }
                }
	      break
	    default:
	      if(batch)
		{
		  if(ofp)
		    {
		      fclose(ofp)
		      ofp = NULL
		    }
		  unlink(part_path)
		}
              else
                {
                  if(output_file && ofp)
                    {
                      fclose(ofp)
                      ofp = NULL
                    }
                  unlink(output_file)
                }
	      break
	    }			/* switch */
	  n += batch_increment
	}
      while((batch
	      && (batch_count == BATCH_COUNT_UNLIMITED || --batch_count))
	     && Sane.STATUS_GOOD == status)

      if(batch)
	{
	  Int num_pgs = (n - batch_start_at) / batch_increment
	  fprintf(stderr, "Batch terminated, %d page%s scanned\n",
		   num_pgs, num_pgs == 1 ? "" : "s")
	}

      if(batch
	  && Sane.STATUS_NO_DOCS == status
	  && (batch_count == BATCH_COUNT_UNLIMITED)
	  && n > batch_start_at)
	status = Sane.STATUS_GOOD

      Sane.cancel(device)
    }
  else
    status = test_it()

  scanimage_exit(status)
  /* the line below avoids compiler warnings */
  return status
}
