import javax.sound.sampled.*;

public class MODPlayer {
  static MODSong mod;

  public static void main (String argv[]) {
    SourceDataLine line;
    AudioFormat af;

    System.out.println ("Java MOD Player v1.0");
    System.out.println ("Copyright (C) 2004 by Ricardo Bittencourt");
    System.out.println ("");
    if (argv.length==0) {
      System.out.println ("You must supply a MOD file in the command line");
      System.out.println ("java -jar MODPlayer.jar music.mod");
      System.exit(1);
    }
    System.out.println ("Loading...");    
    mod=new MODSong();
    mod.readFromFile (argv[0]);
    mod.createWave();

    System.out.println ("Playing...");
    try { 
      af=new AudioFormat (44100,8,1,true,true);
      DataLine.Info info = new DataLine.Info(SourceDataLine.class, af);
      line=(SourceDataLine) AudioSystem.getLine(info);
      line.open(af);
      line.start();
      line.write(mod.getWave(),0,mod.getWave().length);
      line.drain();
      line.stop();
      line.close();
      line = null;
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}