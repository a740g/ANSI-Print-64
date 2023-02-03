'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI emulator demo
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./include/ANSIPrint.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
Screen NewImage(8 * 80, 16 * 60, 32) ' the builtin font width is 8 and height is 16
Font 8 ' switch to 8x8 builtin font

Dim welcomeMessage As String: welcomeMessage = Space$(25) + Chr$(ANSI_ESC) + "[91;107mWelcome to the ANSIPrint Demo!"
welcomeMessage = welcomeMessage + Chr$(ANSI_CR) + Chr$(ANSI_LF) + Chr$(ANSI_CR) + Chr$(ANSI_LF) + Chr$(ANSI_ESC) + "[m"
welcomeMessage = welcomeMessage + Space$(12) + Chr$(ANSI_ESC) + "[93;101mSelect a file to render it or cancel the dialog to quit."

Do
    ' Render the welcome message
    Color DarkGray, Black ' reset the foregound and background colors
    Cls ' this will reset the cursor to 1, 1
    PrintANSI welcomeMessage, -1

    Dim ansFile As String: ansFile = OpenFileDialog$("Open", "", "*.ans|*.asc|*.diz|*.nfo|*.txt", "ANSI Art Files")
    If Not FileExists(ansFile) Then Exit Do
    Title ansFile

    Dim fh As Long: fh = FreeFile
    Open ansFile For Binary Access Read As fh
    Color DarkGray, Black ' reset the foregound and background colors
    Cls ' this will reset the cursor to 1, 1
    PrintANSI Input$(LOF(fh), fh), 3600 ' put a -ve number here for superfast rendering
    Close fh

    Title "Press any key to open another file...": Sleep 3600
Loop

System
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./include/ANSIPrint.bas'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

