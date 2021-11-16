import Sane.config

#ifndef HAVE_SYSLOG

import stdio

void syslog(Int priority, const char *format, va_list args)
{
    printf("%d ", priority)
    printf(format, args)
}

#endif
