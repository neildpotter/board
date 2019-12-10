#!/usr/bin/perl

use gpio;

print "Dump \n";

my $interval = 0x10;	# 2 power result on each line

my $addr = 0;
my $stop = 0x0500;
{
my $gpio = GPIO->new();

	my $base = $addr & $interval;
	$base = 0;


while($addr <= $stop)
{

#	print "$base ";
	printf ("0x%04X: ", $addr);
	
	while ($addr < ($base + $interval)) {

		$byte = $gpio->read($addr);

		printf ("%02X ", $byte);
		$addr++;
	}
	print "\n";
#	$addr = $addr + $interval;
	$base = $addr;

}
}




