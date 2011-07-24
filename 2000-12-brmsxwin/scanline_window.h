//---------------------------------------------------------------------------

#ifndef scanline_windowH
#define scanline_windowH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TScanline : public TForm
{
__published:	// IDE-managed Components
        TScrollBar *intensity_slider;
        TBevel *Bevel1;
        TLabel *Label1;
        TCheckBox *enable_tvborder;
        TButton *Button1;
        TLabel *percent;
        TLabel *Label3;
        TScrollBar *bright_slider;
        void __fastcall Button1Click(TObject *Sender);
        void __fastcall intensity_sliderChange(TObject *Sender);
        void __fastcall FormShow(TObject *Sender);
        void __fastcall enable_tvborderClick(TObject *Sender);
        void __fastcall bright_sliderChange(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TScanline(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TScanline *Scanline;
//---------------------------------------------------------------------------
#endif
