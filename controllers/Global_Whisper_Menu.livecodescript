script "Global | Whisper | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Whisper | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put xterm_ProcessID() into LocalArray ["TtydProcessID"]
   return the browser_View of tObject
end menu_Target

getprop checked_StartXterm [browserView]
   return LocalArray ["TtydProcessID"] is not empty
end checked_StartXterm

getprop transcribeAudioFile_Params [audioView]
   return _ListAudioFiles()
end transcribeAudioFile_Params

getprop playAudioSample_Param [audioView]
   put the filename of audioView into audioFile
   set the itemdelimiter to slash
   put item -1 of audioFile into shortFile
   return shortFile
end playAudioSample_Param

getprop playAudioSample_Params [audioView]
   return _ListAudioFiles()
end playAudioSample_Params

private function _ListAudioFiles
   put _WhisperSampleFolder() into whisperFolder
   put files (whisperFolder) into shortFiles
   filter shortFiles with "*.wav"
   return shortFiles
end _ListAudioFiles

private function _WhisperSampleFolder
   return _WhisperFolder() & "samples/"
end _WhisperSampleFolder

private function _WhisperFolder
   put the module_AssetFolder of stack "View|Audio" into assetFolder
   put assetFolder & "whisper.cpp/" into whisperFolder
   return whisperFolder
end _WhisperFolder

private command _CdToWhisperFolder xtermView
   put _WhisperFolder() into whisperFolder
   put "cd" && whisperFolder into someShell
   ttyd_Execute someShell, xtermView
   return the result
end _CdToWhisperFolder


--> Global | Whisper | Menu
-
on menu_PlayAudioSample audioView, shortFile
   put _WhisperSampleFolder() into sampleFolder
   put sampleFolder & shortFile into audioFile
   --
   set the filename of audioView to audioFile
end menu_PlayAudioSample

private on _
end _

on submenu_InstallWhisper
   return menu_CreateTitle ("Global | Whisper | Menu", "Install")
end submenu_InstallWhisper

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Whisper | Menu")
end submenu_Dev
