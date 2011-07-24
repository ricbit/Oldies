//---------------------------------------------------------------------------

#ifndef keyboard_windowH
#define keyboard_windowH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include <Graphics.hpp>
#include <ComCtrls.hpp>
#include <Dialogs.hpp>
//---------------------------------------------------------------------------
typedef TComboBoxEx *LTCOMBOBOXEX;

class TKeyboard : public TForm
{
__published:	// IDE-managed Components
        TImage *keyboard_image;
        TLabel *message;
        TButton *ok_button;
        TButton *cancel_button;
        TTimer *Timer1;
        TButton *advanced_button;
        TButton *Button4;
        TButton *Button5;
        TBevel *Bevel1;
        TComboBoxEx *normal_box;
        TComboBoxEx *shift_box;
        TComboBoxEx *lgra_box;
        TComboBoxEx *lgrashift_box;
        TComboBoxEx *rgra_box;
        TComboBoxEx *rgrashift_box;
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TLabel *Label4;
        TLabel *Label5;
        TLabel *Label6;
        TSaveDialog *save_key_dialog;
        TOpenDialog *load_key_dialog;
        void __fastcall ok_buttonClick(TObject *Sender);
        void __fastcall cancel_buttonClick(TObject *Sender);
        void __fastcall FormDestroy(TObject *Sender);
        void __fastcall FormActivate(TObject *Sender);
        void __fastcall Timer1Timer(TObject *Sender);
        void __fastcall FormDeactivate(TObject *Sender);
        void __fastcall FormShow(TObject *Sender);
        void __fastcall keyboard_imageMouseDown(TObject *Sender,
          TMouseButton Button, TShiftState Shift, int X, int Y);
        void __fastcall advanced_buttonClick(TObject *Sender);
        void __fastcall normal_boxSelect(TObject *Sender);
        void __fastcall shift_boxSelect(TObject *Sender);
        void __fastcall lgra_boxSelect(TObject *Sender);
        void __fastcall rgra_boxSelect(TObject *Sender);
        void __fastcall lgrashift_boxSelect(TObject *Sender);
        void __fastcall rgrashift_boxSelect(TObject *Sender);
        void __fastcall Button4Click(TObject *Sender);
        void __fastcall Button5Click(TObject *Sender);
        void __fastcall FormHide(TObject *Sender);
private:	// User declarations
        LTCOMBOBOXEX box[6];
public:		// User declarations
        __fastcall TKeyboard(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TKeyboard *Keyboard;
//---------------------------------------------------------------------------
#endif
