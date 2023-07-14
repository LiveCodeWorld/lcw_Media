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
   
   put display_MenuTarget(tObject) into dObject
   put the audio_View of dObject into audioView
   return audioView
end menu_Target


--> Global | Audio | Menu
-
on menu_EditAudio audioView
   put the fileName of audioView into audioFile
   launch document audioFile
end menu_EditAudio

private on _
end _

on menu_EditBehavior audioView
   put the behavior of audioView into bObject
   edit the script of bObject
end menu_EditBehavior
