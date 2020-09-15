@echo off
set imageWidth=100
set imageHeight=100
set cropStep=10

REM orientation
REM 
REM ---------- 0:Horizontal
REM |||||||||| 1:Vertical
REM 
set orientation=1


REM resize 
REM 
REM  0 : disable
REM  1 : enable
REM
set enableResize=0

REM 
REM set the ImageMagick command path
REM
set ImageMagickCommand=magick

REM check parameters
IF "%1"=="" GOTO USAGE
IF "%2"=="" GOTO USAGE

REM 
REM check if the magick exists
REM 
%ImageMagickCommand% -version 2>NUL || GOTO CommandNotFound

REM
REM check other options (set resize or Horizontal crop)
REM
IF /i "%3"=="resize" set enableResize=1
IF /i "%3"=="y" set orientation=0
IF /i "%4"=="resize" set enableResize=1
IF /i "%4"=="y" set orientation=0


set resize=%imageWidth%x%imageHeight%

set imageResizeTempFilename=temp_file_for_image_resize.png

REM
REM Caculate the cropSize && the last crop localation
REM
IF %orientation%==0 (
   set cropSize=%imageWidth%x%cropStep%
   set /a cropLast=%imageHeight%-%cropStep%
) ELSE (
   set cropSize=%cropStep%x%imageHeight%
   set /a cropLast=%imageWidth%-%cropStep%
)
@echo.
@echo Image Size : "%imageWidth%x%imageHeight%"
@echo Crop Size : "%cropSize%"
@echo Crop Offset : "%cropStep%"
@echo.

IF "%1"=="" GOTO END
REM *******************************************************
REM Crop image file 1
REM *******************************************************
@echo Output to images\parts-1-*.png   
set imageFilename=%1

REM ***************************************
REM resize image to temp file
REM ***************************************
IF %enableResize%==1 (
   %ImageMagickCommand% convert -resize %resize% %1 %imageResizeTempFilename%
   set imageFilename=%imageResizeTempFilename%
)

REM ***************************************
REM batch crop image
REM ***************************************
IF %orientation%==0 (
   @echo Crop at Y :
   @echo.
   for /L %%a in (0,%cropStep%,%cropLast%) do (@echo %%a & %ImageMagickCommand% convert -crop %cropSize%+0+%%a %imageFilename% images\parts-1-%%a.png )
) ELSE (
   @echo Crop at X :
   @echo.
   
   for /L %%a in (0,%cropStep%,%cropLast%) do (@echo %%a & %ImageMagickCommand% convert -crop %cropSize%+%%a+0 %imageFilename% images\parts-1-%%a.png )
)
@echo.


IF "%2"=="" GOTO END
REM *******************************************************
REM Crop image file 2
REM *******************************************************
@echo output to images\parts-2-*.png
set imageFilename=%2

REM ***************************************
REM resize image to temp file
REM ***************************************
IF %enableResize%==1 (
   %ImageMagickCommand% convert -resize %resize% %2 %imageResizeTempFilename%
   set imageFilename=%imageResizeTempFilename%
)

REM ***************************************
REM batch crop image
REM ***************************************
IF %orientation%==0 (
   @echo Crop at Y :
   @echo.
   for /L %%a in (0,%cropStep%,%cropLast%) do (@echo %%a & %ImageMagickCommand% convert -crop %cropSize%+0+%%a %imageFilename% images\parts-2-%%a.png )
) ELSE (
   @echo Crop at X :
   @echo.
   for /L %%a in (0,%cropStep%,%cropLast%) do (@echo %%a & %ImageMagickCommand% convert -crop %cropSize%+%%a+0 %imageFilename% images\parts-2-%%a.png )
)
@echo.

IF %enableResize%==TRUE (
	del /Q %imageResizeTempFilename%
)

GOTO :END

:USAGE
@echo.
@echo. 
@echo Usage:
@echo    crop.bat image-1.png image-2.png
@echo.
GOTO :END

:CommandNotFound
@echo.
@echo Can't found the %ImageMagickCommand%
@echo Check the ImageMagick command if in the syteme's PATH
@echo.
%ImageMagickCommand%

:END
@echo.
@echo.
@echo bye!
@echo. 

