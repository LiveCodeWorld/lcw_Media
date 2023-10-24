script "Global | Dot | Save | Menu"
--> MetaData
-
license: GPLv3
name: Global | Dot | Save | Menu
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

getprop disabled_DisplayDotFile [displayView]
   put the dot_File of displayView into dotFile
   return there is not a file dotFile
end disabled_DisplayDotFile

getprop disabled_ExportCanon [displayView]
   put the dot_File of displayView into dotFile
   return there is not a file dotFile
end disabled_ExportCanon

getprop disabled_ExportXdot [displayView]
   put the dot_File of displayView into dotFile
   return there is not a file dotFile
end disabled_ExportXdot

getprop disabled_DisplayStrippedPositions [displayView]
   put the dot_File of displayView into dotFile
   return there is not a file dotFile
end disabled_DisplayStrippedPositions

getprop disabled_DotArrayOfGraph [graphView]
   return exists (the graph_View of graphView) is true
end disabled_DotArrayOfGraph


--> Global | Dot | Save | Menu
-
on submenu_DotFile
   return menu_CreateTitle ("Global | Dot | File | Menu")
end submenu_DotFile

on menu_SaveDisplayed displayView
   put the dot_File of displayView into dotFile
   if there is not a file dotFile then
      ask file "Export dot text..." with "graph.dot"
      put it into dotFile
      if dotFile is empty then
         exit to top
      end if
   end if
   
   put the displayed_Text of displayView into dotText
   put file_GetShort (dotFile) into shortFile
   --
   lcw_Answer "Export dot text to existing file [[shortFile]]?", displayView, shortFile
   put dot_GetName (dotText) into graphName
   dot_SetText dotFile, dotText
   set the dot_File of displayView to dotFile
end menu_SaveDisplayed

private command _
end _

on menu_ExportDot displayView
   put the dot_File of displayView into dotFile
   gv_ExportDot dotFile
   put the result into dotFile
   --
   display_DotText dotFile
end menu_ExportDot

on menu_ExportCanon graphView
   put the dot_File of graphView into dotFile
   gv_ExportCanon dotFile
   put the result into dotFile
   --
   display_DotText dotFile
end menu_ExportCanon

on menu_ExportXdot graphView
   put the dot_File of graphView into dotFile
   gv_ExportXdot dotFile
   put the result into dotFile
   --
   display_DotText dotFile
end menu_ExportXdot

private command __
end __

on menu_DisplayStrippedPositions displayView
   put the dot_File of displayView into dotFile
   put the graph_Style of displayView into graphStyle
   put dotArray_Get (dotFile, graphStyle, true, true) into dotArray
   --
   put dot_FromArray (dotArray, true) into dotText
   display_DotText dotText
   put the result into dView
   set the dot_File of dView to dotFile
end menu_DisplayStrippedPositions

on menu_DisplayJson displayView
   put the dot_File of displayView into dotFile
   put the graph_Style of displayView into graphStyle
   --
   put dotJson_FromDotFile (dotFile, graphStyle, true) into dotJSON
   --
   put dot_GetText(dotFile) into dotText
   put dot_DisplayTitle (dotText, dotFile) into displayTitle
   display_Json dotJSON, displayTitle
end menu_DisplayJson

on menu_DisplayDotFile displayView
   put the dot_File of displayView into dotFile
   --
   display_DotText dotFile
end menu_DisplayDotFile

private command ___
end ___

on menu_DotArrayOfGraph graphView
   put the dot_Array of graphView into dotArray
   --
   put the dot_File of graphView into dotFile
   display_DotArray dotArray, dotFile
end menu_DotArrayOfGraph
