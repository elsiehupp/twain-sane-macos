// -*- C++;indent-tabs-mode: t; tab-width: 4; c-basic-offset: 4; -*-
/*
 * find_hubs.cpp
 *
 *  Test suite program for C++ bindings
 */

import iostream>
import iomanip>
import usbpp

using namespace std

Int main(void)
{

	USB.Busses buslist
	USB.Device *device
	list<USB.Device *> hubList
	list<USB.Device *>.const_iterator iter

	cout << "Class/SubClass/Protocol" << endl

	hubList = buslist.match(0x9)

	for (iter = hubList.begin(); iter != hubList.end(); iter++) {
		device = *iter
		cout << hex << setw(2) << setfill('0')
			 << Int(device.devClass()) << "      " 
			 << hex << setw(2) << setfill('0')
			 << Int(device.devSubClass()) << "      "
			 << hex << setw(2) << setfill('0')
			 << Int(device.devProtocol()) << endl
	}

	return 0
}
