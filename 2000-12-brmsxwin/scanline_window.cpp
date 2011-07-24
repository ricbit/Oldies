//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "scanline_window.h"
#include "brmsx_engine.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TScanline *Scanline;
//---------------------------------------------------------------------------
__fastcall TScanline::TScanline(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TScanline::Button1Click(TObject *Sender)
{
  Hide ();        
}
//---------------------------------------------------------------------------
void __fastcall TScanline::intensity_sliderChange(TObject *Sender)
{
  percent->Caption=AnsiString(intensity_slider->Position*100/128)+"%";
  scanline_value=intensity_slider->Position;
  if (scanline_value==0) {
    first_black_frame=1;
    draw_black_now=0;
    dont_draw_anymore=0;
  } else {
    first_black_frame=0;
    draw_black_now=0;
    dont_draw_anymore=0;
  }
}
//---------------------------------------------------------------------------

void __fastcall TScanline::FormShow(TObject *Sender)
{
  intensity_slider->Position=scanline_value;
  bright_slider->Position=bright_value;
  enable_tvborder->Checked=tvborder_value?true:false;
  percent->Caption=AnsiString(intensity_slider->Position*100/128)+"%";
}
//---------------------------------------------------------------------------

void __fastcall TScanline::enable_tvborderClick(TObject *Sender)
{
  tvborder_value=enable_tvborder->Checked?1:0;
  if (!tvborder_value && !scanline_value) {
    first_black_frame=1;
    draw_black_now=0;
    dont_draw_anymore=0;
  }
}
//---------------------------------------------------------------------------

void __fastcall TScanline::bright_sliderChange(TObject *Sender)
{
  bright_value=bright_slider->Position;
}
//---------------------------------------------------------------------------

