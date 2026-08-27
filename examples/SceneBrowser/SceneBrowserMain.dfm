object SceneBrowserForm: TSceneBrowserForm
  Caption = 'Hue Scene Browser'
  ClientHeight = 420
  ClientWidth = 680
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
    Width = 110
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    Text = 'API v1'
    Items.Strings = ('API v1' 'API v2')
  end
  object LoadButton: TButton
    Left = 536
    Top = 14
    Width = 120
    Height = 28
    Caption = 'Load scenes'
    OnClick = LoadButtonClick
  end
  object ScenesList: TListBox
    Left = 16
    Top = 58
    Width = 290
    Height = 330
    OnClick = ScenesListClick
  end
  object DetailMemo: TMemo
    Left = 320
    Top = 58
    Width = 336
    Height = 270
    ReadOnly = True
  end
  object RecallButton: TButton
    Left = 320
    Top = 342
    Width = 160
    Height = 46
    Caption = 'Recall selected scene'
    OnClick = RecallButtonClick
  end
end
