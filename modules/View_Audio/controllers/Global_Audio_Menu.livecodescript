script "Global | Audio | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Audio | Menu
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
   -- return the display_View of tObject
   put display_MenuTarget (tObject) into dObject
   if exists (dObject) is false then return empty
   
   put the audio_View of dObject into audioView
   return audioView
end menu_Target

getprop selectAudio_Param [audioView]
   put the audio_File of audioView into audioFile
   set the itemdelimiter to slash
   return item -1 of audioFile
end selectAudio_Param
   
getprop selectAudio_Params [audioView]
   return LocalArray ["audioFiles"]   
end selectAudio_Params

getprop disabled_SelectAudio [audioView]
   put LocalArray ["audioFiles"] is empty into sBoolean
   return sBoolean
end disabled_SelectAudio


--> Global | Audio | Menu
-
on menu_SelectAudio audioView, shortFile
   set the defaultfolder to LocalArray ["audioFolder"]
   set the audio_File [true] of audioView to shortFile
end menu_SelectAudio

on menu_EditAudio audioView
   put the fileName of audioView into audioFile
   launch document audioFile
end menu_EditAudio

private on _
end _

on menu_ChooseFolder dView
   answer folder "Choose an audio folder..." as sheet
   if it is empty then exit to top
   put it into audioFolder
   --
   put audioFolder into LocalArray ["audioFolder"]
   put file_ListShort (audioFolder) into LocalArray ["audioFiles"]
end menu_ChooseFolder

on submenu_Whisper
   return "Global | Whisper | Menu"
end submenu_Whisper

on submenu_Dev
   return menu_DevTitle()
end submenu_Dev
