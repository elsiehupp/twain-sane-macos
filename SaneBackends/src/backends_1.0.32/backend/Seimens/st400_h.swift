#ifndef st400_h
#define st400_h

#define ST400_CONFIG_FILE		"st400.conf"
#define ST400_DEFAULT_DEVICE	"/dev/scanner"

/* maximum scanning area in inch(guessed) */
#define ST400_MAX_X		8.5
#define ST400_MAX_Y		12.0

enum ST400_Option {
	OPT_NUM_OPTS = 0,

	OPT_MODE_GROUP,
	OPT_RESOLUTION,
	OPT_DEPTH,
	OPT_THRESHOLD,

	OPT_GEOMETRY_GROUP,
	OPT_TL_X,
	OPT_TL_Y,
	OPT_BR_X,
	OPT_BR_Y,

	NUM_OPTIONS		/* must be last */
]

typedef struct {
	size_t inq_voffset;		/* offset in INQUIRY result */
	char *inq_vendor
	size_t inq_moffset;		/* offset in INQUIRY result */
	char *inq_model

	size_t bits;			/* 6 or 8 */
	unsigned long bufsize;	/* internal buffer of scanner */
	unsigned long maxread;	/* max bytes to read in a cmd(0 = no limit) */
	Int *dpi_list;		/* NULL for default list */

	char *Sane.vendor
	char *Sane.model
	char *Sane.type
} ST400_Model


typedef struct ST400_Device {
	struct ST400_Device *next

	Sane.Device sane
	Sane.Parameters params
	Sane.Option_Descriptor opt[NUM_OPTIONS]
	Sane.Word val[NUM_OPTIONS]

	struct {
		unsigned open		:1
		unsigned scanning	:1
		unsigned eof		:1
	} status

	/* pixel values of entire scan window - for convenience */
	unsigned short x, y, w, h

	Int fd;						/* SCSI filedescriptor */

	/* backend buffer */
	Sane.Byte *buffer
	size_t bufsize
	Sane.Byte *bufp;					/* next byte to transfer */
	size_t bytes_in_buffer

	ST400_Model *model

	/* scanner buffer */
	unsigned short wy, wh;				/* current subwindow */
	unsigned long bytes_in_scanner
	unsigned short lines_to_read
} ST400_Device

#endif /* st400_h */
/* The End */