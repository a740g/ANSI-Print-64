' QB64 ANSI emulator
' https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
' https://en.wikipedia.org/wiki/ANSI_escape_code
' https://en.wikipedia.org/wiki/ANSI.SYS

' Replace with Common.bi once prototyping is done
$NoPrefix
DefLng A-Z
Option Explicit
Option ExplicitArray
Option Base 1
'$Static
$Resize:Smooth
Const FALSE = 0, TRUE = Not FALSE
Const NULL = 0
Const NULLSTRING = ""

Const ERROR_FEATURE_UNAVAILABLE = 73

' ANSI constants (not an exhaustive list; only ones that matter to us)
Const ANSI_BEL = 7 ' Terminal bell
Const ANSI_BS = 8 ' Backspace
Const ANSI_HT = 9 ' Horizontal TAB
Const ANSI_LF = 10 ' Linefeed (newline)
Const ANSI_VT = 11 ' Vertical TAB
Const ANSI_FF = 12 ' Formfeed (also: New page NP)
Const ANSI_CR = 13 ' Carriage return
Const ANSI_SUB = 26 ' End of file (Control-Z)
Const ANSI_ESC = 27 ' Escape character
Const ANSI_SP = 32 ' Space character
Const ANSI_SLASH = 47 ' Slash character
Const ANSI_0 = 48 ' Zero character
Const ANSI_9 = 57 ' Nine character
Const ANSI_SEMICOLON = 59 ' Semicolon character
Const ANSI_QUESTION_MARK = 63 ' Question mark character
Const ANSI_AT_SIGN = 64 ' At sign character
Const ANSI_TILDE = 126 ' Tilde character
Const ANSI_DEL = 127 ' Delete character
' ANSI escape sequence types
Const ANSI_ESC_SS2 = 78 ' Single Shift Two
Const ANSI_ESC_SS3 = 79 ' Single Shift Three
Const ANSI_ESC_DCS = 80 ' Device Control String
Const ANSI_ESC_SOS = 88 ' Start of String
Const ANSI_ESC_CSI = 91 ' Control Sequence Introducer
Const ANSI_ESC_ST = 92 ' String Terminator
Const ANSI_ESC_OSC = 93 ' Operating System Command
Const ANSI_ESC_PM = 94 ' Privacy Message
Const ANSI_ESC_APC = 95 ' Application Program Command
' ANSI CSI sequence types
Const ANSI_ESC_CSI_CUU = 65 ' Cursor Up
Const ANSI_ESC_CSI_CUD = 66 ' Cursor Down
Const ANSI_ESC_CSI_CUF = 67 ' Cursor Forward/Right
Const ANSI_ESC_CSI_CUB = 68 ' Cursor Back/Left
Const ANSI_ESC_CSI_CNL = 69 ' Cursor Next Line
Const ANSI_ESC_CSI_CPL = 70 ' Cursor Previous Line
Const ANSI_ESC_CSI_CHA = 71 ' Cursor Horizontal Absolute
Const ANSI_ESC_CSI_CUP = 72 ' Cursor Position
Const ANSI_ESC_CSI_ED = 74 ' Erase in Display
Const ANSI_ESC_CSI_EL = 75 ' Erase in Line
Const ANSI_ESC_CSI_IL = 76 ' ANSI.SYS: Insert line
Const ANSI_ESC_CSI_DL = 77 ' ANSI.SYS: Delete line
Const ANSI_ESC_CSI_SU = 83 ' Scroll Up
Const ANSI_ESC_CSI_SD = 84 ' Scroll Down
Const ANSI_ESC_CSI_HVP = 102 ' Horizontal Vertical Position
Const ANSI_ESC_CSI_SM = 104 ' ANSI.SYS: Set screen mode
Const ANSI_ESC_CSI_RM = 108 ' ANSI.SYS: Reset screen mode
Const ANSI_ESC_CSI_SGR = 109 ' Select Graphic Rendition
Const ANSI_ESC_CSI_DSR = 110 ' Device status report
Const ANSI_ESC_CSI_SCP = 115 ' Save Current Cursor Position
Const ANSI_ESC_CSI_RCP = 117 ' Restore Saved Cursor Position


Screen NewImage(640, 640, 12)

Do
    Dim ansFile As String: ansFile = OpenFileDialog$("Open", "", "*.ans", "ANSI Files")
    If Not FileExists(ansFile) Then Exit Do

    Dim fh As Long: fh = FreeFile
    Open ansFile For Binary Access Read As fh
    RenderANSI Input$(LOF(fh), fh), 1000 ' put a -ve number here for superfast rendering
    Close fh
    Title "Press any key to open another file...": Sleep 3600
Loop

System

' sStr - the ANSI stream to render
' nCPS - characters / second (bigger numbers means faster; -ve number to disable)
Sub RenderANSI (sStr As String, nCPS As Long)
    Dim As Long nSeqType, nCSIParam(1 To 4), i, ch, nCSIParamIndex, colorTable(0 To 7), isBold, tmp
    Dim sCSIParam(1 To 4) As String
    Dim As Long oldControlChr, oldCursorX, oldCursorY, oldForegroundColor, oldBackgroundColor, oldPrintMode, oldBlink

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
    Locate , 1, 1 ' reset cursor to the left of the screen. TODO: How do we check if the cursor is visible?
    Color 15, 0 ' reset the foreground and background color
    PrintMode FillBackground ' set the print mode to fill the character background
    Blink Off

    For i = 1 To Len(sStr)
        ch = Asc(sStr, i)

        If ch = ANSI_SUB Then ' handle EOF (usually put by SAUCE blocks) - TODO: This probably needs to improve
            Exit For ' exit loop
        ElseIf nSeqType = ANSI_ESC_SS2 Then
            Beep
        ElseIf nSeqType = ANSI_ESC_SS3 Then
            Beep
        ElseIf nSeqType = ANSI_ESC_DCS Then
            Beep
        ElseIf nSeqType = ANSI_ESC_SOS Then
            Beep
        ElseIf nSeqType = ANSI_ESC_CSI Then ' handle CSI sequence
            Select Case ch
                Case ANSI_0 To ANSI_QUESTION_MARK ' parameter bytes
                    Select Case ch
                        Case ANSI_0 To ANSI_9 ' Handle Sequence numeric parameters
                            sCSIParam(nCSIParamIndex) = sCSIParam(nCSIParamIndex) + Chr$(ch)

                        Case ANSI_SEMICOLON ' Handle Sequence parameters seperators
                            nCSIParamIndex = nCSIParamIndex + 1
                    End Select

                Case ANSI_SP To ANSI_SLASH ' intermediate bytes
                    'Select Case ch
                    'End Select

                Case ANSI_AT_SIGN To ANSI_TILDE ' final byte
                    Select Case ch
                        Case ANSI_ESC_CSI_SM ' Set screen mode
                            Beep

                        Case ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                            ' Handle stuff based on the number of parameters that we collected
                            If Len(sCSIParam(1)) > 0 And Len(sCSIParam(2)) > 0 And Len(sCSIParam(3)) > 0 Then ' 3 parameters
                                nCSIParam(1) = Val(sCSIParam(1))
                                nCSIParam(2) = Val(sCSIParam(2))
                                nCSIParam(3) = Val(sCSIParam(3))

                                ' Set styles
                                Select Case nCSIParam(1)
                                    Case 1
                                        isBold = TRUE

                                    Case 22
                                        isBold = FALSE

                                    Case Is >= 30
                                        Error ERROR_FEATURE_UNAVAILABLE
                                End Select

                                Select Case nCSIParam(2)
                                    Case 39 ' default forground color
                                        Color 15

                                    Case 30 To 37 ' foreground colors
                                        Color colorTable(nCSIParam(2) - 30)
                                        If isBold Then Color DefaultColor + 8

                                    Case 90 To 97 ' bright foreground colors
                                        Color colorTable(nCSIParam(2) - 82)
                                End Select

                                Select Case nCSIParam(3)
                                    Case 49 ' default background color
                                        Color , 0

                                    Case 40 To 47 ' background colors
                                        Color , colorTable(nCSIParam(3) - 40)
                                        If isBold Then Color , BackgroundColor + 8

                                    Case 100 To 107 ' bright background colors
                                        Color , colorTable(nCSIParam(3) - 92)
                                End Select
                            ElseIf Len(sCSIParam(1)) > 0 And Len(sCSIParam(2)) > 0 Then ' 2 parameters
                                nCSIParam(1) = Val(sCSIParam(1))
                                nCSIParam(2) = Val(sCSIParam(2))

                                ' Set styles
                                Select Case nCSIParam(1)
                                    Case 1
                                        isBold = TRUE

                                    Case 22
                                        isBold = FALSE

                                    Case 39 ' default forground color
                                        Color 15

                                    Case 49 ' default background color
                                        Color , 0

                                    Case 40 To 47 ' handle regular backgrounds
                                        Color , colorTable(nCSIParam(1) - 40)
                                        If isBold Then Color , BackgroundColor + 8

                                    Case 30 To 37 ' handle regular foreground
                                        Color colorTable(nCSIParam(1) - 30)
                                        If isBold Then Color DefaultColor + 8

                                    Case 90 To 97 ' bright foreground colors
                                        Color colorTable(nCSIParam(2) - 82)

                                    Case 100 To 107 ' bright background colors
                                        Color , colorTable(nCSIParam(2) - 92)
                                End Select

                                Select Case nCSIParam(2)
                                    Case 39 ' default forground color
                                        Color 15

                                    Case 30 To 37 ' foreground colors
                                        Color colorTable(nCSIParam(2) - 30)
                                        If isBold Then Color DefaultColor + 8

                                    Case 90 To 97 ' bright foreground colors
                                        Color colorTable(nCSIParam(2) - 82)

                                    Case 49 ' default background color
                                        Color , 0

                                    Case 40 To 47 ' background colors
                                        Color , colorTable(nCSIParam(2) - 40)
                                        If isBold Then Color , BackgroundColor + 8

                                    Case 100 To 107 ' bright background colors
                                        Color , colorTable(nCSIParam(2) - 92)
                                End Select
                            ElseIf Len(sCSIParam(1)) > 0 Then ' 1 parameter
                                nCSIParam(1) = Val(sCSIParam(1))

                                Select Case nCSIParam(1)
                                    Case 0 ' reset all modes (styles and colors)
                                        Color 15, 0
                                        isBold = FALSE

                                    Case 39 ' default forground color
                                        Color 15

                                    Case 30 To 37 ' foreground colors
                                        Color colorTable(nCSIParam(1) - 30)

                                    Case 90 To 97 ' bright foreground colors
                                        Color colorTable(nCSIParam(1) - 82)

                                    Case 49 ' default background color
                                        Color , 0

                                    Case 40 To 47 ' background colors
                                        Color , colorTable(nCSIParam(1) - 40)

                                    Case 100 To 107 ' bright background colors
                                        Color , colorTable(nCSIParam(1) - 92)
                                End Select
                            End If

                        Case ANSI_ESC_CSI_CUP ' Cursor position
                            If Len(sCSIParam(1)) > 0 Then ' check if we need to move to a specific location
                                Locate 1 + Val(sCSIParam(1)), 1 + Val(sCSIParam(2)) ' line #, column #
                            Else ' put the cursor to 1,1
                                Locate 1, 1
                            End If

                        Case ANSI_ESC_CSI_HVP ' Horizontal and vertical position
                            Locate 1 + Val(sCSIParam(1)), 1 + Val(sCSIParam(2)) ' line #, column #

                        Case ANSI_ESC_CSI_CUU ' Cursor up
                            Locate CsrLin - Val(sCSIParam(1))

                        Case ANSI_ESC_CSI_CUD ' Cursor down
                            Locate CsrLin + Val(sCSIParam(1))

                        Case ANSI_ESC_CSI_CUF ' Cursor forward
                            Locate , Pos(0) + Val(sCSIParam(1))

                        Case ANSI_ESC_CSI_CUB ' Cursor back
                            Locate , Pos(0) - Val(sCSIParam(1))

                        Case ANSI_ESC_CSI_CNL ' Cursor Next Line
                            Locate CsrLin + Val(sCSIParam(1)), 1

                        Case ANSI_ESC_CSI_CPL ' Cursor Previous Line
                            Locate CsrLin - Val(sCSIParam(1)), 1

                        Case ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                            Locate , 1 + Val(sCSIParam(1))
                    End Select

                    ' End of sequence
                    nSeqType = 0

                Case Else ' we were not expecting anything else so throw an error
                    Error ERROR_FEATURE_UNAVAILABLE
            End Select
        ElseIf nSeqType = ANSI_ESC_OSC Then
            Beep
        ElseIf nSeqType = ANSI_ESC_PM Then
            Beep
        ElseIf nSeqType = ANSI_ESC_APC Then
            Beep
        ElseIf nSeqType = ANSI_ESC Then ' Handle escape sequence and stuff that must be escaped
            Select Case ch
                Case Is < ANSI_SP ' handle escaped character
                    ControlChr Off
                    Print Chr$(ch); ' print escaped ESC character
                    ControlChr On
                    nSeqType = 0

                Case ANSI_SP, ANSI_ESC_ST ' Ignore these

                Case ANSI_ESC_SS2
                    nSeqType = ANSI_ESC_SS2

                Case ANSI_ESC_SS3
                    nSeqType = ANSI_ESC_SS3

                Case ANSI_ESC_DCS
                    nSeqType = ANSI_ESC_DCS

                Case ANSI_ESC_SOS
                    nSeqType = ANSI_ESC_SOS

                Case ANSI_ESC_CSI
                    nSeqType = ANSI_ESC_CSI
                    nCSIParamIndex = 1 ' Reset parameter index
                    sCSIParam(1) = NULLSTRING ' reset the control sequence parameter
                    sCSIParam(2) = NULLSTRING ' reset the control sequence parameter
                    sCSIParam(3) = NULLSTRING ' reset the control sequence parameter
                    sCSIParam(4) = NULLSTRING ' reset the control sequence parameter

                Case ANSI_ESC_OSC
                    nSeqType = ANSI_ESC_OSC

                Case ANSI_ESC_PM
                    nSeqType = ANSI_ESC_PM

                Case ANSI_ESC_APC
                    nSeqType = ANSI_ESC_APC

                Case Else ' we were not expecting anything else so throw an error
                    Error ERROR_FEATURE_UNAVAILABLE
            End Select
        Else ' Handle normal characters (including some control characters)
            Select Case ch
                Case ANSI_BEL ' Handle Bell - because QB64 does not (even with ControlChr On)
                    'Print Chr$(ch); ' TODO: do we need to print?
                    Beep

                Case ANSI_BS ' Handle Backspace - because QB64 does not (even with ControlChr On)
                    tmp = Pos(0) ' save old x pos
                    If tmp > 1 Then Locate , tmp - 1 ' move to the left only if we are not on the edge

                Case ANSI_LF ' Handle Line Feed because QB64 screws this up - moves the cursor to the beginning of the next line
                    tmp = Pos(0) ' save old x pos
                    Print Chr$(ch); ' use QB64 to handle the LF and then correct the mistake
                    Locate , tmp ' set the cursor to the old x pos

                Case ANSI_FF ' Handle Form Feed - because QB64 does not (even with ControlChr On)
                    Locate 1, 1

                Case ANSI_CR ' Handle Carriage Return because QB64 screws this up - moves the cursor to the beginning of the next line
                    Locate , 1

                    ' TODO: Check what to do with > Case ANSI_DEL

                Case ANSI_ESC ' Handle Escape Sequence
                    nSeqType = ANSI_ESC ' beginning a new escape sequence

                Case Else
                    Print Chr$(ch);
            End Select
        End If

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

