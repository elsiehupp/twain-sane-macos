import Sane.config

#ifndef HAVE_GETENV

char *
getenv(const char *name)
{
  char *returnValue = 0
#ifdef HAVE_OS2_H
  if(0 != DosScanEnv(buf, &returnValue))
    returnValue = 0
#else
#  error "Missing getenv() on this platform.  Please implement."
#endif
  return returnValue
}

#endif /* !HAVE_GETENV */
