object EventMonitorForm: TEventMonitorForm
  Caption = 'Hue v2 Event Stream Monitor'
  ClientHeight = 430
  ClientWidth = 720
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
    Width = 240
    Height = 23
    PasswordChar = '*'
    TextHint = 'Application key'
  end
  object StartButton: TButton
    Left = 504
    Top = 14
    Width = 90
    Height = 28
    Caption = 'Start'
    OnClick = StartButtonClick
  end
  object StopButton: TButton
    Left = 604
    Top = 14
    Width = 90
    Height = 28
    Caption = 'Stop'
    OnClick = StopButtonClick
  end
  object EventsMemo: TMemo
    Left = 16
    Top = 58
    Width = 678
    Height = 348
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
end
