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
private function _ChooseImageFile imageObject
   # Choose export location
   put the image_Folder of imageObject into imageFolder
   get the stack_Label of imageObject
   put it & ".png" into shortFile
   
   put imageFolder & shortFile into imageFile
   ask file prompt with imageFile
   if it is empty then return empty
   
   put it into imageFile
   return imageFile
end _ChooseImageFile


--> Global | Image | Menu
-
on menu_ImportSvg imageObject
   put the image_Folder of imageObject into imageFolder
   answer file "Please select an SVG file:" with imageFolder with type "SVG svg|SVG" -- "SVG:*.svg"
   if the result is "Cancel" then exit to top
   
   put it into tSVGFile
   put drawingSvgCompileFile (tSVGFile) into svgImage
   set the text of imageObject to svgImage
end menu_ImportSvg

on menu_ExportImage imageObject
   -- put the image_File of imageObject into imageFile
   put the image_Contents of imageObject into someImage
   
   put _ChooseImageFile (imageObject) into imageFile
   put someImage into url ("binfile:/" & imageFile)
end menu_ExportImage

private on _
end _

on menu_RevealImageFolder imageObject
   put the image_Folder of imageObject into imageFolder
   finder_Reveal imageFolder
end menu_RevealImageFolder

on menu_SetImageFolder imageObject
   put the image_Folder of imageObject into imageFolder
   
   answer folder prompt with imageFolder
   if it is emty then exit to top
   put it into imageFolder
   
   set the image_Folder of imageObject to imageFolder
end menu_SetImageFolder

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

