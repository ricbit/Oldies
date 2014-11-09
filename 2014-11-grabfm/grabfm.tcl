# MSX FM Basic to VGM converter, v1.0.
# Ricardo Bittencourt 2014

# Usage: copy your FM basic file to some dir, rename it to autoexec.bas,
# and start openmsx with this command line:
#
# ./openmsx -machine Panasonic_FS-A1GT -diska disk -script grabfm.tcl

set throttle off
set running 0
set psg_register 0
set fm_register 0
set ticks 0
set music_data ""

set file_handle [open "music.vgm" "w"]
fconfigure $file_handle -encoding binary

proc little_endian {value} {
  format "%c%c%c%c" [expr $value & 0xFF] \
                    [expr ($value >> 8) & 0xFF] \
                    [expr ($value >> 16) & 0xFF] \
                    [expr ($value >> 24) & 0xFF]
}

proc zeros {value} {
  string repeat "\0" $value
}

debug set_bp 0x4601 {$running == 0} {
  set running 1
  puts stderr "Start recording"

  debug set_watchpoint write_io 0x7C {} {
    set fm_register [reg A]
  }
  debug set_watchpoint write_io 0x7D {} {
    append music_data [format "%c%c%c" 0x51 $fm_register [reg A]]
  }
  debug set_watchpoint write_io 0xA0 {} {
    set psg_register [reg A]
  }
  debug set_watchpoint write_io 0xA1 {} {
    append music_data [format "%c%c%c" 0xA0 $psg_register [reg A]]
  }
  debug set_bp 0xFD9F {} {
    append music_data [format "%c" 0x62]
    set ticks [expr $ticks + 1]
  }
  debug set_bp 0xFF07 {} {
    debug set_condition {[expr [peek 0xFB3F] & 0x7F] == 0} {
      puts stderr "Stop recording"
      set header ""
      # VGM version 1.7
      append header [little_endian 0x160] 
      append header [zeros 4]
      # YM2413 clock
      append header [little_endian 3579545]
      append header [zeros 4]
      # Number of ticks
      append header [little_endian $ticks]
      append header [zeros 8]
      # Frequency of ticks
      append header [little_endian 60]
      append header [zeros 12]
      # Data starts at offset 0x100
      append header [little_endian 204]
      append header [zeros 60]
      # AY8910 clock
      append header [little_endian 1789750]
      # AY8910 flags
      append header [little_endian 0x00000100]
      append header [zeros 132]
      append header $music_data
      puts -nonewline $file_handle "Vgm "  
      puts -nonewline $file_handle \
        [little_endian [expr 4 + [string length $header]]]
      puts -nonewline $file_handle $header
      close $file_handle
      quit
    }
  }
}
