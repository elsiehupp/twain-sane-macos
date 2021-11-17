/*
 * sanei_magic - Image processing functions for despeckle, deskew, and autocrop

   Copyright(C) 2009 m. allan noah

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

import Sane.config

import stdio
import stdlib
import string
import errno
import math

#define BACKEND_NAME sanei_magic      /* name of this module for debugging */

import Sane.sane
import Sane.sanei_debug
import Sane.sanei_magic

/* prototypes for utility functions defined at bottom of file */
Int * sanei_magic_getTransY(
  Sane.Parameters * params, Int dpi, Sane.Byte * buffer, Int top)

Int * sanei_magic_getTransX(
  Sane.Parameters * params, Int dpi, Sane.Byte * buffer, Int left)

static Sane.Status getTopEdge(Int width, Int height, Int resolution,
  Int * buff, double * finSlope, Int * finXInter, Int * finYInter)

static Sane.Status getLeftEdge(Int width, Int height, Int * top, Int * bot,
 double slope, Int * finXInter, Int * finYInter)

static Sane.Status getLine(Int height, Int width, Int * buff,
  Int slopes, double minSlope, double maxSlope,
  Int offsets, Int minOffset, Int maxOffset,
  double * finSlope, Int * finOffset, Int * finDensity)

void
sanei_magic_init( void )
{
  DBG_INIT()
}

/* find small spots and replace them with image background color */
Sane.Status
sanei_magic_despeck(Sane.Parameters * params, Sane.Byte * buffer,
  Int diam)
{

  Sane.Status ret = Sane.STATUS_GOOD

  Int pw = params.pixels_per_line
  Int bw = params.bytesPerLine
  Int h  = params.lines
  Int bt = bw*h

  var i: Int,j,k,l,n

  DBG(10, "sanei_magic_despeck: start\n")

  if(params.format == Sane.FRAME_RGB){

    for(i=bw; i<bt-bw-(bw*diam); i+=bw){
      for(j=1; j<pw-1-diam; j++){

        Int thresh = 255*3
        Int outer[] = {0,0,0]
        Int hits = 0

        /* loop over rows and columns in window */
        /* find darkest pixel */
        for(k=0; k<diam; k++){
          for(l=0; l<diam; l++){
            Int tmp = 0

            for(n=0; n<3; n++){
              tmp += buffer[i + j*3 + k*bw + l*3 + n]
            }

            if(tmp < thresh)
              thresh = tmp
          }
        }

        /* convert darkest pixel into a brighter threshold */
        thresh = (thresh + 255*3 + 255*3)/3

        /*loop over rows and columns around window */
        for(k=-1; k<diam+1; k++){
          for(l=-1; l<diam+1; l++){

            Int tmp[3]

            /* don"t count pixels in the window */
            if(k != -1 && k != diam && l != -1 && l != diam)
              continue

            for(n=0; n<3; n++){
              tmp[n] = buffer[i + j*3 + k*bw + l*3 + n]
              outer[n] += tmp[n]
            }
            if(tmp[0]+tmp[1]+tmp[2] < thresh){
              hits++
              break
            }
          }
        }

        /*no hits, overwrite with avg surrounding color*/
        if(!hits){

          /* per channel replacement color */
          for(n=0; n<3; n++){
            outer[n] /= (4*diam + 4)
          }

          for(k=0; k<diam; k++){
            for(l=0; l<diam; l++){
              for(n=0; n<3; n++){
                buffer[i + j*3 + k*bw + l*3 + n] = outer[n]
              }
            }
          }
        }
      }
    }
  }

  else if(params.format == Sane.FRAME_GRAY && params.depth == 8){
    for(i=bw; i<bt-bw-(bw*diam); i+=bw){
      for(j=1; j<pw-1-diam; j++){

        Int thresh = 255
        Int outer = 0
        Int hits = 0

        for(k=0; k<diam; k++){
          for(l=0; l<diam; l++){
            if(buffer[i + j + k*bw + l] < thresh)
              thresh = buffer[i + j + k*bw + l]
          }
        }

        /* convert darkest pixel into a brighter threshold */
        thresh = (thresh + 255 + 255)/3

        /*loop over rows and columns around window */
        for(k=-1; k<diam+1; k++){
          for(l=-1; l<diam+1; l++){

            Int tmp = 0

            /* don"t count pixels in the window */
            if(k != -1 && k != diam && l != -1 && l != diam)
              continue

            tmp = buffer[i + j + k*bw + l]

            if(tmp < thresh){
              hits++
              break
            }

            outer += tmp
          }
        }

        /*no hits, overwrite with avg surrounding color*/
        if(!hits){
          /* replacement color */
          outer /= (4*diam + 4)

          for(k=0; k<diam; k++){
            for(l=0; l<diam; l++){
              buffer[i + j + k*bw + l] = outer
            }
          }
        }
      }
    }
  }

  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){
    for(i=bw; i<bt-bw-(bw*diam); i+=bw){
      for(j=1; j<pw-1-diam; j++){

        Int curr = 0
        Int hits = 0

        for(k=0; k<diam; k++){
          for(l=0; l<diam; l++){
            curr += buffer[i + k*bw + (j+l)/8] >> (7-(j+l)%8) & 1
          }
        }

        if(!curr)
          continue

        /*loop over rows and columns around window */
        for(k=-1; k<diam+1; k++){
          for(l=-1; l<diam+1; l++){

            /* don"t count pixels in the window */
            if(k != -1 && k != diam && l != -1 && l != diam)
              continue

            hits += buffer[i + k*bw + (j+l)/8] >> (7-(j+l)%8) & 1

            if(hits)
              break
          }
        }

        /*no hits, overwrite with white*/
        if(!hits){
          for(k=0; k<diam; k++){
            for(l=0; l<diam; l++){
              buffer[i + k*bw + (j+l)/8] &= ~(1 << (7-(j+l)%8))
            }
          }
        }
      }
    }
  }

  else{
    DBG(5, "sanei_magic_despeck: unsupported format/depth\n")
    ret = Sane.STATUS_INVAL
  }

  DBG(10, "sanei_magic_despeck: finish\n")
  return ret
}

/* find likely edges of media inside image background color */
Sane.Status
sanei_magic_findEdges(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, Int * top, Int * bot, Int * left, Int * right)
{

  Sane.Status ret = Sane.STATUS_GOOD

  Int width = params.pixels_per_line
  Int height = params.lines

  Int * topBuf = NULL, * botBuf = NULL
  Int * leftBuf = NULL, * rightBuf = NULL

  Int topCount = 0, botCount = 0
  Int leftCount = 0, rightCount = 0

  var i: Int

  DBG(10, "sanei_magic_findEdges: start\n")

  /* get buffers to find sides and bottom */
  topBuf = sanei_magic_getTransY(params,dpiY,buffer,1)
  if(!topBuf){
    DBG(5, "sanei_magic_findEdges: no topBuf\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  botBuf = sanei_magic_getTransY(params,dpiY,buffer,0)
  if(!botBuf){
    DBG(5, "sanei_magic_findEdges: no botBuf\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  leftBuf = sanei_magic_getTransX(params,dpiX,buffer,1)
  if(!leftBuf){
    DBG(5, "sanei_magic_findEdges: no leftBuf\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  rightBuf = sanei_magic_getTransX(params,dpiX,buffer,0)
  if(!rightBuf){
    DBG(5, "sanei_magic_findEdges: no rightBuf\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  /* loop thru left and right lists, look for top and bottom extremes */
  *top = height
  for(i=0; i<height; i++){
    if(rightBuf[i] > leftBuf[i]){
      if(*top > i){
        *top = i
      }

      topCount++
      if(topCount > 3){
        break
      }
    }
    else{
      topCount = 0
      *top = height
    }
  }

  *bot = -1
  for(i=height-1; i>=0; i--){
    if(rightBuf[i] > leftBuf[i]){
      if(*bot < i){
        *bot = i
      }

      botCount++
      if(botCount > 3){
        break
      }
    }
    else{
      botCount = 0
      *bot = -1
    }
  }

  /* could not find top/bot edges */
  if(*top > *bot){
    DBG(5, "sanei_magic_findEdges: bad t/b edges\n")
    ret = Sane.STATUS_UNSUPPORTED
    goto cleanup
  }

  /* loop thru top and bottom lists, look for l and r extremes
   * NOTE: We don"t look above the top or below the bottom found previously.
   * This prevents issues with adf scanners that pad the image after the
   * paper runs out(usually with white) */
  DBG(5, "sanei_magic_findEdges: bb0:%d tb0:%d b:%d t:%d\n",
    botBuf[0], topBuf[0], *bot, *top)

  *left = width
  for(i=0; i<width; i++){
    if(botBuf[i] > topBuf[i] && (botBuf[i]-10 < *bot || topBuf[i]+10 > *top)){
      if(*left > i){
        *left = i
      }

      leftCount++
      if(leftCount > 3){
        break
      }
    }
    else{
      leftCount = 0
      *left = width
    }
  }

  *right = -1
  for(i=width-1; i>=0; i--){
    if(botBuf[i] > topBuf[i] && (botBuf[i]-10 < *bot || topBuf[i]+10 > *top)){
      if(*right < i){
        *right = i
      }

      rightCount++
      if(rightCount > 3){
        break
      }
    }
    else{
      rightCount = 0
      *right = -1
    }
  }

  /* could not find left/right edges */
  if(*left > *right){
    DBG(5, "sanei_magic_findEdges: bad l/r edges\n")
    ret = Sane.STATUS_UNSUPPORTED
    goto cleanup
  }

  DBG(15, "sanei_magic_findEdges: t:%d b:%d l:%d r:%d\n",
    *top,*bot,*left,*right)

  cleanup:
  if(topBuf)
    free(topBuf)
  if(botBuf)
    free(botBuf)
  if(leftBuf)
    free(leftBuf)
  if(rightBuf)
    free(rightBuf)

  DBG(10, "sanei_magic_findEdges: finish\n")
  return ret
}

/* crop image to given size. updates params with new dimensions */
Sane.Status
sanei_magic_crop(Sane.Parameters * params, Sane.Byte * buffer,
  Int top, Int bot, Int left, Int right)
{

  Sane.Status ret = Sane.STATUS_GOOD

  Int bwidth = params.bytesPerLine

  Int pixels = 0
  Int bytes = 0
  unsigned char * line = NULL
  Int pos = 0, i

  DBG(10, "sanei_magic_crop: start\n")

  /*convert left and right to bytes, figure new byte and pixel width */
  if(params.format == Sane.FRAME_RGB){
    pixels = right-left
    bytes = pixels * 3
    left *= 3
    right *= 3
  }
  else if(params.format == Sane.FRAME_GRAY && params.depth == 8){
    pixels = right-left
    bytes = right-left
  }
  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){
    left /= 8
    right = (right+7)/8
    bytes = right-left
    pixels = bytes * 8
  }
  else{
    DBG(5, "sanei_magic_crop: unsupported format/depth\n")
    ret = Sane.STATUS_INVAL
    goto cleanup
  }

  DBG(15, "sanei_magic_crop: l:%d r:%d p:%d b:%d\n",left,right,pixels,bytes)

  line = malloc(bytes)
  if(!line){
    DBG(5, "sanei_magic_crop: no line\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  for(i=top; i<bot; i++){
    memcpy(line, buffer + i*bwidth + left, bytes)
    memcpy(buffer + pos, line, bytes)
    pos += bytes
  }

  /* update the params struct with the new image size */
  params.lines = bot-top
  params.pixels_per_line = pixels
  params.bytesPerLine = bytes

  cleanup:
  if(line)
    free(line)

  DBG(10, "sanei_magic_crop: finish\n")
  return ret
}

/* find angle of media rotation against image background */
Sane.Status
sanei_magic_findSkew(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, Int * centerX, Int * centerY, double * finSlope)
{
  Sane.Status ret = Sane.STATUS_GOOD

  Int pwidth = params.pixels_per_line
  Int height = params.lines

  double TSlope = 0
  Int TXInter = 0
  Int TYInter = 0
  double TSlopeHalf = 0
  Int TOffsetHalf = 0

  double LSlope = 0
  Int LXInter = 0
  Int LYInter = 0
  double LSlopeHalf = 0
  Int LOffsetHalf = 0

  Int rotateX = 0
  Int rotateY = 0

  Int * topBuf = NULL, * botBuf = NULL

  DBG(10, "sanei_magic_findSkew: start\n")

  dpiX=dpiX

  /* get buffers for edge detection */
  topBuf = sanei_magic_getTransY(params,dpiY,buffer,1)
  if(!topBuf){
    DBG(5, "sanei_magic_findSkew: can"t gTY\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  botBuf = sanei_magic_getTransY(params,dpiY,buffer,0)
  if(!botBuf){
    DBG(5, "sanei_magic_findSkew: can"t gTY\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  /* find best top line */
  ret = getTopEdge(pwidth, height, dpiY, topBuf,
    &TSlope, &TXInter, &TYInter)
  if(ret){
    DBG(5,"sanei_magic_findSkew: gTE error: %d",ret)
    goto cleanup
  }
  DBG(15,"top: %04.04f %d %d\n",TSlope,TXInter,TYInter)

  /* slope is too shallow, don"t want to divide by 0 */
  if(fabs(TSlope) < 0.0001){
    DBG(15,"sanei_magic_findSkew: slope too shallow: %0.08f\n",TSlope)
    ret = Sane.STATUS_UNSUPPORTED
    goto cleanup
  }

  /* find best left line, perpendicular to top line */
  LSlope = (double)-1/TSlope
  ret = getLeftEdge(pwidth, height, topBuf, botBuf, LSlope,
    &LXInter, &LYInter)
  if(ret){
    DBG(5,"sanei_magic_findSkew: gLE error: %d",ret)
    goto cleanup
  }
  DBG(15,"sanei_magic_findSkew: left: %04.04f %d %d\n",LSlope,LXInter,LYInter)

  /* find point about which to rotate */
  TSlopeHalf = tan(atan(TSlope)/2)
  TOffsetHalf = LYInter
  DBG(15,"sanei_magic_findSkew: top half: %04.04f %d\n",TSlopeHalf,TOffsetHalf)

  LSlopeHalf = tan((atan(LSlope) + ((LSlope < 0)?-M_PI_2:M_PI_2))/2)
  LOffsetHalf = - LSlopeHalf * TXInter
  DBG(15,"sanei_magic_findSkew: left half: %04.04f %d\n",LSlopeHalf,LOffsetHalf)

  rotateX = (LOffsetHalf-TOffsetHalf) / (TSlopeHalf-LSlopeHalf)
  rotateY = TSlopeHalf * rotateX + TOffsetHalf
  DBG(15,"sanei_magic_findSkew: rotate: %d %d\n",rotateX,rotateY)

  *centerX = rotateX
  *centerY = rotateY
  *finSlope = TSlope

  cleanup:
  if(topBuf)
    free(topBuf)
  if(botBuf)
    free(botBuf)

  DBG(10, "sanei_magic_findSkew: finish\n")
  return ret
}

/* function to do a simple rotation by a given slope, around
 * a given point. The point can be outside of image to get
 * proper edge alignment. Unused areas filled with bg color
 * FIXME: Do in-place rotation to save memory */
Sane.Status
sanei_magic_rotate(Sane.Parameters * params, Sane.Byte * buffer,
  Int centerX, Int centerY, double slope, Int bg_color)
{

  Sane.Status ret = Sane.STATUS_GOOD

  double slopeRad = -atan(slope)
  double slopeSin = sin(slopeRad)
  double slopeCos = cos(slopeRad)

  Int pwidth = params.pixels_per_line
  Int bwidth = params.bytesPerLine
  Int height = params.lines
  Int depth = 1

  unsigned char * outbuf
  var i: Int, j, k

  DBG(10,"sanei_magic_rotate: start: %d %d\n",centerX,centerY)

  outbuf = malloc(bwidth*height)
  if(!outbuf){
    DBG(15,"sanei_magic_rotate: no outbuf\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  if(params.format == Sane.FRAME_RGB ||
    (params.format == Sane.FRAME_GRAY && params.depth == 8)
  ){

    if(params.format == Sane.FRAME_RGB)
      depth = 3

    memset(outbuf,bg_color,bwidth*height)

    for(i=0; i<height; i++) {
      Int shiftY = centerY - i

      for(j=0; j<pwidth; j++) {
        Int shiftX = centerX - j
        Int sourceX, sourceY

        sourceX = centerX - (Int)(shiftX * slopeCos + shiftY * slopeSin)
        if(sourceX < 0 || sourceX >= pwidth)
          continue

        sourceY = centerY + (Int)(-shiftY * slopeCos + shiftX * slopeSin)
        if(sourceY < 0 || sourceY >= height)
          continue

        for(k=0; k<depth; k++) {
          outbuf[i*bwidth+j*depth+k]
            = buffer[sourceY*bwidth+sourceX*depth+k]
        }
      }
    }
  }

  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    if(bg_color)
      bg_color = 0xff

    memset(outbuf,bg_color,bwidth*height)

    for(i=0; i<height; i++) {
      Int shiftY = centerY - i

      for(j=0; j<pwidth; j++) {
        Int shiftX = centerX - j
        Int sourceX, sourceY

        sourceX = centerX - (Int)(shiftX * slopeCos + shiftY * slopeSin)
        if(sourceX < 0 || sourceX >= pwidth)
          continue

        sourceY = centerY + (Int)(-shiftY * slopeCos + shiftX * slopeSin)
        if(sourceY < 0 || sourceY >= height)
          continue

        /* wipe out old bit */
        outbuf[i*bwidth + j/8] &= ~(1 << (7-(j%8)))

        /* fill in new bit */
        outbuf[i*bwidth + j/8] |=
          ((buffer[sourceY*bwidth + sourceX/8]
          >> (7-(sourceX%8))) & 1) << (7-(j%8))
      }
    }
  }
  else{
    DBG(5, "sanei_magic_rotate: unsupported format/depth\n")
    ret = Sane.STATUS_INVAL
    goto cleanup
  }

  memcpy(buffer,outbuf,bwidth*height)

  cleanup:

  if(outbuf)
    free(outbuf)

  DBG(10,"sanei_magic_rotate: finish\n")

  return ret
}

Sane.Status
sanei_magic_isBlank(Sane.Parameters * params, Sane.Byte * buffer,
  double thresh)
{
  Sane.Status ret = Sane.STATUS_GOOD
  double imagesum = 0
  var i: Int, j

  DBG(10,"sanei_magic_isBlank: start: %f\n",thresh)

  /*convert thresh from percent(0-100) to 0-1 range*/
  thresh /= 100

  if(params.format == Sane.FRAME_RGB ||
    (params.format == Sane.FRAME_GRAY && params.depth == 8)
  ){

    /* loop over all rows, find density of each */
    for(i=0; i<params.lines; i++){
      Int rowsum = 0
      Sane.Byte * ptr = buffer + params.bytesPerLine*i

      /* loop over all columns, sum the "darkness" of the pixels */
      for(j=0; j<params.bytesPerLine; j++){
        rowsum += 255 - ptr[j]
      }

      imagesum += (double)rowsum/params.bytesPerLine/255
    }

  }
  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    /* loop over all rows, find density of each */
    for(i=0; i<params.lines; i++){
      Int rowsum = 0
      Sane.Byte * ptr = buffer + params.bytesPerLine*i

      /* loop over all columns, sum the pixels */
      for(j=0; j<params.pixels_per_line; j++){
        rowsum += ptr[j/8] >> (7-(j%8)) & 1
      }

      imagesum += (double)rowsum/params.pixels_per_line
    }

  }
  else{
    DBG(5, "sanei_magic_isBlank: unsupported format/depth\n")
    ret = Sane.STATUS_INVAL
    goto cleanup
  }

  DBG(5, "sanei_magic_isBlank: sum:%f lines:%d thresh:%f density:%f\n",
    imagesum,params.lines,thresh,imagesum/params.lines)

  if(imagesum/params.lines <= thresh){
    DBG(5, "sanei_magic_isBlank: blank!\n")
    ret = Sane.STATUS_NO_DOCS
  }

  cleanup:

  DBG(10,"sanei_magic_isBlank: finish\n")

  return ret
}

/* Divide the image into 1/2 inch squares, skipping a 1/4 inch
 * margin on all sides. If all squares are under the user"s density,
 * signal our caller to skip the image entirely, by returning
 * Sane.STATUS_NO_DOCS */
Sane.Status
sanei_magic_isBlank2 (Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, double thresh)
{
  Int xb,yb,x,y

  /* .25 inch, rounded down to 8 pixel */
  Int xquarter = dpiX/4/8*8
  Int yquarter = dpiY/4/8*8
  Int xhalf    = xquarter*2
  Int yhalf    = yquarter*2
  Int blockpix = xhalf*yhalf
  Int xblocks  = (params.pixels_per_line-xhalf)/xhalf
  Int yblocks  = (params.lines-yhalf)/yhalf

  /*convert thresh from percent(0-100) to 0-1 range*/
  thresh /= 100

  DBG(10, "sanei_magic_isBlank2: start %d %d %f %d\n",xhalf,yhalf,thresh,blockpix)

  if(params.depth == 8 &&
    (params.format == Sane.FRAME_RGB || params.format == Sane.FRAME_GRAY)
  ){

    Int Bpp = params.format == Sane.FRAME_RGB ? 3 : 1

    for(yb=0; yb<yblocks; yb++){
      for(xb=0; xb<xblocks; xb++){

        /*count dark pix in this block*/
        double blocksum = 0

        for(y=0; y<yhalf; y++){

          /* skip the top and left 1/4 inch */
          Int offset = (yquarter + yb*yhalf + y) * params.bytesPerLine
            + (xquarter + xb*xhalf) * Bpp
          Sane.Byte * ptr = buffer + offset

          /*count darkness of pix in this row*/
          Int rowsum = 0

          for(x=0; x<xhalf*Bpp; x++){
            rowsum += 255 - ptr[x]
          }

          blocksum += (double)rowsum/(xhalf*Bpp)/255
        }

        /* block was darker than thresh, keep image */
        if(blocksum/yhalf > thresh){
          DBG(15, "sanei_magic_isBlank2: not blank %f %d %d\n", blocksum/yhalf, yb, xb)
          return Sane.STATUS_GOOD
        }
        DBG(20, "sanei_magic_isBlank2: block blank %f %d %d\n", blocksum/yhalf, yb, xb)
      }
    }
  }
  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    for(yb=0; yb<yblocks; yb++){
      for(xb=0; xb<xblocks; xb++){

        /*count dark pix in this block*/
        double blocksum = 0

        for(y=0; y<yhalf; y++){

          /* skip the top and left 1/4 inch */
          Int offset = (yquarter + yb*yhalf + y) * params.bytesPerLine
            + (xquarter + xb*xhalf) / 8
          Sane.Byte * ptr = buffer + offset

          /*count darkness of pix in this row*/
          Int rowsum = 0

          for(x=0; x<xhalf; x++){
            rowsum += ptr[x/8] >> (7-(x%8)) & 1
          }

          blocksum += (double)rowsum/xhalf
        }

        /* block was darker than thresh, keep image */
        if(blocksum/yhalf > thresh){
          DBG(15, "sanei_magic_isBlank2: not blank %f %d %d\n", blocksum/yhalf, yb, xb)
          return Sane.STATUS_GOOD
        }
        DBG(20, "sanei_magic_isBlank2: block blank %f %d %d\n", blocksum/yhalf, yb, xb)
      }
    }
  }
  else{
    DBG(5, "sanei_magic_isBlank2: unsupported format/depth\n")
    return Sane.STATUS_INVAL
  }

  DBG(10, "sanei_magic_isBlank2: returning blank\n")
  return Sane.STATUS_NO_DOCS
}

Sane.Status
sanei_magic_findTurn(Sane.Parameters * params, Sane.Byte * buffer,
  Int dpiX, Int dpiY, Int * angle)
{
  Sane.Status ret = Sane.STATUS_GOOD
  var i: Int, j, k
  Int depth = 1
  Int htrans=0, vtrans=0
  Int htot=0, vtot=0

  DBG(10,"sanei_magic_findTurn: start\n")

  if(params.format == Sane.FRAME_RGB ||
    (params.format == Sane.FRAME_GRAY && params.depth == 8)
  ){

    if(params.format == Sane.FRAME_RGB)
      depth = 3

    /* loop over some rows, count segment lengths */
    for(i=0; i<params.lines; i+=dpiY/20){
      Sane.Byte * ptr = buffer + params.bytesPerLine*i
      Int color = 0
      Int len   = 0
      Int sum   = 0

      /* loop over all columns */
      for(j=0; j<params.pixels_per_line; j++){
        Int curr = 0

        /*convert color to gray*/
        for(k=0; k<depth; k++) {
          curr += ptr[j*depth+k]
        }
        curr /= depth

        /*convert gray to binary(with hysteresis) */
        curr = (curr < 100)?1:
               (curr > 156)?0:color

        /*count segment length*/
        if(curr != color || j==params.pixels_per_line-1){
          sum += len * len/5
          len = 0
          color = curr
        }
        else{
          len++
        }
      }

      htot++
      htrans += (double)sum/params.pixels_per_line
    }

    /* loop over some cols, count dark vs light transitions */
    for(i=0; i<params.pixels_per_line; i+=dpiX/20){
      Sane.Byte * ptr = buffer + i*depth
      Int color = 0
      Int len   = 0
      Int sum   = 0

      /* loop over all rows */
      for(j=0; j<params.lines; j++){
        Int curr = 0

        /*convert color to gray*/
        for(k=0; k<depth; k++) {
          curr += ptr[j*params.bytesPerLine+k]
        }
        curr /= depth

        /*convert gray to binary(with hysteresis) */
        curr = (curr < 100)?1:
               (curr > 156)?0:color

        /*count segment length*/
        if(curr != color || j==params.lines-1){
          sum += len * len/5
          len = 0
          color = curr
        }
        else{
          len++
        }
      }

      vtot++
      vtrans += (double)sum/params.lines
    }

  }
  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    /* loop over some rows, count segment lengths */
    for(i=0; i<params.lines; i+=dpiY/30){
      Sane.Byte * ptr = buffer + params.bytesPerLine*i
      Int color = 0
      Int len   = 0
      Int sum   = 0

      /* loop over all columns */
      for(j=0; j<params.pixels_per_line; j++){
        Int curr = ptr[j/8] >> (7-(j%8)) & 1

        /*count segment length*/
        if(curr != color || j==params.pixels_per_line-1){
          sum += len * len/5
          len = 0
          color = curr
        }
        else{
          len++
        }
      }

      htot++
      htrans += (double)sum/params.pixels_per_line
    }

    /* loop over some cols, count dark vs light transitions */
    for(i=0; i<params.pixels_per_line; i+=dpiX/30){
      Sane.Byte * ptr = buffer
      Int color = 0
      Int len   = 0
      Int sum   = 0

      /* loop over all rows */
      for(j=0; j<params.lines; j++){
        Int curr = ptr[j*params.bytesPerLine + i/8] >> (7-(i%8)) & 1

        /*count segment length*/
        if(curr != color || j==params.lines-1){
          sum += len * len/5
          len = 0
          color = curr
        }
        else{
          len++
        }
      }

      vtot++
      vtrans += (double)sum/params.lines
    }

  }
  else{
    DBG(5, "sanei_magic_findTurn: unsupported format/depth\n")
    ret = Sane.STATUS_INVAL
    goto cleanup
  }

  DBG(10, "sanei_magic_findTurn: vtrans=%d vtot=%d vfrac=%f htrans=%d htot=%d hfrac=%f\n",
    vtrans, vtot, (double)vtrans/vtot, htrans, htot, (double)htrans/htot
  )

  if((double)vtrans/vtot > (double)htrans/htot){
    DBG(10, "sanei_magic_findTurn: suggest turning 90\n")
    *angle = 90
  }

  cleanup:

  DBG(10,"sanei_magic_findTurn: finish\n")

  return ret
}

/* FIXME: Do in-place rotation to save memory */
Sane.Status
sanei_magic_turn(Sane.Parameters * params, Sane.Byte * buffer,
  Int angle)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int opwidth, ipwidth = params.pixels_per_line
  Int obwidth, ibwidth = params.bytesPerLine
  Int oheight, iheight = params.lines
  Int depth = 1

  unsigned char * outbuf = NULL
  var i: Int, j, k

  DBG(10,"sanei_magic_turn: start %d\n",angle)

  if(params.format == Sane.FRAME_RGB)
    depth = 3

  /*clean angle and convert to 0-3*/
  angle = (angle % 360) / 90

  /*figure size of output image*/
  switch(angle){
    case 1:
    case 3:
      opwidth = iheight
      oheight = ipwidth

      /*gray and color, 1 or 3 bytes per pixel*/
      if( params.format == Sane.FRAME_RGB
        || (params.format == Sane.FRAME_GRAY && params.depth == 8)
      ){
        obwidth = opwidth*depth
      }

      /*clamp binary to byte width. must be <= input image*/
      else if(params.format == Sane.FRAME_GRAY && params.depth == 1){
        obwidth = opwidth/8
        opwidth = obwidth*8
      }

      else{
        DBG(10,"sanei_magic_turn: bad params\n")
        ret = Sane.STATUS_INVAL
        goto cleanup
      }

      break

    case 2:
      opwidth = ipwidth
      obwidth = ibwidth
      oheight = iheight
      break

    default:
      DBG(10,"sanei_magic_turn: no turn\n")
      goto cleanup
  }

  /*get output image buffer*/
  outbuf = malloc(obwidth*oheight)
  if(!outbuf){
    DBG(15,"sanei_magic_turn: no outbuf\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  /*turn color & gray image*/
  if(params.format == Sane.FRAME_RGB ||
    (params.format == Sane.FRAME_GRAY && params.depth == 8)
  ){

    switch(angle) {

      /*rotate 90 clockwise*/
      case 1:
        for(i=0; i<oheight; i++) {
          for(j=0; j<opwidth; j++) {
            for(k=0; k<depth; k++) {
              outbuf[i*obwidth + j*depth + k]
                = buffer[(iheight-j-1)*ibwidth + i*depth + k]
            }
          }
        }
        break

      /*rotate 180 clockwise*/
      case 2:
        for(i=0; i<oheight; i++) {
          for(j=0; j<opwidth; j++) {
            for(k=0; k<depth; k++) {
              outbuf[i*obwidth + j*depth + k]
                = buffer[(iheight-i-1)*ibwidth + (ipwidth-j-1)*depth + k]
            }
          }
        }
        break

      /*rotate 270 clockwise*/
      case 3:
        for(i=0; i<oheight; i++) {
          for(j=0; j<opwidth; j++) {
            for(k=0; k<depth; k++) {
              outbuf[i*obwidth + j*depth + k]
                = buffer[j*ibwidth + (ipwidth-i-1)*depth + k]
            }
          }
        }
        break
    } /*end switch*/
  }

  /*turn binary image*/
  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    switch(angle) {

      /*rotate 90 clockwise*/
      case 1:
        for(i=0; i<oheight; i++) {
          for(j=0; j<opwidth; j++) {
            unsigned char curr
              = buffer[(iheight-j-1)*ibwidth + i/8] >> (7-(i%8)) & 1

            unsigned char mask = 1 << (7-(j%8))

            if(curr){
              outbuf[i*obwidth + j/8] |= mask
            }
            else{
              outbuf[i*obwidth + j/8] &= (~mask)
            }

          }
        }
        break

      /*rotate 180 clockwise*/
      case 2:
        for(i=0; i<oheight; i++) {
          for(j=0; j<opwidth; j++) {
            unsigned char curr
              = buffer[(iheight-i-1)*ibwidth + (ipwidth-j-1)/8] >> (j%8) & 1

            unsigned char mask = 1 << (7-(j%8))

            if(curr){
              outbuf[i*obwidth + j/8] |= mask
            }
            else{
              outbuf[i*obwidth + j/8] &= (~mask)
            }

          }
        }
        break

      /*rotate 270 clockwise*/
      case 3:
        for(i=0; i<oheight; i++) {
          for(j=0; j<opwidth; j++) {
            unsigned char curr
              = buffer[j*ibwidth + (ipwidth-i-1)/8] >> (i%8) & 1

            unsigned char mask = 1 << (7-(j%8))

            if(curr){
              outbuf[i*obwidth + j/8] |= mask
            }
            else{
              outbuf[i*obwidth + j/8] &= (~mask)
            }

          }
        }
        break
    } /*end switch*/
  }

  else{
    DBG(5, "sanei_magic_turn: unsupported format/depth\n")
    ret = Sane.STATUS_INVAL
    goto cleanup
  }

  /*copy output back into input buffer*/
  memcpy(buffer,outbuf,obwidth*oheight)

  /*update input params*/
  params.pixels_per_line = opwidth
  params.bytesPerLine = obwidth
  params.lines = oheight

  cleanup:

  if(outbuf)
    free(outbuf)

  DBG(10,"sanei_magic_turn: finish\n")

  return ret
}

/* Utility functions, not used outside this file */

/* Repeatedly call getLine to find the best range of slope and offset.
 * Shift the ranges thru 4 different positions to avoid splitting data
 * across multiple bins(false positive). Home-in on the most likely upper
 * line of the paper inside the image. Return the "best" edge. */
static Sane.Status
getTopEdge(Int width, Int height, Int resolution,
  Int * buff, double * finSlope, Int * finXInter, Int * finYInter)
{
  Sane.Status ret = Sane.STATUS_GOOD

  Int slopes = 31
  Int offsets = 31
  double maxSlope = 1
  double minSlope = -1
  Int maxOffset = resolution
  Int minOffset = -resolution

  double topSlope = 0
  Int topOffset = 0
  Int topDensity = 0

  var i: Int,j
  Int pass = 0

  DBG(10,"getTopEdge: start\n")

  while(pass++ < 7){
    double sStep = (maxSlope-minSlope)/slopes
    Int oStep = (maxOffset-minOffset)/offsets

    double slope = 0
    Int offset = 0
    Int density = 0
    Int go = 0

    topSlope = 0
    topOffset = 0
    topDensity = 0

    /* find lines 4 times with slightly moved params,
     * to bypass binning errors, highest density wins */
    for(i=0;i<2;i++){
      double sStep2 = sStep*i/2
      for(j=0;j<2;j++){
        Int oStep2 = oStep*j/2
        ret = getLine(height,width,buff,slopes,minSlope+sStep2,maxSlope+sStep2,offsets,minOffset+oStep2,maxOffset+oStep2,&slope,&offset,&density)
        if(ret){
          DBG(5,"getTopEdge: getLine error %d\n",ret)
          return ret
        }
        DBG(15,"getTopEdge: %d %d %+0.4f %d %d\n",i,j,slope,offset,density)

        if(density > topDensity){
          topSlope = slope
          topOffset = offset
          topDensity = density
        }
      }
    }

    DBG(15,"getTopEdge: ok %+0.4f %d %d\n",topSlope,topOffset,topDensity)

    /* did not find anything promising on first pass,
     * give up instead of fixating on some small, pointless feature */
    if(pass == 1 && topDensity < width/5){
      DBG(5,"getTopEdge: density too small %d %d\n",topDensity,width)
      topOffset = 0
      topSlope = 0
      break
    }

    /* if slope can zoom in some more, do so. */
    if(sStep >= 0.0001){
      minSlope = topSlope - sStep
      maxSlope = topSlope + sStep
      go = 1
    }

    /* if offset can zoom in some more, do so. */
    if(oStep){
      minOffset = topOffset - oStep
      maxOffset = topOffset + oStep
      go = 1
    }

    /* cannot zoom in more, bail out */
    if(!go){
      break
    }

    DBG(15,"getTopEdge: zoom: %+0.4f %+0.4f %d %d\n",
      minSlope,maxSlope,minOffset,maxOffset)
  }

  /* topOffset is in the center of the image,
   * convert to x and y intercept */
  if(topSlope != 0){
    *finYInter = topOffset - topSlope * width/2
    *finXInter = *finYInter / -topSlope
    *finSlope = topSlope
  }
  else{
    *finYInter = 0
    *finXInter = 0
    *finSlope = 0
  }

  DBG(10,"getTopEdge: finish\n")

  return 0
}

/* Loop thru a transition array, and use a simplified Hough transform
 * to divide likely edges into a 2-d array of bins. Then weight each
 * bin based on its angle and offset. Return the "best" bin. */
static Sane.Status
getLine(Int height, Int width, Int * buff,
  Int slopes, double minSlope, double maxSlope,
  Int offsets, Int minOffset, Int maxOffset,
  double * finSlope, Int * finOffset, Int * finDensity)
{
  Sane.Status ret = 0

  Int ** lines = NULL
  var i: Int, j
  Int rise, run
  double slope
  Int offset
  Int sIndex, oIndex
  Int hWidth = width/2

  double * slopeCenter = NULL
  Int * slopeScale = NULL
  double * offsetCenter = NULL
  Int * offsetScale = NULL

  Int maxDensity = 1
  double absMaxSlope = fabs(maxSlope)
  double absMinSlope = fabs(minSlope)
  Int absMaxOffset = abs(maxOffset)
  Int absMinOffset = abs(minOffset)

  DBG(10,"getLine: start %+0.4f %+0.4f %d %d\n",
    minSlope,maxSlope,minOffset,maxOffset)

  /*silence compiler*/
  height = height

  if(absMaxSlope < absMinSlope)
    absMaxSlope = absMinSlope

  if(absMaxOffset < absMinOffset)
    absMaxOffset = absMinOffset

  /* build an array of pretty-print values for slope */
  slopeCenter = calloc(slopes,sizeof(double))
  if(!slopeCenter){
    DBG(5,"getLine: can"t load slopeCenter\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  /* build an array of scaling factors for slope */
  slopeScale = calloc(slopes,sizeof(Int))
  if(!slopeScale){
    DBG(5,"getLine: can"t load slopeScale\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  for(j=0;j<slopes;j++){

    /* find central value of this "bucket" */
    slopeCenter[j] = (
      (double)j*(maxSlope-minSlope)/slopes+minSlope
      + (double)(j+1)*(maxSlope-minSlope)/slopes+minSlope
    )/2

    /* scale value from the requested range into an inverted 100-1 range
     * input close to 0 makes output close to 100 */
    slopeScale[j] = 101 - fabs(slopeCenter[j])*100/absMaxSlope
  }

  /* build an array of pretty-print values for offset */
  offsetCenter = calloc(offsets,sizeof(double))
  if(!offsetCenter){
    DBG(5,"getLine: can"t load offsetCenter\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  /* build an array of scaling factors for offset */
  offsetScale = calloc(offsets,sizeof(Int))
  if(!offsetScale){
    DBG(5,"getLine: can"t load offsetScale\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  for(j=0;j<offsets;j++){

    /* find central value of this "bucket"*/
    offsetCenter[j] = (
      (double)j/offsets*(maxOffset-minOffset)+minOffset
      + (double)(j+1)/offsets*(maxOffset-minOffset)+minOffset
    )/2

    /* scale value from the requested range into an inverted 100-1 range
     * input close to 0 makes output close to 100 */
    offsetScale[j] = 101 - fabs(offsetCenter[j])*100/absMaxOffset
  }

  /* build 2-d array of "density", divided into slope and offset ranges */
  lines = calloc(slopes, sizeof(Int *))
  if(!lines){
    DBG(5,"getLine: can"t load lines\n")
    ret = Sane.STATUS_NO_MEM
    goto cleanup
  }

  for(i=0;i<slopes;i++){
    if(!(lines[i] = calloc(offsets, sizeof(Int)))){
      DBG(5,"getLine: can"t load lines %d\n",i)
      ret = Sane.STATUS_NO_MEM
      goto cleanup
    }
  }

  for(i=0;i<width;i++){
    for(j=i+1;j<width && j<i+width/3;j++){

      /*FIXME: check for invalid(min/max) values?*/
      rise = buff[j] - buff[i]
      run = j-i

      slope = (double)rise/run
      if(slope >= maxSlope || slope < minSlope)
        continue

      /* offset in center of width, not y intercept! */
      offset = slope * hWidth + buff[i] - slope * i
      if(offset >= maxOffset || offset < minOffset)
        continue

      sIndex = (slope - minSlope) * slopes/(maxSlope-minSlope)
      if(sIndex >= slopes)
        continue

      oIndex = (offset - minOffset) * offsets/(maxOffset-minOffset)
      if(oIndex >= offsets)
        continue

      lines[sIndex][oIndex]++
    }
  }

  /* go thru array, and find most dense line(highest number) */
  for(i=0;i<slopes;i++){
    for(j=0;j<offsets;j++){
      if(lines[i][j] > maxDensity)
        maxDensity = lines[i][j]
    }
  }

  DBG(15,"getLine: maxDensity %d\n",maxDensity)

  *finSlope = 0
  *finOffset = 0
  *finDensity = 0

  /* go thru array, and scale densities to % of maximum, plus adjust for
   * preferred(smaller absolute value) slope and offset */
  for(i=0;i<slopes;i++){
    for(j=0;j<offsets;j++){
      lines[i][j] = (float)lines[i][j] / maxDensity * slopeScale[i] * offsetScale[j]
      if(lines[i][j] > *finDensity){
        *finDensity = lines[i][j]
        *finSlope = slopeCenter[i]
        *finOffset = offsetCenter[j]
      }
    }
  }

  if(0){
    fprintf(stderr,"offsetCenter:       ")
    for(j=0;j<offsets;j++){
      fprintf(stderr," %+04.0f",offsetCenter[j])
    }
    fprintf(stderr,"\n")

    fprintf(stderr,"offsetScale:        ")
    for(j=0;j<offsets;j++){
      fprintf(stderr," %04d",offsetScale[j])
    }
    fprintf(stderr,"\n")

    for(i=0;i<slopes;i++){
      fprintf(stderr,"slope: %02d %+02.2f %03d:",i,slopeCenter[i],slopeScale[i])
      for(j=0;j<offsets;j++){
        fprintf(stderr,"% 5d",lines[i][j])
      }
      fprintf(stderr,"\n")
    }
  }

  /* don"t forget to cleanup */
  cleanup:
  for(i=0;i<slopes;i++){
    if(lines[i])
      free(lines[i])
  }
  if(lines)
    free(lines)
  if(slopeCenter)
    free(slopeCenter)
  if(slopeScale)
    free(slopeScale)
  if(offsetCenter)
    free(offsetCenter)
  if(offsetScale)
    free(offsetScale)

  DBG(10,"getLine: finish\n")

  return ret
}

/* find the left side of paper by moving a line
 * perpendicular to top slope across the image
 * the "left-most" point on the paper is the
 * one with the smallest X intercept
 * return x and y intercepts */
static Sane.Status
getLeftEdge(Int width, Int height, Int * top, Int * bot,
 double slope, Int * finXInter, Int * finYInter)
{

  var i: Int
  Int topXInter, topYInter
  Int botXInter, botYInter
  Int leftCount

  DBG(10,"getEdgeSlope: start\n")

  topXInter = width
  topYInter = 0
  leftCount = 0

  for(i=0;i<width;i++){

    if(top[i] < height){
      Int tyi = top[i] - (slope * i)
      Int txi = tyi/-slope

      if(topXInter > txi){
        topXInter = txi
        topYInter = tyi
      }

      leftCount++
      if(leftCount > 5){
        break
      }
    }
    else{
      topXInter = width
      topYInter = 0
      leftCount = 0
    }
  }

  botXInter = width
  botYInter = 0
  leftCount = 0

  for(i=0;i<width;i++){

    if(bot[i] > -1){

      Int byi = bot[i] - (slope * i)
      Int bxi = byi/-slope

      if(botXInter > bxi){
        botXInter = bxi
        botYInter = byi
      }

      leftCount++
      if(leftCount > 5){
        break
      }
    }
    else{
      botXInter = width
      botYInter = 0
      leftCount = 0
    }
  }

  if(botXInter < topXInter){
    *finXInter = botXInter
    *finYInter = botYInter
  }
  else{
    *finXInter = topXInter
    *finYInter = topYInter
  }

  DBG(10,"getEdgeSlope: finish\n")

  return 0
}

/* Loop thru the image and look for first color change in each column.
 * Return a malloc"d array. Caller is responsible for freeing. */
Int *
sanei_magic_getTransY(
  Sane.Parameters * params, Int dpi, Sane.Byte * buffer, Int top)
{
  Int * buff

  var i: Int, j, k
  Int winLen = 9

  Int width = params.pixels_per_line
  Int height = params.lines
  Int depth = 1

  /* defaults for bottom-up */
  Int firstLine = height-1
  Int lastLine = -1
  Int direction = -1

  DBG(10, "sanei_magic_getTransY: start\n")

  /* override for top-down */
  if(top){
    firstLine = 0
    lastLine = height
    direction = 1
  }

  /* build output and preload with impossible value */
  buff = calloc(width,sizeof(Int))
  if(!buff){
    DBG(5, "sanei_magic_getTransY: no buff\n")
    return NULL
  }
  for(i=0; i<width; i++)
    buff[i] = lastLine

  /* load the buff array with y value for first color change from edge
   * gray/color uses a different algo from binary/halftone */
  if(params.format == Sane.FRAME_RGB ||
    (params.format == Sane.FRAME_GRAY && params.depth == 8)
  ){

    if(params.format == Sane.FRAME_RGB)
      depth = 3

    /* loop over all columns, find first transition */
    for(i=0; i<width; i++){

      Int near = 0
      Int far = 0

      /* load the near and far windows with repeated copy of first pixel */
      for(k=0; k<depth; k++){
        near += buffer[(firstLine*width+i) * depth + k]
      }
      near *= winLen
      far = near

      /* move windows, check delta */
      for(j=firstLine+direction; j!=lastLine; j+=direction){

        Int farLine = j-winLen*2*direction
        Int nearLine = j-winLen*direction

        if(farLine < 0 || farLine >= height){
          farLine = firstLine
        }
        if(nearLine < 0 || nearLine >= height){
          nearLine = firstLine
        }

        for(k=0; k<depth; k++){
          far -= buffer[(farLine*width+i)*depth+k]
          far += buffer[(nearLine*width+i)*depth+k]

          near -= buffer[(nearLine*width+i)*depth+k]
          near += buffer[(j*width+i)*depth+k]
        }

        /* significant transition */
        if(abs(near - far) > 50*winLen*depth - near*40/255){
          buff[i] = j
          break
        }
      }
    }
  }

  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    Int near = 0

    for(i=0; i<width; i++){

      /* load the near window with first pixel */
      near = buffer[(firstLine*width+i)/8] >> (7-(i%8)) & 1

      /* move */
      for(j=firstLine+direction; j!=lastLine; j+=direction){
        if((buffer[(j*width+i)/8] >> (7-(i%8)) & 1) != near){
          buff[i] = j
          break
        }
      }
    }
  }

  /* some other format? */
  else{
    DBG(5, "sanei_magic_getTransY: unsupported format/depth\n")
    free(buff)
    return NULL
  }

  /* ignore transitions with few neighbors within .5 inch */
  for(i=0;i<width-7;i++){
    Int sum = 0
    for(j=1;j<=7;j++){
      if(abs(buff[i+j] - buff[i]) < dpi/2)
        sum++
    }
    if(sum < 2)
      buff[i] = lastLine
  }

  DBG(10, "sanei_magic_getTransY: finish\n")

  return buff
}

/* Loop thru the image height and look for first color change in each row.
 * Return a malloc"d array. Caller is responsible for freeing. */
Int *
sanei_magic_getTransX(
  Sane.Parameters * params, Int dpi, Sane.Byte * buffer, Int left)
{
  Int * buff

  var i: Int, j, k
  Int winLen = 9

  Int bwidth = params.bytesPerLine
  Int width = params.pixels_per_line
  Int height = params.lines
  Int depth = 1

  /* defaults for right-first */
  Int firstCol = width-1
  Int lastCol = -1
  Int direction = -1

  DBG(10, "sanei_magic_getTransX: start\n")

  /* override for left-first*/
  if(left){
    firstCol = 0
    lastCol = width
    direction = 1
  }

  /* build output and preload with impossible value */
  buff = calloc(height,sizeof(Int))
  if(!buff){
    DBG(5, "sanei_magic_getTransX: no buff\n")
    return NULL
  }
  for(i=0; i<height; i++)
    buff[i] = lastCol

  /* load the buff array with x value for first color change from edge
   * gray/color uses a different algo from binary/halftone */
  if(params.format == Sane.FRAME_RGB ||
    (params.format == Sane.FRAME_GRAY && params.depth == 8)
  ){

    if(params.format == Sane.FRAME_RGB)
      depth = 3

    /* loop over all columns, find first transition */
    for(i=0; i<height; i++){

      Int near = 0
      Int far = 0

      /* load the near and far windows with repeated copy of first pixel */
      for(k=0; k<depth; k++){
        near += buffer[i*bwidth + k]
      }
      near *= winLen
      far = near

      /* move windows, check delta */
      for(j=firstCol+direction; j!=lastCol; j+=direction){

        Int farCol = j-winLen*2*direction
        Int nearCol = j-winLen*direction

        if(farCol < 0 || farCol >= width){
          farCol = firstCol
        }
        if(nearCol < 0 || nearCol >= width){
          nearCol = firstCol
        }

        for(k=0; k<depth; k++){
          far -= buffer[i*bwidth + farCol*depth + k]
          far += buffer[i*bwidth + nearCol*depth + k]

          near -= buffer[i*bwidth + nearCol*depth + k]
          near += buffer[i*bwidth + j*depth + k]
        }

        if(abs(near - far) > 50*winLen*depth - near*40/255){
          buff[i] = j
          break
        }
      }
    }
  }

  else if(params.format == Sane.FRAME_GRAY && params.depth == 1){

    Int near = 0

    for(i=0; i<height; i++){

      /* load the near window with first pixel */
      near = buffer[i*bwidth + firstCol/8] >> (7-(firstCol%8)) & 1

      /* move */
      for(j=firstCol+direction; j!=lastCol; j+=direction){
        if((buffer[i*bwidth + j/8] >> (7-(j%8)) & 1) != near){
          buff[i] = j
          break
        }
      }
    }
  }

  /* some other format? */
  else{
    DBG(5, "sanei_magic_getTransX: unsupported format/depth\n")
    free(buff)
    return NULL
  }

  /* ignore transitions with few neighbors within .5 inch */
  for(i=0;i<height-7;i++){
    Int sum = 0
    for(j=1;j<=7;j++){
      if(abs(buff[i+j] - buff[i]) < dpi/2)
        sum++
    }
    if(sum < 2)
      buff[i] = lastCol
  }

  DBG(10, "sanei_magic_getTransX: finish\n")

  return buff
}