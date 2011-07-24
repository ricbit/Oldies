//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "about_window.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TAbout *About;
//---------------------------------------------------------------------------
__fastcall TAbout::TAbout(TComponent* Owner)
        : TForm(Owner)
{
  date_label->Caption=AnsiString("Last compiling: ")+__DATE__+" "+__TIME__;
}
//---------------------------------------------------------------------------


void __fastcall TAbout::Button1Click(TObject *Sender)
{
  Hide ();
}
//---------------------------------------------------------------------------
