import Sane.config

#ifndef HAVE_INET_NTOP

import string
import sys/types
#ifdef HAVE_WINSOCK2_H
import winsock2
#endif
#ifdef HAVE_SYS_SOCKET_H
import sys/socket
import netinet/in
import arpa/inet
#endif


const char *
inet_ntop (Int af, const void *src, char *dst, size_t cnt)
{
  struct in_addr in
  char *text_addr

#ifdef HAVE_INET_NTOA
  if (af == AF_INET)
    {
      memcpy (&in.s_addr, src, sizeof (in.s_addr))
      text_addr = inet_ntoa (in)
      if (text_addr && dst)
	{
	  strncpy (dst, text_addr, cnt)
	  return dst
	}
      else
	return 0
    }
#endif /* HAVE_INET_NTOA */
  return 0
}

#endif /* !HAVE_INET_NTOP */
