#!/usr/bin/perl -w

# Creates an USB device list from the description file
#
# epson2usb.pl doc/descriptions/epson2.desc
#
# Copyright (C) 2010 Tower Technologies
# Author: Alessandro Zummo <a.zummo@towertech.it>
#
# This file is part of the SANE package.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, version 2.

use strict;
use warnings;

	my %ids;
	my @models;
	my $i = 0;

	while (<>) {

		my $flip = /^:model/ ... /^$/;

		$models[$i]{$1} = $2
			if /^:(\w+)\s+(.+)/;

		$i++
			if $flip =~ /E0$/;
	}

	foreach my $m (@models) {

		next unless defined $m->{'usbid'};
		next if $m->{'status'} eq ':unsupported';

#		print $m->{'model'} , "\n";
#		print "-", $m->{'usbid'} , "-\n";

		next unless $m->{'usbid'} =~ /"0x04b8"\s+"(0x[[:xdigit:]]+)"/;

		my $id = $1;

#		print $id, "\n";

		$id =~ s/0x0/0x/;

		$m->{'model'} =~ s/;.+$//;
		$m->{'model'} =~ s/\"//g;
		$m->{'model'} =~ s/\s+$//;

		push(@{$ids{$id}}, $m->{'model'});
	}

	foreach (sort keys %ids) {
		print '  ', $_, ', /* ';
		print join(', ', @{$ids{$_}});
		print " */\n";
	}
