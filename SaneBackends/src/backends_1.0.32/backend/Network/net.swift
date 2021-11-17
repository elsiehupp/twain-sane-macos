/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 David Mosberger-Tang
   Copyright(C) 2003, 2008 Julien BLACHE <jb@jblache.org>
      AF-independent code + IPv6, Avahi support

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

   This file implements a SANE network-based meta backend.  */

#ifdef _AIX
import ../include/lalloca /* MUST come first for AIX! */
#endif

import Sane.config
import ../include/lalloca
import ../include/_stdint

import errno
import fcntl
import limits
import stdlib
import string
import unistd
#ifdef HAVE_LIBC_H
import libc /* NeXTStep/OpenStep */
#endif

import sys/time
import sys/types

import netinet/in
import netdb /* OS/2 needs this _after_ <netinet/in, grrr... */

#if WITH_AVAHI
import avahi-client/client
import avahi-client/lookup

import avahi-common/thread-watch
import avahi-common/malloc
import avahi-common/error

# define SANED_SERVICE_DNS "_sane-port._tcp"

static AvahiClient *avahi_client = NULL
static AvahiThreadedPoll *avahi_thread = NULL
static AvahiServiceBrowser *avahi_browser = NULL
#endif /* WITH_AVAHI */

import Sane.sane
import Sane.sanei
import Sane.sanei_net
import Sane.sanei_codec_bin
import net

#define BACKEND_NAME    net
import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX       1024
#endif

import Sane.sanei_config
#define NET_CONFIG_FILE "net.conf"

/* Please increase version number with every change
   (don"t forget to update net.desc) */

/* define the version string depending on which network code is used */
#if defined(HAVE_GETADDRINFO) && defined(HAVE_GETNAMEINFO)
# define NET_USES_AF_INDEP
# ifdef ENABLE_IPV6
#  define NET_VERSION "1.0.14 (AF-indep+IPv6)"
# else
#  define NET_VERSION "1.0.14 (AF-indep)"
# endif /* ENABLE_IPV6 */
#else
# undef ENABLE_IPV6
# define NET_VERSION "1.0.14"
#endif /* HAVE_GETADDRINFO && HAVE_GETNAMEINFO */

static Sane.Auth_Callback auth_callback
static Net_Device *first_device
static Net_Scanner *first_handle
static const Sane.Device **devlist
static Int client_big_endian; /* 1 == big endian; 0 == little endian */
static Int server_big_endian; /* 1 == big endian; 0 == little endian */
static Int depth; /* bits per pixel */
static Int connect_timeout = -1; /* timeout for connection to saned */

#ifndef NET_USES_AF_INDEP
static Int saned_port
#endif /* !NET_USES_AF_INDEP */

/* This variable is only needed, if the depth is 16bit/channel and
   client/server have different endianness.  A value of -1 means, that there"s
   no hang over; otherwise the value has to be casted to Sane.Byte.  hang_over
   means, that there is a remaining byte from a previous call to Sane.read,
   which could not be byte-swapped, e.g. because the frontend requested an odd
   number of bytes.
*/
static Int hang_over

/* This variable is only needed, if the depth is 16bit/channel and
   client/server have different endianness.  A value of -1 means, that there"s
   no left over; otherwise the value has to be casted to Sane.Byte.  left_over
   means, that there is a remaining byte from a previous call to Sane.read,
   which already is in the correct byte order, but could not be returned,
   e.g.  because the frontend requested only one byte per call.
*/
static Int left_over


#ifdef NET_USES_AF_INDEP
static Sane.Status
add_device(const char *name, Net_Device ** ndp)
{
  struct addrinfo hints
  struct addrinfo *res
  struct addrinfo *resp
  struct sockaddr_in *sin
#ifdef ENABLE_IPV6
  struct sockaddr_in6 *sin6
#endif /* ENABLE_IPV6 */

  Net_Device *nd = NULL

  Int error
  short Sane.port = htons(6566)

  DBG(1, "add_device: adding backend %s\n", name)

  for(nd = first_device; nd; nd = nd.next)
    if(strcmp(nd.name, name) == 0)
      {
	DBG(1, "add_device: already in list\n")

	if(ndp)
	  *ndp = nd

	return Sane.STATUS_GOOD
      }

  memset(&hints, 0, sizeof(hints))

# ifdef ENABLE_IPV6
  hints.ai_family = PF_UNSPEC
# else
  hints.ai_family = PF_INET
# endif /* ENABLE_IPV6 */

  error = getaddrinfo(name, "sane-port", &hints, &res)
  if(error)
    {
      error = getaddrinfo(name, NULL, &hints, &res)
      if(error)
	{
	  DBG(1, "add_device: error while getting address of host %s: %s\n",
	       name, gai_strerror(error))

	  return Sane.STATUS_IO_ERROR
	}
      else
	{
          for(resp = res; resp != NULL; resp = resp.ai_next)
            {
              switch(resp.ai_family)
                {
                  case AF_INET:
                    sin = (struct sockaddr_in *) resp.ai_addr
                    sin.sin_port = Sane.port
                    break
#ifdef ENABLE_IPV6
		  case AF_INET6:
		    sin6 = (struct sockaddr_in6 *) resp.ai_addr
		    sin6->sin6_port = Sane.port
		    break
#endif /* ENABLE_IPV6 */
                }
	    }
	}
    }

  nd = malloc(sizeof(Net_Device))
  if(!nd)
    {
      DBG(1, "add_device: not enough memory for Net_Device struct\n")

      freeaddrinfo(res)
      return Sane.STATUS_NO_MEM
    }

  memset(nd, 0, sizeof(Net_Device))
  nd.name = strdup(name)
  if(!nd.name)
    {
      DBG(1, "add_device: not enough memory to duplicate name\n")
      free(nd)
      return Sane.STATUS_NO_MEM
    }

  nd.addr = res
  nd.ctl = -1

  nd.next = first_device

  first_device = nd

  if(ndp)
    *ndp = nd
  DBG(2, "add_device: backend %s added\n", name)
  return Sane.STATUS_GOOD
}

#else /* !NET_USES_AF_INDEP */

static Sane.Status
add_device(const char *name, Net_Device ** ndp)
{
  struct hostent *he
  Net_Device *nd
  struct sockaddr_in *sin

  DBG(1, "add_device: adding backend %s\n", name)

  for(nd = first_device; nd; nd = nd.next)
    if(strcmp(nd.name, name) == 0)
      {
	DBG(1, "add_device: already in list\n")

	if(ndp)
	  *ndp = nd

	return Sane.STATUS_GOOD
      }

  he = gethostbyname(name)
  if(!he)
    {
      DBG(1, "add_device: can"t get address of host %s\n", name)
      return Sane.STATUS_IO_ERROR
    }

  if(he.h_addrtype != AF_INET)
    {
      DBG(1, "add_device: don"t know how to deal with addr family %d\n",
	   he.h_addrtype)
      return Sane.STATUS_INVAL
    }

  nd = malloc(sizeof(*nd))
  if(!nd)
    {
      DBG(1, "add_device: not enough memory for Net_Device struct\n")
      return Sane.STATUS_NO_MEM
    }

  memset(nd, 0, sizeof(*nd))
  nd.name = strdup(name)
  if(!nd.name)
    {
      DBG(1, "add_device: not enough memory to duplicate name\n")
      free(nd)
      return Sane.STATUS_NO_MEM
    }
  nd.addr.sa_family = he.h_addrtype

  sin = (struct sockaddr_in *) &nd.addr
  memcpy(&sin.sin_addr, he.h_addr_list[0], he.h_length)

  nd.ctl = -1
  nd.next = first_device
  first_device = nd
  if(ndp)
    *ndp = nd
  DBG(2, "add_device: backend %s added\n", name)
  return Sane.STATUS_GOOD
}
#endif /* NET_USES_AF_INDEP */


#ifdef NET_USES_AF_INDEP
static Sane.Status
connect_dev(Net_Device * dev)
{
  struct addrinfo *addrp

  Sane.Word version_code
  Sane.Init_Reply reply
  Sane.Status status = Sane.STATUS_IO_ERROR
  Sane.Init_Req req
  Bool connected = Sane.FALSE
#ifdef TCP_NODELAY
  Int on = 1
  Int level = -1
#endif
  struct timeval tv

  var i: Int

  DBG(2, "connect_dev: trying to connect to %s\n", dev.name)

  for(addrp = dev.addr, i = 0; (addrp != NULL) && (connected == Sane.FALSE); addrp = addrp.ai_next, i++)
    {
# ifdef ENABLE_IPV6
      if((addrp.ai_family != AF_INET) && (addrp.ai_family != AF_INET6))
# else /* !ENABLE_IPV6 */
      if(addrp.ai_family != AF_INET)
# endif /* ENABLE_IPV6 */
	{
	  DBG(1, "connect_dev: [%d] don"t know how to deal with addr family %d\n",
	       i, addrp.ai_family)
	  continue
	}

      dev.ctl = socket(addrp.ai_family, SOCK_STREAM, 0)
      if(dev.ctl < 0)
	{
	  DBG(1, "connect_dev: [%d] failed to obtain socket(%s)\n",
	       i, strerror(errno))
	  dev.ctl = -1
	  continue
	}

      /* Set SO_SNDTIMEO for the connection to saned */
      if(connect_timeout > 0)
	{
	  tv.tv_sec = connect_timeout
	  tv.tv_usec = 0

	  if(setsockopt(dev.ctl, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv)) < 0)
	    {
	      DBG(1, "connect_dev: [%d] failed to set SO_SNDTIMEO(%s)\n", i, strerror(errno))
	    }
	}

      if(connect(dev.ctl, addrp.ai_addr, addrp.ai_addrlen) < 0)
	{
	  DBG(1, "connect_dev: [%d] failed to connect(%s)\n", i, strerror(errno))
	  dev.ctl = -1
	  continue
	}
      DBG(3, "connect_dev: [%d] connection succeeded(%s)\n", i, (addrp.ai_family == AF_INET6) ? "IPv6" : "IPv4")
      dev.addr_used = addrp
      connected = Sane.TRUE
    }

  if(connected != Sane.TRUE)
    {
      DBG(1, "connect_dev: couldn"t connect to host(see messages above)\n")
      return Sane.STATUS_IO_ERROR
    }

#else /* !NET_USES_AF_INDEP */

static Sane.Status
connect_dev(Net_Device * dev)
{
  struct sockaddr_in *sin
  Sane.Word version_code
  Sane.Init_Reply reply
  Sane.Status status = Sane.STATUS_IO_ERROR
  Sane.Init_Req req
#ifdef TCP_NODELAY
  Int on = 1
  Int level = -1
#endif
  struct timeval tv

  DBG(2, "connect_dev: trying to connect to %s\n", dev.name)

  if(dev.addr.sa_family != AF_INET)
    {
      DBG(1, "connect_dev: don"t know how to deal with addr family %d\n",
	   dev.addr.sa_family)
      return Sane.STATUS_IO_ERROR
    }

  dev.ctl = socket(dev.addr.sa_family, SOCK_STREAM, 0)
  if(dev.ctl < 0)
    {
      DBG(1, "connect_dev: failed to obtain socket(%s)\n",
	   strerror(errno))
      dev.ctl = -1
      return Sane.STATUS_IO_ERROR
    }
  sin = (struct sockaddr_in *) &dev.addr
  sin.sin_port = saned_port


  /* Set SO_SNDTIMEO for the connection to saned */
  if(connect_timeout > 0)
    {
      tv.tv_sec = connect_timeout
      tv.tv_usec = 0

      if(setsockopt(dev.ctl, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv)) < 0)
	{
	  DBG(1, "connect_dev: failed to set SO_SNDTIMEO(%s)\n", strerror(errno))
	}
    }

  if(connect(dev.ctl, &dev.addr, sizeof(dev.addr)) < 0)
    {
      DBG(1, "connect_dev: failed to connect(%s)\n", strerror(errno))
      dev.ctl = -1
      return Sane.STATUS_IO_ERROR
    }
  DBG(3, "connect_dev: connection succeeded\n")
#endif /* NET_USES_AF_INDEP */

  /* We"re connected now, so reset SO_SNDTIMEO to the default value of 0 */
  if(connect_timeout > 0)
    {
      tv.tv_sec = 0
      tv.tv_usec = 0

      if(setsockopt(dev.ctl, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv)) < 0)
	{
	  DBG(1, "connect_dev: failed to reset SO_SNDTIMEO(%s)\n", strerror(errno))
	}
    }

#ifdef TCP_NODELAY
# ifdef SOL_TCP
  level = SOL_TCP
# else /* !SOL_TCP */
  /* Look up the protocol level in the protocols database. */
  {
    struct protoent *p
    p = getprotobyname("tcp")
    if(p == 0)
      DBG(1, "connect_dev: cannot look up `tcp" protocol number")
    else
      level = p.p_proto
  }
# endif	/* SOL_TCP */

  if(level == -1 ||
      setsockopt(dev.ctl, level, TCP_NODELAY, &on, sizeof(on)))
    DBG(1, "connect_dev: failed to put send socket in TCP_NODELAY mode(%s)",
	 strerror(errno))
#endif /* !TCP_NODELAY */

  DBG(2, "connect_dev: sanei_w_init\n")
  sanei_w_init(&dev.wire, sanei_codec_bin_init)
  dev.wire.io.fd = dev.ctl
  dev.wire.io.read = read
  dev.wire.io.write = write

  /* exchange version codes with the server: */
  req.version_code = Sane.VERSION_CODE(V_MAJOR, V_MINOR,
					SANEI_NET_PROTOCOL_VERSION)
  req.username = getlogin()
  DBG(2, "connect_dev: net_init(user=%s, local version=%d.%d.%d)\n",
       req.username, V_MAJOR, V_MINOR, SANEI_NET_PROTOCOL_VERSION)
  sanei_w_call(&dev.wire, Sane.NET_INIT,
		(WireCodecFunc) sanei_w_init_req, &req,
		(WireCodecFunc) sanei_w_init_reply, &reply)

  if(dev.wire.status != 0)
    {
      DBG(1, "connect_dev: argument marshalling error(%s)\n",
	   strerror(dev.wire.status))
      status = Sane.STATUS_IO_ERROR
      goto fail
    }

  status = reply.status
  version_code = reply.version_code
  DBG(2, "connect_dev: freeing init reply(status=%s, remote "
       "version=%d.%d.%d)\n", Sane.strstatus(status),
       Sane.VERSION_MAJOR(version_code),
       Sane.VERSION_MINOR(version_code), Sane.VERSION_BUILD(version_code))
  sanei_w_free(&dev.wire, (WireCodecFunc) sanei_w_init_reply, &reply)

  if(status != 0)
    {
      DBG(1, "connect_dev: access to %s denied\n", dev.name)
      goto fail
    }
  if(Sane.VERSION_MAJOR(version_code) != V_MAJOR)
    {
      DBG(1, "connect_dev: major version mismatch: got %d, expected %d\n",
	   Sane.VERSION_MAJOR(version_code), V_MAJOR)
      status = Sane.STATUS_IO_ERROR
      goto fail
    }
  if(Sane.VERSION_BUILD(version_code) != SANEI_NET_PROTOCOL_VERSION
      && Sane.VERSION_BUILD(version_code) != 2)
    {
      DBG(1, "connect_dev: network protocol version mismatch: "
	   "got %d, expected %d\n",
	   Sane.VERSION_BUILD(version_code), SANEI_NET_PROTOCOL_VERSION)
      status = Sane.STATUS_IO_ERROR
      goto fail
    }
  dev.wire.version = Sane.VERSION_BUILD(version_code)
  DBG(4, "connect_dev: done\n")
  return Sane.STATUS_GOOD

fail:
  DBG(2, "connect_dev: closing connection to %s\n", dev.name)
  close(dev.ctl)
  dev.ctl = -1
  return status
}


static Sane.Status
fetch_options(Net_Scanner * s)
{
  Int option_number
  DBG(3, "fetch_options: %p\n", (void *) s)

  if(s.opt.num_options)
    {
      DBG(2, "fetch_options: %d option descriptors cached... freeing\n",
	   s.opt.num_options)
      sanei_w_set_dir(&s.hw.wire, WIRE_FREE)
      s.hw.wire.status = 0
      sanei_w_option_descriptor_array(&s.hw.wire, &s.opt)
      if(s.hw.wire.status)
	{
	  DBG(1, "fetch_options: failed to free old list(%s)\n",
	       strerror(s.hw.wire.status))
	  return Sane.STATUS_IO_ERROR
	}
    }
  DBG(3, "fetch_options: get_option_descriptors\n")
  sanei_w_call(&s.hw.wire, Sane.NET_GET_OPTION_DESCRIPTORS,
		(WireCodecFunc) sanei_w_word, &s.handle,
		(WireCodecFunc) sanei_w_option_descriptor_array, &s.opt)
  if(s.hw.wire.status)
    {
      DBG(1, "fetch_options: failed to get option descriptors(%s)\n",
	   strerror(s.hw.wire.status))
      return Sane.STATUS_IO_ERROR
    }

  if(s.local_opt.num_options == 0)
    {
      DBG(3, "fetch_options: creating %d local option descriptors\n",
	   s.opt.num_options)
      s.local_opt.desc =
	malloc(s.opt.num_options * sizeof(s.local_opt.desc))
      if(!s.local_opt.desc)
	{
	  DBG(1, "fetch_options: couldn"t malloc s.local_opt.desc\n")
	  return Sane.STATUS_NO_MEM
	}
      for(option_number = 0
	   option_number < s.opt.num_options
	   option_number++)
	{
	  s.local_opt.desc[option_number] =
	    malloc(sizeof(Sane.Option_Descriptor))
	  if(!s.local_opt.desc[option_number])
	    {
	      DBG(1, "fetch_options: couldn"t malloc "
		   "s.local_opt.desc[%d]\n", option_number)
	      return Sane.STATUS_NO_MEM
	    }
	}
      s.local_opt.num_options = s.opt.num_options
    }
  else if(s.local_opt.num_options != s.opt.num_options)
    {
      DBG(1, "fetch_options: option number count changed during runtime?\n")
      return Sane.STATUS_INVAL
    }

  DBG(3, "fetch_options: copying %d option descriptors\n",
       s.opt.num_options)

  for(option_number = 0; option_number < s.opt.num_options; option_number++)
    {
      memcpy(s.local_opt.desc[option_number], s.opt.desc[option_number],
	      sizeof(Sane.Option_Descriptor))
    }

  s.options_valid = 1
  DBG(3, "fetch_options: %d options fetched\n", s.opt.num_options)
  return Sane.STATUS_GOOD
}

static Sane.Status
do_cancel(Net_Scanner * s)
{
  DBG(2, "do_cancel: %p\n", (void *) s)
  s.hw.auth_active = 0
  if(s.data >= 0)
    {
      DBG(3, "do_cancel: closing data pipe\n")
      close(s.data)
      s.data = -1
    }
  return Sane.STATUS_CANCELLED
}

static void
do_authorization(Net_Device * dev, String resource)
{
  Sane.Authorization_Req req
  Sane.Char username[Sane.MAX_USERNAME_LEN]
  Sane.Char password[Sane.MAX_PASSWORD_LEN]
  char *net_resource

  DBG(2, "do_authorization: dev=%p resource=%s\n", (void *) dev, resource)

  dev.auth_active = 1

  memset(&req, 0, sizeof(req))
  memset(username, 0, sizeof(Sane.Char) * Sane.MAX_USERNAME_LEN)
  memset(password, 0, sizeof(Sane.Char) * Sane.MAX_PASSWORD_LEN)

  net_resource = malloc(strlen(resource) + 6 + strlen(dev.name))

  if(net_resource != NULL)
    {
      sprintf(net_resource, "net:%s:%s", dev.name, resource)
      if(auth_callback)
	{
	  DBG(2, "do_authorization: invoking auth_callback, resource = %s\n",
	       net_resource)
	  (*auth_callback) (net_resource, username, password)
	}
      else
	DBG(1, "do_authorization: no auth_callback present\n")
      free(net_resource)
    }
  else /* Is this necessary? If we don"t have these few bytes we will get
	  in trouble later anyway */
    {
      DBG(1, "do_authorization: not enough memory for net_resource\n")
      if(auth_callback)
	{
	  DBG(2, "do_authorization: invoking auth_callback, resource = %s\n",
	       resource)
	  (*auth_callback) (resource, username, password)
	}
      else
	DBG(1, "do_authorization: no auth_callback present\n")
    }

  if(dev.auth_active)
    {
      Sane.Word ack

      req.resource = resource
      req.username = username
      req.password = password
      DBG(2, "do_authorization: relaying authentication data\n")
      sanei_w_call(&dev.wire, Sane.NET_AUTHORIZE,
		    (WireCodecFunc) sanei_w_authorization_req, &req,
		    (WireCodecFunc) sanei_w_word, &ack)
    }
  else
    DBG(1, "do_authorization: auth_active is false... strange\n")
}


#if WITH_AVAHI
static void
net_avahi_resolve_callback(AvahiServiceResolver *r, AvahiIfIndex interface, AvahiProtocol protocol,
			    AvahiResolverEvent event, const char *name, const char *type,
			    const char *domain, const char *host_name, const AvahiAddress *address,
			    uint16_t port, AvahiStringList *txt, AvahiLookupResultFlags flags,
			    void *userdata)
{
  char a[AVAHI_ADDRESS_STR_MAX]
  char *t

  /* unused */
  interface = interface
  protocol = protocol
  userdata = userdata

  if(!r)
    return

  switch(event)
    {
      case AVAHI_RESOLVER_FAILURE:
	DBG(1, "net_avahi_resolve_callback: failed to resolve service "%s" of type "%s" in domain "%s": %s\n",
	     name, type, domain, avahi_strerror(avahi_client_errno(avahi_service_resolver_get_client(r))))
	break

      case AVAHI_RESOLVER_FOUND:
	DBG(3, "net_avahi_resolve_callback: service "%s" of type "%s" in domain "%s":\n", name, type, domain)

	avahi_address_snprint(a, sizeof(a), address)
	t = avahi_string_list_to_string(txt)

	DBG(3, "\t%s:%u(%s)\n\tTXT=%s\n\tcookie is %u\n\tis_local: %i\n\tour_own: %i\n"
	     "\twide_area: %i\n\tmulticast: %i\n\tcached: %i\n",
	     host_name, port, a, t, avahi_string_list_get_service_cookie(txt),
	     !!(flags & AVAHI_LOOKUP_RESULT_LOCAL), !!(flags & AVAHI_LOOKUP_RESULT_OUR_OWN),
	     !!(flags & AVAHI_LOOKUP_RESULT_WIDE_AREA), !!(flags & AVAHI_LOOKUP_RESULT_MULTICAST),
	     !!(flags & AVAHI_LOOKUP_RESULT_CACHED))

	/* TODO: evaluate TXT record */

	/* Try first with the name */
	if(add_device(host_name, NULL) != Sane.STATUS_GOOD)
	  {
	    DBG(1, "net_avahi_resolve_callback: couldn"t add backend with name %s\n", host_name)

	    /* Then try the raw IP address */
	    if(add_device(t, NULL) != Sane.STATUS_GOOD)
	      DBG(1, "net_avahi_resolve_callback: couldn"t add backend with IP address %s either\n", t)
	  }

	avahi_free(t)
	break
    }

  avahi_service_resolver_free(r)
}

static void
net_avahi_browse_callback(AvahiServiceBrowser *b, AvahiIfIndex interface, AvahiProtocol protocol,
			   AvahiBrowserEvent event, const char *name, const char *type,
			   const char *domain, AvahiLookupResultFlags flags, void *userdata)
{
  AvahiProtocol proto

  /* unused */
  flags = flags
  userdata = userdata

  if(!b)
    return

  switch(event)
    {
      case AVAHI_BROWSER_FAILURE:
	DBG(1, "net_avahi_browse_callback: %s\n", avahi_strerror(avahi_client_errno(avahi_service_browser_get_client(b))))
	avahi_threaded_poll_quit(avahi_thread)
	return

      case AVAHI_BROWSER_NEW:
	DBG(3, "net_avahi_browse_callback: NEW: service "%s" of type "%s" in domain "%s"\n", name, type, domain)

	/* The server will actually be added to our list in the resolver callback */

	/* The resolver object will be freed in the resolver callback, or by
	 * the server if it terminates before the callback is called.
	 */
#ifdef ENABLE_IPV6
	proto = AVAHI_PROTO_UNSPEC
#else
	proto = AVAHI_PROTO_INET
#endif /* ENABLE_IPV6 */
	if(!(avahi_service_resolver_new(avahi_client, interface, protocol, name, type, domain, proto, 0, net_avahi_resolve_callback, NULL)))
	  DBG(2, "net_avahi_browse_callback: failed to resolve service "%s": %s\n", name, avahi_strerror(avahi_client_errno(avahi_client)))
	break

      case AVAHI_BROWSER_REMOVE:
	DBG(3, "net_avahi_browse_callback: REMOVE: service "%s" of type "%s" in domain "%s"\n", name, type, domain)
	/* With the current architecture, we cannot safely remove a server from the list */
	break

      case AVAHI_BROWSER_ALL_FOR_NOW:
      case AVAHI_BROWSER_CACHE_EXHAUSTED:
	DBG(3, "net_avahi_browse_callback: %s\n", event == AVAHI_BROWSER_CACHE_EXHAUSTED ? "CACHE_EXHAUSTED" : "ALL_FOR_NOW")
	break
    }
}

static void
net_avahi_callback(AvahiClient *c, AvahiClientState state, void * userdata)
{
  AvahiProtocol proto
  Int error

  /* unused */
  userdata = userdata

  if(!c)
    return

  switch(state)
    {
      case AVAHI_CLIENT_CONNECTING:
	break

      case AVAHI_CLIENT_S_COLLISION:
      case AVAHI_CLIENT_S_REGISTERING:
      case AVAHI_CLIENT_S_RUNNING:
	if(avahi_browser)
	  return

#ifdef ENABLE_IPV6
	proto = AVAHI_PROTO_UNSPEC
#else
	proto = AVAHI_PROTO_INET
#endif /* ENABLE_IPV6 */

	avahi_browser = avahi_service_browser_new(c, AVAHI_IF_UNSPEC, proto, SANED_SERVICE_DNS, NULL, 0, net_avahi_browse_callback, NULL)
	if(avahi_browser == NULL)
	  {
	    DBG(1, "net_avahi_callback: could not create service browser: %s\n", avahi_strerror(avahi_client_errno(c)))
	    avahi_threaded_poll_quit(avahi_thread)
	  }
	break

      case AVAHI_CLIENT_FAILURE:
	error = avahi_client_errno(c)

	if(error == AVAHI_ERR_DISCONNECTED)
	  {
	    /* Server disappeared - try to reconnect */
	    if(avahi_browser)
	      {
		avahi_service_browser_free(avahi_browser)
		avahi_browser = NULL
	      }

	    avahi_client_free(avahi_client)
	    avahi_client = NULL

	    avahi_client = avahi_client_new(avahi_threaded_poll_get(avahi_thread), AVAHI_CLIENT_NO_FAIL, net_avahi_callback, NULL, &error)
	    if(avahi_client == NULL)
	      {
		DBG(1, "net_avahi_init: could not create Avahi client: %s\n", avahi_strerror(error))
		avahi_threaded_poll_quit(avahi_thread)
	      }
	  }
	else
	  {
	    /* Another error happened - game over */
	    DBG(1, "net_avahi_callback: server connection failure: %s\n", avahi_strerror(error))
	    avahi_threaded_poll_quit(avahi_thread)
	  }
	break
    }
}


static void
net_avahi_init(void)
{
  Int error

  avahi_thread = avahi_threaded_poll_new()
  if(avahi_thread == NULL)
    {
      DBG(1, "net_avahi_init: could not create threaded poll object\n")
      goto fail
    }

  avahi_client = avahi_client_new(avahi_threaded_poll_get(avahi_thread), AVAHI_CLIENT_NO_FAIL, net_avahi_callback, NULL, &error)
  if(avahi_client == NULL)
    {
      DBG(1, "net_avahi_init: could not create Avahi client: %s\n", avahi_strerror(error))
      goto fail
    }

  if(avahi_threaded_poll_start(avahi_thread) < 0)
    {
      DBG(1, "net_avahi_init: Avahi thread failed to start\n")
      goto fail
    }

  /* All done */
  return

 fail:
  DBG(1, "net_avahi_init: Avahi init failed, support disabled\n")

  if(avahi_client)
    {
      avahi_client_free(avahi_client)
      avahi_client = NULL
    }

  if(avahi_thread)
    {
      avahi_threaded_poll_free(avahi_thread)
      avahi_thread = NULL
    }
}

static void
net_avahi_cleanup(void)
{
  if(!avahi_thread)
    return

  DBG(1, "net_avahi_cleanup: stopping thread\n")

  avahi_threaded_poll_stop(avahi_thread)

  if(avahi_browser)
    avahi_service_browser_free(avahi_browser)

  if(avahi_client)
    avahi_client_free(avahi_client)

  avahi_threaded_poll_free(avahi_thread)

  DBG(1, "net_avahi_cleanup: done\n")
}
#endif /* WITH_AVAHI */


Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  char device_name[PATH_MAX]
  const char *optval
  const char *env
  size_t len
  FILE *fp
  short ns = 0x1234
  unsigned char *p = (unsigned char *)(&ns)

#ifndef NET_USES_AF_INDEP
  struct servent *serv
#endif /* !NET_USES_AF_INDEP */

  DBG_INIT()

  DBG(2, "Sane.init: authorize %s null, version_code %s null\n", (authorize) ? "!=" : "==",
       (version_code) ? "!=" : "==")

  devlist = NULL
  first_device = NULL
  first_handle = NULL

#if WITH_AVAHI
  net_avahi_init()
#endif /* WITH_AVAHI */

  auth_callback = authorize

  /* Return the version number of the sane-backends package to allow
     the frontend to print them. This is done only for net and dll,
     because these backends are usually called by the frontend. */
  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.DLL_V_MAJOR, Sane.DLL_V_MINOR,
				       Sane.DLL_V_BUILD)

  DBG(1, "Sane.init: SANE net backend version %s from %s\n", NET_VERSION,
       PACKAGE_STRING)

  /* determine(client) machine byte order */
  if(*p == 0x12)
    {
      client_big_endian = 1
      DBG(3, "Sane.init: Client has big endian byte order\n")
    }
  else
    {
      client_big_endian = 0
      DBG(3, "Sane.init: Client has little endian byte order\n")
    }

#ifndef NET_USES_AF_INDEP
  DBG(2, "Sane.init: determining sane service port\n")
  serv = getservbyname("sane-port", "tcp")

  if(serv)
    {
      DBG(2, "Sane.init: found port %d\n", ntohs(serv.s_port))
      saned_port = serv.s_port
    }
  else
    {
      saned_port = htons(6566)
      DBG(1, "Sane.init: could not find `sane-port" service(%s); using default "
	   "port %d\n", strerror(errno), ntohs(saned_port))
    }
#endif /* !NET_USES_AF_INDEP */

  DBG(2, "Sane.init: searching for config file\n")
  fp = sanei_config_open(NET_CONFIG_FILE)
  if(fp)
    {
      while(sanei_config_read(device_name, sizeof(device_name), fp))
	{
	  if(device_name[0] == "#")	/* ignore line comments */
	    continue
	  len = strlen(device_name)

	  if(!len)
	    continue;		/* ignore empty lines */

	  /*
	   * Check for net backend options.
	   * Anything that isn"t an option is a saned host.
	   */
	  if(strstr(device_name, "connect_timeout") != NULL)
	    {
	      /* Look for the = sign; if it"s not there, error out */
	      optval = strchr(device_name, "=")

	      if(!optval)
		continue

	      optval = sanei_config_skip_whitespace(++optval)
	      if((optval != NULL) && (*optval != "\0"))
		{
		  connect_timeout = atoi(optval)

		  DBG(2, "Sane.init: connect timeout set to %d seconds\n", connect_timeout)
		}

	      continue
	    }
#if WITH_AVAHI
	  avahi_threaded_poll_lock(avahi_thread)
#endif /* WITH_AVAHI */
	  DBG(2, "Sane.init: trying to add %s\n", device_name)
	  add_device(device_name, 0)
#if WITH_AVAHI
	  avahi_threaded_poll_unlock(avahi_thread)
#endif /* WITH_AVAHI */
	}

      fclose(fp)
      DBG(2, "Sane.init: done reading config\n")
    }
  else
    DBG(1, "Sane.init: could not open config file(%s): %s\n",
	 NET_CONFIG_FILE, strerror(errno))

  DBG(2, "Sane.init: evaluating environment variable Sane.NET_HOSTS\n")
  env = getenv("Sane.NET_HOSTS")
  if(env)
    {
      char *copy, *next, *host
      if((copy = strdup(env)) != NULL)
	{
	  next = copy
	  while((host = strsep(&next, ":")))
	    {
#ifdef ENABLE_IPV6
	      if(host[0] == "[")
		{
		  /* skip "[" (host[0]) */
		  host++
		  /* get the rest of the IPv6 addr(we"re screwed if ] is missing)
		   * Is it worth checking for the matching ] ? Not for now. */
		  strsep(&next, "]")
		  /* add back the ":" that got removed by the strsep() */
		  host[strlen(host)] = ":"
		  /* host now holds the IPv6 address */

		  /* skip the ":" that could be after ] (avoids a call to strsep() */
		  if(next[0] == ":")
		    next++
		}

	      /*
	       * if the IPv6 is last in the list, the strsep() call in the while()
	       * will return a string with the first char being "\0". Skip it.
	       */
	      if(host[0] == "\0")
		  continue
#endif /* ENABLE_IPV6 */
#if WITH_AVAHI
	      avahi_threaded_poll_lock(avahi_thread)
#endif /* WITH_AVAHI */
	      DBG(2, "Sane.init: trying to add %s\n", host)
	      add_device(host, 0)
#if WITH_AVAHI
	      avahi_threaded_poll_unlock(avahi_thread)
#endif /* WITH_AVAHI */
	    }
	  free(copy)
	}
      else
	DBG(1, "Sane.init: not enough memory to duplicate "
	     "environment variable\n")
    }

  DBG(2, "Sane.init: evaluating environment variable Sane.NET_TIMEOUT\n")
  env = getenv("Sane.NET_TIMEOUT")
  if(env)
    {
      connect_timeout = atoi(env)
      DBG(2, "Sane.init: connect timeout set to %d seconds from env\n", connect_timeout)
    }

  DBG(2, "Sane.init: done\n")
  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  Net_Scanner *handle, *next_handle
  Net_Device *dev, *next_device
  var i: Int

  DBG(1, "Sane.exit: exiting\n")

#if WITH_AVAHI
  net_avahi_cleanup()
#endif /* WITH_AVAHI */

  /* first, close all handles: */
  for(handle = first_handle; handle; handle = next_handle)
    {
      next_handle = handle.next
      Sane.close(handle)
    }
  first_handle = 0

  /* now close all devices: */
  for(dev = first_device; dev; dev = next_device)
    {
      next_device = dev.next

      DBG(2, "Sane.exit: closing dev %p, ctl=%d\n", (void *) dev, dev.ctl)

      if(dev.ctl >= 0)
	{
	  sanei_w_call(&dev.wire, Sane.NET_EXIT,
			(WireCodecFunc) sanei_w_void, 0,
			(WireCodecFunc) sanei_w_void, 0)
	  sanei_w_exit(&dev.wire)
	  close(dev.ctl)
	}
      if(dev.name)
	free((void *) dev.name)

#ifdef NET_USES_AF_INDEP
      if(dev.addr)
	freeaddrinfo(dev.addr)
#endif /* NET_USES_AF_INDEP */

      free(dev)
    }
  if(devlist)
    {
      for(i = 0; devlist[i]; ++i)
	{
	  if(devlist[i]->vendor)
	    free((void *) devlist[i]->vendor)
	  if(devlist[i]->model)
	    free((void *) devlist[i]->model)
	  if(devlist[i]->type)
	    free((void *) devlist[i]->type)
	  free((void *) devlist[i])
	}
      free(devlist)
    }
  DBG(3, "Sane.exit: finished.\n")
}

/* Note that a call to get_devices() implies that we"ll have to
   connect to all remote hosts.  To avoid this, you can call
   Sane.open() directly(assuming you know the name of the
   backend/device).  This is appropriate for the command-line
   interface of SANE, for example.
 */
Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  static Int devlist_size = 0, devlist_len = 0
  static const Sane.Device *empty_devlist[1] = { 0 ]
  Sane.Get_Devices_Reply reply
  Sane.Status status
  Net_Device *dev
  char *full_name
  var i: Int, num_devs
  size_t len
#define ASSERT_SPACE(n)                                                    \
  {                                                                        \
    if(devlist_len + (n) > devlist_size)                                  \
      {                                                                    \
        devlist_size += (n) + 15;                                          \
        if(devlist)                                                       \
          devlist = realloc(devlist, devlist_size * sizeof(devlist[0])); \
        else                                                               \
          devlist = malloc(devlist_size * sizeof(devlist[0]));           \
        if(!devlist)                                                      \
          {                                                                \
             DBG(1, "Sane.get_devices: not enough memory\n");	           \
             return Sane.STATUS_NO_MEM;                                    \
          }                                                                \
      }                                                                    \
  }

  DBG(3, "Sane.get_devices: local_only = %d\n", local_only)

  if(local_only)
    {
      *device_list = empty_devlist
      return Sane.STATUS_GOOD
    }

  if(devlist)
    {
      DBG(2, "Sane.get_devices: freeing devlist\n")
      for(i = 0; devlist[i]; ++i)
	{
	  if(devlist[i]->vendor)
	    free((void *) devlist[i]->vendor)
	  if(devlist[i]->model)
	    free((void *) devlist[i]->model)
	  if(devlist[i]->type)
	    free((void *) devlist[i]->type)
	  free((void *) devlist[i])
	}
      free(devlist)
      devlist = 0
    }
  devlist_len = 0
  devlist_size = 0

  for(dev = first_device; dev; dev = dev.next)
    {
      if(dev.ctl < 0)
	{
	  status = connect_dev(dev)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(1, "Sane.get_devices: ignoring failure to connect to %s\n",
		   dev.name)
	      continue
	    }
	}
      sanei_w_call(&dev.wire, Sane.NET_GET_DEVICES,
		    (WireCodecFunc) sanei_w_void, 0,
		    (WireCodecFunc) sanei_w_get_devices_reply, &reply)
      if(reply.status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.get_devices: ignoring rpc-returned status %s\n",
	       Sane.strstatus(reply.status))
	  sanei_w_free(&dev.wire,
			(WireCodecFunc) sanei_w_get_devices_reply, &reply)
	  continue
	}

      /* count the number of devices for this backend: */
      for(num_devs = 0; reply.device_list[num_devs]; ++num_devs)

      ASSERT_SPACE(num_devs)

      for(i = 0; i < num_devs; ++i)
	{
	  Sane.Device *rdev
	  char *mem
#ifdef ENABLE_IPV6
	  Bool IPv6 = Sane.FALSE
#endif /* ENABLE_IPV6 */

	  /* create a new device entry with a device name that is the
	     sum of the backend name a colon and the backend"s device
	     name: */
	  len = strlen(dev.name) + 1 + strlen(reply.device_list[i]->name)

#ifdef ENABLE_IPV6
	  if(strchr(dev.name, ":") != NULL)
	    {
	      len += 2
	      IPv6 = Sane.TRUE
	    }
#endif /* ENABLE_IPV6 */

	  mem = malloc(sizeof(*dev) + len + 1)
	  if(!mem)
	    {
	      DBG(1, "Sane.get_devices: not enough free memory\n")
	      sanei_w_free(&dev.wire,
			    (WireCodecFunc) sanei_w_get_devices_reply,
			    &reply)
	      return Sane.STATUS_NO_MEM
	    }

	  memset(mem, 0, sizeof(*dev) + len)
	  full_name = mem + sizeof(*dev)

#ifdef ENABLE_IPV6
	  if(IPv6 == Sane.TRUE)
	    strcat(full_name, "[")
#endif /* ENABLE_IPV6 */

	  strcat(full_name, dev.name)

#ifdef ENABLE_IPV6
	  if(IPv6 == Sane.TRUE)
	    strcat(full_name, "]")
#endif /* ENABLE_IPV6 */

	  strcat(full_name, ":")
	  strcat(full_name, reply.device_list[i]->name)
	  DBG(3, "Sane.get_devices: got %s\n", full_name)

	  rdev = (Sane.Device *) mem
	  rdev.name = full_name
	  rdev.vendor = strdup(reply.device_list[i]->vendor)
	  rdev.model = strdup(reply.device_list[i]->model)
	  rdev.type = strdup(reply.device_list[i]->type)

	  if((!rdev.vendor) || (!rdev.model) || (!rdev.type))
	    {
	      DBG(1, "Sane.get_devices: not enough free memory\n")
	      if(rdev.vendor)
		free((void *) rdev.vendor)
	      if(rdev.model)
		free((void *) rdev.model)
	      if(rdev.type)
		free((void *) rdev.type)
	      free(rdev)
	      sanei_w_free(&dev.wire,
			    (WireCodecFunc) sanei_w_get_devices_reply,
			    &reply)
	      return Sane.STATUS_NO_MEM
	    }

	  devlist[devlist_len++] = rdev
	}
      /* now free up the rpc return value: */
      sanei_w_free(&dev.wire,
		    (WireCodecFunc) sanei_w_get_devices_reply, &reply)
    }

  /* terminate device list with NULL entry: */
  ASSERT_SPACE(1)
  devlist[devlist_len++] = 0

  *device_list = devlist
  DBG(2, "Sane.get_devices: finished(%d devices)\n", devlist_len - 1)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const full_name, Sane.Handle * meta_handle)
{
  Sane.Open_Reply reply
  const char *dev_name
#ifdef ENABLE_IPV6
  const char *tmp_name
  Bool v6addr = Sane.FALSE
#endif /* ENABLE_IPV6 */
  String nd_name
  Sane.Status status
  Sane.Word handle
  Sane.Word ack
  Net_Device *dev
  Net_Scanner *s
  Int need_auth

  DBG(3, "Sane.open(\"%s\")\n", full_name)

#ifdef ENABLE_IPV6
  /*
   * Check whether a numerical IPv6 host was specified
   * [2001:42:42::12] <== check for "[" as full_name[0]
   * ex: [2001:42:42::12]:test:0 (syntax taken from Apache 2)
   */
  if(full_name[0] == "[")
    {
      v6addr = Sane.TRUE
      tmp_name = strchr(full_name, "]")
      if(!tmp_name)
	{
	  DBG(1, "Sane.open: incorrect host address: missing matching "]"\n")
	  return Sane.STATUS_INVAL
	}
    }
  else
    tmp_name = full_name

  dev_name = strchr(tmp_name, ":")
#else /* !ENABLE_IPV6 */

  dev_name = strchr(full_name, ":")
#endif /* ENABLE_IPV6 */

  if(dev_name)
    {
#ifdef strndupa
# ifdef ENABLE_IPV6
      if(v6addr == Sane.TRUE)
	nd_name = strndupa(full_name + 1, dev_name - full_name - 2)
      else
	nd_name = strndupa(full_name, dev_name - full_name)

# else /* !ENABLE_IPV6 */

      nd_name = strndupa(full_name, dev_name - full_name)
# endif /* ENABLE_IPV6 */

      if(!nd_name)
	{
	  DBG(1, "Sane.open: not enough free memory\n")
	  return Sane.STATUS_NO_MEM
	}
#else
      char *tmp

# ifdef ENABLE_IPV6
      if(v6addr == Sane.TRUE)
	tmp = alloca(dev_name - full_name - 2 + 1)
      else
	tmp = alloca(dev_name - full_name + 1)

# else /* !ENABLE_IPV6 */

      tmp = alloca(dev_name - full_name + 1)
# endif /* ENABLE_IPV6 */

      if(!tmp)
	{
	  DBG(1, "Sane.open: not enough free memory\n")
	  return Sane.STATUS_NO_MEM
	}

# ifdef ENABLE_IPV6
      if(v6addr == Sane.TRUE)
	{
	  memcpy(tmp, full_name + 1, dev_name - full_name - 2)
	  tmp[dev_name - full_name - 2] = "\0"
	}
      else
	{
	  memcpy(tmp, full_name, dev_name - full_name)
	  tmp[dev_name - full_name] = "\0"
	}

# else /* !ENABLE_IPV6 */

      memcpy(tmp, full_name, dev_name - full_name)
      tmp[dev_name - full_name] = "\0"
# endif /* ENABLE_IPV6 */

      nd_name = tmp
#endif
      ++dev_name;		/* skip colon */
    }
  else
    {
      /* if no colon interpret full_name as the host name; an empty
         device name will cause us to open the first device of that
         host.  */
#ifdef ENABLE_IPV6
      if(v6addr == Sane.TRUE)
	{
	  nd_name = alloca(strlen(full_name) - 2 + 1)
	  if(!nd_name)
	    {
	      DBG(1, "Sane.open: not enough free memory\n")
	      return Sane.STATUS_NO_MEM
	    }
	  memcpy(nd_name, full_name + 1, strlen(full_name) - 2)
	  nd_name[strlen(full_name) - 2] = "\0"
	}
      else
	nd_name = (char *) full_name

#else /* !ENABLE_IPV6 */

      nd_name = (char *) full_name
#endif /* ENABLE_IPV6 */

      dev_name = ""
    }
  DBG(2, "Sane.open: host = %s, device = %s\n", nd_name, dev_name)

  if(!nd_name[0])
    {
      /* Unlike other backends, we never allow an empty backend-name.
         Otherwise, it"s possible that Sane.open("") will result in
         endless looping(consider the case where NET is the first
         backend...) */

      DBG(1, "Sane.open: empty backend name is not allowed\n")
      return Sane.STATUS_INVAL
    }
  else
    for(dev = first_device; dev; dev = dev.next)
      if(strcmp(dev.name, nd_name) == 0)
	break

  if(!dev)
    {
      DBG(1,
	   "Sane.open: device %s not found, trying to register it anyway\n",
	   nd_name)
#if WITH_AVAHI
      avahi_threaded_poll_lock(avahi_thread)
#endif /* WITH_AVAHI */
      status = add_device(nd_name, &dev)
#if WITH_AVAHI
      avahi_threaded_poll_unlock(avahi_thread)
#endif /* WITH_AVAHI */
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.open: could not open device\n")
	  return status
	}
    }
  else
    DBG(2, "Sane.open: device found in list\n")

  if(dev.ctl < 0)
    {
      DBG(2, "Sane.open: device not connected yet...\n")
      status = connect_dev(dev)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.open: could not connect to device\n")
	  return status
	}
    }

  DBG(3, "Sane.open: net_open\n")
  sanei_w_call(&dev.wire, Sane.NET_OPEN,
		(WireCodecFunc) sanei_w_string, &dev_name,
		(WireCodecFunc) sanei_w_open_reply, &reply)
  do
    {
      if(dev.wire.status != 0)
	{
	  DBG(1, "Sane.open: open rpc call failed(%s)\n",
	       strerror(dev.wire.status))
	  return Sane.STATUS_IO_ERROR
	}

      status = reply.status
      handle = reply.handle
      need_auth = (reply.resource_to_authorize != 0)

      if(need_auth)
	{
	  DBG(3, "Sane.open: authorization required\n")
	  do_authorization(dev, reply.resource_to_authorize)

	  sanei_w_free(&dev.wire, (WireCodecFunc) sanei_w_open_reply,
			&reply)

	  if(dev.wire.direction != WIRE_DECODE)
	    sanei_w_set_dir(&dev.wire, WIRE_DECODE)
	  sanei_w_open_reply(&dev.wire, &reply)

	  continue
	}
      else
	sanei_w_free(&dev.wire, (WireCodecFunc) sanei_w_open_reply, &reply)

      if(need_auth && !dev.auth_active)
	{
	  DBG(2, "Sane.open: open cancelled\n")
	  return Sane.STATUS_CANCELLED
	}

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.open: remote open failed\n")
	  return reply.status
	}
    }
  while(need_auth)

  s = malloc(sizeof(*s))
  if(!s)
    {
      DBG(1, "Sane.open: not enough free memory\n")
      return Sane.STATUS_NO_MEM
    }

  memset(s, 0, sizeof(*s))
  s.hw = dev
  s.handle = handle
  s.data = -1
  s.next = first_handle
  s.local_opt.desc = 0
  s.local_opt.num_options = 0

  DBG(3, "Sane.open: getting option descriptors\n")
  status = fetch_options(s)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "Sane.open: fetch_options failed(%s), closing device again\n",
	   Sane.strstatus(status))

      sanei_w_call(&s.hw.wire, Sane.NET_CLOSE,
		    (WireCodecFunc) sanei_w_word, &s.handle,
		    (WireCodecFunc) sanei_w_word, &ack)

      free(s)

      return status
    }

  first_handle = s
  *meta_handle = s

  DBG(3, "Sane.open: success\n")
  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  Net_Scanner *prev, *s
  Sane.Word ack
  Int option_number

  DBG(3, "Sane.close: handle %p\n", handle)

  prev = 0
  for(s = first_handle; s; s = s.next)
    {
      if(s == handle)
	break
      prev = s
    }
  if(!s)
    {
      DBG(1, "Sane.close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }
  if(prev)
    prev.next = s.next
  else
    first_handle = s.next

  if(s.opt.num_options)
    {
      DBG(2, "Sane.close: removing cached option descriptors\n")
      sanei_w_set_dir(&s.hw.wire, WIRE_FREE)
      s.hw.wire.status = 0
      sanei_w_option_descriptor_array(&s.hw.wire, &s.opt)
      if(s.hw.wire.status)
	DBG(1, "Sane.close: couldn"t free sanei_w_option_descriptor_array "
	     "(%s)\n", Sane.strstatus(s.hw.wire.status))
    }

  DBG(2, "Sane.close: removing local option descriptors\n")
  for(option_number = 0; option_number < s.local_opt.num_options
       option_number++)
    free(s.local_opt.desc[option_number])
  if(s.local_opt.desc)
    free(s.local_opt.desc)

  DBG(2, "Sane.close: net_close\n")
  sanei_w_call(&s.hw.wire, Sane.NET_CLOSE,
		(WireCodecFunc) sanei_w_word, &s.handle,
		(WireCodecFunc) sanei_w_word, &ack)
  if(s.data >= 0)
    {
      DBG(2, "Sane.close: closing data pipe\n")
      close(s.data)
    }
  free(s)
  DBG(2, "Sane.close: done\n")
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Net_Scanner *s = handle
  Sane.Status status

  DBG(3, "Sane.get_option_descriptor: option %d\n", option)

  if(!s.options_valid)
    {
      DBG(3, "Sane.get_option_descriptor: getting option descriptors\n")
      status = fetch_options(s)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.get_option_descriptor: fetch_options failed(%s)\n",
	       Sane.strstatus(status))
	  return 0
	}
    }

  if(((Sane.Word) option >= s.opt.num_options) || (option < 0))
    {
      DBG(2, "Sane.get_option_descriptor: invalid option number\n")
      return 0
    }
  return s.local_opt.desc[option]
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *value, Sane.Word * info)
{
  Net_Scanner *s = handle
  Sane.Control_Option_Req req
  Sane.Control_Option_Reply reply
  Sane.Status status
  size_t value_size
  Int need_auth
  Sane.Word local_info

  DBG(3, "Sane.control_option: option %d, action %d\n", option, action)

  if(!s.options_valid)
    {
      DBG(1, "Sane.control_option: FRONTEND BUG: option descriptors reload needed\n")
      return Sane.STATUS_INVAL
    }

  if(((Sane.Word) option >= s.opt.num_options) || (option < 0))
    {
      DBG(1, "Sane.control_option: invalid option number\n")
      return Sane.STATUS_INVAL
    }

  switch(s.opt.desc[option]->type)
    {
    case Sane.TYPE_BUTTON:
    case Sane.TYPE_GROUP:	/* shouldn"t happen... */
      /* the SANE standard defines that the option size of a BUTTON or
         GROUP is IGNORED.  */
      value_size = 0
      break
    case Sane.TYPE_STRING:	/* strings can be smaller than size */
      value_size = s.opt.desc[option]->size
      if((action == Sane.ACTION_SET_VALUE)
	  && (((Int) strlen((String) value) + 1)
	      < s.opt.desc[option]->size))
	value_size = strlen((String) value) + 1
      break
    default:
      value_size = s.opt.desc[option]->size
      break
    }

  /* Avoid leaking memory bits */
  if(value && (action != Sane.ACTION_SET_VALUE))
    memset(value, 0, value_size)

  /* for SET_AUTO the parameter ``value"" is ignored */
  if(action == Sane.ACTION_SET_AUTO)
    value_size = 0

  req.handle = s.handle
  req.option = option
  req.action = action
  req.value_type = s.opt.desc[option]->type
  req.value_size = value_size
  req.value = value

  local_info = 0

  DBG(3, "Sane.control_option: remote control option\n")
  sanei_w_call(&s.hw.wire, Sane.NET_CONTROL_OPTION,
		(WireCodecFunc) sanei_w_control_option_req, &req,
		(WireCodecFunc) sanei_w_control_option_reply, &reply)

  do
    {
      status = reply.status
      need_auth = (reply.resource_to_authorize != 0)
      if(need_auth)
	{
	  DBG(3, "Sane.control_option: auth required\n")
	  do_authorization(s.hw, reply.resource_to_authorize)
	  sanei_w_free(&s.hw.wire,
			(WireCodecFunc) sanei_w_control_option_reply, &reply)

	  sanei_w_set_dir(&s.hw.wire, WIRE_DECODE)

	  sanei_w_control_option_reply(&s.hw.wire, &reply)
	  continue

	}
      else if(status == Sane.STATUS_GOOD)
	{
	  local_info = reply.info

	  if(info)
	    *info = reply.info
	  if(value_size > 0)
	    {
	      if((Sane.Word) value_size == reply.value_size)
		memcpy(value, reply.value, reply.value_size)
	      else
		DBG(1, "Sane.control_option: size changed from %d to %d\n",
		     s.opt.desc[option]->size, reply.value_size)
	    }

	  if(reply.info & Sane.INFO_RELOAD_OPTIONS)
	    s.options_valid = 0
	}
      sanei_w_free(&s.hw.wire,
		    (WireCodecFunc) sanei_w_control_option_reply, &reply)
      if(need_auth && !s.hw.auth_active)
	return Sane.STATUS_CANCELLED
    }
  while(need_auth)

  DBG(2, "Sane.control_option: remote done(%s, info %x)\n", Sane.strstatus(status), local_info)

  if((status == Sane.STATUS_GOOD) && (info == NULL) && (local_info & Sane.INFO_RELOAD_OPTIONS))
    {
      DBG(2, "Sane.control_option: reloading options as frontend does not care\n")

      status = fetch_options(s)

      DBG(2, "Sane.control_option: reload done(%s)\n", Sane.strstatus(status))
    }

  DBG(2, "Sane.control_option: done(%s, info %x)\n", Sane.strstatus(status), local_info)

  return status
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Net_Scanner *s = handle
  Sane.Get_Parameters_Reply reply
  Sane.Status status

  DBG(3, "Sane.get_parameters\n")

  if(!params)
    {
      DBG(1, "Sane.get_parameters: parameter params not supplied\n")
      return Sane.STATUS_INVAL
    }

  DBG(3, "Sane.get_parameters: remote get parameters\n")
  sanei_w_call(&s.hw.wire, Sane.NET_GET_PARAMETERS,
		(WireCodecFunc) sanei_w_word, &s.handle,
		(WireCodecFunc) sanei_w_get_parameters_reply, &reply)

  status = reply.status
  *params = reply.params
  depth = reply.params.depth
  sanei_w_free(&s.hw.wire,
		(WireCodecFunc) sanei_w_get_parameters_reply, &reply)

  DBG(3, "Sane.get_parameters: returned status %s\n",
       Sane.strstatus(status))
  return status
}

#ifdef NET_USES_AF_INDEP
Sane.Status
Sane.start(Sane.Handle handle)
{
  Net_Scanner *s = handle
  Sane.Start_Reply reply
  struct sockaddr_in sin
  struct sockaddr *sa
#ifdef ENABLE_IPV6
  struct sockaddr_in6 sin6
#endif /* ENABLE_IPV6 */
  Sane.Status status
  Int fd, need_auth
  socklen_t len
  uint16_t port;			/* Internet-specific */


  DBG(3, "Sane.start\n")

  hang_over = -1
  left_over = -1

  if(s.data >= 0)
    {
      DBG(2, "Sane.start: data pipe already exists\n")
      return Sane.STATUS_INVAL
    }

  /* Do this ahead of time so in case anything fails, we can
     recover gracefully(without hanging our server).  */

  switch(s.hw.addr_used.ai_family)
    {
      case AF_INET:
	len = sizeof(sin)
	sa = (struct sockaddr *) &sin
	break
#ifdef ENABLE_IPV6
      case AF_INET6:
	len = sizeof(sin6)
	sa = (struct sockaddr *) &sin6
	break
#endif /* ENABLE_IPV6 */
      default:
	DBG(1, "Sane.start: unknown address family : %d\n",
	     s.hw.addr_used.ai_family)
	return Sane.STATUS_INVAL
    }

  if(getpeername(s.hw.ctl, sa, &len) < 0)
    {
      DBG(1, "Sane.start: getpeername() failed(%s)\n", strerror(errno))
      return Sane.STATUS_IO_ERROR
    }

  fd = socket(s.hw.addr_used.ai_family, SOCK_STREAM, 0)
  if(fd < 0)
    {
      DBG(1, "Sane.start: socket() failed(%s)\n", strerror(errno))
      return Sane.STATUS_IO_ERROR
    }

  DBG(3, "Sane.start: remote start\n")
  sanei_w_call(&s.hw.wire, Sane.NET_START,
		(WireCodecFunc) sanei_w_word, &s.handle,
		(WireCodecFunc) sanei_w_start_reply, &reply)
  do
    {
      status = reply.status
      port = reply.port
      if(reply.byte_order == 0x1234)
	{
	  server_big_endian = 0
	  DBG(1, "Sane.start: server has little endian byte order\n")
	}
      else
	{
	  server_big_endian = 1
	  DBG(1, "Sane.start: server has big endian byte order\n")
	}

      need_auth = (reply.resource_to_authorize != 0)
      if(need_auth)
	{
	  DBG(3, "Sane.start: auth required\n")
	  do_authorization(s.hw, reply.resource_to_authorize)

	  sanei_w_free(&s.hw.wire,
			(WireCodecFunc) sanei_w_start_reply, &reply)

	  sanei_w_set_dir(&s.hw.wire, WIRE_DECODE)

	  sanei_w_start_reply(&s.hw.wire, &reply)

	  continue
	}
      sanei_w_free(&s.hw.wire, (WireCodecFunc) sanei_w_start_reply,
		    &reply)
      if(need_auth && !s.hw.auth_active)
	return Sane.STATUS_CANCELLED

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.start: remote start failed(%s)\n",
	       Sane.strstatus(status))
	  close(fd)
	  return status
	}
    }
  while(need_auth)
  DBG(3, "Sane.start: remote start finished, data at port %hu\n", port)

  switch(s.hw.addr_used.ai_family)
    {
      case AF_INET:
	sin.sin_port = htons(port)
	break
#ifdef ENABLE_IPV6
      case AF_INET6:
	sin6.sin6_port = htons(port)
	break
#endif /* ENABLE_IPV6 */
    }

  if(connect(fd, sa, len) < 0)
    {
      DBG(1, "Sane.start: connect() failed(%s)\n", strerror(errno))
      close(fd)
      return Sane.STATUS_IO_ERROR
    }
  shutdown(fd, 1)
  s.data = fd
  s.reclen_buf_offset = 0
  s.bytes_remaining = 0
  DBG(3, "Sane.start: done(%s)\n", Sane.strstatus(status))
  return status
}

#else /* !NET_USES_AF_INDEP */

Sane.Status
Sane.start(Sane.Handle handle)
{
  Net_Scanner *s = handle
  Sane.Start_Reply reply
  struct sockaddr_in sin
  Sane.Status status
  Int fd, need_auth
  socklen_t len
  uint16_t port;			/* Internet-specific */


  DBG(3, "Sane.start\n")

  hang_over = -1
  left_over = -1

  if(s.data >= 0)
    {
      DBG(2, "Sane.start: data pipe already exists\n")
      return Sane.STATUS_INVAL
    }

  /* Do this ahead of time so in case anything fails, we can
     recover gracefully(without hanging our server).  */
  len = sizeof(sin)
  if(getpeername(s.hw.ctl, (struct sockaddr *) &sin, &len) < 0)
    {
      DBG(1, "Sane.start: getpeername() failed(%s)\n", strerror(errno))
      return Sane.STATUS_IO_ERROR
    }

  fd = socket(s.hw.addr.sa_family, SOCK_STREAM, 0)
  if(fd < 0)
    {
      DBG(1, "Sane.start: socket() failed(%s)\n", strerror(errno))
      return Sane.STATUS_IO_ERROR
    }

  DBG(3, "Sane.start: remote start\n")
  sanei_w_call(&s.hw.wire, Sane.NET_START,
		(WireCodecFunc) sanei_w_word, &s.handle,
		(WireCodecFunc) sanei_w_start_reply, &reply)
  do
    {

      status = reply.status
      port = reply.port
      if(reply.byte_order == 0x1234)
	{
	  server_big_endian = 0
	  DBG(1, "Sane.start: server has little endian byte order\n")
	}
      else
	{
	  server_big_endian = 1
	  DBG(1, "Sane.start: server has big endian byte order\n")
	}

      need_auth = (reply.resource_to_authorize != 0)
      if(need_auth)
	{
	  DBG(3, "Sane.start: auth required\n")
	  do_authorization(s.hw, reply.resource_to_authorize)

	  sanei_w_free(&s.hw.wire,
			(WireCodecFunc) sanei_w_start_reply, &reply)

	  sanei_w_set_dir(&s.hw.wire, WIRE_DECODE)

	  sanei_w_start_reply(&s.hw.wire, &reply)

	  continue
	}
      sanei_w_free(&s.hw.wire, (WireCodecFunc) sanei_w_start_reply,
		    &reply)
      if(need_auth && !s.hw.auth_active)
	return Sane.STATUS_CANCELLED

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.start: remote start failed(%s)\n",
	       Sane.strstatus(status))
	  close(fd)
	  return status
	}
    }
  while(need_auth)
  DBG(3, "Sane.start: remote start finished, data at port %hu\n", port)
  sin.sin_port = htons(port)

  if(connect(fd, (struct sockaddr *) &sin, len) < 0)
    {
      DBG(1, "Sane.start: connect() failed(%s)\n", strerror(errno))
      close(fd)
      return Sane.STATUS_IO_ERROR
    }
  shutdown(fd, 1)
  s.data = fd
  s.reclen_buf_offset = 0
  s.bytes_remaining = 0
  DBG(3, "Sane.start: done(%s)\n", Sane.strstatus(status))
  return status
}
#endif /* NET_USES_AF_INDEP */


Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * data, Int max_length,
	   Int * length)
{
  Net_Scanner *s = handle
  ssize_t nread
  Int cnt
  Int start_cnt
  Int end_cnt
  Sane.Byte swap_buf
  Sane.Byte temp_hang_over
  Int is_even

  DBG(3, "Sane.read: handle=%p, data=%p, max_length=%d, length=%p\n",
       handle, data, max_length, (void *) length)
  if(!length)
    {
      DBG(1, "Sane.read: length == NULL\n")
      return Sane.STATUS_INVAL
    }

  is_even = 1
  *length = 0

  /* If there"s a left over, i.e. a byte already in the correct byte order,
     return it immediately; otherwise read may fail with a Sane.STATUS_EOF and
     the caller never can read the last byte */
  if((depth == 16) && (server_big_endian != client_big_endian))
    {
      if(left_over > -1)
	{
	  DBG(3, "Sane.read: left_over from previous call, return "
	       "immediately\n")
	  /* return the byte, we"ve currently scanned; hang_over becomes
	     left_over */
	  *data = (Sane.Byte) left_over
	  left_over = -1
	  *length = 1
	  return Sane.STATUS_GOOD
	}
    }

  if(s.data < 0)
    {
      DBG(1, "Sane.read: data pipe doesn"t exist, scan cancelled?\n")
      return Sane.STATUS_CANCELLED
    }

  if(s.bytes_remaining == 0)
    {
      /* boy, is this painful or what? */

      DBG(4, "Sane.read: reading packet length\n")
      nread = read(s.data, s.reclen_buf + s.reclen_buf_offset,
		    4 - s.reclen_buf_offset)
      if(nread < 0)
	{
	  DBG(3, "Sane.read: read failed(%s)\n", strerror(errno))
	  if(errno == EAGAIN)
	    {
	      DBG(3, "Sane.read: try again later\n")
	      return Sane.STATUS_GOOD
	    }
	  else
	    {
	      DBG(1, "Sane.read: cancelling read\n")
	      do_cancel(s)
	      return Sane.STATUS_IO_ERROR
	    }
	}
      DBG(4, "Sane.read: read %lu bytes, %d from 4 total\n", (u_long) nread,
	   s.reclen_buf_offset)
      s.reclen_buf_offset += nread
      if(s.reclen_buf_offset < 4)
	{
	  DBG(4, "Sane.read: enough for now\n")
	  return Sane.STATUS_GOOD
	}

      s.reclen_buf_offset = 0
      s.bytes_remaining = (((u_long) s.reclen_buf[0] << 24)
			    | ((u_long) s.reclen_buf[1] << 16)
			    | ((u_long) s.reclen_buf[2] << 8)
			    | ((u_long) s.reclen_buf[3] << 0))
      DBG(3, "Sane.read: next record length=%ld bytes\n",
	   (long) s.bytes_remaining)
      if(s.bytes_remaining == 0xffffffff)
	{
	  char ch

	  DBG(2, "Sane.read: received error signal\n")

	  /* turn off non-blocking I/O(s.data will be closed anyhow): */
	  fcntl(s.data, F_SETFL, 0)

	  /* read the status byte: */
	  if(read(s.data, &ch, sizeof(ch)) != 1)
	    {
	      DBG(1, "Sane.read: failed to read error code\n")
	      ch = Sane.STATUS_IO_ERROR
	    }
	  DBG(1, "Sane.read: error code %s\n",
	       Sane.strstatus((Sane.Status) ch))
	  do_cancel(s)
	  return(Sane.Status) ch
	}
    }

  if(max_length > (Int) s.bytes_remaining)
    max_length = s.bytes_remaining

  nread = read(s.data, data, max_length)

  if(nread < 0)
    {
      DBG(2, "Sane.read: error code %s\n", strerror(errno))
      if(errno == EAGAIN)
	return Sane.STATUS_GOOD
      else
	{
	  DBG(1, "Sane.read: cancelling scan\n")
	  do_cancel(s)
	  return Sane.STATUS_IO_ERROR
	}
    }

  s.bytes_remaining -= nread

  *length = nread
  /* Check whether we are scanning with a depth of 16 bits/pixel and whether
     server and client have different byte order. If this is true, then it"s
     necessary to check whether read returned an odd number. If an odd number
     has been returned, we must save the last byte.
  */
  if((depth == 16) && (server_big_endian != client_big_endian))
    {
      DBG(1,"Sane.read: client/server have different byte order; "
	   "must swap\n")
      /* special case: 1 byte scanned and hang_over */
      if((nread == 1) && (hang_over > -1))
	{
	  /* return the byte, we"ve currently scanned; hang_over becomes
	     left_over */
	  left_over = hang_over
	  hang_over = -1
	  return Sane.STATUS_GOOD
	}
      /* check whether an even or an odd number of bytes has been scanned */
      if((nread % 2) == 0)
        is_even = 1
      else
        is_even = 0
      /* check, whether there"s a hang over from a previous call
	 in this case we memcopy the data up one byte */
      if((nread > 1) && (hang_over > -1))
	{
	  /* store last byte */
	  temp_hang_over = *(data + nread - 1)
	  memmove(data + 1, data, nread - 1)
	  *data = (Sane.Byte) hang_over
	  /* what happens with the last byte depends on whether the number
	     of bytes is even or odd */
	  if(is_even == 1)
	    {
	      /* number of bytes is even; no new hang_over, exchange last
		 byte with hang over; last byte becomes left_over */
	      left_over = *(data + nread - 1)
	      *(data + nread - 1) = temp_hang_over
	      hang_over = -1
	      start_cnt = 0
	      /* last byte already swapped */
	      end_cnt = nread - 2
	    }
	  else
	    {
	      /* number of bytes is odd; last byte becomes new hang_over */
	      hang_over = temp_hang_over
	      left_over = -1
	      start_cnt = 0
	      end_cnt = nread - 1
	    }
	}
      else if(nread == 1)
	{
	  /* if only one byte has been read, save it as hang_over and return
	     length=0 */
	  hang_over = (Int) *data
	  *length = 0
	  return Sane.STATUS_GOOD
	}
      else
	{
	  /* no hang_over; test for even or odd byte number */
	  if(is_even == 1)
	    {
	      start_cnt = 0
	      end_cnt = *length
	    }
	  else
	    {
	      start_cnt = 0
	      hang_over = *(data + *length - 1)
	      *length -= 1
	      end_cnt = *length
	    }
	}
      /* swap the bytes */
      for(cnt = start_cnt; cnt < end_cnt - 1; cnt += 2)
	{
	  swap_buf = *(data + cnt)
	  *(data + cnt) = *(data + cnt + 1)
	  *(data + cnt + 1) = swap_buf
	}
    }
  DBG(3, "Sane.read: %lu bytes read, %lu remaining\n", (u_long) nread,
       (u_long) s.bytes_remaining)

  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle handle)
{
  Net_Scanner *s = handle
  Sane.Word ack

  DBG(3, "Sane.cancel: sending net_cancel\n")

  sanei_w_call(&s.hw.wire, Sane.NET_CANCEL,
		(WireCodecFunc) sanei_w_word, &s.handle,
		(WireCodecFunc) sanei_w_word, &ack)
  do_cancel(s)
  DBG(4, "Sane.cancel: done\n")
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  Net_Scanner *s = handle

  DBG(3, "Sane.set_io_mode: non_blocking = %d\n", non_blocking)
  if(s.data < 0)
    {
      DBG(1, "Sane.set_io_mode: pipe doesn"t exist\n")
      return Sane.STATUS_INVAL
    }

  if(fcntl(s.data, F_SETFL, non_blocking ? O_NONBLOCK : 0) < 0)
    {
      DBG(1, "Sane.set_io_mode: fcntl failed(%s)\n", strerror(errno))
      return Sane.STATUS_IO_ERROR
    }

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  Net_Scanner *s = handle

  DBG(3, "Sane.get_select_fd\n")

  if(s.data < 0)
    {
      DBG(1, "Sane.get_select_fd: pipe doesn"t exist\n")
      return Sane.STATUS_INVAL
    }

  *fd = s.data
  DBG(3, "Sane.get_select_fd: done; *fd = %d\n", *fd)
  return Sane.STATUS_GOOD
}
