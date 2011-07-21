import java.io.*;

public class MODInstrument {
  String name;
  public int length;
  int fineTune;
  public int volume;
  public int repeatStart;
  public int repeatLength;
  public byte[] sample;
  private static boolean DEBUG=false;
  
  MODInstrument (String n, int len, int ft, int v, int rs, int rl) {
    name=new String(n);
    length=len;
    fineTune=ft;
    volume=v;
    repeatStart=rs;
    repeatLength=rl;
    if (DEBUG) System.out.println ("Instrument: "+n);
    if (DEBUG) System.out.println (len+ " "+ ft+ " "+ v+ " "+ rs+ " "+ rl);
  }

  public int getLength() {
    return length;
  }

  public void setSample (byte[] b) {
    sample=b;
  }

  public void flushSample(String s) {
    try {
      FileOutputStream f=new FileOutputStream (s+".raw");
      DataOutput out=new DataOutputStream (f);
      out.write(sample);
      f.close();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public String toString() {
    return new String(name);
  }
}