script "lib_Podcast"
--> MetaData
-
license: GPLv3
name: lib_Podcast
type: library
version: 0.2
deps: lib_Scrape

/*
This library is for manipulating and organising podcasts.
Work in progress.

*/


--> Working on
-
function playerfm_ConstructPageArray playerfmArray
   put playerfmArray ["id"] into episodeID
   put playerfmArray ["title"] into pageTitle
   put playerfmArray ["description"] into podcastDescription
   put playerfmArray ["url"] into audioUrl
   put playerfmArray ["share"] into shareUrl
   --
   put playerfmArray ["series"]["imageURL"] into imageURL
   put playerfmArray ["series"]["url"] into seriesURL
   put playerfmArray ["series"]["id"] into seriesID
   --
   text_StripTags podcastDescription
   put podcastDescription into firstPara
   put podcastDescription into audioDescription
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, audioDescription) into pageArray
   --
   return pageArray
end playerfm_ConstructPageArray


--> Podcast
-
/*
These handlers are share by several podcast libs / sections.
*/

function podcast_ConstructPageArray pageTitle, audioURL, imageURL, firstPara, podcastDescription, audioDescription
   put fedwiki_ConstructNewPageArray (pageTitle, firstPara) into pageArray
   if imageURL is not empty then
      put fedwiki_ConstructImageDiv (imageURL) into imageHTML
      pageArray_AddHtml pageArray, imageHTML
   end if
   
   repeat with lineNum = 2 to the number of lines of podcastDescription
      put word 1 to -1 of line lineNum of podcastDescription into somePara
      pageArray_AddText pageArray, somePara
   end repeat
   pageArray_AddAudio pageArray, audioURL, audioDescription
   pageArray_CleanJournal pageArray
   return pageArray
end podcast_ConstructPageArray


--> ListenNotes | Fedwiki | Episode
-
function listenNotes_ConstructEpisodePageArray episodeID, pEpisodeURL
   put listenNotes_FetchEpisodeInfo (episodeID) into episodeJson
   put json_ToArray (episodeJson) into episodeArray
   --
   put episodeArray ["description"] into episodeDescription
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
   fedwiki_AddExternalLink episodeDescription, episodeURL
   put fedwiki_CreateMarkdownPageArray (episodeTitle, episodeDescription) into pageArray
   
   -- add audio item
   put episodeTitle & "." && episodeDescription into audioDescription
   fedwiki_AddExternalLink pageDescription, listenURL
   pageArray_AddAudio pageArray, audioUrl, audioDescription
   
   -- add episode image
   fedwiki_AddImageToPageArray pageArray, episodeImage, episodeTitle, episodeURL
   
   --now add podcast section
   listenNotes_AddPodcastMarkdown pageArray, episodeArray
   --
   return pageArray
end listenNotes_ConstructEpisodePageArray

command listenNotes_AddPodcastMarkdown @pageArray, episodeArray
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
   fedwiki_AddImageToPageArray pageArray, imageURL, podcastCaption, podcastURL
   return podcastMarkdown
end listenNotes_AddPodcastMarkdown


--> ListenNotes | Fedwiki
-
function listenNotes_ScrapeEpisodeID droppedURL
   -- https://www.listennotes.com/embedded/e/057a4b22462e4d48ad37516bb8c2cd08/
   -- meta - name="twitter:player" content="https://www.listennotes.com/embedded/e/057a4b22462e4d48ad37516bb8c2cd08/"
   -- div id episode-play-button-toolbar
   
   put scrape_FetchTwitterMeta ("player", droppedURL) into listenURL
   set the itemdelimiter to slash
   put item 6 of listenURL into episodeID
   return episodeID
end listenNotes_ScrapeEpisodeID

function listeNotes_SearchAndConstructPageArray searchTerm
   put listenNotes_FindEpisode (searchTerm) into someJSON
   put json_ToArray (someJSON) into listenNotesEpisodeArray
   -- display_Array listenNotesEpisodeArray, "listenNotes_FindEpisode()"
   
   put listenNotesEpisodeArray ["results"] into resultArray
   put listenNotesEpisodeArray ["next_offset"] into nextOffsetNum
   put listenNotesEpisodeArray ["took"] into searchTime
   put listenNotesEpisodeArray ["total"] into totalResults
   -- put item 2 of the extents of resultArray into extentsNum
   put listenNotesEpisodeArray ["count"] into extentsNum
   --
   put listenNotes_ConstructPageArrayTop ("Podcast search results", searchTerm, nextOffsetNum, totalResults, searchTime, extentsNum) into pageArray
   --
   repeat with itemNum = 1 to extentsNum
      put resultArray [itemNum] into itemArray
      put itemArray ["id"] into episodeID
      --
      put listenNotes_FetchEpisodeInfo (episodeID) into episodeJson
      put json_ToArray (episodeJson) into episodeArray
      --
      put itemArray ["description_original"] into episodeDescription
      put episodeArray ["id"] into checkID
      --
      put episodeArray ["title"] into episodeTitle
      put episodeArray ["thumbnail"] into episodeThumb
      put episodeArray ["image"] into episodeImage
      --
      put episodeArray ["audio"] into audioURL
      put episodeArray ["audio_length"] into audioLength
      put episodeArray ["description"] into episodeHTML
      --
      -- display_Array episodeArray, "listenNotes_FetchEpisodeInfo()"
      
      listenNotes_AddAudio pageArray, episodeTitle, episodeDescription, audioURL
   end repeat
   pageArray_CleanJournal pageArray
   --
   -- display_Array pageArray, "ListenNotes PageArray"
   return pageArray
end listeNotes_SearchAndConstructPageArray

private function listenNotes_ConstructPageArrayTop pageTitle, searchTerm, nextOffsetNum, totalResults, searchTime, extentsNum
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
         put listenNotes_ConstructSimpleHeader (searchTerm, nextOffsetNum, totalResults, searchTime) into someHTML
   end switch
   --
   put pageTitle into pageArray ["title"]
   pageArray_AddHtml pageArray, someHTML
   put pageArray_ConstructJournal (pageTitle) into pageArray ["journal"] 
   --
   pageArray_AddPagefold pageArray, foldText
   return pageArray
end listenNotes_ConstructPageArrayTop

private function listenNotes_ConstructSimpleHeader searchTerm, nextOffsetNum, totalResults, searchTime
   put urlencode (searchTerm) into searchTerm
   --
   put "<form action='https://rest.livecode.world/bbc/listenNotes'>" into someForm
   put CR & merge ("Found in [[totalResults]] results ([[searchTime]] seconds)&nbsp;") after someForm
   --
   put CR & merge ("<input name='search_Term' value='[[searchTerm]]'  type='hidden'>") after someForm
   put CR & merge ("<input name='search_Offset' value='[[nextOffsetNum]]' type='hidden'>") after someForm
   --
   put CR & "<button type='submit'>More</button>" after someForm
   put CR & "</form>" after someForm
   return someForm
end listenNotes_ConstructSimpleHeader


--> ListenNotes | API
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

function listenNotes_FetchPodcastEpisodes podcastID
   /*
   put listenNotes_FetchPodcastEpisodes ("9d6939745ed34e3aab0eb78a408ab40d")
   -- id for a specific podcast. You can get id from search api's response.
   curl --get --include 'https://listennotes.p.mashape.com/api/v1/podcasts/9d6939745ed34e3aab0eb78a408ab40d' \
   */
   put "podcasts/" & podcastID into apiPath
   put listenNotes_RestGet (apiPath) into someJSON
   return someJSON
end listenNotes_FetchPodcastEpisodes

function listenNotes_FetchEpisodeInfo episodeID
   -- curl --get --include 'https://listennotes.p.mashape.com/api/v1/episodes/7fbabe370daf4e34a225bce232764f96'
   --
   put "episodes/" & episodeID into apiPath
   put listenNotes_RestGet (apiPath) into someJSON
   return someJSON
end listenNotes_FetchEpisodeInfo

function listenNotes_FindEpisode searchTerm, pExact
   /*
   curl --get --include 'https://listennotes.p.mashape.com/api/v1/search?q=%22A+young+woman+at+a+bar+is+slapped+on+the+butt%22'
   curl --get --include 'https://listennotes.p.rapidapi.com/api/v1/search
   ?sort_by_date=0
   &type=episode
   &offset=0
   &only_in=title
   &language=English
   &ocid=36f02b0c82994118b9f226867d755937
   &q=%22A+Short+History+Of+Story%22' \
         -H 'X-RapidAPI-Key: PBcK3YtG6hMBoA2BjGFiPi7GnxjZFuzR'
   */
   
   if pExact is true then
      put urlencode (searchTerm) into searchTerm
      put kwote (searchTerm, "%22") into searchTerm
      put searchTerm into paramArray ["q"]
   else
      put urlencode (searchTerm) into paramArray ["q"]
   end if
   --
   -- put 0 into paramArray ["offset"]
   -- put "episode" into paramArray ["type"] -- What to search: "episode" (default) or "podcast"?
   --
   put listenNotes_RestGet ("search", paramArray) into someJSON
   return someJSON
end listenNotes_FindEpisode

function listenNotes_FindPodcast podcastTitle
   /*
   -- put "The+Good+Fight" into paramArray ["q"]
   only_in
   Search only in specific fields. Allowed values: title, description, author, audio. If not specified, then search every fields
   */
   
   put urlencode (podcastTitle) into paramArray ["q"]
   --
   put 0 into paramArray ["offset"]
   put "title" into paramArray ["only_in"]
   put "podcast" into paramArray ["type"]
   --
   put listenNotes_RestGet ("search", paramArray) into someJSON
   return someJSON
end listenNotes_FindPodcast


--> ListenNotes | Auth
-
function listenNotes_RestGet apiPath, paramArray
   put "https://listennotes.p.rapidapi.com/api/v1/" & apiPath into restURL
   -- put "https://listennotes.p.mashape.com/api/v1/" & apiPath into restURL
   --
   if paramArray is an array then
      combine paramArray using "&" and "="
      put "?" & paramArray after restURL
   end if
   --
   /*
   put listenNotes_GetMashapeKey() into mashapeKey
   put "X-Mashape-Key:" && mashapeKey into newHeaders
   */
   put listenNotes_GetRapidApiKey() into rapidApiKey
   put "X-RapidAPI-Key:" && rapidApiKey into newHeaders
   --
   put CR & "Accept: application/json" after newHeaders
   set the httpheaders to newHeaders
   --
   put url restURL into resultJSON
   return resultJSON
end listenNotes_RestGet

function listenNotes_GetRapidApiKey
   put secret_Get ("rapidApiKey", "rapidApi") into oAuthToken
   return oAuthToken
end listenNotes_GetRapidApiKey

command listenNotes_SetRapidApiKey oAuthToken
   secret_Set "rapidApiKey", oAuthToken, "rapidApi"
   put the result into modelDataFile
   return modelDataFile
end listenNotes_SetRapidApiKey

function listenNotes_GetMashapeKey
   put secret_Get ("listenNotes_MashapeKey", "listenNotes") into oAuthToken
   return oAuthToken
end listenNotes_GetMashapeKey

command listenNotes_SetMashapeKey oAuthToken
   secret_Set "listenNotes_MashapeKey", oAuthToken, "listenNotes"
   put the result into modelDataFile
   return modelDataFile
end listenNotes_SetMashapeKey


--> PlayerFM | Bookmarks
-
/*
The API is not there, and getting json requires a cookie based authentication
Also the returned json does not contain information about the bookmark timing
*/

function playerfm_FetchBookmarkPageArray pUserName
   put playerfm_FetchBookmarkJson (pUserName) into someJSON
   put json_ToArray (someJSON) into bookmarkArray
   display_Array bookmarkArray
   
   return pageArray
end playerfm_FetchBookmarkPageArray

function playerfm_ConstructBookmarkPageArray
   
end playerfm_ConstructBookmarkPageArray

function playerfm_FetchBookmarkJson pUserName
   /*
   cookie: G_ENABLED_IDPS=google; intercom-lou-bqm10q34=1;
   __utmv=149401207.|1=Logged%20in=yes=1^3=Join%20month=0=1^4=Join%20year=70=1^5=gaUserId=10187263=1;
   __cfduid=d8f04dfbd69f9cbb8f7429b70d75f36911535876727; __stripe_mid=ea3846b4-5452-4be0-9ce3-12959b1565e4;
   __utmc=149401207; G_AUTHUSER_H=0;
   __utma=149401207.1408835397.1535876707.1546425596.1546426094.32;
   __utmz=149401207.1546426094.32.12.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided);
   __utmb=149401207.28.10.1546426094;
   intercom-session-bqm10q34=cEFTSGhYYjBRZHBaT0J4NUFXWUhGdjhGN3BYNWc0N3oxaE9WWWZjbmhSYkRIMkloR1ZPNlhOWHJqUkJBWnI3ZC0tMHRHcUZaZ2V2NjAxZmdFenNlV2NrQT09--beca1ec6a0951f618a36b31a62a4eb2c110ff89c;
   pfm-session=BAh7CUkiD3Nlc3Npb25faWQGOgZFVEkiJWE1NjYzZTBlYTNmNGRkM2IxMGMxZjI4OTcyNDRiNWM4BjsAVEkiGXdhcmRlbi51c2VyLnVzZXIua2V5BjsAVFsHWwZpA%2F9xm0kiAAY7AFRJIh13YXJkZW4udXNlci51c2VyLnNlc3Npb24GOwBUewZJIhRsYXN0X3JlcXVlc3RfYXQGOwBUbCsHuqAsXEkiEF9jc3JmX3Rva2VuBjsARkkiMTNQL09WQ3cxQlZjWGQyeVd1dEQxQXJxdEhhVXVScDBFMkkwRkdDbHUxRXc9BjsARg%3D%3D--a151fa4a6e89a23bd87a2dfa41fc6bbd282d1efb
   */
   
   if pUserName is empty then put "fortyfoxes" into pUserName
   --
   put "https://player.fm/" & pUserName & "/bookmarks.json" into jsonURL
   put url jsonURL into bookmarkJSON
   return bookmarkJSON
end playerfm_FetchBookmarkJson


--> PlayerFM | URLs
-
function playerfm_ConstructURL seriesID, pEpisodeID, pStem
   put "https://player.fm/series/" & seriesID into htmlURL
   if pEpisodeID is not empty then
      put slash & pEpisodeID after htmlURL
   end if 
   put ".html" after htmlURL
   return htmlURL
end playerfm_ConstructURL

function playerfm_ConstructJsonURL seriesID, pEpisodeID
   put "https://player.fm/series/" & seriesID into jsonURL
   if pEpisodeID is not empty then
      put slash & pEpisodeID after jsonURL
   end if 
   put ".json" after jsonURL
   return jsonURL
end playerfm_ConstructJsonURL

function playerfm_ConvertURL droppedURL
   put droppedURL into jsonURL
   if char-5 to -1 of jsonURL is not ".json" then
      put ".json" after jsonURL
   end if
   return jsonURL
end playerfm_ConvertURL


--> PlayerFM
-
function playerfm_FetchArray playerfmURL
   put playerfm_ConvertURL (playerfmURL) into jsonURL
   put url jsonURL into someJSON
   put json_ToArray (someJSON) into playerfmArray
   return playerfmArray
end playerfm_FetchArray

function playerfm_FetchPodcastPageArray someHtml, pURL
   -- html must be valid xhtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   put revXMLMatchingNode (treeID, rootNode, "a", "class", "play-prompt playable button", -1, false) into aNode
   put revXMLAttribute (treeID, aNode, "href") into audioURL
   put revXMLNodeContents (treeID, "html/head/title") into htmlTitle
   put revXMLMatchingNode (treeID, rootNode, "div", "class", "description prose cleanslate", -1, false) into divNode
   put revXMLNodeContents (treeID, divNode) into podcastDescription
   replace CR with space in podcastDescription
   --
   revDeleteXMLTree treeID
   
   put empty into imageURL
   set the itemdelimiter to "-"
   put item 1 of htmlTitle into pageTitle
   if char 1 of pageTitle = "#" then delete word 1 of pageTitle
   put word 1 to -1 of pageTitle into pageTitle
   
   put line 1 of podcastDescription into firstPara
   delete line 1 of podcastDescription
   
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, htmlTitle) into pageArray
   --
   return pageArray
end playerfm_FetchPodcastPageArray


--> Podcast
-
function guardian_FetchPodcastPageArray someHtml, pURL
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   -- class="gu-media-wrapper gu-media-wrapper--audio"
   
   -- <li> class="podcast-meta__item podcast-meta__item--download"
   put revXMLMatchingNode (treeID, rootNode, "li", "class", "podcast-meta__item podcast-meta__item--download", -1, false) into liNode
   put revXMLAttributeValues (treeID, liNode, "a", "href", CR, -1) into audioURL
   
   -- put revXMLMatchingNode (treeID, rootNode, "div", "class", "gu-media-wrapper gu-media-wrapper--audio", -1, false) into divNode
   -- put revXMLAttributeValues (treeID, divNode, "a", "href", CR, -1) into audioURL
   -- filter audioURL with "https://audio.guim.co.uk*"
   
   put revXMLNodeContents (treeID, "html/head/title") into htmlTitle
   scrapeID_OpenGraph treeID, htmlTitle, imageURL, podcastDescription, pageURL
   
   -- put revXMLMatchingNode (treeID, rootNode, "div", "class", "ml__content prose", -1, false) into divNode
   put revXMLMatchingNode (treeID, rootNode, "div", "property", "description", -1, false) into divNode
   if divNode is not empty then
      -- probably better to loop through every <p> child element
      put revXMLText (treeID, divNode, true) into podcastDescription
   end if
   --
   revDeleteXMLTree treeID
   
   put item -1 of htmlTitle into pageTitle
   
   replace CR with space in podcastDescription
   replace "</p>" with CR in podcastDescription
   text_StripTags podcastDescription
   
   --                  Show more       /       Show less
   get line -1 of podcastDescription
   if word 1 to 2 of it = "Show more" and word -2 to -1 of it = "Show less" then
      delete line -1 of podcastDescription
   end if
   put word 1 to -1 of line 1 of podcastDescription into firstPara
   
   if pURL is not empty then
      -- set the itemdelimiter to slash
      -- put item 2 of pURL into domainBit
      put space & "- [" & pURL && "bbc]" after firstPara
   end if
   
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, htmlTitle) into pageArray
   return pageArray
end guardian_FetchPodcastPageArray

function radiolab_FetchPodcastPageArray someHTML
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   scrapeID_OpenGraph treeID, ogTitle, imageURL, podcastDescription, pageURL
   
   put revXMLMatchingNode (treeID, rootNode, "div", "class", "player_element", -1, false) into divNode
   put revXMLAttribute (treeID, divNode, "data-title") into someTitle
   put revXMLAttribute (treeID, divNode, "data-download") into audioURL
   --
   revDeleteXMLTree treeID
   
   put word 1 to -1 of line 1 of podcastDescription into firstPara
   delete line 1 of podcastDescription
   if char -1 of firstPara = "." then delete char -1 of firstPara
   
   set the itemdelimiter to slash
   put item 3 of pageURL into pageURLTag
   set the itemdelimiter to "."
   if item 1 of pageURLTag = "www" then delete item 1 of pageURLTag
   put " - [" & pageURL && pageURLTag & "]" into pageLink
   
   put pageLink after firstPara
   put someTitle & pageLink into audioDescription
   
   set the itemdelimiter to "-"
   put word 1 to -1 of item -1 of ogTitle into pageTitle
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, audioDescription) into pageArray
   return pageArray
end radiolab_FetchPodcastPageArray

function _UglyHack someHtml
   -- only uses "offset"
   put "buttons__download__link" into sString
   put offset (sString, someHtml) into sNum
   if sNum = 0 then return empty
   --
   put offset (">", someHtml, sNum) into bNum
   put char sNum to (sNum + bNum) of someHtml into linkBit
   --
   get "href=" & quote
   put offset (it, linkBit) into nNum
   if nNum = 0 then return empty
   put nNum + 6 into sNum
   put offset (quote, linkBit, sNum) into eNum
   if eNum = 0 then return empty
   put char sNum to (sNum + eNum - 1) of linkBit into someLink
   return word 1 to -1 of someLink
end _UglyHack

function _EvenUglierHack someHTML
   /*
   <a class="link-complex popup__list__item island--squashed br-secondary-bg-ontext br-secondary-bg-onbg--hover br-secondary-link-ontext--hover" href="//open.live.bbc.co.uk/mediaselector/6/redir/version/2.0/mediaset/audio-nondrm-download/proto/https/vpid/p06xdsxq.mp3" download="The Infinite Monkey Cage, Series 19, Microbes: Secret Rulers of the World? - m0001xqb.mp3" aria-label="Download Higher quality (128kbps) ">
   Higher quality (128kbps)
   </a>
   */
   
   put "download=" & quote into sString
   put offset (sString, someHtml) into sNum
   if sNum = 0 then return empty
   get char 1 to sNum of someHTML
   put line -2 to -1 of it into lastLines
   
   get "href=" & quote
   put offset (it, lastLines) into nNum
   if nNum = 0 then return empty
   put nNum + 6 into sNum
   put offset (quote, lastLines, sNum) into eNum
   if eNum = 0 then return empty
   put char sNum to (sNum + eNum - 1) of lastLines into someLink
   return word 1 to -1 of someLink
end _EvenUglierHack

function _UglyXmlhack treeID, rootNode
   -- no longer works
   -- put revXMLAttributeValues (treeID, divNode, "a", "href", CR, 1) into audioURL
   -- this is a real hack as the tree seems utterly broken
   put revXMLMatchingNode (treeID, rootNode, "div", "id", "orb-modules", -1, false) into orbModulesNode
   put revXMLMatchingNode (treeID, orbModulesNode, "div", "class", "br-container__inner", -1, false) into innerNode
   put innerNode & "/div[2]" into mainContentNode
   put revXMLMatchingNode (treeID, mainContentNode, "ul", "class", "list-unstyled popup__list", -1, false) into ulNode
   if ulNode is empty then
      -- no download link
      put empty into audioURL
   else
      put ulNode & "/li[1]/a" into aNode
      put revXMLAttribute (treeID, aNode, "href") into audioURL
      put revXMLAttribute (treeID, aNode, "download") into downloadURL
   end if
   return audioURL
end _UglyXmlhack

function _UglyListenHack podcastDescription
   put listenNotes_FindEpisode (podcastDescription) into resultJSON
   return empty
end _UglyListenHack

function bbc_FetchPodcastPageArray someHtml, pURL
   put _UglyHack (someHtml) into someLink
   if someLink is empty then
      put _EvenUglierHack (someHtml) into someLink
   end if
   html_Tidy someHtml
   
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   -- put "//*[@id='orb-modules']/div/div/div[2]/div[2]/div/div[1]/div/div[2]/div[2]/div[1]/div/div[3]/a" into someXPath
   -- put revXMLDataFromXPathQuery (treeID, someXPath) into someContent
   
   -- <a class="link-complex br-linkinvert buttons__download__link"
   --put revXMLMatchingNode (treeID, rootNode, "a", "class", "link-complex br-linkinvert buttons__download__link", -1, false) into divNode
   --put revXMLMatchingNode (treeID, rootNode, "a", "class", "buttons__download__link", -1, false) into divNode
   
   --
   put revXMLRootNode (treeID) into rootNode
   put revXMLNodeContents (treeID, "html/head/title") into htmlTitle
   scrapeID_OpenGraph treeID, htmlTitle, imageURL, podcastDescription, pageURL
   
   put revXMLMatchingNode (treeID, rootNode, "div", "property", "description", -1, false) into divNode
   if divNode is not empty then
      -- probably better to loop through every <p> child element
      put revXMLText (treeID, divNode, true) into podcastDescription
   end if
   
   if someLink is empty then
      put _UglyXmlhack (treeID, rootNode) into audioURL
      if audioURL is empty then
         put _UglyListenHack (podcastDescription) into audioURL
      end if
   else
      put "https:" & someLink into audioURL
   end if
   --
   revDeleteXMLTree treeID
   --
   put item -1 of htmlTitle into pageTitle
   replace CR with space in podcastDescription
   replace "</p>" with CR in podcastDescription
   text_StripTags podcastDescription
   
   get line -1 of podcastDescription
   if word 1 to 2 of it = "Show more" and word -2 to -1 of it = "Show less" then
      delete line -1 of podcastDescription
   end if
   put word 1 to -1 of line 1 of podcastDescription into firstPara
   
   if pURL is not empty then
      -- set the itemdelimiter to slash
      -- put item 2 of pURL into domainBit
      put space & "- [" & pURL && "bbc]" after firstPara
   end if
   
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, htmlTitle) into pageArray
   return pageArray
end bbc_FetchPodcastPageArray


--> Private | ListenNotes
-
private command listenNotes_AddAudio @pageArray, episodeTitle, episodeDescription, audioURL
   -- quick hack for now
   put word 1 to -1 of episodeDescription into episodeDescription
   pageArray_AddAudio pageArray, audioURL, episodeDescription
end listenNotes_AddAudio

private command _ConstructPageArray pageTitle, audioURL, imageURL, firstPara, podcastDescription, audioDescription
   put fedwiki_ConstructNewPageArray (pageTitle, firstPara) into pageArray
   if imageURL is not empty then
      put fedwiki_ConstructImageDiv (imageURL) into imageHTML
      pageArray_AddHtml pageArray, imageHTML
   end if
   
   repeat with lineNum = 2 to the number of lines of podcastDescription
      put word 1 to -1 of line lineNum of podcastDescription into somePara
      pageArray_AddText pageArray, somePara
   end repeat
   return pageArray
end _ConstructPageArray

private command _DeconstructEpisodeItemArray itemArray
   -- not sure i want / need this stuff
   -- as it is better returned with "listenNotes_FetchEpisodeInfo()"
   
   put itemArray ["podcast_id"] into podcastID
   put itemArray ["podcast_title"] into podcastTitle
   put itemArray ["podcast_listennotes_url"] into podcastListenURL
   put itemArray ["publisher_original"] into publisherName
   --
   put itemArray ["title_original"] into episodeTitle
   put itemArray ["description_original"] into episodeDescription
   put itemArray ["listennotes_url"] into listenURL
   put itemArray ["image"] into imageURL
   put itemArray ["thumbnail"] into thumbnailURL
   -- put itemArray ["genres"] into genreArray
   -- put itemArray ["audio_length"] into prettyAudioLength
end _DeconstructEpisodeItemArray


--> Deps
-
command text_StripTags @someXml
   put word 1 to -1 of replacetext (someXml, "(<(.|\n)+?>)", empty) into someXml
end text_StripTags

command html_Tidy @someHtml
   put the tempname & ".html" into inputFile
   put someHtml into url ("file:" & inputFile)
   
   put "tidy --show-info false --show-warnings false --force-output true --char-encoding utf8 --input-encoding utf8 --output-encoding utf8 --output-xml true -asxml -m" && inputFile into someShell
   -- put "tidy -q -utf8 -asxml -m" && inputFile into someShell
   put shell (someShell) into shellResult
   put url ("file:" & inputFile) into someHtml
end html_Tidy
