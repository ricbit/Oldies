int getchar ();
void putchar (int a);
char vpeek (int address);
void vpoke (int address, char value);
void fill_vram (int start_address, int size, char value);
void *malloc (int size);
char bdos (char function, int de, int hl);
void screen (char mode);
void bios (int address);
