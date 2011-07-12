#include <dos.h>
#include <iostream.h>

class Time {
public:
  struct time ti,tf;
  int frames;
  long int total;

  Time (void);
  void Start (void);
  void Stop (void);
  void Show (void);
};

