script "Global | Podcast | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Podcast | Line | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-


--> Global | Podcast | Line | Menu
-
on submenu_ListenNotes
   return "Global | ListenNotes | Podcast | Menu"
end submenu_ListenNotes

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
