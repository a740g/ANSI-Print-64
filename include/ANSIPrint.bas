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
    Screen NewImage(8 * 80, 800, 32)

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
        Static colorLUTInitialized As Long ' if this is true then the legacy color table has been initialized

        Dim As Long state ' the current parser state
        Dim As Long i, ch ' the current character index and the character
        ReDim arg(1 To ANSI_ARG_COUNT) As Long ' CSI argument list
        Dim As Long argIndex ' the current CSI argument index; 0 means no arguments
        Dim As Long leadInPrefix ' the type of lead-in prefix that was specified; this can help diffrentiate what the argument will be used for
        Dim As Long isBold, isBlink, isInvert ' text attributes
        Dim As Long x, y, z ' temp variables used in many places (usually as counters / index)
        Dim As Long fc, bc ' legacy foreground and background colors
        Dim As Long sX, sY ' saved cursor position
        ' The variables below are used to save various things that are restored before the function exits
        Dim As Long oldControlChr, oldCursorX, oldCursorY, oldPrintMode
        Dim As Unsigned Long oldForegroundColor, oldBackgroundColor

        ' We only support rendering to 32bpp images
        If PixelSize < 4 Then Error ERROR_FEATURE_UNAVAILABLE

        ' Setup legacy color LUT if needed
        If Not colorLUTInitialized Then
            InitializeANSIColorLUT
            colorLUTInitialized = TRUE
        End If

        ' Save some stuff that we might be changing
        oldPrintMode = PrintMode
        oldControlChr = ControlChr
        oldCursorX = Pos(0)
        oldCursorY = CsrLin
        oldForegroundColor = DefaultColor
        oldBackgroundColor = BackgroundColor

        ' Now we are free to change whatever we saved above
        PrintMode FillBackground ' set the print mode to fill the character background
        ControlChr On ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)
        Locate , 1, 0 ' reset cursor to the left of the screen
        sX = Pos(0)
        sY = CsrLin
        ' Reset the foreground and background color
        fc = ANSI_DEFAULT_COLOR_FOREGROUND
        SetColor fc, FALSE, TRUE
        bc = ANSI_DEFAULT_COLOR_BACKGROUND
        SetColor bc, TRUE, TRUE

        state = ANSI_STATE_TEXT ' we will start parsing regular text by default

        For i = 1 To Len(sANSI)
            ch = Asc(sANSI, i)

            Select Case state
                Case ANSI_STATE_TEXT ' handle normal characters (including some control characters)
                    Select Case ch
                        Case ANSI_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
                            state = ANSI_STATE_END

                        Case ANSI_BEL ' handle Bell - because QB64 does not (even with ControlChr On)
                            Beep

                        Case ANSI_BS ' handle Backspace - because QB64 does not (even with ControlChr On)
                            x = Pos(0) ' save old x pos
                            If x > 1 Then Locate , x - 1 ' move to the left only if we are not on the edge

                        Case ANSI_LF ' handle Line Feed because QB64 screws this up - moves the cursor to the beginning of the next line
                            x = Pos(0) ' save old x pos
                            Print Chr$(ch); ' use QB64 to handle the LF and then correct the mistake
                            Locate , x ' set the cursor to the old x pos

                        Case ANSI_FF ' handle Form Feed - because QB64 does not (even with ControlChr On)
                            Locate 1, 1

                        Case ANSI_CR ' handle Carriage Return because QB64 screws this up - moves the cursor to the beginning of the next line
                            Locate , 1

                            'Case ANSI_DEL ' TODO: Check what to do with this

                        Case ANSI_ESC ' handle escape character
                            state = ANSI_STATE_BEGIN ' beginning a new escape sequence

                        Case Else ' print the character
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
                            ReDim arg(1 To ANSI_ARG_COUNT) As Long ' reset the control sequence arguments
                            argIndex = 0 ' reset argument index
                            leadInPrefix = 0 ' reset lead-in prefix
                            state = ANSI_STATE_SEQUENCE

                        Case Else ' throw an error for stuff we are not handling
                            Error ERROR_FEATURE_UNAVAILABLE

                    End Select

                Case ANSI_STATE_SEQUENCE ' handle ESC sequence
                    Select Case ch
                        Case ANSI_0 To ANSI_QUESTION_MARK ' argument bytes
                            If argIndex < 1 Then argIndex = 1 ' set the argument index to one if this is the first time

                            Select Case ch
                                Case ANSI_0 To ANSI_9 ' handle sequence numeric arguments
                                    arg(argIndex) = arg(argIndex) * 10 + ch - ANSI_0

                                Case ANSI_SEMICOLON ' handle sequence argument seperators
                                    argIndex = argIndex + 1 ' increment the argument index

                                Case ANSI_EQUALS_SIGN, ANSI_GREATER_THAN_SIGN, ANSI_QUESTION_MARK ' handle lead-in prefix
                                    leadInPrefix = ch ' just save the prefix type

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
                                    Select Case argIndex
                                        Case 1
                                            Select Case arg(1)
                                                Case 0 To 6, 14 To 18 ' all mode changes are ignored. the screen type must be set by the caller
                                                    ' NOP

                                                Case 7 ' Enable / disable line wrapping
                                                    ' NOP: QB64 does line wrapping by default
                                                    If ANSI_ESC_CSI_RM = ch Then ' ANSI_ESC_CSI_RM disable line wrapping unsupported
                                                        Error ERROR_FEATURE_UNAVAILABLE
                                                    End If

                                                Case 25 ' make cursor visible / invisible
                                                    If ANSI_ESC_CSI_SM = ch Then ' ANSI_ESC_CSI_SM make cursor visible
                                                        Locate , , 1
                                                    Else ' ANSI_ESC_CSI_RM make cursor invisible
                                                        Locate , , 0
                                                    End If

                                                Case Else ' throw an error for stuff we are not handling
                                                    Error ERROR_FEATURE_UNAVAILABLE

                                            End Select

                                        Case Else ' this should never happen
                                            Error ERROR_CANNOT_CONTINUE

                                    End Select

                                Case ANSI_ESC_CSI_ED ' Erase in Display
                                    Select Case argIndex
                                        Case 1
                                            Select Case arg(1)
                                                Case 2 ' erase entire screen
                                                    Cls ' this will also position the cursor to 1, 1

                                                Case Else ' throw an error for stuff we are not handling
                                                    Error ERROR_FEATURE_UNAVAILABLE

                                            End Select

                                        Case Else ' this should never happen
                                            Error ERROR_CANNOT_CONTINUE

                                    End Select

                                Case ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                                    x = 1 ' start with the first argument
                                    Do While x <= argIndex ' loop through the argument list and process each argument
                                        Select Case arg(x)
                                            Case 0 ' reset all modes (styles and colors)
                                                fc = ANSI_DEFAULT_COLOR_FOREGROUND
                                                bc = ANSI_DEFAULT_COLOR_BACKGROUND
                                                isBold = FALSE
                                                isBlink = FALSE
                                                isInvert = FALSE
                                                SetColor fc, isInvert, TRUE
                                                SetColor bc, Not isInvert, TRUE

                                            Case 1 ' enable high intensity colors
                                                If fc < 8 Then fc = fc + 8
                                                isBold = TRUE
                                                SetColor fc, isInvert, TRUE

                                            Case 2, 22 ' enable low intensity, disable high intensity colors
                                                If fc > 7 Then fc = fc - 8
                                                isBold = FALSE
                                                SetColor fc, isInvert, TRUE

                                            Case 5, 6 ' turn blinking on
                                                If bc < 8 Then bc = bc + 8
                                                isBlink = TRUE
                                                SetColor bc, Not isInvert, TRUE

                                            Case 7 ' enable reverse video
                                                If Not isInvert Then
                                                    isInvert = TRUE
                                                    SetColor fc, isInvert, TRUE
                                                    SetColor bc, Not isInvert, TRUE
                                                End If

                                            Case 25 ' turn blinking off
                                                If bc > 7 Then bc = bc - 8
                                                isBlink = FALSE
                                                SetColor bc, Not isInvert, TRUE

                                            Case 27 ' disable reverse video
                                                If isInvert Then
                                                    isInvert = FALSE
                                                    SetColor fc, isInvert, TRUE
                                                    SetColor bc, Not isInvert, TRUE
                                                End If

                                            Case 30 To 37 ' set foreground color
                                                fc = arg(x) - 30
                                                If isBold Then fc = fc + 8
                                                SetColor fc, isInvert, TRUE

                                            Case 38 ' set 8-bit 256 or 24-bit RGB foreground color
                                                Error ERROR_FEATURE_UNAVAILABLE

                                            Case 39 ' set default foreground color
                                                fc = ANSI_DEFAULT_COLOR_FOREGROUND
                                                SetColor fc, isInvert, TRUE

                                            Case 40 To 47 ' set background color
                                                bc = arg(x) - 40
                                                If isBlink Then bc = bc + 8
                                                SetColor bc, Not isInvert, TRUE

                                            Case 48 ' set 8-bit 256 or 24-bit RGB background color
                                                Error ERROR_FEATURE_UNAVAILABLE

                                            Case 49 ' set default background color
                                                bc = ANSI_DEFAULT_COLOR_BACKGROUND
                                                SetColor bc, Not isInvert, TRUE

                                            Case 90 To 97 ' set high intensity foreground color
                                                fc = 8 + arg(x) - 90
                                                SetColor fc, isInvert, TRUE

                                            Case 100 To 107 ' set high intensity background color
                                                bc = 8 + arg(x) - 100
                                                SetColor bc, Not isInvert, TRUE

                                            Case Else ' throw an error for stuff we are not handling
                                                Error ERROR_FEATURE_UNAVAILABLE

                                        End Select

                                        x = x + 1 ' move to the next argument
                                    Loop

                                Case ANSI_ESC_CSI_SCP ' Save Current Cursor Position
                                    sX = Pos(0)
                                    sY = CsrLin

                                Case ANSI_ESC_CSI_RCP ' Restore Saved Cursor Position
                                    Locate sY, sX

                                Case ANSI_ESC_CSI_PABLODRAW_24BPP ' PabloDraw 24-bit ANSI sequences
                                    If 4 = argIndex Then ' we need 4 arguments
                                        If Not arg(1) Then ' foreground
                                            SetColor RGB32(arg(2) And &HFF, arg(3) And &HFF, arg(4) And &HFF), FALSE, FALSE
                                        Else ' background
                                            SetColor RGB32(arg(2) And &HFF, arg(3) And &HFF, arg(4) And &HFF), TRUE, FALSE
                                        End If

                                    Else ' malformed sequence
                                        Error ERROR_CANNOT_CONTINUE

                                    End If

                                Case ANSI_ESC_CSI_CUP, ANSI_ESC_CSI_HVP ' Cursor position or Horizontal and vertical position
                                    x = TextCanvasWidth
                                    If arg(1) < 1 Then
                                        arg(1) = 1
                                    ElseIf arg(1) > x Then
                                        arg(1) = x
                                    End If
                                    y = TextCanvasHeight
                                    If arg(2) < 1 Then
                                        arg(2) = 1
                                    ElseIf arg(2) > y Then
                                        arg(2) = y
                                    End If
                                    Locate arg(1), arg(2) ' line #, column #

                                Case ANSI_ESC_CSI_CUU ' Cursor up
                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin - arg(1)
                                    If y < 1 Then arg(1) = 1
                                    Locate y

                                Case ANSI_ESC_CSI_CUD ' Cursor down
                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin + arg(1)
                                    z = TextCanvasHeight
                                    If y > z Then y = z
                                    Locate y

                                Case ANSI_ESC_CSI_CUF ' Cursor forward
                                    If arg(1) < 1 Then arg(1) = 1
                                    x = Pos(0) + arg(1)
                                    z = TextCanvasWidth
                                    If x > z Then x = z
                                    Locate , x

                                Case ANSI_ESC_CSI_CUB ' Cursor back
                                    If arg(1) < 1 Then arg(1) = 1
                                    x = Pos(0) - arg(1)
                                    If x < 1 Then x = 1
                                    Locate , x

                                Case ANSI_ESC_CSI_CNL ' Cursor Next Line
                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin + arg(1)
                                    z = TextCanvasHeight
                                    If y > z Then y = z
                                    Locate y, 1

                                Case ANSI_ESC_CSI_CPL ' Cursor Previous Line
                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin - arg(1)
                                    If y < 1 Then y = 1
                                    Locate y, 1

                                Case ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                                    x = TextCanvasWidth
                                    If arg(1) < 1 Then
                                        arg(1) = 1
                                    ElseIf arg(1) > x Then
                                        arg(1) = x
                                    End If
                                    Locate , arg(1)

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
    End Sub


    ' Set the foreground or background color
    Sub SetColor (c As Unsigned Long, isBackground As Long, isLegacy As Long)
        Shared ANSIColorLUT() As Unsigned Long

        Dim nRGB As Unsigned Long

        If isLegacy Then
            nRGB = ANSIColorLUT(c)
        Else
            nRGB = c
        End If

        If isBackground Then
            Color , nRGB
        Else
            Color nRGB
        End If
    End Sub


    ' Returns the number of characters per line
    Function TextCanvasWidth&
        TextCanvasWidth = Width \ FontWidth ' this will cause a divide by zero if a variable width font is used; use fixed width fonts instead
    End Function


    ' Returns the number of lines
    Function TextCanvasHeight&
        TextCanvasHeight = Height \ FontHeight
    End Function


    ' Initializes the ANSI legacy LUT
    Sub InitializeANSIColorLUT
        Shared ANSIColorLUT() As Unsigned Long

        ' The first 16 are the standard 16 ANSI colors
        ANSIColorLUT(0) = RGB32(0, 0, 0) '  0 black
        ANSIColorLUT(1) = RGB32(128, 0, 0) '  1 red
        ANSIColorLUT(2) = RGB32(0, 128, 0) '  2 green
        ANSIColorLUT(3) = RGB32(128, 128, 0) '  3 yellow
        ANSIColorLUT(4) = RGB32(0, 0, 128) '  4 blue
        ANSIColorLUT(5) = RGB32(128, 0, 128) '  5 magenta
        ANSIColorLUT(6) = RGB32(0, 128, 128) '  6 cyan
        ANSIColorLUT(7) = RGB32(192, 192, 192) '  7 white (light grey)
        ANSIColorLUT(8) = RGB32(128, 128, 128) '  8 grey
        ANSIColorLUT(9) = RGB32(255, 0, 0) '  9 bright red
        ANSIColorLUT(10) = RGB32(255, 255, 0) ' 10 bright green
        ANSIColorLUT(11) = RGB32(0, 255, 0) ' 11 bright yellow
        ANSIColorLUT(12) = RGB32(0, 0, 255) ' 12 bright blue
        ANSIColorLUT(13) = RGB32(255, 0, 255) ' 13 bright magenta
        ANSIColorLUT(14) = RGB32(0, 255, 255) ' 14 bright cyan
        ANSIColorLUT(15) = RGB32(255, 255, 255) ' 15 bright white

        Dim As Long c, i, r, g, b

        ' The next 216 colors (16-231) are formed by a 3bpc RGB value offset by 16, packed into a single value
        For c = 16 To 231
            i = ((c - 16) \ 36) Mod 6
            If i = 0 Then r = 0 Else r = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 6) Mod 6
            If i = 0 Then g = 0 Else g = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 1) Mod 6
            If i = 0 Then b = 0 Else b = (14135 + 10280 * i) \ 256

            ANSIColorLUT(c) = RGB32(r, g, b)
        Next

        ' The final 24 colors (232-255) are grayscale starting from a shade slighly lighter than black, ranging up to shade slightly darker than white
        For c = 232 To 255
            g = (2056 + 2570 * (c - 232)) \ 256
            ANSIColorLUT(c) = RGB32(g, g, g)
        Next
    End Sub
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

