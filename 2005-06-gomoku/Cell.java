import java.awt.*;

public class Cell extends Button {
  static final long serialVersionUID=1;
  private int state=Table.NONE;

  public Cell () {
    setBackground (Color.lightGray);
  }

  public int getState () {
    return state;
  }

  public boolean setState (int player) {
    if (state==Table.NONE) {
      state=player;
      if (state==Table.X)
        setLabel ("X");
      else
        setLabel ("O");

      return true;
    }
    else return false;
  }

  public void clear () {
    state=Table.NONE;
    setLabel ("");
    setBackground (Color.lightGray);
  }

  public void mark () {
    setBackground (Color.red);
  }

  public void identify () {
    setBackground (Color.yellow);
  }

  public void normal () {
    setBackground (Color.lightGray);
  }

}                    
