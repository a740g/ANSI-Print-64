'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI emulator
' Copyright (c) 2023 Samuel Gomes
'
' https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
' https://en.wikipedia.org/wiki/ANSI_escape_code
' https://en.wikipedia.org/wiki/ANSI.SYS
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./Common.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If ANSIPRINT_BI = UNDEFINED Then
    $Let ANSIPRINT_BI = TRUE
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
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
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

