script "lib_DisplayListenNotes"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_DisplayListenNotes
type: library
version: 0.1

/*
We put the display handlers here so that we can document a clean lib_ListenNotes library.
*/


--> Working on
-
command listenNotes_CreatePodcastWikipage episodeArray, pWikiDomain
   if pWikiDomain is empty then put "cast.pod.club" into pWikiDomain
   
   put listenNotes_ConstructPodcastPageArray (episodeArray) into pageArray
   --
   put episodeArray ["title"] into podcastTitle
   put fedwiki_ConstructSlug (podcastTitle) into pageSlug
   pageArray_Set pWikiDomain, pageSlug, pageArray
   --
   put the result into wikiUrl
   return wikiUrl
end listenNotes_CreatePodcastWikipage

function listenNotes_ApiDocumentationUrl
   return "https://www.listennotes.com/api/docs/"
end listenNotes_ApiDocumentationUrl


--> Display | ListenNotes
-
on mDoubleUp_Podcast fldObject, podcastTitle
   put the display_View of fldObject into displayView
   --
   put the podcast_TitleArray of displayView into podcastTitleArray
   put podcastTitleArray [podcastTitle][1] into podcastArray
   --
   put podcastArray ["id"] into podcastID
   display_PodcastEpisodes podcastID
end mDoubleUp_Podcast

command display_PodCasts
   put podclub_FetchPodcastIndex() into podcastIndex
   --
   display_Data podcastIndex, "Podcasts", "Pod Club"
   put the result into displayView
   --
   display_SetInteractions displayView, "ListenNotes", "mDoubleUp_Podcast"
end display_PodCasts

command display_FindPodcast pSearchTerm
   if pSearchTerm is empty then
      put lcw_Ask ("What podcast would you like to search for?", "To the Best of Our Knowledge") into pSearchTerm
   end if
   --
   put listenNotes_FindPodcast (pSearchTerm) into foundPodcastArray
   -- put listenNotes_FindPodcast (pSearchTerm, 10) into nextPodcastArray
   --
   put listenNotes_ConstructPodcastTitleArray (foundPodcastArray) into podcastTitleArray
   --
   put the keys of podcastTitleArray into  podcastTitles
   display_Data podcastTitles, "Podcasts", "Listen Notes"
   put the result into displayView
   --
   display_SetInteractions displayView, "ListenNotes", "mDoubleUp_Podcast"
   --
   set the podcast_TitleArray of displayView to podcastTitleArray
   set the found_PodcastArray of displayView to foundPodcastArray
end display_FindPodcast

command display_PodcastEpisodes podcastID
   put listenNotes_FetchPodcastArray (podcastID) into podcastListData
   --
   put podcastListData ["title"] into podcastTitle
   put listenNotes_GetPodcastEpisodeTitleArray (podcastListData) into episodeTitleArray
   --
   display_Data episodeTitleArray, podcastTitle, "Podcast"
   put the result into displayView
   --
   set the title_Menu of displayView to "Global | ListenNotes | Podcast | Menu"
   set the line_Menu of displayView to "Global | ListenNotes | Podcast | Line | Menu"
   set the mouse_DoubleUp of displayView to "mDoubleUp_Episode"
   --
   -- set the episode_TitleArray of displayView to episodeTitleArray
   set the podcast_ListData of displayView to podcastListData
   return displayView
end display_PodcastEpisodes
