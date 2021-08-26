script "Global | View | Image| Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | View | Image| Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
on menu_Init tObject
   -- called only once for top menu
   pass menu_Init
end menu_Init

getprop menu_Target [tObject]
   -- called once for each menu
   return tObject
end menu_Target

getprop resizeStyle_Param [vObject]
   put the resize_Style of vObject into rStyle
   return rStyle
end resizeStyle_Param

getprop resizeStyle_Params [vObject]
   put the resize_Styles of vObject into rStyles
   return rStyles
end resizeStyle_Params

getprop checked_BurnImage [vObject]
   put the image_Contents of vObject is not empty into isBurnt
   return isBurnt
end checked_BurnImage


--> Global | View | Image| Menu
-
on menu_SetImageUrl vObject
   put the image_Url of vObject into imageURL
   put lcw_Ask ("Set the image to the conntents of theis url?", imageURL) into imageURL
   set the image_Url of vObject to imageURL
end menu_SetImageUrl

on menu_BurnImage vObject
   put the image_Contents of vObject is not empty into isBurnt
   if isBurnt then
      set the image_Contents of vObject to empty
   else
      set the image_Contents of vObject to someImage
   end if
end menu_BurnImage

on menu_ResizeStyle vObject, rStyle
   set the resize_Style of vObject to rStyle
end menu_ResizeStyle

on _
end _

on submenu_Masked
   return "Global | Image | Masked | Menu"
end submenu_Masked

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on submenu_Authoring
   return "Global | View | Authoring | Menu"
end submenu_Authoring

on submenu_Geometry
   return "Global | View | Geometry | Menu"
end submenu_Geometry



--> Deps
-
