script "Global | Image | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Image | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-


--> Global | Image | Menu
-
on menu_ImportSvg imageObject
   put the home folder & "/Downloads/" into downloadFolder
   answer file "Please select an SVG file:" with downloadFolder with type "SVG svg|SVG" -- "SVG:*.svg"
   if the result is "Cancel" then exit to top
   
   put it into tSVGFile
   put drawingSvgCompileFile (tSVGFile) into svgImage
   set the text of imageObject to svgImage
end menu_ImportSvg


on menu_DownloadFolder
   put the home folder & "/Downloads/" into downloadFolder
   finder_Reveal downloadFolder
end menu_DownloadFolder

private command _
end _

on menu_DisplayProject imageObject
   put the template_Object of imageObject into tObject
   --
   put the project_Name of tObject into projectName
   display_Project projectName
end menu_DisplayProject

on menu_GoView
   put "View|Image|Fit Inside" into vName
   --
   put view_GetTemplateObject (vName) into tObject
   object_GoTo tObject
   put tObject
end menu_GoView
