REM Requirements: files must be numbered "1.mp4, 2.mp4"

REM Pre-processing
REM --renames files, adding leading zeros
@echo on

::specify the ffmpeg.exe file including full path here
set "%FFMPEGFILE%=C:\ffmpeg.exe"

@echo off
setlocal enabledelayedexpansion

@SetLocal EnableDelayedExpansion
@echo off
Echo.
set /p yourfolder="Input the path to the movie folder: "
Echo.

Echo User specified: %yourfolder%


::For /f %%c in ('echo %yourfolder%') do set upath=%%c


::If NOT EXIST !upath! goto nofolder


cd /d %yourfolder%

::help to resume from previous cancelled operation
:: delete temp files, happens when resuming from previous process
if exist "temp.mp4" (
   del temp.mp4
)
if exist "filelist.txt" (
   del ilelist.txt
)
if exist "list.txt" (
   del list.txt
)
if exist "modified_filelist.txt" (
   del modified_filelist.txt
)

::start of renaming numbered files
::add leading zeros to make sorting work
for %%a in (*.mp4) do (


set name=%%~na


If "!name:~1,1!"=="" (
set name=000%%a
echo Renaming "%%a" to "!name!"
ren "%%a" "!name!"
)


IF "!name:~2,1!"=="" (
set name=00%%a
Echo Renaming "%%a" to "!name!"
ren "%%a" "!name!"
)




If "!name:~3,1!"=="" (
set name=0%%a
Echo Renaming "%%a" to "!name!"
ren "%%a" "!name!"
)
)
for /f "delims=" %%b in ('dir /b ^| find /i /v "ABC_"') do (
Echo Renaming "%%b" to "%%b"
ren "%%b" "%%b"
)
goto TheEnd


:nofolder
Echo.
Echo The folder doesn't exist


:TheEnd
 


::start of main merging process

:mainLoop
setlocal enabledelayedexpansion enableextensions 
set FILELIST=filelist.txt
set MODIFIED_FILELIST=modified_filelist.txt

set /a counter = 0

for %%a in ("*.mp4") do (
    
    if !counter! lss 5  (
        set /a counter += 1
        echo %%~nxa>>"%FILELIST%"
        echo File !counter!: %%~nxa
		
    
))

REM Add "-i" before each mp4 file in the list and save it to the modified file list
(for /f "delims=" %%i in (%FILELIST%) do (

    set "line= -i "%%i" "
    <nul set /p "=!line!!newline!" >> %MODIFIED_FILELIST%
)) >nul
for /f %%i in ('type %FILELIST% ^| find /c /v ""') do set FILE_COUNT=%%i

echo Number of files in %FILELIST%: %FILE_COUNT%
echo Modified file list saved to %MODIFIED_FILELIST%


ren %MODIFIED_FILELIST% list.txt

set "output_file=temp.mp4"
set "command_file=list.txt"
rem Use ffmpeg to concatenate all MP4 files
for /f "tokens=*" %%i in (%command_file%) do (
    echo Running script for file: %%i
    call %FFMPEGFILE% %%i-filter_complex "[0:v][0:a][1:v][1:a]concat=n=%FILE_COUNT%:v=1:a=1[vout][aout]" -map "[vout]" -map "[aout]" -c:v libx264 -c:a aac -strict experimental "%output_file%"
)

if exist "0000.mp4" (
   del 0000.mp4
   
)
rename temp.mp4 0000.mp4

rem delete files that have been combined
for /f "tokens=* delims=" %%a in ('type "%FILELIST%"') do (
    set "currentFile=%%a"

    if exist "!currentFile!" (
        if "!currentFile!" neq "0000.mp4" (
		    del "!currentFile!"
            echo Deleted: !currentFile!
        )			
    ) else (
        echo File not found: !currentFile!
    )
)

del %FILELIST%
del list.txt

rem count the files to repeat until 1 file left
set /a mp4count = 0
for %%a in ("*.mp4") do (
    set /a mp4count +=1
)
echo "Loop successful. trying on the rest of files:"
echo !mp4count!
echo "****************"
if !mp4count! neq 1 (
    goto :mainLoop
)


echo "Combining complete."
pause
