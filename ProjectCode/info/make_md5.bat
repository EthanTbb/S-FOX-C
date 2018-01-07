@echo off
REM http://www.jb51.net/article/17927.htm

rem client
MakeMD5List -dst %temp% -src ..\client\ciphercode\client
copy %temp%\filemd5List.json ..\client\ciphercode\client\res\filemd5List.json
del %temp%\filemd5List.json

set /a game_count=0
rem game list
for /f "skip=1 tokens=1,2,3,4,5,6,7,8,9,10 delims==," %%a in (game_list.txt) do (
	echo game name %%b
	del %%d\filemd5List.json
	MakeMD5List -dst %temp% -src ..\%%d
	copy %temp%\filemd5List.json ..\%%d\res\filemd5List.json
	del %temp%\filemd5List.json
	
	set /a game_count+=1
	if  errorlevel 1 goto OnError
)
if  errorlevel 0 goto Finish
:OnError
echo make md5 error
pause

:Finish
echo.
echo.
echo 处理游戏数目 %game_count%
echo.
echo.