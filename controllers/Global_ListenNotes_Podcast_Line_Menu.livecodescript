script "Global | ListenNotes | Podcast | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | ListenNotes | Podcast | Line | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-


--> Global | ListenNotes | Podcast | Line | Menu
-
on menu_DisplayEpisodeArray displayView
   put the top_Line of displayView 
   put the parent_Array ["id"] of displayView into episodeID
   --
   put listenNotes_FetchEpisodeArray (episodeID) into episodeArray
   display_Data episodeArray, "episodeArray", "ListenNotes"
end menu_DisplayEpisodeArray

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
