//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
#include "brmsx_main.h"
#include "brmsx_engine.h"
USEFORM("brmsx_main.cpp", main_window);
USEFORM("fudebug_window.cpp", Fudebug);
USEFORM("about_window.cpp", About);
USEFORM("scanline_window.cpp", Scanline);
USEFORM("keyboard_window.cpp", Keyboard);
USEFORM("joystick_window.cpp", Joystick);
USEFORM("mount_window.cpp", Mount);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR cmdline, int)
{
  int i;

        try
        {

                 Application->Initialize();
                 Application->Title = "BrMSX";

                 // init windows to null;
                 Keyboard=NULL;
                 Scanline=NULL;
                 About=NULL;

                 // parse command line
                 for (i=1; i<=ParamCount(); i++) {
                   if (FindCmdLineSwitch ("slow")) {
                     scanline_value=0;
                     tvborder_value=0;
                     first_black_frame=1;
                   }
                 }

                 // pre-process windows
                 Application->CreateForm(__classid(Tmain_window), &main_window);
                 Application->CreateForm(__classid(TFudebug), &Fudebug);
                 Application->CreateForm(__classid(TMount), &Mount);
                 time_enabled=1;
                 Application->Run();
        }
        catch (Exception &exception)
        {
                 Application->ShowException(&exception);
        }
        return 0;
}
//---------------------------------------------------------------------------
