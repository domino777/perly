#!/usr/bin/perl
#perly.pl
#
#  "Copyright 2013 Mauro Ghedin"
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  or any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#	@author		: Mauro Ghedin
#	@contact	: domyno88 at gmail dot com
#	@version 	: 3.0-beta-1

# TODO
#	Aggiungere le chiavi da rimuovere da file txt esterno .lst
#	Gestire erro (fatto) -- gestire u' errori
#	Aggiungere lista estensioni da controllare in .cfg
#	Scrivere man
#	deafult da .cfg?
#	LOG?

use warnings;
use strict;

my $hlpMsg =<< "HELPMSG"
usage: perly [OPTION]... [PATH] [DESTINATION_PATH]

option:
	-s 			: print result, no action are taken
	-l			: work only on given PATH
	-c			: make a renamed copy of file from PATH to DESTINATION_PATH. Files on PATH are not renamed
	-d			: rename also the folder
	-R			: recursive, file on folder or subfolder are processed

	-v			: software version
	--help			: print this message

example:
	perly -l /home/user/Movie/	: all file name are ranamed on /home/user/Movie

	perly /home/user/Movie
	or
	perly /home/user/Movie .	: all file are moved and renamed on the execution path of the script

	perly [-Rdl /home/user/xxx | -Rdc /home/user/xxx /media/disk/yyy] 

HELPMSG
;

my $versionNoMsg =<< "VRSNOMSG"
perly 3.0-beta-1

Copyright (C) 2013 Mauro Ghedin.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Mauro Ghedin
VRSNOMSG
;

my $simEn, my $makeCp, my $doLocal, my $alsoDir, my $recursive;

#----------------------------------------------------------------------------
# ARGUMENT DETECTION
#---------------------------------------------------------------------------

while (defined $ARGV[0] && $ARGV[0] =~ m/^-/g) {
	$_ = shift @ARGV;;

	if(/^--help/) {
		print $hlpMsg;
		exit 0;
	}
	elsif(/^-[a-zA-Z]+/) {

		foreach my $arg (m/([a-zA-Z])/g) {

	# print help message
			if($arg =~ /v/) {
				print $versionNoMsg;
				exit 0;
			}
	# simulation mode
			elsif ($arg =~ /s/) {	
				$simEn++;
				next;
			}
	# copy mode
			elsif($arg =~ /c/) {
				$makeCp++;
				next;
			}
	# work only on given directory
			elsif($arg =~ /l/) {
				$doLocal++;	
				next;	
			}
	# rename folder
			elsif($arg =~ /d/) {
				$alsoDir++;
				next;
			}
	# recursive mode
			elsif($arg =~ /R/) {
				$recursive++;
				next;
			}
	# cmd err message
			else {
				die "perly: invalid option -- \'$_'\nTry \'perly --help\' for more information.\n";
			}
		}
	}
}	

#print $#ARGV; # get array size - 1 || last postion used on array

#-------------------------------------------------------------------------------------------------------------
#	Saving PATH and DESTINATION_PATH
#-------------------------------------------------------------------------------------------------------------
my $PATH, my $DESTINATION_PATH;

$PATH = (defined $ARGV[0] ? shift @ARGV : die "Path not defined");
$PATH =~ s/([^\/])$/$1\//;

print "SOURCE:\t$PATH\n";

$DESTINATION_PATH = ($doLocal ? (defined $ARGV[0] ? die "Unknow command \"".(shift @ARGV)."\"": $PATH) :  (defined $ARGV[0] ? shift @ARGV : die "Destination path not defined"));
$DESTINATION_PATH =~ s/([^\/]$)/$1\//;

print "DESTINATION:\t$DESTINATION_PATH\n\n\n";
sleep(2);


#print "$PATH  $DESTINATION_PATH";
#if ($doLocal) {
#	$DESTINATION_PATH = $PATH;
#}
#else {
#	$DESTINATION_PATH =
#}
	
#
#	Pattern of strings to remove from file name
#	The removing order follows the orded of data into the array

my @rmKeys = (
		"ITA-ENG", "BRRip", "DVDRip", "BDRip", "1080p", "720p", "x264", "Xvid-", "TRL", "IDN_CREW", 
		"DLMux", "AT0MiC", "DD5", "h264-", "DarkSideMux", "BluRayRip", "T4P3", "iTALIAN", "Wind166", 
		"bluray", "AC3" ,"[.]MD[.]", "[.]DD[.]", "2012", "2010", "2011", "[.][.]1[.][.]", 
		"[.][.]5[.]1[.][.]", "EXTENDED", "EnG", "iTA", "-TrTd_TeaM", "2007", "EDiTiON", "_MD",
		"UNRATED", "RERiP", "LiMiTED", "BrRiP", "XviD-", "LiAN", "_AAC[.]5[.]1[.]", "iDN_CreW",
		"BDrip", "eNGBrRip", "TrTd_TeaM", "5[.]1", "2008", "AAC", "[_]"
);

#-------------------------------------------------------------------------------------------------------------
# 	SUB:	Delete given keys on a given string
#-------------------------------------------------------------------------------------------------------------

sub deleteKey (\@$) {			# keys array and string are referenced
	my $keys = shift;
	my $string = shift;
	
	foreach my $key (@$keys){
		$string =~ s/$key//g
	}
	$string;
	#print "$_\n";
}

#-------------------------------------------------------------------------------------------------------------
#	SUB:	Complete cleaning name
#-------------------------------------------------------------------------------------------------------------


sub clearName(\@$$) {
	my $keys = shift;
	my $string = shift;
	my $ext = shift || "";

	$string = deleteKey(@$keys, $string);

	#print "$_\n";
	$string =~ s/[.]/ /g; 					# Remove point
	$string =~ s/^ - |^-|\[.*\]|\(.*\)|\s[.]|$ext$//g; 	# Remove -, [*], (*), string., file extension
	$string =~ s/ +/ /g;					# Replace multiple space
	$string =~ s/ $//g;					# Remove space at the end of the line
	$string =~ s/^[^a-zA-Z0-9]*//;					# Remove space at the start of the line
	$string =~ s/[^a-zA-Z0-9]*$//;					# Remove space at the start of the line
	$string =~ s/ \//\//g;					# Remove in front of /
	$string;
}

#-------------------------------------------------------------------------------------------------------------
#	SUB:	Get file extension
#-------------------------------------------------------------------------------------------------------------

sub getFileExt($) {
	my $ext = shift;

	$ext =~ /(.*)[.](.+)$/;
	return $2;
}

#-------------------------------------------------------------------------------------------------------------
#	SUB:	folder navigation
#-------------------------------------------------------------------------------------------------------------
sub lsFolder {
	my $path = shift;
	my $recursive = shift || 0;
	my @files;

	$path =~ s/[\ \[\]]/[(\\\ )(\\\[)(\\\])]/g;
	$path =~ s/([^\/]$)/$1\//;

	foreach my $file (glob("$path*")) {
		if (-f $file) {
			push @files, $file; 
		}
		elsif (-d $file) { 
			push @files, $file;
			if ($recursive) {
				push @files, lsFolder($file, $recursive); 
			}
		}
	}
	return @files;
}
#-------------------------------------------------------------------------------------------------------------
#	SUB:	move command
#-------------------------------------------------------------------------------------------------------------
sub mvCmd {
	my $file = shift;
	my $destination = shift;

	system("mv", "$file", "$destination");
}

#-------------------------------------------------------------------------------------------------------------
#	SUB:	copy command
#-------------------------------------------------------------------------------------------------------------
sub cpCmd {
	my $file = shift;
	my $destination = shift;

	-d $file ? system("mkdir", "$destination") : system("cp", "$file", "$destination");
}

#
#

my @vdFile;

die "$PATH is not a folder" if !(-d $PATH);
die "Folder reading is not allowed" if !(-r $PATH);
die "Folder writing is not allowed" if ((!(-w $PATH) && ($doLocal)) || ((!$doLocal) && !(-w $DESTINATION_PATH))) ;

my @fileTree = lsFolder($PATH, $recursive); # $recursive : recursive mode selected
my $fName;

if($doLocal && $alsoDir && !$makeCp) {					# reversing order array
	@fileTree = reverse @fileTree;
}

foreach (@fileTree) {
# String data preparation
	s/\/$//;

	my $ext = (-f $_ ? getFileExt($_) : "");

		
	my $fileOnPATH = $_;			# fileOnPATH		:	File or folder inside PATH
	$fileOnPATH =~ s/($PATH)//;

	if( -d && !$alsoDir) {
			$fName = $fileOnPATH;
	}
	elsif( -f && (!$alsoDir || ($alsoDir && !$makeCp && $doLocal))) {
			$fileOnPATH =~ /(.*\/)(.*)$/;
			my $fileName = (defined $2 ? $2 :  $fileOnPATH);
			my $filePath = (defined $2 ? $1 : "");
			$fName = clearName(@rmKeys, $fileName, $ext);
			$fName = $filePath.$fName;	
	}
	else {
			$fName = clearName(@rmKeys, $fileOnPATH, $ext);		
	}

	my $destination = "$DESTINATION_PATH$fName";
	$destination .= ".$ext" unless !$ext;
	
	print "From::\t$_\n";
	print "To::\t$destination\n\n";

	if	($makeCp && !$simEn) {
		cpCmd($_, $destination);
	}
	elsif	(!$makeCp && !$simEn) {
		mvCmd($_, $destination);
	}
}
