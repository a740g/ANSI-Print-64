'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI emulator
' Copyright (c) 2023 Samuel Gomes
'
' Bibliography:
' https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
' https://en.wikipedia.org/wiki/ANSI_escape_code
' https://en.wikipedia.org/wiki/ANSI.SYS
' http://www.roysac.com/learn/ansisys.html
' https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
' https://talyian.github.io/ansicolors/
' https://www.acid.org/info/sauce/sauce.htm
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./ANSIPrint.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If ANSIPRINT_BAS = UNDEFINED Then
    $Let ANSIPRINT_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    $Debug
    Screen NewImage(640, 640, 12)

    Do
        Dim ansFile As String: ansFile = OpenFileDialog$("Open", "", "*.ans", "ANSI Files")
        If Not FileExists(ansFile) Then Exit Do

        Dim fh As Long: fh = FreeFile
        Open ansFile For Binary Access Read As fh
        PrintANSI Input$(LOF(fh), fh), -1 ' put a -ve number here for superfast rendering
        Close fh
        Title "Press any key to open another file...": Sleep 3600
        Cls
    Loop

    End
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' sANSI - the ANSI stream to render
    ' nCPS - characters / second (bigger numbers means faster; -ve number to disable)
    Sub PrintANSI (sANSI As String, nCPS As Long)
        Dim As Long colorTable(0 To 7) ' the VGA to ANSI color LUT
        Dim As Long state ' the current parser state
        Dim As Long i, ch ' the current character index and the character
        Dim sCSIArg(1 To 5) As String, nCSIArg(1 To 5) As Long ' CSI argument list (string and numeric)
        Dim As Long nCSIArgIndex ' the current CSI argument index; 0 means no arguments
        Dim As Long isBold ' flag that is set when "bold" font is required; this is translated to iCE colors
        Dim As Long x ' a temp variable used in many places (usually as a counter)
        ' The variables below are used to save various things that are restored before the function exits
        Dim As Long oldControlChr, oldCursorX, oldCursorY, oldPrintMode, oldBlink
        Dim As Unsigned Long oldForegroundColor, oldBackgroundColor

        ' Setup ANSI to VGA color table
        Restore ColorTableData
        For i = 0 To 7
            Read colorTable(i)
        Next

        ' Save some stuff that we might be changing
        oldControlChr = ControlChr
        oldCursorX = Pos(0)
        oldCursorY = CsrLin
        oldForegroundColor = DefaultColor
        oldBackgroundColor = BackgroundColor
        oldPrintMode = PrintMode
        oldBlink = Blink

        ' Now we are free to change whatever we saved above
        ControlChr On ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)
        Locate , 1, 1 ' reset cursor to the left of the screen. TODO: How do we check if the cursor is visible? Currently enabled by default for debugging
        Color 15, 0 ' reset the foreground and background color
        PrintMode FillBackground ' set the print mode to fill the character background
        Blink Off

        state = ANSI_STATE_TEXT ' we will start parsing regular text by default

        For i = 1 To Len(sANSI)
            ch = Asc(sANSI, i)

            Select Case state
                Case ANSI_STATE_TEXT ' handle normal characters (including some control characters)
                    Select Case ch
                        Case ANSI_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
                            state = ANSI_STATE_END

                        Case ANSI_BEL ' Handle Bell - because QB64 does not (even with ControlChr On)
                            Beep

                        Case ANSI_BS ' Handle Backspace - because QB64 does not (even with ControlChr On)
                            x = Pos(0) ' save old x pos
                            If x > 1 Then Locate , x - 1 ' move to the left only if we are not on the edge

                        Case ANSI_LF ' Handle Line Feed because QB64 screws this up - moves the cursor to the beginning of the next line
                            x = Pos(0) ' save old x pos
                            Print Chr$(ch); ' use QB64 to handle the LF and then correct the mistake
                            Locate , x ' set the cursor to the old x pos

                        Case ANSI_FF ' Handle Form Feed - because QB64 does not (even with ControlChr On)
                            Locate 1, 1

                        Case ANSI_CR ' Handle Carriage Return because QB64 screws this up - moves the cursor to the beginning of the next line
                            Locate , 1

                            'Case ANSI_DEL ' TODO: Check what to do with this

                        Case ANSI_ESC ' handle escape character
                            state = ANSI_STATE_BEGIN ' beginning a new escape sequence

                        Case Else
                            Print Chr$(ch);

                    End Select

                Case ANSI_STATE_BEGIN ' handle escape sequence
                    Select Case ch
                        Case Is < ANSI_SP ' handle escaped character
                            ControlChr Off
                            Print Chr$(ch); ' print escaped ESC character
                            ControlChr On
                            state = ANSI_STATE_TEXT

                        Case ANSI_ESC_CSI ' handle CSI
                            nCSIArgIndex = 0 ' Reset argument index
                            For x = LBound(sCSIArg) To UBound(sCSIArg)
                                sCSIArg(x) = NULLSTRING ' reset the control sequence arguments
                            Next
                            state = ANSI_STATE_SEQUENCE

                        Case Else ' throw an error for stuff we are not handling
                            Error ERROR_FEATURE_UNAVAILABLE

                    End Select

                Case ANSI_STATE_SEQUENCE ' handle ESC sequence
                    Select Case ch
                        Case ANSI_0 To ANSI_QUESTION_MARK ' argument bytes
                            If nCSIArgIndex < 1 Then nCSIArgIndex = 1 ' set the argument index to one if this is the first time

                            Select Case ch
                                Case ANSI_0 To ANSI_9 ' handle sequence numeric arguments
                                    sCSIArg(nCSIArgIndex) = sCSIArg(nCSIArgIndex) + Chr$(ch)

                                Case ANSI_SEMICOLON ' handle sequence argument seperators
                                    nCSIArgIndex = nCSIArgIndex + 1 ' increment the argument index

                                Case ANSI_EQUALS_SIGN, ANSI_GREATER_THAN_SIGN, ANSI_QUESTION_MARK ' handle lead-in prefix
                                    ' NOP

                                Case Else ' throw an error for stuff we are not handling
                                    Error ERROR_FEATURE_UNAVAILABLE

                            End Select

                        Case ANSI_SP To ANSI_SLASH ' intermediate bytes
                            Select Case ch
                                Case ANSI_SP ' ignore spaces
                                    ' NOP

                                Case Else ' throw an error for stuff we are not handling
                                    Error ERROR_FEATURE_UNAVAILABLE

                            End Select

                        Case ANSI_AT_SIGN To ANSI_TILDE ' final byte
                            Select Case ch
                                Case ANSI_ESC_CSI_SM, ANSI_ESC_CSI_RM ' Set and reset screen mode
                                    Select Case nCSIArgIndex
                                        Case 1
                                            nCSIArg(1) = Val(sCSIArg(1))
                                            Select Case nCSIArg(1)
                                                Case 0, 1 ' 40 x 148 x 25 monochrome (text) & 40 x 148 x 25 color (text)
                                                    Screen 0
                                                    Width 40, 25

                                                Case 2, 3 ' 40 x 148 x 25 monochrome (text) & 40 x 148 x 25 color (text)
                                                    Screen 0
                                                    Width 80, 25

                                                Case 4, 5 ' 320 x 148 x 200 4-color (graphics) & 320 x 148 x 200 monochrome (graphics)
                                                    Screen 1

                                                Case 6 ' 640 x 148 x 200 monochrome (graphics)
                                                    Screen 2

                                                Case 7 ' Enable / disable line wrapping
                                                    ' TODO
                                                    'If ANSI_ESC_CSI_SM = ch Then
                                                    'Else
                                                    'End If

                                                Case 13 ' 320 x 148 x 200 color (16-color graphics)
                                                    Screen 7

                                                Case 14 ' 640 x 148 x 200 color (16-color graphics)
                                                    Screen 8

                                                Case 15 ' 640 x 148 x 350 monochrome (2-color graphics)
                                                    Screen 10

                                                Case 16 ' 640 x 148 x 350 color (16-color graphics)
                                                    Screen 9

                                                Case 17 ' 640 x 148 x 480 monochrome (2-color graphics)
                                                    Screen 11

                                                Case 18 ' 640 x 148 x 480 color (16-color graphics)
                                                    Screen 12

                                                Case 19 ' 320 x 148 x 200 color (256-color graphics)
                                                    Screen 13

                                                Case Else ' throw an error for stuff we are not handling
                                                    Error ERROR_FEATURE_UNAVAILABLE

                                            End Select

                                        Case Else ' this should never happen
                                            Error ERROR_CANNOT_CONTINUE

                                    End Select

                                Case ANSI_ESC_CSI_ED ' Erase in Display
                                    Select Case nCSIArgIndex
                                        Case 1
                                            nCSIArg(1) = Val(sCSIArg(1))
                                            Select Case nCSIArg(1)
                                                Case 2 ' erase entire screen
                                                    Cls

                                                Case Else ' throw an error for stuff we are not handling
                                                    Error ERROR_FEATURE_UNAVAILABLE

                                            End Select

                                        Case Else ' this should never happen
                                            Error ERROR_CANNOT_CONTINUE

                                    End Select

                                Case ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                                    ' Handle stuff based on the number of arguments that we collected
                                    Select Case nCSIArgIndex
                                        Case 3 ' 3 arguments
                                            nCSIArg(1) = Val(sCSIArg(1))
                                            nCSIArg(2) = Val(sCSIArg(2))
                                            nCSIArg(3) = Val(sCSIArg(3))

                                            ' Set styles
                                            Select Case nCSIArg(1)
                                                Case 1
                                                    isBold = TRUE

                                                Case 22
                                                    isBold = FALSE

                                                Case Is >= 30
                                                    Error ERROR_FEATURE_UNAVAILABLE
                                            End Select

                                            Select Case nCSIArg(2)
                                                Case 39 ' default forground color
                                                    Color 15

                                                Case 30 To 37 ' foreground colors
                                                    Color colorTable(nCSIArg(2) - 30)
                                                    If isBold Then Color DefaultColor + 8

                                                Case 90 To 97 ' bright foreground colors
                                                    Color colorTable(nCSIArg(2) - 82)
                                            End Select

                                            Select Case nCSIArg(3)
                                                Case 49 ' default background color
                                                    Color , 0

                                                Case 40 To 47 ' background colors
                                                    Color , colorTable(nCSIArg(3) - 40)
                                                    If isBold Then Color , BackgroundColor + 8

                                                Case 100 To 107 ' bright background colors
                                                    Color , colorTable(nCSIArg(3) - 92)
                                            End Select

                                        Case 2 ' 2 arguments
                                            nCSIArg(1) = Val(sCSIArg(1))
                                            nCSIArg(2) = Val(sCSIArg(2))

                                            ' Set styles
                                            Select Case nCSIArg(1)
                                                Case 1
                                                    isBold = TRUE

                                                Case 22
                                                    isBold = FALSE

                                                Case 39 ' default forground color
                                                    Color 15

                                                Case 49 ' default background color
                                                    Color , 0

                                                Case 40 To 47 ' handle regular backgrounds
                                                    Color , colorTable(nCSIArg(1) - 40)
                                                    If isBold Then Color , BackgroundColor + 8

                                                Case 30 To 37 ' handle regular foreground
                                                    Color colorTable(nCSIArg(1) - 30)
                                                    If isBold Then Color DefaultColor + 8

                                                Case 90 To 97 ' bright foreground colors
                                                    Color colorTable(nCSIArg(2) - 82)

                                                Case 100 To 107 ' bright background colors
                                                    Color , colorTable(nCSIArg(2) - 92)
                                            End Select

                                            Select Case nCSIArg(2)
                                                Case 39 ' default forground color
                                                    Color 15

                                                Case 30 To 37 ' foreground colors
                                                    Color colorTable(nCSIArg(2) - 30)
                                                    If isBold Then Color DefaultColor + 8

                                                Case 90 To 97 ' bright foreground colors
                                                    Color colorTable(nCSIArg(2) - 82)

                                                Case 49 ' default background color
                                                    Color , 0

                                                Case 40 To 47 ' background colors
                                                    Color , colorTable(nCSIArg(2) - 40)
                                                    If isBold Then Color , BackgroundColor + 8

                                                Case 100 To 107 ' bright background colors
                                                    Color , colorTable(nCSIArg(2) - 92)
                                            End Select

                                        Case 1 ' 1 argument
                                            nCSIArg(1) = Val(sCSIArg(1))

                                            Select Case nCSIArg(1)
                                                Case 0 ' reset all modes (styles and colors)
                                                    Color 15, 0
                                                    isBold = FALSE

                                                Case 39 ' default forground color
                                                    Color 15

                                                Case 30 To 37 ' foreground colors
                                                    Color colorTable(nCSIArg(1) - 30)

                                                Case 90 To 97 ' bright foreground colors
                                                    Color colorTable(nCSIArg(1) - 82)

                                                Case 49 ' default background color
                                                    Color , 0

                                                Case 40 To 47 ' background colors
                                                    Color , colorTable(nCSIArg(1) - 40)

                                                Case 100 To 107 ' bright background colors
                                                    Color , colorTable(nCSIArg(1) - 92)
                                            End Select

                                        Case Else ' this should never happen
                                            Error ERROR_CANNOT_CONTINUE

                                    End Select

                                Case ANSI_ESC_CSI_CUP ' Cursor position
                                    If Len(sCSIArg(1)) > 0 Then ' check if we need to move to a specific location
                                        Locate 1 + Val(sCSIArg(1)), 1 + Val(sCSIArg(2)) ' line #, column #
                                    Else ' put the cursor to 1,1
                                        Locate 1, 1
                                    End If

                                Case ANSI_ESC_CSI_HVP ' Horizontal and vertical position
                                    Locate 1 + Val(sCSIArg(1)), 1 + Val(sCSIArg(2)) ' line #, column #

                                Case ANSI_ESC_CSI_CUU ' Cursor up
                                    Locate CsrLin - Val(sCSIArg(1))

                                Case ANSI_ESC_CSI_CUD ' Cursor down
                                    Locate CsrLin + Val(sCSIArg(1))

                                Case ANSI_ESC_CSI_CUF ' Cursor forward
                                    Locate , Pos(0) + Val(sCSIArg(1))

                                Case ANSI_ESC_CSI_CUB ' Cursor back
                                    Locate , Pos(0) - Val(sCSIArg(1))

                                Case ANSI_ESC_CSI_CNL ' Cursor Next Line
                                    Locate CsrLin + Val(sCSIArg(1)), 1

                                Case ANSI_ESC_CSI_CPL ' Cursor Previous Line
                                    Locate CsrLin - Val(sCSIArg(1)), 1

                                Case ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                                    Locate , 1 + Val(sCSIArg(1))

                                Case Else ' throw an error for stuff we are not handling
                                    Error ERROR_FEATURE_UNAVAILABLE

                            End Select

                            ' End of sequence
                            state = ANSI_STATE_TEXT

                        Case Else ' throw an error for stuff we are not handling
                            Error ERROR_FEATURE_UNAVAILABLE

                    End Select

                Case ANSI_STATE_END ' exit loop if end state was set
                    Exit For

                Case Else
                    Error ERROR_CANNOT_CONTINUE ' this should never happen

            End Select

            If nCPS > 0 Then Limit nCPS ' limit the loop speed if char/sec is a positive value
        Next

        ' Set stuff the way we found them
        If oldControlChr Then
            ControlChr Off
        Else
            ControlChr On
        End If

        Locate oldCursorY, oldCursorX
        Color oldForegroundColor, oldBackgroundColor

        Select Case oldPrintMode
            Case 1
                PrintMode KeepBackground
            Case 2
                PrintMode OnlyBackground
            Case 3
                PrintMode FillBackground
        End Select

        If oldBlink Then
            Blink On
        Else
            Blink Off
        End If

        ColorTableData:
        Data 0,4,2,6,1,5,3,7
    End Sub
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

