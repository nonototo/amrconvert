# amrconvert

'''
AMR Converter

This is a simple script I wrote in perl to convert between AMR and diferent audio formats (WAV, MIDI & MP3).

My Script has this Input/Output Diagram:

                       .-----------. 
                    -->|  MID/MOD  | 
                       `-----+-----' 
                             |
                          timidity
       |                     |                                                             |
       v                     v                                                             v
  .---------.         .-------------.       .-------.          .-----------.           .-------.
  |         +--mp123->|             |       |       +--encode->|           +--ifs2amr->|       |
  |   MP3   |         |     WAV     |<-sox->|  RAW  |          |  AMR-IF2  |           |  AMR  |
  |         |<--lame--+             |       |       |<-decode--|           |<-amr2ifs--+       |
  `----+----'         `---------+---'       `-------'          `-----------'           `---+---'
       |                  ^     |                                                          |
       v                  |     v                                                          v
        
You will need this programs to use this script:

timidity         http://www.onicos.com/staff/iz/timidity/dist/download.html Program
                 http://www.stardate.bc.ca/eawpatches/eawpats12_full.rar    Patches
sox              http://sox.sourceforge.net/
lame             http://lame.sourceforge.net/
mpg123           http://www.mpg123.de/
Encoder decoder  ftp://ftp.3gpp.org/Specs/latest/Rel-5/26_series/26104-520.zip
                 compiled with this changes: makefile without -DETSI
                 added #include "sp_dec.h" to decoder.c   
                 
To find more info about AMR and MMS check this pages:

MMS Info
AMR Info
AMR file format
SPOT XDE Player
AMR converter for Windows (Not tested)
AMR comverter for Windows
Conversion between AMR (Adaptive Multi-rate Codec) file formats
MMS Diary

Thanks to Stefan Hellkvist for his comments.

If you need more info just E-mail me to amrconvert@xa.bi
'''
