use Device::BCM2835;
use warnings;
#use strict;
 
package GPIO;

#
# Called when object is created
#

use constant 	D0 => 	Device::BCM2835::RPI_GPIO_P1_03;	# SD
use constant 	D1 => 	Device::BCM2835::RPI_GPIO_P1_05;	# SC
use constant 	D2 => 	Device::BCM2835::RPI_GPIO_P1_07;	# 4
use constant 	D3 => 	Device::BCM2835::RPI_GPIO_P1_08;	# TXD
use constant 	D4 => 	Device::BCM2835::RPI_GPIO_P1_10;	# RXD
use constant 	D5 => 	Device::BCM2835::RPI_GPIO_P1_11;	# 17
use constant 	D6 => 	Device::BCM2835::RPI_GPIO_P1_12;	# 18
use constant 	D7 => 	Device::BCM2835::RPI_GPIO_P1_13;	# 21
#use constant 	XX => 	Device::BCM2835::RPI_GPIO_P1_12;
#use constant 	D7 => 	Device::BCM2835::RPI_GPIO_P1_16;
use constant 	OE => 	Device::BCM2835::RPI_GPIO_P1_18;	# pin 24
#use constant 	D7 => 	Device::BCM2835::RPI_GPIO_P1_19;	
#use constant 	D7 => 	Device::BCM2835::RPI_GPIO_P1_21;	
use constant 	LH => 	Device::BCM2835::RPI_GPIO_P1_22;	# 25
use constant 	LL => 	Device::BCM2835::RPI_GPIO_P1_23;	# SCLK
use constant 	WE => 	Device::BCM2835::RPI_GPIO_P1_24;	# CE0
use constant 	CS => 	Device::BCM2835::RPI_GPIO_P1_26;	# CE1

use constant	DELAY => .01;	# 10ms


sub new {
	my $class = shift;
	my $self = {};;		# The constructor
	bless $self, $class;

	$self->_init();

	return $self;
}

sub _init() {
	my $self = shift;
	#
	# Set up the GPIO ports - CS, WE, OE, High and low latch all output
	#
	print "Initializing\n";
	Device::BCM2835::init() 
 		|| die "Could not init library";
 

	$self->setGPIO(0);	# Data lines to output
	Device::BCM2835::gpio_fsel(&CS,    &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);	# CS  - 19
	$self->setCS(1);
	Device::BCM2835::gpio_fsel(&OE,    &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);	# OE - 13
	$self->setOE(1);
	Device::BCM2835::gpio_fsel(&WE,   &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);	# WE - todo
	$self->setWE(1);
	Device::BCM2835::gpio_fsel(&LH, 	&Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);	# High - 18
	$self->setHighLatch(0);
	Device::BCM2835::gpio_fsel(&LL, 	&Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);	# Low - 23
	$self->setLowLatch(0);
	#
	# Set initial states
	#
	$self->{lastHigh} = -1;

	return 1;
}

sub DESTROY()
{
 	my $self = shift;

	$self->setOE(0);			# Write protect the device
	$self->setCS(1);	
	$self->setWE(1);
}

#
# Program a byte to the chip
#
sub program() {
	my $self = shift;
	my $addr = shift;
	my $byte = shift;

	#
	# Write sequence is 5555H AAH 	2AAAH 55H 	5555H A0H <addr> <data>
	#
	$self->write (0x5555, 0xaa);
	$self->write (0x2aaa, 0x55);
	$self->write (0x5555, 0xa0);
	$self->write ($addr, $byte);

	return 1;
}

#
# Erase the chip
#
sub erase() {
	my $self = shift;

	#
	# Chip erase sequence is
	# 5555H AAH 	2AAAH 55H 	5555H 80H 	5555H AAH 	2AAAH 55H 	5555H 10H
	#

	$self->write (0x5555, 0xaa);
	$self->write (0x2aaa, 0x55);
	$self->write (0x5555, 0x80);
	$self->write (0x5555, 0xaa);
	$self->write (0x2aaa, 0x55);
	$self->write (0x5555, 0x10);

	sleep 1;
}

#
# Read the software id from the chip
#
sub printDeviceID()
{
	my $self = shift;
	#
	# Enter Software ID mode
	# 5555H AAH 	2AAAH 55H 	5555H 90H
	#
	$self->write (0x5555, 0xaa);
	$self->write (0x2aaa, 0x55);
	$self->write (0x5555, 0x90);

	#
	# read the ID
	#
	my $byte = $self->read(0x0000);
	printf  ("Manufactures ID: %02X\n", $byte);
	$byte = $self->read(0x0001);
	printf ("Device ID: %02X\n ", $byte);

	#
	# Reset from software ID mode
	# 5555H AAH 	2AAAH 55H 	5555H F0H
	$self->write (0x5555, 0xaa);
	$self->write (0x2aaa, 0x55);
	$self->write (0x5555, 0xf0);

}

#
# Write a byte to the chip 
sub write() {
	my $self = shift;
	my $addr = shift;
	my $byte = shift;
	#
	# Split the address to low and high bytes
	#
	my $high = int $addr /256;
	my $low = $addr - ($high * 256);
	#
	# Write the high address to the high latch
	#
	if ($high != $self->{lastHigh}) {
		$self->output($high);
		$self->setHighLatch(1);
		$self->setHighLatch(0);
		$self->{lastHigh} = $high;
	}
	#
	# Write the low address byte to the low latch
	#
	$self->output($low);
	$self->setLowLatch(1);
	$self->setLowLatch(0);
	#
	# Write the data byte out to the chip
	#
	$self->output($byte);
	$self->setCS(0);		# Address bus latched
	$self->setWE(0);
	$self->setWE(1);		# Databus latched
	$self->setCS(1);

	return 1;
}

#
# read a byte from the chip
sub read() {
	my $self = shift;
	my $addr = shift;
	#
	# Split the address to low and high bytes
	#
	my $high = int $addr /256;
	my $low = $addr - ($high * 256);
	#
	# Write the high address to the high latch
	#

	if ($high != $self->{lastHigh}) {
		$self->output($high);
		$self->setHighLatch(1);
		$self->setHighLatch(0);
		$self->{lastHigh} = $high;
	}
	#
	# Write the loiw address byte to the low latch
	#
	$self->output($low);
	$self->setLowLatch(1);
	$self->setLowLatch(0);
	#
	# Read the data byte out to the chip
	#
	$self->setGPIO(1);			# Read enable the data ports
	$self->setCS(0);
	$self->setOE(0);
	my $byte = $self->input();
	$self->setOE(1);
	$self->setCS(1);
	$self->setGPIO(0);			# Default to output

	return $byte;
}


sub setHighLatch() {
	my $self = shift;
	my $bool = shift;

	if ($bool) {
		Device::BCM2835::gpio_write(&LH, 1);
	}
	else {
		Device::BCM2835::gpio_write(&LH,  0);
	}
	select(undef,undef,undef, DELAY);
	return 1;
}

sub setLowLatch() {
	my $self = shift;
	my $bool = shift;

	if ($bool) {
		Device::BCM2835::gpio_write(&LL, 1);
	}
	else {
		Device::BCM2835::gpio_write(&LL, 0);
	}
	select(undef,undef,undef, DELAY);
	return 1;
}


sub setWE() {
	my $self = shift;
	my $bool = shift;

	if ($bool) {
		Device::BCM2835::gpio_write(&WE, 1);	# todo
	}
	else {
		Device::BCM2835::gpio_write(&WE, 0);
	}
	select(undef,undef,undef, DELAY);
	return 1;
}

sub setCS() {
	my $self = shift;
	my $bool = shift;

	if ($bool) {
		Device::BCM2835::gpio_write(&CS, 1);	# Port 19
	}
	else {
		Device::BCM2835::gpio_write(&CS, 0);
	}
	select(undef,undef,undef, DELAY);
	return 1;
}


sub setOE() {
	my $self = shift;
	my $bool = shift;

	if ($bool) {
		Device::BCM2835::gpio_write(&OE, 1);	# Port 13
	}
	else {
		Device::BCM2835::gpio_write(&OE, 0);
	}
	select(undef,undef,undef, DELAY);
	return 1;
}

sub input() {

	my $self = shift;

	my $byte = 0;
	if (Device::BCM2835::gpio_lev(&D7)) {
		$byte = $byte + 128; 	}
	if (Device::BCM2835::gpio_lev(&D6)) {
		$byte+=64; 	 }
	if (Device::BCM2835::gpio_lev(&D5)) {
		$byte+=32; 	}
	if (Device::BCM2835::gpio_lev(&D4)) {
		$byte+=16; 	}
	if (Device::BCM2835::gpio_lev(&D3)) {
		$byte+=8; 	}
	if (Device::BCM2835::gpio_lev(&D2)) {
		$byte+=4; 	}
	if (Device::BCM2835::gpio_lev(&D1)) {
		$byte+=2; 	}
	if (Device::BCM2835::gpio_lev(&D0)) {
		$byte+=1;	}
	return $byte;
}

sub output() {

	my $self = shift;
	my $byte = shift;
	my $bit = 0;

	$bit = (128 & $byte) / 128;
	Device::BCM2835::gpio_write(&D7, $bit);
	$bit =  (64 & $byte) / 64;
	Device::BCM2835::gpio_write(&D6, $bit);
	$bit = (32 & $byte) / 32;
	Device::BCM2835::gpio_write(&D5, $bit);
	$bit = (16 & $byte) / 16;
	Device::BCM2835::gpio_write(&D4, $bit);
	$bit = (8 & $byte) / 8;
	Device::BCM2835::gpio_write(&D3, $bit);
	$bit = (4 & $byte) / 4;
	Device::BCM2835::gpio_write(&D2, $bit);
	$bit = (2 & $byte) / 2;
	Device::BCM2835::gpio_write(&D1, $bit);
	$bit = (1 & $byte) / 1;
	Device::BCM2835::gpio_write(&D0, $bit);
	select(undef,undef,undef, DELAY);
#	sleep 1;
	return 1;
}

#
# Set the data bits as input = 1 or output = 0
#
sub setGPIO() {
	my $self = shift;
	my $bool = shift;



	my $direction;

         if ($bool) {
		$direction =  &Device::BCM2835::BCM2835_GPIO_FSEL_INPT;
	}
	else	{
		$direction = &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP;
	}

	#
	# set them
	#
	Device::BCM2835::gpio_fsel(&D7, $direction);
	Device::BCM2835::gpio_fsel(&D6, $direction);
	Device::BCM2835::gpio_fsel(&D5, $direction);
	Device::BCM2835::gpio_fsel(&D4, $direction);
	Device::BCM2835::gpio_fsel(&D3, $direction);
	Device::BCM2835::gpio_fsel(&D2, $direction);	
	Device::BCM2835::gpio_fsel(&D1, $direction);
	Device::BCM2835::gpio_fsel(&D0, $direction);

	return 1;
}


1;


