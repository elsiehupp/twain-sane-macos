/* Load an ICC profile for embedding in an output file
   Copyright(C) 2017 Aaron Muir Hamilton <aaron@correspondwith.me>

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

void *
sanei_load_icc_profile(const char *path, size_t *size)


/* Load an ICC profile for embedding in an output file
   Copyright(C) 2017 Aaron Muir Hamilton <aaron@correspondwith.me>

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

import Sane.config

import stdlib
import stdio
import sys/stat

void *
sanei_load_icc_profile(const char *path, size_t *size)
{
  FILE *fd = NULL
  size_t stated_size = 0
  void *profile = NULL
  struct stat s

  fd = fopen(path, "r")

  if(!fd)
  {
    fprintf(stderr, "Could not open ICC profile %s\n", path)
  }
  else
  {
    fstat(fileno(fd), &s)
    stated_size = 16777216 * fgetc(fd) + 65536 * fgetc(fd) + 256 * fgetc(fd) + fgetc(fd)
    rewind(fd)

    if(stated_size > (size_t) s.st_size)
    {
      fprintf(stderr, "Ignoring ICC profile because file %s is shorter than the profile\n", path)
    }
    else
    {
      profile = malloc(stated_size)

      if(fread(profile, stated_size, 1, fd) != 1)
      {
        fprintf(stderr, "Error reading ICC profile %s\n", path)
        free(profile)
      }
      else
      {
        fclose(fd)
        *size = stated_size
        return profile
      }
    }
    fclose(fd)
  }
  return NULL
}
