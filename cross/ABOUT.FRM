VERSION 5.00
Begin VB.Form About 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "About CrossWorder Pro For Windows"
   ClientHeight    =   3180
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4620
   Icon            =   "About.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3180
   ScaleWidth      =   4620
   ShowInTaskbar   =   0   'False
   StartUpPosition =   2  'CenterScreen
   Begin VB.TextBox aboutus 
      BackColor       =   &H80000000&
      CausesValidation=   0   'False
      Height          =   2535
      Left            =   1320
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   3  'Both
      TabIndex        =   5
      Top             =   120
      Width           =   3135
   End
   Begin VB.CommandButton OK 
      Caption         =   "OK"
      Height          =   375
      Left            =   0
      TabIndex        =   0
      Top             =   2760
      Width           =   4575
   End
   Begin VB.Line Line4 
      X1              =   0
      X2              =   1200
      Y1              =   0
      Y2              =   0
   End
   Begin VB.Line Line3 
      X1              =   0
      X2              =   0
      Y1              =   0
      Y2              =   2640
   End
   Begin VB.Line Line2 
      X1              =   0
      X2              =   1200
      Y1              =   2640
      Y2              =   2640
   End
   Begin VB.Line Line1 
      X1              =   1200
      X2              =   1200
      Y1              =   0
      Y2              =   2640
   End
   Begin VB.Label Label2 
      Caption         =   "Release 2"
      Height          =   255
      Left            =   240
      TabIndex        =   2
      Top             =   1080
      Width           =   735
   End
   Begin VB.Label Label4 
      Caption         =   "  FREEWARE      VERSION"
      Height          =   375
      Left            =   120
      TabIndex        =   4
      Top             =   2160
      Width           =   1095
   End
   Begin VB.Label Label3 
      Caption         =   "   (C) 2001        Brainwave Incorporated"
      Height          =   615
      Left            =   120
      TabIndex        =   3
      Top             =   1440
      Width           =   975
   End
   Begin VB.Label Label1 
      Caption         =   "  Version 2.2"
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   840
      Width           =   1095
   End
   Begin VB.Image Image1 
      Height          =   525
      Left            =   240
      Picture         =   "About.frx":0442
      Top             =   240
      Width           =   735
   End
End
Attribute VB_Name = "About"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Private Sub Form_Load()
Open InputForm.WDir + "about.cwp" For Input As #9
 aboutus.Text = Input$(LOF(9), 9)
 Close #9
End Sub

Private Sub OK_Click()
 About.Hide
End Sub
