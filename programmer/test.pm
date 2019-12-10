#!/usr/bin/perl

use gpio;

print "testing \n";




	print "Running the test program\n";

	my $gpio = GPIO->new();


#	$byte = $gpio->printDeviceID();

	$gpio->write(0x0008, 0x00);

