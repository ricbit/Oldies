/* Z80 cpu core - Written from scratch by Romain Tisserand */

/* Bugs fixed by Ricardo Bittencourt */

/* History :

 2004-08-10 : [ricbit] Fixed RLD,RRD,ADD,ADC,SUB,SBC,OR,AND,XOR,CP
 2004-08-09 : [ricbit] Fixed CPL,SBC16,ADC16,RLA,RLCA,RRCA,RRA
 2002-11-19 : Fixed nasty bug involving the HALT instruction and IRQ system
 2002-11-13 : 1st release

 This source code is part of the Javel Project  */

import java.math.BigInteger;

public final class Z80 implements Cpu {
  private int AF, BC, DE, HL,
      AF2, BC2, DE2, HL2, IX, IY, XY,
      PC, SP, IFF1, IFF2, IM,
      word, addr;
  private int I, R, vector;
  private int cyclesToDo;
  private int sliceClocks;
  private BigInteger totalClocks;
  private MC1000machine machine;
   
  int NMIInt, IRQ;
   
  private boolean intel8080 = false;
  private boolean running = false;
  private static final byte PF_Table[] = new byte[256];
  private int enable;
  private long frequency;
  private boolean halted = false;
  private final int NMI_PC;
   
  private Ports port;
  private Memory mem;
   
  public void setPorts(Ports p) {
    this.port = p;
  }
   
  Z80(MC1000machine m, boolean intel8080, int startAddr) {
    machine=m;
    this.mem = machine.memory;
    this.port = machine.ports;
    this.frequency = frequency;
    this.intel8080 = intel8080;
      
    if (intel8080 == true) {
      NMI_PC = 0x10;
    } else {
      NMI_PC = 0x66;
    }
      
    PF_Table_init();
    reset(startAddr);
    start();
  }

  Z80(Memory m, Ports p, boolean intel8080, int startAddr) {
    this.mem = m;
    this.port = p;
    this.frequency = frequency;
    this.intel8080 = intel8080;
      
    if (intel8080 == true) {
      NMI_PC = 0x10;
    } else {
      NMI_PC = 0x66;
    }
      
    PF_Table_init();
    reset(startAddr);
    start();
  }

  public void dump() {
    System.out.println("PC=" + Integer.toHexString(PC));
  }
   
  public final void start() {
    running = true;
  }

  public final void stop() {
    running = false;
  }

  public final void reset(int startAddr) { 
    PC = startAddr; 
    SP = 0xDFF0; 
    AF = 0x0040;
    AF2 = BC = DE = HL = BC2 = DE2 = HL2 = 0;
    IRQ = NMIInt = 0;
    vector = 0;
    IM = 0; 
    IFF1 = IFF2 = 0;
    I = R = 0;
    IX = IY = XY = 0xFFFF; 
    enable = 0;
    cyclesToDo = 0;
    totalClocks=BigInteger.ZERO;
    sliceClocks=0;
  }
   
  private final void UpdateR() {
    R = ((R & 0x80) | ((R + 1) & 0x7F));
  }
   
  private  final void memWriteByte(int addr, int data) {
    mem.writeByte(addr, data);
  }

  private  final int memReadByte(int addr) { 
    return mem.readByte(addr);
  }

  private  final void  ioWriteByte(int p, int data) {
    port.out(p, data, totalClocks.add(BigInteger.valueOf(sliceClocks-cyclesToDo)));
  }

  private  final int  ioReadByte(int p) { 
    return port.in(p,totalClocks.add(BigInteger.valueOf(sliceClocks-cyclesToDo)));
  }
   
  private final void memWriteWord(int address, int  data) {
    memWriteByte(address, (data & 0xFF));
    memWriteByte(address + 1, ((data & 0xFF00) >> 8));
  }
   
  private final int memReadWord(int address) {
    return ((memReadByte(address)) | (memReadByte((address + 1)) << 8));
  }
   
  private final void setA(int v) {
    AF = (AF & 0xFF) | ((v) << 8);
  }

  private final void setF(int v) {
    AF = (AF & 0xFF00) | (v);
  }

  private final void setB(int v) {
    BC = (BC & 0xFF) | ((v) << 8);
  }

  private final void setC(int v) {
    BC = (BC & 0xFF00) | (v);
  }

  private final void setD(int v) {
    DE = (DE & 0xFF) | ((v) << 8);
  }

  private final void setE(int v) {
    DE = (DE & 0xFF00) | (v);
  }

  private final void setH(int v) {
    HL = (HL & 0xFF) | ((v) << 8);
  }

  private final void setL(int v) {
    HL = (HL & 0xFF00) | (v);
  }

  private final void setIXL(int v) {
    IX = (IX & 0xFF00) | (v);
  }

  private final void setIXH(int v) {
    IX = (IX & 0xFF) | ((v) << 8);
  }

  private final void setIYL(int v) {
    IY = (IY & 0xFF00) | (v);
  }

  private final void setIYH(int v) {
    IY = (IY & 0xFF) | ((v) << 8);
  }
   
  private final void setXYL(int v) {
    XY = (XY & 0xFF00) | (v);
  }

  private final void setXYH(int v) {
    XY = (XY & 0xFF) | ((v) << 8);
  }
   
  private final int getA() {
    return (AF >> 8);
  }

  private final int getB() {
    return (BC >> 8);
  }

  private final int getC() {
    return (BC & 0xFF);
  }

  private final int getD() {
    return (DE >> 8);
  }

  private final int getE() {
    return (DE & 0xFF);
  }

  private final int getH() {
    return (HL >> 8);
  }

  private final int getL() {
    return (HL & 0xFF);
  }

  private final int getIXH() {
    return (IX >> 8);
  }

  private final int getIXL() {
    return IX & 0xFF;
  }

  private final int getIYH() {
    return (IY >> 8);
  }

  private final int getIYL() {
    return IY & 0xFF;
  }

  private final int getXYH() {
    return (XY >> 8);
  }

  private final int getXYL() {
    return XY & 0xFF;
  }
   
  private final void decB() {
    setB((getB() - 1) & 0xFF);
  }
   
  private final void ClearCF() {
    AF &= 0xFFFE;
  }

  private final void ClearNF() {
    AF &= 0xFFFD;
  }

  private final void ClearVF() {
    AF &= 0xFFFB;
  }

  private final void ClearHF() {
    AF &= 0xFFEF;
  }

  private final void ClearZF() {
    AF &= 0xFFBF;
  }

  private final void ClearSF() {
    AF &= 0xFF7F;
  }

  private final void SetCF() {
    AF |= 0x01;
  }

  private final void SetNF() {
    AF |= 0x02;
  }

  private final void SetVF() {
    AF |= 0x04;
  }

  private final void SetHF() {
    AF |= 0x10;
  }

  private final void SetZF() {
    AF |= 0x40;
  }

  private final void SetSF() {
    AF |= 0x80;
  }
   
  private final void YF_XF_FLAGS(int x) {
    if ((x & 0x08) != 0) {
      AF |= 0x08;
    } else {
      AF &= 0xFFF7;
    } 
    if ((x & 0x20) != 0) {
      AF |= 0x20;
    } else {
      AF &= 0xFFDF;
    }
  }
   
  private final void PARI_FLAG(int x) {
    if (PF_Table[x & 0xFF] != 0) {
      SetVF();
    } else {
      ClearVF();
    }
  }
   
  private final void SIGN_FLAG(int value, int size) {
    if ((value & (1 << (size - 1))) != 0) {
      SetSF();
    } else {
      ClearSF();
    }
  }
   
  private final void ZERO_FLAG(int value) {
    if (value == 0) {
      SetZF();
    } else {
      ClearZF();
    }
  }
   
  private final void HC_FLAG(int v1, int v2, int v3) {
    if (((v1 ^ v2 ^ v3) & 0x10) != 0) {
      SetHF();
    } else {
      ClearHF();
    }
  }
   
  private final void CARRY_FLAG(long value, int size) {
    if ((value & (1 << size)) != 0) {
      SetCF();
    } else {
      ClearCF();
    }
  }
   
  private final void OVER_FLAG(int v1, int v2, long v3, int size) {
    if ((((v2 ^ v1 ^ 0x80) & (v2 ^ v3) & (1 << (size - 1))) >> 5) != 0) {
      SetVF();
    } else {
      ClearVF();
    }
  }
   
  private final void OVER_FLAG2(int v1, int v2, long v3, int size) {
    if ((((v2 ^ v1) & (v1 ^ v3) & (1 << (size - 1))) >> 5) != 0) {
      SetVF();
    } else {
      ClearVF();
    }
  }
   
  private final void ADD(int x) { 
    int temp = x;
    int acu = (AF >> 8);
    int sum = acu + temp;
    int cbits = acu ^ temp ^ sum;

    AF = ((sum & 0xff) << 8) | (sum & 0xa8) | (((sum & 0xff) == 0 ? 1 : 0) << 6)
        | (cbits & 0x10) | (((cbits >> 6) ^ (cbits >> 5)) & 4)
        | ((cbits >> 8) & 1);
  }

  private final void ADC(int x) { 
    int temp = x;
    int acu = (AF >> 8);
    int sum = acu + temp + (AF & 1);
    int cbits = acu ^ temp ^ sum;

    AF = ((sum & 0xff) << 8) | (sum & 0xa8) | (((sum & 0xff) == 0 ? 1 : 0) << 6)
        | (cbits & 0x10) | (((cbits >> 6) ^ (cbits >> 5)) & 4)
        | ((cbits >> 8) & 1);
  }

  private final void SBC(int x) { 
    int temp = x;
    int acu = (AF >> 8);
    int sum = acu - temp - (AF & 1);
    int cbits = acu ^ temp ^ sum;

    AF = ((sum & 0xff) << 8) | (sum & 0xa8) | (((sum & 0xff) == 0 ? 1 : 0) << 6)
        | (cbits & 0x10) | (((cbits >> 6) ^ (cbits >> 5)) & 4) | 2
        | ((cbits >> 8) & 1);
  }

  private final int INC(int x) {
    int val = x + 1;

    OVER_FLAG(x, 1, val, 8);
    HC_FLAG(x, 1, val);
    x = (val & 0xFF);
    SIGN_FLAG(x, 8);
    ZERO_FLAG(x);
    ClearNF(); 
    return x;
  }

  private final int DEC(int x) {
    int val = x - 1;

    OVER_FLAG2(x, 1, val, 8);
    HC_FLAG(x, 1, val);
    x = (val & 0xFF);
    SIGN_FLAG(x, 8);
    ZERO_FLAG(x);
    SetNF(); 
    return x;
  }

  private final void SUB(int v) { 
    int temp = v;
    int acu = (AF >> 8);
    int sum = acu - temp;
    int cbits = acu ^ temp ^ sum;

    AF = ((sum & 0xff) << 8) | (sum & 0xa8) | (((sum & 0xff) == 0 ? 1 : 0) << 6)
        | (cbits & 0x10) | (((cbits >> 6) ^ (cbits >> 5)) & 4) | 2
        | ((cbits >> 8) & 1);
  }

  private final void AND(int v) { 
    int sum = ((AF >> 8) & v) & 0xff;

    AF = (sum << 8) | (sum & 0xa8) | 0x10 | ((sum == 0 ? 1 : 0) << 6)
        | ((PF_Table[sum & 0xff] ^ 1) << 2);
  }

  private final void XOR(int v) { 
    int sum = ((AF >> 8) ^ v) & 0xff;

    AF = (sum << 8) | (sum & 0xa8) | ((sum == 0 ? 1 : 0) << 6)
        | ((PF_Table[sum & 0xff] ^ 1) << 2);
  }

  private final void OR(int v) { 
    int sum = ((AF >> 8) | v) & 0xff;

    AF = (sum << 8) | (sum & 0xa8) | ((sum == 0 ? 1 : 0) << 6)
        | ((PF_Table[sum & 0xff] ^ 1) << 2);
  }

  private final void CP(int v) { 
    int temp = v;

    AF = (AF & ((~0x28) & 0xFFFF)) | (temp & 0x28);
    int acu = (AF >> 8);
    int sum = acu - temp;
    int cbits = acu ^ temp ^ sum;

    AF = (AF & 0xff00) | (sum & 0x80) | (((sum & 0xff) == 0 ? 1 : 0) << 6)
        | (temp & 0x28) | (((cbits >> 6) ^ (cbits >> 5)) & 4) | 2
        | (cbits & 0x10) | ((cbits >> 8) & 1);
  }

  private final void DAA() {
    int val = getA();

    if ((AF & 0x01) != 0) {
      val |= 256;
    } 
    if ((AF & 0x10) != 0) {
      val |= 512;
    } 
    if ((AF & 0x02) != 0) {
      val |= 1024;
    }
    AF = DAATable2[val];
  }
   
  /* fixed by ricbit */
  private final void CPL() {
    setA(0xFF & (~getA()));
    SetHF();
    SetNF();
    YF_XF_FLAGS(getA());
  }

  private final void EXX() {
    word = BC;
    BC = BC2;
    BC2 = word;
    word = DE;
    DE = DE2;
    DE2 = word;
    word = HL;
    HL = HL2;
    HL2 = word;
  }

  private final void SCF() {
    ClearHF();
    ClearNF();
    SetCF();
    YF_XF_FLAGS(getA());
  }
 
  private final void CCF() {
    ClearNF(); 
    if ((AF & 0x01) != 0) {
      SetHF();
      ClearCF();
    } else {
      ClearHF();
      SetCF();
    }
    YF_XF_FLAGS(getA());
  }
 
  private final void PUSH(int v) {
    SP -= 2;
    SP &= 0xFFFF;
    memWriteWord(SP, v & 0xFFFF);
  }

  private final int POP() {
    int val = memReadWord(SP);

    val &= 0xFFFF;
    SP += 2;
    SP &= 0xFFFF; 
    return val;
  }

  private final void RST(int v) {
    PUSH(PC);
    PC = v;
  }

  private final void RET() {
    PC = memReadWord(SP);
    SP += 2;
    SP &= 0xFFFF;
  }

  private final void CALL() {
    SP -= 2;
    SP &= 0xFFFF;
    memWriteWord(SP, (PC + 2));
    PC = memReadWord(PC);
  }

  private final void NEG() {
    int val = getA();

    setA(0);
    SUB(val);
  }
   
  private final int ADD16(int x, int y) {
    ClearNF();
    int val = (x) + (y);

    if ((((y ^ x ^ val)) & 0x1000) != 0) {
      SetHF();
    } else {
      ClearHF();
    }
    CARRY_FLAG(val, 16);
    YF_XF_FLAGS(val >> 8);
    return val & 0xFFFF;
  }
   
  private final void SBC_HL(int x) { 
    HL &= 0xffff;
    x &= 0xffff;
    int sum = HL - x - (AF & 1);
    int cbits = (HL ^ x ^ sum) >> 8;

    HL = sum & 0xFFFF;
    AF = (AF & 0xff00) | ((sum >> 8) & 0xa8)
        | (((sum & 0xffff) == 0 ? 1 : 0) << 6)
        | (((cbits >> 6) ^ (cbits >> 5)) & 4) | (cbits & 0x10) | 2
        | ((cbits >> 8) & 1);

  }
   
  private final void ADC_HL(int x) { 
    HL &= 0xffff;
    x &= 0xffff;
    int sum = HL + x + (AF & 1);
    int cbits = (HL ^ x ^ sum) >> 8;

    HL = sum & 0xffff;
    AF = (AF & 0xff00) | ((sum >> 8) & 0xa8)
        | (((sum & 0xffff) == 0 ? 1 : 0) << 6)
        | (((cbits >> 6) ^ (cbits >> 5)) & 4) | (cbits & 0x10)
        | ((cbits >> 8) & 1);

  }

  private final void cbFlag(int temp, int cbits) {
    AF = (AF & 0xff00) | (temp & 0xa8) | (((temp & 0xff) == 0 ? 1 : 0) << 6)
        | ((PF_Table[temp & 0xff] ^ 1) << 2) | (cbits == 0 ? 0 : 1);
  }
   
  private final int RR(int x) { 

    /* int old_x=x&0xFF; int val=old_x; val=(((val>>1))|((AF&0x01)<<7))&0xFF; ZERO_FLAG(val); SIGN_FLAG(val,8); PARI_FLAG(val);
     if ((old_x&0x01)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); */
    int temp = (x >> 1) | ((AF & 1) << 7);
    int cbits = x & 1;

    cbFlag(temp, cbits);
    return temp; 
  }
   
  private final int RL(int x) { 

    /* int old_x=x&0xFF; int val=old_x; val=((val<<1)|(AF&0x01))&0xFF; ZERO_FLAG(val); SIGN_FLAG(val,8); PARI_FLAG(val);
     if ((old_x&0x80)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); */
    int temp = (x << 1) | (AF & 1);
    int cbits = x & 0x80;

    cbFlag(temp, cbits);
    return temp;
  }
   
  private final int RRC(int x) { 

    /* int old_x=x&0xFF; int val=old_x; val=((val>>1)|(val<<7))&0xFF; 
     ZERO_FLAG(val); SIGN_FLAG(val,8); PARI_FLAG(val);
     if ((old_x&0x01)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); 
     return val&0xFF; */
    int temp = (x >> 1) | (x << 7);
    int cbits = temp & 0x80;

    cbFlag(temp, cbits);
    return temp;
  }
   
  private final int RLC(int x) { 

    /* int old_x=x&0xFF; int val=old_x; val=((val<<1)|(val>>7))&0xFF; 
     ZERO_FLAG(val); SIGN_FLAG(val,8); PARI_FLAG(val);
     if ((old_x&0x80)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); 
     return val; */
    int temp = (x << 1) | (x >> 7);
    int cbits = temp & 1;

    cbFlag(temp, cbits);
    return temp;
  }
   
  private final void RRA() { 
    int temp = (AF >> 8) & 0xFF;
    int sum = temp >> 1;

    AF = ((AF & 1) << 15) | (sum << 8) | (sum & 0x28) | (AF & 0xc4) | (temp & 1);

  }

  private final void RLA() { 
    AF = ((AF << 8) & 0x0100) | ((AF >> 7) & 0x28)
        | ((AF << 1) & ((~0x1ff) & 0xFFFF)) | (AF & 0xc4) | ((AF >> 15) & 1);

  }

  private final void RRCA() { 
    int temp = (AF >> 8) & 0xFF;
    int sum = temp >> 1;

    AF = ((temp & 1) << 15) | (sum << 8) | (sum & 0x28) | (AF & 0xc4)
        | (temp & 1);
  }

  private final void RLCA() { 
    AF = ((AF >> 7) & 0x0128) | ((AF << 1) & ((~0x1ff) & 0xFFFF)) | (AF & 0xc4)
        | ((AF >> 15) & 1);

  }
   
  private final void RLD() { 
    int temp = memReadByte(HL);
    int acu = (AF >> 8) & 0xFF;

    memWriteByte(HL, ((temp & 0xf) << 4) | (acu & 0xf));
    acu = (acu & 0xf0) | ((temp >> 4) & 0xf);
    AF = (acu << 8) | (acu & 0xa8) | (((acu & 0xff) == 0 ? 1 : 0) << 6)
        | ((PF_Table[acu] ^ 1) << 2) | (AF & 1);
  }

  private final void RRD() { 
    int temp = memReadByte(HL);
    int acu = (AF >> 8) & 0xFF;

    memWriteByte(HL, ((temp >> 4) & 0xf) | ((acu & 0xf) << 4));
    acu = (acu & 0xf0) | (temp & 0xf);
    AF = (acu << 8) | (acu & 0xa8) | (((acu & 0xff) == 0 ? 1 : 0) << 6)
        | ((PF_Table[acu] ^ 1) << 2) | (AF & 1);

  }
   
  private final int IN() {
    int val = ioReadByte(BC);

    ClearHF();
    ClearNF();
    SIGN_FLAG(val, 8);
    ZERO_FLAG(val);
    PARI_FLAG(val);
    YF_XF_FLAGS(val); 
    return val;
  }
   
  private final void INI() {
    int byte2 = ioReadByte(BC) & 0xFF;

    memWriteByte(HL, byte2);
    HL++;
    HL &= 0xFFFF;
    decB();
    SIGN_FLAG(getB(), 8);
    ZERO_FLAG(getB());

    /* if (((((getC()+1)&0xFF)+byte2)&0x100)!=0) { SetCF(); SetHF(); }
     else { ClearCF(); ClearHF(); }*/
    if ((byte2 & 0x80) != 0) {
      SetNF();
    } else {
      ClearNF();
    }
  }
   
  private final void IND() {
    int byte2 = ioReadByte(BC) & 0xFF;

    memWriteByte(HL, byte2);
    HL--;
    HL &= 0xFFFF;
    decB();
    SIGN_FLAG(getB(), 8);
    ZERO_FLAG(getB());

    /* if (((((getC()+1)&0xFF)+byte2)&0x100)!=0) { SetCF(); SetHF(); }
     else { ClearCF(); ClearHF(); }*/
    if ((byte2 & 0x80) != 0) {
      SetNF();
    } else {
      ClearNF();
    }
  }

  private final void INIR() {
    INI();
    if (getB() != 0) {
      PC -= 2;
    }
  }

  private final void INDR() {
    IND();
    if (getB() != 0) {
      PC -= 2;
    }
  }
   
  private final void OUTI() {
    int byte2 = memReadByte(HL);

    ioWriteByte(BC, byte2);
    HL++;
    HL &= 0xFFFF;
    decB();
    SIGN_FLAG(getB(), 8);
    ZERO_FLAG(getB());
    if ((byte2 & 0x80) != 0) {
      SetNF();
    } else {
      ClearNF();
    }

    /* if (((byte2+getL())&0x100)!=0) { SetCF(); SetHF(); } 
     else { ClearCF(); ClearHF(); }*/ }

  private final void OUTD() {
    int byte2 = memReadByte(HL);

    ioWriteByte(BC, byte2);
    HL--;
    HL &= 0xFFFF;
    decB();
    SIGN_FLAG(getB(), 8);
    ZERO_FLAG(getB());
    if ((byte2 & 0x80) != 0) {
      SetNF();
    } else {
      ClearNF();
    }

    /* if (((byte2+getL())&0x100)!=0) { SetCF(); SetHF(); } 
     else { ClearCF(); ClearHF(); }*/ }

  private final void OUTDR() {
    OUTD(); 
    if (getB() != 0) {
      PC -= 2;
    }
  }

  private final void OUTIR() {
    OUTI(); 
    if (getB() != 0) {
      PC -= 2;
    }
  }
   
  private final void LDI() {
    ClearHF();
    ClearNF();
    int byte2 = memReadByte(HL) & 0xFF;

    memWriteByte(DE, byte2);
    DE++;
    HL++;
    BC--;
    DE &= 0xFFFF;
    HL &= 0xFFFF;
    BC &= 0xFFFF;
    if ((BC) != 0) {
      SetVF();
    } else {
      ClearVF();
    }
    byte2 += getA();
    byte2 &= 0xFF;
    if ((byte2 & 0x02) != 0) {
      AF |= 0x20;
    } else {
      AF &= 0xFFDF;
    } 
    if ((byte2 & 0x08) != 0) {
      AF |= 0x08;
    } else {
      AF &= 0xFFF7;
    }
    UpdateR();
  }
   
  private final void LDD() {
    ClearHF();
    ClearNF();
    int byte2 = memReadByte(HL) & 0xFF;

    memWriteByte(DE, byte2);
    DE--;
    HL--;
    BC--;
    DE &= 0xFFFF;
    HL &= 0xFFFF;
    BC &= 0xFFFF;
    if ((BC) != 0) {
      SetVF();
    } else {
      ClearVF();
    }
    byte2 += getA();
    byte2 &= 0xFF;
    if ((byte2 & 0x02) != 0) {
      AF |= 0x20;
    } else {
      AF &= 0xFFDF;
    } 
    if ((byte2 & 0x08) != 0) {
      AF |= 0x08;
    } else {
      AF &= 0xFFF7;
    }
    UpdateR();
  }
   
  private final void LDIR() {
    LDI();  
    if (BC != 0) {
      PC -= 2;
    }
  }
   
  private final void LDDR() {
    LDD();  
    if (BC != 0) {
      PC -= 2;
    }
  }
   
  private final void CPI() {
    SetNF();
    int byte2 = memReadByte(HL);

    HL++;
    HL &= 0xFFFF;
    BC--;
    BC &= 0xFFFF;
    int val = byte2 & 0xFF;
    int res = getA() - val;

    res &= 0xFF;
    ZERO_FLAG(res);
    if (((getA() ^ res ^ val) & 0x10) != 0) {
      SetHF();
    } else {
      ClearHF();
    }
    SIGN_FLAG(res, 8);
    YF_XF_FLAGS((getA() - byte2 - ((AF & 0x10) >> 4)));
    if ((BC) != 0) {
      SetVF();
    } else {
      ClearVF();
    }
  }
   
  private final void CPD() {
    SetNF();
    int byte2 = memReadByte(HL);

    HL--;
    HL &= 0xFFFF;
    BC--;
    BC &= 0xFFFF;
    int val = byte2 & 0xFF;
    int res = getA() - val;

    res &= 0xFF;
    ZERO_FLAG(res);
    if (((getA() ^ res ^ val) & 0x10) != 0) {
      SetHF();
    } else {
      ClearHF();
    }
    SIGN_FLAG(res, 8);
    YF_XF_FLAGS((getA() - byte2 - ((AF & 0x10) >> 4)));
    if ((BC) != 0) {
      SetVF();
    } else {
      ClearVF();
    }
  }
   
  private final void CPIR() {
    CPI();  
    if ((BC != 0) && ((AF & 0x40) == 0)) {
      PC -= 2;
    }
  }
   
  private final void CPDR() {
    CPD();  
    if ((BC != 0) && ((AF & 0x40) == 0)) {
      PC -= 2;
    }
  }
   
  private final void BIT(int y, int x) {
    if ((x & (1 << y)) != 0) {
      ClearZF();
      ClearVF();
      switch (y) {
      case 7:
        SetSF();
        break;

      case 5:
        AF |= 0x20;
        break;

      case 3:
        AF |= 0x08;
        break;
      }
    } else {
      SetZF();
      SetVF();
    }
    ClearNF();
    SetHF();
  }
   
  private final int RES(int y, int x) { 
    return (x & (~(1 << y))) & 0xFF;
  }

  private final int SET(int y, int x) {
    return (x | (1 << y)) & 0xFF;
  }
   
  private final int SRA(int x) { 

    /* int old_x=x&0xFF; x=old_x; x=(x&0x80)|((x>>1)); x&=0xFF; ZERO_FLAG(x); SIGN_FLAG(x,8); PARI_FLAG(x);
     if ((old_x&0x01)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); 
     return x; */
    int temp = (x >> 1) | (x & 0x80);
    int cbits = x & 1;

    cbFlag(temp, cbits);
    return temp;

  }
   
  private final int SRL(int x) { 

    /* int old_x=x&0xFF; x=old_x; x=(x>>1)&0xFF; ZERO_FLAG(x); SIGN_FLAG(x,8); PARI_FLAG(x);
     if ((old_x&0x01)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); 
     return x; }*/
    int temp = x >> 1;
    int cbits = x & 1;

    cbFlag(temp, cbits);
    return temp;
  }
   
  private final int SLA(int x) { 

    /* int old_x=x&0xFF; x=old_x; x=(x<<1)&0xFF;  ZERO_FLAG(x); SIGN_FLAG(x,8); PARI_FLAG(x);
     if ((old_x&0x80)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); 
     return x; }*/
    int temp = x << 1;
    int cbits = x & 0x80;

    cbFlag(temp, cbits);
    return temp;
  }
   
  private final int SLL(int x) { 

    /* int old_x=x&0xFF; x=old_x; x=((x<<1)|0x01)&0xFF; ZERO_FLAG(x); SIGN_FLAG(x,8); PARI_FLAG(x);
     if ((old_x&0x80)!=0) SetCF(); 
     else ClearCF(); ClearHF(); ClearNF(); 
     return x; }*/
    int temp = (x << 1) | 1;
    int cbits = x & 0x80;

    cbFlag(temp, cbits);
    return temp;
  }
   
  private final int LD_RES(int i, int y) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = RES(y, memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_SET(int i, int y) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = SET(y, memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_RLC(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = RLC(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_RRC(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = RRC(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_RL(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = RL(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_RR(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = RR(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_SRA(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = SRA(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_SLA(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = SLA(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_SRL(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = SRL(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }

  private final int LD_SLL(int i) {
    int tmp_addr = i + (byte) (memReadByte(PC++));

    tmp_addr &= 0xFFFF;
    int byte2 = SLL(memReadByte(tmp_addr));

    memWriteByte(tmp_addr, byte2); 
    return byte2;
  }
   
  private final void exeOpcode(int opcode) {
      
    switch (opcode) {
    case 0xCB:
      exe_cb_opcode(memReadByte(PC++));
      break; // Prefix

    case 0xED:
      exe_ed_opcode(memReadByte(PC++));
      break; // Prefix

    case 0xDD:
      IX = exe_dd_opcode(IX, memReadByte(PC++));
      break; // Prefix

    case 0xFD:
      IY = exe_dd_opcode(IY, memReadByte(PC++));
      break; // Prefix

    case 0x00: 
      break; // NOP

    case 0x01:
      BC = memReadWord(PC);
      PC += 2; 
      break; // LD BC,NN

    case 0x02:
      memWriteByte(BC, getA()); 
      break; // LD (BC),A

    case 0x03:
      BC++;
      BC &= 0xFFFF; 
      break; // INC BC

    case 0x04:
      setB(INC(getB())); 
      break; // INC B

    case 0x05:
      setB(DEC(getB())); 
      break; // DEC B

    case 0x06:
      setB(memReadByte(PC++));
      break; // LD B,N

    case 0x07:
      RLCA(); 
      break; // RLCA

    case 0x08:
      word = AF;
      AF = AF2;
      AF2 = word; 
      break; // EX AF,AF'

    case 0x09:
      HL = ADD16(HL, BC); 
      break; // ADD HL,BC

    case 0x0A:
      setA(memReadByte(BC)); 
      break; // LD A,(BC)

    case 0x0B:
      BC--;
      BC &= 0xFFFF; 
      break; // DEC BC

    case 0x0C:
      setC(INC(getC())); 
      break; // INC C

    case 0x0D:
      setC(DEC(getC())); 
      break; // DEC C

    case 0x0E:
      setC(memReadByte(PC++)); 
      break; // LD C,N

    case 0x0F:
      RRCA(); 
      break; // RRCA

    case 0x10:
      decB();
      if (getB() != 0) {
        cyclesToDo -= 3;
        PC += 1 + (byte) (memReadByte(PC));
      } else {
        PC++;
      }
      break; // DJNZ (PC+dd)

    case 0x11:
      DE = memReadWord(PC);
      PC += 2;
      break; // LD DE,NN

    case 0x12:
      memWriteByte(DE, getA()); 
      break; // LD (DE),A

    case 0x13:
      DE++;
      DE &= 0xFFFF; 
      break; // INC DE

    case 0x14:
      setD(INC(getD())); 
      break; // INC D

    case 0x15:
      setD(DEC(getD())); 
      break; // DEC D

    case 0x16:
      setD(memReadByte(PC++)); 
      break; // LD D,N

    case 0x17:
      RLA(); 
      break; // RLA

    case 0x18:
      PC += 1 + (byte) (memReadByte(PC)); 
      break; // JR e

    case 0x19:
      HL = ADD16(HL, DE); 
      break; // ADD HL,DE

    case 0x1A:
      setA(memReadByte(DE)); 
      break; // LD A,(DE)

    case 0x1B:
      DE--;
      DE &= 0xFFFF;
      break; // DEC DE

    case 0x1C:
      setE(INC(getE()));
      break; // INC E

    case 0x1D:
      setE(DEC(getE()));
      break; // DEC E

    case 0x1E:
      setE(memReadByte(PC++));
      break; // LD E,N

    case 0x1F:
      RRA(); 
      break; // RRA

    case 0x20:
      if ((AF & 0x40) == 0) {
        cyclesToDo -= 5;
        PC += 1 + (byte) (memReadByte(PC));
      } else {
        PC++;
      }
      break; // JR NZ,n

    case 0x21:
      HL = memReadWord(PC);
      PC += 2;
      break; // LD HL,NN

    case 0x22:
      memWriteWord(memReadWord(PC), HL);
      PC += 2;
      break; // LD (NN),HL

    case 0x23:
      HL++;
      HL &= 0xFFFF; 
      break; // INC HL

    case 0x24:
      setH(INC(getH())); 
      break; // INC H

    case 0x25:
      setH(DEC(getH())); 
      break; // DEC H

    case 0x26:
      setH(memReadByte(PC++));
      break; // LD H,N

    case 0x27:
      DAA(); 
      break; // DAA

    case 0x28:
      if ((AF & 0x40) != 0) {
        cyclesToDo -= 5;
        PC += 1 + (byte) (memReadByte(PC));
      } else {
        PC++;
      } 
      break; // JR Z,n

    case 0x29:
      HL = ADD16(HL, HL); 
      break; // ADD HL,HL

    case 0x2A:
      HL = memReadWord(memReadWord(PC));
      PC += 2;
      break; // LD HL,(NN)

    case 0x2B:
      HL--;
      HL &= 0xFFFF; 
      break; // DEC HL

    case 0x2C:
      setL(INC(getL())); 
      break; // INC L

    case 0x2D:
      setL(DEC(getL())); 
      break; // DEC L

    case 0x2E:
      setL(memReadByte(PC++));
      break; // LD L,N

    case 0x2F:
      CPL(); 
      break; // CPL

    case 0x30:
      if ((AF & 0x01) == 0) {
        cyclesToDo -= 5;
        PC += 1 + (byte) (memReadByte(PC));
      } else {
        PC++;
      }
      break; // JR NC,n

    case 0x31:
      SP = memReadWord(PC);
      PC += 2;
      break; // LD SP,NN

    case 0x32:
      memWriteByte(memReadWord(PC), getA());
      PC += 2;
      break; // LD (NN),A

    case 0x33:
      SP++;
      SP &= 0xFFFF; 
      break; // INC SP

    case 0x34:
      memWriteByte(HL, INC(memReadByte(HL))); 
      break; // INC (HL)

    case 0x35:
      memWriteByte(HL, DEC(memReadByte(HL))); 
      break; // DEC (HL)

    case 0x36:
      memWriteByte(HL, memReadByte(PC++));
      break; // LD (HL),N

    case 0x37:
      SCF(); 
      break; // SCF

    case 0x38:
      if ((AF & 0x01) != 0) {
        cyclesToDo -= 5;
        PC += 1 + (byte) (memReadByte(PC));
      } else {
        PC++;
      } 
      break; // JR C,n

    case 0x39:
      HL = ADD16(HL, SP); 
      break; // ADD HL,SP

    case 0x3A:
      setA(memReadByte(memReadWord(PC)));
      PC += 2;
      break; // LD A,(NN)

    case 0x3B:
      SP--;
      SP &= 0xFFFF; 
      break; // DEC SP

    case 0x3C:
      setA(INC(getA())); 
      break; // INC A

    case 0x3D:
      setA(DEC(getA())); 
      break; // DEC A

    case 0x3E:
      setA(memReadByte(PC++));
      break; // LD A,N

    case 0x3F:
      CCF(); 
      break; // CCF

    case 0x40: 
      break; // LD B,B

    case 0x41:
      setB(getC()); 
      break; // LD B,C

    case 0x42:
      setB(getD()); 
      break; // LD B,D

    case 0x43:
      setB(getE()); 
      break; // LD B,E

    case 0x44:
      setB(getH()); 
      break; // LD B,H

    case 0x45:
      setB(getL()); 
      break; // LD B,L

    case 0x46:
      setB(memReadByte(HL)); 
      break; // LD B,(HL)

    case 0x47:
      setB(getA()); 
      break; // LD B,A

    case 0x48:
      setC(getB()); 
      break; // LD C,B

    case 0x49: 
      break; // LD C,C

    case 0x4A:
      setC(getD()); 
      break; // LD C,D

    case 0x4B:
      setC(getE()); 
      break; // LD C,E

    case 0x4C:
      setC(getH()); 
      break; // LD C,H

    case 0x4D:
      setC(getL()); 
      break; // LD C,L

    case 0x4E:
      setC(memReadByte(HL)); 
      break; // LD C,(HL)

    case 0x4F:
      setC(getA()); 
      break; // LD C,A

    case 0x50:
      setD(getB()); 
      break; // LD D,B

    case 0x51:
      setD(getC()); 
      break; // LD D,C

    case 0x52: 
      break; // LD D,D

    case 0x53:
      setD(getE()); 
      break; // LD D,E

    case 0x54:
      setD(getH()); 
      break; // LD D,H

    case 0x55:
      setD(getL()); 
      break; // LD D,L

    case 0x56:
      setD(memReadByte(HL)); 
      break; // LD D,(HL)

    case 0x57:
      setD(getA()); 
      break; // LD D,A

    case 0x58:
      setE(getB()); 
      break; // LD E,B

    case 0x59:
      setE(getC()); 
      break; // LD E,C

    case 0x5A:
      setE(getD()); 
      break; // LD E,D

    case 0x5B: 
      break; // LD E,E

    case 0x5C:
      setE(getH()); 
      break; // LD E,H

    case 0x5D:
      setE(getL()); 
      break; // LD E,L

    case 0x5E:
      setE(memReadByte(HL)); 
      break; // LD E,(HL)

    case 0x5F:
      setE(getA()); 
      break; // LD E,A

    case 0x60:
      setH(getB()); 
      break; // LD H,B

    case 0x61:
      setH(getC()); 
      break; // LD H,C

    case 0x62:
      setH(getD()); 
      break; // LD H,D

    case 0x63:
      setH(getE()); 
      break; // LD H,E

    case 0x64: 
      break; // LD H,H

    case 0x65:
      setH(getL()); 
      break; // LD H,L

    case 0x66:
      setH(memReadByte(HL)); 
      break; // LD H,(HL)

    case 0x67:
      setH(getA()); 
      break; // LD H,A

    case 0x68:
      setL(getB()); 
      break; // LD L,B

    case 0x69:
      setL(getC()); 
      break; // LD L,C

    case 0x6A:
      setL(getD()); 
      break; // LD L,D

    case 0x6B:
      setL(getE()); 
      break; // LD L,E

    case 0x6C:
      setL(getH()); 
      break; // LD L,H

    case 0x6D: 
      break; // LD L,L

    case 0x6E:
      setL(memReadByte(HL)); 
      break; // LD L,(HL)

    case 0x6F:
      setL(getA()); 
      break; // LD L,A

    case 0x70:
      memWriteByte(HL, getB()); 
      break; // LD (HL),B

    case 0x71:
      memWriteByte(HL, getC()); 
      break; // LD (HL),C

    case 0x72:
      memWriteByte(HL, getD()); 
      break; // LD (HL),D

    case 0x73:
      memWriteByte(HL, getE()); 
      break; // LD (HL),E

    case 0x74:
      memWriteByte(HL, getH()); 
      break; // LD (HL),H

    case 0x75:
      memWriteByte(HL, getL()); 
      break; // LD (HL),L

    case 0x76:
      halted = true; 
      break; // HALT

    case 0x77:
      memWriteByte(HL, getA()); 
      break; // LD (HL),A

    case 0x78:
      setA(getB()); 
      break; // LD A,B

    case 0x79:
      setA(getC()); 
      break; // LD A,C

    case 0x7A:
      setA(getD()); 
      break; // LD A,D

    case 0x7B:
      setA(getE()); 
      break; // LD A,E

    case 0x7C:
      setA(getH()); 
      break; // LD A,H

    case 0x7D:
      setA(getL()); 
      break; // LD A,L

    case 0x7E:
      setA(memReadByte(HL)); 
      break; // LD A,(HL)

    case 0x7F: 
      break; // LD A,A

    case 0x80:
      ADD(getB()); 
      break; // ADD A,B

    case 0x81:
      ADD(getC()); 
      break; // ADD A,C

    case 0x82:
      ADD(getD()); 
      break; // ADD A,D

    case 0x83:
      ADD(getE()); 
      break; // ADD A,E

    case 0x84:
      ADD(getH()); 
      break; // ADD A,H

    case 0x85:
      ADD(getL()); 
      break; // ADD A,L

    case 0x86:
      ADD(memReadByte(HL)); 
      break; // ADD (HL)

    case 0x87:
      ADD(getA()); 
      break; // ADD A,A

    case 0x88:
      ADC(getB()); 
      break; // ADC A,B

    case 0x89:
      ADC(getC()); 
      break; // ADC A,C

    case 0x8A:
      ADC(getD()); 
      break; // ADC A,D

    case 0x8B:
      ADC(getE()); 
      break; // ADC A,E

    case 0x8C:
      ADC(getH()); 
      break; // ADC A,H

    case 0x8D:
      ADC(getL()); 
      break; // ADC A,L

    case 0x8E:
      ADC(memReadByte(HL)); 
      break; // ADC (HL)

    case 0x8F:
      ADC(getA()); 
      break; // ADC A,A

    case 0x90:
      SUB(getB()); 
      break; // SUB B

    case 0x91:
      SUB(getC()); 
      break; // SUB C

    case 0x92:
      SUB(getD()); 
      break; // SUB D

    case 0x93:
      SUB(getE()); 
      break; // SUB E

    case 0x94:
      SUB(getH()); 
      break; // SUB H

    case 0x95:
      SUB(getL()); 
      break; // SUB L

    case 0x96:
      SUB(memReadByte(HL)); 
      break; // SUB (HL)

    case 0x97:
      SUB(getA()); 
      break; // SUB A

    case 0x98:
      SBC(getB()); 
      break; // SBC B

    case 0x99:
      SBC(getC()); 
      break; // SBC C

    case 0x9A:
      SBC(getD()); 
      break; // SBC D

    case 0x9B:
      SBC(getE()); 
      break; // SBC E

    case 0x9C:
      SBC(getH()); 
      break; // SBC H

    case 0x9D:
      SBC(getL()); 
      break; // SBC L

    case 0x9E:
      SBC(memReadByte(HL)); 
      break; // SBC (HL)

    case 0x9F:
      SBC(getA()); 
      break; // SBC A

    case 0xA0:
      AND(getB()); 
      break; // AND B

    case 0xA1:
      AND(getC()); 
      break; // AND C

    case 0xA2:
      AND(getD()); 
      break; // AND D

    case 0xA3:
      AND(getE()); 
      break; // AND E

    case 0xA4:
      AND(getH()); 
      break; // AND H

    case 0xA5:
      AND(getL()); 
      break; // AND L

    case 0xA6:
      AND(memReadByte(HL)); 
      break; // AND (HL)

    case 0xA7:
      AND(getA()); 
      break; // AND A

    case 0xA8:
      XOR(getB()); 
      break; // XOR B

    case 0xA9:
      XOR(getC()); 
      break; // XOR C

    case 0xAA:
      XOR(getD()); 
      break; // XOR D

    case 0xAB:
      XOR(getE()); 
      break; // XOR E

    case 0xAC:
      XOR(getH()); 
      break; // XOR H

    case 0xAD:
      XOR(getL()); 
      break; // XOR L

    case 0xAE:
      XOR(memReadByte(HL)); 
      break; // XOR (HL)

    case 0xAF:
      XOR(getA()); 
      break; // XOR A

    case 0xB0:
      OR(getB()); 
      break; // OR B

    case 0xB1:
      OR(getC()); 
      break; // OR C

    case 0xB2:
      OR(getD()); 
      break; // OR D

    case 0xB3:
      OR(getE()); 
      break; // OR E

    case 0xB4:
      OR(getH()); 
      break; // OR H

    case 0xB5:
      OR(getL()); 
      break; // OR L

    case 0xB6:
      OR(memReadByte(HL)); 
      break; // OR (HL)

    case 0xB7:
      OR(getA()); 
      break; // OR A

    case 0xB8:
      CP(getB()); 
      break; // CP B

    case 0xB9:
      CP(getC()); 
      break; // CP C

    case 0xBA:
      CP(getD()); 
      break; // CP D

    case 0xBB:
      CP(getE()); 
      break; // CP E

    case 0xBC:
      CP(getH()); 
      break; // CP H

    case 0xBD:
      CP(getL()); 
      break; // CP L

    case 0xBE:
      CP(memReadByte(HL)); 
      break; // CP (HL)

    case 0xBF:
      CP(getA()); 
      break; // CP A

    case 0xC0:
      if ((AF & 0x40) == 0) {
        cyclesToDo -= 6;
        RET();
      } 
      break; // RET NZ

    case 0xC1:
      BC = POP(); 
      break; // POP BC

    case 0xC2: 
      if ((AF & 0x40) == 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      } 
      break; // JP NZ,nn

    case 0xC3:
      PC = memReadWord(PC);
      break; // JP nn

    case 0xC4:
      if ((AF & 0x40) == 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL NZ,nn

    case 0xC5:
      PUSH(BC); 
      break; // PUSH BC

    case 0xC6:
      ADD(memReadByte(PC++));
      break; // ADD nn

    case 0xC7:
      RST(0x00); 
      break; // RST 00h

    case 0xC8:
      if ((AF & 0x40) != 0) {
        cyclesToDo -= 6;
        RET();
      } 
      break; // RET Z

    case 0xC9:
      RET(); 
      break; // RET

    case 0xCA:
      if ((AF & 0x40) != 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      }
      break; // JP Z,nn

    case 0xCC:
      if ((AF & 0x40) != 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      }
      break; // CALL Z,nn

    case 0xCD:
      CALL(); 
      break; // CALL

    case 0xCE:
      ADC(memReadByte(PC++));
      break; // ADC nn

    case 0xCF:
      RST(0x08); 
      break; // RST 08h

    case 0xD0:
      if ((AF & 0x01) == 0) {
        RET();
      } 
      break; // RET NC

    case 0xD1:
      DE = POP(); 
      break; // POP DE

    case 0xD2:
      if ((AF & 0x01) == 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      }
      break; // JP NC,nn

    case 0xD3:
      ioWriteByte((getA() << 8) | memReadByte(PC++), getA()); 
      break; // OUT (N),A

    case 0xD4:
      if ((AF & 0x01) == 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL NC,nn

    case 0xD5:
      PUSH(DE); 
      break; // PUSH DE

    case 0xD6:
      SUB(memReadByte(PC++)); 
      break; // SUB n

    case 0xD7:
      RST(0x10); 
      break; // RST 10h

    case 0xD8:
      if ((AF & 0x01) != 0) {
        RET();
      } 
      break; // RET C

    case 0xD9:
      EXX(); 
      break; // EXX

    case 0xDA:
      if ((AF & 0x01) != 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      } 
      break; // JP C,nn

    case 0xDB:
      setA(ioReadByte((getA() << 8) | memReadByte(PC++))); 
      break; // IN A,N

    case 0xDC:
      if ((AF & 0x01) != 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL C,nn

    case 0xDE:
      SBC(memReadByte(PC++)); 
      break; // SBC n

    case 0xDF:
      RST(0x18); 
      break; // RST 18h

    case 0xE0:
      if ((AF & 0x04) == 0) {
        cyclesToDo -= 6;
        RET();
      } 
      break; // RET PO

    case 0xE1:
      HL = POP(); 
      break; // POP HL

    case 0xE2:
      if ((AF & 0x04) == 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      } 
      break; // JP PO,nn

    case 0xE3:
      word = HL;
      HL = memReadWord(SP);
      memWriteWord(SP, word); 
      break; // EX (SP),HL

    case 0xE4:
      if ((AF & 0x04) == 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL PO,nn

    case 0xE5:
      PUSH(HL); 
      break; // PUSH HL

    case 0xE6:
      AND(memReadByte(PC++)); 
      break; // AND n

    case 0xE7:
      RST(0x20); 
      break; // RST 20h

    case 0xE8:
      if ((AF & 0x04) != 0) {
        cyclesToDo -= 6;
        RET();
      } 
      break; // RET PE

    case 0xE9:
      PC = HL; 
      break; // JP HL

    case 0xEA:
      if ((AF & 0x04) != 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      } 
      break; // JP PE,nn

    case 0xEB:
      word = DE;
      DE = HL;
      HL = word; 
      break; // EX DE,HL

    case 0xEC:
      if ((AF & 0x04) != 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL PE,nn

    case 0xEE:
      XOR(memReadByte(PC++)); 
      break; // XOR n

    case 0xEF:
      RST(0x28); 
      break; // RST 28h

    case 0xF0:
      if ((AF & 0x80) == 0) {
        cyclesToDo -= 6;
        RET();
      } 
      break; // RET P

    case 0xF1:
      AF = POP(); 
      break; // POP AF

    case 0xF2:
      if ((AF & 0x80) == 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      } 
      break; // JP P,nn

    case 0xF3:
      IFF1 = IFF2 = 0; 
      break; // DI

    case 0xF4:
      if ((AF & 0x80) == 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL P,nn

    case 0xF5:
      PUSH(AF); 
      break; // PUSH AF

    case 0xF6:
      OR(memReadByte(PC++)); 
      break; // OR n

    case 0xF7:
      RST(0x30); 
      break; // RST 30h

    case 0xF8:
      if ((AF & 0x80) != 0) {
        cyclesToDo -= 6;
        RET();
      } 
      break; // RET M

    case 0xF9:
      SP = HL; 
      break; // LD SP,HL

    case 0xFA:
      if ((AF & 0x80) != 0) {
        PC = memReadWord(PC);
      } else {
        PC += 2;
      } 
      break; // JP M,nn

    case 0xFB:
      enable = 1; 
      break; // EI

    case 0xFC:
      if ((AF & 0x80) != 0) {
        cyclesToDo -= 7;
        CALL();
      } else {
        PC += 2;
      } 
      break; // CALL M,nn

    case 0xFE:
      CP(memReadByte(PC++));
      break; // CP nn

    case 0xFF:
      RST(0x38); 
      break; // RST 38h
    }
    cyclesToDo -= cycles_main_opcode[opcode];
  }
   
  private final void exe_ed_opcode(int opcode) {
      
    switch (opcode) {
    // CASE TABLE FOR ED OPCODES
    case 0x40:
      setB(IN()); 
      break; // IN B,(C)

    case 0x41:
      ioWriteByte(BC, getB()); 
      break; // OUT (C),B

    case 0x42:
      SBC_HL(BC); 
      break; // * SBC HL,BC

    case 0x43:
      memWriteWord(memReadWord(PC), BC);
      PC += 2; 
      break; // LD (NN),BC

    case 0x44:
      NEG(); 
      break; // NEG

    case 0x45:
      IFF1 = IFF2;
      RET();
      Interrupt(); 
      break; // * RETN

    case 0x46:
      IM = 0; 
      break; // * IM 0

    case 0x47:
      I = getA();
      break; // LD I,A (incomplete)

    case 0x48:
      setC(IN());
      break; // IN C,(C)

    case 0x49:
      ioWriteByte(BC, getC());
      break; // OUT (C),C

    case 0x4A:
      ADC_HL(BC); 
      break; // * ADC HL,BC

    case 0x4B:
      BC = memReadWord(memReadWord(PC));
      PC += 2; 
      break; // LD BC,(NN)

    case 0x4C:
      NEG();
      break; // NEG

    case 0x4D:
      IFF1 = 1;
      RET();
      break; // * RETI

    case 0x4E:
      IM = 0;
      break; // IM 0

    case 0x4F:
      R = getA();
      break; // LD R,A

    case 0x50:
      setD(IN()); 
      break; // IN D,(C)

    case 0x51:
      ioWriteByte(BC, getD()); 
      break; // OUT (C),D

    case 0x52:
      SBC_HL(DE); 
      break; // * SBC HL,DE

    case 0x53:
      memWriteWord(memReadWord(PC), DE);
      PC += 2; 
      break; // LD (NN),DE

    case 0x54:
      NEG(); 
      break; // NEG

    case 0x55:
      IFF1 = IFF2;
      RET();
      Interrupt(); 
      break; // * RETN

    case 0x56:
      IM = 1; 
      break; // * IM 1

    case 0x57:
      setA(I);
      if ((IFF2) != 0) {
        SetVF();
      } else {
        ClearVF();
      }
      SIGN_FLAG(getA(), 8);
      ZERO_FLAG(getA());
      ClearHF();
      YF_XF_FLAGS(getA());
      break; // LD A,I

    case 0x58:
      setE(IN()); 
      break; // IN E,(C)

    case 0x59:
      ioWriteByte(BC, getE()); 
      break; // OUT (C),E

    case 0x5A:
      ADC_HL(DE); 
      break; // ADC HL,DE

    case 0x5B:
      DE = memReadWord(memReadWord(PC));
      PC += 2;
      break; // LD DE,(NN)

    case 0x5C:
      NEG();
      break; // NEG

    case 0x5D:
      IFF1 = IFF2;
      RET();
      Interrupt();
      break; // RETN

    case 0x5E:
      IM = 2;
      break; // IM 2

    case 0x5F:
      setA(R);
      if ((IFF2) != 0) {
        SetVF();
      } else {
        ClearVF();
      }
      SIGN_FLAG(getA(), 8);
      ZERO_FLAG(getA());
      ClearHF();
      YF_XF_FLAGS(getA());
      ClearNF();
      break; // LD A,R

    case 0x60:
      setH(IN()); 
      break; // IN H,(C)

    case 0x61:
      ioWriteByte(BC, getH()); 
      break; // OUT (C),H

    case 0x62:
      SBC_HL(HL); 
      break; // SBC HL,HL

    case 0x63:
      memWriteWord(memReadWord(PC), HL);
      PC += 2; 
      break; // LD (NN),HL

    case 0x64:
      NEG();
      break; // NEG

    case 0x65:
      IFF1 = IFF2;
      RET();
      Interrupt();
      break; // RETN

    case 0x66:
      IM = 0; 
      break; // IM 0

    case 0x67:
      RRD(); 
      break; // * RRD

    case 0x68:
      setL(IN()); 
      break; // IN L,(C)

    case 0x69:
      ioWriteByte(BC, getL()); 
      break; // OUT (C),L

    case 0x6A:
      ADC_HL(HL); 
      break; // * ADC HL,HL

    case 0x6B:
      HL = memReadWord(memReadWord(PC));
      PC += 2; 
      break; // LD HL,(NN)

    case 0x6C:
      NEG(); 
      break; // NEG

    case 0x6D:
      IFF1 = IFF2;
      RET();
      Interrupt(); 
      break; // * RETN

    case 0x6E:
      IM = 0;
      break; // * IM 0

    case 0x6F:
      RLD(); 
      break; // * RLD

    case 0x70:
      IN(); 
      break; // IN (C)

    case 0x71:
      ioWriteByte(BC, 0); 
      break; // OUT (C),0

    case 0x72:
      SBC_HL(SP); 
      break; // SBC HL,SP

    case 0x73:
      memWriteWord(memReadWord(PC), SP);
      PC += 2; 
      break; // LD (NN),SP

    case 0x74:
      NEG();
      break; // NEG

    case 0x75:
      IFF1 = IFF2;
      RET();
      Interrupt(); 
      break; // * RETN

    case 0x76:
      IM = 2;
      break; // * IM 2

    case 0x78:
      setA(IN()); 
      break; // IN A,(C)

    case 0x79:
      ioWriteByte(BC, getA()); 
      break; // OUT (C),A

    case 0x7A:
      ADC_HL(SP); 
      break; // * ADC HL,SP

    case 0x7B:
      SP = memReadWord(memReadWord(PC));
      PC += 2; 
      break; // LD SP,(NN)

    case 0x7C:
      NEG();
      break; // NEG

    case 0x7D:
      IFF1 = IFF2;
      RET();
      Interrupt();
      break; // * RETN

    case 0x7E:
      IM = 2;
      break; // * IM 2

    case 0xA0:
      LDI();
      break; // LDI

    case 0xA1:
      CPI();
      break; // CPI

    case 0xA2:
      INI(); 
      break; // INI

    case 0xA3:
      OUTI(); 
      break; // OUTI

    case 0xA8:
      LDD(); 
      break; // LDD

    case 0xA9:
      CPD(); 
      break; // CPD

    case 0xAA:
      IND(); 
      break; // IND

    case 0xAB:
      OUTD();
      break; // OUTD

    case 0xB0:
      LDIR();
      break; // LDIR

    case 0xB1:
      CPIR();
      break; // CPIR

    case 0xB2:
      INIR();
      break; // INIR

    case 0xB3:
      OUTIR(); 
      break; // OUTIR

    case 0xB8:
      LDDR(); 
      break; // LDDR

    case 0xB9:
      CPDR(); 
      break; // CPDR

    case 0xBA:
      INDR(); 
      break; // INDR

    case 0xBB:
      OUTDR(); 
      break; // OUTDR
         
    default: // Should not happen :)
      break;
    }
    cyclesToDo -= cycles_ed_opcode[opcode];
  }
   
  private final void exe_cb_opcode(int opcode) {
      
    switch (opcode) {
    // CASE TABLE FOR CB OPCODES
         
    case 0x00:
      setB(RLC(getB()));
      break;

    case 0x01:
      setC(RLC(getC()));
      break;

    case 0x02:
      setD(RLC(getD()));
      break;

    case 0x03:
      setE(RLC(getE()));
      break;

    case 0x04:
      setH(RLC(getH()));
      break;

    case 0x05:
      setL(RLC(getL()));
      break;

    case 0x06:
      memWriteByte(HL, RLC(memReadByte(HL)));
      break;

    case 0x07:
      setA(RLC(getA()));
      break;

    case 0x08:
      setB(RRC(getB()));
      break;

    case 0x09:
      setC(RRC(getC()));
      break;

    case 0x0A:
      setD(RRC(getD()));
      break;

    case 0x0B:
      setE(RRC(getE()));
      break;

    case 0x0C:
      setH(RRC(getH()));
      break;

    case 0x0D:
      setL(RRC(getL()));
      break;

    case 0x0E:
      memWriteByte(HL, RRC(memReadByte(HL)));
      break;

    case 0x0F:
      setA(RRC(getA()));
      break;

    case 0x10:
      setB(RL(getB()));
      break;

    case 0x11:
      setC(RL(getC()));
      break;

    case 0x12:
      setD(RL(getD()));
      break;

    case 0x13:
      setE(RL(getE()));
      break;

    case 0x14:
      setH(RL(getH()));
      break;

    case 0x15:
      setL(RL(getL()));
      break;

    case 0x16:
      memWriteByte(HL, RL(memReadByte(HL)));
      break;

    case 0x17:
      setA(RL(getA()));
      break;

    case 0x18:
      setB(RR(getB()));
      break;

    case 0x19:
      setC(RR(getC()));
      break;

    case 0x1A:
      setD(RR(getD()));
      break;

    case 0x1B:
      setE(RR(getE()));
      break;

    case 0x1C:
      setH(RR(getH()));
      break;

    case 0x1D:
      setL(RR(getL()));
      break;

    case 0x1E:
      memWriteByte(HL, RR(memReadByte(HL)));
      break;

    case 0x1F:
      setA(RR(getA()));
      break;

    case 0x20:
      setB(SLA(getB()));
      break;

    case 0x21:
      setC(SLA(getC()));
      break;

    case 0x22:
      setD(SLA(getD()));
      break;

    case 0x23:
      setE(SLA(getE()));
      break;

    case 0x24:
      setH(SLA(getH()));
      break;

    case 0x25:
      setL(SLA(getL()));
      break;

    case 0x26:
      memWriteByte(HL, SLA(memReadByte(HL)));
      break;

    case 0x27:
      setA(SLA(getA()));
      break;

    case 0x28:
      setB(SRA(getB()));
      break;

    case 0x29:
      setC(SRA(getC()));
      break;

    case 0x2A:
      setD(SRA(getD()));
      break;

    case 0x2B:
      setE(SRA(getE()));
      break;

    case 0x2C:
      setH(SRA(getH()));
      break;

    case 0x2D:
      setL(SRA(getL()));
      break;

    case 0x2E:
      memWriteByte(HL, SRA(memReadByte(HL)));
      break;

    case 0x2F:
      setA(SRA(getA()));
      break;

    case 0x30:
      setB(SLL(getB()));
      break;

    case 0x31:
      setC(SLL(getC()));
      break;

    case 0x32:
      setD(SLL(getD()));
      break;

    case 0x33:
      setE(SLL(getE()));
      break;

    case 0x34:
      setH(SLL(getH()));
      break;

    case 0x35:
      setL(SLL(getL()));
      break;

    case 0x36:
      memWriteByte(HL, SLL(memReadByte(HL)));
      break;

    case 0x37:
      setA(SLL(getA()));
      break;

    case 0x38:
      setB(SRL(getB()));
      break;

    case 0x39:
      setC(SRL(getC()));
      break;

    case 0x3A:
      setD(SRL(getD()));
      break;

    case 0x3B:
      setE(SRL(getE()));
      break;

    case 0x3C:
      setH(SRL(getH()));
      break;

    case 0x3D:
      setL(SRL(getL()));
      break;

    case 0x3E:
      memWriteByte(HL, SRL(memReadByte(HL)));
      break;

    case 0x3F:
      setA(SRL(getA()));
      break;

    case 0x40:
      BIT(0, getB());
      break;

    case 0x41:
      BIT(0, getC());
      break;

    case 0x42:
      BIT(0, getD());
      break;

    case 0x43:
      BIT(0, getE());
      break;

    case 0x44:
      BIT(0, getH());
      break;

    case 0x45:
      BIT(0, getL());
      break;

    case 0x46:
      BIT(0, memReadByte(HL));
      break;

    case 0x47:
      BIT(0, getA());
      break;

    case 0x48:
      BIT(1, getB());
      break;

    case 0x49:
      BIT(1, getC());
      break;

    case 0x4A:
      BIT(1, getD());
      break;

    case 0x4B:
      BIT(1, getE());
      break;

    case 0x4C:
      BIT(1, getH());
      break;

    case 0x4D:
      BIT(1, getL());
      break;

    case 0x4E:
      BIT(1, memReadByte(HL));
      break;

    case 0x4F:
      BIT(1, getA());
      break;

    case 0x50:
      BIT(2, getB());
      break;

    case 0x51:
      BIT(2, getC());
      break;

    case 0x52:
      BIT(2, getD());
      break;

    case 0x53:
      BIT(2, getE());
      break;

    case 0x54:
      BIT(2, getH());
      break;

    case 0x55:
      BIT(2, getL());
      break;

    case 0x56:
      BIT(2, memReadByte(HL));
      break;

    case 0x57:
      BIT(2, getA());
      break;

    case 0x58:
      BIT(3, getB());
      break;

    case 0x59:
      BIT(3, getC());
      break;

    case 0x5A:
      BIT(3, getD());
      break;

    case 0x5B:
      BIT(3, getE());
      break;

    case 0x5C:
      BIT(3, getH());
      break;

    case 0x5D:
      BIT(3, getL());
      break;

    case 0x5E:
      BIT(3, memReadByte(HL));
      break;

    case 0x5F:
      BIT(3, getA());
      break;

    case 0x60:
      BIT(4, getB());
      break;

    case 0x61:
      BIT(4, getC());
      break;

    case 0x62:
      BIT(4, getD());
      break;

    case 0x63:
      BIT(4, getE());
      break;

    case 0x64:
      BIT(4, getH());
      break;

    case 0x65:
      BIT(4, getL());
      break;

    case 0x66:
      BIT(4, memReadByte(HL));
      break;

    case 0x67:
      BIT(4, getA());
      break;

    case 0x68:
      BIT(5, getB());
      break;

    case 0x69:
      BIT(5, getC());
      break;

    case 0x6A:
      BIT(5, getD());
      break;

    case 0x6B:
      BIT(5, getE());
      break;

    case 0x6C:
      BIT(5, getH());
      break;

    case 0x6D:
      BIT(5, getL());
      break;

    case 0x6E:
      BIT(5, memReadByte(HL));
      break;

    case 0x6F:
      BIT(5, getA());
      break;

    case 0x70:
      BIT(6, getB());
      break;

    case 0x71:
      BIT(6, getC());
      break;

    case 0x72:
      BIT(6, getD());
      break;

    case 0x73:
      BIT(6, getE());
      break;

    case 0x74:
      BIT(6, getH());
      break;

    case 0x75:
      BIT(6, getL());
      break;

    case 0x76:
      BIT(6, memReadByte(HL));
      break;

    case 0x77:
      BIT(6, getA());
      break;

    case 0x78:
      BIT(7, getB());
      break;

    case 0x79:
      BIT(7, getC());
      break;

    case 0x7A:
      BIT(7, getD());
      break;

    case 0x7B:
      BIT(7, getE());
      break;

    case 0x7C:
      BIT(7, getH());
      break;

    case 0x7D:
      BIT(7, getL());
      break;

    case 0x7E:
      BIT(7, memReadByte(HL));
      break;

    case 0x7F:
      BIT(7, getA());
      break;

    case 0x80:
      setB(RES(0, getB()));
      break;

    case 0x81:
      setC(RES(0, getC()));
      break;

    case 0x82:
      setD(RES(0, getD()));
      break;

    case 0x83:
      setE(RES(0, getE()));
      break;

    case 0x84:
      setH(RES(0, getH()));
      break;

    case 0x85:
      setL(RES(0, getL()));
      break;

    case 0x86:
      memWriteByte(HL, RES(0, memReadByte(HL)));
      break;

    case 0x87:
      setA(RES(0, getA()));
      break;

    case 0x88:
      setB(RES(1, getB()));
      break;

    case 0x89:
      setC(RES(1, getC()));
      break;

    case 0x8A:
      setD(RES(1, getD()));
      break;

    case 0x8B:
      setE(RES(1, getE()));
      break;

    case 0x8C:
      setH(RES(1, getH()));
      break;

    case 0x8D:
      setL(RES(1, getL()));
      break;

    case 0x8E:
      memWriteByte(HL, RES(1, memReadByte(HL)));
      break;

    case 0x8F:
      setA(RES(1, getA()));
      break;

    case 0x90:
      setB(RES(2, getB()));
      break;

    case 0x91:
      setC(RES(2, getC()));
      break;

    case 0x92:
      setD(RES(2, getD()));
      break;

    case 0x93:
      setE(RES(2, getE()));
      break;

    case 0x94:
      setH(RES(2, getH()));
      break;

    case 0x95:
      setL(RES(2, getL()));
      break;

    case 0x96:
      memWriteByte(HL, RES(2, memReadByte(HL)));
      break;

    case 0x97:
      setA(RES(2, getA()));
      break;

    case 0x98:
      setB(RES(3, getB()));
      break;

    case 0x99:
      setC(RES(3, getC()));
      break;

    case 0x9A:
      setD(RES(3, getD()));
      break;

    case 0x9B:
      setE(RES(3, getE()));
      break;

    case 0x9C:
      setH(RES(3, getH()));
      break;

    case 0x9D:
      setL(RES(3, getL()));
      break;

    case 0x9E:
      memWriteByte(HL, RES(3, memReadByte(HL)));
      break;

    case 0x9F:
      setA(RES(3, getA()));
      break;

    case 0xA0:
      setB(RES(4, getB()));
      break;

    case 0xA1:
      setC(RES(4, getC()));
      break;

    case 0xA2:
      setD(RES(4, getD()));
      break;

    case 0xA3:
      setE(RES(4, getE()));
      break;

    case 0xA4:
      setH(RES(4, getH()));
      break;

    case 0xA5:
      setL(RES(4, getL()));
      break;

    case 0xA6:
      memWriteByte(HL, RES(4, memReadByte(HL)));
      break;

    case 0xA7:
      setA(RES(4, getA()));
      break;

    case 0xA8:
      setB(RES(5, getB()));
      break;

    case 0xA9:
      setC(RES(5, getC()));
      break;

    case 0xAA:
      setD(RES(5, getD()));
      break;

    case 0xAB:
      setE(RES(5, getE()));
      break;

    case 0xAC:
      setH(RES(5, getH()));
      break;

    case 0xAD:
      setL(RES(5, getL()));
      break;

    case 0xAE:
      memWriteByte(HL, RES(5, memReadByte(HL)));
      break;

    case 0xAF:
      setA(RES(5, getA()));
      break;

    case 0xB0:
      setB(RES(6, getB()));
      break;

    case 0xB1:
      setC(RES(6, getC()));
      break;

    case 0xB2:
      setD(RES(6, getD()));
      break;

    case 0xB3:
      setE(RES(6, getE()));
      break;

    case 0xB4:
      setH(RES(6, getH()));
      break;

    case 0xB5:
      setL(RES(6, getL()));
      break;

    case 0xB6:
      memWriteByte(HL, RES(6, memReadByte(HL)));
      break;

    case 0xB7:
      setA(RES(6, getA()));
      break;

    case 0xB8:
      setB(RES(7, getB()));
      break;

    case 0xB9:
      setC(RES(7, getC()));
      break;

    case 0xBA:
      setD(RES(7, getD()));
      break;

    case 0xBB:
      setE(RES(7, getE()));
      break;

    case 0xBC:
      setH(RES(7, getH()));
      break;

    case 0xBD:
      setL(RES(7, getL()));
      break;

    case 0xBE:
      memWriteByte(HL, RES(7, memReadByte(HL)));
      break;

    case 0xBF:
      setA(RES(7, getA()));
      break;

    case 0xC0:
      setB(SET(0, getB()));
      break;

    case 0xC1:
      setC(SET(0, getC()));
      break;

    case 0xC2:
      setD(SET(0, getD()));
      break;

    case 0xC3:
      setE(SET(0, getE()));
      break;

    case 0xC4:
      setH(SET(0, getH()));
      break;

    case 0xC5:
      setL(SET(0, getL()));
      break;

    case 0xC6:
      memWriteByte(HL, SET(0, memReadByte(HL)));
      break;

    case 0xC7:
      setA(SET(0, getA()));
      break;

    case 0xC8:
      setB(SET(1, getB()));
      break;

    case 0xC9:
      setC(SET(1, getC()));
      break;

    case 0xCA:
      setD(SET(1, getD()));
      break;

    case 0xCB:
      setE(SET(1, getE()));
      break;

    case 0xCC:
      setH(SET(1, getH()));
      break;

    case 0xCD:
      setL(SET(1, getL()));
      break;

    case 0xCE:
      memWriteByte(HL, SET(1, memReadByte(HL)));
      break;

    case 0xCF:
      setA(SET(1, getA()));
      break;

    case 0xD0:
      setB(SET(2, getB()));
      break;

    case 0xD1:
      setC(SET(2, getC()));
      break;

    case 0xD2:
      setD(SET(2, getD()));
      break;

    case 0xD3:
      setE(SET(2, getE()));
      break;

    case 0xD4:
      setH(SET(2, getH()));
      break;

    case 0xD5:
      setL(SET(2, getL()));
      break;

    case 0xD6:
      memWriteByte(HL, SET(2, memReadByte(HL)));
      break;

    case 0xD7:
      setA(SET(2, getA()));
      break;

    case 0xD8:
      setB(SET(3, getB()));
      break;

    case 0xD9:
      setC(SET(3, getC()));
      break;

    case 0xDA:
      setD(SET(3, getD()));
      break;

    case 0xDB:
      setE(SET(3, getE()));
      break;

    case 0xDC:
      setH(SET(3, getH()));
      break;

    case 0xDD:
      setL(SET(3, getL()));
      break;

    case 0xDE:
      memWriteByte(HL, SET(3, memReadByte(HL)));
      break;

    case 0xDF:
      setA(SET(3, getA()));
      break;

    case 0xE0:
      setB(SET(4, getB()));
      break;

    case 0xE1:
      setC(SET(4, getC()));
      break;

    case 0xE2:
      setD(SET(4, getD()));
      break;

    case 0xE3:
      setE(SET(4, getE()));
      break;

    case 0xE4:
      setH(SET(4, getH()));
      break;

    case 0xE5:
      setL(SET(4, getL()));
      break;

    case 0xE6:
      memWriteByte(HL, SET(4, memReadByte(HL)));
      break;

    case 0xE7:
      setA(SET(4, getA()));
      break;

    case 0xE8:
      setB(SET(5, getB()));
      break;

    case 0xE9:
      setC(SET(5, getC()));
      break;

    case 0xEA:
      setD(SET(5, getD()));
      break;

    case 0xEB:
      setE(SET(5, getE()));
      break;

    case 0xEC:
      setH(SET(5, getH()));
      break;

    case 0xED:
      setL(SET(5, getL()));
      break;

    case 0xEE:
      memWriteByte(HL, SET(5, memReadByte(HL)));
      break;

    case 0xEF:
      setA(SET(5, getA()));
      break;

    case 0xF0:
      setB(SET(6, getB()));
      break;

    case 0xF1:
      setC(SET(6, getC()));
      break;

    case 0xF2:
      setD(SET(6, getD()));
      break;

    case 0xF3:
      setE(SET(6, getE()));
      break;

    case 0xF4:
      setH(SET(6, getH()));
      break;

    case 0xF5:
      setL(SET(6, getL()));
      break;

    case 0xF6:
      memWriteByte(HL, SET(6, memReadByte(HL)));
      break;

    case 0xF7:
      setA(SET(6, getA()));
      break;

    case 0xF8:
      setB(SET(7, getB()));
      break;

    case 0xF9:
      setC(SET(7, getC()));
      break;

    case 0xFA:
      setD(SET(7, getD()));
      break;

    case 0xFB:
      setE(SET(7, getE()));
      break;

    case 0xFC:
      setH(SET(7, getH()));
      break;

    case 0xFD:
      setL(SET(7, getL()));
      break;

    case 0xFE:
      memWriteByte(HL, SET(7, memReadByte(HL)));
      break;

    case 0xFF:
      setA(SET(7, getA()));
      break;
    }
    cyclesToDo -= cycles_cb_opcode[opcode];
  }
   
  private final int exe_dd_opcode(int index, int opcode) {
    XY = index;
    switch (opcode) {
    // CASE TABLE FOR DD OPCODES
         
    case 0xCB:
      exe_dd_cb_opcode(memReadByte(++PC));
      break; // Prefix

    case 0xED:
      exe_ed_opcode(memReadByte(PC++));
      break; // Redirecting

    case 0xDD:
      IX = exe_dd_opcode(IX, memReadByte(PC++));
      break; // Redirecting

    case 0xFD:
      IY = exe_dd_opcode(IY, memReadByte(PC++));
      break; // Redirecting

    case 0x09:
      XY = ADD16(XY, BC);
      break; // ADD XY,BC

    case 0x19:
      XY = ADD16(XY, DE);
      break; // ADD XY,DE

    case 0x21:
      XY = memReadWord(PC);
      PC += 2;
      break; // LD XY,NN

    case 0x22:
      memWriteWord(memReadWord(PC), XY);
      PC += 2;
      break; // LD (NN),XY

    case 0x23:
      XY++;
      XY &= 0xFFFF;
      break; // INC XY

    case 0x24:
      setXYH(INC(getXYH()));
      break; // INC XYH

    case 0x25:
      setXYH(DEC(getXYH()));
      break; // DEC XYH

    case 0x26:
      setXYH(memReadByte(PC++)); 
      break; // LD XYH,N

    case 0x29:
      XY = ADD16(XY, XY);
      break; // ADD XY,XY

    case 0x2A:
      XY = memReadWord(memReadWord(PC));
      PC += 2;
      break; // LD XY,(NN)

    case 0x2B:
      XY--;
      XY &= 0xFFFF;
      break; // DEC XY

    case 0x2C:
      setXYL(INC(getXYL()));
      break; // INC XYL

    case 0x2D:
      setXYL(DEC(getXYL()));
      break; // DEC XYL

    case 0x2E:
      setXYL(memReadByte(PC++)); 
      break; // LD XYL,N

    case 0x34:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, INC(memReadByte(word))); 
      break; // INC (XY+dd)

    case 0x35:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, DEC(memReadByte(word)));
      break; // DEC (XY+dd)

    case 0x36:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, memReadByte(PC++));
      break; // LD (XY+d),N

    case 0x39:
      XY = ADD16(XY, SP);
      break; // ADD XY,SP

    case 0x44:
      setB(getXYH());
      break; // LD B,XYH

    case 0x45:
      setB(getXYL());
      break; // LD B,XYL

    case 0x46:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setB(memReadByte(word)); 
      break; // LD B,(XY+N)

    case 0x4C:
      setC(getXYH());
      break; // LD C,XYH

    case 0x4D:
      setC(getXYL());
      break; // LD C,XYL

    case 0x4E:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setC(memReadByte(word)); 
      break; // LD C,(XY+N)

    case 0x54:
      setD(getXYH());
      break; // LD D,XYH

    case 0x55:
      setD(getXYL());
      break; // LD D,XYL

    case 0x56:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setD(memReadByte(word)); 
      break; // LD D,(XY+N)

    case 0x5C:
      setE(getXYH());
      break; // LD E,XYH

    case 0x5D:
      setE(getXYL());
      break; // LD E,XYL

    case 0x5E:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setE(memReadByte(word)); 
      break; // LD E,(XY+N)

    case 0x60:
      setXYH(getB());
      break; // LD XYH,B

    case 0x61:
      setXYH(getC());
      break; // LD XYH,C

    case 0x62:
      setXYH(getD());
      break; // LD XYH,D

    case 0x63:
      setXYH(getE());
      break; // LD XYH,E

    case 0x64:
      break; // LD XYH,XYH

    case 0x65:
      setXYH(getXYL());
      break; // LD XYH,XYL

    case 0x66:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setH(memReadByte(word)); 
      break; // LD H,(XY+d)

    case 0x67:
      setXYH(getA());
      break; // LD XYH,A

    case 0x68:
      setXYL(getB());
      break; // LD XYL,B

    case 0x69:
      setXYL(getC());
      break; // LD XYL,C

    case 0x6A:
      setXYL(getD());
      break; // LD XYL,D

    case 0x6B:
      setXYL(getE());
      break; // LD XYL,E

    case 0x6C:
      setXYL(getXYH());
      break; // LD XYL,XYH

    case 0x6D:
      break; // LD XYL,XYL

    case 0x6E:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setL(memReadByte(word)); 
      break; // LD L,(XY+d)

    case 0x6F:
      setXYL(getA());
      break; // LD XYL,A

    case 0x70:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getB()); 
      break; // LD (XY+d),B

    case 0x71:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getC()); 
      break; // LD (XY+d),C

    case 0x72:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getD()); 
      break; // LD (XY+d),D

    case 0x73:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getE()); 
      break; // LD (XY+d,E

    case 0x74:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getH()); 
      break; // LD (XY+d),H

    case 0x75:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getL()); 
      break; // LD (XY+d),L

    case 0x77:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      memWriteByte(word, getA()); 
      break; // LD (XY+d),A

    case 0x7C:
      setA(getXYH());
      break;

    case 0x7D:
      setA(getXYL());
      break;

    case 0x7E:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      setA(memReadByte(word)); 
      break; // LD A,(XY+d)

    case 0x84:
      ADD(getXYH());
      break; // ADD A,XYH

    case 0x85:
      ADD(getXYL());
      break; // ADD A,XYL

    case 0x86:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      ADD(memReadByte(word)); 
      break; // ADD A,(XY+d)

    case 0x8C:
      ADC(getXYH());
      break; // ADC A,XYH

    case 0x8D:
      ADC(getXYL());
      break; // ADC A,XYL

    case 0x8E:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      ADC(memReadByte(word)); 
      break; // ADC A,(XY+d)

    case 0x94:
      SUB(getXYH());
      break; // SUB A,XYH

    case 0x95:
      SUB(getXYL());
      break; // SUB A,XYL

    case 0x96:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      SUB(memReadByte(word)); 
      break; // SUB A,(XY+d)

    case 0x9C:
      SBC(getXYH());
      break; // SBC A,XYH

    case 0x9D:
      SBC(getXYL());
      break; // SBC A,XYL

    case 0x9E:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      SBC(memReadByte(word)); 
      break; // SBC A,(XY+d)

    case 0xA4:
      AND(getXYH());
      break; // AND XYH

    case 0xA5:
      AND(getXYL());
      break; // AND XYL

    case 0xA6:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      AND(memReadByte(word)); 
      break; // AND (XY+d)

    case 0xAC:
      XOR(getXYH());
      break; // XOR XYH

    case 0xAD:
      XOR(getXYL());
      break; // XOR XYL

    case 0xAE:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      XOR(memReadByte(word)); 
      break; // XOR (XY+d)

    case 0xB4:
      OR(getXYH());
      break; // OR XYH

    case 0xB5:
      OR(getXYL());
      break; // OR XYL

    case 0xB6:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      OR(memReadByte(word)); 
      break; // OR (XY+d)

    case 0xBC:
      CP(getXYH());
      break; // CP XYH

    case 0xBD:
      CP(getXYL());
      break; // CP XYL

    case 0xBE:
      word = XY + (byte) (memReadByte(PC++));
      word &= 0xFFFF;
      CP(memReadByte(word)); 
      break; // CP (XY+d)

    case 0xE1:
      XY = POP();
      break; // POP XY

    case 0xE3:
      word = memReadWord(SP);
      memWriteWord(SP, XY);
      XY = word;
      break; // EX (SP),XY

    case 0xE5:
      PUSH(XY);
      break; // PUSH XY

    case 0xE9:
      PC = XY;
      break; // JP XY

    case 0xF9:
      SP = XY;
      break; // LD SP,XY
    }
    cyclesToDo -= cycles_dd_opcode[opcode];
    return XY;
  }
   
  private final void exe_dd_cb_opcode(int opcode) {

    PC--;
    switch (opcode) {
    // CASE TABLE FOR DD-CB OPCODES
    case 0x00:
      setB(LD_RLC(XY));
      break;

    case 0x01:
      setC(LD_RLC(XY));
      break;

    case 0x02:
      setD(LD_RLC(XY));
      break;

    case 0x03:
      setE(LD_RLC(XY));
      break;

    case 0x04:
      setH(LD_RLC(XY));
      break;

    case 0x05:
      setL(LD_RLC(XY));
      break;

    case 0x06:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RLC(memReadByte(addr))); 
      break;

    case 0x07:
      setA(LD_RLC(XY));
      break;

    case 0x08:
      setB(LD_RRC(XY));
      break;

    case 0x09:
      setC(LD_RRC(XY));
      break;

    case 0x0A:
      setD(LD_RRC(XY));
      break;

    case 0x0B:
      setE(LD_RRC(XY));
      break;

    case 0x0C:
      setH(LD_RRC(XY));
      break;

    case 0x0D:
      setL(LD_RRC(XY));
      break;

    case 0x0E:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RRC(memReadByte(addr))); 
      break;

    case 0x0F:
      setA(LD_RRC(XY));
      break;

    case 0x10:
      setB(LD_RL(XY));
      break;

    case 0x11:
      setC(LD_RL(XY));
      break;

    case 0x12:
      setD(LD_RL(XY));
      break;

    case 0x13:
      setE(LD_RL(XY));
      break;

    case 0x14:
      setH(LD_RL(XY));
      break;

    case 0x15:
      setL(LD_RL(XY));
      break;

    case 0x16:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RL(memReadByte(addr))); 
      break;

    case 0x17:
      setA(LD_RL(XY));
      break;

    case 0x18:
      setB(LD_RR(XY));
      break;

    case 0x19:
      setC(LD_RR(XY));
      break;

    case 0x1A:
      setD(LD_RR(XY));
      break;

    case 0x1B:
      setE(LD_RR(XY));
      break;

    case 0x1C:
      setH(LD_RR(XY));
      break;

    case 0x1D:
      setL(LD_RR(XY));
      break;

    case 0x1E:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RR(memReadByte(addr))); 
      break;

    case 0x1F:
      setA(LD_RR(XY));
      break;

    case 0x20:
      setB(LD_SLA(XY));
      break;

    case 0x21:
      setC(LD_SLA(XY));
      break;

    case 0x22:
      setD(LD_SLA(XY));
      break;

    case 0x23:
      setE(LD_SLA(XY));
      break;

    case 0x24:
      setH(LD_SLA(XY));
      break;

    case 0x25:
      setL(LD_SLA(XY));
      break;

    case 0x26:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SLA(memReadByte(addr))); 
      break;

    case 0x27:
      setA(LD_SLA(XY));
      break;

    case 0x28:
      setB(LD_SRA(XY));
      break;

    case 0x29:
      setC(LD_SRA(XY));
      break;

    case 0x2A:
      setD(LD_SRA(XY));
      break;

    case 0x2B:
      setE(LD_SRA(XY));
      break;

    case 0x2C:
      setH(LD_SRA(XY));
      break;

    case 0x2D:
      setL(LD_SRA(XY));
      break;

    case 0x2E:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SRA(memReadByte(addr))); 
      break;

    case 0x2F:
      setA(LD_SRA(XY));
      break;

    case 0x30:
      setB(LD_SLL(XY));
      break;

    case 0x31:
      setC(LD_SLL(XY));
      break;

    case 0x32:
      setD(LD_SLL(XY));
      break;

    case 0x33:
      setE(LD_SLL(XY));
      break;

    case 0x34:
      setH(LD_SLL(XY));
      break;

    case 0x35:
      setL(LD_SLL(XY));
      break;

    case 0x36:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SLL(memReadByte(addr))); 
      break;

    case 0x37:
      setA(LD_SLL(XY));
      break;

    case 0x38:
      setB(LD_SRL(XY));
      break;

    case 0x39:
      setC(LD_SRL(XY));
      break;

    case 0x3A:
      setD(LD_SRL(XY));
      break;

    case 0x3B:
      setE(LD_SRL(XY));
      break;

    case 0x3C:
      setH(LD_SRL(XY));
      break;

    case 0x3D:
      setL(LD_SRL(XY));
      break;

    case 0x3E:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SRL(memReadByte(addr))); 
      break;

    case 0x3F:
      setA(LD_SRL(XY));
      break;

    case 0x40:
    case 0x41:
    case 0x42:
    case 0x43:
    case 0x44:
    case 0x45:
    case 0x46:
    case 0x47:
      BIT(0, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x48:
    case 0x49:
    case 0x4A:
    case 0x4B:
    case 0x4C:
    case 0x4D:
    case 0x4E:
    case 0x4F:
      BIT(1, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x50:
    case 0x51:
    case 0x52:
    case 0x53:
    case 0x54:
    case 0x55:
    case 0x56:
    case 0x57:
      BIT(2, memReadByte(XY + (byte) (memReadByte(PC++))));
      break;

    case 0x58:
    case 0x59:
    case 0x5A:
    case 0x5B:
    case 0x5C:
    case 0x5D:
    case 0x5E:
    case 0x5F:
      BIT(3, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x60:
    case 0x61:
    case 0x62:
    case 0x63:
    case 0x64:
    case 0x65:
    case 0x66:
    case 0x67:
      BIT(4, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x68:
    case 0x69:
    case 0x6A:
    case 0x6B:
    case 0x6C:
    case 0x6D:
    case 0x6E:
    case 0x6F:
      BIT(5, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x70:
    case 0x71:
    case 0x72:
    case 0x73:
    case 0x74:
    case 0x75:
    case 0x76:
    case 0x77:
      BIT(6, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x78:
    case 0x79:
    case 0x7A:
    case 0x7B:
    case 0x7C:
    case 0x7D:
    case 0x7E:
    case 0x7F:
      BIT(7, memReadByte(XY + (byte) (memReadByte(PC++)))); 
      break;

    case 0x80:
      setB(LD_RES(XY, 0));
      break;

    case 0x81:
      setC(LD_RES(XY, 0));
      break;

    case 0x82:
      setD(LD_RES(XY, 0));
      break;

    case 0x83:
      setE(LD_RES(XY, 0));
      break;

    case 0x84:
      setH(LD_RES(XY, 0));
      break;

    case 0x85:
      setL(LD_RES(XY, 0));
      break;

    case 0x86:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(0, memReadByte(addr))); 
      break;

    case 0x87:
      setA(LD_RES(XY, 0));
      break;

    case 0x88:
      setB(LD_RES(XY, 1));
      break;

    case 0x89:
      setC(LD_RES(XY, 1));
      break;

    case 0x8A:
      setD(LD_RES(XY, 1));
      break;

    case 0x8B:
      setE(LD_RES(XY, 1));
      break;

    case 0x8C:
      setH(LD_RES(XY, 1));
      break;

    case 0x8D:
      setL(LD_RES(XY, 1));
      break;

    case 0x8E:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(1, memReadByte(addr))); 
      break;

    case 0x8F:
      setA(LD_RES(XY, 1));
      break;

    case 0x90:
      setB(LD_RES(XY, 2));
      break;

    case 0x91:
      setC(LD_RES(XY, 2));
      break;

    case 0x92:
      setD(LD_RES(XY, 2));
      break;

    case 0x93:
      setE(LD_RES(XY, 2));
      break;

    case 0x94:
      setH(LD_RES(XY, 2));
      break;

    case 0x95:
      setL(LD_RES(XY, 2));
      break;

    case 0x96:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(2, memReadByte(addr))); 
      break;

    case 0x97:
      setA(LD_RES(XY, 2));
      break;

    case 0x98:
      setB(LD_RES(XY, 3));
      break;

    case 0x99:
      setC(LD_RES(XY, 3));
      break;

    case 0x9A:
      setD(LD_RES(XY, 3));
      break;

    case 0x9B:
      setE(LD_RES(XY, 3));
      break;

    case 0x9C:
      setH(LD_RES(XY, 3));
      break;

    case 0x9D:
      setL(LD_RES(XY, 3));
      break;

    case 0x9E:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(3, memReadByte(addr))); 
      break;

    case 0x9F:
      setA(LD_RES(XY, 3));
      break;

    case 0xA0:
      setB(LD_RES(XY, 4));
      break;

    case 0xA1:
      setC(LD_RES(XY, 4));
      break;

    case 0xA2:
      setD(LD_RES(XY, 4));
      break;

    case 0xA3:
      setE(LD_RES(XY, 4));
      break;

    case 0xA4:
      setH(LD_RES(XY, 4));
      break;

    case 0xA5:
      setL(LD_RES(XY, 4));
      break;

    case 0xA6:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(4, memReadByte(addr))); 
      break;

    case 0xA7:
      setA(LD_RES(XY, 4));
      break;

    case 0xA8:
      setB(LD_RES(XY, 5));
      break;

    case 0xA9:
      setC(LD_RES(XY, 5));
      break;

    case 0xAA:
      setD(LD_RES(XY, 5));
      break;

    case 0xAB:
      setE(LD_RES(XY, 5));
      break;

    case 0xAC:
      setH(LD_RES(XY, 5));
      break;

    case 0xAD:
      setL(LD_RES(XY, 5));
      break;

    case 0xAE:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(5, memReadByte(addr))); 
      break;

    case 0xAF:
      setA(LD_RES(XY, 5));
      break;

    case 0xB0:
      setB(LD_RES(XY, 6));
      break;

    case 0xB1:
      setC(LD_RES(XY, 6));
      break;

    case 0xB2:
      setD(LD_RES(XY, 6));
      break;

    case 0xB3:
      setE(LD_RES(XY, 6));
      break;

    case 0xB4:
      setH(LD_RES(XY, 6));
      break;

    case 0xB5:
      setL(LD_RES(XY, 6));
      break;

    case 0xB6:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(6, memReadByte(addr))); 
      break;

    case 0xB7:
      setA(LD_RES(XY, 6));
      break;

    case 0xB8:
      setB(LD_RES(XY, 7));
      break;

    case 0xB9:
      setC(LD_RES(XY, 7));
      break;

    case 0xBA:
      setD(LD_RES(XY, 7));
      break;

    case 0xBB:
      setE(LD_RES(XY, 7));
      break;

    case 0xBC:
      setH(LD_RES(XY, 7));
      break;

    case 0xBD:
      setL(LD_RES(XY, 7));
      break;

    case 0xBE:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, RES(7, memReadByte(addr))); 
      break;

    case 0xBF:
      setA(LD_RES(XY, 7));
      break;

    case 0xC0:
      setB(LD_SET(XY, 0));
      break;

    case 0xC1:
      setC(LD_SET(XY, 0));
      break;

    case 0xC2:
      setD(LD_SET(XY, 0));
      break;

    case 0xC3:
      setE(LD_SET(XY, 0));
      break;

    case 0xC4:
      setH(LD_SET(XY, 0));
      break;

    case 0xC5:
      setL(LD_SET(XY, 0));
      break;

    case 0xC6:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(0, memReadByte(addr))); 
      break;

    case 0xC7:
      setA(LD_SET(XY, 0));
      break;

    case 0xC8:
      setB(LD_SET(XY, 1));
      break;

    case 0xC9:
      setC(LD_SET(XY, 1));
      break;

    case 0xCA:
      setD(LD_SET(XY, 1));
      break;

    case 0xCB:
      setE(LD_SET(XY, 1));
      break;

    case 0xCC:
      setH(LD_SET(XY, 1));
      break;

    case 0xCD:
      setL(LD_SET(XY, 1));
      break;

    case 0xCE:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(1, memReadByte(addr))); 
      break;

    case 0xCF:
      setA(LD_SET(XY, 1));
      break;

    case 0xD0:
      setB(LD_SET(XY, 2));
      break;

    case 0xD1:
      setC(LD_SET(XY, 2));
      break;

    case 0xD2:
      setD(LD_SET(XY, 2));
      break;

    case 0xD3:
      setE(LD_SET(XY, 2));
      break;

    case 0xD4:
      setH(LD_SET(XY, 2));
      break;

    case 0xD5:
      setL(LD_SET(XY, 2));
      break;

    case 0xD6:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(2, memReadByte(addr))); 
      break;

    case 0xD7:
      setA(LD_SET(XY, 2));
      break;

    case 0xD8:
      setB(LD_SET(XY, 3));
      break;

    case 0xD9:
      setC(LD_SET(XY, 3));
      break;

    case 0xDA:
      setD(LD_SET(XY, 3));
      break;

    case 0xDB:
      setE(LD_SET(XY, 3));
      break;

    case 0xDC:
      setH(LD_SET(XY, 3));
      break;

    case 0xDD:
      setL(LD_SET(XY, 3));
      break;

    case 0xDE:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(3, memReadByte(addr))); 
      break;

    case 0xDF:
      setA(LD_SET(XY, 3));
      break;

    case 0xE0:
      setB(LD_SET(XY, 4));
      break;

    case 0xE1:
      setC(LD_SET(XY, 4));
      break;

    case 0xE2:
      setD(LD_SET(XY, 4));
      break;

    case 0xE3:
      setE(LD_SET(XY, 4));
      break;

    case 0xE4:
      setH(LD_SET(XY, 4));
      break;

    case 0xE5:
      setL(LD_SET(XY, 4));
      break;

    case 0xE6:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(4, memReadByte(addr))); 
      break;

    case 0xE7:
      setA(LD_SET(XY, 4));
      break;

    case 0xE8:
      setB(LD_SET(XY, 5));
      break;

    case 0xE9:
      setC(LD_SET(XY, 5));
      break;

    case 0xEA:
      setD(LD_SET(XY, 5));
      break;

    case 0xEB:
      setE(LD_SET(XY, 5));
      break;

    case 0xEC:
      setH(LD_SET(XY, 5));
      break;

    case 0xED:
      setL(LD_SET(XY, 5));
      break;

    case 0xEE:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(5, memReadByte(addr))); 
      break;

    case 0xEF:
      setA(LD_SET(XY, 5));
      break;

    case 0xF0:
      setB(LD_SET(XY, 6));
      break;

    case 0xF1:
      setC(LD_SET(XY, 6));
      break;

    case 0xF2:
      setD(LD_SET(XY, 6));
      break;

    case 0xF3:
      setE(LD_SET(XY, 6));
      break;

    case 0xF4:
      setH(LD_SET(XY, 6));
      break;

    case 0xF5:
      setL(LD_SET(XY, 6));
      break;

    case 0xF6:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(6, memReadByte(addr))); 
      break;

    case 0xF7:
      setA(LD_SET(XY, 6));
      break;

    case 0xF8:
      setB(LD_SET(XY, 7));
      break;

    case 0xF9:
      setC(LD_SET(XY, 7));
      break;

    case 0xFA:
      setD(LD_SET(XY, 7));
      break;

    case 0xFB:
      setE(LD_SET(XY, 7));
      break;

    case 0xFC:
      setH(LD_SET(XY, 7));
      break;

    case 0xFD:
      setL(LD_SET(XY, 7));
      break;

    case 0xFE:
      addr = XY + (byte) (memReadByte(PC++));
      addr &= 0xFFFF;
      memWriteByte(addr, SET(7, memReadByte(addr))); 
      break;

    case 0xFF:
      setA(LD_SET(XY, 7));
      break;
         
    }
    PC++;
    cyclesToDo -= cycles_xx_cb_opcode[opcode];
  }
   
  public final void run(int nbCycles) {
    totalClocks=totalClocks.add(BigInteger.valueOf(sliceClocks-cyclesToDo));
    sliceClocks=nbCycles;
    cyclesToDo += nbCycles;
    Interrupt();      
      
    while (cyclesToDo > 0) {
      UpdateR();
         
      // Accepts interrupts the intruction AFTER EI
      switch (enable) {
      case 2:
        IFF1 = IFF2 = 1;
        Interrupt();
        enable = 0;
        break;
            
      case 1:
        enable = 2;
        break;
      }
         
      if (halted == false) {
        exeOpcode(memReadByte(PC++));
        PC &= 0xFFFF;
      } else {
        cyclesToDo -= 4; 
        Interrupt();
      }
    }
  }
   
  public final void PendingIRQ(int value) {
    vector = value;
    IRQ = 1;
    if (IFF1 != 0) {
      CheckIRQ();
    }
  }
   
  public final void PendingNMI() {
    NMIInt = 1;
  }
   
  public final void CheckIRQ() {
    if ((IFF1 == 0) || (IRQ == 0)) {
      return;
    }
      
    IRQ = IFF1 = IFF2 = 0;
    halted = false;
    UpdateR();      
      
    switch (IM) {
    // 8080 compatible mode
    case 0:
      exeOpcode(vector);
      break;
         
    // RST 38h
    case 1:
      SP -= 2;
      SP &= 0xFFFF;
      memWriteWord(SP, PC);
      PC = 0x0038;
      cyclesToDo -= 13;
      break;
         
    // CALL (address I*256+(value read on the bus))
    case 2:
      SP -= 2;
      SP &= 0xFFFF;
      memWriteWord(SP, PC);
      PC = memReadWord(((I) << 8) + vector);
      cyclesToDo -= 19;
      break;
    }
  }
   
  private final void PF_Table_init() {
    int c;
    byte d;
    int m;
      
    for (c = 0; c <= 255; c++) {
      d = 0;
      for (m = 0; m <= 7; m++) {
        if ((c & (1 << m)) != 0) {
          d ^= 1;
        }
      }
      PF_Table[c] = d;
    }
  }
   
  public final void NMI() {
    NMIInt = IFF1 = 0; // Disable interrupts and ack the interrupt
    halted = false; // Unhalt the CPU
    SP -= 2;
    SP &= 0xFFFF;
    memWriteWord(SP, PC);
    PC = NMI_PC; // NMI !
  }
   
  public final void Interrupt() {
    if (NMIInt != 0) {
      NMI();
      cyclesToDo -= 11;
      return;
    }
    if ((IFF1 != 0) && (IRQ != 0)) {
      CheckIRQ();
      cyclesToDo += 19;
      return;
    }
  }
   
  private static final int cycles_main_opcode[] = {
    4, 10, 7, 6, 4, 4, 7, 4, 4, 11, 7, 6, 4, 4, 7, 4, 10, 10, 7, 6, 4, 4, 7, 4,
    12, 11, 7, 6, 4, 4, 7, 4, 7, 10, 16, 6, 4, 4, 7, 4, 7, 11, 16, 6, 4, 4, 7, 4,
    7, 10, 13, 6, 11, 11, 10, 4, 7, 11, 13, 6, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7,
    4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4,
    4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 7, 7, 7, 7, 7, 7, 4, 7, 4, 4, 4,
    4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4,
    4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7,
    4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 5, 10, 10, 10, 10, 11, 7,
    11, 5, 10, 10, 0, 10, 17, 7, 11, 5, 10, 10, 11, 10, 11, 7, 11, 5, 4, 10, 11,
    10, 0, 7, 11, 5, 10, 10, 19, 10, 11, 7, 11, 5, 4, 10, 4, 10, 0, 7, 11, 5, 10,
    10, 4, 10, 11, 7, 11, 5, 6, 10, 4, 10, 0, 7, 11
  };
   
  private static final int cycles_ed_opcode[] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 12, 15, 20, 8, 8, 8, 9, 12, 12, 15,
    20, 8, 8, 8, 9, 12, 12, 15, 20, 8, 8, 8, 9, 12, 12, 15, 20, 8, 8, 8, 9, 12,
    12, 15, 20, 8, 8, 8, 18, 12, 12, 15, 20, 8, 8, 8, 18, 12, 12, 15, 20, 8, 8,
    8, 8, 12, 12, 15, 20, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 16, 16, 8, 8,
    8, 8, 16, 16, 16, 16, 8, 8, 8, 8, 16, 16, 16, 16, 8, 8, 8, 8, 16, 16, 16, 16,
    8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  };
   
  private static final int cycles_dd_opcode[] = {
    4, 4, 4, 4, 4, 4, 4, 4, 4, 15, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    15, 4, 4, 4, 4, 4, 4, 4, 14, 20, 10, 8, 8, 11, 4, 4, 15, 20, 10, 8, 8, 11, 4,
    4, 4, 4, 4, 23, 23, 19, 4, 4, 15, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 8, 8, 19, 4,
    4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 8,
    8, 8, 8, 8, 8, 19, 8, 8, 8, 8, 8, 8, 8, 19, 8, 19, 19, 19, 19, 19, 19, 4, 19,
    4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4,
    4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4, 4,
    4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4, 4, 8, 8, 19, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4,
  };
   
  private static final int cycles_cb_opcode[] = {
    8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8,
    8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8,
    8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 12, 8, 8, 8, 8,
    8, 8, 8, 12, 8, 8, 8, 8, 8, 8, 8, 12, 8, 8, 8, 8, 8, 8, 8, 12, 8, 8, 8, 8, 8,
    8, 8, 12, 8, 8, 8, 8, 8, 8, 8, 12, 8, 8, 8, 8, 8, 8, 8, 12, 8, 8, 8, 8, 8, 8,
    8, 12, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8,
    15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8,
    15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8,
    15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8,
    15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8, 15, 8, 8, 8, 8, 8, 8, 8,
    15, 8, 8, 8, 8, 8, 8, 8, 15, 8,	
  };
   
  private static final int cycles_xx_cb_opcode[] = {
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23,
  };
   
  private static final int DAATable2[] = {
    0x0044, 0x0100, 0x0200, 0x0304, 0x0400, 0x0504, 0x0604, 0x0700, 0x0808,
    0x090C, 0x1010, 0x1114, 0x1214, 0x1310, 0x1414, 0x1510, 0x1000, 0x1104,
    0x1204, 0x1300, 0x1404, 0x1500, 0x1600, 0x1704, 0x180C, 0x1908, 0x2030,
    0x2134, 0x2234, 0x2330, 0x2434, 0x2530, 0x2020, 0x2124, 0x2224, 0x2320,
    0x2424, 0x2520, 0x2620, 0x2724, 0x282C, 0x2928, 0x3034, 0x3130, 0x3230,
    0x3334, 0x3430, 0x3534, 0x3024, 0x3120, 0x3220, 0x3324, 0x3420, 0x3524,
    0x3624, 0x3720, 0x3828, 0x392C, 0x4010, 0x4114, 0x4214, 0x4310, 0x4414,
    0x4510, 0x4000, 0x4104, 0x4204, 0x4300, 0x4404, 0x4500, 0x4600, 0x4704,
    0x480C, 0x4908, 0x5014, 0x5110, 0x5210, 0x5314, 0x5410, 0x5514, 0x5004,
    0x5100, 0x5200, 0x5304, 0x5400, 0x5504, 0x5604, 0x5700, 0x5808, 0x590C,
    0x6034, 0x6130, 0x6230, 0x6334, 0x6430, 0x6534, 0x6024, 0x6120, 0x6220,
    0x6324, 0x6420, 0x6524, 0x6624, 0x6720, 0x6828, 0x692C, 0x7030, 0x7134,
    0x7234, 0x7330, 0x7434, 0x7530, 0x7020, 0x7124, 0x7224, 0x7320, 0x7424,
    0x7520, 0x7620, 0x7724, 0x782C, 0x7928, 0x8090, 0x8194, 0x8294, 0x8390,
    0x8494, 0x8590, 0x8080, 0x8184, 0x8284, 0x8380, 0x8484, 0x8580, 0x8680,
    0x8784, 0x888C, 0x8988, 0x9094, 0x9190, 0x9290, 0x9394, 0x9490, 0x9594,
    0x9084, 0x9180, 0x9280, 0x9384, 0x9480, 0x9584, 0x9684, 0x9780, 0x9888,
    0x998C, 0x0055, 0x0111, 0x0211, 0x0315, 0x0411, 0x0515, 0x0045, 0x0101,
    0x0201, 0x0305, 0x0401, 0x0505, 0x0605, 0x0701, 0x0809, 0x090D, 0x1011,
    0x1115, 0x1215, 0x1311, 0x1415, 0x1511, 0x1001, 0x1105, 0x1205, 0x1301,
    0x1405, 0x1501, 0x1601, 0x1705, 0x180D, 0x1909, 0x2031, 0x2135, 0x2235,
    0x2331, 0x2435, 0x2531, 0x2021, 0x2125, 0x2225, 0x2321, 0x2425, 0x2521,
    0x2621, 0x2725, 0x282D, 0x2929, 0x3035, 0x3131, 0x3231, 0x3335, 0x3431,
    0x3535, 0x3025, 0x3121, 0x3221, 0x3325, 0x3421, 0x3525, 0x3625, 0x3721,
    0x3829, 0x392D, 0x4011, 0x4115, 0x4215, 0x4311, 0x4415, 0x4511, 0x4001,
    0x4105, 0x4205, 0x4301, 0x4405, 0x4501, 0x4601, 0x4705, 0x480D, 0x4909,
    0x5015, 0x5111, 0x5211, 0x5315, 0x5411, 0x5515, 0x5005, 0x5101, 0x5201,
    0x5305, 0x5401, 0x5505, 0x5605, 0x5701, 0x5809, 0x590D, 0x6035, 0x6131,
    0x6231, 0x6335, 0x6431, 0x6535, 0x6025, 0x6121, 0x6221, 0x6325, 0x6421,
    0x6525, 0x6625, 0x6721, 0x6829, 0x692D, 0x7031, 0x7135, 0x7235, 0x7331,
    0x7435, 0x7531, 0x7021, 0x7125, 0x7225, 0x7321, 0x7425, 0x7521, 0x7621,
    0x7725, 0x782D, 0x7929, 0x8091, 0x8195, 0x8295, 0x8391, 0x8495, 0x8591,
    0x8081, 0x8185, 0x8285, 0x8381, 0x8485, 0x8581, 0x8681, 0x8785, 0x888D,
    0x8989, 0x9095, 0x9191, 0x9291, 0x9395, 0x9491, 0x9595, 0x9085, 0x9181,
    0x9281, 0x9385, 0x9481, 0x9585, 0x9685, 0x9781, 0x9889, 0x998D, 0xA0B5,
    0xA1B1, 0xA2B1, 0xA3B5, 0xA4B1, 0xA5B5, 0xA0A5, 0xA1A1, 0xA2A1, 0xA3A5,
    0xA4A1, 0xA5A5, 0xA6A5, 0xA7A1, 0xA8A9, 0xA9AD, 0xB0B1, 0xB1B5, 0xB2B5,
    0xB3B1, 0xB4B5, 0xB5B1, 0xB0A1, 0xB1A5, 0xB2A5, 0xB3A1, 0xB4A5, 0xB5A1,
    0xB6A1, 0xB7A5, 0xB8AD, 0xB9A9, 0xC095, 0xC191, 0xC291, 0xC395, 0xC491,
    0xC595, 0xC085, 0xC181, 0xC281, 0xC385, 0xC481, 0xC585, 0xC685, 0xC781,
    0xC889, 0xC98D, 0xD091, 0xD195, 0xD295, 0xD391, 0xD495, 0xD591, 0xD081,
    0xD185, 0xD285, 0xD381, 0xD485, 0xD581, 0xD681, 0xD785, 0xD88D, 0xD989,
    0xE0B1, 0xE1B5, 0xE2B5, 0xE3B1, 0xE4B5, 0xE5B1, 0xE0A1, 0xE1A5, 0xE2A5,
    0xE3A1, 0xE4A5, 0xE5A1, 0xE6A1, 0xE7A5, 0xE8AD, 0xE9A9, 0xF0B5, 0xF1B1,
    0xF2B1, 0xF3B5, 0xF4B1, 0xF5B5, 0xF0A5, 0xF1A1, 0xF2A1, 0xF3A5, 0xF4A1,
    0xF5A5, 0xF6A5, 0xF7A1, 0xF8A9, 0xF9AD, 0x0055, 0x0111, 0x0211, 0x0315,
    0x0411, 0x0515, 0x0045, 0x0101, 0x0201, 0x0305, 0x0401, 0x0505, 0x0605,
    0x0701, 0x0809, 0x090D, 0x1011, 0x1115, 0x1215, 0x1311, 0x1415, 0x1511,
    0x1001, 0x1105, 0x1205, 0x1301, 0x1405, 0x1501, 0x1601, 0x1705, 0x180D,
    0x1909, 0x2031, 0x2135, 0x2235, 0x2331, 0x2435, 0x2531, 0x2021, 0x2125,
    0x2225, 0x2321, 0x2425, 0x2521, 0x2621, 0x2725, 0x282D, 0x2929, 0x3035,
    0x3131, 0x3231, 0x3335, 0x3431, 0x3535, 0x3025, 0x3121, 0x3221, 0x3325,
    0x3421, 0x3525, 0x3625, 0x3721, 0x3829, 0x392D, 0x4011, 0x4115, 0x4215,
    0x4311, 0x4415, 0x4511, 0x4001, 0x4105, 0x4205, 0x4301, 0x4405, 0x4501,
    0x4601, 0x4705, 0x480D, 0x4909, 0x5015, 0x5111, 0x5211, 0x5315, 0x5411,
    0x5515, 0x5005, 0x5101, 0x5201, 0x5305, 0x5401, 0x5505, 0x5605, 0x5701,
    0x5809, 0x590D, 0x6035, 0x6131, 0x6231, 0x6335, 0x6431, 0x6535, 0x0604,
    0x0700, 0x0808, 0x090C, 0x0A0C, 0x0B08, 0x0C0C, 0x0D08, 0x0E08, 0x0F0C,
    0x1010, 0x1114, 0x1214, 0x1310, 0x1414, 0x1510, 0x1600, 0x1704, 0x180C,
    0x1908, 0x1A08, 0x1B0C, 0x1C08, 0x1D0C, 0x1E0C, 0x1F08, 0x2030, 0x2134,
    0x2234, 0x2330, 0x2434, 0x2530, 0x2620, 0x2724, 0x282C, 0x2928, 0x2A28,
    0x2B2C, 0x2C28, 0x2D2C, 0x2E2C, 0x2F28, 0x3034, 0x3130, 0x3230, 0x3334,
    0x3430, 0x3534, 0x3624, 0x3720, 0x3828, 0x392C, 0x3A2C, 0x3B28, 0x3C2C,
    0x3D28, 0x3E28, 0x3F2C, 0x4010, 0x4114, 0x4214, 0x4310, 0x4414, 0x4510,
    0x4600, 0x4704, 0x480C, 0x4908, 0x4A08, 0x4B0C, 0x4C08, 0x4D0C, 0x4E0C,
    0x4F08, 0x5014, 0x5110, 0x5210, 0x5314, 0x5410, 0x5514, 0x5604, 0x5700,
    0x5808, 0x590C, 0x5A0C, 0x5B08, 0x5C0C, 0x5D08, 0x5E08, 0x5F0C, 0x6034,
    0x6130, 0x6230, 0x6334, 0x6430, 0x6534, 0x6624, 0x6720, 0x6828, 0x692C,
    0x6A2C, 0x6B28, 0x6C2C, 0x6D28, 0x6E28, 0x6F2C, 0x7030, 0x7134, 0x7234,
    0x7330, 0x7434, 0x7530, 0x7620, 0x7724, 0x782C, 0x7928, 0x7A28, 0x7B2C,
    0x7C28, 0x7D2C, 0x7E2C, 0x7F28, 0x8090, 0x8194, 0x8294, 0x8390, 0x8494,
    0x8590, 0x8680, 0x8784, 0x888C, 0x8988, 0x8A88, 0x8B8C, 0x8C88, 0x8D8C,
    0x8E8C, 0x8F88, 0x9094, 0x9190, 0x9290, 0x9394, 0x9490, 0x9594, 0x9684,
    0x9780, 0x9888, 0x998C, 0x9A8C, 0x9B88, 0x9C8C, 0x9D88, 0x9E88, 0x9F8C,
    0x0055, 0x0111, 0x0211, 0x0315, 0x0411, 0x0515, 0x0605, 0x0701, 0x0809,
    0x090D, 0x0A0D, 0x0B09, 0x0C0D, 0x0D09, 0x0E09, 0x0F0D, 0x1011, 0x1115,
    0x1215, 0x1311, 0x1415, 0x1511, 0x1601, 0x1705, 0x180D, 0x1909, 0x1A09,
    0x1B0D, 0x1C09, 0x1D0D, 0x1E0D, 0x1F09, 0x2031, 0x2135, 0x2235, 0x2331,
    0x2435, 0x2531, 0x2621, 0x2725, 0x282D, 0x2929, 0x2A29, 0x2B2D, 0x2C29,
    0x2D2D, 0x2E2D, 0x2F29, 0x3035, 0x3131, 0x3231, 0x3335, 0x3431, 0x3535,
    0x3625, 0x3721, 0x3829, 0x392D, 0x3A2D, 0x3B29, 0x3C2D, 0x3D29, 0x3E29,
    0x3F2D, 0x4011, 0x4115, 0x4215, 0x4311, 0x4415, 0x4511, 0x4601, 0x4705,
    0x480D, 0x4909, 0x4A09, 0x4B0D, 0x4C09, 0x4D0D, 0x4E0D, 0x4F09, 0x5015,
    0x5111, 0x5211, 0x5315, 0x5411, 0x5515, 0x5605, 0x5701, 0x5809, 0x590D,
    0x5A0D, 0x5B09, 0x5C0D, 0x5D09, 0x5E09, 0x5F0D, 0x6035, 0x6131, 0x6231,
    0x6335, 0x6431, 0x6535, 0x6625, 0x6721, 0x6829, 0x692D, 0x6A2D, 0x6B29,
    0x6C2D, 0x6D29, 0x6E29, 0x6F2D, 0x7031, 0x7135, 0x7235, 0x7331, 0x7435,
    0x7531, 0x7621, 0x7725, 0x782D, 0x7929, 0x7A29, 0x7B2D, 0x7C29, 0x7D2D,
    0x7E2D, 0x7F29, 0x8091, 0x8195, 0x8295, 0x8391, 0x8495, 0x8591, 0x8681,
    0x8785, 0x888D, 0x8989, 0x8A89, 0x8B8D, 0x8C89, 0x8D8D, 0x8E8D, 0x8F89,
    0x9095, 0x9191, 0x9291, 0x9395, 0x9491, 0x9595, 0x9685, 0x9781, 0x9889,
    0x998D, 0x9A8D, 0x9B89, 0x9C8D, 0x9D89, 0x9E89, 0x9F8D, 0xA0B5, 0xA1B1,
    0xA2B1, 0xA3B5, 0xA4B1, 0xA5B5, 0xA6A5, 0xA7A1, 0xA8A9, 0xA9AD, 0xAAAD,
    0xABA9, 0xACAD, 0xADA9, 0xAEA9, 0xAFAD, 0xB0B1, 0xB1B5, 0xB2B5, 0xB3B1,
    0xB4B5, 0xB5B1, 0xB6A1, 0xB7A5, 0xB8AD, 0xB9A9, 0xBAA9, 0xBBAD, 0xBCA9,
    0xBDAD, 0xBEAD, 0xBFA9, 0xC095, 0xC191, 0xC291, 0xC395, 0xC491, 0xC595,
    0xC685, 0xC781, 0xC889, 0xC98D, 0xCA8D, 0xCB89, 0xCC8D, 0xCD89, 0xCE89,
    0xCF8D, 0xD091, 0xD195, 0xD295, 0xD391, 0xD495, 0xD591, 0xD681, 0xD785,
    0xD88D, 0xD989, 0xDA89, 0xDB8D, 0xDC89, 0xDD8D, 0xDE8D, 0xDF89, 0xE0B1,
    0xE1B5, 0xE2B5, 0xE3B1, 0xE4B5, 0xE5B1, 0xE6A1, 0xE7A5, 0xE8AD, 0xE9A9,
    0xEAA9, 0xEBAD, 0xECA9, 0xEDAD, 0xEEAD, 0xEFA9, 0xF0B5, 0xF1B1, 0xF2B1,
    0xF3B5, 0xF4B1, 0xF5B5, 0xF6A5, 0xF7A1, 0xF8A9, 0xF9AD, 0xFAAD, 0xFBA9,
    0xFCAD, 0xFDA9, 0xFEA9, 0xFFAD, 0x0055, 0x0111, 0x0211, 0x0315, 0x0411,
    0x0515, 0x0605, 0x0701, 0x0809, 0x090D, 0x0A0D, 0x0B09, 0x0C0D, 0x0D09,
    0x0E09, 0x0F0D, 0x1011, 0x1115, 0x1215, 0x1311, 0x1415, 0x1511, 0x1601,
    0x1705, 0x180D, 0x1909, 0x1A09, 0x1B0D, 0x1C09, 0x1D0D, 0x1E0D, 0x1F09,
    0x2031, 0x2135, 0x2235, 0x2331, 0x2435, 0x2531, 0x2621, 0x2725, 0x282D,
    0x2929, 0x2A29, 0x2B2D, 0x2C29, 0x2D2D, 0x2E2D, 0x2F29, 0x3035, 0x3131,
    0x3231, 0x3335, 0x3431, 0x3535, 0x3625, 0x3721, 0x3829, 0x392D, 0x3A2D,
    0x3B29, 0x3C2D, 0x3D29, 0x3E29, 0x3F2D, 0x4011, 0x4115, 0x4215, 0x4311,
    0x4415, 0x4511, 0x4601, 0x4705, 0x480D, 0x4909, 0x4A09, 0x4B0D, 0x4C09,
    0x4D0D, 0x4E0D, 0x4F09, 0x5015, 0x5111, 0x5211, 0x5315, 0x5411, 0x5515,
    0x5605, 0x5701, 0x5809, 0x590D, 0x5A0D, 0x5B09, 0x5C0D, 0x5D09, 0x5E09,
    0x5F0D, 0x6035, 0x6131, 0x6231, 0x6335, 0x6431, 0x6535, 0x0046, 0x0102,
    0x0202, 0x0306, 0x0402, 0x0506, 0x0606, 0x0702, 0x080A, 0x090E, 0x0402,
    0x0506, 0x0606, 0x0702, 0x080A, 0x090E, 0x1002, 0x1106, 0x1206, 0x1302,
    0x1406, 0x1502, 0x1602, 0x1706, 0x180E, 0x190A, 0x1406, 0x1502, 0x1602,
    0x1706, 0x180E, 0x190A, 0x2022, 0x2126, 0x2226, 0x2322, 0x2426, 0x2522,
    0x2622, 0x2726, 0x282E, 0x292A, 0x2426, 0x2522, 0x2622, 0x2726, 0x282E,
    0x292A, 0x3026, 0x3122, 0x3222, 0x3326, 0x3422, 0x3526, 0x3626, 0x3722,
    0x382A, 0x392E, 0x3422, 0x3526, 0x3626, 0x3722, 0x382A, 0x392E, 0x4002,
    0x4106, 0x4206, 0x4302, 0x4406, 0x4502, 0x4602, 0x4706, 0x480E, 0x490A,
    0x4406, 0x4502, 0x4602, 0x4706, 0x480E, 0x490A, 0x5006, 0x5102, 0x5202,
    0x5306, 0x5402, 0x5506, 0x5606, 0x5702, 0x580A, 0x590E, 0x5402, 0x5506,
    0x5606, 0x5702, 0x580A, 0x590E, 0x6026, 0x6122, 0x6222, 0x6326, 0x6422,
    0x6526, 0x6626, 0x6722, 0x682A, 0x692E, 0x6422, 0x6526, 0x6626, 0x6722,
    0x682A, 0x692E, 0x7022, 0x7126, 0x7226, 0x7322, 0x7426, 0x7522, 0x7622,
    0x7726, 0x782E, 0x792A, 0x7426, 0x7522, 0x7622, 0x7726, 0x782E, 0x792A,
    0x8082, 0x8186, 0x8286, 0x8382, 0x8486, 0x8582, 0x8682, 0x8786, 0x888E,
    0x898A, 0x8486, 0x8582, 0x8682, 0x8786, 0x888E, 0x898A, 0x9086, 0x9182,
    0x9282, 0x9386, 0x9482, 0x9586, 0x9686, 0x9782, 0x988A, 0x998E, 0x3423,
    0x3527, 0x3627, 0x3723, 0x382B, 0x392F, 0x4003, 0x4107, 0x4207, 0x4303,
    0x4407, 0x4503, 0x4603, 0x4707, 0x480F, 0x490B, 0x4407, 0x4503, 0x4603,
    0x4707, 0x480F, 0x490B, 0x5007, 0x5103, 0x5203, 0x5307, 0x5403, 0x5507,
    0x5607, 0x5703, 0x580B, 0x590F, 0x5403, 0x5507, 0x5607, 0x5703, 0x580B,
    0x590F, 0x6027, 0x6123, 0x6223, 0x6327, 0x6423, 0x6527, 0x6627, 0x6723,
    0x682B, 0x692F, 0x6423, 0x6527, 0x6627, 0x6723, 0x682B, 0x692F, 0x7023,
    0x7127, 0x7227, 0x7323, 0x7427, 0x7523, 0x7623, 0x7727, 0x782F, 0x792B,
    0x7427, 0x7523, 0x7623, 0x7727, 0x782F, 0x792B, 0x8083, 0x8187, 0x8287,
    0x8383, 0x8487, 0x8583, 0x8683, 0x8787, 0x888F, 0x898B, 0x8487, 0x8583,
    0x8683, 0x8787, 0x888F, 0x898B, 0x9087, 0x9183, 0x9283, 0x9387, 0x9483,
    0x9587, 0x9687, 0x9783, 0x988B, 0x998F, 0x9483, 0x9587, 0x9687, 0x9783,
    0x988B, 0x998F, 0xA0A7, 0xA1A3, 0xA2A3, 0xA3A7, 0xA4A3, 0xA5A7, 0xA6A7,
    0xA7A3, 0xA8AB, 0xA9AF, 0xA4A3, 0xA5A7, 0xA6A7, 0xA7A3, 0xA8AB, 0xA9AF,
    0xB0A3, 0xB1A7, 0xB2A7, 0xB3A3, 0xB4A7, 0xB5A3, 0xB6A3, 0xB7A7, 0xB8AF,
    0xB9AB, 0xB4A7, 0xB5A3, 0xB6A3, 0xB7A7, 0xB8AF, 0xB9AB, 0xC087, 0xC183,
    0xC283, 0xC387, 0xC483, 0xC587, 0xC687, 0xC783, 0xC88B, 0xC98F, 0xC483,
    0xC587, 0xC687, 0xC783, 0xC88B, 0xC98F, 0xD083, 0xD187, 0xD287, 0xD383,
    0xD487, 0xD583, 0xD683, 0xD787, 0xD88F, 0xD98B, 0xD487, 0xD583, 0xD683,
    0xD787, 0xD88F, 0xD98B, 0xE0A3, 0xE1A7, 0xE2A7, 0xE3A3, 0xE4A7, 0xE5A3,
    0xE6A3, 0xE7A7, 0xE8AF, 0xE9AB, 0xE4A7, 0xE5A3, 0xE6A3, 0xE7A7, 0xE8AF,
    0xE9AB, 0xF0A7, 0xF1A3, 0xF2A3, 0xF3A7, 0xF4A3, 0xF5A7, 0xF6A7, 0xF7A3,
    0xF8AB, 0xF9AF, 0xF4A3, 0xF5A7, 0xF6A7, 0xF7A3, 0xF8AB, 0xF9AF, 0x0047,
    0x0103, 0x0203, 0x0307, 0x0403, 0x0507, 0x0607, 0x0703, 0x080B, 0x090F,
    0x0403, 0x0507, 0x0607, 0x0703, 0x080B, 0x090F, 0x1003, 0x1107, 0x1207,
    0x1303, 0x1407, 0x1503, 0x1603, 0x1707, 0x180F, 0x190B, 0x1407, 0x1503,
    0x1603, 0x1707, 0x180F, 0x190B, 0x2023, 0x2127, 0x2227, 0x2323, 0x2427,
    0x2523, 0x2623, 0x2727, 0x282F, 0x292B, 0x2427, 0x2523, 0x2623, 0x2727,
    0x282F, 0x292B, 0x3027, 0x3123, 0x3223, 0x3327, 0x3423, 0x3527, 0x3627,
    0x3723, 0x382B, 0x392F, 0x3423, 0x3527, 0x3627, 0x3723, 0x382B, 0x392F,
    0x4003, 0x4107, 0x4207, 0x4303, 0x4407, 0x4503, 0x4603, 0x4707, 0x480F,
    0x490B, 0x4407, 0x4503, 0x4603, 0x4707, 0x480F, 0x490B, 0x5007, 0x5103,
    0x5203, 0x5307, 0x5403, 0x5507, 0x5607, 0x5703, 0x580B, 0x590F, 0x5403,
    0x5507, 0x5607, 0x5703, 0x580B, 0x590F, 0x6027, 0x6123, 0x6223, 0x6327,
    0x6423, 0x6527, 0x6627, 0x6723, 0x682B, 0x692F, 0x6423, 0x6527, 0x6627,
    0x6723, 0x682B, 0x692F, 0x7023, 0x7127, 0x7227, 0x7323, 0x7427, 0x7523,
    0x7623, 0x7727, 0x782F, 0x792B, 0x7427, 0x7523, 0x7623, 0x7727, 0x782F,
    0x792B, 0x8083, 0x8187, 0x8287, 0x8383, 0x8487, 0x8583, 0x8683, 0x8787,
    0x888F, 0x898B, 0x8487, 0x8583, 0x8683, 0x8787, 0x888F, 0x898B, 0x9087,
    0x9183, 0x9283, 0x9387, 0x9483, 0x9587, 0x9687, 0x9783, 0x988B, 0x998F,
    0x9483, 0x9587, 0x9687, 0x9783, 0x988B, 0x998F, 0xFABE, 0xFBBA, 0xFCBE,
    0xFDBA, 0xFEBA, 0xFFBE, 0x0046, 0x0102, 0x0202, 0x0306, 0x0402, 0x0506,
    0x0606, 0x0702, 0x080A, 0x090E, 0x0A1E, 0x0B1A, 0x0C1E, 0x0D1A, 0x0E1A,
    0x0F1E, 0x1002, 0x1106, 0x1206, 0x1302, 0x1406, 0x1502, 0x1602, 0x1706,
    0x180E, 0x190A, 0x1A1A, 0x1B1E, 0x1C1A, 0x1D1E, 0x1E1E, 0x1F1A, 0x2022,
    0x2126, 0x2226, 0x2322, 0x2426, 0x2522, 0x2622, 0x2726, 0x282E, 0x292A,
    0x2A3A, 0x2B3E, 0x2C3A, 0x2D3E, 0x2E3E, 0x2F3A, 0x3026, 0x3122, 0x3222,
    0x3326, 0x3422, 0x3526, 0x3626, 0x3722, 0x382A, 0x392E, 0x3A3E, 0x3B3A,
    0x3C3E, 0x3D3A, 0x3E3A, 0x3F3E, 0x4002, 0x4106, 0x4206, 0x4302, 0x4406,
    0x4502, 0x4602, 0x4706, 0x480E, 0x490A, 0x4A1A, 0x4B1E, 0x4C1A, 0x4D1E,
    0x4E1E, 0x4F1A, 0x5006, 0x5102, 0x5202, 0x5306, 0x5402, 0x5506, 0x5606,
    0x5702, 0x580A, 0x590E, 0x5A1E, 0x5B1A, 0x5C1E, 0x5D1A, 0x5E1A, 0x5F1E,
    0x6026, 0x6122, 0x6222, 0x6326, 0x6422, 0x6526, 0x6626, 0x6722, 0x682A,
    0x692E, 0x6A3E, 0x6B3A, 0x6C3E, 0x6D3A, 0x6E3A, 0x6F3E, 0x7022, 0x7126,
    0x7226, 0x7322, 0x7426, 0x7522, 0x7622, 0x7726, 0x782E, 0x792A, 0x7A3A,
    0x7B3E, 0x7C3A, 0x7D3E, 0x7E3E, 0x7F3A, 0x8082, 0x8186, 0x8286, 0x8382,
    0x8486, 0x8582, 0x8682, 0x8786, 0x888E, 0x898A, 0x8A9A, 0x8B9E, 0x8C9A,
    0x8D9E, 0x8E9E, 0x8F9A, 0x9086, 0x9182, 0x9282, 0x9386, 0x3423, 0x3527,
    0x3627, 0x3723, 0x382B, 0x392F, 0x3A3F, 0x3B3B, 0x3C3F, 0x3D3B, 0x3E3B,
    0x3F3F, 0x4003, 0x4107, 0x4207, 0x4303, 0x4407, 0x4503, 0x4603, 0x4707,
    0x480F, 0x490B, 0x4A1B, 0x4B1F, 0x4C1B, 0x4D1F, 0x4E1F, 0x4F1B, 0x5007,
    0x5103, 0x5203, 0x5307, 0x5403, 0x5507, 0x5607, 0x5703, 0x580B, 0x590F,
    0x5A1F, 0x5B1B, 0x5C1F, 0x5D1B, 0x5E1B, 0x5F1F, 0x6027, 0x6123, 0x6223,
    0x6327, 0x6423, 0x6527, 0x6627, 0x6723, 0x682B, 0x692F, 0x6A3F, 0x6B3B,
    0x6C3F, 0x6D3B, 0x6E3B, 0x6F3F, 0x7023, 0x7127, 0x7227, 0x7323, 0x7427,
    0x7523, 0x7623, 0x7727, 0x782F, 0x792B, 0x7A3B, 0x7B3F, 0x7C3B, 0x7D3F,
    0x7E3F, 0x7F3B, 0x8083, 0x8187, 0x8287, 0x8383, 0x8487, 0x8583, 0x8683,
    0x8787, 0x888F, 0x898B, 0x8A9B, 0x8B9F, 0x8C9B, 0x8D9F, 0x8E9F, 0x8F9B,
    0x9087, 0x9183, 0x9283, 0x9387, 0x9483, 0x9587, 0x9687, 0x9783, 0x988B,
    0x998F, 0x9A9F, 0x9B9B, 0x9C9F, 0x9D9B, 0x9E9B, 0x9F9F, 0xA0A7, 0xA1A3,
    0xA2A3, 0xA3A7, 0xA4A3, 0xA5A7, 0xA6A7, 0xA7A3, 0xA8AB, 0xA9AF, 0xAABF,
    0xABBB, 0xACBF, 0xADBB, 0xAEBB, 0xAFBF, 0xB0A3, 0xB1A7, 0xB2A7, 0xB3A3,
    0xB4A7, 0xB5A3, 0xB6A3, 0xB7A7, 0xB8AF, 0xB9AB, 0xBABB, 0xBBBF, 0xBCBB,
    0xBDBF, 0xBEBF, 0xBFBB, 0xC087, 0xC183, 0xC283, 0xC387, 0xC483, 0xC587,
    0xC687, 0xC783, 0xC88B, 0xC98F, 0xCA9F, 0xCB9B, 0xCC9F, 0xCD9B, 0xCE9B,
    0xCF9F, 0xD083, 0xD187, 0xD287, 0xD383, 0xD487, 0xD583, 0xD683, 0xD787,
    0xD88F, 0xD98B, 0xDA9B, 0xDB9F, 0xDC9B, 0xDD9F, 0xDE9F, 0xDF9B, 0xE0A3,
    0xE1A7, 0xE2A7, 0xE3A3, 0xE4A7, 0xE5A3, 0xE6A3, 0xE7A7, 0xE8AF, 0xE9AB,
    0xEABB, 0xEBBF, 0xECBB, 0xEDBF, 0xEEBF, 0xEFBB, 0xF0A7, 0xF1A3, 0xF2A3,
    0xF3A7, 0xF4A3, 0xF5A7, 0xF6A7, 0xF7A3, 0xF8AB, 0xF9AF, 0xFABF, 0xFBBB,
    0xFCBF, 0xFDBB, 0xFEBB, 0xFFBF, 0x0047, 0x0103, 0x0203, 0x0307, 0x0403,
    0x0507, 0x0607, 0x0703, 0x080B, 0x090F, 0x0A1F, 0x0B1B, 0x0C1F, 0x0D1B,
    0x0E1B, 0x0F1F, 0x1003, 0x1107, 0x1207, 0x1303, 0x1407, 0x1503, 0x1603,
    0x1707, 0x180F, 0x190B, 0x1A1B, 0x1B1F, 0x1C1B, 0x1D1F, 0x1E1F, 0x1F1B,
    0x2023, 0x2127, 0x2227, 0x2323, 0x2427, 0x2523, 0x2623, 0x2727, 0x282F,
    0x292B, 0x2A3B, 0x2B3F, 0x2C3B, 0x2D3F, 0x2E3F, 0x2F3B, 0x3027, 0x3123,
    0x3223, 0x3327, 0x3423, 0x3527, 0x3627, 0x3723, 0x382B, 0x392F, 0x3A3F,
    0x3B3B, 0x3C3F, 0x3D3B, 0x3E3B, 0x3F3F, 0x4003, 0x4107, 0x4207, 0x4303,
    0x4407, 0x4503, 0x4603, 0x4707, 0x480F, 0x490B, 0x4A1B, 0x4B1F, 0x4C1B,
    0x4D1F, 0x4E1F, 0x4F1B, 0x5007, 0x5103, 0x5203, 0x5307, 0x5403, 0x5507,
    0x5607, 0x5703, 0x580B, 0x590F, 0x5A1F, 0x5B1B, 0x5C1F, 0x5D1B, 0x5E1B,
    0x5F1F, 0x6027, 0x6123, 0x6223, 0x6327, 0x6423, 0x6527, 0x6627, 0x6723,
    0x682B, 0x692F, 0x6A3F, 0x6B3B, 0x6C3F, 0x6D3B, 0x6E3B, 0x6F3F, 0x7023,
    0x7127, 0x7227, 0x7323, 0x7427, 0x7523, 0x7623, 0x7727, 0x782F, 0x792B,
    0x7A3B, 0x7B3F, 0x7C3B, 0x7D3F, 0x7E3F, 0x7F3B, 0x8083, 0x8187, 0x8287,
    0x8383, 0x8487, 0x8583, 0x8683, 0x8787, 0x888F, 0x898B, 0x8A9B, 0x8B9F,
    0x8C9B, 0x8D9F, 0x8E9F, 0x8F9B, 0x9087, 0x9183, 0x9283, 0x9387, 0x9483,
    0x9587, 0x9687, 0x9783, 0x988B, 0x998F
  };
   
}

