extern "C" void runZ80 (void);
extern "C" void resetZ80 (void);
extern "C" void stepZ80 (void);
extern "C" void readmem_asm (void);
extern "C" void z80_interrupt (void);
extern unsigned short regpc;
extern unsigned short regaf;
extern unsigned short regbc;
extern unsigned short regde;
extern unsigned short reghl;
extern unsigned short regsp;
extern unsigned short regix;
extern unsigned short regiy;
extern unsigned int iff1;
extern unsigned int breakpoint;
extern unsigned int stopped;
extern unsigned int mem[8];
extern unsigned int memlock[8];
extern unsigned int slot[4*16];
extern unsigned int idlerom;


