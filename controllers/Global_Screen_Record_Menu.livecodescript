script "Global | Screen | Record | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Screen | Record | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop checked_RecordScreen [displayView]
   return screen_IsRecording()
end checked_RecordScreen


--> Global | Screen | Record | Menu
-
on menu_RecordScreen displayView
   -- screen_StartRecording
   put empty into shortFile
   screen_ToggleRecord shortFile, true
end menu_RecordScreen

private on _
end _

on menu_SetThisScreen
   screen_SetNum
end menu_SetThisScreen

on menu_RevealRecordingFolder displayView
   finder_Reveal screen_GetCastFolder()
end menu_RevealRecordingFolder

on submenu_Dev
   return menu_DevTitle ("Global | Screen | Record | Menu")
end submenu_Dev
