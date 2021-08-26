script "Global | ListenNotes | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | ListenNotes | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
getprop displayRss_Params
   put the hkey_CaseConditions ["M menu_DisplayRss"] of me into caseConditions
   return caseConditions
end displayRss_Params


--> Global | ListenNotes | Menu
-
on menu_DisplayRss displayView, whichRSS
   switch whichRSS
      case "The Cosmic Portal"
         put "https://feeds.buzzsprout.com/1279940.rss" into rssURL
         break
      case "Daring Fireball"
         put "https://daringfireball.net/feeds/main" into rssURL
         break
      case "Daring Fireball Talkshow"
         put "https://daringfireball.net/thetalkshow/rss" into rssURL
         break
      case "The Guardian"
         put "https://www.theguardian.com/uk/rss" into rssURL
         break
      case "Radiolab"
         put "http://feeds.wnyc.org/radiolab" into rssURL
         break
      case "2017 Wiki Journal"
         put "http://future.fedwiki.org/plugin/rss/2017-journal.xml" into rssURL
         break
      case "Google Alert Feed"
         put "https://www.google.com/alerts/feeds/07925126973483736542/15837936957629622679" into rssURL
         break
      case "BBC London News"
         put "http://feeds.bbci.co.uk/news/england/london/rss.xml" into rssURL
         break
      case "Science Alert"
         put "https://feeds.feedburner.com/sciencealert-latestnews" into rssURL
         break
   end switch
   --
   
   local pFilterDate, pTitle, pWikiDomain, pDisplayStyle, pCleanHow
   -- put "Thu, 8 Oct 2020 07:44:00 -0500" into pFilterDate
   put "raw" into pCleanHow
   --
   put rss_GetPageArray (rssURL, pFilterDate, pTitle, pWikiDomain, pDisplayStyle, pCleanHow) into pageArray
   --
   display_PageArray pageArray
end menu_DisplayRss

on menu_ListenNotesImportTest
   put "ea21dda2f7324cd585072c5a9d24f00a" into podcastID
   --
   put listenNotes_FetchPodcastPageArray (podcastID) into pageArray
   display_PageArray pageArray
end menu_ListenNotesImportTest

on _
end _

on menu_FetchPodcasts
   display_PodCasts
   put the result into displayView
end menu_FetchPodcasts

on menu_StorePodcasts displayView
   -- put podclub_FetchPodcastIndex() into podcastIndex
   set the cursor to watch
   put the displayed_Index of displayView into podcastIndex
   sort podcastIndex
   --
   podclub_StorePodcastIndex podcastIndex
   put the result into indexURL
   --
   set the displayed_Index of displayView to podcastindex
   --
   launch url indexURL
end menu_StorePodcasts

on _
end _

on menu_FindPodcast
   display_FindPodcast
end menu_FindPodcast

on menu_FindLocal
   put lcw_Ask ("What would you like to search for?", "liquid") into searchTerm
   --
   put listenNotes_EpisodeSearchPageArray (searchTerm) into pageArray
   fedwiki_ReturnPageArray pageArray
end menu_FindLocal

on menu_FindEpisode
   put lcw_Ask ("What would you like to search for?", "liquid") into searchTerm
   --
   put "https://rest.livecode.world/podcast/findEpisode" into restUrl
   put searchTerm into postArray ["search_Term"]
   put json_FromArray (postArray) into someJSON
   put jsonrpc_POST (someJSON, restUrl)
end menu_FindEpisode

on _
end _

on menu_Documentation
   launch url listenNotes_ApiDocumentationUrl()
end menu_Documentation

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_TestEpisode
   put "https://rest.livecode.world/podcast/importEpisode" into postURL
   put "c2262fec307f40f79bc46ddc3b0fcb69" into episodeID
   put listenNotes_ConstructEpisodePageArray (episodeID) into pageArray
   display_PageArray pageArray
end menu_TestEpisode

on menu_DisplayPodcastTitleArray displayView
   put the podcast_TitleArray of displayView into podcastTitleArray
   --
   display_Data podcastTitleArray, "podcast_TitleArray"
end menu_DisplayPodcastTitleArray

on menu_RapidApiDocumentation displayView
   /*
   Actually, Listen API v2 is (almost) backward compatible with v1 (as of May, 2019), in terms of endpoints, parameters, and JSON responses. The pricing of v2 is simpler.
   We hosted Listen API v1 on RapidAPI who handled analytics and billing for us. As Listen Notes grows as a business, we need more customization and flexibility than the 3rd party platform RapidAPI can provide. Thus, we built Listen API v2 to replace RapidAPI.
   To migrate to Listen API v2, you just need to follow three steps:
   Subscribe to either the FREE or PRO plan on this page.
   In your code, change the base url to https://listen-api.listennotes.com, change the version number to v2 in all endpoints, and use the new API key in the X-ListenAPI-Key header. You can simply copy the entire endpoint url from the docs page.
   Contact us at hello@listennotes.com, so we can turn on the "backward-compatible" mode for you. Otherwise, there are some minor discrepancies for the API response between v1 and v2.
   Listen API v1's response headers X-RateLimit-* don't exist in v2. Instead, you can find response headers X-ListenAPI-FreeQuota and X-ListenAPI-Usage when using Listen API v2.
   We will keep Listen API v1 up and running. Please take your time to migrate to v2. All the future improvements will only go to Listen API v2.
   */
   
   launch url "https://rapidapi.com/listennotes/api/listennotes/"
end menu_RapidApiDocumentation


--> Deps
-
