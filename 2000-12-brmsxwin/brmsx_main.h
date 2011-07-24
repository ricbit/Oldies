//---------------------------------------------------------------------------
#ifndef brmsx_mainH
#define brmsx_mainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include <ComCtrls.hpp>
#include <Menus.hpp>
#include <ToolWin.hpp>
#include <ImgList.hpp>
#include <Dialogs.hpp>
#include <ddraw.h>
#include <ActnList.hpp>
#include <ActnMan.hpp>
#include <ExtActns.hpp>
#include <ActnCtrls.hpp>
#include <Buttons.hpp>
#include <AppEvnts.hpp>
//---------------------------------------------------------------------------
class Tmain_window : public TForm
{
__published:	// IDE-managed Components
        TImage *Image1;
        TStatusBar *StatusBar1;
        TMainMenu *MainMenu1;
        TMenuItem *File1;
        TMenuItem *Options1;
        TMenuItem *LoadCartridge1;
        TMenuItem *Exit1;
        TMenuItem *FuDebug1;
        TMenuItem *Help1;
        TMenuItem *About1;
        TMenuItem *Options2;
        TMenuItem *Scanlines1;
        TMenuItem *Keyboard1;
        TMenuItem *Joystick1;
        TOpenDialog *generic_load_dialog;
        TSpeedButton *SpeedButton1;
        TSpeedButton *SpeedButton2;
        TSpeedButton *SpeedButton3;
        TMenuItem *LoadDiskImage1;
        TMenuItem *MountDirectory1;
        TApplicationEvents *ApplicationEvents1;
        void __fastcall FormPaint(TObject *Sender);
        void __fastcall Exit1Click(TObject *Sender);
        void __fastcall FormDestroy(TObject *Sender);
        void __fastcall FuDebug1Click(TObject *Sender);
        void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
        void __fastcall LoadCartridge1Click(TObject *Sender);
        void __fastcall FormActivate(TObject *Sender);
        void __fastcall FormDeactivate(TObject *Sender);
        void __fastcall About1Click(TObject *Sender);
        void __fastcall Scanlines1Click(TObject *Sender);
        void __fastcall Keyboard1Click(TObject *Sender);
        void __fastcall Joystick1Click(TObject *Sender);
        void __fastcall SpeedButton1Click(TObject *Sender);
        void __fastcall SpeedButton3Click(TObject *Sender);
        void __fastcall LoadDiskImage1Click(TObject *Sender);
        void __fastcall MountDirectory1Click(TObject *Sender);
        void __fastcall ApplicationEvents1Exception(TObject *Sender,
          Exception *E);
private:	// User declarations
        void load_cartA (void);
        void load_diskA (void);
public:		// User declarations
        __fastcall Tmain_window(TComponent* Owner);
};
//---------------------------------------------------------------------------

extern PACKAGE Tmain_window *main_window;
extern volatile int time_enabled;
extern volatile int running;
extern LPDIRECTDRAWSURFACE7 blitbuffer;
extern unsigned char *vram;
extern unsigned char keyindex[],keybit[];


//---------------------------------------------------------------------------
#endif
