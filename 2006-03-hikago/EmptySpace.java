public class EmptySpace {
	int pointer;
	int size;
	
	EmptySpace (int gameData[], int addr) {
		pointer=0;
		for (int i=0; i<4; i++)
		  pointer|=gameData[addr+i]<<(i*8);
		pointer-=0x8000000;  
		
		for (size=0; gameData[pointer+size]!=0; size+=gameData[pointer+size]>=0x80?2:1);		
    size++;
	}
	
	int getSize() {
		return size;
	}
	
	int getPointer() {
		return pointer;
	}
}