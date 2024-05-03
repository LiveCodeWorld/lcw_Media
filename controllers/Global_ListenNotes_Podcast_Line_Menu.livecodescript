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
getprop menu_Target [tObject]   
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop menu_CheckTarget [dView]
   return true
end menu_CheckTarget


--> Global | ListenNotes | Podcast | Line | Menu
-
on menu_DisplayEpisodeArray dView
   put the parent_Array ["id"] of dView into episodeID
   --
   put listenNotes_FetchEpisodeArray (episodeID) into episodeArray
   --
   put episodeArray ["title"] into episodeTitle
   display_Data episodeArray, episodeTitle, "listenNotes_FetchEpisodeArray()"
end menu_DisplayEpisodeArray

on _
end _

on menu_Test dView
   put the parent_Array ["id"] of dView
end menu_Test

on submenu_Dev
   return menu_DevTitle ("Global | ListenNotes | Podcast | Line | Menu")
end submenu_Dev
