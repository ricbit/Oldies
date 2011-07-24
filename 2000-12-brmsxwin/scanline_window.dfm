object Scanline: TScanline
  Left = 270
  Top = 141
  BorderStyle = bsDialog
  Caption = 'Video Settings'
  ClientHeight = 266
  ClientWidth = 233
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 16
    Top = 16
    Width = 201
    Height = 193
  end
  object Label1: TLabel
    Left = 32
    Top = 72
    Width = 101
    Height = 13
    Caption = 'Intensity of scanlines:'
  end
  object percent: TLabel
    Left = 152
    Top = 72
    Width = 20
    Height = 13
    Caption = '50%'
  end
  object Label3: TLabel
    Left = 32
    Top = 128
    Width = 27
    Height = 13
    Caption = 'Bright'
  end
  object intensity_slider: TScrollBar
    Left = 32
    Top = 96
    Width = 169
    Height = 16
    Max = 128
    PageSize = 0
    Position = 64
    TabOrder = 0
    OnChange = intensity_sliderChange
  end
  object enable_tvborder: TCheckBox
    Left = 32
    Top = 40
    Width = 121
    Height = 17
    Caption = 'Enable TV border'
    Checked = True
    State = cbChecked
    TabOrder = 1
    OnClick = enable_tvborderClick
  end
  object Button1: TButton
    Left = 79
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 2
    OnClick = Button1Click
  end
  object bright_slider: TScrollBar
    Left = 32
    Top = 152
    Width = 169
    Height = 16
    Max = 199
    PageSize = 0
    Position = 100
    TabOrder = 3
    OnChange = bright_sliderChange
  end
end
