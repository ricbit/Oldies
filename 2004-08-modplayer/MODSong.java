import java.io.*;

public class MODSong {
  String name; 
  MODInstrument instrument[]=new MODInstrument[31];
  MODPattern pattern[];
  int songLength;
  int songPosition[]=new int[128];
  byte[] wave;
  private static boolean DEBUG=false;

  private int unsigned (byte b) {
    return b<0?0x100+b:b;
  }

  private byte removeZero (byte b) {
    return b==0?32:b;
  }

  public void readFromFile (String s) {
    try {
      DataInput in=new DataInputStream (new FileInputStream (s));
    
      /* read 20 bytes of song name */
      byte[] modname=new byte[20];
      for (int i=0; i<20; i++)
        modname[i]=removeZero(in.readByte());	
      name=new String (modname);
      if (DEBUG) System.out.println ("name: "+name);

      /* read each of 31 instrument parameter blocks */
      for (int i=0; i<31; i++) {
        byte[] samplename=new byte[22];
	for (int j=0; j<22; j++) 
  	  samplename[j]=removeZero(in.readByte());
	instrument[i]=new MODInstrument
	  (new String(samplename),in.readShort()*2,in.readByte()&0xF,unsigned(in.readByte()),
	   in.readShort()*2,in.readShort()*2);	
      }
      
      /* read global parameters */
      songLength=unsigned(in.readByte());
      if (DEBUG) System.out.println ("song len: "+songLength);
      in.skipBytes(1);

      /* read all 128 song positions */
      int maxpos=0;
      for (int i=0; i<128; i++) {
	songPosition[i]=unsigned(in.readByte());
	maxpos=Math.max(maxpos,songPosition[i]);
  	if (DEBUG) System.out.println ("pos["+i+"]:"+songPosition[i]);
      }
      maxpos++;

      /* read 4-bytes signature */
      byte[] sig=new byte[4];
      for (int i=0; i<4; i++)
        sig[i]=removeZero(in.readByte());	
      if (DEBUG) System.out.println (new String(sig));

      /* read all song patterns */
      if (DEBUG) System.out.println ("total patterns: "+maxpos);
      pattern=new MODPattern[maxpos];
      for (int i=0; i<maxpos; i++) {
	pattern[i]=new MODPattern();
	for (int j=0; j<64; j++)
	  for (int k=0; k<4; k++)
	    pattern[i].insertNote(j,k,in.readInt());
      }

      /* read all samples */
      for (int i=0; i<31; i++) {
 	int len=instrument[i].getLength();
	byte[] b;
  	if (len>0) {
	  b=new byte[len];
	  for (int j=0; j<len; j++)
	    b[j]=in.readByte();
	  instrument[i].setSample(b);
	  //instrument[i].flushSample(name+"."+i);
	}
      }

    } catch (Exception e) {
      e.printStackTrace();
      System.exit(1);
    }
  }

  public byte[] getWave() {
    return wave;
  }

  private byte saturateSum (byte a, byte b) {
    int a1,b1,s;

    a1=a;
    b1=b;
    s=a1+b1;
    return (byte)(s<-128?-128:s>127?127:s);
  }

  private int getSpeed() {
    for (int i=0; i<songLength; i++)
      if (pattern[songPosition[i]].hasSpeed())
	return pattern[songPosition[i]].getSpeed();
    return 6;
  }

  private boolean hasSpeed() {
    for (int i=0; i<songLength; i++)
      if (pattern[songPosition[i]].hasSpeed())
	return true;
    return false;
  }


  public void createWave() {
    int noteSpeed=6;
    int sampleRate=44100;
    int clock=3570000;
    int irqRate=50;
    int stepSize;
    int size;
    int[] chanpos=new int[4];
    int[] chansum=new int[4];
    int[] lastper=new int[4];
    int[] lastvol=new int[4];
    int chaninc;
    int patt,note,inside;
    MODInstrument ins[]=new MODInstrument[4];

    if (hasSpeed())
      noteSpeed=getSpeed();
    size=songLength*64*sampleRate*noteSpeed/irqRate;
    chaninc=clock/sampleRate;
    stepSize=sampleRate*noteSpeed/irqRate;
    wave=new byte[size];
    chanpos[0]=0;
    chanpos[1]=0;
    chanpos[2]=0;
    chanpos[3]=0;
    chansum[0]=0;
    chansum[1]=0;
    chansum[2]=0;
    chansum[3]=0;
    lastper[0]=0;
    lastper[1]=0;
    lastper[2]=0;
    lastper[3]=0;
    lastvol[0]=64;
    lastvol[1]=64;
    lastvol[2]=64;
    lastvol[3]=64;
    patt=0; note=0; inside=0;
	  for (int i=0; i<4; i++)
  	  if (pattern[songPosition[patt]].period[note][i]!=0) {
  	    lastper[i]=pattern[songPosition[patt]].period[note][i];
	    ins[i]=instrument[-1+pattern[songPosition[patt]].sample[note][i]];
	    chanpos[i]=0;
	    chansum[i]=0;
 	  }

    for (int pos=0; pos<size; pos++) {
      wave[pos]=0;
      for (int i=0; i<4; i++) {
	if (lastper[i]!=0) {	  
	  if (chanpos[i]<ins[i].length)
	  wave[pos]=saturateSum
	    (wave[pos],(byte)((int)ins[i].sample[chanpos[i]]*ins[i].volume*lastvol[i]/(64*64)));
	  chansum[i]+=chaninc;
   	  if ((ins[i].repeatStart!=0) && (chanpos[i]>(ins[i].repeatLength+ins[i].repeatStart)))
	    chanpos[i]-=ins[i].repeatLength;
	  while (chansum[i]>=lastper[i]) {
	    chansum[i]-=lastper[i];
	    chanpos[i]++;
  	  }
        }
      }

      inside++;
      if (inside>stepSize) {
	inside=0;
	note++;
	if (note>63) {
  	  note=0;
	  patt++;
	}
	for (int i=0; i<4; i++)
  	  if (pattern[songPosition[patt]].period[note][i]!=0) {
  	    lastper[i]=pattern[songPosition[patt]].period[note][i];
	    ins[i]=instrument[-1+pattern[songPosition[patt]].sample[note][i]];
	    chanpos[i]=0;
	    chansum[i]=0;
 	    if ((pattern[songPosition[patt]].effect[note][i]>>8)==0xF)
	      lastvol[i]=pattern[songPosition[patt]].effect[note][i]&0xFF;
 	    /*if ((pattern[songPosition[patt]].effect[note][i]>>8)==0xC) {
    	      noteSpeed=pattern[songPosition[patt]].effect[note][i]&0xFF;

	      if (noteSpeed>27)
		noteSpeed=60*irqRate*4/noteSpeed;
	 	//System.out.println ("opa "+noteSpeed);
	      stepSize=sampleRate*noteSpeed/irqRate;
	    }*/
 	  }
      }
    }

    /*try {      
      FileOutputStream f=new FileOutputStream ("playme.raw");
      DataOutput out=new DataOutputStream (f);
      out.write(wave);
      f.close();
    } catch (Exception e) {
      e.printStackTrace();
    }*/

  }
}