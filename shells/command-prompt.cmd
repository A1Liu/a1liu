@Rem @cd %HOMEPATH%\code
@set mypath=%cd%
@cd %~dp0
@cd ..
@call "%mypath%\local\command-prompt.cmd"
@cd %mypath%
