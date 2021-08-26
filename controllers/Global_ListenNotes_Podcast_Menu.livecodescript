script "Global | ListenNotes | Podcast | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | ListenNotes | Podcast | Menu
type: controller
version: 0.1

/*
*/


--> Variables
-
local LocalArray


--> Menu | Init
-
getprop menu_Target [tObject]   
   put the display_View of tObject into displayView
   put the podcast_ListData of displayView into podcastListData
   put podcastListData ["id"] into podcastID
   -- 
   put podcastListData into LocalArray ["podcastListData"]
   return podcastID
end menu_Target


--> Global | ListenNotes | Podcast | Menu
-
on menu_CreatePodcastPage podcastID
   put LocalArray ["podcastListData"] into podcastListData
   --
   listenNotes_CreatePodcastWikipage podcastListData
   put the result into wikiUrl
   if item 1 of wikiUrl = "error" then
      -- Error, scp: /root/.wiki/wikiDomian/pages/radiolab: No such file or directory
      lcw_AnswerWarning wikiUrl, displayView
   else
      launch url wikiUrl
   end if
end menu_CreatePodcastPage

on _
end _

on menu_DisplayRss podcastID
   put LocalArray ["podcastListData"] into podcastListData
   --
   put podcastListData ["title"] into podcastTitle
   put podcastListData ["description"] into podcastDescription
   put podcastListData ["rss"] into podcastRSS
   --
   put url podcastRSS into someRSS
   put rss_ConstructArray (someRSS) into rssArray
   --
   display_Data rssArray, podcastTitle, "RSS"
   atom_DisplayText someRSS, "rss"
end menu_DisplayRss

on menu_DisplayDataGrid podcastID
   put LocalArray ["podcastListData"] into podcastListData
   --
   put podcastListData ["title"] into podcastTitle
   display_View "View|Tree|Datagrid", podcastTitle, "Podcast"
   put the result into displayView
   --
   put the behavior of displayView into bObject
   edit the script of bObject
end menu_DisplayDataGrid

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_DisplayPodcastPageArray podcastID
   put listenNotes_FetchPodcastPageArray (podcastID) into pageArray
   display_PageArray pageArray
end menu_DisplayPodcastPageArray

on menu_FindEpisode podcastID
   put LocalArray ["podcastListData"] into podcastListData
   --
   put listenNotes_FetchEpisodeArray (podcastID) into episodeArray
end menu_FindEpisode


--> Deps
-
command listenNotes_DeconstructEpisodeArray episodeArray, @episodeID, @episodeTitle
   put episodeArray ["id"] into episodeID
   put episodeArray ["title"] into episodeTitle
   put episodeArray ["description"] into podcastDescription
   put episodeArray ["rss"] into podcastRSS
   put episodeArray ["thumbnail"] into podcastThumbnail
   put episodeArray ["image"] into podcastImage
   put episodeArray ["website"] into podcastURL
   put episodeArray ["total_episodes"] into totalEpisodes
end listenNotes_DeconstructEpisodeArray
