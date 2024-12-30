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

getprop graphStyle_Param [svgView]
   return the graph_Style of svgView
end graphStyle_Param

getprop graphStyle_Params
   return dot_ListGraphStyles()
end graphStyle_Params

getprop checked_DisplayDotGraph [svgView]
   put the linked_GraphView of svgView into graphView
   return exists (graphView)
end checked_DisplayDotGraph

getprop checked_ScreenDimensions [graphView]
   put the stack_IsProportional of graphView into sBoolean
   return sBoolean
end checked_ScreenDimensions


--> Global | Image | SVG | Menu
-
on menu_DisplayDotGraph svgView
   put the dot_File of svgView into dotFile
   put the graph_Style of svgView into graphStyle
   --
   put the linked_GraphView of svgView into graphView
   if exists (graphView) then
      set the dot_File [graphStyle] of graphView to dotFile
   else
      put "View|Dot|Graph" into viewName
      stack_CloneInvisible viewName
      put the result into cloneStackName
      put the long id of control 1 of cd 1 of stack cloneStackName into graphView
      --
      set the edge_Width of graphView to 1
      set the dot_File [graphStyle] of graphView to dotFile
      --
      display_ShowStack graphView, cloneStackName
      --
      set the linked_SvgView of graphView to svgView
      set the linked_GraphView of svgView to graphView
   end if
end menu_DisplayDotGraph

-- on submenu_Save
return "Global | Dot | Save | Menu"
end submenu_Save

on submenu_Assets
   return "Global | Svg | Assets | Menu"
end submenu_Assets

on menu_GraphStyle svgView, graphStyle
   set the graph_Style of svgView to graphStyle
end menu_GraphStyle

private command _
end _

on menu_ResizeToScreen graphView
   put the dot_Array of graphView into dotArray
   --
   put the dot_ScreenRect of graphView into bbRect
   put bbRect into dotArray ["bb"]
   delete variable dotArray ["size"]
   put 16/9 into dotArray ["ratio"]
   --
   set the dot_Array of graphView to dotArray
   put the result into newDot
   display_Text newDOT
end menu_ResizeToScreen

on menu_ScreenDimensions graphView
   put the screen_ProportionalStackRect of graphView into nRect
   set the stack_Rect of graphView to nRect
end menu_ScreenDimensions

on menu_Decompose svgView
   put the dot_File of svgView into dotFile
   --
   display_DotGraphs dotFile, svgView
end menu_Decompose

on menu_Recompose svgView
   put the dot_File of svgView into dotFile
   --
   put gv_RecomposeDotFile (dotFile, "svg") into svgXML
   set the svg_XML of svgView to svgXML
   -- display_Json newJSON, "Dot Array"
end menu_Recompose

private command __
end __

on menu_HkeyLinkArray svgView
   -- put the link_Array of svgView into linkArray
   put the displayed_Hkey of svgView into hKey
   put the graph_Style of svgView into graphStyle
   --
   display_HkeyLinkArray hkey, graphStyle
   put the result into dView
end menu_HkeyLinkArray

getprop disabled_HkeyLinkArray [svgView]
   put the displayed_Hkey of svgView into hKey
   return hKey is empty
end disabled_HkeyLinkArray

on menu_DataViewData svgView
   put the dv_Data of svgView into dvData
   --
   put the stack_Label of svgView into graphName
   put the graph_Style of svgView into graphStyle
   display_Data dvData, graphStyle, graphName
end menu_DataViewData

on menu_StyleArray svgView
   -- put the dot_File of svgView into dotFile
   -- put the graph_Style of svgView into graphStyle
   -- put the link_Array of svgView into linkArray
   -- put the dv_Data of svgView into dvData
   put the dot_StyleArray of svgView into dotStyleArray
   --
   put the stack_Label of svgView into graphName
   put the graph_Style of svgView into graphStyle
   display_Data dotStyleArray, graphStyle, graphName
end menu_StyleArray

private command ___
end ___

on menu_FluidSvg svgView, someBoolean
   set the svg_IsFluid of svgView to someBoolean
end menu_FluidSvg

on menu_RevealSvgFile svgView
   put the svg_File of svgView into svgFile
   finder_Reveal svgFile
end menu_RevealSvgFile

on menu_SvgTools svgView
   display_ToolStack svgView
end menu_SvgTools

on submenu_Dev
   return menu_DevTitle ("Global | Image | SVG | Menu")
end submenu_Dev
