VERSION 5.00
Begin VB.Form InputForm 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "CrossWorder Pro For Windows"
   ClientHeight    =   3705
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4530
   Icon            =   "main.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3705
   ScaleMode       =   0  'User
   ScaleWidth      =   4530
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton aboutus 
      Caption         =   "About "
      Height          =   375
      Left            =   458
      TabIndex        =   9
      ToolTipText     =   "Click to view info about program"
      Top             =   2640
      Width           =   1215
   End
   Begin VB.CommandButton Quit 
      Caption         =   "Quit"
      Height          =   375
      Left            =   1628
      TabIndex        =   8
      ToolTipText     =   "Quit program"
      Top             =   2640
      Width           =   1215
   End
   Begin VB.CommandButton dispres 
      Caption         =   "Display Result"
      Enabled         =   0   'False
      Height          =   375
      Left            =   2858
      TabIndex        =   7
      ToolTipText     =   "Click to view result of last search"
      Top             =   2640
      Width           =   1215
   End
   Begin VB.Frame Frame1 
      Caption         =   "Search for"
      Height          =   2415
      Left            =   278
      TabIndex        =   0
      Top             =   120
      Width           =   3975
      Begin VB.CheckBox AutoShow 
         Caption         =   "AutoShow Results"
         Height          =   435
         Left            =   2160
         TabIndex        =   12
         ToolTipText     =   "Show results of search instantly"
         Top             =   720
         Value           =   1  'Checked
         Width           =   1695
      End
      Begin VB.CheckBox Filtstat 
         Caption         =   "Filter results"
         Height          =   195
         Left            =   225
         TabIndex        =   11
         ToolTipText     =   "Check to search within previous result"
         Top             =   840
         Width           =   1695
      End
      Begin VB.TextBox InpBox 
         Height          =   315
         Left            =   240
         MousePointer    =   3  'I-Beam
         TabIndex        =   6
         ToolTipText     =   "Enter search string here "
         Top             =   360
         Width           =   3015
      End
      Begin VB.CommandButton go 
         Caption         =   "GO!"
         Default         =   -1  'True
         Height          =   315
         Left            =   3240
         MousePointer    =   1  'Arrow
         TabIndex        =   5
         ToolTipText     =   "Click to search."
         Top             =   360
         Width           =   495
      End
      Begin VB.OptionButton letstr 
         Caption         =   "LetterSet"
         Height          =   255
         Left            =   2640
         TabIndex        =   4
         ToolTipText     =   "Finds all words containing  letters entered in any order"
         Top             =   1920
         Width           =   1095
      End
      Begin VB.OptionButton WordFill 
         Caption         =   "Word Fill"
         Height          =   255
         Left            =   2640
         TabIndex        =   3
         ToolTipText     =   "Replaces ? with letter to form valid word"
         Top             =   1560
         Value           =   -1  'True
         Width           =   1095
      End
      Begin VB.OptionButton strstr 
         Caption         =   "Match String"
         Height          =   255
         Left            =   360
         TabIndex        =   2
         ToolTipText     =   "Finds all words containing entered pattern"
         Top             =   1920
         Width           =   1335
      End
      Begin VB.OptionButton anagrammer 
         Caption         =   "Anagram"
         Height          =   255
         Left            =   360
         TabIndex        =   1
         ToolTipText     =   "Finds valid combinations of entered letters"
         Top             =   1560
         Width           =   1095
      End
      Begin VB.Frame Options 
         Caption         =   "Options"
         Height          =   975
         Left            =   120
         TabIndex        =   10
         Top             =   1320
         Width           =   3735
         Begin VB.Image Image1 
            Height          =   525
            Left            =   1560
            Picture         =   "main.frx":0442
            Top             =   240
            Width           =   735
         End
      End
   End
   Begin VB.Label resultcount 
      Height          =   255
      Left            =   398
      TabIndex        =   13
      Top             =   3240
      Width           =   3735
   End
End
Attribute VB_Name = "InputForm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Public cross As String
Public IFile As String
Public OFile As String
Public WDir As String
Public FiltNo As Integer
Public valid As Integer
Public opcode As Integer

Function checksum(arg$)

For i = 1 To Len(arg$)
 l$ = Mid$(arg$, i, 1): ascii = Asc(l$)
 asciisum = asciisum + ascii
Next: ascii = 0
checksum = asciisum

End Function
Private Sub jumble()

length = Len(cross)
chksum = checksum(cross)
ReDim letter$(length), chk(length)
For i = 1 To length
 letter$(i) = Mid$(cross, i, 1): ascii = Asc(letter$(i))
Next: ascii = 0
Print

If InputForm.FiltNo = 0 Then
  IFile = LTrim$(RTrim$(Str$(length))) + ".wrd"
  OFile = "crossol2.scp"
 Else
  Select Case (InputForm.FiltNo Mod 2)
   Case 1: IFile = "crossol2.scp": OFile = "crossol1.scp"
   Case 0: IFile = "crossol1.scp": OFile = "crossol2.scp"
  End Select
 End If

Open WDir + IFile For Input As #1
Open WDir + OFile For Output As #2
 
Do Until EOF(1)
 Input #1, a$
 crosschksum = checksum(a$)
 
 flag = 1
 For i = 1 To length
  chk(i) = InStr(a$, letter$(i))
 Next
 For i = 1 To length
  If chk(i) = 0 Then flag = 0
 Next

 If flag = 1 Then
  If chksum = crosschksum Then Print #2, a$: valid = valid + 1
 End If

 Loop
Close
Call Checkdisp(valid)
End Sub
Sub Checkdisp(valid)
'InpBox.Text = ""
If valid <> 0 Then
 If valid < 500 Then
  dispres.Enabled = True
  resultcount.Caption = "Found " + Str$(valid) + "  words."
  If AutoShow.Value = 1 Then Results.Show
 Else
  resultcount.Caption = "Results exceed useful limits. Filter results."
  Filtstat.Value = 1
  
 End If
Else
 dispres.Enabled = False
 resultcount.Caption = "No results to display."
End If
go.Enabled = True
End Sub

Private Sub aboutus_Click()
 About.Show (1)
End Sub

Private Sub dispres_Click()
 Results.Show
End Sub


Private Sub Form_Activate()
go.Enabled = True
resultcount.Caption = ""
If Filtstat.Value = 1 Then
 If WordFill.Value = True Then
  strstr.Value = True
 ElseIf strstr.Value = True Then
  WordFill.Value = True
 ElseIf letstr.Value = True Then
  WordFill.Value = True
 End If
 End If
 End Sub

Private Sub Form_Load()
 InputForm.FiltNo = 1
 Open "wdir.ini" For Input As #1
 Line Input #1, WDir
 Close #1
 go.Enabled = True
End Sub

Private Sub go_Click()
 go.Enabled = False
 cross = InpBox.Text
 dispres.Enabled = False
 If Filtstat.Value = 0 Then
  InputForm.FiltNo = 0
 Else
  InputForm.FiltNo = InputForm.FiltNo + 1
 End If
 Close
 
 valid = 0
 If Len(cross) > 0 Then
  If InStr(cross, "?") <> 0 Then WordFill.Value = True
  If InStr(cross, "*") <> 0 Then cross = Left$(cross, Len(cross) - 1): letstr.Value = True
  If InStr(cross, "#") <> 0 Then cross = Left$(cross, Len(cross) - 1): strstr.Value = True
  If InStr(cross, "=") <> 0 Then cross = Left$(cross, Len(cross) - 1): anagrammer.Value = True
  If WordFill.Value = True Then If InStr(cross, "?") = 0 Then letstr.Value = True
  
  If WordFill.Value = True Then Call wordfinder
  If anagrammer.Value = True Then Call jumble
  If strstr.Value = True Then Call exactstr
  If letstr.Value = True Then Call anystr
 Else
  go.Enabled = True
 End If
End Sub

Sub wordfinder()
 cross = LTrim$(LCase$(cross))
 length = Len(cross$)
 ReDim letter$(length), wordlet$(length)
 numknown = 1
 For i = 1 To length
  letter$(i) = Mid$(cross, i, 1)
 Next

 If InputForm.FiltNo = 0 Then
  IFile = LTrim$(RTrim$(Str$(length))) + ".wrd"
  OFile = "crossol2.scp"
 Else
  Select Case (InputForm.FiltNo Mod 2)
   Case 1: IFile = "crossol2.scp": OFile = "crossol1.scp"
   Case 0: IFile = "crossol1.scp": OFile = "crossol2.scp"
  End Select
 End If


Open WDir + IFile For Input As #1
Open WDir + OFile For Output As #2
 
Do Until EOF(1)

 Input #1, a$
 
 flag = 1
 For i = 1 To length
  wordlet$(i) = Mid$(a$, i, 1)
 Next
 
 For i = 1 To length
  If letter$(i) <> "?" Then
   If letter$(i) <> wordlet$(i) Then flag = 0
  End If
 Next

 If flag = 1 Then
  Print #2, a$
  valid = valid + 1
 End If

Loop: Close

Call Checkdisp(valid)

End Sub

Private Sub Quit_Click()
End
End Sub

Sub exactstr()
 If InputForm.FiltNo = 0 Then
  IFile = "dict.txt"
  OFile = "crossol2.scp"
 Else
  Select Case (InputForm.FiltNo Mod 2)
   Case 1: IFile = "crossol2.scp": OFile = "crossol1.scp"
   Case 0: IFile = "crossol1.scp": OFile = "crossol2.scp"
  End Select
 End If
 
 Open WDir + IFile For Input As #1
 Open WDir + OFile For Output As #2

 length = Len(cross)

 Do Until EOF(1)
  Input #1, a$
  If InStr(a$, cross) <> 0 Then Print #2, a$: valid = valid + 1
 Loop
 Close
Call Checkdisp(valid)
End Sub

Sub anystr()
  If InputForm.FiltNo = 0 Then
  IFile = "dict.txt"
  OFile = "crossol2.scp"
 Else
  Select Case (InputForm.FiltNo Mod 2)
   Case 1: IFile = "crossol2.scp": OFile = "crossol1.scp"
   Case 0: IFile = "crossol1.scp": OFile = "crossol2.scp"
  End Select
 End If
 
 Open WDir + IFile For Input As #1
 Open WDir + OFile For Output As #2
 
 length = Len(cross)
 
 Do Until EOF(1)
  Input #1, a$
  
  flag = 1
  For i = 1 To length
   l$ = Mid$(cross, i, 1)
   If InStr(a$, l$) <> 0 Then Else flag = 0
  Next
  If flag = 1 Then Print #2, a$: valid = valid + 1
 
 Loop
 Close
Call Checkdisp(valid)
End Sub

