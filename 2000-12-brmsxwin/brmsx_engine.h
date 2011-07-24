unsigned char readmem (unsigned short addr);
void run_msx (unsigned int *z80time, unsigned int *vdptime,
              unsigned int *bordertime);

extern unsigned int scanline_value;
extern unsigned int tvborder_value;
extern unsigned int first_black_frame;
extern unsigned int draw_black_now;
extern unsigned int dont_draw_anymore;
extern unsigned int bright_value;


