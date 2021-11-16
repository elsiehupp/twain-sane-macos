
#ifndef MUSTEK_PP_DECL_H
#define MUSTEK_PP_DECL_H
/* debug driver, version 0.11-devel, author Jochen Eisinger */
static Sane.Status	debug_drv_init(Int options, Sane.String_Const port,
					Sane.String_Const name, Sane.Attach_Callback attach)
static void		debug_drv_capabilities(Int info, String *model,
						String *vendor, String *type,
						Int *maxres, Int *minres,
						Int *maxhsize, Int *maxvsize,
						Int *caps)
static Sane.Status	debug_drv_open(String port, Int caps, Int *fd)
static void		debug_drv_setup(Sane.Handle hndl)
static Sane.Status	debug_drv_config(Sane.Handle hndl,
					  Sane.String_Const optname,
                                          Sane.String_Const optval)
static void		debug_drv_close(Sane.Handle hndl)
static Sane.Status	debug_drv_start(Sane.Handle hndl)
static void		debug_drv_read(Sane.Handle hndl, Sane.Byte *buffer)
static void		debug_drv_stop(Sane.Handle hndl)


/* CIS drivers for 600CP, 1200CP, and 1200CP+
   Version 0.13-beta, author Eddy De Greef */

static Sane.Status	cis600_drv_init  (Int options,
					  Sane.String_Const port,
				      	  Sane.String_Const name,
                                          Sane.Attach_Callback attach)
static Sane.Status	cis1200_drv_init(Int options,
					  Sane.String_Const port,
				      	  Sane.String_Const name,
                                          Sane.Attach_Callback attach)
static Sane.Status	cis1200p_drv_init(Int options,
				 	  Sane.String_Const port,
				      	  Sane.String_Const name,
                                          Sane.Attach_Callback attach)
static void		cis_drv_capabilities(Int info,
					     String *model,
					     String *vendor,
                                             String *type,
					     Int *maxres,
                                             Int *minres,
					     Int *maxhsize,
                                             Int *maxvsize,
					     Int *caps)
static Sane.Status	cis_drv_open(String port, Int caps, Int *fd)
static void		cis_drv_setup(Sane.Handle hndl)
static Sane.Status	cis_drv_config(Sane.Handle hndl,
					Sane.String_Const optname,
                                        Sane.String_Const optval)
static void		cis_drv_close(Sane.Handle hndl)
static Sane.Status	cis_drv_start(Sane.Handle hndl)
static void		cis_drv_read(Sane.Handle hndl, Sane.Byte *buffer)
static void		cis_drv_stop(Sane.Handle hndl)

/* CCD drivers for 300 dpi models
   Version 0.11-devel, author Jochen Eisinger */

static Sane.Status	ccd300_init  (Int options,
					  Sane.String_Const port,
				      	  Sane.String_Const name,
                                          Sane.Attach_Callback attach)
static void		ccd300_capabilities(Int info,
					     String *model,
					     String *vendor,
                                             String *type,
					     Int *maxres,
                                             Int *minres,
					     Int *maxhsize,
                                             Int *maxvsize,
					     Int *caps)
static Sane.Status	ccd300_open(String port, Int caps, Int *fd)
static void		ccd300_setup(Sane.Handle hndl)
static Sane.Status	ccd300_config(Sane.Handle hndl,
					Sane.String_Const optname,
                                        Sane.String_Const optval)
static void		ccd300_close(Sane.Handle hndl)
static Sane.Status	ccd300_start(Sane.Handle hndl)
static void		ccd300_read(Sane.Handle hndl, Sane.Byte *buffer)
static void		ccd300_stop(Sane.Handle hndl)

#endif
