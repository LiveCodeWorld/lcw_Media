﻿script "Global | SVG | Tree | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | SVG | Tree | Line | Menu
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

private function _SvgUrl displayView
   put the selected_Line of displayView into shortSvgFile
   put the displayed_URL of displayView into someURL
   put url_FromShortFile (shortSvgFile, someURL) into svgURL
   return svgURL
end _SvgUrl

function url_FromShortFile shortSvgFile, someURL
   -- set the itemdelimiter to slash
   put someURL into svgURL
   if char -1 of svgURL is not slash then put slash after svgURL
   put shortSvgFile after svgURL
   return svgURL
end url_FromShortFile


--> Global | SVG | Tree | Line | Menu
-
on menu_DisplaySvg displayView
   put _SvgUrl (displayView) into svgURL
   --
   display_SVG svgURL, "SVG"
end menu_DisplaySvg

on menu_DisplayXml displayView
   put _SvgUrl (displayView) into svgURL
   --
   put url svgURL into someXML
   display_Text someXML
end menu_DisplayXml

on _
end _

on menu_VisitWebpage displayView
   put _SvgUrl (displayView) into svgURL
   launch url svgURL
end menu_VisitWebpage
