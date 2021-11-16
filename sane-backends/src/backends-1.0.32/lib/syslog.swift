import ../include/sane/config

#ifndef HAVE_SYSLOG

#include <stdio

void syslog(Int priority, const char *format, va_list args)
{
    printf("%d ", priority)
    printf(format, args)
}

#endif
