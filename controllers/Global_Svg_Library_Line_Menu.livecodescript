script "Global | Svg | Library | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Svg | Library | Line | Menu
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
   -- called once for each menu
   return the display_View of tObject
end menu_Target

getprop menu_IsSimple
   return true
end menu_IsSimple



--> Global | Svg | Library | Line | Menu
-
on menu_DisplayIconFamily displayView
   put the selected_Line of displayView into iFamilyName
   display_IconFamily iFamilyName
end menu_DisplayIconFamily

on _
end _

on menu_Experiment displayView
   put displayView
end menu_Experiment
