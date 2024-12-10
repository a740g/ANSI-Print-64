'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI emulator demo
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/StringOps.bi'
'$INCLUDE:'include/Math/Math.bi'
'$INCLUDE:'include/Pathname.bi'
'$INCLUDE:'include/Base64.bi'
'$INCLUDE:'include/ANSIPrint.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$COLOR:32
$RESIZE:SMOOTH
$EXEICON:'./ANSIPrint64.ico'
$VERSIONINFO:CompanyName='Samuel Gomes'
$VERSIONINFO:FileDescription='ANSI Print 64 executable'
$VERSIONINFO:InternalName='ANSIPrint64'
$VERSIONINFO:LegalCopyright='Copyright (c) 2024, Samuel Gomes'
$VERSIONINFO:LegalTrademarks='All trademarks are property of their respective owners'
$VERSIONINFO:OriginalFilename='ANSIPrint64.exe'
$VERSIONINFO:ProductName='ANSI Print 64'
$VERSIONINFO:Web='https://github.com/a740g'
$VERSIONINFO:Comments='https://github.com/a740g'
$VERSIONINFO:FILEVERSION#=1,3,9,0
$VERSIONINFO:PRODUCTVERSION#=1,3,9,0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
CONST APP_NAME = "ANSI Print 64"
CONST CANVAS_WIDTH_MAX = 320 ' max width of our text canvas
CONST CANVAS_WIDTH_MIN = 1
CONST CANVAS_HEIGHT_MAX = 120 ' max height of our text canvas
CONST CANVAS_HEIGHT_MIN = 1
CONST CANVAS_WIDTH_DEFAULT = 80 ' default width of our text canvas
CONST CANVAS_HEIGHT_DEFAULT = 25 ' default height of our text canvas
CONST CANVAS_FONT_DEFAULT = 16 ' default font that we want to use
CONST ANSI_CPS_DEFAULT = 3600 ' default rendering speed
CONST ANSI_CPS_MAX = 99999
CONST ANSI_CPS_MIN = 0
CONST UPDATES_PER_SECOND = 30
' Program events
CONST EVENT_NONE = 0 ' idle
CONST EVENT_QUIT = 1 ' user wants to quit
CONST EVENT_CMDS = 2 ' process command line
CONST EVENT_LOAD = 3 ' user want to load files
CONST EVENT_DROP = 4 ' user dropped files
CONST EVENT_DRAW = 5 ' draw next art
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
DIM SHARED Canvas AS LONG ' a handle to the canvas image
DIM SHARED CanvasSize AS Vector2LType ' the width and height of our canvas in characters
DIM SHARED CanvasFont AS LONG ' just holds the font type (not a font handle!)
DIM SHARED ANSICPS AS LONG ' rendering speed (0 = no delay; 1 = 1 char / sec, 3600 = 3600 char / sec and so on)
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------------------------
CHDIR _STARTDIR$ ' Change to the directory specifed by the environment
ANSICPS = ANSI_CPS_DEFAULT ' set default speed
CanvasSize.x = CANVAS_WIDTH_DEFAULT ' set default width
CanvasSize.y = CANVAS_HEIGHT_DEFAULT ' set default height
CanvasFont = CANVAS_FONT_DEFAULT ' set default font
SetupCanvas ' set the initial window size
_TITLE APP_NAME + " " + _OS$ ' Set app title to the way it was
_ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH ' Allow the program window to run fullscreen with Alt+Enter
_ACCEPTFILEDROP ' Enable drag and drop of files

DIM event AS _BYTE: event = EVENT_CMDS ' defaults to command line event on program entry

' Event loop
DO
    SELECT CASE event
        CASE EVENT_QUIT
            EXIT DO

        CASE EVENT_CMDS
            event = OnCommandLine

        CASE EVENT_LOAD
            event = OnSelectedFiles

        CASE EVENT_DROP
            event = OnDroppedFiles

        CASE ELSE
            event = OnWelcomeScreen
    END SELECT
LOOP

SYSTEM
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
' Automatically sets up the window size based on globals
SUB SetupCanvas
    ' Free any old canvas
    IF Canvas < -1 THEN
        SCREEN 0
        _FREEIMAGE Canvas
        Canvas = 0
    END IF

    Canvas = _NEWIMAGE(8 * CanvasSize.x, CanvasFont * CanvasSize.y * (1 - (CanvasFont = 8)), 32) ' 8 is the built-in font width
    SCREEN Canvas ' make the canvas the default screen
    _FONT CanvasFont ' set the current font
    LOCATE , , _FALSE ' turn cursor off
END SUB


' Welcome screen loop
FUNCTION OnWelcomeScreen%%
    ' Allocate and setup the welcome screen
    DIM AS LONG img: img = _NEWIMAGE(80 * 8, 16 * 25, 32)
    SCREEN img

    ' Load the ANSI art data
    RESTORE Data_ANSIPrint_ans_3547
    DIM AS STRING buffer: buffer = Base64_LoadResourceData

    ' Render the ANSI art
    ANSI_Print buffer

    ' Get into a loop and check for input
    DIM k AS LONG, e AS _BYTE
    DO
        k = _KEYHIT

        IF k = _KEY_ESC THEN
            e = EVENT_QUIT

        ELSEIF _TOTALDROPPEDFILES > 0 THEN
            e = EVENT_DROP

        ELSEIF k = _KEY_F1 THEN
            e = EVENT_LOAD

        ELSEIF k = KEY_UPPER_F OR k = KEY_LOWER_F THEN
            CanvasFont = 24 - CanvasFont ' toggle between 16 and 8

        ELSEIF k = _KEY_UP THEN
            CanvasSize.y = CanvasSize.y + 1
            IF CanvasSize.y > CANVAS_HEIGHT_MAX THEN CanvasSize.y = CANVAS_HEIGHT_MAX

        ELSEIF k = _KEY_DOWN THEN
            CanvasSize.y = CanvasSize.y - 1
            IF CanvasSize.y < CANVAS_HEIGHT_MIN THEN CanvasSize.y = CANVAS_HEIGHT_MIN

        ELSEIF k = _KEY_LEFT THEN
            CanvasSize.x = CanvasSize.x - 1
            IF CanvasSize.x < CANVAS_WIDTH_MIN THEN CanvasSize.x = CANVAS_WIDTH_MIN

        ELSEIF k = _KEY_RIGHT THEN
            CanvasSize.x = CanvasSize.x + 1
            IF CanvasSize.x > CANVAS_WIDTH_MAX THEN CanvasSize.x = CANVAS_WIDTH_MAX

        ELSEIF k = KEY_PLUS OR k = KEY_EQUALS THEN
            ANSICPS = ANSICPS + 10
            IF ANSICPS > ANSI_CPS_MAX THEN ANSICPS = ANSI_CPS_MAX

        ELSEIF k = KEY_MINUS OR k = KEY_UNDERSCORE THEN
            ANSICPS = ANSICPS - 10
            IF ANSICPS < ANSI_CPS_MIN THEN ANSICPS = ANSI_CPS_MIN

        END IF

        COLOR Yellow, Purple
        LOCATE 15, 56: PRINT USING "##"; CanvasFont
        LOCATE 17, 58: PRINT USING "###"; CanvasSize.y
        LOCATE 19, 57: PRINT USING "###"; CanvasSize.x
        LOCATE 21, 57: PRINT USING "#####"; ANSICPS

        _LIMIT UPDATES_PER_SECOND
    LOOP WHILE e = EVENT_NONE

    ' Free screen image
    SCREEN 0
    _FREEIMAGE img

    OnWelcomeScreen = e

    Data_ANSIPrint_ans_3547:
    DATA 3547,984,-1
    DATA eNqsVkWiGzEMvUdRq3IbmklhNp8c5nym6ao732BOWvJVKjmKfqL6O6iAMY8y9PSmbOHpTSWrpfb305ta
    DATA zf7eZ3n4Of6v2YjHVZtTP/efHAv4QzNUSy0vBAtl1xlcUzFTCW4BCrjFT4mQCiQqCPnWc7/J31KDq7gA
    DATA vDCTA6zLD2NUwpR7GrhFOvoJtgXhvsXJ18hMjZ+lPr/8j2j6u+/44eNUwjSHJ2/YJwakwukSoc7BxVVB
    DATA hH55YekN/SxMRRy4F9DHbU5uiCQv4YeQiJNI/AA/aJZaLAyb98gSTYZJ0qyWZEnFbn5cZQiRMEQlSxK7
    DATA xv5woLH6HwoiRbhxFgXtd5Sz5LMVoUnZ/tKFCItbyr67NbuiVZTxYiEsYlN2TZxmyXyV/yFWgkt2NpfS
    DATA HMNb8Edlo4INTsryJ6r5+mfbP+udtj9OTc8cn0Kj3TPTBXDtYT35WjtnxjrXL+1U5IiauBQlRHSIFA3P
    DATA 80tJysXKTI/jSQ7M5SmUYHzWPhVYwQyRiR1xE/Xyy4+1g93iZCgcR9kD5BQJzAJRpQ9E2tkofsTDawwH
    DATA p9Ay7WZrITzenNg3lfpbFqBNaBsxFztE6M+lSJhrS3APB6TjA1LiBAk0GOLZCEpwMrwYwOFkMryIB3p8
    DATA ODg/nEqkBP8QZzWlPLV6OSAdSXVxHwEj+rDYIVsRF5AV1xVSxv90MNSeadBZO6GYNsj1on1y2grH6nWz
    DATA KW1EO4l78eUCQe9w6IogJcZtcFt0S5pElL6yStYc9fviYzzbiRmcmAlMR8achK4C9TStLRy4LJ/1u80f
    DATA LLQRsRIvplXEm7BrEU4J0cVETpNFOFNkpWdFx3FV/o2qfRWk9qmUs7+vX4inQnFpcrZCYolCYlGJogLJ
    DATA INgx1NnVwMDRL9gzoCgzr0TBJTU3H6vKRHMTg3Q0MZ/8vNTw/Jw0ZDEjAyNjA3Mjc1FeBgZGxgAGCQYQ
    DATA YGT2dPJVCHN3ZEAFAJ80q0I=
END FUNCTION


' Initializes, loads and renders an ANSI file
' Also checks for input, shows info etc
FUNCTION DoFileDraw%% (fileName AS STRING)
    DoFileDraw = EVENT_DRAW ' default event is to draw next file

    IF NOT _FILEEXISTS(fileName) THEN
        _MESSAGEBOX APP_NAME, "Failed to load: " + fileName, "error"

        EXIT FUNCTION
    END IF

    ' Read the contents of the whole file into memory
    DIM buffer AS STRING: buffer = _READFILE$(fileName)

    ' Check if the file has a SAUCE record and if so setup canvas properties using it
    IF SAUCE_IsPresent(buffer) THEN
        DIM sauce AS SAUCEType: SAUCE_Read buffer, sauce
        CanvasSize.x = ANSI_GetWidth(sauce)
        CanvasSize.y = ANSI_GetHeight(sauce)
        CanvasFont = ANSI_GetFontHeight(sauce)
    END IF

    ' Now setup the canvas to draw on
    SetupCanvas

    ' Set the app title to display the file name
    _TITLE APP_NAME + " - " + Pathname_GetFileName(fileName)

    COLOR DarkGray, Black ' reset the foregound and background colors
    CLS ' this will reset the cursor to 1, 1
    ANSI_ResetEmulator
    ANSI_SetEmulationSpeed ANSICPS
    DIM dummy AS _BYTE: dummy = ANSI_PrintString(buffer) ' print and ignore return value

    _TITLE APP_NAME + " - [ESC to EXIT] - " + Pathname_GetFileName(fileName)

    DIM AS LONG k

    DO
        k = _KEYHIT

        IF _TOTALDROPPEDFILES > 0 THEN
            DoFileDraw = EVENT_DROP
            EXIT DO
        ELSEIF k = 21248 THEN ' Shift + Delete - you known what it does
            IF _MESSAGEBOX(APP_NAME, "Are you sure you want to delete " + fileName + " permanently?", "yesno", "question", 0) = 1 THEN
                KILL fileName
                EXIT DO
            END IF
        END IF

        _LIMIT UPDATES_PER_SECOND
    LOOP UNTIL k = _KEY_ESC

    _TITLE APP_NAME + " " + _OS$ ' Set app title to the way it was
END FUNCTION


' Processes the command line one file at a time
FUNCTION OnCommandLine%%
    DIM e AS _BYTE: e = EVENT_NONE

    IF GetProgramArgumentIndex(KEY_QUESTION_MARK) > 0 THEN
        _MESSAGEBOX APP_NAME, APP_NAME + CHR$(_KEY_ENTER) + _
            "Syntax: ANSIPrintDemo [ansi_art.ans]" + CHR$(_KEY_ENTER) + _
            "  -w x: Text canvas width" + CHR$(_KEY_ENTER) + _
            "  -h x: Text canvas height" + CHR$(_KEY_ENTER) + _
            "  -f x: Font height" + CHR$(_KEY_ENTER) + _
            "  -s x: Characters / second" + CHR$(_KEY_ENTER) + _
            "    -?: Shows this message" + STRING$(2, _KEY_ENTER) + _
            "Copyright (c) 2024, Samuel Gomes" + STRING$(2, _KEY_ENTER) + _
            "https://github.com/a740g/", "info"

        e = EVENT_QUIT
    ELSE
        DIM argName AS INTEGER
        DIM argIndex AS LONG: argIndex = 1 ' start with the first argument

        DO
            argName = String_ToLowerCase(GetProgramArgument("whfs", argIndex))

            SELECT CASE argName
                CASE -1 ' no more arguments
                    EXIT DO

                CASE KEY_LOWER_W ' w
                    argIndex = argIndex + 1 ' value at next index
                    CanvasSize.x = Math_ClampLong(VAL(COMMAND$(argIndex)), CANVAS_WIDTH_MIN, CANVAS_WIDTH_MAX)

                CASE KEY_LOWER_H ' h
                    argIndex = argIndex + 1 ' value at next index
                    CanvasSize.y = Math_ClampLong(VAL(COMMAND$(argIndex)), CANVAS_HEIGHT_MIN, CANVAS_HEIGHT_MAX)

                CASE KEY_LOWER_F ' f
                    argIndex = argIndex + 1 ' value at next index
                    CanvasFont = VAL(COMMAND$(argIndex))
                    IF CanvasFont <> 8 THEN CanvasFont = 16

                CASE KEY_LOWER_S ' s
                    argIndex = argIndex + 1 ' value at next index
                    ANSICPS = Math_ClampLong(VAL(COMMAND$(argIndex)), ANSI_CPS_MIN, ANSI_CPS_MAX)

                CASE ELSE ' probably a file name
                    e = DoFileDraw(COMMAND$(argIndex))
                    IF e <> EVENT_DRAW THEN EXIT DO

            END SELECT

            argIndex = argIndex + 1 ' move to the next index
        LOOP UNTIL argName = -1
    END IF

    OnCommandLine = e
END FUNCTION


' Processes dropped files one file at a time
FUNCTION OnDroppedFiles%%
    ' Make a copy of the dropped file and clear the list
    REDIM fileNames(1 TO _TOTALDROPPEDFILES) AS STRING
    DIM i AS _UNSIGNED LONG
    DIM e AS _BYTE: e = EVENT_NONE

    FOR i = 1 TO _TOTALDROPPEDFILES
        fileNames(i) = _DROPPEDFILE(i)
    NEXT
    _FINISHDROP ' This is critical

    ' Now play the dropped file one at a time
    FOR i = LBOUND(fileNames) TO UBOUND(fileNames)
        e = DoFileDraw(fileNames(i))
        IF e <> EVENT_DRAW THEN EXIT FOR
    NEXT

    OnDroppedFiles = e
END FUNCTION


' Processes a list of files selected by the user
FUNCTION OnSelectedFiles%%
    DIM ofdList AS STRING
    DIM e AS _BYTE: e = EVENT_NONE

    ofdList = _OPENFILEDIALOG$(APP_NAME, , "*.ans|*.ANS|*.asc|*.ASC|*.diz|*.DIZ|*.nfo|*.NFO|*.txt|*.TXT", "ANSI Art Files", _TRUE)
    IF LEN(ofdList) = NULL THEN EXIT FUNCTION

    REDIM fileNames(0 TO 0) AS STRING
    DIM AS LONG i, j

    j = String_Tokenize(ofdList, "|", _STR_EMPTY, _FALSE, fileNames())

    FOR i = 0 TO j - 1
        e = DoFileDraw(fileNames(i))
        IF e <> EVENT_DRAW THEN EXIT FOR
    NEXT

    OnSelectedFiles = e
END FUNCTION
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/StringOps.bas'
'$INCLUDE:'include/Pathname.bas'
'$INCLUDE:'include/Base64.bas'
'$INCLUDE:'include/ProgramArgs.bas'
'$INCLUDE:'include/ANSIPrint.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
