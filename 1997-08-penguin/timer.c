extern int realtimer;

void my_timer () {
  realtimer++;
}

void timer_on () {
  install_timer ();
  install_int (my_timer,16);
}
