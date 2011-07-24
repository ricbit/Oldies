//---------------------------------------------------------------------------

#include <vcl.h>
#include <stdio.h>
#include <jpeg.hpp>
#pragma hdrstop

#include <dinput.h>
#include "brmsx_main.h"
#include "keyboard_window.h"
#include "keyboard_jpg.h"
#include "keymap.h"
#include "msxrom.h"

//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TKeyboard *Keyboard;

// DirectInput
LPDIRECTINPUT dinput_interface2=NULL;
LPDIRECTINPUTDEVICE dinput_keyboard2=NULL;

typedef struct Graphics::TBitmap *LBITMAP;
Graphics::TBitmap *save_image;
TImageList *full_charset;
LBITMAP charset[256];

TMemoryStream *keyboard_stream;
TJPEGImage *keyboard_original;

int enabled=0;
unsigned char dirty[256];
unsigned char key,lastkey;
unsigned char backindex[256],backbit[256];
unsigned char extendedmap[6*8*6];

#define LOG2(x) (((x)>1)+((x)>2)+((x)>4)+((x)>8)+((x)>16)+((x)>32)+((x)>64))

//---------------------------------------------------------------------------
__fastcall TKeyboard::TKeyboard(TComponent* Owner)
        : TForm(Owner)
{
  int ret,i,j,k;
  unsigned char b;
  unsigned int *current_scanline;
  TCursor save_cursor;

  save_cursor=Screen->Cursor;
  Screen->Cursor = crHourGlass;    // Show hourglass cursor

  try{

    // Get DirectInput
    ret=DirectInputCreateEx (
          (HINSTANCE)GetWindowLong(Keyboard->Handle,GWL_HINSTANCE),
          DIRECTINPUT_VERSION,IID_IDirectInput7,
          (void**)&dinput_interface2, NULL);
    if (ret!=DI_OK) {
      Application->MessageBox
        ("Cannot create DirectInput interface","BrMSX",MB_OK);
      Application->Terminate ();
      return;
    }

    // Get keyboard
    ret=dinput_interface2->CreateDevice(GUID_SysKeyboard,&dinput_keyboard2,NULL);
    if (ret!=DI_OK) {
      Application->MessageBox
        ("Cannot create keyboard interface","BrMSX",MB_OK);
      Application->Terminate ();
      return;
    }

    // Set keyboard data format
    ret=dinput_keyboard2->SetDataFormat(&c_dfDIKeyboard);
    if (ret!=DI_OK) {
      Application->MessageBox
        ("Cannot set keyboard data format","BrMSX",MB_OK);
      Application->Terminate ();
      return;
    }

    // Set keyboard exclusive mode
    ret=dinput_keyboard2->SetCooperativeLevel(Keyboard->Handle,
          DISCL_EXCLUSIVE | DISCL_FOREGROUND );
    if (ret!=DI_OK) {
      Application->MessageBox
        ("Cannot set keyboard exclusive mode","BrMSX",MB_OK);
      Application->Terminate ();
      return;
    }

    // init main image from jpeg
    keyboard_stream=new TMemoryStream();
    keyboard_stream->SetSize (51347);
    memcpy (keyboard_stream->Memory,keyboard_jpg,51347);
    keyboard_original=new TJPEGImage();
    keyboard_original->LoadFromStream(keyboard_stream);

    // init bitmaps
    save_image=new Graphics::TBitmap();
    save_image->PixelFormat=pf32bit;
    save_image->Height=241;
    save_image->Width=617;
    save_image->Canvas->Draw(0,0,keyboard_original);

    keyboard_image->Picture->Assign (save_image);
    keyboard_image->ControlStyle = keyboard_image->ControlStyle << csOpaque;
    Keyboard->ControlStyle = Keyboard->ControlStyle << csOpaque;
    keyboard_image->Invalidate();

    for (i=0; i<256; i++) {
      charset[i]=new Graphics::TBitmap();
      charset[i]->PixelFormat=pf32bit;
      charset[i]->Height=16;
      charset[i]->Width=16;
      Application->ProcessMessages();
    }

    full_charset=new TImageList (16,16);

    full_charset->Clear();
    full_charset->Masked=false;
    for (k=0; k<256; k++) {
      for (j=0; j<16; j++) {
        b=rom[0x1BBF+k*8+j/2];
        current_scanline=(unsigned int *)(charset[k]->ScanLine[j]);
        for (i=0; i<16; i++)
          current_scanline[i]=(b&(1<<(7-i/2)))?clBlack:clWhite;
      }
      full_charset->Add(charset[k],NULL);
      Application->ProcessMessages();
    }

    box[0]=normal_box;
    box[1]=shift_box;
    box[2]=lgra_box;
    box[3]=lgrashift_box;
    box[4]=rgra_box;
    box[5]=rgrashift_box;

    for (j=0; j<6; j++) {
      box[j]->Images=full_charset;
      for (i=0; i<256; i++) {
        box[j]->ItemsEx->AddItem (IntToHex(i,2),i,i,i,-1,NULL);
        Application->ProcessMessages();
      }
    }

    // set keyboard mode
    enabled=0;

  } __finally {
    Screen->Cursor = save_cursor; // always restore the cursor
  }
}
//---------------------------------------------------------------------------
void __fastcall TKeyboard::ok_buttonClick(TObject *Sender)
{
  int i;

  for (i=0; i<256; i++) {
    keyindex[i]=backindex[i];
    keybit[i]=backbit[i];
  }

  // copy extended key information to rom
  for (i=0; i<6*8*6; i++)
    rom[0xDA5+i]=extendedmap[i];

  ModalResult=mrOk;
}
//---------------------------------------------------------------------------
void __fastcall TKeyboard::cancel_buttonClick(TObject *Sender)
{
  ModalResult=mrOk;
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::FormDestroy(TObject *Sender)
{
  Timer1->Enabled=false;
  
  if (dinput_interface2!=NULL)
    dinput_interface2->Release();
  if (dinput_keyboard2!=NULL) {
    dinput_keyboard2->Unacquire();
    dinput_keyboard2->Release();
  }

}
//---------------------------------------------------------------------------


void __fastcall TKeyboard::FormActivate(TObject *Sender)
{
  int i;

  if (dinput_keyboard2!=NULL)
    dinput_keyboard2->Acquire();

  // copy extended key information from rom
  for (i=0; i<6*8*6; i++)
    extendedmap[i]=rom[0xDA5+i];

  enabled=1;
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::Timer1Timer(TObject *Sender)
{
  unsigned char keybuf[256];
  int ret,i,bit,ii,jj;
  unsigned int *buffer,*orig;

  if (!enabled)
    return;

  ret=dinput_keyboard2->GetDeviceState(256,keybuf);
  if (ret!=DI_OK) {
    dinput_keyboard2->Acquire();
    return;
  }

  for (i=0; i<256; i++) {

    if (enabled==1) {

      if ((keybuf[i]&0x80)&&(!dirty[i])&&(backbit[i])) {
        bit=LOG2(backbit[i]);
        dirty[i]=1;
        for (jj=0; jj<241; jj++) {
          buffer=(unsigned int *)(keyboard_image->Picture->Bitmap->ScanLine[jj]);
          for (ii=0; ii<617; ii++)
            if (keymap[jj*617+ii]==((backindex[i]<<4)|bit))
              buffer[ii]=(buffer[ii]>>1)&0x7F7F7F7F;
        }
        keyboard_image->Invalidate();

      } else if (((keybuf[i]&0x80)==0)&&(dirty[i])&&(backbit[i])) {
        bit=LOG2(backbit[i]);
        dirty[i]=0;
        for (jj=0; jj<241; jj++) {
          buffer=(unsigned int *)(keyboard_image->Picture->Bitmap->ScanLine[jj]);
          orig=(unsigned int *)(save_image->ScanLine[jj]);
          for (ii=0; ii<617; ii++)
            if (keymap[jj*617+ii]==((backindex[i]<<4)|bit))
              buffer[ii]=orig[ii];
        }
        keyboard_image->Invalidate();
      }

    } else if (enabled==2) {

      if (keybuf[i]&0x80) {
        backindex[i]=key>>4;
        backbit[i]=1<<(key&7);
        enabled=1;
        keyboard_image->Picture->Assign (save_image);
        keyboard_image->Invalidate();
        message->Caption=
          "Click on the key you want to configure, using the mouse";
      }

    }
  }
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::FormDeactivate(TObject *Sender)
{
  enabled=0;
  ModalResult=mrOk;
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::FormShow(TObject *Sender)
{
  int i,j,k;
  unsigned char b;

  Keyboard->Height=350;
  keyboard_image->Picture->Assign (save_image);
  for (i=0; i<256; i++) {
    dirty[i]=0;
    backindex[i]=keyindex[i];
    backbit[i]=keybit[i];
  }

  advanced_button->Caption="Advanced >>";
  message->Caption="Click on the key you want to configure, using the mouse";
  Timer1->Enabled=true;
}

//---------------------------------------------------------------------------



void __fastcall TKeyboard::keyboard_imageMouseDown(TObject *Sender,
      TMouseButton Button, TShiftState Shift, int X, int Y)
{
  int i,ii,jj,r,g,b,sum;
  unsigned int *buffer;

  key=keymap[Y*617+X];
  if ((enabled>0 && enabled<3)&&(key!=0xFF)) {
    // remap key using keyboard
    enabled=2;
    keyboard_image->Picture->Assign (save_image);
    for (i=0; i<256; i++)
      dirty[i]=0;
    if (lastkey!=key) {

      for (jj=0; jj<241; jj++) {
        buffer=(unsigned int *)(keyboard_image->Picture->Bitmap->ScanLine[jj]);
        for (ii=0; ii<617; ii++)
          if (keymap[jj*617+ii]==key) {
            r=(buffer[ii]>>16)&0xFF;
            g=(buffer[ii]>>8)&0xFF;
            b=(buffer[ii]>>0)&0xFF;
            sum=(r+g+b)/3;
            buffer[ii]=((sum<<8)+sum)<<8;
          }
      }
      lastkey=key;
      message->Caption="Use your keyboard to select a new key";
    } else {
      enabled=1;
      lastkey=0xFF;
      message->Caption="Click on the key you want to configure, "
                       "using the mouse";
    }
    keyboard_image->Invalidate();

  } else if ((enabled==3)&&(key!=0xFF)) {
    // change extended key mappings

    keyboard_image->Picture->Assign (save_image);
    for (i=0; i<256; i++)
      dirty[i]=0;

    for (jj=0; jj<241; jj++) {
      buffer=(unsigned int *)(keyboard_image->Picture->Bitmap->ScanLine[jj]);
      for (ii=0; ii<617; ii++)
        if (keymap[jj*617+ii]==key) {
          r=(buffer[ii]>>16)&0xFF;
          g=(buffer[ii]>>8)&0xFF;
          b=(buffer[ii]>>0)&0xFF;
          sum=(r+g+b)/3;
          buffer[ii]=((sum<<8)+sum);
        }
    }
    keyboard_image->Invalidate();
    if ((key>>4)>5) {
      message->Caption="This key does not have extended information";
      for (i=0; i<6; i++) {
        box[i]->ItemIndex=0;
        box[i]->Enabled=false;
      }
    } else {
      message->Caption="Change the key mapping below";
      for (i=0; i<6; i++) {
        box[i]->ItemIndex=extendedmap[i*8*6+(key>>4)*8+(key&7)];
        box[i]->Enabled=true;
      }
    }

  }
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::advanced_buttonClick(TObject *Sender)
{
  int i,j,k;

  if (enabled<3) {
    Keyboard->Height=440;
    advanced_button->Caption="<< Back";
    message->Caption="Select a key using the mouse";
    enabled=3;
    for (i=0; i<6; i++) {
      box[i]->ItemIndex=0;
      box[i]->Enabled=false;
    }
  } else {
    Keyboard->Height=350;
    advanced_button->Caption="Advanced >>";
    message->Caption=
      "Click on the key you want to configure, using the mouse";
    enabled=1;
  }
  for (i=0; i<256; i++)
    dirty[i]=0;
  keyboard_image->Picture->Assign (save_image);
  keyboard_image->Invalidate ();
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::normal_boxSelect(TObject *Sender)
{
  advanced_button->SetFocus();
  extendedmap[0*8*6+(key>>4)*8+(key&7)]=box[0]->ItemIndex;
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::shift_boxSelect(TObject *Sender)
{
  advanced_button->SetFocus();
  extendedmap[1*8*6+(key>>4)*8+(key&7)]=box[1]->ItemIndex;
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::lgra_boxSelect(TObject *Sender)
{
  advanced_button->SetFocus();
  extendedmap[2*8*6+(key>>4)*8+(key&7)]=box[2]->ItemIndex;

}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::rgra_boxSelect(TObject *Sender)
{
  advanced_button->SetFocus();
  extendedmap[4*8*6+(key>>4)*8+(key&7)]=box[4]->ItemIndex;

}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::lgrashift_boxSelect(TObject *Sender)
{
  advanced_button->SetFocus();
  extendedmap[3*8*6+(key>>4)*8+(key&7)]=box[3]->ItemIndex;

}
//---------------------------------------------------------------------------


void __fastcall TKeyboard::rgrashift_boxSelect(TObject *Sender)
{
  advanced_button->SetFocus();
  extendedmap[5*8*6+(key>>4)*8+(key&7)]=box[5]->ItemIndex;
}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::Button4Click(TObject *Sender)
{
  FILE *f;

  save_key_dialog->Filter=
    "Keyboard configuration (*.key)|*.key";
  save_key_dialog->DefaultExt="key";
  if (save_key_dialog->Execute()) {
    f=fopen (save_key_dialog->FileName.c_str(),"wb");
    fwrite (backindex,1,256,f);
    fwrite (backbit,1,256,f);
    fwrite (extendedmap,1,6*8*6,f);
    fclose (f);
  }

}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::Button5Click(TObject *Sender)
{
  FILE *f;

  load_key_dialog->Filter=
    "Keyboard configuration (*.key)|*.key";
  load_key_dialog->DefaultExt="key";
  if (load_key_dialog->Execute()) {
    f=fopen (load_key_dialog->FileName.c_str(),"rb");
    fread (backindex,1,256,f);
    fread (backbit,1,256,f);
    fread (extendedmap,1,6*8*6,f);
    fclose (f);
  }


}
//---------------------------------------------------------------------------

void __fastcall TKeyboard::FormHide(TObject *Sender)
{
  Timer1->Enabled=false;
}
//---------------------------------------------------------------------------

