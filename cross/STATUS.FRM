VERSION 5.00
Begin VB.Form status 
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "Search"
   ClientHeight    =   75
   ClientLeft      =   45
   ClientTop       =   285
   ClientWidth     =   2475
   Icon            =   "status.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   75
   ScaleWidth      =   2475
   ShowInTaskbar   =   0   'False
   StartUpPosition =   2  'CenterScreen
   Begin VB.Label Label1 
      Caption         =   "Processing . . . . "
      Height          =   255
      Left            =   960
      TabIndex        =   0
      Top             =   120
      Width           =   1215
   End
   Begin VB.Image logo 
      BorderStyle     =   1  'Fixed Single
      Height          =   585
      Left            =   0
      Picture         =   "status.frx":0442
      Top             =   0
      Width           =   795
   End
End
Attribute VB_Name = "status"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
