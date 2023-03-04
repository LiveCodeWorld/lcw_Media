script "Global | Svg | IconLibrary | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Svg | IconLibrary | Menu
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
   return the display_View of tObject
end menu_Target

getprop displayIconFamily_Params
   return iconFamilies()
end displayIconFamily_Params

getprop displayIconFamily_Param
   return getCurrentIconFamily()
end displayIconFamily_Param

getprop loadIconFamily_Params
   return icon_ListLibraries()
end loadIconFamily_Params

getprop removeIconFamily_Params
   put icon_ListLibraries() into iconFamilyNames
   replace ".array" with empty in iconFamilyNames
   return iconFamilyNames
end removeIconFamily_Params


--> Global | Svg | IconLibrary | Menu
-
on menu_LoadIconFamily displayView, iFamilyName
   icon_LoadFamily iFamilyName
end menu_LoadIconFamily

on menu_RemoveIconFamily displayView, iFamilyName
   icon_RemoveFamily iFamilyName
end menu_RemoveIconFamily

private on _
end _

on menu_ExportIconFamily displayView
   put the displayed_Title of displayView into iFamilyName
   --
   icon_SetLibrary iFamilyName
end menu_ExportIconFamily

on insert_Menu
   return "Global | Svg | Library | Menu"
end insert_Menu

on menu_Refresh displayView
   put the displayed_Title of displayView into iFamilyName
   display_IconFamily iFamilyName
end menu_Refresh
