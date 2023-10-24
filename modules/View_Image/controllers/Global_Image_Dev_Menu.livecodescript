script "Global | Image | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Image | Dev | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target


--> Global | Image | Dev | Menu
-
on menu_ImageData imageView
   put the icon_Data of imageView into iconData
   display_Data iconData, "iconData"
end menu_ImageData

private on _
end _

on menu_FetchIconPath imageView
   put the icon_Data of imageView into iconData
   put iconData ["id"] into iconID
   --
   put noun_FetchIconPath (iconID)
end menu_FetchIconPath

on menu_DownloadIcon imageView
   put the icon_Data of imageView into iconData
   put iconData ["id"] into iconID
   --
   put noun_DownloadIcon (iconID) into downloadData
   display_Data downloadData, "noun_DownloadIcon()"
end menu_DownloadIcon
