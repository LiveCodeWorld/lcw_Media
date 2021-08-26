script "Global | Svg | IconLibrary | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Svg | IconLibrary | Line | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
on menu_Init tObject
   -- called only once for top menu
  pass menu_Init
end menu_Init

getprop menu_Target [tObject]
   -- called once for each menu
   return the display_View of tObject
end menu_Target


--> Global | Svg | IconLibrary | Line | Menu
-
on menu_DisplayIcon displayView
   put the selected_line of displayView into iName
   put the title_Text of displayView into iFamilyName
   --
   put svgLibrary_ConstructPathName (iName, iFamilyName) into iPathName
   put iconSVGPathFromName (iPathName) into svgPathData
   -- put iconCodepointFromName (iPathName)
   put svgPathData
end menu_DisplayIcon

on menu_RemoveIcon displayView
   put the selected_line of displayView into iName
   put the title_Text of displayView into iFamilyName
   --
   put getCurrentIconFamily() into oFamilyName
   setCurrentIconFamily iFamilyName
   --
   put iconData() into iData
   breakpoint
   --
   setCurrentIconFamily oFamilyName
end menu_RemoveIcon

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Experiment displayView
   put displayView
end menu_Experiment
