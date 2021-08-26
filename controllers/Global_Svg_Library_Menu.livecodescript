script "Global | Svg | Library | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Svg | Library | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_IsSimple
   return true
end menu_IsSimple

getprop menu_Target [tObject]
   put the display_View of tObject into displayView
   if exists (displayView) then
      put the displayed_Object of tObject into viewObject
      return viewObject
   else
      return tObject
   end if
end menu_Target

getprop displayIconFamily_Params
   return iconFamilies()
end displayIconFamily_Params

getprop displayIconFamily_Param
   return getCurrentIconFamily()
end displayIconFamily_Param

getprop deleteIconFamily_Params
   return iconFamilies()
end deleteIconFamily_Params


--> Global | Svg | Library | Menu
-
on menu_AddIconFamily svgView
   put lcw_Ask ("Create a new icon family with the name...", "Custom", svgView) into iFamilyName
   put iconData() into iData
   --
   addIconFamily iFamilyName, iData
end menu_AddIconFamily

on menu_DeleteIconFamily svgView, iFamilyName
   deleteIconFamily iFamilyName
end menu_DeleteIconFamily

-- on menu_AddToSvglibrary svgView, iFamilyName
-- addIcon pName, pSVG, pCodepoint
end menu_AddToSvglibrary

on menu_DisplayIconFamily svgView, iFamilyName
   display_IconFamily iFamilyName
   --
   put iconData() into iData
   display_Data iData, "iconData()", iFamilyName
end menu_DisplayIconFamily

on _
end _

on submenu_Library
   return "Global | Svg | Library | Menu"
end submenu_Library

on menu_ListAtopiaAssets
   -- put "dao.lexon.wiki" into wikiDomain
   -- put atopia_ListAssets (wikiDomain, "") into assetData
   -- display_Data assetData, "Assets", wikiDomain
   --
   display_AtopiaAssets "livecode.world"
end menu_ListAtopiaAssets
 
on menu_ExampleSvgs
   display_HtmlSvgLinks "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/"
end menu_ExampleSvgs
