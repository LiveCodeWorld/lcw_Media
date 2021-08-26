script "Global | Svg | Display | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Svg | Display | Menu
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
   -- called once for each menu
   return the display_View of tObject
end menu_Target


--> Global | Svg | Display | Menu
-
on menu_SetUrl svgView, whichUrl
   breakpoint
   switch whichUrl
      case "Compound"
         put "http://livecode.world/graphs/graph.html" into someUrl
         break
      case "Paths"
         put "https://livecode.world/graphs/graphviz.html" into someUrl
         -- put "http://js.cytoscape.org/demos/6c9907e7896f8ae23f9f/" into someUrl
         break
      case "Huge"
         -- put "http://js.cytoscape.org/demos/57e7cc43342193d9d21a/" into someUrl
         put "http://js.cytoscape.org/demos/f64e811fc3311414e083/" into someUrl
         break
      case "Cats"
         put "http://js.cytoscape.org/demos/aedff159b0df05ccfaa5/" into someUrl
         break
      case "Wine"
         put "http://js.cytoscape.org/demos/cde4db55e581d10405f5/" into someURL
         break
      default
         answer file "Enter a url..."
         if it is empty then exit to top
         put it into someURL
   end switch
   -- put someURL
   set the url of svgView to someURL
end menu_SetUrl

on menu_DisplaySvgPane svgView
   put the svg_File of svgView into svgFile
   --
   display_SVG svgFile
end menu_DisplaySvgPane

on menu_DisplaySvgPane svgView
   put the svg_File of svgView into svgFile
   set the svg_File of svgView to svgFile
   --
   put scriptEditor_PaneObject ("Deps") into paneObject
   set the svg_File [true] of control 1 of paneObject to imageFile
   --
   put the svg_File [true] of control 1 of paneObject & CR & svgFile
end menu_DisplaySvgPane

on menu_DisplaySvgHeader svgView
   put the svg_HeaderArray of svgView into svgHeaderArray
   display_Array svgHeaderArray
end menu_DisplaySvgHeader

on menu_DisplaySvgxml svgView
   put the svg_XML of svgView
end menu_DisplaySvgxml

on _
end _

on menu_RevealSvgFile svgView
   put the svg_File of svgView into svgFile
   finder_Reveal svgFile
end menu_RevealSvgFile

on menu_RevealHkeyOverlayFolder svgView
   put the displayed_Hkey of svgView into hKey
   put project_HandlerMetadataFolder (hKey, true) into hkeyMetadataFolder
   put "put project_HandlerMetadataFolder (hKey):" && hkeyMetadataFolder
   finder_Reveal hkeyMetadataFolder
end menu_RevealHkeyOverlayFolder

on menu_RevealProjectOverlayFolder svgView
   put _DisplayedObject (svgView) into scriptObject
   --
   put the project_OverlayFolder of scriptObject into projectOverlayFolder
   put "the project_OverlayFolder:" && projectOverlayFolder
   finder_Reveal projectOverlayFolder
end menu_RevealProjectOverlayFolder

on menu_RevealStackOverlayFolder svgView
   put _DisplayedObject (svgView) into scriptObject
   --
   put the overlay_Folder of scriptObject into overlayFolder
   put "the overlay_Folder:" && overlayFolder
   finder_Reveal overlayFolder
end menu_RevealStackOverlayFolder

on menu_RevealTextStackFolder svgView
   put _DisplayedObject (svgView) into scriptObject
   --
   put the textStack_Folder of scriptObject into textStackFolder
   put "the textStack_Folder:" && textStackFolder
   finder_Reveal textStackFolder
end menu_RevealTextStackFolder

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Experiment displayView
   put displayView
end menu_Experiment


--> Deps
-
