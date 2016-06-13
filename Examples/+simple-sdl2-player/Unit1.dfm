object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'FFMPEG PLAY - DELPHI VCL DEMO'
  ClientHeight = 613
  ClientWidth = 829
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Scaled = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 16
  object Panel2: TPanel
    Left = 0
    Top = 538
    Width = 829
    Height = 75
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 432
    ExplicitWidth = 1046
    object StatusBar1: TStatusBar
      Left = 0
      Top = 56
      Width = 829
      Height = 19
      Panels = <>
      ExplicitLeft = 952
      ExplicitTop = 16
      ExplicitWidth = 0
    end
    object Button1: TButton
      Left = 8
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Play'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 103
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Pause'
      TabOrder = 2
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 200
      Top = 17
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = Button3Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 829
    Height = 538
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    BevelOuter = bvNone
    Color = 3355443
    Padding.Left = 1
    Padding.Top = 1
    Padding.Right = 1
    Padding.Bottom = 1
    ParentBackground = False
    TabOrder = 1
    ExplicitLeft = 632
    ExplicitTop = 160
    ExplicitWidth = 185
    ExplicitHeight = 185
    object Panel1: TPanel
      Left = 1
      Top = 1
      Width = 827
      Height = 536
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      BevelOuter = bvNone
      BiDiMode = bdLeftToRight
      Color = 8947848
      ParentBiDiMode = False
      ParentBackground = False
      TabOrder = 0
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 185
      ExplicitHeight = 41
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 96
    Top = 312
  end
  object MainMenu1: TMainMenu
    Left = 160
    Top = 320
    object File1: TMenuItem
      Caption = 'File'
      object Open1: TMenuItem
        Caption = 'Open'
        OnClick = Open1Click
      end
      object Savesa1: TMenuItem
        Caption = 'Save as'
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
      end
    end
    object N1: TMenuItem
      Caption = '?'
    end
  end
end
