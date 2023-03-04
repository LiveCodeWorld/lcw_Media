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
getprop menu_Target [tObject]
   put the display_View of tObject into displayView
   if exists (displayView) then
      put the displayed_Object of tObject into viewObject
      return viewObject
   else
      return tObject
   end if
end menu_Target

private function _SafeFamileNames
   put iconFamilies() into sFamilyNames
   line_Delete "ide", sFamilyNames
   line_Delete "fontawesome", sFamilyNames
   return sFamilyNames
end _SafeFamileNames

getprop addToSvglibrary_Param
   return getCurrentIconFamily()
end addToSvglibrary_Param

getprop addToSvglibrary_Params
   return _SafeFamileNames()
end addToSvglibrary_Params

getprop disabled_AddToSvgLibrary [svgButton]
   return _SafeFamileNames() is empty
end disabled_AddToSvgLibrary

getprop deleteIconFamily_Params
   return _SafeFamileNames()
end deleteIconFamily_Params

getprop disabled_DeleteIconFamily [svgButton]
   return _SafeFamileNames() is empty
end disabled_DeleteIconFamily
   
getprop disabled_DisplayIconData [svgButton]
   put the icon_Data of svgButton into iconData
   return iconData is not an array
end disabled_DisplayIconData

getprop disabled_AddToSvglibrary [svgButton]
   put the icon_Data of svgButton into iconData
   return iconData is not an array
end disabled_AddToSvglibrary

getprop displayIconFamily_Param
   return getCurrentIconFamily()
end displayIconFamily_Param

getprop displayIconFamily_Params
   return iconFamilies()
end displayIconFamily_Params

private function _GetIconName svgButton, iFamilyName
   put the icon_Data of svgButton into iconData
   --
   if iconData is an array then
      -- put iconData ["term"] into iconName
      put iconData ["term_slug"] into iconName
   else
      -- put the stack_Label of svgButton into iconName
      put the short name of svgButton into iconName
   end if
   --
   put iFamilyName & slash & iconName into iName
   --
   return iName
end _GetIconName


--> Global | Svg | Library | Menu
-
on menu_AddToSvgLibrary svgButton, iFamilyName
   put the iconPath of svgButton into svgPath
   if char 1 of svgPath is not "M" then
      breakpoint
   end if
   --
   put _GetIconName (svgButton, iFamilyName) into iName
   put lcw_Ask ("What name would you like to give this icon?", iName) into iName
   --
   addIcon iName, svgPath, 0
   --
   display_IconFamily iFamilyName
end menu_AddToSvgLibrary

on menu_DisplayIconFamily svgView, iFamilyName
   display_IconFamily iFamilyName
   --
   put iconData() into iData
   display_Data iData, "iconData()", iFamilyName
end menu_DisplayIconFamily

on _
end _

on menu_NewIconFamily svgButton
   put lcw_Ask ("Create a new icon family with the name...", "Custom", svgView) into iFamilyName
   -- put iconData() into iData
   put the icon_Data of svgButton into iconData
   put iconData ["term_slug"] into iName
   put the iconPath of svgButton into svgPath
   --
   put svgPath into iData [iName]["svg"]
   put 0 into iData [iName]["codepoint"]
   --
   addIconFamily iFamilyName, iData
end menu_NewIconFamily

on menu_DeleteIconFamily svgView, iFamilyName
   setCurrentIconFamily "fontawesome"
   --
   deleteIconFamily iFamilyName
end menu_DeleteIconFamily

on _ListAtopiaAssets
   -- put "dao.lexon.wiki" into wikiDomain
   -- put atopia_ListAssets (wikiDomain, "") into assetData
   -- display_Data assetData, "Assets", wikiDomain
   --
   display_AtopiaAssets "livecode.world"
end _ListAtopiaAssets
 
on menu_ExampleSvgs
   display_ExampleSvgs
end menu_ExampleSvgs
