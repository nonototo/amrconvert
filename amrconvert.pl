#!/usr/local/bin/perl
# @(#)amrconvert,v 0.2 05/12/2003 (c) Xabi Vazquez Gallardo <amr(@)xa.bi>
#
# Copyright (c) 2002,2003 XaBier Vazquez Gallardo
# All rights reserved.
# Redistribution and use of this source is permitted
# provided that this notice is preserved and that due credit is given
# to Xabier Vazquez Gallardo
#
# ------------------------------------------------------------------------------
# I am not responsible and should not be held responsible for any harm or
# damages caused by this script any complaints received resulting from the use
# of these scripts will be ignored ! Use at your own risk !
# ------------------------------------------------------------------------------
# 
# More Info at    http://xa.bi/mms/
# Needed Files:
# timidity        http://www.onicos.com/staff/iz/timidity/dist/download.html Program
#                 http://www.stardate.bc.ca/eawpatches/eawpats12_full.rar    Patches
# sox             http://sox.sourceforge.net/
# lame            http://lame.sourceforge.net/
# mpg123          http://www.mpg123.de/
# Encoder decoder ftp://ftp.3gpp.org/Specs/latest/Rel-5/26_series/26104-500.zip
#                 Compile with these changes:
#                   - makefile without -DETSI
#                   - add #include "sp_dec.h" to decoder.c
# Change paths of encoder & decoder acording to your needs.

my $ENCODEMODE = "MR475"; # MR475||MR515||MR59||MR67||MR74||MR795||MR102||MR122||-modefile=/home/xvazquez/am2/allmodes.txt
my $ENCODER = "/home/xvazquez/am2/encoder";
my $DECODER = "/home/xvazquez/am2/decoder";
my %hModes = (
  "0000" => { Type => "4.75", Header => 4, Frame => 95 , Stuff => 5, Bytes => 13, Code => '00000100' },
  "0001" => { Type => "5.15", Header => 4, Frame => 103, Stuff => 5, Bytes => 14, Code => '00001100' },
  "0010" => { Type => "5.90", Header => 4, Frame => 118, Stuff => 6, Bytes => 16, Code => '00010100' },
  "0011" => { Type => "6.70", Header => 4, Frame => 134, Stuff => 6, Bytes => 18, Code => '00011100' },
  "0100" => { Type => "7.40", Header => 4, Frame => 148, Stuff => 0, Bytes => 19, Code => '00100100' },
  "0101" => { Type => "7.95", Header => 4, Frame => 159, Stuff => 5, Bytes => 21, Code => '00101100' },
  "0110" => { Type => "10.2", Header => 4, Frame => 204, Stuff => 0, Bytes => 26, Code => '00110100' },
  "0111" => { Type => "12.2", Header => 4, Frame => 244, Stuff => 0, Bytes => 31, Code => '00111100' },
  "1000" => { Type => "SID8", Header => 4, Frame => 39 , Stuff => 5, Bytes => 6 , Code => '01000100' },
  "1001" => { Type => "SID9", Header => 4, Frame => 43 , Stuff => 1, Bytes => 6 , Code => '01001100' },
  "1010" => { Type => "SIDA", Header => 4, Frame => 38 , Stuff => 6, Bytes => 6 , Code => '01010100' },
  "1011" => { Type => "SIDB", Header => 4, Frame => 37 , Stuff => 7, Bytes => 6 , Code => '01011100' },
  "1100" => { Type => "ERRO", Header => 0, Frame => 0  , Stuff => 0, Bytes => 0 , Code => '01100100' },
  "1101" => { Type => "ERRO", Header => 0, Frame => 0  , Stuff => 0, Bytes => 0 , Code => '01101100' },
  "1110" => { Type => "ERRO", Header => 0, Frame => 0  , Stuff => 0, Bytes => 0 , Code => '01110100' },
  "1111" => { Type => "NDAT", Header => 4, Frame => 0  , Stuff => 4, Bytes => 1 , Code => '01111100' }
);
my @aTmpFiles;
my $READING_HEADER = 0;
my $WAITING_HEADER = 1;
my $READING_BITS   = 2;
  
sub char2bin {
  my $sBinary = unpack("B32", pack("N", shift));
  $sBinary =~ s/^........................//;
  return $sBinary;
}
  
sub bin2dec {
  return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub readFile {
  open(IN, shift);
  my $sRes = "";
  while ($sLine = <IN>) {
    $sRes .= $sLine;
  }
  close(IN);
  return($sRes);
}

sub delete_temp_files {
  while (my $sFilename = pop(@aTmpFiles)) {
    unlink($sFilename);
  }
}

sub show_error {
  delete_temp_files();
  print "Error: " . $_[0] . "\n\n";
  exit;
}

sub amr_2_if2 {
  my $sTmp          = readFile($_[0]);
  my $sStatus       = $READING_HEADER;
  my $sOutputStream = "";
  open OUT, ">" . $_[1];
  foreach my $iChar (unpack('C*', $sTmp)) {
    if ($sStatus == $READING_HEADER) {
      if (chr($iChar) eq "\n") {
        die("Bad Header.") unless ($sOutputStream =~ /^#!AMR/);
        $sStatus = $WAITING_HEADER;
      }
      $sOutputStream .= chr($iChar);
    } elsif ($sStatus == $WAITING_HEADER) {
      my ($sBinaryType) = (char2bin($iChar) =~ /.(....).../);
      $hMode = $hModes{$sBinaryType};
      die("Bad Data Block") if ($hMode->{Type} eq "ERRO");
      unless ($hMode->{Type} eq "NDAT") {
        $sOutputStream = reverse($sBinaryType);
        $sStatus = $READING_BITS;
      }
    } elsif ($sStatus == $READING_BITS) {
      my $sTmp = char2bin($iChar); 
      if (length($sOutputStream) + 8 >= ($hMode->{Frame} + $hMode->{Header})) {
        $sOutputStream .= substr($sTmp, 0, ($hMode->{Frame}+$hMode->{Header}) - length($sOutputStream));
        $sOutputStream .= substr("00000000", 0, $hMode->{Stuff});
        $sStatus = $WAITING_HEADER;
        my @aData = $sOutputStream =~ m/(........)/g;
        foreach my $sByte (@aData) {
          $sByte = reverse($sByte);
          print OUT chr(bin2dec($sByte));
        }
      } else {
        $sOutputStream .= $sTmp;
      }
    }
  }
  close(OUT);
}

sub if2_2_amr {
  my $sTmp          = readFile($_[0]);
  my $sStatus       = $WAITING_HEADER;
  my $sOutputStream = "";
  my $iReadedBytes  = 1;
  open OUT, ">" . $_[1];
  print OUT "#!AMR\n";
  foreach my $iChar (unpack('C*', $sTmp)) {
    if ($sStatus == $WAITING_HEADER) {
      $iReadedBytes = 1;
      my ($sInitStream, $sBinaryType) = (char2bin($iChar) =~ /(....)(....)/);
      $hMode = $hModes{$sBinaryType};
      die("Bad Data Block") if ($hMode->{Type} eq "ERRO");
      unless ($hMode->{Type} eq "NDAT") {
        $sOutputStream = reverse($sInitStream);
        $sStatus = $READING_BITS;
      }
    } elsif ($sStatus == $READING_BITS) {
      $sOutputStream .= reverse(char2bin($iChar));
      $iReadedBytes++;
      if ($iReadedBytes >= $hMode->{Bytes}) {
        $sOutputStream .= "00000000";
        my @aData = $sOutputStream =~ m/(........)/g;
        my $iBitsCount = $hMode->{Frame};
        my $iCount = 0;
        print OUT chr(bin2dec($hMode->{Code}));
        while ($iBitsCount > 0) {
          print OUT chr(bin2dec($aData[$iCount]));
          $iCount++;
          $iBitsCount = $iBitsCount - 8;
        }
        $sStatus = $WAITING_HEADER;
      }
    }
  }
  close(OUT);
}

my $sInputFile = $ARGV[0] || show_error("Must give an input file.");
my $sOutFile   = $ARGV[1] || show_error("Must give an output file.");
-f $sInputFile || show_error("[" . $sInputFile . "] does not exist.");
my ($sInType)  = ($sInputFile =~ /.*\.(.*)/);
my ($sOutType) = ($sOutFile =~ /.*\.(.*)/);
$sInType = uc($sInType);
$sOutType = uc($sOutType);
$sInType ne $sOutType || show_error("Filetypes must be diferent.");
$sInType eq "MID" || $sInType eq "MP3" || $sInType eq "WAV" || $sInType eq "AMR" || show_error("[." . $sInType . "] Unkown type.");
$sOutType eq "MP3" || $sOutType eq "WAV" || $sOutType eq "AMR" || show_error("[." . $sOutType . "] Unkown type.");

my $sCommand;
if      ($sInType eq "MID") {
  if ($sOutType eq "MP3") {
    push(@aTmpFiles, "/tmp/file_$$.wav");
    $sCommand = "timidity -E WPVSTO -EFdelay=0 -EFreverb=0 -EFchorus=0 -Ow8M -A 100 -o /tmp/file_$$.wav $sInputFile >/dev/null";
    system($sCommand) == 0 || show_error("System error.");
    $sCommand = "lame /tmp/file_$$.wav $sOutFile --silent";
    system($sCommand) == 0 || show_error("System error.");
  } elsif ($sOutType eq "WAV") {
    $sCommand = "timidity -E WPVSTO -EFdelay=0 -EFreverb=0 -EFchorus=0 -Ow8M -A 100 -o $sOutFile $sInputFile >/dev/null";
    system($sCommand) == 0 || show_error("System error.");
  } elsif ($sOutType eq "AMR") {
    push(@aTmpFiles, "/tmp/file_$$.wav");
    $sCommand = "timidity -E WPVSTO -EFdelay=0 -EFreverb=0 -EFchorus=0 -Ow8M -A 100 -o /tmp/file_$$.wav $sInputFile >/dev/null";
    system($sCommand) == 0 || show_error("System error.");
    push(@aTmpFiles, "/tmp/file_$$.raw");
    $sCommand = "sox -t wav /tmp/file_$$.wav -r 8000 -w -c 1 /tmp/file_$$.raw";
    system($sCommand) == 0 || show_error("System error.");
    push(@aTmpFiles, "/tmp/file_$$.if2");
    $sCommand = $ENCODER . " -dtx " . $ENCODEMODE . " /tmp/file_$$.raw /tmp/file_$$.if2 >/dev/null 2>&1";
    system($sCommand) == 0 || show_error("System error.");
    if2_2_amr("/tmp/file_$$.if2", $sOutFile);
  }
} elsif ($sInType eq "MP3") {
  if ($sOutType eq "WAV") {
    $sCommand = "mpg123 --quiet $sInputFile -w $sOutFile";
    system($sCommand) == 0 || show_error("System error.");
  } elsif ($sOutType eq "AMR") {
    push(@aTmpFiles, "/tmp/file_$$.raw");
    $sCommand = "mpg123 --quiet $sInputFile -w - | sox -t wav - -r 8000 -w -c 1 /tmp/file_$$.raw 2>/dev/null";
    system($sCommand) == 0 || show_error("System error.");
    push(@aTmpFiles, "/tmp/file_$$.if2");
    $sCommand = $ENCODER . " -dtx " . $ENCODEMODE . " /tmp/file_$$.raw /tmp/file_$$.if2 >/dev/null 2>&1";
    system($sCommand) == 0 || show_error("System error.");
    if2_2_amr("/tmp/file_$$.if2", $sOutFile);
  }
} elsif ($sInType eq "WAV") {
  if ($sOutType eq "MP3") {
    $sCommand = "lame $sInputFile $sOutFile --silent";
    system($sCommand) == 0 || show_error("System error.");
  } elsif ($sOutType eq "AMR") {
    push(@aTmpFiles, "/tmp/file_$$.raw");
    $sCommand = "sox -t wav $sInputFile -r 8000 -w -c 1 /tmp/file_$$.raw";
    system($sCommand) == 0 || show_error("System error.");
    push(@aTmpFiles, "/tmp/file_$$.if2");
    $sCommand = $ENCODER . " -dtx " . $ENCODEMODE . " /tmp/file_$$.raw /tmp/file_$$.if2 >/dev/null 2>&1";
    system($sCommand) == 0 || show_error("System error.");
    if2_2_amr("/tmp/file_$$.if2", $sOutFile);
  }
} elsif ($sInType eq "AMR") {
  if ($sOutType eq "WAV") {
    push(@aTmpFiles, "/tmp/file_$$.if2");
    amr_2_if2($sInputFile, "/tmp/file_$$.if2");
    push(@aTmpFiles, "/tmp/file_$$.raw");
    $sCommand = $DECODER . " /tmp/file_$$.if2 /tmp/file_$$.raw >/dev/null 2>&1";
    system($sCommand) == 0 || show_error("System error.");
    $sCommand = "sox -r 8000 -w -c 1 -s /tmp/file_$$.raw -r 16000 -w -c 1 $sOutFile >/dev/null 2>/dev/null";
    system($sCommand) == 0 || show_error("System error.");
  } elsif ($sOutType eq "MP3") {
    push(@aTmpFiles, "/tmp/file_$$.if2");
    amr_2_if2($sInputFile, "/tmp/file_$$.if2");
    push(@aTmpFiles, "/tmp/file_$$.raw");
    $sCommand = $DECODER . " /tmp/file_$$.if2 /tmp/file_$$.raw >/dev/null 2>&1";
    system($sCommand) == 0 || show_error("System error.");
    push(@aTmpFiles, "/tmp/file_$$.wav");
    $sCommand = "sox -r 8000 -w -c 1 -s /tmp/file_$$.raw -r 16000 -w -c 1 /tmp/file_$$.wav >/dev/null 2>/dev/null";
    system($sCommand) == 0 || show_error("System error.");
    $sCommand = "lame /tmp/file_$$.wav $sOutFile --silent";
    system($sCommand) == 0 || show_error("System error.");
  }
}

delete_temp_files();
