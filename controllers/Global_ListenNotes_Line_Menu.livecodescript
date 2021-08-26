script "Global | ListenNotes | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | ListenNotes | Line | Menu
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
   put the display_View of tObject into displayView
   --
   put the podcast_TitleArray of displayView into LocalArray ["podcastTitleArray"]
   put the found_PodcastArray of displayView into LocalArray ["foundPodcastArray"]
   --
   return displayView
end menu_Target

function _GetPodcastArray displayView
   put _GetPodcastTitle (displayView) into podcastTitle
   --
   put LocalArray ["podcastTitleArray"][podcastTitle] into podcastData
   put podcastData [1] into podcastArray
   --
   if item 2 of the extents of podcastData > 1 then
      lcw_Answer "Found more than one hit. Choose one?"
      display_Data podcastData, podcastTitle
   end if
   return podcastArray
end _GetPodcastArray

function _GetPodcastListData displayView
   put _GetPodcastTitle (displayView) into podcastTitle
   --
   put LocalArray ["podcastTitleArray"] into podcastTitleArray
   put podcastTitleArray [podcastTitle] into podcastData
   --
   return podcastData
end _GetPodcastListData

function _GetPodcastID displayView
   put _GetPodcastArray (displayView) into podcastArray
   put podcastArray ["id"] into podcastID
   return podcastID
end _GetPodcastID

function _GetPodcastTitle displayView
   put the selected_Line of displayView into podcastTitle
   return podcastTitle
end _GetPodcastTitle


--> Global | ListenNotes | Line | Menu
-
on menu_Fixmetadata displayView
   put _GetPodcastTitle (displayView) into podcastTitle
   --
   put podclub_FetchPocastMetadata (podcastTitle) into mData
   put mData ["podcastID"] into podcastID
   if podcastID is not empty then
      put listenNotes_FetchPodcastArray (podcastID) into podcastListData
      --
      display_Data podcastListData, "podcastListData", "Podclub Podcasts"
   else
      lcw_Answer "Metadata is broken!"
   end if
end menu_Fixmetadata

on menu_DisplayPodcastEpisodes displayView
   put _GetPodcastID (displayView) into podcastID
   --
   display_PodcastEpisodes podcastID
end menu_DisplayPodcastEpisodes

on menu_FindPodcastEpisode displayView
   put _GetPodcastTitle (displayView) into podcastTitle
   put _GetPodcastID (displayView) into podcastID
   --
   put merge ("What would you like to search for in podcast '[[podcastTitle]]'?") into someQuestion
   put lcw_Ask (someQuestion, "Color blue", displayView) into searchTerm
   put text_IsQuoted (searchTerm) into pExact
   --
   put listenNotes_FindEpisode (searchTerm, podcastID, pExact) into foundEpisodeData
   put listenNotes_FoundPageArray (foundEpisodeData) into pageArray
   --
   display_Data foundEpisodeData, podcastTitle, "Found Episodes"
   display_PageArray pageArray
end menu_FindPodcastEpisode

on _
end _

on menu_CreatePodcastPage displayView
   put _GetPodcastID (displayView) into podcastID
   put listenNotes_FetchPodcastArray (podcastID) into podcastListData
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

on menu_ViewOnListenNotes displayView
   -- https://www.listennotes.com/c/535815a492a941d79b95be6ae1c5cc9c/
   put _GetPodcastArray (displayView) into podcastArray
   --
   put podcastArray ["listennotes_url"] into listenNotesURL
   launch url listenNotesURL
end menu_ViewOnListenNotes

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_DisplayPodcastArray displayView
   put the podcast_TitleArray of displayView into podcastData
   --
   display_Data podcastData, "podcast_TitleArray"
end menu_DisplayPodcastArray


--> Deps
-
