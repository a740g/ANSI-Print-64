'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI emulator demo
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'include/CRTLib.bi'
'$Include:'include/FileOps.bi'
'$Include:'include/Base64.bi'
'$Include:'include/ANSIPrint.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$NoPrefix
$Color:32
$Resize:Smooth
$ExeIcon:'./ANSIPrint64.ico'
$VersionInfo:CompanyName=Samuel Gomes
$VersionInfo:FileDescription=ANSI Print 64 executable
$VersionInfo:InternalName=ANSIPrint64
$VersionInfo:LegalCopyright=Copyright (c) 2023, Samuel Gomes
$VersionInfo:LegalTrademarks=All trademarks are property of their respective owners
$VersionInfo:OriginalFilename=ANSIPrint64.exe
$VersionInfo:ProductName=ANSI Print 64
$VersionInfo:Web=https://github.com/a740g
$VersionInfo:Comments=https://github.com/a740g
$VersionInfo:FILEVERSION#=1,3,5,0
$VersionInfo:PRODUCTVERSION#=1,3,5,0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
Const APP_NAME = "ANSI Print 64"
Const CANVAS_WIDTH_MAX = 240 ' max width of our text canvas
Const CANVAS_WIDTH_MIN = 40
Const CANVAS_HEIGHT_MAX = 67 ' max height of our text canvas
Const CANVAS_HEIGHT_MIN = 25
Const CANVAS_WIDTH_DEFAULT = 80 ' default width of our text canvas
Const CANVAS_HEIGHT_DEFAULT = 25 ' default height of our text canvas
Const CANVAS_FONT_DEFAULT = 16 ' default font that we want to use
Const ANSI_CPS_DEFAULT = 3600 ' default rendering speed
Const ANSI_CPS_MAX = 99999
Const ANSI_CPS_MIN = 0
Const UPDATES_PER_SECOND = 30
' Program events
Const EVENT_NONE = 0 ' idle
Const EVENT_QUIT = 1 ' user wants to quit
Const EVENT_CMDS = 2 ' process command line
Const EVENT_LOAD = 3 ' user want to load files
Const EVENT_DROP = 4 ' user dropped files
Const EVENT_DRAW = 5 ' draw next art
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
Dim Shared Canvas As Long ' a handle to the canvas image
Dim Shared CanvasSize As Vector2DType ' the width and height of our canvas in characters
Dim Shared CanvasFont As Long ' just holds the font type (not a font handle!)
Dim Shared ANSICPS As Long ' rendering speed (0 = no delay; 1 = 1 char / sec, 3600 = 3600 char / sec and so on)
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------------------------
ChDir StartDir$ ' Change to the directory specifed by the environment
ANSICPS = ANSI_CPS_DEFAULT ' set default speed
CanvasSize.x = CANVAS_WIDTH_DEFAULT ' set default width
CanvasSize.y = CANVAS_HEIGHT_DEFAULT ' set default height
CanvasFont = CANVAS_FONT_DEFAULT ' set default font
SetupCanvas ' set the initial window size
Title APP_NAME + " " + OS$ ' Set app title to the way it was
AllowFullScreen SquarePixels , Smooth ' Allow the program window to run fullscreen with Alt+Enter
AcceptFileDrop ' Enable drag and drop of files

Dim event As Byte: event = EVENT_CMDS ' defaults to command line event on program entry

' Event loop
Do
    Select Case event
        Case EVENT_QUIT
            Exit Do

        Case EVENT_CMDS
            event = DoCommandLine

        Case EVENT_LOAD
            event = DoSelectedFiles

        Case EVENT_DROP
            event = DoDroppedFiles

        Case Else
            event = DoWelcomeScreen
    End Select
Loop

System
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
' Automatically sets up the window size based on globals
Sub SetupCanvas
    ' Free any old canvas
    If Canvas < -1 Then
        Screen 0
        FreeImage Canvas
        Canvas = 0
    End If

    Canvas = NewImage(8 * CanvasSize.x, CanvasFont * CanvasSize.y * (1 - (CanvasFont = 8)), 32) ' 8 is the built-in font width
    Screen Canvas ' make the canvas the default screen
    Font CanvasFont ' set the current font
    Locate , , FALSE ' turn cursor off
End Sub


' Welcome screen loop
Function DoWelcomeScreen%%
    ' Allocate and setup the welcome screen
    Dim As Long img: img = NewImage(80 * 8, 16 * 25, 32)
    Screen img

    ' Load the ANSI art data
    Restore Data_ANSIPrint_ans_3569
    Dim As String buffer: buffer = LoadResource

    ' Render the ANSI art
    PrintANSI buffer

    ' Get into a loop and check for input
    Dim k As Long, e As Byte
    Do
        k = KeyHit

        If k = KEY_ESCAPE Then
            e = EVENT_QUIT

        ElseIf TotalDroppedFiles > 0 Then
            e = EVENT_DROP

        ElseIf k = KEY_F1 Then
            e = EVENT_LOAD

        ElseIf k = KEY_UPPER_F Or k = KEY_LOWER_F Then
            CanvasFont = 24 - CanvasFont ' toggle between 16 and 8

        ElseIf k = KEY_UP_ARROW Then
            CanvasSize.y = CanvasSize.y + 1
            If CanvasSize.y > CANVAS_HEIGHT_MAX Then CanvasSize.y = CANVAS_HEIGHT_MAX

        ElseIf k = KEY_DOWN_ARROW Then
            CanvasSize.y = CanvasSize.y - 1
            If CanvasSize.y < CANVAS_HEIGHT_MIN Then CanvasSize.y = CANVAS_HEIGHT_MIN

        ElseIf k = KEY_LEFT_ARROW Then
            CanvasSize.x = CanvasSize.x - 1
            If CanvasSize.x < CANVAS_WIDTH_MIN Then CanvasSize.x = CANVAS_WIDTH_MIN

        ElseIf k = KEY_RIGHT_ARROW Then
            CanvasSize.x = CanvasSize.x + 1
            If CanvasSize.x > CANVAS_WIDTH_MAX Then CanvasSize.x = CANVAS_WIDTH_MAX

        ElseIf k = KEY_PLUS Or k = KEY_EQUALS Then
            ANSICPS = ANSICPS + 10
            If ANSICPS > ANSI_CPS_MAX Then ANSICPS = ANSI_CPS_MAX

        ElseIf k = KEY_MINUS Or k = KEY_UNDERSCORE Then
            ANSICPS = ANSICPS - 10
            If ANSICPS < ANSI_CPS_MIN Then ANSICPS = ANSI_CPS_MIN

        End If

        Color Yellow, Purple
        Locate 15, 56: Print Using "##"; CanvasFont
        Locate 17, 58: Print Using "##"; CanvasSize.y
        Locate 19, 57: Print Using "###"; CanvasSize.x
        Locate 21, 57: Print Using "#####"; ANSICPS

        Limit UPDATES_PER_SECOND
    Loop While e = EVENT_NONE

    ' Free screen image
    Screen 0
    FreeImage img

    DoWelcomeScreen = e

    Data_ANSIPrint_ans_3569:
    Data 3569,1044,-1
    Data eJytVs2PmkAU1/TWZO9NvUxP1Wy2ooAeOFnFlUTRCq5NNKGm2W2alt1ka2/8p27Cv9L3ZoZh+Ia2zygw
    Data b3y/D94MdA6KTzqHgaHq/kvnoKr+y/+MDpS/eh0BXPCSQNDroe/huUe/HgThXzrMM/FRSqQDeI9Y8SwW
    Data h+qTIyEB/ASkj6UCQAqw9JGCd70eHiALCcITjA/hxNhlGZaA8igOOQIe/geOARbuweB7gKYHHGXn9MP+
    Data BMNf6Am7LMaKoXh9VAfnCBEgfa+PZUkQf6iugCJiWkp18W8FWAgCk0GMd/RQD6J4feogFKIF8cejtY9U
    Data EZ1BpfNhnoLBAhTdUDVDGzTtPahjQAmNlxgYmlZags8v7JXiyNYqnU7r1oVhzGCGYmhjX1DVFP+SCRiW
    Data pih+PpO68CncAsz8iJgwFo3h08i6oUVZfpc4FUj5bEzHMV4fVwC05nwAB7ocePoDRpQf+6vd0rVuHHNp
    Data Tl0yt5amky4uiajPP0E+co0RbRZJNoKPRKeCi8xEun0Rl2x93U96KXYt05mWe2mbn13Ylz7tLDdRVuhO
    Data gwk9Qk65mAvTkpLwb4byUnBdBZ9BR1MIsyQHRG5GnDkPHsrtm69tlyxM63Yh2ccna353MOpxAkUqhI5m
    Data MmqbSBdUpZ11OIRxU4bS6jBYfWFpno27DbTYbL23yWS7Xe/LLZ1O7LuJI0xl9ysydKT1CnykTRki1bCq
    Data JXOUlHZGI3dzF3/Eq3ITylLjNzvP1qU5x7W7RaMaOLu3Zu4ibexQj1uVq8r4nJRS54kQFjTNX7ZvaocS
    Data bEKRr/GEDBOkwsTjUd5hdbFsqdnXwU25u1vTnplb4mxMc5a3F4x0XUWP4wzHRwGhLLnuW0ZKSUpLUXDc
    Data HOSG8DGLMMMkGRwpzKIVg4JpOr48htyxxq+RpRG/sb6drle2a5Ffv7/+IKczOT2f31W2ZSacyW5qKsrE
    Data dqzN8/fHM5nd+0+5M09jTfmWGls+Pd7vn34+yGNDZagqQ0W7vmq12u1N600Lo/3K+rgid7eTVjL+AE5A
    Data qkw=
End Function


' Initializes, loads and plays a mod file
' Also checks for input, shows info etc
Function DoFileDraw%% (fileName As String)
    DoFileDraw = EVENT_DRAW ' default event is to draw next file

    If Not FileExists(fileName) Then
        MessageBox APP_NAME, "Failed to load: " + fileName, "error"

        Exit Function
    End If

    SetupCanvas ' setup the canvas to draw on

    ' Set the app title to display the file name
    Title APP_NAME + " - " + GetFileNameFromPathOrURL(fileName)

    Dim fh As Long: fh = FreeFile
    Open fileName For Binary Access Read As fh

    Color DarkGray, Black ' reset the foregound and background colors
    Cls ' this will reset the cursor to 1, 1
    ResetANSIEmulator
    SetANSIEmulationSpeed ANSICPS
    Dim dummy As Long: dummy = PrintANSIString(Input$(LOF(fh), fh)) ' print and ignore return value

    Close fh

    Title APP_NAME + " - [ESC to EXIT] - " + GetFileNameFromPathOrURL(fileName)

    Dim As Long k

    Do
        k = KeyHit

        If TotalDroppedFiles > 0 Then
            DoFileDraw = EVENT_DROP
            Exit Do
        ElseIf k = 21248 Then ' Shift + Delete - you known what it does
            If MessageBox(APP_NAME, "Are you sure you want to delete " + fileName + " permanently?", "yesno", "question", 0) = 1 Then
                Kill fileName
                Exit Do
            End If
        End If

        Limit UPDATES_PER_SECOND
    Loop Until k = KEY_ESCAPE

    Title APP_NAME + " " + OS$ ' Set app title to the way it was
End Function


' Processes the command line one file at a time
Function DoCommandLine%%
    Dim e As Byte: e = EVENT_NONE

    If GetProgramArgumentIndex(KEY_QUESTION_MARK) > 0 Then
        MessageBox APP_NAME, APP_NAME + Chr$(KEY_ENTER) + _
            "Syntax: ANSIPrintDemo [ansi_art.ans]" + Chr$(KEY_ENTER) + _
            "  -w x: Text canvas width" + Chr$(KEY_ENTER) + _
            "  -h x: Text canvas height" + Chr$(KEY_ENTER) + _
            "  -f x: Font height" + Chr$(KEY_ENTER) + _
            "  -s x: Characters / second" + Chr$(KEY_ENTER) + _
            "    -?: Shows this message" + String$(2, KEY_ENTER) + _
            "Copyright (c) 2023, Samuel Gomes" + String$(2, KEY_ENTER) + _
            "https://github.com/a740g/", "info"

        e = EVENT_QUIT
    Else
        Dim argName As Integer
        Dim argIndex As Long: argIndex = 1 ' start with the first argument

        Do
            argName = ToLower(GetProgramArgument("whfs", argIndex))

            Select Case argName
                Case -1 ' no more arguments
                    Exit Do

                Case KEY_LOWER_W ' w
                    argIndex = argIndex + 1 ' value at next index
                    CanvasSize.x = ClampLong(Val(Command$(argIndex)), CANVAS_WIDTH_MIN, CANVAS_WIDTH_MAX)

                Case KEY_LOWER_H ' h
                    argIndex = argIndex + 1 ' value at next index
                    CanvasSize.y = ClampLong(Val(Command$(argIndex)), CANVAS_HEIGHT_MIN, CANVAS_HEIGHT_MAX)

                Case KEY_LOWER_F ' f
                    argIndex = argIndex + 1 ' value at next index
                    CanvasFont = Val(Command$(argIndex))
                    If CanvasFont <> 8 Then CanvasFont = 16

                Case KEY_LOWER_S ' s
                    argIndex = argIndex + 1 ' value at next index
                    ANSICPS = ClampLong(Val(Command$(argIndex)), ANSI_CPS_MIN, ANSI_CPS_MAX)

                Case Else ' probably a file name
                    e = DoFileDraw(Command$(argIndex))
                    If e <> EVENT_DRAW Then Exit Do

            End Select

            argIndex = argIndex + 1 ' move to the next index
        Loop Until argName = -1
    End If

    DoCommandLine = e
End Function


' Processes dropped files one file at a time
Function DoDroppedFiles%%
    ' Make a copy of the dropped file and clear the list
    ReDim fileNames(1 To TotalDroppedFiles) As String
    Dim i As Unsigned Long
    Dim e As Byte: e = EVENT_NONE

    For i = 1 To TotalDroppedFiles
        fileNames(i) = DroppedFile(i)
    Next
    FinishDrop ' This is critical

    ' Now play the dropped file one at a time
    For i = LBound(fileNames) To UBound(fileNames)
        e = DoFileDraw(fileNames(i))
        If e <> EVENT_DRAW Then Exit For
    Next

    DoDroppedFiles = e
End Function


' Processes a list of files selected by the user
Function DoSelectedFiles%%
    Dim ofdList As String
    Dim e As Byte: e = EVENT_NONE

    ofdList = OpenFileDialog$(APP_NAME, NULLSTRING, "*.ans|*.ANS|*.asc|*.ASC|*.diz|*.DIZ|*.nfo|*.NFO|*.txt|*.TXT", "ANSI Art Files", TRUE)
    If ofdList = NULLSTRING Then Exit Function

    ReDim fileNames(0 To 0) As String
    Dim As Long i, j

    j = TokenizeString(ofdList, "|", NULLSTRING, FALSE, fileNames())

    For i = 0 To j - 1
        e = DoFileDraw(fileNames(i))
        If e <> EVENT_DRAW Then Exit For
    Next

    DoSelectedFiles = e
End Function
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'include/ProgramArgs.bas'
'$Include:'include/FileOps.bas'
'$Include:'include/StringOps.bas'
'$Include:'include/Base64.bas'
'$Include:'include/ANSIPrint.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
