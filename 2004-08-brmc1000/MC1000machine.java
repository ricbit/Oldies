public class MC1000machine {

  public MC1000memory memory;
  public MC1000ports ports;
  public Z80 z80core;
  public MC6847 vdp;
  public AY38912 psg;
  public CSW tape;

  MC1000machine(boolean has48kb) {
    vdp=new MC6847(this); 
    memory=new MC1000memory(this,has48kb);    
    ports=new MC1000ports(this);    
    z80core=new Z80(this,false,0xc000);
    psg=new AY38912(this);
    tape=new CSW(this);
  }
  
}
