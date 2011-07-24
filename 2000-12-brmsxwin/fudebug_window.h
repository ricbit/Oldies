//---------------------------------------------------------------------------
#ifndef fudebug_windowH
#define fudebug_windowH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ComCtrls.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TFudebug : public TForm
{
__published:	// IDE-managed Components
        TPageControl *debug;
        TTabSheet *CPU_tab;
        TTabSheet *Memory_tab;
        TGroupBox *GroupBox1;
        TLabel *disasm1;
        TLabel *disasm2;
        TGroupBox *GroupBox2;
        TLabel *disasm4;
        TLabel *disasm0;
        TLabel *disasm3;
        TLabel *disasm5;
        TLabel *disasm6;
        TLabel *disasm7;
        TLabel *disasm9;
        TLabel *disasm8;
        TLabel *disasm11;
        TLabel *disasm10;
        TLabel *Label13;
        TLabel *Label14;
        TLabel *Label15;
        TLabel *Label16;
        TLabel *Label17;
        TLabel *Label18;
        TLabel *Label19;
        TLabel *Label21;
        TLabel *label_regaf;
        TLabel *label_regbc;
        TLabel *label_regde;
        TLabel *label_reghl;
        TLabel *label_regix;
        TLabel *label_regiy;
        TLabel *label_regpc;
        TLabel *label_regsp;
        TEdit *input;
        TLabel *label_di;
        TTabSheet *Sprites_tab;
        TListBox *sprite_list;
        TGroupBox *GroupBox3;
        TLabel *sprite_x;
        TLabel *sprite_y;
        TLabel *sprite_pattern;
        TLabel *sprite_color;
        TImage *color_sample;
        TImage *image_mono;
        TImage *image_black;
        TImage *image_white;
        TTabSheet *FDC_tab;
        TGroupBox *GroupBox4;
        TLabel *D0_value;
        TLabel *D1_value;
        TLabel *D2_value;
        TLabel *D3_value;
        TLabel *D4_value;
        TGroupBox *GroupBox5;
        TLabel *Label1;
        TLabel *label_current_command;
        TLabel *waiting_label;
        void __fastcall FormShow(TObject *Sender);
        void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
        void __fastcall inputKeyDown(TObject *Sender, WORD &Key,
          TShiftState Shift);
        void __fastcall inputChange(TObject *Sender);
        void __fastcall FormPaint(TObject *Sender);
        void __fastcall debugChange(TObject *Sender);
        void __fastcall sprite_listClick(TObject *Sender);
        void __fastcall sprite_listKeyPress(TObject *Sender, char &Key);
private:	// User declarations
        int fast_command;
        int sregaf,sregbc,sregde,sreghl,sregsp,sregix,sregiy,sregpc;

        void save_regs (void);
        void draw_spriteattr(void);
        void lock_fudebug(void);

public:		// User declarations
        __fastcall TFudebug(TComponent* Owner);
        void draw_fudebug (void);
};
//---------------------------------------------------------------------------
extern PACKAGE TFudebug *Fudebug;
//---------------------------------------------------------------------------
#endif
