import ../../include/sane/config

import stdlib
import sys/types
import sys/stat
import fcntl
import errno
import string
import assert

/* sane includes for the sanei functions called */
import Sane.sane
import Sane.saneopts
import Sane.sanei

static Sane.Option_Descriptor none_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_INT,
  Sane.UNIT_NONE,
  sizeof (Sane.Word),
  0,
  Sane.CONSTRAINT_NONE,
  {NULL}
]


static Sane.Option_Descriptor none_bool_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_BOOL,
  Sane.UNIT_NONE,
  sizeof (Sane.Word),
  0,
  Sane.CONSTRAINT_NONE,
  {NULL}
]

/* range for Int constraint */
static const Sane.Range int_range = {
  3,				/* minimum */
  18,				/* maximum */
  3				/* quantization */
]

/* range for sane fixed constraint */
static const Sane.Range fixed_range = {
  Sane.FIX(1.0),		/* minimum */
  Sane.FIX(431.8),		/* maximum */
  Sane.FIX(0.01)				/* quantization */
]

static Sane.Option_Descriptor int_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Word),
  0,
  Sane.CONSTRAINT_RANGE,
  {NULL}
]

static Sane.Option_Descriptor fixed_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Word),
  0,
  Sane.CONSTRAINT_RANGE,
  {NULL}
]

#define ARRAY_SIZE 7

static Sane.Option_Descriptor array_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Word) * ARRAY_SIZE,
  0,
  Sane.CONSTRAINT_RANGE,
  {NULL}
]

#define WORD_SIZE 9
static const Int dpi_list[] =
  { WORD_SIZE - 1, 100, 200, 300, 400, 500, 600, 700, 800 ]

static Sane.Option_Descriptor word_array_opt = {
  Sane.NAME_SCAN_RESOLUTION,
  Sane.TITLE_SCAN_RESOLUTION,
  Sane.DESC_SCAN_RESOLUTION,
  Sane.TYPE_INT,
  Sane.UNIT_DPI,
  sizeof (Sane.Word) * WORD_SIZE,
  100,
  Sane.CONSTRAINT_WORD_LIST,
  {NULL}
]

static const Sane.String_Const string_list[] = {
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_HALFTONE,
  Sane.VALUE_SCAN_MODE_GRAY,
  "linelength",
  0
]

static Sane.Option_Descriptor string_array_opt = {
  Sane.NAME_SCAN_MODE,
  Sane.TITLE_SCAN_MODE,
  Sane.DESC_SCAN_MODE,
  Sane.TYPE_STRING,
  Sane.UNIT_NONE,
  8,
  0,
  Sane.CONSTRAINT_STRING_LIST,
  {NULL}
]


/******************************/
/* start of tests definitions */
/******************************/

/*
 * constrained Int
 */
static void
min_int_value (void)
{
  Int value = int_range.min
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == int_range.min)
}

static void
max_int_value (void)
{
  Int value = int_range.max
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == int_range.max)
}

static void
below_min_int_value (void)
{
  Int value = int_range.min - 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == int_range.min)
}

/* rounded to lower value */
static void
quant1_int_value (void)
{
  Int value = int_range.min + 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == int_range.min)
}

/* rounded to higher value */
static void
quant2_int_value (void)
{
  Int value = int_range.min + int_range.quant - 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == int_range.min + int_range.quant)
}

static void
in_range_int_value (void)
{
  Int value = int_range.min + int_range.quant
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == int_range.min + int_range.quant)
}

static void
above_max_int_value (void)
{
  Int value = int_range.max + 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&int_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == int_range.max)
}

/*
 * constrained fixed value
 */
static void
min_fixed_value (void)
{
  Int value = fixed_range.min
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == fixed_range.min)
}

static void
max_fixed_value (void)
{
  Int value = fixed_range.max
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == fixed_range.max)
}

static void
below_min_fixed_value (void)
{
  Int value = fixed_range.min - 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == fixed_range.min)
}

/* rounded to lower value */
static void
quant1_fixed_value (void)
{
  Int value = fixed_range.min + fixed_range.quant/3
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == fixed_range.min)
}

/* rounded to higher value */
static void
quant2_fixed_value (void)
{
  Int value = fixed_range.min + fixed_range.quant - fixed_range.quant/3
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == fixed_range.min + fixed_range.quant)
}

static void
in_range_fixed_value (void)
{
  Int value = fixed_range.min + fixed_range.quant
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == fixed_range.min + fixed_range.quant)
}

static void
above_max_fixed_value (void)
{
  Int value = fixed_range.max + 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&fixed_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == fixed_range.max)
}


static void
above_max_word (void)
{
  Sane.Word value = 25000
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&word_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == 800)
}


static void
below_max_word (void)
{
  Sane.Word value = 1
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&word_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == 100)
}

static void
closest_200_word (void)
{
  Sane.Word value = 249
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&word_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == 200)
}


static void
closest_300_word (void)
{
  Sane.Word value = 251
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&word_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  assert (value == 300)
}


static void
exact_400_word (void)
{
  Sane.Word value = 400
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&word_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  assert (value == 400)
}

/*
 * constrained Int array
 */
static void
min_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min
    }
  status = sanei_constrain_value (&array_opt, value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.min)
    }
}

static void
max_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.max
    }

  status = sanei_constrain_value (&array_opt, value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.max)
    }
}

static void
below_min_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min - 1
    }

  status = sanei_constrain_value (&array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.min)
    }
}

/* rounded to lower value */
static void
quant1_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min + 1
    }
  status = sanei_constrain_value (&array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.min)
    }
}

/* rounded to higher value */
static void
quant2_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min + int_range.quant - 1
    }
  status = sanei_constrain_value (&array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.min + int_range.quant)
    }
}

static void
in_range_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min + int_range.quant
    }

  status = sanei_constrain_value (&array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.min + int_range.quant)
    }
}

static void
above_max_int_array (void)
{
  Int value[ARRAY_SIZE]
  Sane.Word info = 0
  Sane.Status status
  var i: Int

  for (i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.max + 1
    }
  status = sanei_constrain_value (&array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == Sane.INFO_INEXACT)
  for (i = 0; i < ARRAY_SIZE; i++)
    {
      assert (value[i] == int_range.max)
    }
}

static void
wrong_string_array (void)
{
  Sane.Char value[9] = "wrong"
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&string_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_INVAL)
  assert (info == 0)
}


static void
none_int (void)
{
  Int value = 555
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&none_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
}


static void
none_bool_nok (void)
{
  Bool value = 555
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&none_bool_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_INVAL)
  assert (info == 0)
}


static void
none_bool_ok (void)
{
  Bool value = Sane.FALSE
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&none_bool_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
}

/**
 * several partial match
 */
static void
string_array_several (void)
{
  Sane.Char value[9] = "Line"
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&string_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_INVAL)
  assert (info == 0)
}

/**
 * unique partial match
 */
static void
partial_string_array (void)
{
  Sane.Char value[9] = "Linea"
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&string_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
}

static void
string_array_ignorecase (void)
{
  Sane.Char value[9] = "lineart"
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&string_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
}

static void
string_array_ok (void)
{
  Sane.Char value[9] = "Lineart"
  Sane.Word info = 0
  Sane.Status status

  status = sanei_constrain_value (&string_array_opt, &value, &info)

  /* check results */
  assert (status == Sane.STATUS_GOOD)
  assert (info == 0)
}

/**
 * run the test suite for sanei constrain related tests
 */
static void
sanei_constrain_suite (void)
{
  /* to be compatible with pre-C99 compilers */
  int_opt.constraint.range = &int_range
  fixed_opt.constraint.range = &fixed_range
  array_opt.constraint.range = &int_range
  word_array_opt.constraint.word_list = dpi_list
  string_array_opt.constraint.string_list = string_list

  /* tests for constrained Int value */
  min_int_value ()
  max_int_value ()
  below_min_int_value ()
  above_max_int_value ()
  quant1_int_value ()
  quant2_int_value ()
  in_range_int_value ()

  /* tests for sane fixed constrained value */
  min_fixed_value ()
  max_fixed_value ()
  below_min_fixed_value ()
  above_max_fixed_value ()
  quant1_fixed_value ()
  quant2_fixed_value ()
  in_range_fixed_value ()

  /* tests for constrained Int array */
  min_int_array ()
  max_int_array ()
  below_min_int_array ()
  above_max_int_array ()
  quant1_int_array ()
  quant2_int_array ()
  in_range_int_array ()

  /* tests for word lists */
  above_max_word ()
  below_max_word ()
  closest_200_word ()
  closest_300_word ()
  exact_400_word ()

  /* tests for string lists */
  wrong_string_array ()
  partial_string_array ()
  string_array_ok ()
  string_array_ignorecase ()
  string_array_several ()

  /* constraint none tests  */
  none_int ()
  none_bool_nok ()
  none_bool_ok ()
}

/**
 * main function to run the test suites
 */
func Int main (void)
{
  /* run suites */
  sanei_constrain_suite ()

  return 0
}

/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */
