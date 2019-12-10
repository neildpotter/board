#!/usr/bin/perl

use gpio;

	my $filename =  $ARGV[0];
	chomp $filename;

	#
	# Try openning the file
	#
	open( my $fh, '<', $filename ) or die "Can't open $filename: $!";

	#
	# Check that the first line came from the assembler
	#
	my $line = <$fh>;
	chomp $line;
	if ($line eq 'Z80ASM')
	{
		die "$filename is not Z80ASM\n";
	}
	close $fh;

	#
	# Open the file again in byte mode, and skip over the header
	#
my $headerSize = 8;
my $oneByte;
	open my $fh, "<:raw", $filename or die "Couldn't open $fileName!";

	for ($i = 0; $i < $headerSize; $i++)
	{
		my $bytes_read = read ($fh, $oneByte, 1) or die "Error reading $fileName!";
	}
	#
	# Read the address offset from the file
	#
	read($fh, $oneByte, 1) or die "Error reading $fileName!";
	my $addrLow = ord($oneByte);
	read($fh, $oneByte, 1) or die "Error reading $fileName!";
	my $addrHigh = ord($oneByte);
	my $startAddr = ($addrHigh * 256) + $addrLow;

	printf ("Program $filename, address offset 0x%04X\n", $addr);
	my $count = 0;
	my $addr = $startAddr;
	my $checksum = 0;
	#
	# Get control of the programmer and erase the chip
	#
	my $gpio = GPIO->new();
	print "Erasing chip\n";
	$gpio->erase();
	#
	# Read the file and program the chip one byte at a time to the end
	# 
	while (read $fh, $oneByte, 1)
	{
		my $byte = ord ($oneByte);
		if ($count /16 == int $count /16)	{
			printf ("Programming 0x%04X\n", $addr);
		}
		$gpio->program($addr, $byte);
		$addr++;
		$count++;
		$checkSum = $checkSum + $byte;

	}
	close $fh;
	print "Programming complete $count bytes written\n";
	#
	# Verify the program by reading and calculating the checksum
	#
	$addr = $startAddr;

	print "Verifying...\n";
	my $verify = 0;
	while ($count--)
	{
	        my $byte = $gpio->read($addr);
		$verify = $verify + $byte;
		$addr++
	}

	if ($checkSum == $verify) {
		print "Success!!!\n";
	}
	else {
		print "Program verification failure\n";
	}




