script "Global | Svg | Assets | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Svg | Assets | Menu
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
   if exists (tObject) is false then return empty
   put the svg_View of tObject into svgView
   if exists (svgView) is true then return svgView
   
   put the display_View of tObject into displayView
end menu_Target

getprop menu_CheckTarget [svgView]
   if exists (svgView) then
      return true
   else
      return false
   end if
end menu_CheckTarget
   
getprop disabled_DownloadAssets [svgView]
   put _ShortAssetFiles (svgView) into shortAssetFiles
   if shortAssetFiles is empty then
      return true
   else
      return false
   end if
end disabled_DownloadAssets

getprop disabled_DisplayAsset [svgView]
   put _ShortAssetFiles (svgView) into shortAssetFiles
   if shortAssetFiles is empty then
      return true
   else
      return false
   end if
end disabled_DisplayAsset

getprop displayAsset_Params [svgView]
   put _ShortAssetFiles (svgView) into shortAssetFiles
   return shortAssetFiles
end displayAsset_Params

private function _ShortAssetFiles svgView
   put _DisplayedObject (svgView) into hObject
   if exists (hObject) is false then return empty
   --
   put the project_Folder of hObject into projectFolder
   put asset_ListFiles (projectFolder, empty, true) into shortAssetFiles
   return shortAssetFiles
end _ShortAssetFiles

private function _DisplayedObject svgView
   -- put the displayed_Object of svgView into hObject
   put the stack_Name of svgView into stackName
   put the label of stack stackName into hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   return hObject
end _DisplayedObject


--> Global | Svg | Assets | Menu
-
on menu_DisplaySvgXml svgView
   put the svg_XML of svgView into svgXML
   --
   put the stack_Label of svgView into dTitle
   display_Text svgXML, dTitle
end menu_DisplaySvgXml

on menu_UploadSvg svgView
   put "livecode.world" into wikiDomain
   put "graph" into shortFolder
   --
   put the svg_File of svgView into svgFile
   set the itemdelimiter to slash
   put item -1 of svgFile into shortFile
   --
   atopia_StoreAssetFile wikiDomain, shortFile, svgFile, shortFolder
   --
   if the result is not empty then
      put the result
   else
      display_AtopiaAssets wikiDomain, shortFolder
      launch_Fedwiki wikiDomain, "Graphs"
   end if
end menu_UploadSvg

on menu_RevealSvg svgView
   -- put the url of svgView into browserURL
   put the svg_File of svgView into svgFile
   -- put the svg_Url of svgView into svgFile
   put the svg_HTML of svgView into sHTML
   --
   finder_Reveal svgFile
   display_Text sHTML, "the svg_HTML"
end menu_RevealSvg

-- on menu_DownloadAssets svgView
put _DisplayedObject (svgView) into scriptObject
put the project_Folder of scriptObject into projectFolder

-- put "http://livecode.world/graphs/graph.html" into someUrl
asset_DownloadHtml "http://livecode.world/graphs/graph.html", projectFolder
asset_DownloadHtml "https://livecode.world/graphs/graphviz.html", projectFolder
asset_DownloadHtml "http://js.cytoscape.org/demos/aedff159b0df05ccfaa5/", projectFolder, "cats.html"
end menu_DownloadAssets

on menu_DisplayAsset svgView, shortAssetFile
   put _DisplayedObject (svgView) into scriptObject
   put the project_Folder of scriptObject into projectFolder
   --
   put asset_GetFile (projectFolder, shortAssetFile) into htmlFile
   put ("file:" & htmlFile) into someURL
   
   put the long id of control 1 of cd 1 of stack "View|Image|SVG" into svgView
   put url someURL into someHtml
   
   -- set the htmltext of svgView to someHtml
   set the url of svgView to htmlFile
   
   if the shiftKey is "Down" then
      put the htmltext of svgView
      display_Index someHtml
   end if
end menu_DisplayAsset

on _
end _

on menu_ExportSvg svgView
   put the htmltext of svgView into someHTML
   put the svg_XML of svgView into someSVG
   put the svg_URL of svgView into svgURL
   
   answer folder "Choose a folder to export the html and svg..."
   if it is empty then exit to top
   
   put it into someFolder
   set the defaultfolder to someFolder
   
   set the itemdelimiter to slash
   put item -1 of svgURL into shortFile
   if char -4 to -1 of shortFile is not ".svg" then
      set the itemdelimiter to "."
      if the number of items of shortFile = 2 then delete item -1 of shortFile
      put ".svg" after shortFile
   end if
   put "file:" & shortFile into localSvgUrl
   
   put someHTML into url "file:index.html"
   put someSVG into url localSvgUrl
end menu_ExportSvg
