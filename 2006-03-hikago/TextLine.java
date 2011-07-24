import java.util.*;

public class TextLine {
  ArrayList<String> line;
  int len,space,MAX;
  
// -------------------------------------------------------------------	

  TextLine () {
    line=new ArrayList<String>();
    len=0;
    space=0;
    MAX=28;
  }
  
// -------------------------------------------------------------------	

  int getLength(String s) {
  	if (s.equals("@NAME")) {
  		return 8;
  	} else {
  		return s.length();
  	}
  }

// -------------------------------------------------------------------	

  boolean fit (String s) {
  	return (len()+space+getLength(s)<=MAX);
  }
  
// -------------------------------------------------------------------	

  int len() {
  	int l=0;
  	
  	for (String s:line)
  	  l+=getLength(s);
  	  
  	return l;  
  }
  
// -------------------------------------------------------------------	

  void add (String s) {
  	if (space>0) 
  		line.add(" ");
  	line.add(s);	
  	space=1;
  }
  
// -------------------------------------------------------------------	

  StringBuffer flush () {
  	StringBuffer out=new StringBuffer();  	
  	
  	for (String s:line)
  	  out.append(s);  	  
  	  
  	return out;  
  }

// -------------------------------------------------------------------	

  ArrayList<Integer> getBuffer() {
  	ArrayList<Integer> buffer=new ArrayList<Integer>();
  	int name[]={0x87,0x56,0x87,0x40,0x87,0x54};
  	
  	for (String s:line) {
  		if (s.equals("@NAME"))
  		  for (int i=0; i<name.length; i++)
  		    buffer.add(name[i]);
  		else  
  		  for (int i=0; i<s.length(); i++)
  		    buffer.add(s.charAt(i)&0xFF);
  	}
  	
  	return buffer;
  }

// -------------------------------------------------------------------	
  
}