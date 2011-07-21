import java.awt.*;
import java.awt.event.*;
import java.applet.*;

public class velha extends Applet implements ActionListener {
  Grid[] grid;
  int current_player;
  int current_level;
  boolean game_over;
  AudioClip placed;
  CheckboxGroup game_level;
  Checkbox beginner;

  public void init () {
    Panel pleft,pright;
    Panel pcheck,pnew;
    Button bnew;
    Checkbox easy,medium,hard;
    int i,j;

    placed=getAudioClip (getCodeBase(),"placed.wav");
    placed.play ();
    placed.stop ();

    grid=new Grid[4];
    for (i=0; i<4; i++) 
      grid[i]=new Grid();

    pleft=new Panel();
    pleft.setLayout (new GridLayout (3,3));

    pleft.add (new Panel() );
    pleft.add ( grid[0] );
    pleft.add (new Panel() );

    pleft.add ( grid[3] );
    pleft.add (new Panel() );
    pleft.add ( grid[1] );

    pleft.add (new Panel() );
    pleft.add ( grid[2] );
    pleft.add (new Panel() );

    pright=new Panel();
    pright.setLayout (new GridLayout(3,1));

    bnew=new Button ("    New    ");
    pnew=new Panel();
    pnew.add (bnew);
    pright.add (pnew);

    beginner=new Checkbox ("Beginner",null,false);
    pright.add (beginner);

    pcheck=new Panel ();
    pcheck.setLayout (new GridLayout (3,1));
    game_level=new CheckboxGroup();
    easy=new Checkbox ("Easy",game_level,false);
    medium=new Checkbox ("Medium",game_level,false);
    hard=new Checkbox ("Hard",game_level,true);
    pcheck.add (easy);
    pcheck.add (medium);
    pcheck.add (hard);
    pright.add (pcheck);

    setLayout (new BorderLayout ());
    setBackground (Color.white);

    add ("Center",pleft);
    add ("East",pright);

    for (i=0; i<4; i++)
      for (j=0; j<16; j++)
        grid[i].cell[j].addActionListener (this);
    bnew.addActionListener (this);

    current_level=3;

  }

  public void start () {
    int i;

    current_player=Table.X;
    game_over=false;

    for (i=0; i<4; i++)
      grid[i].clear ();
  }

  private Table retrieveTable () {
    Table table;
    int i,j;
    String label;

    label=game_level.getSelectedCheckbox().getLabel();
    if ("Easy".equals (label))
      current_level=1;
    else if ("Medium".equals (label))
      current_level=2;
    else if ("Hard".equals (label))
      current_level=3;

    table=new Table (current_level);
    for (i=0; i<4; i++)
      for (j=0; j<16; j++)
        table.setState (i,j,grid[i].cell[j].getState());

    return table;
  }

  private void end_game (Table table) {
    int i,j;

    game_over=true;
    for (i=0; i<4; i++)
      for (j=0; j<16; j++)
        if (table.getSolution (i*16+j)!=Table.NONE)
          grid[i].cell[j].mark ();
  }

  private void identifyTable (Table table) {
    int i,j;

    table.identify ();
    for (i=0; i<4; i++)
      for (j=0; j<16; j++)
        if (table.getSolution (i*16+j)!=Table.NONE)
          grid[i].cell[j].identify ();
        else
          grid[i].cell[j].normal ();
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
      grid[position/16].cell[position%16].setState (Table.O);

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
