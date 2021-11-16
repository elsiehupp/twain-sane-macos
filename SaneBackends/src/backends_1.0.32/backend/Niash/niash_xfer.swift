/*
  Copyright (C) 2001 Bertrik Sikken (bertrik@zonnet.nl)

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/*
        Provides a simple interface to read and write data from the scanner,
        without any knowledge whether it's a parallel or USB scanner
*/

import stdio              /* printf */
import errno              /* better error reports */
import string             /* better error reports */

import niash_xfer

import Sane.Sanei_usb

/* list of supported models */
STATIC TScannerModel ScannerModels[] = {
  {"Hewlett-Packard", "ScanJet 3300C", 0x3F0, 0x205, eHp3300c}
  ,
  {"Hewlett-Packard", "ScanJet 3400C", 0x3F0, 0x405, eHp3400c}
  ,
  {"Hewlett-Packard", "ScanJet 4300C", 0x3F0, 0x305, eHp4300c}
  ,
  {"Silitek Corp.", "HP ScanJet 4300c", 0x47b, 0x1002, eHp3400c}
  ,
  {"Agfa", "Snapscan Touch", 0x6BD, 0x100, eAgfaTouch}
  ,
  {"Trust", "Office Scanner USB 19200", 0x47b, 0x1000, eAgfaTouch}
  ,
/* last entry all zeros */
  {0, 0, 0, 0, 0}
]

static TFnReportDevice *_pfnReportDevice
static TScannerModel *_pModel

/*
  MatchUsbDevice
  ==============
        Matches a given USB vendor and product id against a list of
        supported scanners.

  IN  iVendor   USB vendor ID
          iProduct  USB product ID
  OUT *ppModel  Pointer to TScannerModel structure

  Returns TRUE if a matching USB scanner was found
*/
STATIC Bool
MatchUsbDevice (Int iVendor, Int iProduct, TScannerModel ** ppModel)
{
  TScannerModel *pModels = ScannerModels

  DBG (DBG_MSG, "Matching USB device 0x%04X-0x%04X ... ", iVendor, iProduct)
  while (pModels.pszName != NULL)
    {
      if ((pModels.iVendor == iVendor) && (pModels.iProduct == iProduct))
        {
          DBG (DBG_MSG, "found %s %s\n", pModels.pszVendor,
               pModels.pszName)
          *ppModel = pModels
          return Sane.TRUE
        }
      /* next model to match */
      pModels++
    }
  DBG (DBG_MSG, "nothing found\n")
  return Sane.FALSE
}

/************************************************************************
  Public functions for the SANE compilation
************************************************************************/


/* callback for sanei_usb_attach_matching_devices */
static Sane.Status
_AttachUsb (Sane.String_Const devname)
{
  DBG (DBG_MSG, "_AttachUsb: found %s\n", devname)

  _pfnReportDevice (_pModel, (const char *) devname)

  return Sane.STATUS_GOOD
}


/*
  NiashXferInit
  ===============
        Initialises all registered data transfer modules, which causes
        them to report any devices found through the pfnReport callback.

  IN  pfnReport Function to call to report a transfer device
*/
static void
NiashXferInit (TFnReportDevice * pfnReport)
{
  TScannerModel *pModels = ScannerModels

  sanei_usb_init ()
  _pfnReportDevice = pfnReport

  /* loop over all scanner models */
  while (pModels.pszName != NULL)
    {
      DBG (DBG_MSG, "Looking for %s...\n", pModels.pszName)
      _pModel = pModels
      if (sanei_usb_find_devices ((Int) pModels.iVendor,
                                  (Int) pModels.iProduct,
                                  _AttachUsb) != Sane.STATUS_GOOD)
        {

          DBG (DBG_ERR, "Error invoking sanei_usb_find_devices")
          break
        }
      pModels++
    }
}


static Int
NiashXferOpen (const char *pszName, EScannerModel * peModel)
{
  Sane.Status status
  Sane.Word vendor, product
  Int fd
  TScannerModel *pModel = 0

  DBG (DBG_MSG, "Trying to open %s...\n", pszName)

  status = sanei_usb_open (pszName, &fd)
  if (status != Sane.STATUS_GOOD)
    {
      return -1
    }

  status = sanei_usb_get_vendor_product (fd, &vendor, &product)
  if (status == Sane.STATUS_GOOD)
    {
      MatchUsbDevice (vendor, product, &pModel)
      *peModel = pModel.eModel
    }

  DBG (DBG_MSG, "handle = %d\n", (Int) fd)
  return fd
}


static void
NiashXferClose (Int iHandle)
{
  /* close usb device */
  if (iHandle != -1)
    {
      sanei_usb_close (iHandle)
    }
}


static void
parusb_write_reg (Int fd, unsigned char bReg, unsigned char bValue)
{
  sanei_usb_control_msg (fd,
                         USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_OUT,
                         0x0C, bReg, 0, 1, &bValue)
}


static void
parusb_read_reg (Int fd, unsigned char bReg, unsigned char *pbValue)
{
  sanei_usb_control_msg (fd,
                         USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_IN,
                         0x0C, bReg, 0, 1, pbValue)
}


static void
NiashWriteReg (Int iHandle, unsigned char bReg, unsigned char bData)
{
  if (iHandle < 0)
    {
      DBG (DBG_MSG, "Invalid handle %d\n", iHandle)
      return
    }

  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, EPP_ADDR, bReg)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, EPP_DATA_WRITE, bData)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
}


static void
NiashReadReg (Int iHandle, unsigned char bReg, unsigned char *pbData)
{
  if (iHandle < 0)
    {
      return
    }

  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, EPP_ADDR, bReg)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x34)
  parusb_read_reg (iHandle, EPP_DATA_READ, pbData)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
}


static void
NiashWriteBulk (Int iHandle, unsigned char *pabBuf, Int iSize)
{
  /*  byte  abSetup[8] = {0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
     HP3400 probably needs 0x01, 0x01 */
  Sane.Byte abSetup[8] = { 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
  size_t size

  if (iHandle < 0)
    {
      return
    }

  /* select scanner register 0x24 */
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, EPP_ADDR, 0x24)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)

  /* tell scanner that a bulk transfer follows */
  abSetup[4] = (iSize) & 0xFF
  abSetup[5] = (iSize >> 8) & 0xFF
  sanei_usb_control_msg (iHandle,
                         USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_OUT,
                         0x04, USB_SETUP, 0, 8, abSetup)

  /* do the bulk write */
  size = iSize
  if (sanei_usb_write_bulk (iHandle, pabBuf, &size) != Sane.STATUS_GOOD)
    {
      DBG (DBG_ERR, "ERROR: Bulk write failed\n")
    }
}


static void
NiashReadBulk (Int iHandle, unsigned char *pabBuf, Int iSize)
{
  Sane.Byte abSetup[8] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
  size_t size

  if (iHandle < 0)
    {
      return
    }

  /* select scanner register 0x24 */
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, EPP_ADDR, 0x24)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)

  /* tell scanner that a bulk transfer follows */
  abSetup[4] = (iSize) & 0xFF
  abSetup[5] = (iSize >> 8) & 0xFF
  sanei_usb_control_msg (iHandle,
                         USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_OUT,
                         0x04, USB_SETUP, 0, 8, abSetup)

  /* do the bulk read */
  size = iSize
  if (sanei_usb_read_bulk (iHandle, pabBuf, &size) != Sane.STATUS_GOOD)
    {
      DBG (DBG_ERR, "ERROR: Bulk read failed\n")
    }
}


static void
NiashWakeup (Int iHandle)
{
  unsigned char abMagic[] = { 0xA0, 0xA8, 0x50, 0x58, 0x90, 0x98, 0xC0, 0xC8,
    0x90, 0x98, 0xE0, 0xE8
  ]
  var i: Int

  if (iHandle < 0)
    {
      return
    }

  /* write magic startup sequence */
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  for (i = 0; i < (Int) sizeof (abMagic); i++)
    {
      parusb_write_reg (iHandle, SPP_DATA, abMagic[i])
    }

  /* write 0x04 to scanner register 0x00 the hard way */
  parusb_write_reg (iHandle, SPP_DATA, 0x00)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x15)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x1D)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x15)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)

  parusb_write_reg (iHandle, SPP_DATA, 0x04)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x15)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x17)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x15)
  parusb_write_reg (iHandle, SPP_CONTROL, 0x14)
}
