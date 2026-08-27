object AutomationForm: TAutomationForm
  Caption = 'Hue Home Automation Reference'
  ClientHeight = 430
  ClientWidth = 660
  Position = poScreenCenter
  object HostEdit: TEdit
    Left = 16
    Top = 16
    Width = 220
    Height = 23
    Text = 'bridge-id.local'
  end
  object KeyEdit: TEdit
    Left = 248
    Top = 16
    Width = 220
    Height = 23
    PasswordChar = '*'
    TextHint = 'Application key'
  end
  object ConnectButton: TButton
    Left = 480
    Top = 14
    Width = 150
    Height = 28
    Caption = 'Connect / refresh'
    OnClick = ConnectButtonClick
  end
  object MorningButton: TButton
    Left = 16
    Top = 58
    Width = 150
    Height = 36
    Caption = 'Morning routine'
    OnClick = MorningButtonClick
  end
  object EveningButton: TButton
    Left = 176
    Top = 58
    Width = 150
    Height = 36
    Caption = 'Evening routine'
    OnClick = EveningButtonClick
  end
  object AwayButton: TButton
    Left = 336
    Top = 58
    Width = 150
    Height = 36
    Caption = 'Away: all rooms off'
    OnClick = AwayButtonClick
  end
  object LogMemo: TMemo
    Left = 16
    Top = 112
    Width = 614
    Height = 294
    ScrollBars = ssVertical
  end
  object AutomationTimer: TTimer
    Interval = 60000
    OnTimer = AutomationTimerTimer
    Left = 584
    Top = 64
  end
end
