'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI emulator demo
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./include/ANSIPrint.bi'
'$Include:'./include/Base64.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
Const APP_NAME = "ANSIPrint Demo"
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
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------
Dim Shared Canvas As Long ' a handle to the canvas image
Dim Shared CanvasWidth As Long ' the width of our window in characters
Dim Shared CanvasHeight As Long ' the height of our window in characters
Dim Shared CanvasFont As Long ' just holds the font type (not a font handle!)
Dim Shared ANSICPS As Long ' rendering speed
'-----------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
ChDir StartDir$ ' Change to the directory specifed by the environment
ANSICPS = ANSI_CPS_DEFAULT ' set default speed
CanvasWidth = CANVAS_WIDTH_DEFAULT ' set default width
CanvasHeight = CANVAS_HEIGHT_DEFAULT ' set default height
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
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' Automatically sets up the window size based on globals
Sub SetupCanvas
    ' Free any old canvas
    If Canvas < -1 Then
        Screen 0
        FreeImage Canvas
        Canvas = 0
    End If

    Canvas = NewImage(8 * CanvasWidth, CanvasFont * CanvasHeight * (1 - (CanvasFont = 8)), 32) ' 8 is the built-in font width
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
            CanvasHeight = CanvasHeight + 1
            If CanvasHeight > CANVAS_HEIGHT_MAX Then CanvasHeight = CANVAS_HEIGHT_MAX

        ElseIf k = KEY_DOWN_ARROW Then
            CanvasHeight = CanvasHeight - 1
            If CanvasHeight < CANVAS_HEIGHT_MIN Then CanvasHeight = CANVAS_HEIGHT_MIN

        ElseIf k = KEY_LEFT_ARROW Then
            CanvasWidth = CanvasWidth - 1
            If CanvasWidth < CANVAS_WIDTH_MIN Then CanvasWidth = CANVAS_WIDTH_MIN

        ElseIf k = KEY_RIGHT_ARROW Then
            CanvasWidth = CanvasWidth + 1
            If CanvasWidth > CANVAS_WIDTH_MAX Then CanvasWidth = CANVAS_WIDTH_MAX

        ElseIf k = KEY_PLUS Or k = KEY_EQUALS Then
            ANSICPS = ANSICPS + 10
            If ANSICPS > ANSI_CPS_MAX Then ANSICPS = ANSI_CPS_MAX

        ElseIf k = KEY_MINUS Or k = KEY_UNDERSCORE Then
            ANSICPS = ANSICPS - 10
            If ANSICPS < ANSI_CPS_MIN Then ANSICPS = ANSI_CPS_MIN

        End If

        Color Yellow, Purple
        Locate 15, 56: Print Using "##"; CanvasFont
        Locate 17, 58: Print Using "##"; CanvasHeight
        Locate 19, 57: Print Using "###"; CanvasWidth
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

    SetupCanvas ' setup the canvas to draw on

    ' Set the app title to display the file name
    Title APP_NAME + " - " + GetFileNameFromPath(fileName)

    Dim fh As Long: fh = FreeFile
    Open fileName For Binary Access Read As fh

    Color DarkGray, Black ' reset the foregound and background colors
    Cls ' this will reset the cursor to 1, 1
    ResetANSIEmulator
    SetANSIEmulationSpeed ANSICPS
    Dim dummy As Long: dummy = PrintANSIString(Input$(LOF(fh), fh)) ' print and ignore return value

    Close fh

    Title APP_NAME + " - [ESC to EXIT] - " + GetFileNameFromPath(fileName)

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
    Dim i As Unsigned Long
    Dim e As Byte: e = EVENT_NONE

    If (Command$(1) = "/?" Or Command$(1) = "-?") Then
        MessageBox APP_NAME, APP_NAME + Chr$(13) + "Syntax: ANSIPrintDemo [ansi_art.ans]" + Chr$(13) + "    /?: Shows this message" + String$(2, 13) + "Copyright (c) 2023, Samuel Gomes" + String$(2, 13) + "https://github.com/a740g/", "info"
        e = EVENT_QUIT
    Else
        For i = 1 To CommandCount
            e = DoFileDraw(Command$(i))
            If e <> EVENT_DRAW Then Exit For
        Next
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

    j = ParseOpenFileDialogList(ofdList, fileNames())

    For i = 0 To j - 1
        e = DoFileDraw(fileNames(i))
        If e <> EVENT_DRAW Then Exit For
    Next

    DoSelectedFiles = e
End Function


' This is a simple text parser that can take an input string from OpenFileDialog$ and spit out discrete filepaths in an array
' Returns the number of strings parsed
Function ParseOpenFileDialogList& (ofdList As String, ofdArray() As String)
    Dim As Long p, c
    Dim ts As String

    ReDim ofdArray(0 To 0) As String
    ts = ofdList

    Do
        p = InStr(ts, "|")

        If p = 0 Then
            ofdArray(c) = ts

            ParseOpenFileDialogList& = c + 1
            Exit Function
        End If

        ofdArray(c) = Left$(ts, p - 1)
        ts = Mid$(ts, p + 1)

        c = c + 1
        ReDim Preserve ofdArray(0 To c) As String
    Loop
End Function


' Gets the filename portion from a file path
Function GetFileNameFromPath$ (pathName As String)
    Dim i As Unsigned Long

    ' Retrieve the position of the first / or \ in the parameter from the
    For i = Len(pathName) To 1 Step -1
        If Asc(pathName, i) = KEY_SLASH Or Asc(pathName, i) = KEY_BACKSLASH Then Exit For
    Next

    ' Return the full string if pathsep was not found
    If i = 0 Then
        GetFileNameFromPath = pathName
    Else
        GetFileNameFromPath = Right$(pathName, Len(pathName) - i)
    End If
End Function
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./include/ANSIPrint.bas'
'$Include:'./include/Base64.bas'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

