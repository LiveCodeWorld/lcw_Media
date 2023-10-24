script "Global | Image | SVG | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Image | SVG | Dev | Menu
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
   put the svg_View of tObject into svgView
   if exists (svgView) is false then
      put the displayed_Object of tObject into svgView
   end if
   return svgView
end menu_Target

getprop menu_CheckTarget [svgView]
   return exists (svgView)
end menu_CheckTarget


--> Global | Image | SVG | Dev | Menu
-
on menu_DisplaySvgPathText svgView
   put the svg_XML of svgView into svgXML
   put svg_GetPathText (svgXML)
end menu_DisplaySvgPathText

on menu_DeleteHeaderKey svgView, headerType
   put the svg_HeaderArray of svgView into svgHeaderArray
   delete variable svgHeaderArray [headerType]
   set the svg_HeaderArray of svgView to svgHeaderArray
end menu_DeleteHeaderKey

on menu_SetScale svgView
   put the svg_Scale of svgView into svgScale
   put lcw_Ask ("Change the scale of the svg view?", svgScale) into svgScale
   set the svg_Scale of svgView to svgScale
end menu_SetScale

private command _
end _

on submenu_Tree
   return "Global | Svg | Tree | Menu"
end submenu_Tree

on submenu_Assets
   return "Global | Svg | Assets | Menu"
end submenu_Assets

on submenu_Handler
   return "Global | Svg | Handler | Menu"
end submenu_Handler

private command __
end __

on menu_DisplaySvg svgView, svgName
   put _ConstructNameArray() into nameArray
   put nameArray [svgName] into sURL
   --
   set the svg_URL of svgView to sURL
end menu_DisplaySvg

on submenu_Display
   return "Global | Svg | Display | Menu"
end submenu_Display

on submenu_SvgLibrary
   return "Global | Svg | Library | Menu"
end submenu_SvgLibrary

on submenu_IconLibrary
   return "Global | Svg | IconLibrary | Menu"
end submenu_IconLibrary

private command ___
end ___

on menu_EditSvgBehavior svgView
   put the behavior of svgView into bObject
   edit the script of bObject
end menu_EditSvgBehavior
