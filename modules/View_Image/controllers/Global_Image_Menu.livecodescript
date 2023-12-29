script "Global | Image | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Image | Menu
type: controller
version: 0.1

/*
A general menu to help with displaying images..
*/


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

on menu_ExportImage imageObject
   put the image_File of imageObject into imageFile
end menu_ExportImage

private on _
end _

on menu_DownloadFolder
   put the home folder & "/Downloads/" into downloadFolder
   finder_Reveal downloadFolder
end menu_DownloadFolder

on menu_DisplayProject imageObject
   put the template_Object of imageObject into tObject
   --
   put the project_Name of tObject into projectName
   display_Project projectName
end menu_DisplayProject

on menu_EditBehavior imageObject
   put the behavior of imageObject into bObject
   edit the script of bObject
end menu_EditBehavior

private on __
end __

on menu_ImageTemplate
   put view_GetTemplateObject ("View|Image") into tObject
   object_GoTo tObject
end menu_ImageTemplate

on menu_SvgButtonTemplate
   put view_GetTemplateObject ("View|Button|Svg") into tObject
   object_GoTo tObject
end menu_SvgButtonTemplate

on menu_FitInsideTemplate
   put view_GetTemplateObject ("View|Image|Fit Inside") into tObject
   object_GoTo tObject
end menu_FitInsideTemplate

private on ___
end ___

on submenu_Dev
   return menu_DevTitle()
end submenu_Dev

