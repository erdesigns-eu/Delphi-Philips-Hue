object SimpleHueForm: TSimpleHueForm
  Caption = 'Philips Hue - Simple v1/v2 Demo'
  ClientHeight = 360
  ClientWidth = 560
  Position = poScreenCenter
  object HostEdit: TEdit
    Left = 16
    Top = 16
    Width = 190
    Height = 23
    Text = 'bridge-id.local'
  end
  object KeyEdit: TEdit
    Left = 216
    Top = 16
    Width = 190
    Height = 23
    PasswordChar = '*'
    TextHint = 'Application key'
  end
  object VersionBox: TComboBox
    Left = 416
    Top = 16
    Width = 120
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    Text = 'API v1'
    Items.Strings = ('API v1' 'API v2')
  end
  object LoadButton: TButton
    Left = 16
    Top = 52
    Width = 120
    Height = 30
    Caption = 'Load lights'
    OnClick = LoadButtonClick
  end
  object OnButton: TButton
    Left = 144
    Top = 52
    Width = 90
    Height = 30
    Caption = 'On'
    OnClick = OnButtonClick
  end
  object OffButton: TButton
    Left = 242
    Top = 52
    Width = 90
    Height = 30
    Caption = 'Off'
    OnClick = OffButtonClick
  end
  object LightsList: TListBox
    Left = 16
    Top = 96
    Width = 520
    Height = 240
  end
end
