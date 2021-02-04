#ifndef SANE_DS_CALLBACK_H
#define SANE_DS_CALLBACK_H

#include <sane/sane.h>

class SaneDevice;

void SaneCallbackDevice (SaneDevice * sanedevice);
UInt32 SaneCallbackResult ();

void SaneAuthCallback (SANE_String_Const resource,
                       SANE_Char username [SANE_MAX_USERNAME_LEN],
                       SANE_Char password [SANE_MAX_PASSWORD_LEN]);

#endif
