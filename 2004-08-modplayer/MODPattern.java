public class MODPattern {
  public int[][] sample;
  public int[][] period;
  public int[][] effect;
  private static boolean DEBUG=false;

/*


 _____byte 1_____   byte2_    _____byte 3_____   byte4_
/                 /        /                 /
0000          0000-00000000  0000          0000-00000000

Upper four    12 bits for    Lower four    Effect command.
bits of sam-  note period.   bits of sam-
ple number.                  ple number.

*/

  MODPattern () {
    sample=new int[64][];
    for (int i=0; i<64; i++)
      sample[i]=new int[4];

    period=new int[64][];
    for (int i=0; i<64; i++)
      period[i]=new int[4];

    effect=new int[64][];
    for (int i=0; i<64; i++)
      effect[i]=new int[4];
  }

  public int getSpeed() {
    for (int i=0; i<64; i++)
      for (int j=0; j<4; j++)
        if ((effect[i][j]>>8)==0xF)
	  return effect[i][j]&0xFF;
    return 6;
  }

  public boolean hasSpeed() {
    for (int i=0; i<64; i++)
      for (int j=0; j<4; j++)
        if ((effect[i][j]>>8)==0xF)
	  return true;
    return false;
  }

  public void insertNote (int pos, int chan, int data) {
    sample[pos][chan]=((data>>12)&0xF) | ((data>>24)&0xF0);
    period[pos][chan]=(data>>16)&0xFFF;
    effect[pos][chan]=data&0xFFF;
    if (DEBUG) System.out.print
      ("Note "+pos+"("+chan+"): "+sample[pos][chan]+" "+
	period[pos][chan]+" ");
    switch (effect[pos][chan]>>8) {
      case 0xC: 
	if (DEBUG) System.out.println ("Volume "+(effect[pos][chan]&0xFF));
	break;	
      case 0xF: 
	if (DEBUG) System.out.println ("Speed "+(effect[pos][chan]&0xFF));
	break;	
      case 0:
	if (DEBUG) System.out.println ("-");
	break;
      default: 
	if (DEBUG) System.out.println ("Unknown "+(effect[pos][chan]>>8));
    }
  }
}