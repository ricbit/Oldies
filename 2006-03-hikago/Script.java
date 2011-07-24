/* Script parser for GBA translations */
/* by Ricardo Bittencourt */
/* started in 2006.3.19 */
/* last modification in 2006.3.28 */

import java.util.*;
import java.io.*;
import java.awt.image.*;
import javax.xml.parsers.*;
import javax.imageio.*;
import org.xml.sax.*;  
import org.w3c.dom.*;

class XMLError extends Exception {
  XMLError (String s) {
    super ("XMLError: "+s);
  }
}

public class Script {

// -------------------------------------------------------------------	
// GLOBALS

  static int[] gameData;
  static Boolean extract;
  static EmptySpaceList emptyList;
  
// -------------------------------------------------------------------	

  public static String getElement (Node n, String element) throws XMLError {
  	NodeList list,list2;
  	String s=null;
  	
  	list=n.getChildNodes();
  	for (int i=0; i<list.getLength(); i++) 
  	  if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals(element)) {
  	    list2=list.item(i).getChildNodes();
  	    
  	    for (int j=0; j<list2.getLength(); j++) 
  	      if (list2.item(j).getNodeType()==Document.TEXT_NODE) {
  	        if (s==null)
  	          s=list2.item(j).getNodeValue();
  	        else  
  	          throw new XMLError ("More than one "+element);
  	      }
  	  }
  	
  	return s;  
  }

// -------------------------------------------------------------------	

  public static String getAttribute (Node n, String element, String attribute) {
  	NodeList list;
  	
  	list=n.getChildNodes();
  	for (int i=0; i<list.getLength(); i++) 
  	  if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals(element)) 
  	    return list.item(i).getAttributes().getNamedItem(attribute).getNodeValue();

  	return null;
  }

// -------------------------------------------------------------------	

  public static int[] readFile (String name) throws XMLError {
  	DataInput in=null;
  	int size;  	
  	File f;
  	    
  	// Read file from disk
  	f=new File(name);
    if (!f.exists()) 
      throw new XMLError ("File <"+name+"> not found");
      
    size=(int)(f.length());    
    int[] buffer=new int[size];
    byte[] byteData=new byte[size];
  	try {
      in=new DataInputStream (new FileInputStream (name));
      in.readFully(byteData,0,size);  
      for (int i=0; i<size; i++)
        buffer[i]=(int)byteData[i]&0xFF;
    } catch (IOException fe) {
      fe.printStackTrace();
    }     
    
    return buffer;
  }
  	
// -------------------------------------------------------------------	

  public static void writeFile (int[] buffer, String name) throws XMLError {
  	DataOutputStream out=null;
  	    
  	// Write file to disk
    byte[] byteData=new byte[gameData.length];
    for (int i=0; i<gameData.length; i++)
      byteData[i]=(byte)gameData[i];
  	try {
      out=new DataOutputStream (new FileOutputStream (name));
      out.write(byteData);  
      out.close();
    } catch (IOException fe) {
      fe.printStackTrace();
    }     
    
    return;
  }
  	
// -------------------------------------------------------------------	

  public static IndexColorModel readPalette (String name, int index) throws XMLError {
  	int[] rawPalette;
  	byte[] r,g,b;
  	
  	rawPalette=readFile(name);
  	r=new byte[16];
  	g=new byte[16];
  	b=new byte[16];
  	for (int i=0; i<16; i++) {
  		r[i]=(byte) rawPalette[index*16*3+i*3+0];
  		g[i]=(byte) rawPalette[index*16*3+i*3+1];
  		b[i]=(byte) rawPalette[index*16*3+i*3+2];
    } 
    IndexColorModel finalPalette=new IndexColorModel (8,16,r,g,b);
  	
  	return finalPalette;
  }

// -------------------------------------------------------------------	

  public static void mySetPixel (BufferedImage image, int x, int y, int value) {
    int pixel[];
    WritableRaster wr=image.getRaster();
    
    pixel=new int [1];
    pixel[0]=value;
    wr.setPixel(x,y,pixel);
  }

// -------------------------------------------------------------------	

  public static int myGetPixel (BufferedImage image, int x, int y) {
    int pixel[];
    WritableRaster wr=image.getRaster();
    
    pixel=new int [1];
    pixel=wr.getPixel(x,y,pixel);
    return pixel[0];
  }

// -------------------------------------------------------------------	

  public static void writeGraphic (Node n) throws XMLError {
  	int addr,width,height,index;
  	String name;
  	IndexColorModel palette;
  	BufferedImage image=null;
    
    addr=Integer.parseInt(getElement(n,"addr"),16);
    width=Integer.parseInt(getElement(n,"width"));
    height=Integer.parseInt(getElement(n,"height"));
    name="_"+getElement(n,"name")+".bmp";
    
    File f=new File(name);
    if (!f.exists())
      return;
      
    try {
      image=ImageIO.read(f);
    } catch (IOException fe) {
      fe.printStackTrace();
    }     

    for (int i=0; i<height*width*4*8; i++)
       gameData[addr+i]=0;

    for (int hh=0; hh<height; hh++)
      for (int ww=0; ww<width; ww++)
        for (int j=0; j<8; j++) 
          for (int i=0; i<4; i++)
            for (int ii=0; ii<2; ii++) 
              gameData[addr+i+j*4+ww*4*8+hh*4*8*width]|=(myGetPixel(image,ww*8+i*2+ii,hh*8+j)&0xf)<<(ii*4);

    System.out.println ("inserted graphic <"+name+">.");
  }
 
// -------------------------------------------------------------------	

  public static void readGraphic (Node n) throws XMLError {
  	int addr,width,height,index;
  	String name;
  	IndexColorModel palette;
  	BufferedImage image;
    
    addr=Integer.parseInt(getElement(n,"addr"),16);
    width=Integer.parseInt(getElement(n,"width"));
    height=Integer.parseInt(getElement(n,"height"));
    name=getElement(n,"name")+".bmp";
    index=Integer.parseInt(getAttribute(n,"palette","index"));
    palette=readPalette(getElement(n,"palette"),index);
    
    image=new BufferedImage (width*8, height*8, BufferedImage.TYPE_BYTE_BINARY, palette);

    for (int hh=0; hh<height; hh++)
      for (int ww=0; ww<width; ww++)
        for (int j=0; j<8; j++) 
          for (int i=0; i<4; i++)
            for (int ii=0; ii<2; ii++) 
              mySetPixel (image,ww*8+i*2+ii,hh*8+j,(0xf&(gameData[addr+(ww+hh*width)*4*8+j*4+i]>>(ii*4))));
              
    //System.out.println (((IndexColorModel)(image.getColorModel())).getMapSize());
    
    try {
      ImageIO.write(image, "bmp", new File(name));
    } catch (IOException fe) {
      fe.printStackTrace();
    }     
    
    System.out.println ("extracted graphic <"+name+">.");
  }

// -------------------------------------------------------------------	

  public static void readText (Node n) throws XMLError {
  	int pointer,addr;
  	DataOutputStream out;
  	
  	pointer=Integer.parseInt(getElement(n,"pointer"),16);
  	addr=0;
  	for (int i=0; i<4; i++)
  	  addr|=gameData[pointer+i]<<(i*8);
  	addr-=0x8000000;  

  	try {
      out=new DataOutputStream (new FileOutputStream (getElement(n,"pointer")+".sjs"));
      while (gameData[addr]!=0) {
        out.writeByte(gameData[addr++]);  
        out.writeByte(gameData[addr++]);  
      }
      out.close();
    } catch (IOException fe) {
      fe.printStackTrace();
    }     
    
    System.out.println ("extracted text <"+getElement(n,"pointer")+">.");    
  }    

// -------------------------------------------------------------------	

  public static void writeText (Node n) throws XMLError {
  	int pointer,addr;
  	TextBlock text;
  	
  	if (getElement(n,"data")==null)
  	   return;
  	   
  	pointer=Integer.parseInt(getElement(n,"pointer"),16);
  	text=new TextBlock(getElement(n,"data").split(" "));

    System.out.println ("\ninserted text <"+getElement(n,"pointer")+">.");    
    addr=emptyList.find (text.getBuffer().size());
  	
  	addr+=0x8000000;
  	for (int i=0; i<4; i++)
  	  gameData[pointer+i]=(addr>>(i*8))&0xFF;  
  	addr-=0x8000000;
  	
  	for (int i=0; i<text.getBuffer().size(); i++)
  	  gameData[addr+i]=text.getBuffer().get(i)&0xFF;
  	  
    System.out.println ("----------------------------");    
  	text.flush();
  }    

// -------------------------------------------------------------------	

  public static void buildEmptyList (NodeList list) throws XMLError {
  	  	
  	for (int i=0; i<list.getLength(); i++) 
  	  if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals("text")) 
  	    if (getElement(list.item(i),"data")!=null)
  	      emptyList.add(gameData,Integer.parseInt(getElement(list.item(i),"pointer"),16));  	 
  }
  
// -------------------------------------------------------------------	

  public static void buildAddrLog (NodeList list, String name) throws XMLError {

  	try {
      DataOutputStream out=new DataOutputStream (new FileOutputStream (name));
  	  for (int i=0; i<list.getLength(); i++) 
  	    if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals("text")) 
  	      out.writeBytes(getElement(list.item(i),"pointer")+"\n");  	 
      out.close();
    } catch (IOException fe) {
      fe.printStackTrace();
    }     
  }
  
// -------------------------------------------------------------------	

  public static void readTranslation (Node n) throws XMLError {
  	NodeList list;
  	
  	list=n.getChildNodes();
  	
  	// Search for the game rom
    gameData=readFile(getElement(n,"game"));    
    System.out.println ("Found <"+getElement(n,"game")+">, "+gameData.length+" bytes.");
  	    
  	// Process Graphics
  	for (int i=0; i<list.getLength(); i++) 
  	  if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals("graphic")) {
  	  	if (extract)
  	      readGraphic(list.item(i));
  	    else  
  	      writeGraphic(list.item(i));
  	  }
  	  
  	// Process Text
  	if (!extract) {
  	  buildEmptyList (list);
  	  buildAddrLog (list,getElement(n,"addrlog"));
  	}
  	
  	for (int i=0; i<list.getLength(); i++) 
  	  if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals("text")) {
  	  	if (extract)
  	      readText(list.item(i));
  	    else  
  	      writeText(list.item(i));
  	  }
  	  
  	// Write back
  	if (!extract) {
  		writeFile(gameData,"_"+getElement(n,"game"));
      System.out.println ("Finished <_"+getElement(n,"game")+">.");
    }     
  	
  }

// -------------------------------------------------------------------	

  public static void readDocument (Node n) throws XMLError {
  	NodeList list;
  	
  	// Check for document-type
  	if (n.getNodeType()!=Document.DOCUMENT_NODE) 
  	  throw new XMLError("Document not found");
  	  
  	list=n.getChildNodes();
  	for (int i=0; i<list.getLength(); i++) 
  	  if (list.item(i).getNodeType()==Document.ELEMENT_NODE && list.item(i).getNodeName().equals("translation"))
  	     readTranslation(list.item(i));
  }

// -------------------------------------------------------------------	

  public static void main(String argv[]) {
  	
  	// Check for command line usage
  	if (argv.length!=2) {
      System.err.println("Usage: java Script filename (extract/insert)");
      System.exit(1);
    }	  		
    
    if (!argv[1].equals("extract") && !argv[1].equals("insert")) {
      System.err.println("Usage: java Script filename (extract/insert)");
      System.exit(1);
    }
    
    // Init globals
    gameData=null;
    extract=argv[1].equals("extract");
    emptyList=new EmptySpaceList(0x7fade0);
    
    // Create xml factory
    DocumentBuilderFactory factory=DocumentBuilderFactory.newInstance();
    
    // Parse the document and check for errors
    try {
      DocumentBuilder builder = factory.newDocumentBuilder();
      Document document = builder.parse( new File(argv[0]) );
	    readDocument (document);
 
    } catch (SAXException sxe) {
      // Error generated during parsing
      Exception  x = sxe;
      if (sxe.getException() != null)
        x = sxe.getException();
      x.printStackTrace();

    } catch (ParserConfigurationException pce) {
      // Parser with specified options can't be built
      pce.printStackTrace();

    } catch (IOException ioe) {
      // I/O error
      ioe.printStackTrace();

    } catch (XMLError xe) {
      // XML error
      xe.printStackTrace();
    }
  }
	
// -------------------------------------------------------------------	
}