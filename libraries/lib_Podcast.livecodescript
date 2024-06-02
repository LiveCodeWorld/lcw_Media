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
function podcast_GetWikiDomain
   -- return "cast.pod.club"
   return "podcast.anarchive.earth"
end podcast_GetWikiDomain


--> Podcast | Model
-
function podclub_FetchPodcastIndex
   put podcast_GetWikiDomain() into wikiDomain
   put pageArray_FetchItemModel (wikiDomain, "podcast-index", "177c38e4139ed7de") into podcastIndex
   replace "- [[" with empty in podcastIndex
   replace "]]" with empty in podcastIndex
   return podcastIndex
end podclub_FetchPodcastIndex

command podclub_StorePodcastIndex podcastIndex
   put podcast_GetWikiDomain() into wikiDomain
   put markdown_LinkedBullets (podcastIndex) into markdownIndex
   pageArray_StoreItemModel wikiDomain, "podcast-index", "177c38e4139ed7de", markdownIndex
   put the result into wikipageURL
   return wikipageURL
end podclub_StorePodcastIndex

function pageArray_FetchItemModel wikiDomain, pageSlug, itemID
   put pageArray_Fetch (wikiDomain, pageSlug, true) into pageArray
   put pageArray_GetItemText (pageArray, itemID) into someText
   return someText
end pageArray_FetchItemModel

command pageArray_StoreItemModel wikiDomain, pageSlug, itemID, someText
   put pageArray_Fetch (wikiDomain, pageSlug, true) into pageArray
   pageArray_SetItemText pageArray, itemID, someText
   pageArray_Set wikiDomain, pageSlug, pageArray
   put the result into wikipageURL
   return wikipageURL
end pageArray_StoreItemModel


--> Podcast
-
/*
These handlers are share by several podcast libs / sections.
*/

on mDoubleUp_Podcast displayView, podcastName
   podcast_Launch podcastName
end mDoubleUp_Podcast

on display_CuratedPodcasts
   put podcast_ListCurated() into pageTitles
   --
   display_Data pageTitles, "Curated", "Podcasts"
   put the result into displayView
   --
   display_SetInteractions displayView, "Podcast", "mDoubleUp_Podcast"
   return displayView
end display_CuratedPodcasts

command podcast_Launch podcastName
   put podcast_GetWikiDomain() into wikiDomain
   fedwiki_Launch wikiDomain, podcastName
end podcast_Launch


--> Podclub | Model
-
function podclub_FetchPocastMetadata podcastTitle
   put podcast_GetWikiDomain() into wikiDomain
   put fedwiki_ConstructSlug (podcastTitle) into pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug, true) into pageArray
   put pageArray ["story"][1]["text"] into firstPara
   --
   delete line 1 of firstPara
   put word 1 to -1 of firstPara into metaLines
   set the itemdelimiter to ":"
   repeat for each line someLine in metaLines
      -- > Feed: [http://feeds.wnyc.org/radiolab rss]
      put item 1 of someLine into someKey
      if word 1 of someKey = ">" then delete word 1 of someKey
      put word 1 to -1 of someKey into someKey
      put word 1 to -1 of item 2 to -1 of someLine into someValue
      if someValue is empty then next repeat
      --
      fedwiki_DeconstructExternalLink someValue, someURL, linkWord
      if the result is false then next repeat
      put someURL into mData [someKey]
   end repeat
   --
   -- https://www.listennotes.com/search/?q=Democracy&sort_by_date=0&scope=episode&offset=0&language=Any%20language&len_min=0&ocid=535815a492a941d79b95be6ae1c5cc9c
   put mData ["Search"] into listenURL
   set the itemdelimiter to "?"
   put item -1 of listenURL into listenParamArray
   split listenParamArray by "&" and "="
   put listenParamArray ["ocid"] into mData ["podcastID"]
   --
   return mData
end podclub_FetchPocastMetadata

command fedwiki_DeconstructExternalLink someLink, @someURL, @linkWord
   put "\[(.+)\s(.+)\]" into someReg
   if matchText (someLink, someReg , sURL, sWord) is true then
      put word 1 to -1 of sURL into someURL
      put word 1 to -1 of sWord into linkWord
      return true
   else
      put empty into someURL
      put empty into linkWord
      return false
   end if
end fedwiki_DeconstructExternalLink

function podcast_ListCurated pLoad
   put podcast_GetWikiDomain() into wikiDomain
   put fedwiki_FetchSitemapArray (wikiDomain, pLoad) into sitemapArray
   put fedwiki_GetSitemapTitles (sitemapArray) into pageTitles
   --
   line_Delete "Welcome Visitors", pageTitles
   return pageTitles
end podcast_ListCurated

function podcast_ConstructPageArray pageTitle, audioURL, imageURL, firstPara, podcastDescription, audioDescription
   put pageArray_Construct (pageTitle, firstPara) into pageArray
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


--> PlayerFM | Bookmarks
-
/*
The API is not there, and getting json requires a cookie based authentication
Also the returned json does not contain information about the bookmark timing
*/

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

function playerfm_FetchBookmarkPageArray pUserName
   put playerfm_FetchBookmarkJson (pUserName) into someJSON
   put json_ToArray (someJSON) into bookmarkArray
   display_Array bookmarkArray
   
   return pageArray
end playerfm_FetchBookmarkPageArray

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
   
   if pUserName is empty then put "davidbovill" into pUserName
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
   revXMLDeleteTree treeID
   
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
   revXMLDeleteTree treeID
   
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
   revXMLDeleteTree treeID
   
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
         -- could search using listenNotes
         put empty into audioURL
      end if
   else
      put "https:" & someLink into audioURL
   end if
   --
   revXMLDeleteTree treeID
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
