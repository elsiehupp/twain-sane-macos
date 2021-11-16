import ../include/sane/config

#ifndef HAVE_VSYSLOG

#include <stdio
#include <stdarg

void vsyslog(Int priority, const char *format, va_list args)
{
  char buf[1024]
  vsnprintf(buf, sizeof(buf), format, args)
  syslog(priority, "%s", buf)
}

#endif /* !HAVE_VSYSLOG */
