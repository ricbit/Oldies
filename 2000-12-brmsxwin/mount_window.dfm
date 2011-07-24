object Mount: TMount
  Left = 226
  Top = 121
  Width = 443
  Height = 323
  Caption = 'Mount Directory'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object top_label: TLabel
    Left = 115
    Top = 16
    Width = 205
    Height = 13
    Caption = 'Select a directory to mount as MSX drive A:'
  end
  object drivebox: TDriveComboBox
    Left = 26
    Top = 48
    Width = 193
    Height = 19
    DirList = dirlist
    TabOrder = 0
  end
  object dirlist: TDirectoryListBox
    Left = 26
    Top = 80
    Width = 193
    Height = 161
    FileList = filelist
    ItemHeight = 16
    TabOrder = 1
  end
  object Button1: TButton
    Left = 132
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 228
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = Button2Click
  end
  object filelist: TFileListBox
    Left = 240
    Top = 48
    Width = 169
    Height = 193
    ItemHeight = 13
    TabOrder = 4
  end
end
