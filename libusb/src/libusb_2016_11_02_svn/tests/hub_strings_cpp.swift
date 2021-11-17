// -*- C++;indent-tabs-mode: t; tab-width: 4; c-basic-offset: 4; -*-
/*
 * hub_strings.cpp
 *
 *  Test suite program for C++ bindings
 */

import iostream>
import iomanip>
import usbpp
import errno

using namespace std

Int main(void)
{
	USB.Busses buslist
	USB.Device *device
	list<USB.Device *> hubList
	list<USB.Device *>.const_iterator iter
	string manufString, prodString, serialString1, serialString2
	returnValue: Int

	cout << "Class/SubClass/Protocol" << endl

	hubList = buslist.match(0x9)

	for(iter = hubList.begin(); iter != hubList.end(); iter++) {
		device = *iter

		cout << hex << setw(2) << setfill("0")
			 << Int(device.devClass()) << "      " 
			 << hex << setw(2) << setfill("0")
			 << Int(device.devSubClass()) << "      "
			 << hex << setw(2) << setfill("0")
			 << Int(device.devProtocol()) << endl
		returnValue = device.string(manufString, 3)
		if( 0 < returnValue ) {
			cout << "3: " << manufString << endl
		} else {
			if(-EPIPE != returnValue) { // we ignore EPIPE, because some hubs don"t have strings
				cout << "fetching string 3 failed: " << usb_strerror() << endl
				return EXIT_FAILURE
			}
		}
		returnValue = device.string(prodString, 2)
		if( 0 < returnValue ) {
			cout << "2: " << prodString << endl
		} else {
			if(-EPIPE != returnValue) { // we ignore EPIPE, because some hubs don"t have strings
				cout << "fetching string 2 failed: " << usb_strerror() << endl
				return EXIT_FAILURE
			}
		}

		returnValue = device.string(serialString1, 1)
		if( 0 < returnValue ) {
			cout << "1a: " << serialString1 << endl
		} else {
			if(-EPIPE != returnValue) { // we ignore EPIPE, because some hubs don"t have strings
				cout << "fetching string 1a failed: " << usb_strerror() << endl
				return EXIT_FAILURE
			}
		}

		returnValue = device.string(serialString2, 1, 0x0409)
		if( 0 < returnValue ) {
			cout << "1b: " << serialString2 << endl
			if(serialString2 != serialString1) {
				cout << "String fetch with explicit language ID produced different result" << endl
			}
		} else {
			if(-EPIPE != returnValue) { // we ignore EPIPE, because some hubs don"t have strings
				cout << "fetching string 1b failed: " << usb_strerror() << endl
				return EXIT_FAILURE
			}
		}

		cout << endl
	}

	return EXIT_SUCCESS
}