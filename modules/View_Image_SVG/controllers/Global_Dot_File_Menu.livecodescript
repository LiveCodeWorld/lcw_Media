script "Global | Dot | File | Menu"
--> MetaData
-
license: GPLv3
name: Global | Dot | File | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop graphDotFile_Params
   return dot_ListGraphStyles()
end graphDotFile_Params

getprop disabled_GraphDotFile [displayView]
   put the dot_File of displayView into dotFile
   return there is not a file dotFile
end disabled_GraphDotFile


--> Global | Dot | File | Menu
-
on menu_GraphDotFile displayView, graphStyle
   put the dot_File of displayView into dotFile
   --
   display_DotFileSvg dotFile, graphStyle
   put the result into svgView
end menu_GraphDotFile

private on _
end _

on menu_MenuEdit displayView
   menu_Edit "Global | Dot | File | Menu"
end menu_MenuEdit

on submenu_Dev
   return menu_DevTitle ("Global | Dot | File | Menu")
end submenu_Dev
