//---------------------------------------------------------------------------

#ifndef mount_windowH
#define mount_windowH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <FileCtrl.hpp>
#include "cdiroutl.h"
#include <Grids.hpp>
#include <Outline.hpp>
//---------------------------------------------------------------------------
class TMount : public TForm
{
__published:	// IDE-managed Components
        TDriveComboBox *drivebox;
        TDirectoryListBox *dirlist;
        TButton *Button1;
        TButton *Button2;
        TLabel *top_label;
        TFileListBox *filelist;
        void __fastcall Button2Click(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TMount(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMount *Mount;
//---------------------------------------------------------------------------
#endif
