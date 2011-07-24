import java.util.*;

public class TextBlock {
  TextLine line[];
  ArrayList<Integer> data;
  int current;
	
// -------------------------------------------------------------------	

	TextBlock (String[] text) {
		current=0;
		
		line=new TextLine[4];
		
		for (int i=0; i<4; i++)
		   line[i]=new TextLine();		   
		   
		for (int i=0; i<text.length; i++) {
		  if (!line[current].fit(text[i]))
		    current++;
		    
		  line[current].add(text[i]);
		}
		
		data=null;
	}
	
// -------------------------------------------------------------------	

	void flush () {
		for (int i=0; i<=current; i++)
		  System.out.println(line[i].flush());
	}

// -------------------------------------------------------------------	

  ArrayList<Integer> getBuffer () {
  	ArrayList<Integer> buffer;
  	
  	if (data!=null)
  	  return data;

    data=new ArrayList<Integer>();
    
  	for (int i=0; i<=current; i++) {
  		buffer=line[i].getBuffer();
  		
  		for (int j=0; j<buffer.size(); j++)
  		  data.add(buffer.get(j));
  		
  		if (i==current) 
  		  data.add(0);
  		else {
  		  data.add(0x81);
  		  data.add(0xab);
  		} 
  	}
  	
  	return data; 
  }
	
}

