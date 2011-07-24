//---------------------------------------------------------------------------
#include <vcl.h>
#include <string.h>
#include <stdlib.h>
#pragma hdrstop

#include "brmsx_z80.h"
#include "brmsx_engine.h"
#include "brmsx_vdp.h"
#include "fudebug_window.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TFudebug *Fudebug;
int breakpointF8;
int disasm_addr;

extern unsigned char *vram;
extern unsigned int z80speed;


//---------------------------------------------------------------------------
__fastcall TFudebug::TFudebug(TComponent* Owner)
        : TForm(Owner)
{
  fast_command=0;
}

#define RGB2WINDOWS(color) \
  (TColor((((color)>>16)&0xFF)+((color)&0xFF00)+(((color)&0xFF)<<16)))


//---------------------------------------------------------------------------

#define CHECK_REG(reg) \
        if (s##reg!= reg )\
          label_##reg->Font->Color=clRed;\
        else\
          label_##reg->Font->Color=clWindowText;


AnsiString printop100 (int addr, char *str) {
  return AnsiString(IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+
"           "+str);
}

#define PRINTOP100(op,str) \
case op : output=printop100(addr,str);\
addr++;break;

AnsiString printop200 (int addr, char *str) {
  return AnsiString(IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" "+
  IntToHex(readmem(addr+1),2)+"        "+str);
}

#define PRINTOP200(op,str) \
case op : output=printop200(addr,str);\
addr+=2;break;

AnsiString printop312 (int addr, char *str) {
  return AnsiString(IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " +
IntToHex(readmem(addr+1),2)+" "+IntToHex(readmem(addr+2),2)+"     "+str+
IntToHex(readmem(addr+2),2)+IntToHex(readmem(addr+1),2));
}

#define PRINTOP312(op,str) \
case op : output=printop312(addr,str);\
addr+=3; break;

#define PRINTOP412(op,str) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " + \
IntToHex(readmem(addr+1),2)+" "+IntToHex(readmem(addr+2),2)+\
" "+IntToHex(readmem(addr+3),2)+"  "+str+\
IntToHex(readmem(addr+3),2)+IntToHex(readmem(addr+2),2);\
addr+=4; break;

#define PRINTOP211(op,str) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " + \
IntToHex(readmem(addr+1),2)+"        "+str+\
IntToHex(readmem(addr+1),2);\
addr+=2; break;

#define PRINTOP2JR(op,str) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " + \
IntToHex(readmem(addr+1),2)+"        "+str+\
IntToHex(addr+2+(signed char)readmem(addr+1),4);\
addr+=2; break;

#define PRINTOP322(op,str,str2) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " + \
IntToHex(readmem(addr+1),2)+" "+IntToHex(readmem(addr+2),2)+"     "+str+\
IntToHex(readmem(addr+2),2)+IntToHex(readmem(addr+1),2)+str2;\
addr+=3; break;

#define PRINTOP422(op,str,str2) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " + \
IntToHex(readmem(addr+1),2)+" "+IntToHex(readmem(addr+2),2)+\
" "+IntToHex(readmem(addr+3),2)+"  "+str+\
IntToHex(readmem(addr+3),2)+IntToHex(readmem(addr+2),2)+str2;\
addr+=4; break;

#define PRINTOP221(op,str,str2) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" " + \
IntToHex(readmem(addr+1),2)+"        "+str+\
IntToHex(readmem(addr+1),2)+str2;\
addr+=2; break;

#define PRINTOP321(op,str,str2) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" "+\
IntToHex(readmem(addr+1),2)+" "+ \
IntToHex(readmem(addr+2),2)+"     "+str+\
IntToHex(readmem(addr+2),2)+str2;\
addr+=3; break;

#define PRINTOP421(op,str,str2) \
case op : output=IntToHex(addr,4)+"  "+IntToHex(readmem(addr),2)+" "+\
IntToHex(readmem(addr+1),2)+" "+ \
IntToHex(readmem(addr+2),2)+" "+ \
IntToHex(readmem(addr+3),2)+"  "+str+\
IntToHex(readmem(addr+2),2)+str2+IntToHex(readmem(addr+3),2);\
addr+=4; break;

//---------------------------------------------------------------------------
void TFudebug::save_regs (void) {
  sregaf=regaf;
  sregbc=regbc;
  sregde=regde;
  sreghl=reghl;
  sregpc=regpc;
  sregsp=regsp;
  sregix=regix;
  sregiy=regiy;
}

//---------------------------------------------------------------------------
void TFudebug::draw_fudebug (void) {
  unsigned char opcode;
  unsigned short addr;
  AnsiString output;
  int i;

  D0_value->Caption=AnsiString("D0= ")+IntToHex(portD0,2);
  D1_value->Caption=AnsiString("D1= ")+IntToHex(portD1,2);
  D2_value->Caption=AnsiString("D2= ")+IntToHex(portD2,2);
  D3_value->Caption=AnsiString("D3= ")+IntToHex(portD3,2);
  D4_value->Caption=AnsiString("D4= ")+IntToHex(portD4,2);

  switch (current_command) {
    case 0x0:
      label_current_command->Caption="Restore";
      break;
    case 0x1:
      label_current_command->Caption="Seek";
      break;
    case 0x8:
      label_current_command->Caption="Read Sector";
      break;
    case 0xD:
      label_current_command->Caption="Force Interrupt";
      break;
    default:
      label_current_command->Caption="Not Implemented";
      break;
  }

  label_regaf->Caption=IntToHex(regaf,4);
  label_regbc->Caption=IntToHex(regbc,4);
  label_regde->Caption=IntToHex(regde,4);
  label_reghl->Caption=IntToHex(reghl,4);
  label_regix->Caption=IntToHex(regix,4);
  label_regiy->Caption=IntToHex(regiy,4);
  label_regpc->Caption=IntToHex(regpc,4);
  label_regsp->Caption=IntToHex(regsp,4);

  if (iff1)
    label_di->Caption="EI";
  else
    label_di->Caption="DI";

  addr=disasm_addr;

  for (i=0; i<12; i++) {
    if (i==1)
      breakpointF8=addr;

    opcode=readmem(addr);
    switch (opcode) {

PRINTOP100      (0x00,"NOP")
PRINTOP312      (0x01,"LD BC,")
PRINTOP100      (0x02,"LD (BC),A")
PRINTOP100      (0x03,"INC BC")
PRINTOP100      (0x04,"INC B")
PRINTOP100      (0x05,"DEC B")
PRINTOP211      (0x06,"LD B,")
PRINTOP100      (0x07,"RLCA")
PRINTOP100      (0x08,"EX AF,AF'")
PRINTOP100      (0x09,"ADD HL,BC")
PRINTOP100      (0x0A,"LD A,(BC)")
PRINTOP100      (0x0B,"DEC BC")
PRINTOP100      (0x0C,"INC C")
PRINTOP100      (0x0D,"DEC C")
PRINTOP211      (0x0E,"LD C,")
PRINTOP100      (0x0F,"RRCA")
PRINTOP2JR      (0x10,"DJNZ ")
PRINTOP312      (0x11,"LD DE,")
PRINTOP100      (0x12,"LD (DE),A")
PRINTOP100      (0x13,"INC DE")
PRINTOP100      (0x14,"INC D")
PRINTOP100      (0x15,"DEC D")
PRINTOP211      (0x16,"LD D,")
PRINTOP100      (0x17,"RLA")
PRINTOP2JR      (0x18,"JR ")
PRINTOP100      (0x19,"ADD HL,DE")
PRINTOP100      (0x1A,"LD A,(DE)")
PRINTOP100      (0x1B,"DEC DE")
PRINTOP100      (0x1C,"INC E")
PRINTOP100      (0x1D,"DEC E")
PRINTOP211      (0x1E,"LD E,")
PRINTOP100      (0x1F,"RRA")
PRINTOP2JR      (0x20,"JR NZ,")
PRINTOP312      (0x21,"LD HL,")
PRINTOP322      (0x22,"LD (","),HL")
PRINTOP100      (0x23,"INC HL")
PRINTOP100      (0x24,"INC H")
PRINTOP100      (0x25,"DEC H")
PRINTOP211      (0x26,"LD H,")
PRINTOP100      (0x27,"DAA")
PRINTOP2JR      (0x28,"JR Z,")
PRINTOP100      (0x29,"ADD HL,HL")
PRINTOP322      (0x2A,"LD HL,(",")")
PRINTOP100      (0x2B,"DEC HL")
PRINTOP100      (0x2C,"INC L")
PRINTOP100      (0x2D,"DEC L")
PRINTOP211      (0x2E,"LD L,")
PRINTOP100      (0x2F,"CPL")
PRINTOP2JR      (0x30,"JR NC,")
PRINTOP312      (0x31,"LD SP,")
PRINTOP322      (0x32,"LD (","),A")
PRINTOP100      (0x33,"INC SP")
PRINTOP100      (0x34,"INC (HL)")
PRINTOP100      (0x35,"DEC (HL)")
PRINTOP211      (0x36,"LD (HL),")
PRINTOP100      (0x37,"SCF")
PRINTOP2JR      (0x38,"JR C,")
PRINTOP100      (0x39,"ADD HL,SP")
PRINTOP322      (0x3A,"LD A,(",")")
PRINTOP100      (0x3B,"DEC SP")
PRINTOP100      (0x3C,"INC A")
PRINTOP100      (0x3D,"DEC A")
PRINTOP211      (0x3E,"LD A,")
PRINTOP100      (0x3F,"CCF")
PRINTOP100      (0x40,"LD B,B")
PRINTOP100      (0x41,"LD B,C")
PRINTOP100      (0x42,"LD B,D")
PRINTOP100      (0x43,"LD B,E")
PRINTOP100      (0x44,"LD B,H")
PRINTOP100      (0x45,"LD B,L")
PRINTOP100      (0x46,"LD B,(HL)")
PRINTOP100      (0x47,"LD B,A")
PRINTOP100      (0x48,"LD C,B")
PRINTOP100      (0x49,"LD C,C")
PRINTOP100      (0x4A,"LD C,D")
PRINTOP100      (0x4B,"LD C,E")
PRINTOP100      (0x4C,"LD C,H")
PRINTOP100      (0x4D,"LD C,L")
PRINTOP100      (0x4E,"LD C,(HL)")
PRINTOP100      (0x4F,"LD C,A")
PRINTOP100      (0x50,"LD D,B")
PRINTOP100      (0x51,"LD D,C")
PRINTOP100      (0x52,"LD D,D")
PRINTOP100      (0x53,"LD D,E")
PRINTOP100      (0x54,"LD D,H")
PRINTOP100      (0x55,"LD D,L")
PRINTOP100      (0x56,"LD D,(HL)")
PRINTOP100      (0x57,"LD D,A")
PRINTOP100      (0x58,"LD E,B")
PRINTOP100      (0x59,"LD E,C")
PRINTOP100      (0x5A,"LD E,D")
PRINTOP100      (0x5B,"LD E,E")
PRINTOP100      (0x5C,"LD E,H")
PRINTOP100      (0x5D,"LD E,L")
PRINTOP100      (0x5E,"LD E,(HL)")
PRINTOP100      (0x5F,"LD E,A")
PRINTOP100      (0x60,"LD H,B")
PRINTOP100      (0x61,"LD H,C")
PRINTOP100      (0x62,"LD H,D")
PRINTOP100      (0x63,"LD H,E")
PRINTOP100      (0x64,"LD H,H")
PRINTOP100      (0x65,"LD H,L")
PRINTOP100      (0x66,"LD H,(HL)")
PRINTOP100      (0x67,"LD H,A")
PRINTOP100      (0x68,"LD L,B")
PRINTOP100      (0x69,"LD L,C")
PRINTOP100      (0x6A,"LD L,D")
PRINTOP100      (0x6B,"LD L,E")
PRINTOP100      (0x6C,"LD L,H")
PRINTOP100      (0x6D,"LD L,L")
PRINTOP100      (0x6E,"LD L,(HL)")
PRINTOP100      (0x6F,"LD L,A")
PRINTOP100      (0x70,"LD (HL),B")
PRINTOP100      (0x71,"LD (HL),C")
PRINTOP100      (0x72,"LD (HL),D")
PRINTOP100      (0x73,"LD (HL),E")
PRINTOP100      (0x74,"LD (HL),H")
PRINTOP100      (0x75,"LD (HL),L")
PRINTOP100      (0x76,"HALT")
PRINTOP100      (0x77,"LD (HL),A")
PRINTOP100      (0x78,"LD A,B")
PRINTOP100      (0x79,"LD A,C")
PRINTOP100      (0x7A,"LD A,D")
PRINTOP100      (0x7B,"LD A,E")
PRINTOP100      (0x7C,"LD A,H")
PRINTOP100      (0x7D,"LD A,L")
PRINTOP100      (0x7E,"LD A,(HL)")
PRINTOP100      (0x7F,"LD A,A")
PRINTOP100      (0x80,"ADD A,B")
PRINTOP100      (0x81,"ADD A,C")
PRINTOP100      (0x82,"ADD A,D")
PRINTOP100      (0x83,"ADD A,E")
PRINTOP100      (0x84,"ADD A,H")
PRINTOP100      (0x85,"ADD A,L")
PRINTOP100      (0x86,"ADD A,(HL)")
PRINTOP100      (0x87,"ADD A,A")
PRINTOP100      (0x88,"ADC A,B")
PRINTOP100      (0x89,"ADC A,C")
PRINTOP100      (0x8A,"ADC A,D")
PRINTOP100      (0x8B,"ADC A,E")
PRINTOP100      (0x8C,"ADC A,H")
PRINTOP100      (0x8D,"ADC A,L")
PRINTOP100      (0x8E,"ADC A,(HL)")
PRINTOP100      (0x8F,"ADC A,A")
PRINTOP100      (0x90,"SUB B")
PRINTOP100      (0x91,"SUB C")
PRINTOP100      (0x92,"SUB D")
PRINTOP100      (0x93,"SUB E")
PRINTOP100      (0x94,"SUB H")
PRINTOP100      (0x95,"SUB L")
PRINTOP100      (0x96,"SUB (HL)")
PRINTOP100      (0x97,"SUB A")
PRINTOP100      (0x98,"SBC A,B")
PRINTOP100      (0x99,"SBC A,C")
PRINTOP100      (0x9A,"SBC A,D")
PRINTOP100      (0x9B,"SBC A,E")
PRINTOP100      (0x9C,"SBC A,H")
PRINTOP100      (0x9D,"SBC A,L")
PRINTOP100      (0x9E,"SBC A,(HL)")
PRINTOP100      (0x9F,"SBC A,A")
PRINTOP100      (0xA0,"AND B")
PRINTOP100      (0xA1,"AND C")
PRINTOP100      (0xA2,"AND D")
PRINTOP100      (0xA3,"AND E")
PRINTOP100      (0xA4,"AND H")
PRINTOP100      (0xA5,"AND L")
PRINTOP100      (0xA6,"AND (HL)")
PRINTOP100      (0xA7,"AND A")
PRINTOP100      (0xA8,"XOR B")
PRINTOP100      (0xA9,"XOR C")
PRINTOP100      (0xAA,"XOR D")
PRINTOP100      (0xAB,"XOR E")
PRINTOP100      (0xAC,"XOR H")
PRINTOP100      (0xAD,"XOR L")
PRINTOP100      (0xAE,"XOR (HL)")
PRINTOP100      (0xAF,"XOR A")
PRINTOP100      (0xB0,"OR B")
PRINTOP100      (0xB1,"OR C")
PRINTOP100      (0xB2,"OR D")
PRINTOP100      (0xB3,"OR E")
PRINTOP100      (0xB4,"OR H")
PRINTOP100      (0xB5,"OR L")
PRINTOP100      (0xB6,"OR (HL)")
PRINTOP100      (0xB7,"OR A")
PRINTOP100      (0xB8,"CP B")
PRINTOP100      (0xB9,"CP C")
PRINTOP100      (0xBA,"CP D")
PRINTOP100      (0xBB,"CP E")
PRINTOP100      (0xBC,"CP H")
PRINTOP100      (0xBD,"CP L")
PRINTOP100      (0xBE,"CP (HL)")
PRINTOP100      (0xBF,"CP A")
PRINTOP100      (0xC0,"RET NZ")
PRINTOP100      (0xC1,"POP BC")
PRINTOP312      (0xC2,"JP NZ,")
PRINTOP312      (0xC3,"JP ")
PRINTOP312      (0xC4,"CALL NZ,")
PRINTOP100      (0xC5,"PUSH BC")
PRINTOP211      (0xC6,"ADD A,")
PRINTOP100      (0xC7,"RST 0")
PRINTOP100      (0xC8,"RET Z")
PRINTOP100      (0xC9,"RET")
PRINTOP312      (0xCA,"JP Z,")
PRINTOP312      (0xCC,"CALL Z,")
PRINTOP312      (0xCD,"CALL ")
PRINTOP211      (0xCE,"ADC A,")
PRINTOP100      (0xCF,"RST 08")
PRINTOP100      (0xD0,"RET NC")
PRINTOP100      (0xD1,"POP DE")
PRINTOP312      (0xD2,"JP NC,")
PRINTOP221      (0xD3,"OUT (","),A")
PRINTOP312      (0xD4,"CALL NC,")
PRINTOP100      (0xD5,"PUSH DE")
PRINTOP211      (0xD6,"SUB ")
PRINTOP100      (0xD7,"RST 10")
PRINTOP100      (0xD8,"RET C")
PRINTOP100      (0xD9,"EXX")
PRINTOP312      (0xDA,"JP C,")
PRINTOP221      (0xDB,"IN A,(",")")
PRINTOP312      (0xDC,"CALL C,")
PRINTOP211      (0xDE,"SBC A,")
PRINTOP100      (0xDF,"RST 18")
PRINTOP100      (0xE0,"RET PO")
PRINTOP100      (0xE1,"POP HL")
PRINTOP312      (0xE2,"JP PO,")
PRINTOP100      (0xE3,"EX (SP),HL")
PRINTOP312      (0xE4,"CALL PO,")
PRINTOP100      (0xE5,"PUSH HL")
PRINTOP211      (0xE6,"AND ")
PRINTOP100      (0xE7,"RST 20")
PRINTOP100      (0xE8,"RET PE")
PRINTOP100      (0xE9,"JP (HL)")
PRINTOP312      (0xEA,"JP PO,")
PRINTOP100      (0xEB,"EX DE,HL")
PRINTOP312      (0xEC,"CALL PE,")
PRINTOP211      (0xEE,"XOR ")
PRINTOP100      (0xEF,"RST 28")
PRINTOP100      (0xF0,"RET P")
PRINTOP100      (0xF1,"POP AF")
PRINTOP312      (0xF2,"JP P,")
PRINTOP100      (0xF3,"DI")
PRINTOP312      (0xF4,"CALL P,")
PRINTOP100      (0xF5,"PUSH AF")
PRINTOP211      (0xF6,"OR ")
PRINTOP100      (0xF7,"RST 30")
PRINTOP100      (0xF8,"RET M")
PRINTOP100      (0xF9,"LD SP,HL")
PRINTOP312      (0xFA,"JP M,")
PRINTOP100      (0xFB,"EI")
PRINTOP312      (0xFC,"CALL M,")
PRINTOP211      (0xFE,"CP ")
PRINTOP100      (0xFF,"RST 38")
case 0xCB:
                switch (readmem(addr+1)) {
PRINTOP200     (0x00,"RLC B")
PRINTOP200     (0x01,"RLC C")
PRINTOP200     (0x02,"RLC D")
PRINTOP200     (0x03,"RLC E")
PRINTOP200     (0x04,"RLC H")
PRINTOP200     (0x05,"RLC L")
PRINTOP200     (0x06,"RLC (HL)")
PRINTOP200     (0x07,"RLC A")
PRINTOP200     (0x08,"RRC B")
PRINTOP200     (0x09,"RRC C")
PRINTOP200     (0x0A,"RRC D")
PRINTOP200     (0x0B,"RRC E")
PRINTOP200     (0x0C,"RRC H")
PRINTOP200     (0x0D,"RRC L")
PRINTOP200     (0x0E,"RRC (HL)")
PRINTOP200     (0x0F,"RRC A")
PRINTOP200     (0x10,"RL B")
PRINTOP200     (0x11,"RL C")
PRINTOP200     (0x12,"RL D")
PRINTOP200     (0x13,"RL E")
PRINTOP200     (0x14,"RL H")
PRINTOP200     (0x15,"RL L")
PRINTOP200     (0x16,"RL (HL)")
PRINTOP200     (0x17,"RL A")
PRINTOP200     (0x18,"RR B")
PRINTOP200     (0x19,"RR C")
PRINTOP200     (0x1A,"RR D")
PRINTOP200     (0x1B,"RR E")
PRINTOP200     (0x1C,"RR H")
PRINTOP200     (0x1D,"RR L")
PRINTOP200     (0x1E,"RR (HL)")
PRINTOP200     (0x1F,"RR A")
PRINTOP200     (0x20,"SLA B")
PRINTOP200     (0x21,"SLA C")
PRINTOP200     (0x22,"SLA D")
PRINTOP200     (0x23,"SLA E")
PRINTOP200     (0x24,"SLA H")
PRINTOP200     (0x25,"SLA L")
PRINTOP200     (0x26,"SLA (HL)")
PRINTOP200     (0x27,"SLA A")
PRINTOP200     (0x28,"SRA B")
PRINTOP200     (0x29,"SRA C")
PRINTOP200     (0x2A,"SRA D")
PRINTOP200     (0x2B,"SRA E")
PRINTOP200     (0x2C,"SRA H")
PRINTOP200     (0x2D,"SRA L")
PRINTOP200     (0x2E,"SRA (HL)")
PRINTOP200     (0x2F,"SRA A")
PRINTOP200     (0x30,"SLL B")
PRINTOP200     (0x31,"SLL C")
PRINTOP200     (0x32,"SLL D")
PRINTOP200     (0x33,"SLL E")
PRINTOP200     (0x34,"SLL H")
PRINTOP200     (0x35,"SLL L")
PRINTOP200     (0x36,"SLL (HL)")
PRINTOP200     (0x37,"SLL A")
PRINTOP200     (0x38,"SRL B")
PRINTOP200     (0x39,"SRL C")
PRINTOP200     (0x3A,"SRL D")
PRINTOP200     (0x3B,"SRL E")
PRINTOP200     (0x3C,"SRL H")
PRINTOP200     (0x3D,"SRL L")
PRINTOP200     (0x3E,"SRL (HL)")
PRINTOP200     (0x3F,"SRL A")
PRINTOP200     (0x40,"BIT 0,B")
PRINTOP200     (0x41,"BIT 0,C")
PRINTOP200     (0x42,"BIT 0,D")
PRINTOP200     (0x43,"BIT 0,E")
PRINTOP200     (0x44,"BIT 0,H")
PRINTOP200     (0x45,"BIT 0,L")
PRINTOP200     (0x46,"BIT 0,(HL)")
PRINTOP200     (0x47,"BIT 0,A")
PRINTOP200     (0x48,"BIT 1,B")
PRINTOP200     (0x49,"BIT 1,C")
PRINTOP200     (0x4A,"BIT 1,D")
PRINTOP200     (0x4B,"BIT 1,E")
PRINTOP200     (0x4C,"BIT 1,H")
PRINTOP200     (0x4D,"BIT 1,L")
PRINTOP200     (0x4E,"BIT 1,(HL)")
PRINTOP200     (0x4F,"BIT 1,A")
PRINTOP200     (0x50,"BIT 2,B")
PRINTOP200     (0x51,"BIT 2,C")
PRINTOP200     (0x52,"BIT 2,D")
PRINTOP200     (0x53,"BIT 2,E")
PRINTOP200     (0x54,"BIT 2,H")
PRINTOP200     (0x55,"BIT 2,L")
PRINTOP200     (0x56,"BIT 2,(HL)")
PRINTOP200     (0x57,"BIT 2,A")
PRINTOP200     (0x58,"BIT 3,B")
PRINTOP200     (0x59,"BIT 3,C")
PRINTOP200     (0x5A,"BIT 3,D")
PRINTOP200     (0x5B,"BIT 3,E")
PRINTOP200     (0x5C,"BIT 3,H")
PRINTOP200     (0x5D,"BIT 3,L")
PRINTOP200     (0x5E,"BIT 3,(HL)")
PRINTOP200     (0x5F,"BIT 3,A")
PRINTOP200     (0x60,"BIT 4,B")
PRINTOP200     (0x61,"BIT 4,C")
PRINTOP200     (0x62,"BIT 4,D")
PRINTOP200     (0x63,"BIT 4,E")
PRINTOP200     (0x64,"BIT 4,H")
PRINTOP200     (0x65,"BIT 4,L")
PRINTOP200     (0x66,"BIT 4,(HL)")
PRINTOP200     (0x67,"BIT 4,A")
PRINTOP200     (0x68,"BIT 5,B")
PRINTOP200     (0x69,"BIT 5,C")
PRINTOP200     (0x6A,"BIT 5,D")
PRINTOP200     (0x6B,"BIT 5,E")
PRINTOP200     (0x6C,"BIT 5,H")
PRINTOP200     (0x6D,"BIT 5,L")
PRINTOP200     (0x6E,"BIT 5,(HL)")
PRINTOP200     (0x6F,"BIT 5,A")
PRINTOP200     (0x70,"BIT 6,B")
PRINTOP200     (0x71,"BIT 6,C")
PRINTOP200     (0x72,"BIT 6,D")
PRINTOP200     (0x73,"BIT 6,E")
PRINTOP200     (0x74,"BIT 6,H")
PRINTOP200     (0x75,"BIT 6,L")
PRINTOP200     (0x76,"BIT 6,(HL)")
PRINTOP200     (0x77,"BIT 6,A")
PRINTOP200     (0x78,"BIT 7,B")
PRINTOP200     (0x79,"BIT 7,C")
PRINTOP200     (0x7A,"BIT 7,D")
PRINTOP200     (0x7B,"BIT 7,E")
PRINTOP200     (0x7C,"BIT 7,H")
PRINTOP200     (0x7D,"BIT 7,L")
PRINTOP200     (0x7E,"BIT 7,(HL)")
PRINTOP200     (0x7F,"BIT 7,A")
PRINTOP200     (0x80,"RES 0,B")
PRINTOP200     (0x81,"RES 0,C")
PRINTOP200     (0x82,"RES 0,D")
PRINTOP200     (0x83,"RES 0,E")
PRINTOP200     (0x84,"RES 0,H")
PRINTOP200     (0x85,"RES 0,L")
PRINTOP200     (0x86,"RES 0,(HL)")
PRINTOP200     (0x87,"RES 0,A")
PRINTOP200     (0x88,"RES 1,B")
PRINTOP200     (0x89,"RES 1,C")
PRINTOP200     (0x8A,"RES 1,D")
PRINTOP200     (0x8B,"RES 1,E")
PRINTOP200     (0x8C,"RES 1,H")
PRINTOP200     (0x8D,"RES 1,L")
PRINTOP200     (0x8E,"RES 1,(HL)")
PRINTOP200     (0x8F,"RES 1,A")
PRINTOP200     (0x90,"RES 2,B")
PRINTOP200     (0x91,"RES 2,C")
PRINTOP200     (0x92,"RES 2,D")
PRINTOP200     (0x93,"RES 2,E")
PRINTOP200     (0x94,"RES 2,H")
PRINTOP200     (0x95,"RES 2,L")
PRINTOP200     (0x96,"RES 2,(HL)")
PRINTOP200     (0x97,"RES 2,A")
PRINTOP200     (0x98,"RES 3,B")
PRINTOP200     (0x99,"RES 3,C")
PRINTOP200     (0x9A,"RES 3,D")
PRINTOP200     (0x9B,"RES 3,E")
PRINTOP200     (0x9C,"RES 3,H")
PRINTOP200     (0x9D,"RES 3,L")
PRINTOP200     (0x9E,"RES 3,(HL)")
PRINTOP200     (0x9F,"RES 3,A")
PRINTOP200     (0xA0,"RES 4,B")
PRINTOP200     (0xA1,"RES 4,C")
PRINTOP200     (0xA2,"RES 4,D")
PRINTOP200     (0xA3,"RES 4,E")
PRINTOP200     (0xA4,"RES 4,H")
PRINTOP200     (0xA5,"RES 4,L")
PRINTOP200     (0xA6,"RES 4,(HL)")
PRINTOP200     (0xA7,"RES 4,A")
PRINTOP200     (0xA8,"RES 5,B")
PRINTOP200     (0xA9,"RES 5,C")
PRINTOP200     (0xAA,"RES 5,D")
PRINTOP200     (0xAB,"RES 5,E")
PRINTOP200     (0xAC,"RES 5,H")
PRINTOP200     (0xAD,"RES 5,L")
PRINTOP200     (0xAE,"RES 5,(HL)")
PRINTOP200     (0xAF,"RES 5,A")
PRINTOP200     (0xB0,"RES 6,B")
PRINTOP200     (0xB1,"RES 6,C")
PRINTOP200     (0xB2,"RES 6,D")
PRINTOP200     (0xB3,"RES 6,E")
PRINTOP200     (0xB4,"RES 6,H")
PRINTOP200     (0xB5,"RES 6,L")
PRINTOP200     (0xB6,"RES 6,(HL)")
PRINTOP200     (0xB7,"RES 6,A")
PRINTOP200     (0xB8,"RES 7,B")
PRINTOP200     (0xB9,"RES 7,C")
PRINTOP200     (0xBA,"RES 7,D")
PRINTOP200     (0xBB,"RES 7,E")
PRINTOP200     (0xBC,"RES 7,H")
PRINTOP200     (0xBD,"RES 7,L")
PRINTOP200     (0xBE,"RES 7,(HL)")
PRINTOP200     (0xBF,"RES 7,A")
PRINTOP200     (0xC0,"SET 0,B")
PRINTOP200     (0xC1,"SET 0,C")
PRINTOP200     (0xC2,"SET 0,D")
PRINTOP200     (0xC3,"SET 0,E")
PRINTOP200     (0xC4,"SET 0,H")
PRINTOP200     (0xC5,"SET 0,L")
PRINTOP200     (0xC6,"SET 0,(HL)")
PRINTOP200     (0xC7,"SET 0,A")
PRINTOP200     (0xC8,"SET 1,B")
PRINTOP200     (0xC9,"SET 1,C")
PRINTOP200     (0xCA,"SET 1,D")
PRINTOP200     (0xCB,"SET 1,E")
PRINTOP200     (0xCC,"SET 1,H")
PRINTOP200     (0xCD,"SET 1,L")
PRINTOP200     (0xCE,"SET 1,(HL)")
PRINTOP200     (0xCF,"SET 1,A")
PRINTOP200     (0xD0,"SET 2,B")
PRINTOP200     (0xD1,"SET 2,C")
PRINTOP200     (0xD2,"SET 2,D")
PRINTOP200     (0xD3,"SET 2,E")
PRINTOP200     (0xD4,"SET 2,H")
PRINTOP200     (0xD5,"SET 2,L")
PRINTOP200     (0xD6,"SET 2,(HL)")
PRINTOP200     (0xD7,"SET 2,A")
PRINTOP200     (0xD8,"SET 3,B")
PRINTOP200     (0xD9,"SET 3,C")
PRINTOP200     (0xDA,"SET 3,D")
PRINTOP200     (0xDB,"SET 3,E")
PRINTOP200     (0xDC,"SET 3,H")
PRINTOP200     (0xDD,"SET 3,L")
PRINTOP200     (0xDE,"SET 3,(HL)")
PRINTOP200     (0xDF,"SET 3,A")
PRINTOP200     (0xE0,"SET 4,B")
PRINTOP200     (0xE1,"SET 4,C")
PRINTOP200     (0xE2,"SET 4,D")
PRINTOP200     (0xE3,"SET 4,E")
PRINTOP200     (0xE4,"SET 4,H")
PRINTOP200     (0xE5,"SET 4,L")
PRINTOP200     (0xE6,"SET 4,(HL)")
PRINTOP200     (0xE7,"SET 4,A")
PRINTOP200     (0xE8,"SET 5,B")
PRINTOP200     (0xE9,"SET 5,C")
PRINTOP200     (0xEA,"SET 5,D")
PRINTOP200     (0xEB,"SET 5,E")
PRINTOP200     (0xEC,"SET 5,H")
PRINTOP200     (0xED,"SET 5,L")
PRINTOP200     (0xEE,"SET 5,(HL)")
PRINTOP200     (0xEF,"SET 5,A")
PRINTOP200     (0xF0,"SET 6,B")
PRINTOP200     (0xF1,"SET 6,C")
PRINTOP200     (0xF2,"SET 6,D")
PRINTOP200     (0xF3,"SET 6,E")
PRINTOP200     (0xF4,"SET 6,H")
PRINTOP200     (0xF5,"SET 6,L")
PRINTOP200     (0xF6,"SET 6,(HL)")
PRINTOP200     (0xF7,"SET 6,A")
PRINTOP200     (0xF8,"SET 7,B")
PRINTOP200     (0xF9,"SET 7,C")
PRINTOP200     (0xFA,"SET 7,D")
PRINTOP200     (0xFB,"SET 7,E")
PRINTOP200     (0xFC,"SET 7,H")
PRINTOP200     (0xFD,"SET 7,L")
PRINTOP200     (0xFE,"SET 7,(HL)")
PRINTOP200     (0xFF,"SET 7,A")
default: output=AnsiString("NULL ")+AnsiString(IntToHex(opcode,2)); break;

                }
                break;
case 0xDD:
                switch (readmem(addr+1)) {

PRINTOP200      (0x09,"ADD IX,BC")
PRINTOP200      (0x19,"ADD IX,DE")
PRINTOP412      (0x21,"LD IX,")
PRINTOP422      (0x22,"LD (","),IX")
PRINTOP200      (0x23,"INC IX")
PRINTOP200      (0x24,"INC IXh")
PRINTOP200      (0x25,"DEC IXh")
PRINTOP321      (0x26,"LD IXh,","")
PRINTOP200      (0x29,"ADD IX,IX")
PRINTOP422      (0x2A,"LD IX,(",")")
PRINTOP200      (0x2B,"DEC IX")
PRINTOP200      (0x2C,"INC IXl")
PRINTOP200      (0x2D,"DEC IXl")
PRINTOP321      (0x2E,"LD IXl,","")
PRINTOP321      (0x34,"INC (IX+",")")
PRINTOP321      (0x35,"DEC (IX+",")")
PRINTOP421      (0x36,"LD (IX+","),")
PRINTOP200      (0x39,"ADD IX,SP")
PRINTOP200      (0x44,"LD B,IXh")
PRINTOP200      (0x45,"LD B,IXl")
PRINTOP321      (0x46,"LD B,(IX+",")")
PRINTOP200      (0x4C,"LD C,IXh")
PRINTOP200      (0x4D,"LD C,IXl")
PRINTOP321      (0x4E,"LD C,(IX+",")")
PRINTOP200      (0x54,"LD D,IXh")
PRINTOP200      (0x55,"LD D,IXl")
PRINTOP321      (0x56,"LD D,(IX+",")")
PRINTOP200      (0x5C,"LD E,IXh")
PRINTOP200      (0x5D,"LD E,IXl")
PRINTOP321      (0x5E,"LD E,(IX+",")")
PRINTOP200      (0x60,"LD IXh,B")
PRINTOP200      (0x61,"LD IXh,C")
PRINTOP200      (0x62,"LD IXh,D")
PRINTOP200      (0x63,"LD IXh,E")
PRINTOP200      (0x64,"LD IXh,IXh")
PRINTOP200      (0x65,"LD IXh,IXl")
PRINTOP321      (0x66,"LD H,(IX+",")")
PRINTOP200      (0x67,"LD IXh,A")
PRINTOP200      (0x68,"LD IXl,B")
PRINTOP200      (0x69,"LD IXl,C")
PRINTOP200      (0x6A,"LD IXl,D")
PRINTOP200      (0x6B,"LD IXl,E")
PRINTOP200      (0x6C,"LD IXl,IXh")
PRINTOP200      (0x6D,"LD IXl,IXl")
PRINTOP321      (0x6E,"LD L,(IX+",")")
PRINTOP200      (0x6F,"LD IXl,A")
PRINTOP321      (0x70,"LD (IX+","),B")
PRINTOP321      (0x71,"LD (IX+","),C")
PRINTOP321      (0x72,"LD (IX+","),D")
PRINTOP321      (0x73,"LD (IX+","),E")
PRINTOP321      (0x74,"LD (IX+","),H")
PRINTOP321      (0x75,"LD (IX+","),L")
PRINTOP321      (0x77,"LD (IX+","),A")
PRINTOP200      (0x7C,"LD A,IXh")
PRINTOP200      (0x7D,"LD A,IXl")
PRINTOP321      (0x7E,"LD A,(IX+",")")
PRINTOP200      (0x84,"ADD A,IXh")
PRINTOP200      (0x85,"ADD A,IXl")
PRINTOP321      (0x86,"ADD A,(IX+",")")
PRINTOP200      (0x8C,"ADC A,IXh")
PRINTOP200      (0x8D,"ADC A,IXl")
PRINTOP321      (0x8E,"ADC A,(IX+",")")
PRINTOP200      (0x94,"SUB IXh")
PRINTOP200      (0x95,"SUB IXl")
PRINTOP321      (0x96,"SUB (IX+",")")
PRINTOP200      (0x9C,"SBC A,IXh")
PRINTOP200      (0x9D,"SBC A,IXl")
PRINTOP321      (0x9E,"SBC A,(IX+",")")
PRINTOP200      (0xA4,"AND IXh")
PRINTOP200      (0xA5,"AND IXl")
PRINTOP321      (0xA6,"AND (IX+",")")
PRINTOP200      (0xAC,"XOR IXh")
PRINTOP200      (0xAD,"XOR IXl")
PRINTOP321      (0xAE,"XOR (IX+",")")
PRINTOP200      (0xB4,"OR IXh")
PRINTOP200      (0xB5,"OR IXl")
PRINTOP321      (0xB6,"OR (IX+",")")
PRINTOP200      (0xBC,"CP IXh")
PRINTOP200      (0xBD,"CP IXl")
PRINTOP321      (0xBE,"CP (IX+",")")
PRINTOP200      (0xE1,"POP IX")
PRINTOP200      (0xE3,"EX (SP),IX")
PRINTOP200      (0xE5,"PUSH IX")
PRINTOP200      (0xE9,"JP (IX)")
PRINTOP200      (0xF9,"LD SP,IX")



default: output=AnsiString("NULL ")+AnsiString(IntToHex(opcode,2)); break;
                }
                break;
case 0xFD:
                switch (readmem(addr+1)) {
PRINTOP200      (0x09,"ADD IY,BC")
PRINTOP200      (0x19,"ADD IY,DE")
PRINTOP412      (0x21,"LD IY,")
PRINTOP422      (0x22,"LD (","),IY")
PRINTOP200      (0x23,"INC IY")
PRINTOP200      (0x24,"INC IYh")
PRINTOP200      (0x25,"DEC IYh")
PRINTOP321      (0x26,"LD IYh,","")
PRINTOP200      (0x29,"ADD IY,IY")
PRINTOP422      (0x2A,"LD IY,(",")")
PRINTOP200      (0x2B,"DEC IY")
PRINTOP200      (0x2C,"INC IYl")
PRINTOP200      (0x2D,"DEC IYl")
PRINTOP321      (0x2E,"LD IYl,","")
PRINTOP321      (0x34,"INC (IY+",")")
PRINTOP321      (0x35,"DEC (IY+",")")
PRINTOP421      (0x36,"LD (IY+","),")
PRINTOP200      (0x39,"ADD IY,SP")
PRINTOP200      (0x44,"LD B,IYh")
PRINTOP200      (0x45,"LD B,IYl")
PRINTOP321      (0x46,"LD B,(IY+",")")
PRINTOP200      (0x4C,"LD C,IYh")
PRINTOP200      (0x4D,"LD C,IYl")
PRINTOP321      (0x4E,"LD C,(IY+",")")
PRINTOP200      (0x54,"LD D,IYh")
PRINTOP200      (0x55,"LD D,IYl")
PRINTOP321      (0x56,"LD D,(IY+",")")
PRINTOP200      (0x5C,"LD E,IYh")
PRINTOP200      (0x5D,"LD E,IYl")
PRINTOP321      (0x5E,"LD E,(IY+",")")
PRINTOP200      (0x60,"LD IYh,B")
PRINTOP200      (0x61,"LD IYh,C")
PRINTOP200      (0x62,"LD IYh,D")
PRINTOP200      (0x63,"LD IYh,E")
PRINTOP200      (0x64,"LD IYh,IYh")
PRINTOP200      (0x65,"LD IYh,IYl")
PRINTOP321      (0x66,"LD H,(IY+",")")
PRINTOP200      (0x67,"LD IYh,A")
PRINTOP200      (0x68,"LD IYl,B")
PRINTOP200      (0x69,"LD IYl,C")
PRINTOP200      (0x6A,"LD IYl,D")
PRINTOP200      (0x6B,"LD IYl,E")
PRINTOP200      (0x6C,"LD IYl,IYh")
PRINTOP200      (0x6D,"LD IYl,IYl")
PRINTOP321      (0x6E,"LD L,(IY+",")")
PRINTOP200      (0x6F,"LD IYl,A")
PRINTOP321      (0x70,"LD (IY+","),B")
PRINTOP321      (0x71,"LD (IY+","),C")
PRINTOP321      (0x72,"LD (IY+","),D")
PRINTOP321      (0x73,"LD (IY+","),E")
PRINTOP321      (0x74,"LD (IY+","),H")
PRINTOP321      (0x75,"LD (IY+","),L")
PRINTOP321      (0x77,"LD (IY+","),A")
PRINTOP200      (0x7C,"LD A,IYh")
PRINTOP200      (0x7D,"LD A,IYl")
PRINTOP321      (0x7E,"LD A,(IY+",")")
PRINTOP200      (0x84,"ADD A,IYh")
PRINTOP200      (0x85,"ADD A,IYl")
PRINTOP321      (0x86,"ADD A,(IY+",")")
PRINTOP200      (0x8C,"ADC A,IYh")
PRINTOP200      (0x8D,"ADC A,IYl")
PRINTOP321      (0x8E,"ADC A,(IY+",")")
PRINTOP200      (0x94,"SUB IYh")
PRINTOP200      (0x95,"SUB IYl")
PRINTOP321      (0x96,"SUB (IY+",")")
PRINTOP200      (0x9C,"SBC A,IYh")
PRINTOP200      (0x9D,"SBC A,IYl")
PRINTOP321      (0x9E,"SBC A,(IY+",")")
PRINTOP200      (0xA4,"AND IYh")
PRINTOP200      (0xA5,"AND IYl")
PRINTOP321      (0xA6,"AND (IY+",")")
PRINTOP200      (0xAC,"XOR IYh")
PRINTOP200      (0xAD,"XOR IYl")
PRINTOP321      (0xAE,"XOR (IY+",")")
PRINTOP200      (0xB4,"OR IYh")
PRINTOP200      (0xB5,"OR IYl")
PRINTOP321      (0xB6,"OR (IY+",")")
PRINTOP200      (0xBC,"CP IYh")
PRINTOP200      (0xBD,"CP IYl")
PRINTOP321      (0xBE,"CP (IY+",")")
PRINTOP200      (0xE1,"POP IY")
PRINTOP200      (0xE3,"EX (SP),IY")
PRINTOP200      (0xE5,"PUSH IY")
PRINTOP200      (0xE9,"JP (IY)")
PRINTOP200      (0xF9,"LD SP,IY")
default: output=AnsiString("NULL ")+AnsiString(IntToHex(opcode,2)); break;

                }
                break;
case 0xED:
                switch (readmem(addr+1)) {
PRINTOP200      (0x40,"IN B,(C)")
PRINTOP200      (0x41,"OUT (C),B")
PRINTOP200      (0x42,"SBC HL,BC")
PRINTOP422      (0x43,"LD (","),BC")
PRINTOP200      (0x44,"NEG")
PRINTOP200      (0x45,"RETN")
PRINTOP200      (0x46,"IM 0")
PRINTOP200      (0x47,"LD I,A")
PRINTOP200      (0x48,"IN C,(C)")
PRINTOP200      (0x49,"OUT (C),C")
PRINTOP200      (0x4A,"ADC HL,BC")
PRINTOP422      (0x4B,"LD BC,(",")")
PRINTOP200      (0x4C,"NEG")
PRINTOP200      (0x4D,"RETI")
PRINTOP200      (0x4E,"IM 0/1")
PRINTOP200      (0x4F,"LD R,A")
PRINTOP200      (0x50,"IN D,(C)")
PRINTOP200      (0x51,"OUT (C),D")
PRINTOP200      (0x52,"SBC HL,DE")
PRINTOP422      (0x53,"LD (","),DE")
PRINTOP200      (0x54,"NEG")
PRINTOP200      (0x55,"RETN")
PRINTOP200      (0x56,"IM 1")
PRINTOP200      (0x57,"LD A,I")
PRINTOP200      (0x58,"IN E,(C)")
PRINTOP200      (0x59,"OUT (C),E")
PRINTOP200      (0x5A,"ADC HL,DE")
PRINTOP422      (0x5B,"LD DE,(",")")
PRINTOP200      (0x5C,"NEG")
PRINTOP200      (0x5D,"RETN")
PRINTOP200      (0x5E,"IM 2")
PRINTOP200      (0x5F,"LD A,R")
PRINTOP200      (0x60,"IN H,(C)")
PRINTOP200      (0x61,"OUT (C),H")
PRINTOP200      (0x62,"SBC HL,HL")
PRINTOP422      (0x63,"LD (","),HL")
PRINTOP200      (0x64,"NEG")
PRINTOP200      (0x65,"RETN")
PRINTOP200      (0x66,"IM 0")
PRINTOP200      (0x67,"RRD")
PRINTOP200      (0x68,"IN L,(C)")
PRINTOP200      (0x69,"OUT (C),L")
PRINTOP200      (0x6A,"ADC HL,HL")
PRINTOP422      (0x6B,"LD HL,(",")")
PRINTOP200      (0x6C,"NEG")
PRINTOP200      (0x6D,"RETN")
PRINTOP200      (0x6E,"IM 0/1")
PRINTOP200      (0x6F,"RLD")
PRINTOP200      (0x70,"IN (C)")
PRINTOP200      (0x71,"OUT (C),0")
PRINTOP200      (0x72,"SBC HL,SP")
PRINTOP422      (0x73,"LD (","),SP")
PRINTOP200      (0x74,"NEG")
PRINTOP200      (0x75,"RETN")
PRINTOP200      (0x76,"IM 1")
PRINTOP200      (0x78,"IN A,(C)")
PRINTOP200      (0x79,"OUT (C),A")
PRINTOP200      (0x7A,"ADC HL,SP")
PRINTOP422      (0x7B,"LD SP,(",")")
PRINTOP200      (0x7C,"NEG")
PRINTOP200      (0x7D,"RETN")
PRINTOP200      (0x7E,"IM 2")
PRINTOP200      (0xA0,"LDI")
PRINTOP200      (0xA1,"CPI")
PRINTOP200      (0xA2,"INI")
PRINTOP200      (0xA3,"OUTI")
PRINTOP200      (0xA8,"LDD")
PRINTOP200      (0xA9,"CPI")
PRINTOP200      (0xAA,"IND")
PRINTOP200      (0xAB,"OUTD")
PRINTOP200      (0xB0,"LDIR")
PRINTOP200      (0xB1,"CPIR")
PRINTOP200      (0xB2,"INIR")
PRINTOP200      (0xB3,"OTIR")
PRINTOP200      (0xB8,"LDDR")
PRINTOP200      (0xB9,"CPDR")
PRINTOP200      (0xBA,"INDR")
PRINTOP200      (0xBB,"OTDR")
PRINTOP200      (0xFF,"PATCH")
default: output=AnsiString("NULL ")+AnsiString(IntToHex(opcode,2)); break;

                }
                break;
default: output=AnsiString("NULL ")+AnsiString(IntToHex(opcode,2)); break;
    }
    switch (i) {
      case 0: disasm0->Caption=output; break;
      case 1: disasm1->Caption=output; break;
      case 2: disasm2->Caption=output; break;
      case 3: disasm3->Caption=output; break;
      case 4: disasm4->Caption=output; break;
      case 5: disasm5->Caption=output; break;
      case 6: disasm6->Caption=output; break;
      case 7: disasm7->Caption=output; break;
      case 8: disasm8->Caption=output; break;
      case 9: disasm9->Caption=output; break;
      case 10: disasm10->Caption=output; break;
      case 11: disasm11->Caption=output; break;
    }
  }
        CHECK_REG (regaf);
        CHECK_REG (regbc);
        CHECK_REG (regde);
        CHECK_REG (reghl);
        CHECK_REG (regpc);
        CHECK_REG (regsp);
        CHECK_REG (regix);
        CHECK_REG (regiy);
}


extern int time_enabled;
extern volatile int running;

void __fastcall TFudebug::FormShow(TObject *Sender)
{
  int i;
  time_enabled=0;
  while (running) {}
  save_regs ();
  disasm_addr=regpc;

  sprite_list->Clear();
  for (i=0; i<32; i++)
    sprite_list->Items->Add (AnsiString("Sprite ")+i);
  sprite_list->ItemIndex=0;
  draw_spriteattr ();
  Invalidate ();
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::FormClose(TObject *Sender, TCloseAction &Action)
{
  time_enabled=1;
}
//---------------------------------------------------------------------------

void TFudebug::lock_fudebug(void)
{
  debug->Visible=false;
  time_enabled=1;
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::inputKeyDown(TObject *Sender, WORD &Key,
      TShiftState Shift)
{
  if (input->Text=="")
    switch (Key) {
      case '1':
        debug->ActivePage=CPU_tab;
        input->Modified=true;
        fast_command=1;
        break;
      case '2':
        debug->ActivePage=Memory_tab;
        input->Modified=true;
        fast_command=1;
        break;
      case '3':
        debug->ActivePage=Sprites_tab;
        input->Modified=true;
        fast_command=1;
        break;
      case '4':
        debug->ActivePage=FDC_tab;
        input->Modified=true;
        fast_command=1;
        break;
      case VK_F7:
        save_regs();
        stepZ80();
        disasm_addr=regpc;
        Invalidate();
        input->Modified=true;
        fast_command=1;
        break;
      case VK_UP:
        disasm_addr=disasm_addr>0?disasm_addr-1:disasm_addr;
        Invalidate();
        input->Modified=true;
        fast_command=1;
        break;
      case VK_DOWN:
        disasm_addr=breakpointF8;
        Invalidate();
        input->Modified=true;
        fast_command=1;
        break;
      case VK_F8:
        breakpoint=breakpointF8;
        time_enabled=1;
        input->Modified=true;
        fast_command=1;
        break;
      default:
        fast_command=0;
    }
  else if (Key==VK_RETURN) {
    char *command;

    AnsiString trimmed;
    trimmed=input->Text.Trim();
    command=new char[trimmed.Length()+1];
    strcpy (command,trimmed.c_str());
    strupr (command);
    strtok (command," ");
    if (!strcmp (command,"RESET")) {
      resetZ80();
      Invalidate();
    } else if (!strcmp (command,"B")) {
      breakpoint=strtol(strtok (NULL," "),NULL,16);
      lock_fudebug();
    } else if (!strcmp (command,"U")) {
      disasm_addr=strtol(strtok (NULL," "),NULL,16);
      Invalidate();
    } else if (!strcmp (command,"SPEED")) {
      z80speed=(int)((atof(strtok (NULL," "))*1000000)/(480*60));
    }
    input->Text="";
    input->Modified=true;
    fast_command=1;
    delete command;
  } else
    fast_command=0;
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::inputChange(TObject *Sender)
{
  if (fast_command)
    input->Text="";
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::FormPaint(TObject *Sender)
{
  draw_fudebug();
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::debugChange(TObject *Sender)
{
  int i;

  if (debug->ActivePage==Sprites_tab) {
    draw_spriteattr();
  }
}
//---------------------------------------------------------------------------

void  TFudebug::draw_spriteattr(void) {
  int i;
  int base;
  int x,y,color;
  unsigned char yy;

  base=vdpreg[5]<<7;
  for (i=0; i<32; i++)
    if (sprite_list->Selected[i]) {
      x=vram[base+i*4+1]+(vram[base+i*4+3]&128?-32:0);
      yy=(unsigned char)vram[base+i*4+0]-1;
      y=(int)(yy>208?(signed char)yy:(unsigned char)yy);
      color=vram[base+i*4+3]&0xF;
      sprite_x->Caption=AnsiString("X= ")+x;
      sprite_y->Caption=AnsiString("Y= ")+y;
      sprite_pattern->Caption=AnsiString("Pattern= ")+(vram[base+i*4+2]&0xFC);
      sprite_color->Caption=AnsiString("Color= ")+color;
      color_sample->Canvas->Brush->Color=RGB2WINDOWS(palette32[color*2]);
      color_sample->Canvas->FillRect(Rect(0,0,14,14));

      break;
    }
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::sprite_listClick(TObject *Sender)
{
  draw_spriteattr();
}
//---------------------------------------------------------------------------

void __fastcall TFudebug::sprite_listKeyPress(TObject *Sender, char &Key)
{
  draw_spriteattr();

}
//---------------------------------------------------------------------------


