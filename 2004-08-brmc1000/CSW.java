import java.applet.Applet;
import java.io.*;
import java.util.*;
import java.util.zip.*;
import java.math.*;
import java.net.*;

class CSWError extends Exception {
  CSWError (String s) {
    super ("CSWError: "+s);
  }
}

public class CSW {
  int sampleRate;
  boolean[] data;
  MC1000machine machine;
  
  CSW(MC1000machine m) {
    machine=m;
    data=null;
  }

  public boolean returnSample (BigInteger time, int clock) {
    if (data==null)
      return true;	
  	
    if (time.compareTo(BigInteger.ZERO) < 0)
      return true;

    BigInteger t=time.multiply(BigInteger.valueOf(sampleRate)).divide(BigInteger.valueOf(clock));
    if (t.compareTo(BigInteger.valueOf(data.length)) >= 0)
      return true;

    return data[t.intValue()];
  }
  
  public BigInteger getLength(int clock) {
    if (data==null)
      return BigInteger.ZERO;	
  	
    return BigInteger.valueOf(data.length).
    	     multiply(BigInteger.valueOf(clock)).
    	     divide(BigInteger.valueOf(sampleRate));
  }

  public void readFromURL (Applet applet, String name) throws CSWError,IOException {
    URL http=new URL (applet.getCodeBase(),name);
    try {
      DataInput in=new DataInputStream(http.openStream());
      readFromStream (in);
    } catch (UnknownServiceException e) {
      throw new IOException();
    }	
  }

  public void readFromFile (String name) throws FileNotFoundException,CSWError,IOException {
    DataInput in=new DataInputStream (new FileInputStream (name));
    readFromStream (in);
  }

  public void readFromStream (DataInput in) throws CSWError,IOException {
    
    // Check magic signature
    byte[] magic=new byte[0x16];
    for (int i=0; i<0x16; i++)
      magic[i]=in.readByte();
    if (!new String(magic).equals("Compressed Square Wave"))
      throw new CSWError("Wrong magic");

    // Check separator
    if (in.readByte()!=0x1A)
      throw new CSWError("No separator found");

    // Check version
    byte majorVersion,minorVersion;
    majorVersion=in.readByte();
    minorVersion=in.readByte();
    if (majorVersion!=0x02 || minorVersion!=0x00)
      throw new CSWError("Wrong version");

    // Read sample rate
    sampleRate=0;
    for (int i=0; i<4; i++) 
      sampleRate|=(0xFF&(int)in.readByte())<<(i*8);

    // Read length
    int size=0;
    for (int i=0; i<4; i++) 
      size|=(0xFF&(int)in.readByte())<<(i*8);

    // Read flags
    in.readByte();

    // Read header extension
    int headerExtension=in.readByte();

    // Check encoding app name
    byte[] encodingApp=new byte[0x10];
    for (int i=0; i<0x10; i++)
      encodingApp[i]=in.readByte();

    // Skip header extension
    if (headerExtension>0)
      for (int i=0; i<headerExtension; i++)
        in.readByte();
  
    // read
    ArrayList compressedData=new ArrayList();
    try {
      while (true) {
        compressedData.add(new Byte(in.readByte()));
      }
    } catch (EOFException e) {}

    // Inflate
    byte[] compressedArray= new byte[compressedData.size()];
    for (int i=0; i<compressedData.size(); i++)
      compressedArray[i]=((Byte)(compressedData.get(i))).byteValue();
    Inflater decompresser = new Inflater();
    decompresser.setInput(compressedArray);
    byte[] rleData=new byte[size];
    try {
      decompresser.inflate(rleData,0,size);
    } catch (DataFormatException e) {
      throw new CSWError("Error in data format");
    }

    // Traverse and find length of unencoded data
    int finalSize=0;
    for (int i=0; i<rleData.length;) {
      if (rleData[i]!=0) 
  	finalSize+=unsignedByte(rleData[i++]);
      else {
	int max=0;
	i++;
    	for (int j=0; j<4; j++) 
      	  max|=(0xFF&rleData[i++])<<(j*8);
	finalSize+=max;
      }
    }

    // undo RLE
    boolean state=false;
    data=new boolean[finalSize];
    int current=0;
    for (int i=0; i<rleData.length;) {
      if (rleData[i]!=0) {
	for (int j=0; j<unsignedByte(rleData[i]); j++)
	  data[current++]=state;
	i++;
      } else {
	int max=0;
	i++;
    	for (int j=0; j<4; j++) 
      	  max|=(0xFF&rleData[i++])<<(j*8);
    	for (int j=0; j<max; j++) 
	  data[current++]=state;
      }
      state=!state;
    }
  }

  public void writeRawWave (String name) throws Exception {
    DataOutputStream out=new DataOutputStream (new FileOutputStream (name));
    for (int i=0; i<data.length; i++)
      if (data[i])
 	out.writeByte(0);
      else
	out.writeByte(255);
    out.close();
  }

  private int unsignedByte (byte b) {
    return b<0?0x100-(int)b:b;
  }
}