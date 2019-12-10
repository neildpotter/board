#!/usr/bin/perl

use constant	DELAY => .01;	# 10ms

my @hexLookup = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

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
	# Get the size of the data by reading through it
	#
	read($fh, $oneByte, 1) or die "Error reading $fileName!";			# skip start address
	read($fh, $oneByte, 1) or die "Error reading $fileName!";

my $size = 0;
		
	while (read($fh, $oneByte, 1))
	{
		$size++;
	}

	my $sizeh = int $size /256;
	my $sizel = $size - 256 * $sizeh;

my	$sizeString = sprintf ("%02X %02X ", $sizeh, $sizel);
	print "File is $sizeString bytes\n";
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

	printf ("Block load $filename, address offset 0x%04X\n", $addr);
	my $count = 0;
	my $addr = $startAddr;
	my $checksum = 0;

	#
	# Get a handle on the serial port
	# Output a B to get the board ready to receive
my $ttyPort = '/dev/ttyUSB0';

#	open( my $tfh, '>::encoding(utf8)', $ttyPort ) or die "Can't open $ttyPort $!";
	open( my $tfh, '>::raw', $ttyPort ) or die "Can't open $ttyPort $!";

	syswrite $tfh,"load\r";								# send the command to board

	sleep 1;
#
# Start block mode by resetting and then sending a B
#
	syswrite $tfh,'L';								# Start block mode
	#
	# Write the size of the load
	#
	syswrite $tfh,"$sizeString";			# Send the size 

	#
	# Read the file and write to the serial port
	# 
	while (read $fh, $oneByte, 1)
	{
		my $byte = ord ($oneByte);
		my $highNibble = $byte & 0xf0;
		$highNibble = $highNibble /16;

		my $lowNibble = $byte & 0x0f;
#		print "$highNibble, $lowNibble\n";
		# 
		# Convert to hex via lookup table
		#
		my $hichar = @hexLookup[$highNibble];
		my $lochar = @hexLookup[$lowNibble];
#		sleep 1;
#		print "$hichar $lochar   \n";
		syswrite $tfh,"$hichar$lochar ";			# Send the byte
		$count++;
#		select(undef,undef,undef, DELAY);
	}
	close $fh;
	syswrite $tfh,'Z';							# Terminator
	close $tfh;

	printf ("Block complete %04X bytes sent\n", $count);









