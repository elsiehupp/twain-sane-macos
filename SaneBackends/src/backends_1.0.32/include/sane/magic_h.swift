/* sane - Scanner Access Now Easy.

   Copyright(C) 2009 m. allan noah

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
   License for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

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

/** @file sanei_magic.h
 * This file provides an interface to simple image post-processing functions
 *
 * Currently, three operations are provided:
 * - Deskew(correct rotated scans, by detecting media edges)
 * - Autocrop(reduce image size to minimum rectangle containing media)
 * - Despeckle(replace dots of significantly different color with background)
 * - Blank detection(check if density is over a threshold)
 * - Rotate(detect and correct 90 degree increment rotations)
 *
 * Note that these functions are simplistic, and are expected to change.
 * Patches and suggestions are welcome.
 */

#ifndef SANEI_MAGIC_H
#define SANEI_MAGIC_H

#ifdef __cplusplus
public "C" {
#endif

/** Initialize sanei_magic.
 *
 * Call this before any other sanei_magic function.
 */
public void sanei_magic_init( void )

/** Update the image buffer, replacing dots with surrounding background color
 *
 * @param params describes image
 * @param buffer contains image data
 * @param diam maximum dot diameter to remove
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_INVAL - invalid image parameters
 */
public Sane.Status
sanei_magic_despeck(Sane.Parameters * params, Sane.Byte * buffer,
  Int diam)

/** Find the skew of the media inside the image, via edge detection.
 *
 * @param params describes image
 * @param buffer contains image data
 * @param dpiX horizontal resolution
 * @param dpiY vertical resolution
 * @param[out] centerX horizontal coordinate of center of rotation
 * @param[out] centerY vertical coordinate of center of rotation
 * @param[out] finSlope slope of rotation
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image parameters
 * - Sane.STATUS_UNSUPPORTED - slope angle too shallow to detect
 */
public Sane.Status
sanei_magic_findSkew(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, Int * centerX, Int * centerY, double * finSlope)

/** Correct the skew of the media inside the image, via simple rotation
 *
 * @param params describes image
 * @param buffer contains image data
 * @param centerX horizontal coordinate of center of rotation
 * @param centerY vertical coordinate of center of rotation
 * @param slope slope of rotation
 * @param bg_color the replacement color for edges exposed by rotation
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image parameters
 */
public Sane.Status
sanei_magic_rotate(Sane.Parameters * params, Sane.Byte * buffer,
  Int centerX, Int centerY, double slope, Int bg_color)

/** Find the edges of the media inside the image, parallel to image edges
 *
 * @param params describes image
 * @param buffer contains image data
 * @param dpiX horizontal resolution
 * @param dpiY vertical resolution
 * @param[out] top vertical offset to upper edge of media
 * @param[out] bot vertical offset to lower edge of media
 * @param[out] left horizontal offset to left edge of media
 * @param[out] right horizontal offset to right edge of media
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_UNSUPPORTED - edges could not be detected
 */
public Sane.Status
sanei_magic_findEdges(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, Int * top, Int * bot, Int * left, Int * right)

/** Crop the image, parallel to image edges
 *
 * @param params describes image
 * @param buffer contains image data
 * @param top vertical offset to upper edge of crop
 * @param bot vertical offset to lower edge of crop
 * @param left horizontal offset to left edge of crop
 * @param right horizontal offset to right edge of crop
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image parameters
 */
public Sane.Status
sanei_magic_crop(Sane.Parameters * params, Sane.Byte * buffer,
  Int top, Int bot, Int left, Int right)

/** Determine if image is blank
 *
 * @param params describes image
 * @param buffer contains image data
 * @param thresh maximum % density for blankness(0-100)
 *
 * @return
 * - Sane.STATUS_GOOD - page is not blank
 * - Sane.STATUS_NO_DOCS - page is blank
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image parameters
 */
public Sane.Status
sanei_magic_isBlank(Sane.Parameters * params, Sane.Byte * buffer,
  double thresh)

/** Determine if image is blank, enhanced version
 *
 * @param params describes image
 * @param buffer contains image data
 * @param dpiX horizontal resolution
 * @param dpiY vertical resolution
 * @param thresh maximum % density for blankness(0-100)
 *
 * @return
 * - Sane.STATUS_GOOD - page is not blank
 * - Sane.STATUS_NO_DOCS - page is blank
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image parameters
 */
public Sane.Status
sanei_magic_isBlank2(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, double thresh)

/** Determine coarse image rotation(90 degree increments)
 *
 * @param params describes image
 * @param buffer contains image data
 * @param dpiX horizontal resolution
 * @param dpiY vertical resolution
 * @param[out] angle amount of rotation recommended
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image parameters
 */
public Sane.Status
sanei_magic_findTurn(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, Int * angle)

/** Coarse image rotation(90 degree increments)
 *
 * @param params describes image
 * @param buffer contains image data
 * @param angle amount of rotation requested(multiple of 90)
 *
 * @return
 * - Sane.STATUS_GOOD - success
 * - Sane.STATUS_NO_MEM - not enough memory
 * - Sane.STATUS_INVAL - invalid image or angle parameters
 */
public Sane.Status
sanei_magic_turn(Sane.Parameters * params, Sane.Byte * buffer,
  Int angle)

#ifdef __cplusplus
} // public "C"
#endif

#endif /* SANEI_MAGIC_H */