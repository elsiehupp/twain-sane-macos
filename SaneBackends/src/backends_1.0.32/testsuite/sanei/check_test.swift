import ../../include/sane/config

import stdlib
import sys/types
import sys/stat
import fcntl
import errno
import string
import assert

/* sane includes for the sanei functions called */
import ../../include/sane/sane
import ../../include/sane/saneopts
import ../../include/sane/sanei

/* range for constraint */
static const Sane.Range int_range = {
  3,				/* minimum */
  18,				/* maximum */
  3				/* quantization */
]

static Sane.Option_Descriptor int_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof(Sane.Word),
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
  sizeof(Sane.Word) * ARRAY_SIZE,
  0,
  Sane.CONSTRAINT_RANGE,
  {NULL}
]

static Sane.Option_Descriptor bool_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_BOOL,
  Sane.UNIT_MM,
  sizeof(Bool),
  0,
  Sane.CONSTRAINT_NONE,
  {NULL}
]

static Sane.Option_Descriptor bool_array_opt = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_BOOL,
  Sane.UNIT_MM,
  sizeof(Bool) * ARRAY_SIZE,
  0,
  Sane.CONSTRAINT_NONE,
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
  sizeof(Sane.Word) * WORD_SIZE,
  100,
  Sane.CONSTRAINT_WORD_LIST,
  {NULL}
]

/******************************/
/* start of tests definitions */
/******************************/

/*
 * constrained Int
 */
static void
min_int_value(void)
{
  Int value = int_range.min
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
  assert(value == int_range.min)
}


static void
max_int_value(void)
{
  Int value = int_range.max
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
  assert(value == int_range.max)
}


static void
below_min_int_value(void)
{
  Int value = int_range.min - 1
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


/* rounded to lower value */
static void
quant1_int_value(void)
{
  Int value = int_range.min + 1
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


/* close to higher value */
static void
quant2_int_value(void)
{
  Int value = int_range.min + int_range.quant - 1
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


static void
in_range_int_value(void)
{
  Int value = int_range.min + int_range.quant
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
  assert(value == int_range.min + int_range.quant)
}


static void
above_max_int_value(void)
{
  Int value = int_range.max + 1
  Sane.Status status

  status = sanei_check_value(&int_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


/*
 * constrained Int array
 */
static void
min_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min
    }
  status = sanei_check_value(&array_opt, value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
  for(i = 0; i < ARRAY_SIZE; i++)
    {
      assert(value[i] == int_range.min)
    }
}


static void
max_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.max
    }

  status = sanei_check_value(&array_opt, value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
  for(i = 0; i < ARRAY_SIZE; i++)
    {
      assert(value[i] == int_range.max)
    }
}


static void
below_min_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min - 1
    }

  status = sanei_check_value(&array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


/* rounded to lower value */
static void
quant1_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min + 1
    }
  status = sanei_check_value(&array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


/* rounded to higher value */
static void
quant2_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min + int_range.quant - 1
    }
  status = sanei_check_value(&array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


static void
in_range_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.min + int_range.quant
    }

  status = sanei_check_value(&array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
  for(i = 0; i < ARRAY_SIZE; i++)
    {
      assert(value[i] == int_range.min + int_range.quant)
    }
}


static void
above_max_int_array(void)
{
  Int value[ARRAY_SIZE]
  Sane.Status status
  var i: Int

  for(i = 0; i < ARRAY_SIZE; i++)
    {
      value[i] = int_range.max + 1
    }
  status = sanei_check_value(&array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


static void
bool_true(void)
{
  Bool value = Sane.TRUE
  Sane.Status status
  status = sanei_check_value(&bool_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
}


static void
bool_false(void)
{
  Bool value = Sane.FALSE
  Sane.Status status
  status = sanei_check_value(&bool_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
}


static void
wrong_bool(void)
{
  Bool value = 2
  Sane.Status status
  status = sanei_check_value(&bool_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


static void
bool_array(void)
{
  Bool value[ARRAY_SIZE]
  Sane.Status status
  var i: Int
  for(i = 0; i < ARRAY_SIZE; i++)
    value[i] = i % 2
  status = sanei_check_value(&bool_array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
}


static void
word_array_ok(void)
{
  Sane.Word value = 400
  Sane.Status status
  status = sanei_check_value(&word_array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_GOOD)
}


static void
word_array_nok(void)
{
  Sane.Word value = 444
  Sane.Status status
  status = sanei_check_value(&word_array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}

static void
wrong_bool_array(void)
{
  Bool value[ARRAY_SIZE]
  Sane.Status status
  var i: Int
  for(i = 0; i < ARRAY_SIZE; i++)
    value[i] = i % 2
  value[3] = 4
  status = sanei_check_value(&bool_array_opt, &value)

  /* check results */
  assert(status == Sane.STATUS_INVAL)
}


/**
 * run the test suite for sanei_check_value related tests
 */
static void
sanei_check_suite(void)
{
  /* to be compatible with pre-C99 compilers */
  int_opt.constraint.range = &int_range
  array_opt.constraint.range = &int_range
  word_array_opt.constraint.word_list = dpi_list

  /* tests for constrained Int value */
  min_int_value()
  max_int_value()
  below_min_int_value()
  above_max_int_value()
  quant1_int_value()
  quant2_int_value()
  in_range_int_value()

  /* tests for constrained Int array */
  min_int_array()
  max_int_array()
  below_min_int_array()
  above_max_int_array()
  quant1_int_array()
  quant2_int_array()
  in_range_int_array()

  /* tests for boolean value */
  bool_true()
  bool_false()
  wrong_bool()
  bool_array()
  wrong_bool_array()

  /* word array test */
  word_array_ok()
  word_array_nok()
}


func Int main(void)
{
  sanei_check_suite()
  return 0
}

/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */
