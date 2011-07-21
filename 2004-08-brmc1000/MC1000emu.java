import java.applet.Applet;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import javax.swing.*;

public class MC1000emu extends Applet implements ActionListener {
  MC1000machine machine;
  Timer timer;

  public void actionPerformed(ActionEvent e) {
    machine.z80core.run(59600);
    paint(getGraphics());
  }

  public void paint (Graphics g) {
    BufferedImage buffer=machine.vdp.draw();
    g.drawImage(buffer,0,0,null);
  }

  public void update(Graphics g) {}

  public void init () {
    boolean has48kb=false;
    String tape=null;
    
    if (getParameter("ram")!=null)
      if (getParameter("ram").equals("48"))
  	has48kb=true;

    tape=getParameter("tape");

    machine=new MC1000machine(has48kb);
    
    try {
      machine.memory.loadROM(getCodeBase());
      if (tape!=null)
        machine.tape.readFromURL(this,tape);
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(1);
    }
    
    timer=new Timer (16,this);
    addKeyListener (machine.psg.getKeyListener());
  }

  public void start () {
    timer.start();
  }

  public void stop () {
    timer.stop();
  }

  public String getAppletInfo() {
    return "BrMC1000: an MC-1000 emulator by Ricardo Bittencourt";
  }

}