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
getprop dep_StackNames
    return "lib_Fedwiki,lib_LCW,lib_Stack,model_Library"
end dep_StackNames


--> Pinterest | Authentication
-
function pinterest_GetAuthenticationToken
   put secret_Get ("PinterestAuthenticationToken", "pinterest") into PinterestAuthenticationToken
   return PinterestAuthenticationToken
end pinterest_GetAuthenticationToken

function pinterest_GetAppSecret
   put secret_Get ("PinterestAppSecret", "pinterest") into PinterestAppSecret
   return PinterestAppSecret
end pinterest_GetAppSecret

function pinterest_GetAppID
   put secret_Get ("PinterestAppID", "pinterest") into PinterestAppID
   return PinterestAppID
end pinterest_GetAppID


--> Pinterest | Authentication | Set
-
command pinterest_SetAuthenticationToken pAppSecret
   secret_Set "PinterestAuthenticationToken", pAppSecret, "pinterest"
   put the result into modelDataFile
   return modelDataFile
end pinterest_SetAuthenticationToken

command pinterest_SetAppSecret pAppSecret
   secret_Set "PinterestAppSecret", pAppSecret, "pinterest"
   put the result into modelDataFile
   return modelDataFile
end pinterest_SetAppSecret

command pinterest_SetAppID pAppID
   user_SetValue "PinterestAppID", pAppID, "pinterest"
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
   put pageArray_Construct (pageTitle, firstParagraph) into pageArray
   
   put fedwiki_ConstructImageDiv (imageURL) into imageHTML
   /*
   local imageLink, imageLinkTag
   put pageTitle into imageCaption
   put fedwiki_ConstructImageHtml (imageURL, imageCaption, imageLink, imageLinkTag) into imageHTML
   */
   pageArray_AddHtml pageArray, imageHTML
   
   repeat for each line someLine in photoDescription
      put fedwiki_JsonEncode (someLine) into nextParagraph
      pageArray_AddText pageArray, nextParagraph
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


--> Deps
-
function secret_Get secretName
   -- for server use only
   if the environment is not "server" then pass "secret_Get"
   --
   put rigFetchConfigItem (secretName) into someSecret
   return someSecret
end secret_Get


--> Private
-
private function _RestStem methodBit
   put pinterest_GetAuthenticationToken() into PinterestAuthenticationToken
   put "https://api.pinterest.com/v1/" into someURL
   put methodBit & "/?access_token=" & PinterestAuthenticationToken & "&" after someURL
   return someURL
end _RestStem
