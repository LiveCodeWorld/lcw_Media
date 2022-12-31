script "Global | Image | SVG | Menu"
--> MetaData
-
license: GPLv3
name: Global | Image | SVG | Menu
type: controller
target: svgView
version: 0.2


--> Menu | Init
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

getprop fluidSvg_Param [svgView]
   put the svg_IsFluid of svgView into someBoolean
   return someBoolean
end fluidSvg_Param

getprop fluidSvg_Params
   return "true,false"
end fluidSvg_Params

getprop deleteHeaderKey_Params [svgView]
   -- strange bug trying to set this to header_Keys, or some_Keys
   put the svg_HeaderArray of svgView into svgHeaderArray
   return keys (svgHeaderArray)
end deleteHeaderKey_Params

getprop displaySvg_Params
   return _UrlNameMenu()
end displaySvg_Params
   
private function _UrlNameMenu
   put _ConstructNameArray() into nameArray
   put keys (nameArray) into nameMenu
   replace CR with comma in nameMenu
   return nameMenu
end _UrlNameMenu

private function _ConstructNameArray
   -- construct a dictionary to store urls in and enable menu interface based on keys
   local nameArray
   _AddToNameArray nameArray, "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/AJ_Digital_Camera.svg"
   _AddToNameArray nameArray,  "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/basura.svg"
   _AddToNameArray nameArray, "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/car.svg"
   _AddToNameArray nameArray, "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/displayWebStats.svg"
   --
   return nameArray
end _ConstructNameArray

private command _AddToNameArray @nameArray, sURL
   set the itemdelimiter to slash
   put item -1 of sURL into shortName
   put sURL into nameArray [shortName]
end _AddToNameArray


--> Global | Image | SVG | Menu
-
on menu_DisplaySvg svgView, svgName
   put _ConstructNameArray() into nameArray
   put nameArray [svgName] into sURL
   --
   set the svg_URL of svgView to sURL
end menu_DisplaySvg

on menu_FluidSvg svgView, someBoolean
   set the svg_IsFluid of svgView to someBoolean
end menu_FluidSvg

on _
end _

on menu_SvgTools svgView
   display_ToolStack svgView
end menu_SvgTools

on submenu_Display
   return "Global | Svg | Display | Menu"
end submenu_Display

on submenu_Tree
   return "Global | Svg | Tree | Menu"
end submenu_Tree

on submenu_SvgLibrary
   return "Global | Svg | Library | Menu"
end submenu_SvgLibrary

on submenu_IconLibrary
   return "Global | Svg | IconLibrary | Menu"
end submenu_IconLibrary

on submenu_Assets
   return "Global | Svg | Assets | Menu"
end submenu_Assets

on submenu_Handler
   return "Global | Svg | Handler | Menu"
end submenu_Handler

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on _DisplaySvgPathText svgView
   put the svg_XML of svgView into svgXML
   put svg_GetPathText (svgXML)
end _DisplaySvgPathText

on _DeleteHeaderKey svgView, headerType
   put the svg_HeaderArray of svgView into svgHeaderArray
   delete variable svgHeaderArray [headerType]
   set the svg_HeaderArray of svgView to svgHeaderArray
end _DeleteHeaderKey

on _SetScale svgView
   put the svg_Scale of svgView into svgScale
   put lcw_Ask ("Change the scale of the svg view?", svgScale) into svgScale
   set the svg_Scale of svgView to svgScale
end _SetScale

on _
end _

on _EditSvgBehavior svgView
   put the behavior of svgView into bObject
   edit the script of bObject
end _EditSvgBehavior
