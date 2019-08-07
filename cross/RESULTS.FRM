VERSION 5.00
Begin VB.Form Results 
   AutoRedraw      =   -1  'True
   Caption         =   "Search- Results"
   ClientHeight    =   3750
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   3300
   FillStyle       =   0  'Solid
   FontTransparent =   0   'False
   Icon            =   "Results.frx":0000
   LinkMode        =   1  'Source
   LinkTopic       =   "Form2"
   MinButton       =   0   'False
   ScaleHeight     =   3750
   ScaleWidth      =   3300
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton filterres 
      Caption         =   "Filter Results"
      Height          =   375
      Left            =   23
      TabIndex        =   2
      Top             =   3240
      Width           =   1575
   End
   Begin VB.TextBox ShowRes 
      Height          =   3015
      Left            =   143
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   1
      Top             =   120
      Width           =   3015
   End
   Begin VB.CommandButton OK 
      Caption         =   "OK"
      Default         =   -1  'True
      Height          =   375
      Left            =   1703
      TabIndex        =   0
      Top             =   3240
      Width           =   1575
   End
End
Attribute VB_Name = "Results"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Private Sub filterres_Click()
InputForm.Filtstat.Value = 1
InputForm.InpBox.Text = ""
Results.Hide
End Sub

Private Sub Form_Activate()
ShowRes.Text = ""
Open InputForm.WDir + InputForm.OFile For Input As #1
ShowRes.Text = Input$(LOF(1), 1)
Close #1
End Sub

Private Sub OK_Click()
 InputForm.Filtstat.Value = 0
 InputForm.InpBox.Text = ""
 Results.Hide
End Sub
