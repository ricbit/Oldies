import java.util.*;

public class EmptySpaceList {
	ArrayList<EmptySpace> list;
	int freePos;
	
// -------------------------------------------------------------------	

	EmptySpaceList(int pos) {
		list=new ArrayList<EmptySpace>();
		freePos=pos;
	}
	
// -------------------------------------------------------------------	

	void add (int gameData[], int addr) {
		list.add(new EmptySpace(gameData,addr));
	}

// -------------------------------------------------------------------	
	
	void flush() {
	  System.out.println ("free spaces:");
		for (EmptySpace e: list)
		  System.out.println ("free: "+e.getSize()+" at "+Integer.toHexString(e.getPointer()));
	}
	
// -------------------------------------------------------------------	

  int find(int size) {
  	int max=10000,addr;
  	EmptySpace chosen=null;
  	
  	for (EmptySpace e: list) 
  		if (e.getSize()>=size && e.getSize()<max) {
  			chosen=e;
  			max=e.getSize();
  		}
  		
    //chosen=null;
    if (chosen==null) {
   	  System.out.println ("placed "+size+" in a new block.");    	
    	addr=freePos;
    	freePos+=size;
    }	else {
   	  System.out.println ("placed "+size+" in a "+chosen.getSize()+" block.");
   	  addr=chosen.getPointer();
   	  list.remove(chosen);
    }

    return addr;
  }
	
// -------------------------------------------------------------------	
	
}