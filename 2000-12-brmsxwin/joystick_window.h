//---------------------------------------------------------------------------

#ifndef joystick_windowH
#define joystick_windowH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TJoystick : public TForm
{
__published:	// IDE-managed Components
        TImage *joystick_image;
private:	// User declarations
public:		// User declarations
        __fastcall TJoystick(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TJoystick *Joystick;
//---------------------------------------------------------------------------
#endif
