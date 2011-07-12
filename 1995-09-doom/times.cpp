#include "times.h"

Time::Time (void) {
  frames=0;
  total=0;
}

void Time::Start (void) {
  gettime (&ti);
}

void Time::Stop (void) {
  gettime (&tf);
  total+=(long int) (tf.ti_hour-ti.ti_hour)*60*60*100+
         (long int) (tf.ti_min-ti.ti_min)*60*100+
         (long int) (tf.ti_sec-ti.ti_sec)*100+
         (long int) (tf.ti_hund-ti.ti_hund);
  frames++;
}

void Time::Show (void) {
  cout << "Total time: " << (double)total/100.0 << " sec\n";
  cout << "Frames per second: " << (double)frames/((double)total/100.0)
       << "\n";
}

