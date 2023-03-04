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
   put the selected_line of displayView into iconName
   put the title_Text of displayView into iFamilyName
   --
   put svgLibrary_ConstructPathName (iconName, iFamilyName) into iPathName
   put iconSVGPathFromName (iPathName) into svgPathText
   -- put iconCodepointFromName (iPathName)
   --
   display_SvgIcon iconName, svgPathText
   put the result into svgButton
   --
   -- put svgPathText
   return svgButton
end menu_DisplayIcon

on menu_RemoveIcon displayView
   put the selected_line of displayView into iconName
   put the title_Text of displayView into iFamilyName
   --
   icon_Delete iconName, iFamilyName
   --
   display_IconFamily iFamilyName
end menu_RemoveIcon
