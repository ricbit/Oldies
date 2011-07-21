import java.math.BigInteger;
import java.lang.Integer;

public class MC1000ports implements Ports {
  MC1000machine machine;

  MC1000ports(MC1000machine m) {
    machine=m;
  }
  
  public void out(int addr,int data, BigInteger clocks) {
    addr&=0xFF;
    //System.out.println ("OUT ("+Integer.toHexString(addr)+")="+Integer.toHexString(data));
    switch (addr) {
      case 0x20: 
        machine.psg.setRegister (data);
	break;
      case 0x60: 
        machine.psg.writeRegister (data);
	break;
      case 0x80:
	machine.memory.vramStatus (data);
	machine.vdp.changeMode (data);
	break;
      case 0x10:
      case 0x11:
	// support for 80 columns not implemented yet 
	break;
      case 0x12:
	machine.memory.vram80Status (data);
	break;
      default:
        //System.out.println ("OUT ("+Integer.toHexString(addr)+")="+Integer.toHexString(data));
    }
  }

  public int in(int addr, BigInteger clocks) {
    int ret;
    addr&=0xFF;
    //System.out.println ("IN ("+Integer.toHexString(addr)+")");
    switch (addr) {
      case 0x10:
      case 0x11:
	// support for 80 columns not implemented yet 
	ret=0xFF;
	break;
      case 0x40: 
        ret=machine.psg.readRegister (clocks);
	break;
      default:
        //System.out.println ("IN ("+Integer.toHexString(addr)+")");
	ret=0xFF;
    }
    return ret;
  }

}