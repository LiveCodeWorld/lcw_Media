script "lib_ListenNotes"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_ListenNotes
type: library
version: 0.2

/*
The ListenNotes API is the best API out there for searching for podcasts.
It is a commercial library, with free limits for a small number of searches.
This library helps interface with that library.

curl -X GET --include 'https://listen-api.listennotes.com/api/v2/podcasts/4d3fe717742d4963a85562e9f84d8c79?next_episode_pub_date=1479154463000&sort=recent_first' \
-H 'X-ListenAPI-Key: <SIGN UP FOR API KEY>'

-- put "https://listennotes.p.rapidapi.com/api/v1/" & apiPath into ListenNotes_RestURL
-- put "https://listennotes.p.mashape.com/api/v1/" & apiPath into ListenNotes_RestURL -- old
*/

--> Variables
-
constant ListenNotes_BaseRestURL = "https://listen-api.listennotes.com/api/v2/"


--> Working on
-
command listenNotes_CreatePodcastWikipage episodeArray, pWikiDomain
   if pWikiDomain is empty then put podcast_GetWikiDomain() into pWikiDomain
   
   put listenNotes_ConstructPodcastPageArray (episodeArray) into pageArray
   --
   put episodeArray ["title"] into podcastTitle
   put fedwiki_ConstructSlug (podcastTitle) into pageSlug
   pageArray_Set pWikiDomain, pageSlug, pageArray
   --
   put the result into wikiUrl
   return wikiUrl
end listenNotes_CreatePodcastWikipage


--> PageArray | ListenNotes
-
command pageArray_AddEpisodeUpdateButton @pageArray, podcastID, pPageTitle
   put platform_RestUrl() & "/podcast/updateRecent" into postURL
   --
   put podcastID into hiddenKeyValueArray ["podcastID"]
   if pPageTitle is not empty then put pPageTitle into hiddenKeyValueArray ["pageTitle"]
   --
   pageArray_AddButton pageArray, "Update Recent", postURL, hiddenKeyValueArray
end pageArray_AddEpisodeUpdateButton


--> Podcast
-
function podcast_ConstructButton podcastTitle, podcastID, pUseLabel, pButtonCommand
   if pButtonCommand is empty then put "importPodcast" into pButtonCommand
   --
   put platform_RestUrl() & "/podcast/" & pButtonCommand into postURL
   --
   if pUseLabel is true then
      put "Import" into buttonName
      put "[[" & podcastTitle & "]]" into pLabel
   else
      put podcastTitle into buttonName
      put empty into pLabel
   end if
   --
   put podcastTitle into inputKeyValueArray ["podcastTitle"]
   put podcastID into inputKeyValueArray ["podcastID"]
   --
   put fedwiki_ConstructButtonForm (buttonName, postURL, inputKeyValueArray, pLabel) into someHTML
   return someHTML
end podcast_ConstructButton

function podcast_ConstructButtonTemplate pUseLabel
   put platform_RestUrl ("/podcast/importPodcast") into postURL
   --
   put "{{podcastTitle}}" into curlyTitle
   if pUseLabel is true then
      put "Import" into buttonName
      put "[[" & curlyTitle & "]]" into pLabel
   else
      put curlyTitle into buttonName
      put empty into pLabel
   end if
   --
   put fedwiki_ConstructButtonForm (buttonName, postURL, "podcastTitle", curlyTitle, pLabel) into someHTML
   return someHTML
end podcast_ConstructButtonTemplate


--> ListenNotes | Fetch
-
function listenNotes_FetchPodcastPageArray podcastID
   put listenNotes_FetchPodcastArray (podcastID) into podcastListData
   put listenNotes_ConstructPodcastPageArray (podcastListData) into pageArray
   return pageArray
end listenNotes_FetchPodcastPageArray

function listenNotes_ConstructPodcastPageArray podcastListData
   local pageArray
   
   put podcastListData ["id"] into podcastID
   put podcastListData ["title"] into podcastTitle
   put podcastListData ["description"] into podcastDescription
   put podcastListData ["rss"] into podcastRSS
   put podcastListData ["thumbnail"] into podcastThumbnail
   put podcastListData ["image"] into podcastImageURL
   put podcastListData ["website"] into podcastURL
   put podcastListData ["total_episodes"] into totalEpisodes
   
   -- construct basic page
   put "Here is a podcast that I need to write  about..." into pageMarkdown
   fedwiki_AddExternalLink pageMarkdown, podcastRSS, "rss"
   put pageArray_Construct (podcastTitle, pageMarkdown) into pageArray
   --
   put podcastTitle && "RSS" into buttonName
   pageArray_AddRssButton pageArray, podcastRSS, buttonName
   --
   put "[[" & podcastTitle & "]]" into imageCaption
   pageArray_AddThumbnail pageArray, podcastImageURL, imageCaption, podcastURL
   --
   put word 1 to -1 of text_HtmlToUtf8 (podcastDescription) into someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown
   --
   pageArray_AddEpisodeUpdateButton pageArray, podcastID, podcastTitle
   --
   pageArray_AddMarkdown pageArray, "# Recent episodes"
   _AddEpisodePodcasts pageArray, podcastListData
   --
   pageArray_AddMarkdown pageArray, "# Metadata"
   _AddPodcastMetadata pageArray, podcastListData
   --
   _addPodcastSearchForm pageArray, podcastID, podcastTitle
   --
   return pageArray
end listenNotes_ConstructPodcastPageArray

function listenNotes_FetchPodcastArray podcastID
   /*
   -- here we just get the most recent 10 episodes from the api
   -- seems to only return 10 recent episodes
   -- we could use the rss to get more
   
   -- v2
   curl -X GET --include 'https://listen-api.listennotes.com/api/v2/podcasts/4d3fe717742d4963a85562e9f84d8c79?next_episode_pub_date=1479154463000&sort=recent_first' \
   -H 'X-ListenAPI-Key: <SIGN UP FOR API KEY>'
   
   -- v1
   curl --request GET \
   --url 'https://rapidapi.p.rapidapi.com/api/v1/podcasts/9d6939745ed34e3aab0eb78a408ab40d?next_episode_pub_date=1479154463000&sort=recent_first' \
   --header 'x-rapidapi-host: listennotes.p.rapidapi.com' \
   --header 'x-rapidapi-key: <SIGN UP FOR API KEY>'
   */
   put "podcasts/" & podcastID into apiPath
   --
   put listenNotes_RestGet (apiPath, empty, "v1") into someJSON
   -- put utf8_Encode (someJSON) into someJSON
   put json_ToArray (someJSON) into responseArray
   return responseArray
end listenNotes_FetchPodcastArray

function listenNotes_FetchUpdatesPodcastPageArray podcastID, pPageTitle, pWikiDoamin
   if pWikiDoamin is empty then put podcast_GetWikiDomain() into pWikiDoamin
   
   put listenNotes_FetchPodcastArray (podcastID) into podcastListData
   put _ConstructEpisodeBody (podcastListData) into storyArray
   --
   if pPageTitle is empty then
      # Get from metadata from podcastID
      put podcastListData ["title"] into pPageTitle
   end if
   
   # Get a Template
   put fedwiki_ConstructSlug (pPageTitle) into pPageSlug
   put pageArray_Fetch (pWikiDoamin, pPageSlug) into pageArray
   --
   pageArray_DeleteSection pageArray, "Recent episodes"
   put the result into itemNumsToDelete
   --
   if itemNumsToDelete = 0 then
      pageArray_AddMarkdown pageArray, "# Recent episodes"
      put the result into lastItemNum
      pageArray_InsertStoryAfter pageArray, storyArray, lastItemNum
   else
      put item 1 of itemNumsToDelete - 1 into titleItemNum
      pageArray_InsertStoryAfter pageArray, storyArray, titleItemNum
   end if
   return pageArray
end listenNotes_FetchUpdatesPodcastPageArray

function listenNotes_GetRecentPodcastSection podcastListData
   put podcastListData ["episodes"] into episodesData
   repeat with itemNum = 1 to item 2 of the extents of episodesData
      put episodesData [itemNum] into episodeArray
      --
      put episodeArray ["audio"] into audioURL
      put _ConstructAudioDescription  (episodeArray) into audioDescription
      pageArray_AddAudio pageArray, audioUrl, audioDescription
   end repeat
   pageArray_ReplaceSectionBody pageArray, "Recent episodes", storyArray
end listenNotes_GetRecentPodcastSection


--> ListenNotes | Episode
-
function listenNotes_FetchEpisodeArray episodeID
   /* curl -X GET -s 'https://listen-api.listennotes.com/api/v2/episodes/6b6d65930c5a4f71b254465871fed370?show_transcript=1' \
   -H 'X-ListenAPI-Key: ed3344a8fe4848fcab48118745da87ff'
   */
   -- curl --get --include 'https://listennotes.p.mashape.com/api/v1/episodes/7fbabe370daf4e34a225bce232764f96'
   --
   put "episodes/" & episodeID into apiPath
   put listenNotes_RestGet (apiPath, empty, "v2") into episodeJson
   --
   replace "\u00a0" with empty in episodeJson -- hack to remove "¬"
   --
   put json_ToArray (episodeJson) into episodeArray
   return episodeArray
end listenNotes_FetchEpisodeArray

function listenNotes_FindEpisode searchTerm, pPodcastID, pExact
   put listenNotes_FetchEpisodeJSON (searchTerm, pPodcastID, pExact) into someJSON
   put json_ToArray (someJSON) into episodeArray
   return episodeArray
end listenNotes_FindEpisode

function listenNotes_FetchEpisodeJSON searchTerm, pPodcastID, pExact
   put "episode" into paramArray ["type"] -- What to search: "episode" (default) or "podcast"?
   --
   if pExact is true then
      put urlencode (searchTerm) into searchTerm
      put kwote (searchTerm, "%22") into searchTerm
      put searchTerm into paramArray ["q"]
   else
      put urlencode (searchTerm) into paramArray ["q"]
   end if
   --
   if pPodcastID is not empty then
      put pPodcastID into paramArray ["ocid"]
   end if
   put listenNotes_RestGet ("search", paramArray) into someJSON
   return someJSON
end listenNotes_FetchEpisodeJSON

function listenNotes_RestGet apiPath, paramArray, pVersion
   switch pVersion
      case "v2"
         -- v2 (witing for API key)
         put ListenNotes_BaseRestURL into restURL
         put listenNotes_GetApiKey() into apiKey
         put "X-ListenAPI-Key:" && apiKey into newHeaders
         break
      default
         -- v1
         put _VersionBaseUrl() into restURL
         put listenNotes_GetRapidApiKey() into apiKey
         put "X-RapidAPI-Key:" && apiKey into newHeaders
   end switch
   
   put apiPath after restURL
   --
   if paramArray is an array then
      combine paramArray using "&" and "="
      put "?" & paramArray after restURL
   end if
   --
   put CR & "Accept: application/json" after newHeaders
   set the httpheaders to newHeaders
   put url restURL into utf8JSON
   --
   put textDecode (utf8JSON, "UTF-8") into rJSON
   replace "\u00a0" with empty in rJSON
   --
   return rJSON
end listenNotes_RestGet


--> ListenNotes | Scrape
-
function listenNotes_PageArrayFromScrape droppedURL
   put listenNotes_FetchEpisodeID (droppedURL) into episodeID
   put listenNotes_ConstructEpisodePageArray (episodeID) into pageArray
   return pageArray
end listenNotes_PageArrayFromScrape

function listenNotes_FetchEpisodeID droppedURL
   put url droppedURL into someHTML
   put listenNotes_EpisodeID (someHtml) into episodeID
   -- put listenNotes_ScrapeEpisodeID (someHtml) into episodeID
   return episodeID
end listenNotes_FetchEpisodeID

function listenNotes_EpisodeID someHtml
   -- put url "https://www.listennotes.com/podcasts/revolutions/725-the-parliament-of-dAFT1JL2irh/" into someHtml
   local episodeID
   --
   put "data-episode-uuid='(.+)'" into sReg
   replace "'" with quote in sReg
   if matchText (someHtml, sReg, episodeID) is true then
      return episodeID
   else
      return empty
   end if
   
   -- another way to do it
   put wordOffset ("data-episode-uuid", someHtml) into wordNum
   if wordNum - 0 then return empty
   put token 7 of word wordNum of someHtml into episodeID 
   return wordNum 
end listenNotes_EpisodeID

function listenNotes_ScrapeEpisodeID someHtml
   -- this scrape is fragile
   -- use "listenNotes_EpisodeID()" instead
   put listenNotes_ScrapeEpisodeAttributeArray (someHtml) into attributeArray
   put attributeArray ["data-episode-uuid"] into episodeID
   return episodeID
end listenNotes_ScrapeEpisodeID

function listenNotes_ScrapePodcastID droppedURL
   /*
   <div class="input-group ln-search-input-container">
   <input type="hidden" name="ocid" value="535815a492a941d79b95be6ae1c5cc9c" />
   <input type="text" name="q" class="form-control ln-search-input" placeholder="people, places, topics..." aria-label="people, places, topics..." required>
   <div class="input-group-append">
   <input class="btn btn-primary" type="submit" value="search" />
   </div>
   */
   put url droppedURL into someHTML
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   if treeID is not a number then return treeID
   --
   put revXMLRootNode (treeID) into rootNode
   -- put revXMLMatchingNode (treeID, rootNode, "div", "class", "input-group ln-search-input-container", -1, false) into divNode
   -- put revXMLAttributeValues (treeID, divNode, "input", "value", comma, 1) into aValues
   -- put revXMLText (treeID , divNode , true) into divHtml
   -- put revXMLMatchingNode (treeID, divNode, "input", "name", "ocid", -1, false) into inputNode
   
   put revXMLMatchingNode (treeID, rootNode, "input", "name", "ocid", -1, false) into inputNode
   -- put revXMLText (treeID , inputNode , true) into inputHtml
   -- put revXMLAttributes (treeID, inputNode, tab, CR) into attributeArray
   -- split attributeArray using CR and tab
   put revXMLAttribute (treeID, inputNode, "value") into podcastID
   --
   revXMLDeleteTree treeID
   --
   return podcastID
end listenNotes_ScrapePodcastID

function listenNotes_ScrapeEpisodeAttributeArray someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   if treeID is not a number then return treeID
   --
   put revXMLRootNode (treeID) into rootNode
   put revXMLMatchingNode (treeID, rootNode, "div", "id", "episode-play-button-toolbar", -1, false) into divNode
   put revXMLAttributes (treeID, divNode, tab, CR) into attributeArray
   --
   revXMLDeleteTree treeID
   --
   split attributeArray using CR and tab
   return attributeArray
end listenNotes_ScrapeEpisodeAttributeArray


--> ListenNotes | Find
-
function listenNotes_FindPodcast podcastTitle, pOnlyIn, pOffset
   /*
   -- put "The+Good+Fight" into paramArray ["q"]
   only_in
   Search only in specific fields. Allowed values: title, description, author, audio. If not specified, then search every fields
   */
   if pOffset is empty then put 0 into pOffset
   --
   put urlencode (podcastTitle) into paramArray ["q"]
   --
   put pOffset into paramArray ["offset"]
   -- put "title" into paramArray ["only_in"]
   put "podcast" into paramArray ["type"]
   --
   put listenNotes_RestGet ("search", paramArray) into jsonResult
   put json_ToArray (jsonResult) into resultArray
   --
   return resultArray
end listenNotes_FindPodcast


--> ListenNotes | Episode | Find
-
function listenNotes_EpisodeSearchPageArray searchTerm
   put listenNotes_FindEpisode (searchTerm) into foundEpisodeData
   put listenNotes_FoundPageArray (foundEpisodeData) into pageArray
   return pageArray
end listenNotes_EpisodeSearchPageArray

function listenNotes_ConstructEpisodePageArray episodeID, pEpisodeURL
   try
      put listenNotes_FetchEpisodeArray (episodeID) into episodeArray
   catch e
      transport_ExitAndReturnError "With listenNotes_FetchEpisodeArray()", "Error"
   end try
   --
   put episodeArray ["description"] into episodeDescriptionHTML
   put episodeArray ["listennotes_url"] into listenURL
   put episodeArray ["title"] into episodeTitle
   put episodeArray ["audio"] into audioURL
   put episodeArray ["image"] into episodeImage
   -- put episodeArray ["thumbnail"] into episodeThumb
   -- put episodeArray ["audio_length"] into audioLength
   -- put episodeArray ["id"] into checkID
   if pEpisodeURL is empty then
      put listenURL into episodeURL
   else
      put pEpisodeURL into episodeURL
   end if
   
   -- construct basic page
   put word 1 to -1 of text_ConvertHtml (episodeDescriptionHTML) into oDescription
   put oDescription into episodeDescription
   put line 1 of episodeDescription into firstPara
   delete line 1 of episodeDescription
   fedwiki_AddExternalLink firstPara, episodeURL
   put fedwiki_CreateMarkdownPageArray (episodeTitle, firstPara) into pageArray
   
   -- add audio
   _AddEpisodeAudioSection pageArray, episodeArray
   
   -- add thumb
   _AddEpisodeImage pageArray, episodeArray
   
   -- add rest of text
   repeat for each line somePara in episodeDescription
      put word 1 to -1 of somePara into nextPara
      if nextPara is empty then next repeat
      pageArray_AddMarkdown pageArray, nextPara
   end repeat
   
   /*
   pageArray_AddMonkeyKeyWordSection pageArray, someText
   */
   
   --now add podcast section
   _AddEpisodePodcastSection pageArray, episodeArray
   --
   return pageArray
end listenNotes_ConstructEpisodePageArray

function listenNotes_FoundPageArray foundEpisodeData
   put foundEpisodeData ["count"] into extentsNum
   -- put item 2 of the extents of resultArray into extentsNum
   if extentsNum is not a number then return empty
   
   put foundEpisodeData ["results"] into resultArray
   put foundEpisodeData ["next_offset"] into nextOffsetNum
   put foundEpisodeData ["took"] into searchTime
   put foundEpisodeData ["total"] into totalResults
   --
   put _ConstructPageArrayTop ("Podcast search results", searchTerm, nextOffsetNum, totalResults, searchTime, extentsNum) into pageArray
   --  
   repeat with itemNum = 1 to extentsNum
      put resultArray [itemNum] into episodeArray
      put episodeArray ["id"] into episodeID
      -- put listenNotes_FetchEpisodeArray (episodeID) into episodeArray
      --
      put episodeArray ["description_original"] into episodeDescription
      put episodeArray ["id"] into episodeID
      --
      put episodeArray ["podcast_id"] into podcastID
      put episodeArray ["podcast_title_original"] into podcastTitle
      --
      put episodeArray ["title_original"] into episodeTitle
      put episodeArray ["thumbnail"] into thumbURL
      put episodeArray ["image"] into episodeImage
      --
      put episodeArray ["audio"] into audioURL
      put episodeArray ["audio_length"] into audioLength
      put episodeArray ["pub_date_ms"] into pubDate
      --
      put episodeArray ["listennotes_url"] into listenURL
      put episodeArray ["podcast_listennotes_url"] into podcastURL
      --
      put word 1 to 40 of episodeDescription & "..." into episodeTeaser
      put text_ConvertHtml (word 1 to -1 of episodeTeaser) into episodeMarkdown
      fedwiki_AddExternalLink episodeMarkdown, listenURL
      --
      put "[[" & episodeTitle & "]]" into thumbCaption
      put fedwiki_ConstructThumbHtml (thumbURL, thumbCaption, listenURL) into thumbHTML
      put thumbHTML & CR & CR & episodeMarkdown into episodeThumbHTML
      put CR & "<p/>" after episodeThumbHTML
      
      -- add button
      put platform_RestUrl ("/podcast/importEpisode") into postURL
      put episodeID into inputKeyValueArray ["episodeID"]
      put fedwiki_ConstructButtonForm ("Import Episode", postURL, inputKeyValueArray, empty, "center") into buttonHTML
      put CR & buttonHTML after episodeThumbHTML
      --
      pageArray_AddHtml pageArray, episodeThumbHTML
      --
      put "[[" & episodeTitle & "]]" && "from the" && "[[" & podcastTitle & "]] podcast" into audioDescription
      pageArray_AddAudio pageArray, audioUrl, audioDescription
      --
      pageArray_AddPagefold pageArray, "."
   end repeat
   pageArray_CleanJournal pageArray
   --
   return pageArray
end listenNotes_FoundPageArray


--> Listen | Notes | Podcast
-
function listenNotes_GetPodcastEpisodeTitleArray resultArray 
   put resultArray ["episodes"] into episodeArray
   put resultArray ["total_episodes"] into totalEpisodes
   --
   repeat with itemNum = 1 to item 2 of the extents of episodeArray -- max 10 episodes
      put episodeArray [itemNum] into itemArray
      --
      put itemArray ["title"] into episodeTitle
      delete variable itemArray ["title"]
      put itemArray into episodeTitleArray [episodeTitle]
   end repeat
   return episodeTitleArray
end listenNotes_GetPodcastEpisodeTitleArray

function listenNotes_ConstructPodcastTitleArray resultArray 
   --  ignoring pagination for now
   put resultArray ["total"] into foundTotal
   put resultArray ["count"] into paginationCount
   put resultArray ["next_offset"] into nextOffset
   
   put resultArray ["results"] into paginatedResultArray
   --
   repeat with itemNum = 1 to item 2 of the extents of paginatedResultArray
      put paginatedResultArray [itemNum] into itemArray
      --
      put itemArray ["title_original"] into podcastTitle
      put item 2 of the extents of podcastTitle [podcastTitle] + 1 into subItemNum
      put itemArray into podcastTitleArray [podcastTitle][subItemNum]
   end repeat
   return podcastTitleArray
end listenNotes_ConstructPodcastTitleArray


--> ListenNotes | Recommendations
-
/*
https://market.mashape.com/listennotes/listennotes#
*/
function listenNotes_FetchEpisodeRecommendations episodeID
   -- curl --get --include 'https://listennotes.p.mashape.com/api/v1/episodes/deecd6ee486f4f47abe61998efc2c0c2/recommendations' \
   put "episodes/" & episodeID & "/recommendations" into apiPath
   put listenNotes_RestGet (apiPath) into someJSON
   return someJSON
end listenNotes_FetchEpisodeRecommendations

function listenNotes_FetchPodcastRecommendations podcastID
   -- curl --get --include 'https://listennotes.p.mashape.com/api/v1/podcasts/25212ac3c53240a880dd5032e547047b/recommendations' \
   put "podcasts/" & podcastID & "/recommendations" into apiPath
   put listenNotes_RestGet (apiPath) into someJSON
   return someJSON
end listenNotes_FetchPodcastRecommendations


--> ListenNotes | Rest
-
function listenNotes_GetApiKey
   put secret_Get ("listenNotesApiKey", "listenNotes") into oAuthToken
   return oAuthToken
end listenNotes_GetApiKey

command listenNotes_SetApiKey oAuthToken
   secret_Set  "listenNotesApiKey", oAuthToken, "listenNotes"
   put the result into modelDataFile
   return modelDataFile
end listenNotes_SetApiKey


--> ListenNotes | Rest | v1
-
function listenNotes_GetRapidApiKey
   put secret_Get ("rapidApiKey", "rapidApi") into oAuthToken
   return oAuthToken
end listenNotes_GetRapidApiKey

command listenNotes_SetRapidApiKey oAuthToken
   secret_Set "rapidApiKey", oAuthToken, "rapidApi"
   put the result into modelDataFile
   return modelDataFile
end listenNotes_SetRapidApiKey


--> Private
-
private command _addPodcastSearchForm @pageArray, podcastID, podcastTitle
   pageArray_Addmarkdown pageArray, "# Search podcast"
   pageArray_Addmarkdown pageArray,  "Use this form to search this podcast for episodes:"
   --
   -- put podcast_ConstructButton (podcastTitle, podcastID, false, "findEpisodeInPodcast") into formHTML
   put "findEpisodeInPodcast" into formHandlerName
   --
   put platform_RestUrl ("/podcast/") & formHandlerName into postURL
   put podcastID into hiddenKeyValueArray ["podcastID"]
   put podcastTitle into hiddenKeyValueArray ["podcastTitle"] -- not needed
   --
   put fedwiki_ConstructSearchForm ("Search podcast", postURL, "search_Term", 54, "Color blue", "right", hiddenKeyValueArray, "darkgreen") into formHTML
   pageArray_AddHtml pageArray, formHTML
   return true
end _addPodcastSearchForm

private function _ConstructSimpleHeader searchTerm, nextOffsetNum, totalResults, searchTime
   put urlencode (searchTerm) into searchTerm
   --
   put platform_RestUrl ("/bbc/listenNotes") into restUrl
   put "<form action='[[restUrl]]/'>" into someForm
   put CR & "Found in [[totalResults]] results ([[searchTime]] seconds)&nbsp;" after someForm
   --
   put CR & "<input name='search_Term' value='[[searchTerm]]'  type='hidden'>" after someForm
   put CR & "<input name='search_Offset' value='[[nextOffsetNum]]' type='hidden'>" after someForm
   --
   put CR & "<button type='submit'>More</button>" after someForm
   put CR & "</form>" after someForm
   --
   return merge (someForm)
end _ConstructSimpleHeader

private function _ConstructEpisodeBody podcastListData
   put podcastListData ["episodes"] into episodesData
   repeat with itemNum = 1 to item 2 of the extents of episodesData
      put episodesData [itemNum] into episodeArray
      put episodeArray ["audio"] into audioURL
      put _ConstructAudioDescription  (episodeArray) into audioDescription
      --
      put itemArray_ConstructAudio (audioUrl, audioDescription) into itemArray
      put itemArray into storyArray [itemNum]
   end repeat
   return storyArray
end _ConstructEpisodeBody

private function _ConstructAudioDescription episodeArray
   put episodeArray ["title"] into episodeTitle
   put episodeArray ["listennotes_url"] into listenURL
   --
   put episodeTitle  into audioDescription
   -- put "." && html_StripAllTags (episodeArray ["description"]) after audioDescription
   fedwiki_AddExternalLink audioDescription, listenURL, "listen"
   --
   return audioDescription
end _ConstructAudioDescription

private command _AddEpisodePodcasts @pageArray, podcastListData
   put podcastListData ["episodes"] into episodesData
   repeat with itemNum = 1 to item 2 of the extents of episodesData
      put episodesData [itemNum] into episodeArray
      --
      put episodeArray ["audio"] into audioURL
      put _ConstructAudioDescription  (episodeArray) into audioDescription
      pageArray_AddAudio pageArray, audioUrl, audioDescription
   end repeat
end _AddEpisodePodcasts

private command _AddPodcastMetadata @pageArray, podcastListData
   put podcastListData ["id"] into someCode ["id"]
   put podcastListData ["title"] into someCode ["title"]
   put podcastListData ["rss"] into someCode ["rss"]
   put podcastListData ["website"] into someCode ["website"]
   put podcastListData ["total_episodes"] into someCode ["total_episodes"]
   --
   combine someCode with CR and ": "
   --
   pageArray_AddCode pageArray, someCode
end _AddPodcastMetadata

private command _AddMultipleParas @pageArray, episodeDescription, listenURL, pOnlyfirst
   put "." & CR into someEnd
   replace ". " with someEnd in episodeDescription
   replace "! " with someEnd in episodeDescription
   put line 1 of episodeDescription into firstPara
   delete line 1 of episodeDescription
   put text_ConvertHtml (word 1 to -1 of firstPara) into someMarkdown
   fedwiki_AddExternalLink someMarkdown, listenURL
   pageArray_AddMarkdown pageArray, someMarkdown
   if pOnlyfirst is true then return 1
   
   repeat for each line someLine in episodeDescription
      put text_ConvertHtml (word 1 to -1 of someLine) into someMarkdown
      pageArray_AddMarkdown pageArray, someMarkdown
   end repeat
   return the number of lines of episodeDescription + 1
end _AddMultipleParas

private command _AddEpisodeAudioSection @pageArray, episodeArray
   local episodeTitle, episodeImage, audioUrl, audioDescription, listenURL
   
   put episodeArray ["title"] into episodeTitle
   put episodeArray ["audio"] into audioURL
   -- put episodeArray ["audio_length"] into audioLength
   -- put episodeArray ["id"] into checkID
   
   put "[[" & episodeTitle & "]]" into linkedTitle
   put linkedTitle into audioDescription
   fedwiki_AddExternalLink audioDescription, listenURL
   pageArray_AddAudio pageArray, audioUrl, audioDescription
end _AddEpisodeAudioSection

private command _AddEpisodeImage @pageArray, episodeArray
   local episodeTitle, episodeImage, audioUrl, audioDescription, listenURL
   
   put episodeArray ["title"] into episodeTitle
   -- put episodeArray ["image"] into episodeImageURL
   put episodeArray ["thumbnail"] into episodeThumbURL
   put episodeArray ["listennotes_url"] into listenURL
   
   put "[[" & episodeTitle & "]]" into linkedTitle
   
   pageArray_AddThumbnail pageArray, episodeThumbURL, linkedTitle, listenURL
end _AddEpisodeImage

private command _AddEpisodePodcastSection @pageArray, episodeArray
   put episodeArray ["podcast"]["publisher"] into publisher
   put episodeArray ["podcast"]["title"] into podcastTitle
   put episodeArray ["podcast"]["description"] into podcastDescription
   put episodeArray ["podcast"]["website"] into podcastURL
   
   --now add podcast section
   pageArray_SetTitle pageArray, podcastTitle
   pageArray_AddMarkdown pageArray, podcastDescription
   
   --now add podcast image
   put episodeArray ["podcast"]["image"] into imageURL
   put episodeArray ["podcast"]["thumbnail"] into thumbURL
   --
   put "[[" & podcastTitle & "]] by" && publisher into podcastCaption
   --
   pageArray_AddThumbnail pageArray, imageURL, podcastCaption, podcastURL
   return podcastMarkdown
end _AddEpisodePodcastSection

private function _VersionBaseUrl
   put "https://listennotes.p.rapidapi.com/api/v1/" into baseURL
   return baseURL
end _VersionBaseUrl

private function _ConstructPageArrayTop pageTitle, searchTerm, nextOffsetNum, totalResults, searchTime, extentsNum
   /*
   Not quite sure what maxNum is. = totalResults - nextOffsetNum ?
   */
   put extentsNum && "results" into foldText
   
   switch -- different headers depending on pagination state
      case totalResults = 0
         put pageArray_Construct ("No result found.", "Search for something a bit more interesting...") into pageArray
         return pageArray
      case nextStartIndex is empty
         -- no more found after this. Provide some other options?
         put merge ("Found in [[totalResults]] results ([[searchTime]] seconds)<p>") into someHTML
         break
      default
         -- there are more to paginate
         put _ConstructSimpleHeader (searchTerm, nextOffsetNum, totalResults, searchTime) into someHTML
   end switch
   --
   put pageTitle into pageArray ["title"]
   pageArray_AddHtml pageArray, someHTML
   put journalArray_Construct (pageTitle) into pageArray ["journal"] 
   --
   pageArray_AddPagefold pageArray, foldText
   return pageArray
end _ConstructPageArrayTop


--> Deps
-
-- function secret_Get secretName
   -- for server use only
   if the environment is not "server" then pass "secret_Get"
   --
   put rigFetchConfigItem (secretName) into someSecret
   return someSecret
end secret_Get
