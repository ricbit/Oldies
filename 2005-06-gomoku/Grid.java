import java.awt.*;

public class Grid extends Panel {
  Cell cell[];
  static final long serialVersionUID=1;

  public Grid () {
    int i;

    setLayout (new GridLayout (19,19));

    cell=new Cell[19*19];
    for (i=0; i<19*19; i++) {
      cell[i]=new Cell ();
      add (cell[i]);
      cell[i].setFont (new Font ("Arial",Font.BOLD,10));
    }
  }

  public void clear () {
    int i;

    for (i=0; i<19*19; i++)
      cell[i].clear ();
  }

}
