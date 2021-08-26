script "Global | Podcast | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Podcast | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.
*/


--> Variables
-
local LocalArray


--> Menu | Init
-
on menu_Init tObject   
   -- do something when the menu first loads
   
   put the display_View of tObject into displayView
   --
   put the data_Array of displayView into LocalArray ["dataArray"]
end menu_Init


--> Global | Podcast | Menu
-
on menu_DisplayCuratedPodcast
   display_CuratedPodcasts
end menu_DisplayCuratedPodcast

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_EditPodcastLibs displayView
   edit the script of stack "lib_Podcast"
   edit the script of stack "lib_ListenNotes"
   edit the script of stack "lib_OmnyStudio"
   edit the script of stack "lib_Audioboom"
end menu_EditPodcastLibs

on menu_UnloadSitempas
   fedwiki_UnloadSitemaps
end menu_UnloadSitempas


--> Deps
-
