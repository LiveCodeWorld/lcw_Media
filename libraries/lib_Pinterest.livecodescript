script "lib_Pinterest"
--> MetaData
-
license: GPLv3
name: lib_Pinterest
type: library
version: 0.3


--> Variables
-
constant cPinterestModelShortFile = "pinterest_Authentication.array"

local PinterestAppID
local PinterestAppSecret
local PinterestAuthenticationToken


--> Working on
-
command display_PinterestAuthenticatonArray
   put user_GetArray (cPinterestModelShortFile) into authenticationArray
   display_Array authenticationArray
end display_PinterestAuthenticatonArray


--> Pinterest | Model
-
function pinterest_GetAuthenticationToken
   -- cached
   if PinterestAuthenticationToken is empty then
      put user_GetValue ("PinterestAuthenticationToken", cPinterestModelShortFile) into PinterestAuthenticationToken
      if PinterestAuthenticationToken is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if
   return PinterestAuthenticationToken
end pinterest_GetAuthenticationToken

command pinterest_SetAuthenticationToken pAppSecret
   user_SetValue "PinterestAuthenticationToken", cPinterestModelShortFile, pAppSecret
   put the result into modelDataFile
   return modelDataFile
end pinterest_SetAuthenticationToken

function pinterest_GetAppSecret
   -- cached
   if PinterestAppSecret is empty then
      put user_GetValue ("PinterestAppSecret", cPinterestModelShortFile) into PinterestAppSecret
      if PinterestAppSecret is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if
   return PinterestAppSecret
end pinterest_GetAppSecret

command pinterest_SetAppSecret pAppSecret
   user_SetValue "PinterestAppSecret", cPinterestModelShortFile, pAppSecret
   put the result into modelDataFile
   return modelDataFile
end pinterest_SetAppSecret

function pinterest_GetAppID
   -- cached
   if PinterestAppID is empty then      
      put user_GetValue ("PinterestAppID", cPinterestModelShortFile) into PinterestAppID
      if PinterestAppID is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if
   return PinterestAppID
end pinterest_GetAppID

command pinterest_SetAppID pAppID
   user_SetValue "PinterestAppID", cPinterestModelShortFile, pAppID
   put the result into modelDataFile
   return modelDataFile
end pinterest_SetAppID


--> Pinterest | Board
-
function pinterest_FetchBoardNextArray someBoard
   -- put "johitch2006/outdoor-learning-inspirational-spaces" into someBoard -- id or user/boardSlug
   
   put pinterest_FetchBoardArray (someBoard) into boardArray
   --
   put boardArray ["page"]["next"] into nextURL
   put url nextURL into nextJson
   put json_ToArray (nextJson) into nextArray
   --
   return nextArray
end pinterest_FetchBoardNextArray

function pinterest_FetchBoardArray someBoard
   -- put "johitch2006/outdoor-learning-inspirational-spaces" into someBoard -- id or user/boardSlug
   
   put pinterest_FetchBoardPinsJson (someBoard) into someJson
   put json_ToArray (someJson) into boardArray
   return boardArray
end pinterest_FetchBoardArray


--> Pinterest
-
function pinterest_FetchPinPageJson photoID
   -- put 134545107601633296 into photoID
   put pinterest_FetchPinInfo (photoID) into pinArray
   pinterest_DeconstructPinInfo pinArray, imageURL, photoDescription, pinterestURL, originalPageURL, imageWidth, imageHeight
   --
   put pinterest_ConstructPageArray (photoDescription, imageURL) into pageArray
   put json_FromArray (pageArray) into pageJSON
   return pageJSON
end pinterest_FetchPinPageJson

function pinterest_ConstructPageArray photoDescription, imageURL
   put "Pinterest Pin" into pageTitle
   --
   put fedwiki_JsonEncode (photoDescription) into photoDescription
   put line 1 of photoDescription into firstParagraph
   delete line 1 of photoDescription
   put fedwiki_ConstructNewPageArray (pageTitle, firstParagraph) into pageArray
   
   put fedwiki_ConstructImageDiv (imageURL) into imageHTML
   /*
   local imageLink, imageLinkTag
   put pageTitle into imageCaption
   put fedwiki_ConstructImageHtml (imageURL, imageCaption, imageLink, imageLinkTag) into imageHTML
   */
   fedwiki_AddHtmlToPageArray pageArray, imageHTML
   
   repeat for each line someLine in photoDescription
      put fedwiki_JsonEncode (someLine) into nextParagraph
      fedwiki_AddParagraphToPageArray pageArray, nextParagraph
   end repeat
   
   return pageArray
end pinterest_ConstructPageArray

private command pinterest_DeconstructPinInfo pinArray, @cachedImageURL, @photoDescription, @pinterestURL, @originalPageURL, @imageWidth, @imageHeight
   put pinArray ["data"] into dataArray
   put dataArray ["image"]["original"] into imageArray
   --
   put imageArray ["url"] into cachedImageURL
   put imageArray ["width"] into imageWidth
   put imageArray ["height"] into imageHeight   
   --
   put dataArray ["link"] into storedHtmlURL
   put dataArray ["note"] into photoDescription
   put dataArray ["url"] into pinterestURL
   put dataArray ["original_link"] into originalPageURL
end pinterest_DeconstructPinInfo

function pinterest_FetchPinInfo photoID
   -- put "https://www.pinterest.co.uk/pin/134545107601633296/" into someURL
   -- put 134545107601633296 into photoID
   
   -- https://api.pinterest.com/v1/pins/134545107601633296/?access_token=xxx&fields=
   -- link%2Cnote%2Curl%2Cimage%2Cmetadata%2Cmedia%2Cboard%2Coriginal_link%2Cattribution%2Ccolor%2Ccounts%2Ccreated_at%2Ccreator%2Cid"
   
   get "pins/" & photoID
   put _RestStem (it) into someURL
   put "fields=" & urlencode("link,note,url,image,metadata,media,board,original_link,attribution,color,counts,created_at,creator,id") after someURL
   put url someURL into someJSON
   put json_ToArray (someJSON) into responseArray
   
   return responseArray   
end pinterest_FetchPinInfo

function pinterest_FetchBoardPinsJson someBoard
   -- https://api.pinterest.com/v1/boards/johitch2006/outdoor-learning-inspirational-spaces/pins/?access_token=xxx&fields=id%2Clink%2Cnote%2Curl   
   get "boards/" & someBoard & "/pins"
   put _RestStem (it) into someURL
   put "fields=" & urlencode("id,link,note,url,media,image,creator,created_at,counts,board,attribution,original_link,metadata") after someURL
   put url someURL into someJson
   return someJson
end pinterest_FetchBoardPinsJson

function pinterest_FetchUserInfo
   put _RestStem("me") into someURL
   put "fields=" & urlencode("first_name,id,last_name,url,image,username,created_at,counts,bio,account_type") after someURL
   put url someURL into someJson
   return someJson
end pinterest_FetchUserInfo


--> Private
-
private function _RestStem methodBit
   put pinterest_GetAuthenticationToken() into PinterestAuthenticationToken
   put "https://api.pinterest.com/v1/" into someURL
   put methodBit & "/?access_token=" & PinterestAuthenticationToken & "&" after someURL
   return someURL
end _RestStem
