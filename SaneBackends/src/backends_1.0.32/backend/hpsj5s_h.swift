#ifndef __HPSJ5S_MIDDLE_LEVEL_API_HEADER__
#define __HPSJ5S_MIDDLE_LEVEL_API_HEADER__


import ieee1284

/*Scanner hardware registers*/
#define REGISTER_FUNCTION_CODE		0x70	/*Here goes function code */
#define REGISTER_FUNCTION_PARAMETER	0x60	/*Here goes function param */

#define ADDRESS_RESULT			0x20	/*Here we get result */

/*Scanner functions(not all - some of them I can't identify)*/
#define FUNCTION_SETUP_HARDWARE		0xA0

/*Scanner hardware control flags:*/
/*Set this flag and non-zero speed to start rotation*/
#define FLAGS_HW_MOTOR_READY		0x1
/*Set this flag to turn on lamp*/
#define FLAGS_HW_LAMP_ON		0x2
/*Set this flag to turn indicator lamp off*/
#define FLAGS_HW_INDICATOR_OFF		0x4


/*
        Types:
*/
/*Color modes we support: 1-bit Drawing, 2-bit Halftone, 8-bit Gray Scale, 24-bt True Color*/
typedef enum
{ Drawing, Halftone, GrayScale, TrueColor }
enumColorDepth

/*Middle-level API:*/

static Int OpenScanner(const char *scanner_path)

static void CloseScanner(Int handle)

static Int DetectScanner(void)

static void StandByScanner(void)

static void SwitchHardwareState(Sane.Byte mask, Sane.Byte invert_mask)

static Int CheckPaperPresent(void)

static Int ReleasePaper(void)

static Int PaperFeed(Sane.Word wLinesToFeed)

static void TransferScanParameters(enumColorDepth enColor,
				    Sane.Word wResolution,
				    Sane.Word wCorrectedLength)

static void TurnOnPaperPulling(enumColorDepth enColor,
				Sane.Word wResolution)

static void TurnOffPaperPulling(void)

static Sane.Byte GetCalibration(void)

static void CalibrateScanElements(void)

/*Internal-use functions:*/

static Int OutputCheck(void)
static Int InputCheck(void)
static Int CallCheck(void)
static void LoadingPaletteToScanner(void)

/*Low level warappers:*/

static void WriteAddress(Sane.Byte Address)

static void WriteData(Sane.Byte Data)

static void WriteScannerRegister(Sane.Byte Address, Sane.Byte Data)

static void CallFunctionWithParameter(Sane.Byte Function,
				       Sane.Byte Parameter)

static Sane.Byte CallFunctionWithRetVal(Sane.Byte Function)

static Sane.Byte ReadDataByte(void)

static void ReadDataBlock(Sane.Byte * Buffer, Int length)

/*Daisy chaining API: (should be moved to ieee1284 library in future)*/

/*Deselect all devices in chain on this port.*/
static void daisy_deselect_all(struct parport *port)

/*Select device with number 'daisy' in 'mode'.*/
static Int daisy_select(struct parport *port, Int daisy, Int mode)

/*Setup address for device in chain on this port*/
static Int assign_addr(struct parport *port, Int daisy)

/* Send a daisy-chain-style CPP command packet. */
static Int cpp_daisy(struct parport *port, Int cmd)

#endif
