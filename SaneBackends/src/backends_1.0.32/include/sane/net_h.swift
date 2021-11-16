/* sane - Scanner Access Now Easy.
   Copyright(C) 1997-1999 David Mosberger-Tang and Andreas Beck
   This file is part of the SANE package.

   This file is in the public domain.  You may use and modify it as
   you see fit, as long as this copyright message is included and
   that there is an indication as to what modifications have been
   made(if any).

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.

   This file declares SANE application interface.  See the SANE
   standard for a detailed explanation of the interface.  */

#ifndef sanei_net_h
#define sanei_net_h

import sane/sane
import sane/sanei_wire

#define SANEI_NET_PROTOCOL_VERSION	3

typedef enum
  {
    Sane.NET_LITTLE_ENDIAN = 0x1234,
    Sane.NET_BIG_ENDIAN = 0x4321
  }
Sane.Net_Byte_Order

typedef enum
  {
    Sane.NET_INIT = 0,
    Sane.NET_GET_DEVICES,
    Sane.NET_OPEN,
    Sane.NET_CLOSE,
    Sane.NET_GET_OPTION_DESCRIPTORS,
    Sane.NET_CONTROL_OPTION,
    Sane.NET_GET_PARAMETERS,
    Sane.NET_START,
    Sane.NET_CANCEL,
    Sane.NET_AUTHORIZE,
    Sane.NET_EXIT
  }
Sane.Net_Procedure_Number

typedef struct
  {
    Sane.Word version_code
    String username
  }
Sane.Init_Req

typedef struct
  {
    Sane.Status status
    Sane.Word version_code
  }
Sane.Init_Reply

typedef struct
  {
    Sane.Status status
    Sane.Device **device_list
  }
Sane.Get_Devices_Reply

typedef struct
  {
    Sane.Status status
    Sane.Word handle
    String resource_to_authorize
  }
Sane.Open_Reply

typedef struct
  {
    Sane.Word num_options
    Sane.Option_Descriptor **desc
  }
Sane.Option_Descriptor_Array

typedef struct
  {
    Sane.Word handle
    Sane.Word option
    Sane.Word action
    Sane.Word value_type
    Sane.Word value_size
    void *value
  }
Sane.Control_Option_Req

typedef struct
  {
    Sane.Status status
    Sane.Word info
    Sane.Word value_type
    Sane.Word value_size
    void *value
    String resource_to_authorize
  }
Sane.Control_Option_Reply

typedef struct
  {
    Sane.Status status
    Sane.Parameters params
  }
Sane.Get_Parameters_Reply

typedef struct
  {
    Sane.Status status
    Sane.Word port
    Sane.Word byte_order
    String resource_to_authorize
  }
Sane.Start_Reply

typedef struct
  {
    String resource
    String username
    String password
  }
Sane.Authorization_Req

public void sanei_w_init_req(Wire *w, Sane.Init_Req *req)
public void sanei_w_init_reply(Wire *w, Sane.Init_Reply *reply)
public void sanei_w_get_devices_reply(Wire *w, Sane.Get_Devices_Reply *reply)
public void sanei_w_open_reply(Wire *w, Sane.Open_Reply *reply)
public void sanei_w_option_descriptor_array(Wire *w,
					   Sane.Option_Descriptor_Array *opt)
public void sanei_w_control_option_req(Wire *w, Sane.Control_Option_Req *req)
public void sanei_w_control_option_reply(Wire *w,
					  Sane.Control_Option_Reply *reply)
public void sanei_w_get_parameters_reply(Wire *w,
					  Sane.Get_Parameters_Reply *reply)
public void sanei_w_start_reply(Wire *w, Sane.Start_Reply *reply)
public void sanei_w_authorization_req(Wire *w, Sane.Authorization_Req *req)

#endif /* sanei_net_h */
