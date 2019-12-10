#!/usr/bin/perl

use gpio;

print "testing \n";




	print "Running the test program\n";

	my $gpio = GPIO->new();

	$gpio->erase();

	$byte = 0x00;
	$addr = 0x0000;

	while ($byte < 256)
	{
		printf ("0x%04X: %02X\n", $addr, $byte);
		$gpio->program($addr, $byte);
		$addr++;
		$byte++;
	}


