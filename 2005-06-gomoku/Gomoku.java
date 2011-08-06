import java.awt.*;
import java.awt.event.*;
import java.applet.*;

public class Gomoku extends Applet implements ActionListener {
  Grid grid;
  int current_player;
  int current_level;
  boolean game_over;
  static final long serialVersionUID=1;
  AudioClip placed;
  CheckboxGroup game_level;
  Checkbox beginner;

  public void init () {
    Panel pleft,pright;
    Panel pcheck,pnew;
    Button bnew;
    Checkbox easy,medium,hard;
    int j;

    placed=getAudioClip (getCodeBase(),"placed.wav");
    placed.play ();
    placed.stop ();

    pleft=new Panel();
    grid = new Grid();

    pleft.add (grid);
    
    pright=new Panel();
    pright.setLayout (new GridLayout(3,1));

    bnew=new Button ("    New    ");
    pnew=new Panel();
    pnew.add (bnew);
    pright.add (pnew);

    beginner=new Checkbox ("HINT",null,false);
    pright.add (beginner);

    pcheck=new Panel ();
    pcheck.setLayout (new GridLayout (3,1));
    game_level=new CheckboxGroup();
    hard=new Checkbox ("Hard",game_level,false);
    medium=new Checkbox ("Medium",game_level,false);
    easy=new Checkbox ("Easy",game_level,true);
    pcheck.add (hard);
    pcheck.add (medium);
    pcheck.add (easy);
    pright.add (pcheck);

    setLayout (new BorderLayout ());
    setBackground (Color.white);

    add ("Center",pleft);
    add ("East",pright);

    for (j=0; j<19*19; j++)
        grid.cell[j].addActionListener (this);
    bnew.addActionListener (this);

    current_level=1;

  }

  public void start () {
    current_player=Table.X;
    game_over=false;

    grid.clear();
  }

  private Table retrieveTable () {
    Table table;
    int j;
    String label;

    label=game_level.getSelectedCheckbox().getLabel();
    if ("Easy".equals (label))
      current_level=1;
    else if ("Medium".equals (label))
      current_level=2;
    else if ("Hard".equals (label))
      current_level=3;

    table=new Table (current_level);    
    for (j=0; j<19*19; j++)
        table.setState (j,grid.cell[j].getState());

    return table;
  }

  private void end_game (Table table) {
    int j;

    game_over=true;
    for (j=0; j<19*19; j++)
      if (table.getSolution (j)!=Table.NONE)
        grid.cell[j].mark ();
  }

  private void identifyTable (Table table) {
    int j;

    table.identify ();
    for (j=0; j<19*19; j++)
        if (table.getSolution (j)!=Table.NONE)
          grid.cell[j].identify ();
        else
          grid.cell[j].normal ();
  }

  private void iteration () {
    Table table;
    int position;

    placed.play ();
    table=retrieveTable ();
    if (beginner.getState ())
      identifyTable (table);
    if (table.check ()) {
      end_game (table);  
    } else {
      position=table.think ();
      placed.play ();
      grid.cell[position].setState (Table.O);

      table=retrieveTable ();
      if (beginner.getState ())
        identifyTable (table);
      if (table.check ()) 
        end_game (table);

    }
 
    table=null;
  }

  public void actionPerformed (ActionEvent e) {
    Cell c;

    if (e.getActionCommand().equals ("    New    ")) {
      start ();
    }
    else if (!game_over) {
      c=(Cell)e.getSource ();
      if (c.setState (current_player)) 
        iteration ();
    }
  }

}
