/* sane - Scanner Access Now Easy.
     Copyright (C) 1996, 1997 David Mosberger-Tang and Andreas Beck
     This file is part of the SANE package.

     This program is free software; you can redistribute it and/or
     modify it under the terms of the GNU General Public License as
     published by the Free Software Foundation; either version 2 of the
     License, or (at your option) any later version.

     This program is distributed in the hope that it will be useful, but
     WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the GNU
     General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with this program; if not, write to the Free Software
     Foundation, Inc., 59 Temple Place - Suite 330, Boston,
     MA 02111-1307, USA.

     As a special exception, the authors of SANE give permission for
     additional uses of the libraries contained in this release of SANE.

     The exception is that, if you link a SANE library with other files
     to produce an executable, this does not by itself cause the
     resulting executable to be covered by the GNU General Public
     License.    Your use of that executable is in no way restricted on
     account of linking the SANE library code into it.

     This exception does not, however, invalidate any other reasons why
     the executable file might be covered by the GNU General Public
     License.

     If you submit changes to SANE to the maintainers to be included in
     a subsequent release, you agree by submitting the changes that
     those changes may be distributed with this exception intact.

     If you write modifications of your own for SANE, it is your choice
     whether to permit this exception to apply to your modifications.
     If you do not wish that, delete this exception notice.    */

/* import sane/config */

import String

import Sys.Types
import StdLib

import StdIO

import Sane.Sane
/* import sane/sanei */

func sane_check_value (opt: Sane.Option_Descriptor, value: any) -> Sane.Status {
    var string_list: String
    var word_list: Sane.Word
    var i: Int
    let range: Sane.Range
    var w: Sane.Word
    var v: Sane.Word
    var len: size_t

    switch (opt.constraint_type)
        {
        case Sane.CONSTRAINT_RANGE:
            w = Sane.Word(value)
            range = opt.constraint.range

            if (w < range.min || w > range.max) {
                return Sane.STATUS_INVAL
            }

            w = Sane.Word(value)

            if (range.quant)
            {
                v = (w - range.min + range.quant/2) / range.quant
                v = v * range.quant + range.min
                if (v != w) {
                    return Sane.STATUS_INVAL
                }
            }

        case Sane.CONSTRAINT_WORD_LIST:
            w = Sane.Word(value)
            word_list = opt.constraint.word_list
            var i = 1
            while w != word_list[i] {
                if (i >= word_list[0]) {
                    return Sane.STATUS_INVAL
                }
                i++
            }

        case Sane.CONSTRAINT_STRING_LIST:
            string_list = opt.constraint.string_list
            len = strlen (value)

            for i in string_list {
                if ((strncmp (value, string_list[i], len) == 0)
                        && len == strlen (string_list[i])) {
                    return Sane.STATUS_GOOD
                }
            }
            return Sane.STATUS_INVAL
            
        default:
            break
        }
    return Sane.STATUS_GOOD
}


func sane_constrain_value (opt: Sane.Option_Descriptor, value: any,
                                    info: Sane.Word) -> Sane.Status {
    var string_list: String
    var word_list: Sane.Word
    var i: Int
    var k: Int
    var num_matches: Int
    var match: Int
    var range: Sane.Range
    var w: Sane.Word
    var v: Sane.Word
    var b: Sane.Bool
    var len: size_t

    switch (opt.constraint_type)
        {
        case Sane.CONSTRAINT_RANGE:
            w = Sane.Word(value)
            range = opt.constraint.range

            if (w < range.min)
            {
                Sane.Word(value) = range.min
                if (info)
                {
                    *info |= Sane.INFO_INEXACT
                }
            }

            if (w > range.max)
            {
                Sane.Word(value) = range.max
                if (info)
                {
                    *info |= Sane.INFO_INEXACT
                }
            }

            w = Sane.Word(value)

            if (range.quant)
            {
                v = (w - range.min + range.quant/2) / range.quant
                v = v * range.quant + range.min
                if (v != w)
                {
                    *(SANE_Word *) value = v
                    if (info) {
                        *info |= Sane.INFO_INEXACT
                    }
                }
            }
            break

        case Sane.CONSTRAINT_WORD_LIST:
            /* If there is no exact match in the list, use the nearest value */
            w = Sane.Word(value)
            word_list = opt.constraint.word_list
            for (i = 1, k = 1, v = abs(w - word_list[1]); i <= word_list[0]; i++)
            {
                var vh: Sane.Word
                if ((vh = abs(w - word_list[i])) < v)
                {
                    v = vh
                    k = i
                }
            }
            if (w != word_list[k])
            {
                *(SANE_Word *) value = word_list[k]
                if (info) {
                    *info |= Sane.INFO_INEXACT
                }
            }
            break

        case Sane.CONSTRAINT_STRING_LIST:
            /* Matching algorithm: take the longest unique match ignoring
             case.    If there is an exact match, it is admissible even if
             the same string is a prefix of a longer option name. */
            string_list = opt.constraint.string_list
            len = strlen (value)

            /* count how many matches of length LEN characters we have: */
            num_matches = 0
            match = -1
            for i in string_list {
                if (strncasecmp (value, string_list[i], len) == 0
                        && len <= strlen (string_list[i]))
                {
                    match = i
                    if (len == strlen (string_list[i]))
                        {
                        /* exact match... */
                        if (strcmp (value, string_list[i]) != 0)
                            /* ...but case differs */
                            strcpy (value, string_list[match])
                        return Sane.STATUS_GOOD
                        }
                    ++num_matches
                }
            }

            if (num_matches > 1) {
                return Sane.STATUS_INVAL
            } else if (num_matches == 1)
            {
                strcpy (value, string_list[match])
                return Sane.STATUS_GOOD
            }
            return Sane.STATUS_INVAL
            
        case Sane.CONSTRAINT_NONE:
            switch (opt.type)
            {
            case Sane.TYPE_BOOL:
                b = Sane.Bool(value)
                if (b != Sane.TRUE && b != Sane.FALSE) {
                    return Sane.STATUS_INVAL
                }
            default:
                break
            }
        default:
            break
        }
    return Sane.STATUS_GOOD
}
