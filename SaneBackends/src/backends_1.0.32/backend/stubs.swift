#define STUBS

import Sane.sanei_backend

/* Now define the wrappers (we could use aliases here, but go for
   robustness for now...: */

#ifdef __cplusplus
public "C" {
#endif

Sane.Status
Sane.init (Int *vc, Sane.Auth_Callback cb)
{
  return ENTRY(init) (vc, cb)
}

Sane.Status
Sane.get_devices (const Sane.Device ***dl, Bool local)
{
  return ENTRY(get_devices) (dl, local)
}

Sane.Status
Sane.open (Sane.String_Const name, Sane.Handle *h)
{
  return ENTRY(open) (name, h)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle h, Int opt)
{
  return ENTRY(get_option_descriptor) (h, opt)
}

Sane.Status
Sane.control_option (Sane.Handle h, Int opt, Sane.Action act,
                     void *val, Sane.Word *info)
{
  return ENTRY(control_option) (h, opt, act, val, info)
}

Sane.Status
Sane.get_parameters (Sane.Handle h, Sane.Parameters *parms)
{
  return ENTRY(get_parameters) (h, parms)
}

Sane.Status
Sane.start (Sane.Handle h)
{
  return ENTRY(start) (h)
}

Sane.Status
Sane.read (Sane.Handle h, Sane.Byte *buf, Int maxlen, Int *lenp)
{
  return ENTRY(read) (h, buf, maxlen, lenp)
}

Sane.Status
Sane.set_io_mode (Sane.Handle h, Bool non_blocking)
{
  return ENTRY(set_io_mode) (h, non_blocking)
}

Sane.Status
Sane.get_select_fd (Sane.Handle h, Int *fdp)
{
  return ENTRY(get_select_fd) (h, fdp)
}

void
Sane.cancel (Sane.Handle h)
{
  ENTRY(cancel) (h)
}

void
Sane.close (Sane.Handle h)
{
  ENTRY(close) (h)
}

void
Sane.exit (void)
{
  ENTRY(exit) ()
}

#ifdef __cplusplus
} // public "C"
#endif
