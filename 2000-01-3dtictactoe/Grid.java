import java.awt.*;

public class Grid extends Panel {
  Cell cell[];

  public Grid () {
    int i;

    setLayout (new GridLayout (4,4));

    cell=new Cell[16];
    for (i=0; i<16; i++) {
      cell[i]=new Cell ();
      add (cell[i]);
      cell[i].setFont (new Font ("Arial",Font.BOLD,20));
    }
  }

  public void clear () {
    int i;

    for (i=0; i<16; i++)
      cell[i].clear ();
  }

}
