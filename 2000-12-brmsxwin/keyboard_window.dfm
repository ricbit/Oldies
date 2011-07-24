object Keyboard: TKeyboard
  Left = 140
  Top = 83
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Keyboard Configuration'
  ClientHeight = 413
  ClientWidth = 617
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnDestroy = FormDestroy
  OnDeactivate = FormDeactivate
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object keyboard_image: TImage
    Left = 0
    Top = 0
    Width = 617
    Height = 241
    OnMouseDown = keyboard_imageMouseDown
  end
  object message: TLabel
    Left = 16
    Top = 256
    Width = 401
    Height = 13
    AutoSize = False
    Caption = 'Click on the key you want to configure, using the mouse'
  end
  object Bevel1: TBevel
    Left = 8
    Top = 328
    Width = 601
    Height = 10
    Shape = bsTopLine
  end
  object Label1: TLabel
    Left = 79
    Top = 344
    Width = 33
    Height = 13
    Caption = 'Normal'
  end
  object Label2: TLabel
    Left = 159
    Top = 344
    Width = 21
    Height = 13
    Caption = 'Shift'
  end
  object Label3: TLabel
    Left = 239
    Top = 344
    Width = 29
    Height = 13
    Caption = 'LGRA'
  end
  object Label4: TLabel
    Left = 319
    Top = 344
    Width = 31
    Height = 13
    Caption = 'RGRA'
  end
  object Label5: TLabel
    Left = 399
    Top = 344
    Width = 56
    Height = 13
    Caption = 'LGRA+Shift'
  end
  object Label6: TLabel
    Left = 479
    Top = 344
    Width = 58
    Height = 13
    Caption = 'RGRA+Shift'
  end
  object ok_button: TButton
    Left = 456
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 0
    OnClick = ok_buttonClick
  end
  object cancel_button: TButton
    Left = 536
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = cancel_buttonClick
  end
  object advanced_button: TButton
    Left = 16
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Advanced >>'
    TabOrder = 2
    OnClick = advanced_buttonClick
  end
  object Button4: TButton
    Left = 456
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Save'
    TabOrder = 3
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 536
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 4
    OnClick = Button5Click
  end
  object normal_box: TComboBoxEx
    Left = 79
    Top = 368
    Width = 57
    Height = 22
    ItemsEx.CaseSensitive = False
    ItemsEx.SortType = stNone
    ItemsEx = <>
    Style = csExDropDownList
    StyleEx = []
    ItemHeight = 16
    TabOrder = 5
    OnSelect = normal_boxSelect
    DropDownCount = 8
  end
  object shift_box: TComboBoxEx
    Left = 159
    Top = 368
    Width = 57
    Height = 22
    ItemsEx.CaseSensitive = False
    ItemsEx.SortType = stNone
    ItemsEx = <>
    Style = csExDropDownList
    StyleEx = []
    ItemHeight = 16
    TabOrder = 6
    OnSelect = shift_boxSelect
    DropDownCount = 8
  end
  object lgra_box: TComboBoxEx
    Left = 239
    Top = 368
    Width = 57
    Height = 22
    ItemsEx.CaseSensitive = False
    ItemsEx.SortType = stNone
    ItemsEx = <>
    Style = csExDropDownList
    StyleEx = []
    ItemHeight = 16
    TabOrder = 7
    OnSelect = lgra_boxSelect
    DropDownCount = 8
  end
  object lgrashift_box: TComboBoxEx
    Left = 399
    Top = 368
    Width = 57
    Height = 22
    ItemsEx.CaseSensitive = False
    ItemsEx.SortType = stNone
    ItemsEx = <>
    Style = csExDropDownList
    StyleEx = []
    ItemHeight = 16
    TabOrder = 8
    OnSelect = lgrashift_boxSelect
    DropDownCount = 8
  end
  object rgra_box: TComboBoxEx
    Left = 319
    Top = 368
    Width = 57
    Height = 22
    ItemsEx.CaseSensitive = False
    ItemsEx.SortType = stNone
    ItemsEx = <>
    Style = csExDropDownList
    StyleEx = []
    ItemHeight = 16
    TabOrder = 9
    OnSelect = rgra_boxSelect
    DropDownCount = 8
  end
  object rgrashift_box: TComboBoxEx
    Left = 479
    Top = 368
    Width = 57
    Height = 22
    ItemsEx.CaseSensitive = False
    ItemsEx.SortType = stNone
    ItemsEx = <>
    Style = csExDropDownList
    StyleEx = []
    ItemHeight = 16
    TabOrder = 10
    OnSelect = rgrashift_boxSelect
    DropDownCount = 8
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 19
    OnTimer = Timer1Timer
    Left = 576
    Top = 344
  end
  object save_key_dialog: TSaveDialog
    Left = 544
    Top = 376
  end
  object load_key_dialog: TOpenDialog
    Left = 576
    Top = 376
  end
end
