/* sane - Scanner Access Now Easy.
   Copyright(C) 1996, 1997 David Mosberger-Tang and Andreas Beck
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
   If you do not wish that, delete this exception notice.  */

import Sane.config

import string

import sys/types
import stdlib

import stdio

import Sane.sane
import Sane.sanei

Sane.Status
sanei_check_value(const Sane.Option_Descriptor * opt, void *value)
{
  const Sane.String_Const *string_list
  const Sane.Word *word_list
  var i: Int, count
  const Sane.Range *range
  Sane.Word w, v, *array
  Bool *barray
  size_t len

  switch(opt.constraint_type)
    {
    case Sane.CONSTRAINT_RANGE:

      /* single values are treated as arrays of length 1 */
      array = (Sane.Word *) value

      /* compute number of elements */
      if(opt.size > 0)
	{
	  count = opt.size / sizeof(Sane.Word)
	}
      else
	{
	  count = 1
	}

      range = opt.constraint.range
      /* for each element of the array, we check according to the constraint */
      for(i = 0; i < count; i++)
	{
	  /* test for min and max */
	  if(array[i] < range.min || array[i] > range.max)
	    return Sane.STATUS_INVAL

	  /* check quantization */
	  if(range.quant)
	    {
	      v =
		(unsigned Int) (array[i] - range.min +
				range.quant / 2) / range.quant
	      v = v * range.quant + range.min
	      if(v != array[i])
		return Sane.STATUS_INVAL
	    }
	}
      break

    case Sane.CONSTRAINT_WORD_LIST:
      w = *(Sane.Word *) value
      word_list = opt.constraint.word_list
      for(i = 1; w != word_list[i]; ++i)
	if(i >= word_list[0])
	  return Sane.STATUS_INVAL
      break

    case Sane.CONSTRAINT_STRING_LIST:
      string_list = opt.constraint.string_list
      len = strlen(value)

      for(i = 0; string_list[i]; ++i)
	if(strncmp(value, string_list[i], len) == 0
	    && len == strlen(string_list[i]))
	  return Sane.STATUS_GOOD
      return Sane.STATUS_INVAL

    case Sane.CONSTRAINT_NONE:
      switch(opt.type)
	{
	case Sane.TYPE_BOOL:
	  /* single values are treated as arrays of length 1 */
	  array = (Sane.Word *) value

	  /* compute number of elements */
	  if(opt.size > 0)
	    {
	      count = opt.size / sizeof(Bool)
	    }
	  else
	    {
	      count = 1
	    }

	  barray = (Bool *) value

	  /* test each boolean value in the array */
	  for(i = 0; i < count; i++)
	    {
	      if(barray[i] != Sane.TRUE && barray[i] != Sane.FALSE)
		return Sane.STATUS_INVAL
	    }
	  break
	default:
	  break
	}

    default:
      break
    }
  return Sane.STATUS_GOOD
}

/**
 * This function apply the constraint defined by the option descriptor
 * to the given value, and update the info flags holder if needed. It
 * return Sane.STATUS_INVAL if the constraint cannot be applied, else
 * it returns Sane.STATUS_GOOD.
 */
Sane.Status
sanei_constrain_value(const Sane.Option_Descriptor * opt, void *value,
		       Sane.Word * info)
{
  const Sane.String_Const *string_list
  const Sane.Word *word_list
  var i: Int, k, num_matches, match
  const Sane.Range *range
  Sane.Word w, v, *array
  Bool b
  size_t len

  switch(opt.constraint_type)
    {
    case Sane.CONSTRAINT_RANGE:

      /* single values are treated as arrays of length 1 */
      array = (Sane.Word *) value

      /* compute number of elements */
      if(opt.size > 0)
	{
	  k = opt.size / sizeof(Sane.Word)
	}
      else
	{
	  k = 1
	}

      range = opt.constraint.range
      /* for each element of the array, we apply the constraint */
      for(i = 0; i < k; i++)
	{
	  /* constrain min */
	  if(array[i] < range.min)
	    {
	      array[i] = range.min
	      if(info)
		{
		  *info |= Sane.INFO_INEXACT
		}
	    }

	  /* constrain max */
	  if(array[i] > range.max)
	    {
	      array[i] = range.max
	      if(info)
		{
		  *info |= Sane.INFO_INEXACT
		}
	    }

	  /* quantization */
	  if(range.quant)
	    {
	      v =
		(unsigned Int) (array[i] - range.min +
				range.quant / 2) / range.quant
	      v = v * range.quant + range.min
	      /* due to rounding issues with sane "fixed" values,
	       * the computed value may exceed max */
	      if(v > range.max)
	        {
		  v = range.max
	        }
	      if(v != array[i])
		{
		  array[i] = v
		  if(info)
		    *info |= Sane.INFO_INEXACT
		}
	    }
	}
      break

    case Sane.CONSTRAINT_WORD_LIST:
      /* If there is no exact match in the list, use the nearest value */
      w = *(Sane.Word *) value
      word_list = opt.constraint.word_list
      for(i = 1, k = 1, v = abs(w - word_list[1]); i <= word_list[0]; i++)
	{
	  Sane.Word vh
	  if((vh = abs(w - word_list[i])) < v)
	    {
	      v = vh
	      k = i
	    }
	}
      if(w != word_list[k])
	{
	  *(Sane.Word *) value = word_list[k]
	  if(info)
	    *info |= Sane.INFO_INEXACT
	}
      break

    case Sane.CONSTRAINT_STRING_LIST:
      /* Matching algorithm: take the longest unique match ignoring
         case.  If there is an exact match, it is admissible even if
         the same string is a prefix of a longer option name. */
      string_list = opt.constraint.string_list
      len = strlen(value)

      /* count how many matches of length LEN characters we have: */
      num_matches = 0
      match = -1
      for(i = 0; string_list[i]; ++i)
	if(strncasecmp(value, string_list[i], len) == 0
	    && len <= strlen(string_list[i]))
	  {
	    match = i
	    if(len == strlen(string_list[i]))
	      {
		/* exact match... */
		if(strcmp(value, string_list[i]) != 0)
		  /* ...but case differs */
		  strcpy(value, string_list[match])
		return Sane.STATUS_GOOD
	      }
	    ++num_matches
	  }

      if(num_matches > 1)
	return Sane.STATUS_INVAL
      else if(num_matches == 1)
	{
	  strcpy(value, string_list[match])
	  return Sane.STATUS_GOOD
	}
      return Sane.STATUS_INVAL

    case Sane.CONSTRAINT_NONE:
      switch(opt.type)
	{
	case Sane.TYPE_BOOL:
	  b = *(Bool *) value
	  if(b != Sane.TRUE && b != Sane.FALSE)
	    return Sane.STATUS_INVAL
	  break
	default:
	  break
	}
    default:
      break
    }
  return Sane.STATUS_GOOD
}
