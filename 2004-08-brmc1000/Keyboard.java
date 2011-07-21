import java.awt.event.*;

public class Keyboard implements KeyListener {
  int[] keyMap;
  int keySelect;
  boolean tapeStarted;

  Keyboard() {
    keyMap=new int[8];
    for (int i=0; i<8; i++)
      keyMap[i]=0xFF;
    tapeStarted=false;
  }

  public int read() {
    int line;

    for (int i=0; i<8; i++) {
      line=(~(1<<i))&0xFF;
      if (line==keySelect) 
	return keyMap[i];
    }
    return 0xFF; 
  }

  public boolean hasTapeStarted() {
    return tapeStarted;
  }

  public void write(int a) {
    keySelect=a;
  }

  private void keyAction(KeyEvent e) {
    int line,col;

    line=0; col=0;
    switch (e.getKeyCode()) {
      case KeyEvent.VK_EQUALS:
	line=0; col=0; // @ 
	break;
      case 'H':
	line=0; col=1; // H
	break;
      case 'P':
	line=0; col=2; // P
	break;
      case 'X':
	line=0; col=3; // X
	break;
      case '0':
	line=0; col=4; // 0
	break;
      case '8':
	line=0; col=5; // 8
	break;
      case 'A':
	line=1; col=0; // A
	break;
      case 'I':
	line=1; col=1; // I
	break;
      case 'Q':
	line=1; col=2; // Q
	break;
      case 'Y':
	line=1; col=3; // Y
	break;
      case '1':
	line=1; col=4; // 1
	break;
      case '9':
	line=1; col=5; // 9
	break;
      case 'B':
	line=2; col=0; // B
	break;
      case 'J':
	line=2; col=1; // J
	break;
      case 'R':
	line=2; col=2; // R
	break;
      case 'Z':
	line=2; col=3; // Z
	break;
      case '2':
	line=2; col=4; // 2
	break;
      case ']':
	line=2; col=5; // ":"
	break;
      case 'C':
	line=3; col=0; // C
	break;
      case 'K':
	line=3; col=1; // K
	break;
      case 'S':
	line=3; col=2; // S
	break;
      case KeyEvent.VK_ENTER:
	line=3; col=3; // ENTER
	break;
      case '3':
	line=3; col=4; // 3
	break;
      case KeyEvent.VK_SEMICOLON:
	line=3; col=5; // ;
	break;
      case 'D':
	line=4; col=0; // D
	break;
      case 'L':
	line=4; col=1; // L
	break;
      case 'T':
	line=4; col=2; // T
	break;
      case KeyEvent.VK_SPACE:
	line=4; col=3; // T
	break;
      case '4':
	line=4; col=4; // 4
	break;
      case KeyEvent.VK_COMMA:
	line=4; col=5; // ","
	break;
      case 'E':
	line=5; col=0; // E
	break;
      case 'M':
	line=5; col=1; // M
	break;
      case 'U':
	line=5; col=2; // U
	break;
      case KeyEvent.VK_BACK_SPACE:
	line=5; col=3; // RUBOUT
	break;
      case '5':
	line=5; col=4; // 5
	break;
      case KeyEvent.VK_MINUS:
	line=5; col=5; // -
	break;
      case 'F':
	line=6; col=0; // F
	break;
      case 'N':
	line=6; col=1; // N
	break;
      case 'V':
	line=6; col=2; // V
	break;
      case '[':
	line=6; col=3; // ^
	break;
      case '6':
	line=6; col=4; // 6
	break;
      case KeyEvent.VK_PERIOD:
	line=6; col=5; // .
	break;
      case 'G':
	line=7; col=0; // G
	break;
      case 'O':
	line=7; col=1; // O
	break;
      case 'W':
	line=7; col=2; // W
	break;
      case '7':
	line=7; col=4; // 7
	break;
      case KeyEvent.VK_SLASH:
      case 0: // This is added so it can recognize the slash key on the Brazilian keyboard (ABNT2).   
	line=7; col=5; // /
	break;
      case KeyEvent.VK_DELETE:
	line=7; col=3; // reset (?)
	break;
      case KeyEvent.VK_SHIFT:
	setLine(e,6);
	return;
      case KeyEvent.VK_CONTROL:
	setLine(e,7);
	return;
      case KeyEvent.VK_CAPS_LOCK:
	line=1; col=0; // joy A - button
	break;
      case KeyEvent.VK_UP:
	line=1; col=1; // joy A - up
	break;
      case KeyEvent.VK_DOWN:
	line=1; col=2; // joy A - down
	break;
      case KeyEvent.VK_LEFT:
	line=1; col=3; // joy A - left
	break;
      case KeyEvent.VK_RIGHT:
	line=1; col=4; // joy A - right
	break;
      case KeyEvent.VK_NUMPAD5:
	line=0; col=0; // joy B - button
	break;
      case KeyEvent.VK_NUMPAD8:
	line=0; col=1; // joy B - up
	break;
      case KeyEvent.VK_NUMPAD2:
	line=0; col=2; // joy B - down
	break;
      case KeyEvent.VK_NUMPAD4:
	line=0; col=3; // joy B - left
	break;
      case KeyEvent.VK_NUMPAD6:
	line=0; col=4; // joy B - right
	break;
      case KeyEvent.VK_F5:
	tapeStarted=true;
	return;
      default:
	return;
    }
    if (e.getID()==KeyEvent.KEY_PRESSED)
      keyMap[line]&=(~(1<<col))&0xFF;
    else
      keyMap[line]|=(1<<col);
  }

  public void keyPressed(KeyEvent e) {
    keyAction(e);
  }
  public void keyReleased(KeyEvent e) {
    keyAction(e);
  }
 
  private void setLine (KeyEvent e, int line) {
    for (int i=0; i<8; i++)
      if (e.getID()==KeyEvent.KEY_PRESSED)
        keyMap[i]&=(~(1<<line))&0xFF;
      else
        keyMap[i]|=(1<<line);
  }

  public void keyTyped(KeyEvent e) {}
}