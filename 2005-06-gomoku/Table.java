public class Table {
	  static final long serialVersionUID=1;
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

	    node=new int[19*19];
	    solution=new int[19*19];
	    for (i=0; i<19*19; i++) {
	      node[i]=NONE;
	      solution[i]=NONE;
	    }
	    max_depth=game_level;
	  }

	  public void setState (int j, int state) {
	    node[j]=state;
	  }

	  public int getState (int i) {
	    return node[i];
	  }

	  private void line (int action, int a, int b, int c, int d, int e) {
	    int tn, tx, to;
	    int value;

	    switch (action) {
	      case CHECK:
	        if ((node[a]==node[b]) && (node[b]==node[c]) &&
	           (node[c]==node[d]) && (node[d]==node[a]) &&
	           (node[a]==node[e]) &&
	           (node[a]!=NONE))
	        {
	          solution[a]=node[a];
	          solution[b]=node[b];
	          solution[c]=node[c];
	          solution[d]=node[d];
	          solution[e]=node[e];
	        }
	        break;
	      case EVALUATE:
	        tn=0; tx=0; to=0;

	        if (node[a]==NONE) tn++;
	        if (node[b]==NONE) tn++;
	        if (node[c]==NONE) tn++;
	        if (node[d]==NONE) tn++;
	        if (node[e]==NONE) tn++;

	        if (node[a]==X) tx++;
	        if (node[b]==X) tx++;
	        if (node[c]==X) tx++;
	        if (node[d]==X) tx++;
	        if (node[e]==X) tx++;

	        if (node[a]==O) to++;
	        if (node[b]==O) to++;
	        if (node[c]==O) to++;
	        if (node[d]==O) to++;
	        if (node[e]==O) to++;

	        if (tx+tn==5) {
	          value=0;
	          switch (tx) {
	            case 1: value=-1; break;
	            case 2: value=-10; break;
	            case 3: value=-10000; break;
	            case 4: value=-1000000; break;
	            case 5: value=-10000000; break;
	          }
	          solution[a]+=value;
	          solution[b]+=value;
	          solution[c]+=value;
	          solution[d]+=value;
	          solution[e]+=value;
	        }

	        if (to+tn==5) {
	          value=0;
	          switch (to) {
	            case 1: value=1; break;
	            case 2: value=10; break;
	            case 3: value=1000; break;
	            case 4: value=100000; break;
	            case 5: value=20000000; break;
	          }
	          solution[a]+=value;
	          solution[b]+=value;
	          solution[c]+=value;
	          solution[d]+=value;
	          solution[e]+=value;
	        }

	        break;
	      case IDENTIFY:
	        tn=0; tx=0; to=0;

	        if (node[a]==NONE) tn++;
	        if (node[b]==NONE) tn++;
	        if (node[c]==NONE) tn++;
	        if (node[d]==NONE) tn++;
	        if (node[e]==NONE) tn++;

	        if (node[a]==X) tx++;
	        if (node[b]==X) tx++;
	        if (node[c]==X) tx++;
	        if (node[d]==X) tx++;
	        if (node[e]==X) tx++;

	        if (node[a]==O) to++;
	        if (node[b]==O) to++;
	        if (node[c]==O) to++;
	        if (node[d]==O) to++;
	        if (node[e]==O) to++;

	        if (tn==1 && ((tx+tn==5) || (to+tn==5))) {
	          if (node[a]==NONE) solution[a]=1;
	          if (node[b]==NONE) solution[b]=1;
	          if (node[c]==NONE) solution[c]=1;
	          if (node[d]==NONE) solution[d]=1;
	          if (node[e]==NONE) solution[e]=1;
	        }

	        break;
	    }
	  }

	  private void traverse (int action) {
	    int i,j,k;

	    // in-frame horizontal
	    for (k=0; k<19; k++)
	      for (j=0; j<=19-5; j++)
            line (action,k*19+0+j,k*19+1+j,k*19+2+j,k*19+3+j,k*19+4+j);

	    // in-frame vertical
	    for (k=0; k<19; k++)
  	      for (j=0; j<=19-5; j++)
	        line (action,j*19+k,(j+1)*19+k,(j+2)*19+k,(j+3)*19+k,(j+4)*19+k);

	    // in-frame diagonal negative
	    
	    for (k=0; k<=19-5; k++)
		  for (j=0; j<=19-5; j++)
	          line (action,(k)*19+(j),
	        		(k+1)*19+(j+1),
	        		(k+2)*19+(j+2),
	        		(k+3)*19+(j+3),
	        		(k+4)*19+(j+4));

	    // in-frame diagonal positive
	    for (k=0; k<=19-5; k++)
		  for (j=0; j<=19-5; j++)
	          line (action,(k)*19+(j+4),
	        		(k+1)*19+(j+3),
	        		(k+2)*19+(j+2),
	        		(k+3)*19+(j+1),
	        		(k+4)*19+(j+0));

	  }

	  public boolean check () {
	    int i;
	    boolean value=false;

	    for (i=0; i<19*19; i++)
	      solution[i]=NONE;

	    traverse (CHECK);

	    for (i=0; i<19*19; i++)
	      if (solution[i]!=NONE)
	        value=true;

	    return value;
	  }

	  private int evaluate () {
	    int i;
	    int total=0;

	    for (i=0; i<19*19; i++)
	      solution[i]=0;
	    
	    traverse (EVALUATE);

	    for (i=0; i<19*19; i++)
	      total+=solution[i];

	    return total;
	  }

	  public void identify () {
	    int i;
	    int total=0;

	    for (i=0; i<19*19; i++)
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

	      for (i=0; i<19*19; i++)
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
