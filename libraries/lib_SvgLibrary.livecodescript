script "lib_SvgLibrary"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_SvgLibrary
type: library
version: 0.1

/*Some help*/


--> Working on
-
on mDoubleUp_DisplaySvgIcon displayView, iconName
   put the title_Text of displayView into iFamilyName
   put svgLibrary_ConstructPathName (iconName, iFamilyName) into iPathName
   --
   put iconSVGPathFromName (iPathName) into svgPathText
   --
   display_SvgIcon iconName, svgPathText
   put the result into svgButton
   -- put svgPathText
   return svgButton
end mDoubleUp_DisplaySvgIcon

on mDoubleUp_DisplayIconFamily displayView, iFamilName
   display_IconFamily iFamilName
end mDoubleUp_DisplayIconFamily

command display_IconLibrary
   put iconFamilies() into iFamilyNames
   display_Data iFamilyNames, "Icon Family Names", "Icon Library"
   put the result into displayView
   --
   display_SetInteractions displayView, "Svg | Library", "mDoubleUp_DisplayIconFamily"
   return displayView
end display_IconLibrary

command display_IconFamily iFamilyName
   setCurrentIconFamily iFamilyName
   get iconListForFamily (iFamilyName)
   put iconNames() into iNames
   put iconNamesForFamily (iFamilyName) into iNames
   --
   display_Data iNames, iFamilyName, "Svg Icon Library"
   put the result into displayView
   display_SetInteractions displayView, "Svg | IconLibrary", "mDoubleUp_DisplaySvgIcon"
   return displayView
end display_IconFamily

command display_SvgButton svgXML, pLabel
   if pLabel is empty then put "SVG Button" into pLabel
   put svg_GetPathText (svgXML) into svgPathText
   --
   display_Clone "View|Button|Svg", pLabel, svgPathText, "icon_PathText", "mouse", "toplevel"
   put the result into displayView
   display_ToolStack displayView
   --
   return displayView
end display_SvgButton


--> Svg | Library
-
function svgLibrary_ConstructPathName iconName, pFamilyName
   if pFamilyName is empty then
      return iconName
   else
      put pFamilyName & slash & iconName into iPathName
      return iPathName
   end if
end svgLibrary_ConstructPathName


--> Deps
-
