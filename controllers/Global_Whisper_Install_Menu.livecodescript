script "Global | Whisper | Install | Menu"
--> MetaData
-
license: GPLv3
name: Global | Whisper | Install | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this menu.
Full help text should be provided on the linked wiki.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   return the browser_View of tObject
end menu_Target

getprop menu_CheckTarget [xtermView]
   return exists (xtermView)
end menu_CheckTarget

private command _PasteXterm someShell, xtermView
   -- display_Xterm xtermView
   -- put the result into xtermView
   --
   ttyd_Paste someShell, xtermView
   return the result
end _PasteXterm

private function _WhisperFolder
   put LocalArray ["installFolder"] into installFolder
   text_AddTrailing installFolder, slash
   put installFolder & "whisper.cpp/" into whisperFolder
   return whisperFolder
end _WhisperFolder

private command _CdToWhisperFolder xtermView
   put _WhisperFolder() into whisperFolder
   put "cd" && whisperFolder into someShell
   ttyd_Execute someShell, xtermView
   return the result
end _CdToWhisperFolder


--> Global | Whisper | Install | Menu
-
on menu_ChooseInstallationFolder xtermView
   if exists (stack "View|Audio") then
      put the module_AssetFolder of stack "View|Audio" into assetFolder
   else
      put the module_AssetFolder of xtermView into assetFolder
   end if
   answer folder "Choose a folder to install software..." with assetFolder as sheet
   if it is empty then exit to top
   --
   put it into installFolder
   text_AddTrailing installFolder, slash
   put installFolder into LocalArray ["installFolder"]
   --
   put "cd" && kwote (installFolder) into someShell
   _PasteXterm someShell, xtermView
end menu_ChooseInstallationFolder

private on _
end _

on menu_DownloadWhisper xtermView
   put "git clone https://github.com/ggerganov/whisper.cpp.git" into someShell
   --
   _PasteXterm someShell, xtermView
end menu_DownloadWhisper

on menu_Make xtermView
   put "cd whisper.cpp;make" into someShell
   --
   _PasteXterm someShell, xtermView
end menu_Make

on menu_DownloadSmallModel xtermView
   put "cd models" into someShell
   ttyd_Execute someShell, xtermView
   --
   put "bash ./download-ggml-model.sh small" into someShell
   ttyd_Paste someShell, xtermView
end menu_DownloadSmallModel

private on __
end __

getprop testTranscribe_Params [audioView]
   return _ListAudioFiles()
end testTranscribe_Params

private function _ListAudioFiles
   put _WhisperSampleFolder() into whisperFolder
   put files (whisperFolder) into shortFiles
   filter shortFiles with "*.wav"
   return shortFiles
end _ListAudioFiles

private function _WhisperSampleFolder
   return _WhisperFolder() & "samples/"
end _WhisperSampleFolder

on menu_TestTranscribe xtermView, audioFile
   _CdToWhisperFolder xtermView
   --
   put "./main -m models/ggml-small.bin -f samples/jfk.wav" into someShell
   ttyd_Paste someShell, xtermView
end menu_TestTranscribe

on menu_LiveTranscribe xtermView
   _CdToWhisperFolder xtermView
   --
   put "./stream -m ./models/ggml-small.bin -t 6 --step 0 --length 30000 -vth 0.6" into someShell
   ttyd_Execute someShell, xtermView
end menu_LiveTranscribe

on submenu_Dev
   return menu_DevTitle ("Global | Whisper | Install | Menu")
end submenu_Dev
