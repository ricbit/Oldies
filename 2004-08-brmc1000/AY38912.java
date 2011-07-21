import java.awt.event.*;
import java.math.*;

public class AY38912 {
  int regs[];
  int current;
  Keyboard keys;
  boolean tapeStarted;
  BigInteger tapeStartTime,currentPosition;  
  MC1000machine machine;

  AY38912(MC1000machine m) {
    regs=new int[16];
    keys=new Keyboard();
    tapeStarted=false;
    tapeStartTime=BigInteger.ZERO;
    machine=m;
  }
  
  public void setRegister (int r) {
    current=r&0xF;
  }

  public void writeRegister (int value) {
    regs[current]=value&0xFF;
    if (current==14)
      keys.write(value);
    //System.out.println ("PSG["+Integer.toHexString(current)+"]="+Integer.toHexString(value));
  }

  public int readRegister (BigInteger clocks) {
    int ret;

    if (!tapeStarted && keys.hasTapeStarted()) {
      if (!machine.tape.getLength(59600*60).equals(BigInteger.ZERO)) {
        tapeStarted=keys.hasTapeStarted();
        tapeStartTime=clocks;
      }
    }
 
    currentPosition=clocks.subtract(tapeStartTime);

    if (current<15)
      ret=regs[current];
    else {
      int cassete=0xFF;
      
      if (tapeStarted)
        if (!machine.tape.returnSample(clocks.subtract(tapeStartTime),59600*60))
           cassete=0x7F;
           
      ret=keys.read() & cassete;     
    }
 
    //System.out.println ("read PSG["+Integer.toHexString(current)+"]="+Integer.toHexString(ret)+" "+clocks);
    return ret;
  }
  
  public boolean hasTapeStarted() {
    return tapeStarted;
  }

  public int tapeProgress() {
    if (!tapeStarted)
      return 0;
      
    return currentPosition.multiply(BigInteger.valueOf(100)).divide(machine.tape.getLength(59600*60)).intValue();
  }


  public KeyListener getKeyListener () {
    return keys;
  }
}