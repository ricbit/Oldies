public class Table {
  final static int NONE=0;
  final static int X=1;
  final static int O=2;

  final static int CHECK=0;
  final static int EVALUATE=1;
  final static int IDENTIFY=2;

  final static int evalMIN=0;
  final static int evalMAX=1;

  int[] node;
  int[] solution;

  int max_depth=3;

  public Table (int game_level) {
    int i;

    node=new int[64];
    solution=new int[64];
    for (i=0; i<64; i++) {
      node[i]=NONE;
      solution[i]=NONE;
    }
    max_depth=game_level;
  }

  public void setState (int i, int j, int state) {
    node[i*16+j]=state;
  }

  public int getState (int i) {
    return node[i];
  }

  private void line (int action, int a, int b, int c, int d) {
    int tn, tx, to;
    int value;

    switch (action) {
      case CHECK:
        if ((node[a]==node[b]) && (node[b]==node[c]) &&
           (node[c]==node[d]) && (node[d]==node[a]) &&
           (node[a]!=NONE))
        {
          solution[a]=node[a];
          solution[b]=node[b];
          solution[c]=node[c];
          solution[d]=node[d];
        }
        break;
      case EVALUATE:
        tn=0; tx=0; to=0;

        if (node[a]==NONE) tn++;
        if (node[b]==NONE) tn++;
        if (node[c]==NONE) tn++;
        if (node[d]==NONE) tn++;

        if (node[a]==X) tx++;
        if (node[b]==X) tx++;
        if (node[c]==X) tx++;
        if (node[d]==X) tx++;

        if (node[a]==O) to++;
        if (node[b]==O) to++;
        if (node[c]==O) to++;
        if (node[d]==O) to++;

        if (tx+tn==4) {
          value=0;
          switch (tx) {
            case 1: value=-1; break;
            case 2: value=-10; break;
            case 3: value=-10000; break;
            case 4: value=-100000; break;
          }
          solution[a]+=value;
          solution[b]+=value;
          solution[c]+=value;
          solution[d]+=value;
        }

        if (to+tn==4) {
          value=0;
          switch (to) {
            case 1: value=1; break;
            case 2: value=10; break;
            case 3: value=10000; break;
            case 4: value=100000; break;
          }
          solution[a]+=value;
          solution[b]+=value;
          solution[c]+=value;
          solution[d]+=value;
        }

        break;
      case IDENTIFY:
        tn=0; tx=0; to=0;

        if (node[a]==NONE) tn++;
        if (node[b]==NONE) tn++;
        if (node[c]==NONE) tn++;
        if (node[d]==NONE) tn++;

        if (node[a]==X) tx++;
        if (node[b]==X) tx++;
        if (node[c]==X) tx++;
        if (node[d]==X) tx++;

        if (node[a]==O) to++;
        if (node[b]==O) to++;
        if (node[c]==O) to++;
        if (node[d]==O) to++;

        if (tn==1 && ((tx+tn==4) || (to+tn==4))) {
          if (node[a]==NONE) solution[a]=1;
          if (node[b]==NONE) solution[b]=1;
          if (node[c]==NONE) solution[c]=1;
          if (node[d]==NONE) solution[d]=1;
        }

        break;
    }
  }

  private void traverse (int action) {
    int i,j;

    // in-frame horizontal
    for (i=0; i<4; i++) 
      for (j=0; j<4; j++)
        line (action,i*16+j*4+0,i*16+j*4+1,i*16+j*4+2,i*16+j*4+3);

    // in-frame vertical
    for (i=0; i<4; i++) 
      for (j=0; j<4; j++)
        line (action,i*16+0*4+j,i*16+1*4+j,i*16+2*4+j,i*16+3*4+j);

    // in-frame diagonal
    for (i=0; i<4; i++) {
      line (action,i*16+0,i*16+4+1,i*16+8+2,i*16+12+3);
      line (action,i*16+3,i*16+4+2,i*16+8+1,i*16+12+0);
    }

    // deep single
    for (i=0; i<16; i++)
      line (action,i+16*0,i+16*1,i+16*2,i+16*3);

    // deep horizontal positive
    for (i=0; i<4; i++)
      for (j=0; j<4; j++)
        line (action,i*4+0+((j+0)%4)*16,i*4+1+((j+1)%4)*16,
              i*4+2+((j+2)%4)*16,i*4+3+((j+3)%4)*16);

    // deep horizontal negative
    for (i=0; i<4; i++)
      for (j=0; j<4; j++)
        line (action,i*4+0+((j+3)%4)*16,i*4+1+((j+2)%4)*16,
              i*4+2+((j+1)%4)*16,i*4+3+((j+0)%4)*16);

    // deep vertical positive
    for (i=0; i<4; i++)
      for (j=0; j<4; j++)
        line (action,i+0+((j+0)%4)*16,i+4+((j+1)%4)*16,
              i+8+((j+2)%4)*16,i+12+((j+3)%4)*16);

    // deep vertical negative
    for (i=0; i<4; i++)
      for (j=0; j<4; j++)
        line (action,i+0+((j+3)%4)*16,i+4+((j+2)%4)*16,
              i+8+((j+1)%4)*16,i+12+((j+0)%4)*16);

    // deep diagonal positive
    for (i=0; i<4; i++) {
      line (action,((i+0)%4)*16+0,((i+1)%4)*16+4+1,
            ((i+2)%4)*16+8+2,((i+3)%4)*16+12+3);
      line (action,((i+0)%4)*16+3,((i+1)%4)*16+4+2,
            ((i+2)%4)*16+8+1,((i+3)%4)*16+12+0);
    }

    // deep diagonal negative
    for (i=0; i<4; i++) {
      line (action,((i+3)%4)*16+0,((i+2)%4)*16+4+1,
            ((i+1)%4)*16+8+2,((i+0)%4)*16+12+3);
      line (action,((i+3)%4)*16+3,((i+2)%4)*16+4+2,
            ((i+1)%4)*16+8+1,((i+0)%4)*16+12+0);
    }

  }

  public boolean check () {
    int i;
    boolean value=false;

    for (i=0; i<64; i++)
      solution[i]=NONE;

    traverse (CHECK);

    for (i=0; i<64; i++)
      if (solution[i]!=NONE)
        value=true;

    return value;
  }

  private int evaluate () {
    int i;
    int total=0;

    for (i=0; i<64; i++)
      solution[i]=0;
    
    traverse (EVALUATE);

    for (i=0; i<64; i++)
      total+=solution[i];

    return total;
  }

  public void identify () {
    int i;
    int total=0;

    for (i=0; i<64; i++)
      solution[i]=0;
    
    traverse (IDENTIFY);

  }

  public int minimax (int action, int rec_level) {
    int chosen_i,chosen_value;
    int i,value;

    if (rec_level==max_depth)
      return evaluate();
    else {

      chosen_i=0;

      if (action==evalMAX)
        chosen_value=Integer.MIN_VALUE;
      else
        chosen_value=Integer.MAX_VALUE;

      for (i=0; i<64; i++)
        if (node[i]==NONE) {

          if (action==evalMAX) {
            node[i]=O;
            if (check ()) {
              value=evaluate();
              if (value>chosen_value) {
                chosen_i=i;
                chosen_value=value;
              }
            }
            else if (evaluate() > chosen_value) {
              value=minimax (evalMIN,rec_level+1);
              if (value>chosen_value) {
                chosen_i=i;
                chosen_value=value;
              }
            }
            node[i]=NONE;
          } else {
            node[i]=X;
            if (check ()) {
              value=evaluate();
              if (value<chosen_value) {
                chosen_i=i;
                chosen_value=value;
              }
            }
            else if (evaluate() < chosen_value) {
              value=minimax (evalMAX,rec_level+1);
              if (value<chosen_value) {
                chosen_i=i;
                chosen_value=value;
              }
            }
            node[i]=NONE;
          }
        }

      if (rec_level==0)
        return chosen_i;
      else
        return chosen_value;
    }
  }

  public int think () {
    int chosen;

    chosen=minimax (evalMAX,0);

    return chosen;
  }

  public int getSolution (int i) {
    return solution[i];
  }

}
