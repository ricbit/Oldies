//---------------------------------------------------------------------------

#include <vcl.h>
#include <jpeg.hpp>
#pragma hdrstop

#include "joystick_window.h"
#include "joypad_jpg.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TJoystick *Joystick;
TMemoryStream *joypad_stream;
TJPEGImage *joypad_original;
//---------------------------------------------------------------------------
__fastcall TJoystick::TJoystick(TComponent* Owner)
        : TForm(Owner)
{
  joypad_stream=new TMemoryStream();
  joypad_stream->SetSize (21129);
  memcpy (joypad_stream->Memory,joypad_jpg,21129);
  joypad_original=new TJPEGImage();
  joypad_original->LoadFromStream(joypad_stream);
  joystick_image->Canvas->Draw(0,0,joypad_original);
  joystick_image->Invalidate();


}
//---------------------------------------------------------------------------
