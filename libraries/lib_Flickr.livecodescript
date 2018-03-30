script "lib_Flickr"
--> MetaData
-
license: GPLv3
name: lib_Flickr
type: library
version: 0.2


--> MetaData
-
name: libOPN_Flickr
type: library
version: 0.7
copyright: David Bovill

/*
A library for image Flickr and other online galleries.
Taken from a script.txt file of libOPN_Flickr. Could not find original stack.
*/


--> Working on
-
command fedwiki_DeconstructLocationArray locationArray, @mapLat, @mapLong, @locationAccuracy, @locationDescription, @someWhere
   put locationArray ["latitude"] into mapLat
   put locationArray ["longitude"] into mapLong
   put locationArray ["accuracy"] into locationAccuracy
   put locationArray ["description"] into locationDescription
   
   put locationArray ["neighbourhood"]["_content"] into neighbourHood
   put locationArray ["locality"]["_content"] into locality
   put locationArray ["country"]["_content"] into country
   
   put neighbourHood &comma&space& locality &comma&space& country into someWhere
end fedwiki_DeconstructLocationArray

function flickr_ConstructPhotoMapPageArray pageTitle, photoDescription, imageURL, pPageURL, pLocationArray, pPhotoTags, pTileType
   put fedwiki_JsonEncode (photoDescription) into photoDescription
   put line 1 of photoDescription into firstParagraph
   delete line 1 of photoDescription
   put fedwiki_ConstructNewPageArray (pageTitle, firstParagraph) into pageArray
   
   put fedwiki_ConstructImageDiv (imageURL, pPageURL) into imageHTML
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
   
   if pLocationArray is an array then
      fedwiki_DeconstructLocationArray pLocationArray, mapLat, mapLong, locationAccuracy, mapText, someWhere
      if mapText is empty then
         put firstParagraph into mapText
      end if
      put "[[" & pageTitle & "]]" into pinText
      fedwiki_AddMapToPageArray pageArray, mapLat, mapLong, mapText, locationAccuracy, pinText, pTileType
   end if
   
   put json_FromArray (pageArray) into pageJSON
   return pageJSON
end flickr_ConstructPhotoMapPageArray

function flickr_GetPersonInfo userID
   put "flickr.people.getInfo" into methodName
   put userID into paramArray ["user_id"]
   
   put flickr_FetchJson (methodName, paramArray, true) into someJSON
   return someJSON
end flickr_GetPersonInfo


--> Flickr | Album
-
function flickr_ListAlbumPhotos photosetID, userID, pPhotoExtras
   /*
   This method does not require authentication.
   
   photoset_id (Required)
   user_id (Required)
   extras (Optional)
   A comma-delimited list of extra information to fetch for each returned record. Currently supported fields are: license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media, path_alias, url_sq, url_t, url_s, url_m, url_o
   per_page (Optional)
   page (Optional)
   privacy_filter (Optional)
   Return photos only matching a certain privacy level. This only applies when making an authenticated call to view a photoset you own. Valid values are:
   1 public photos
   2 private photos visible to friends
   3 private photos visible to family
   4 private photos visible to friends & family
   5 completely private photos
   media (Optional)
   Filter results by media type. Possible values are all (default), photos or videos
   */
   
   put photosetID into paramArray ["photoset_id"]
   put userID into paramArray ["user_id"]
   if pPhotoExtras is true then
      put "license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media, path_alias, url_sq, url_t, url_s, url_m, url_o" into paramArray ["extras"]
   else
      put "license, geo, tags, machine_tags, o_dims, path_alias, url_sq, url_t, url_s, url_m, url_o" into paramArray ["extras"]
   end if
   
   put flickr_FetchJsonArray ("flickr.photosets.getPhotos", paramArray, true) into responseArray
   display_Array responseArray
   return responseArray
end flickr_ListAlbumPhotos

function flickr_ListAlbums pPhotoExtras, pUserID
   /*
   page (Optional)
   The page of results to get. Currently, if this is not provided, all sets are returned, but this behaviour may change in future.
   per_page (Optional)
   */
   
   put pUserID into paramArray ["user_id"]
   if pPhotoExtras is true then
      put "license,date_upload,date_taken,owner_name,icon_server,original_format,last_update,geo, tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_o" into paramArray ["primary_photo_extras"]
   end if
   
   put flickr_FetchJsonArray ("flickr.photosets.getList", paramArray) into responseArray
   display_Array responseArray
   return responseArray
end flickr_ListAlbums

command flickr_AddToAlbum photoID, photosetID
   /*
   get "https://api.flickr.com/services/rest/?method=flickr.photosets.addPhoto&api_key=5306afda3bc7ac180a127a586999464e&
   photoset_id=72157683626414062&
   photo_id=35970754626&format=json&nojsoncallback=1&auth_token=72157684384779981-84c70915814b1e8e&api_sig=08c97bb14b7a638e13f564a9076a4980"
   
   api_key (Required)
   photoset_id (Required)
   photo_id (Required)
   */
   
   put photosetID into paramArray ["photoset_id"]
   put photoID into paramArray ["photo_id"]
   
   put flickr_FetchJsonArray ("flickr.photosets.addPhoto", paramArray) into responseArray
   return responseArray ["stat"] = "OK"
end flickr_AddToAlbum



--> Flickr | Galleries
-
function flickr_LookupGallery galleryURL
   put galleryURL into paramArray ["url"]
   put flickr_FetchJsonArray ("flickr.urls.lookupGallery", paramArray) into responseArray
   display_Array responseArray
   return responseArray
end flickr_LookupGallery


--> Flickr | Upload
-
command flickr_UploadPhoto somePhoto, photoTitle, description, tags, isPublic, isFriend, isFamily
   local paramArray, urlParamBit, baseString
   
   if photoTitle is not empty then put photoTitle into paramArray ["title"]
   if description is not empty then put description into paramArray["description"]
   if tags is not empty then put tags into paramArray["tags"]
   
   /*
   if isPublic is not empty then put isPublic into paramArray["is_public"]
   if isFriend is not empty then put isFriend into paramArray["is_friend"]
   if isFamily is not empty then put isFamily into paramArray["is_family"]
   */
   
   put flickr_GetConsumerKey() into consumerKey
   put uuid() into oauthNonce
   put "HMAC-SHA1" into sigMethod
   put the ticks into timestamp
   put flickr_GetAccessToken() into authToken
   put "1.0" into oauthVersion
   
   put consumerKey into paramArray ["oauth_consumer_key"]
   put oauthNonce into paramArray ["oauth_nonce"]
   put sigMethod into paramArray ["oauth_signature_method"]
   put timestamp into paramArray ["oauth_timestamp"]
   put authToken into paramArray ["oauth_token"]
   put oauthVersion into paramArray ["oauth_version"]
   
   put cUploadPhotoEndPoint into someURL
   flickr_ConstructParamBits "POST", cUploadPhotoEndPoint, paramArray, urlParamBit, baseString
   
   try
      put flickr_ConstructOauthSignature (baseString) into oAuthSignature
   catch e
      return "Error, using oAuth"
   end try
   
   try
      get libUrlMultipartFormData (tForm, "oauth_consumer_key", consumerKey, "oauth_nonce", oauthNonce, "oauth_signature_method", sigMethod, "oauth_timestamp", timestamp, "oauth_token", authToken, "oauth_version", oauthVersion, "oauth_signature", oauthSignature)
      if it is not empty then
         return "Error: creating multipart form"
      end if
      
      put line 1 of tForm into newHeaders
      set the httpheaders to newHeaders
      put line 2 to -1 of tForm into postData
      
      put "C:\test.jpg" into shortFile
      put "image/jpeg" into mimeType
      put "binary" into someEncoding
      
      if description is not empty then get libUrlMultipartFormAddPart (postData, "description", description)
      
      -- add the photo to the end (it is not signed)
      if libUrlMultipartFormAddPart (postData,"photo", somePhoto, mimeType, someEncoding) is not empty then
         set the httpheaders to empty
         return "Error: creating multipart form" into postResult
      end if
      
      if tags is not empty then get libUrlMultipartFormAddPart (postData, "tags", tags)
      if photoTitle is not empty then get libUrlMultipartFormAddPart (postData, "title", photoTitle)
      
      put "Content-Disposition: form-data; name=" & kwote("photo") into testLine
      put lineoffset (testLine, postData) into lineNum
      put testLine & "; filename=" & kwote(shortFile) into fullLine
      put fullLine into line lineNum of postData
   catch e
      return "Error, with libUrlMultipartFormData"
   end try
   
   try
      post postData to url someURL
      put it into uploadResponseXml
      put flickr_ParseUploadResponse (uploadResponseXml) into photoID
      
      ## check the result, etc., here
      set the httpheaders to empty
      return photoID
   catch e
      return "error, problem with post postData in flickr_UploadPhoto" 
   end try
end flickr_UploadPhoto

function flickr_ParseUploadResponse uploadResponseXml
   /*
   <?xml version="1.0" encoding="utf-8" ?>
   <rsp stat="ok">
   <photoid>36164786925</photoid>
   </rsp>
   */
   put flickr_ParseXmlResponse (uploadResponseXml) into treeID
   if treeID is not a number then return empty
   
   put revXMLNodeContents (treeID, "/rsp/photoid") into photoID
   revDeleteXMLTree treeID
   return photoID
end flickr_ParseUploadResponse

function flickr_ParseXmlResponse someXml
   put revCreateXMLTree (someXml, false, true, false) into treeID
   put revXMLAttribute (treeID, "/rsp", "stat") into responseStatus
   if responseStatus is "OK" then
      return treeID
   else
      revDeleteXMLTree treeID
      return false
   end if
end flickr_ParseXmlResponse


--> Flickr | Fetch
-
function flickr_FetchJsonArray methodName, paramArray, pDontSign
   put flickr_FetchJson (methodName, paramArray, pDontSign) into someJSON
   put json_ToArray (someJSON) into responseArray
   return responseArray
end flickr_FetchJsonArray

function flickr_FetchJson methodName, paramArray, pDontSign
   put "GET" into restMethod
   put flickr_OauthRestUrl (methodName, paramArray, restMethod, pDontSign) into someURL
   put url someURL into someJSON
   return someJSON
end flickr_FetchJson


--> Flickr | Photo | Dropped
-
command flickr_FetchAndDeconstructFromDroppedUrl droppedURL, @photoTitle, @photoDescription, @mediumURL, @photoTags
   flickr_DeconstructDroppedPhotoID droppedURL, nsID, photoID
   if the result is false then
      -- return error
      return empty
   end if
   
   put flickr_FetchPhotoInfo (photoID) into photoInfoArray
   put photoInfoArray ["stat"] into fetchStatus
   if fetchStatus is not "ok" then
      return empty
   end if
   
   put photoInfoArray ["photo"] into photoArray
   
   put photoArray ["title"]["_content"] into photoTitle
   put photoArray ["description"]["_content"] into photoDescription
   
   put photoArray ["tags"]["tag"] into tagArray
   repeat with itemNum = 1 to item 2 of the extents of tagArray
      put tagArray [itemNum]["_content"] & comma after photoTags
   end repeat
   delete char -1 of photoTags
   
   utf8_Decode photoTitle
   utf8_Decode photoDescription
   utf8_Decode photoTags
   
   put flickr_FetchPhotoSizeArray (photoID) into photoSizeArray
   put flickr_ParseSizeArray (photoSizeArray) into sizeArray
   put sizeArray ["medium"] into mediumURL
   
   put sizeArray into photoArray ["flickr_FetchPhotoSizeArray"]
   return photoArray
end flickr_FetchAndDeconstructFromDroppedUrl

command flickr_DeconstructDroppedPhotoID droppedURL, @nsID, @photoID
   set the itemdelimiter to slash
   if item 1 to 4 of droppedURL is not "https://www.flickr.com/photos" then
      put empty into nsID
      put empty into photoID
      return false
   end if
   
   put item 5 of droppedURL into nsID
   put item 6 of droppedURL into photoID
   return true
end flickr_DeconstructDroppedPhotoID


--> Flickr | Photo
-
function flickr_FetchUserPhotos
   put flickr_OauthRestUrl ("flickr.activity.userPhotos") into someURL
   put url someURL into someResponse
   return someResponse
end flickr_FetchUserPhotos

function flickr_FetchTotalViews
   put flickr_OauthRestUrl ("flickr.stats.getTotalViews") into someURL
   put url someURL into someResponse
   return someResponse
end flickr_FetchTotalViews


--> Flickr | Photo | Info
-
function flickr_FetchPhotoInfo photoID, pPhotoSecret
   put "flickr.photos.getInfo" into methodName
   put photoID into paramArray ["photo_id"]
   if pPhotoSecret is not empty then put pPhotoSecret into paramArray ["secret"]
   
   put flickr_FetchJsonArray (methodName, paramArray) into responseArray
   return responseArray
end flickr_FetchPhotoInfo

function flickr_FetchPhotoExif photoID, photoSecret
   put "flickr.photos.getExif" into methodName
   put photoID into paramArray["photo_id"]
   if photoSecret is not empty then put photoSecret into paramArray["secret"]
   
   put flickr_FetchJsonArray (methodName, paramArray) into responseArray
   return responseArray
end flickr_FetchPhotoExif


--> Flickr | Photo | Sizes
-
function flickr_FetchMediumPhotoUrl photoID
   put flickr_FetchPhotoSizeArray (photoID) into photoSizeArray
   put flickr_ParseSizeArray (photoSizeArray) into sizeArray
   put sizeArray ["medium"] into mediumURL
   return mediumURL
end flickr_FetchMediumPhotoUrl

function flickr_FetchSizes photoID
   put flickr_FetchPhotoSizeArray (photoID) into photoSizeArray
   put flickr_ParseSizeArray (photoSizeArray) into sizeLabelArray
   return keys (sizeLabelArray)
end flickr_FetchSizes

function flickr_FetchPhotoSizeArray photoID
   put "flickr.photos.getSizes" into methodName
   put photoID into paramArray["photo_id"]
   
   put flickr_FetchJsonArray (methodName, paramArray) into photoSizeArray
   return photoSizeArray
end flickr_FetchPhotoSizeArray

function flickr_ParseSizeArray photoSizeArray
   put photoSizeArray ["stat"] into fetchStatus
   if fetchStatus is not "ok" then
      return empty
   else
      put photoSizeArray ["sizes"]["size"] into sizeArray
      repeat with itemNum = 1 to item 2 of the extents of sizeArray
         put sizeArray [itemNum]["label"] into someLabel
         put sizeArray [itemNum]["width"] into someWidth
         put sizeArray [itemNum]["height"] into someHeight
         put sizeArray [itemNum]["source"] into someSource
         put sizeArray [itemNum]["url"] into someURL
         
         put someSource into sizeLabelArray [someLabel]
      end repeat
      return sizeLabelArray
   end if
end flickr_ParseSizeArray


--> Flickr | Photo | Geo
-
function flickr_GetPhotoGeoLocation photoID
   put "flickr.photos.geo.getLocation" into methodName
   put photoID into paramArray ["photo_id"]
   
   put flickr_FetchJsonArray (methodName, paramArray) into photoSizeArray
   return photoSizeArray
end flickr_GetPhotoGeoLocation

function flickr_GetPhotoGeoPerms photoID
   put "flickr.photos.geo.getPerms" into methodName
   put photoID into paramArray ["photo_id"]
   
   put flickr_FetchJsonArray (methodName, paramArray) into photoSizeArray
   return photoSizeArray
end flickr_GetPhotoGeoPerms


--> Private 
-
private command flickr_AddDefaultsToParamArray @paramArray   
   put flickr_GetConsumerKey() into paramArray ["oauth_consumer_key"]
   put uuid() into paramArray ["oauth_nonce"]
   put the ticks into paramArray ["oauth_timestamp"]
   put "HMAC-SHA1" into paramArray ["oauth_signature_method"]
   put "1.0" into paramArray ["oauth_version"]
end flickr_AddDefaultsToParamArray

private command flickr_ConstructParamBits restMethod, restEndPoint, paramArray, @urlParamBit, @baseString
   -- http://www.wackylabs.net/2011/12/oauth-and-flickr-part-2/
   
   -- encode the params
   put keys (paramArray) into paramkeys
   sort paramKeys
   repeat for each line paramKey in paramkeys
      put paramArray [paramKey] into paramValue
      if paramValue is not empty then -- maybe we should allow empty params???
         put paramKey & "=" & urlencode (paramValue) & "&" after urlParamBit
         put paramKey & "=" & flickr_OauthEncode (paramValue) & "&" after partiallyEncodedParamBit
      end if
   end repeat
   delete char -1 of urlParamBit
   delete char -1 of partiallyEncodedParamBit
   put flickr_OauthEncode (partiallyEncodedParamBit) into encodedParamBit
   put restMethod &"&"& flickr_OauthEncode (restEndPoint) &"&"& encodedParamBit into baseString
end flickr_ConstructParamBits


--> Deps 
-
function json_FromArray pArray, pForceRootType, pPretty
   repeat for each key tKey in pArray
      if pArray[tKey] is an array then
         put "}"&json_FromArray(pArray[tKey]) into pArray[tKey]
      end if
   end repeat
   return(mergJSONEncode("pArray",pForceRootType,pPretty))
end json_FromArray

function json_ToArray pJSON
   if pJSON is empty then return false
   try -- as otherwise an error with non-json causes script to exit
      local tArray,tKeys
      if pJSON is empty then return empty
      repeat for each line tKey in mergJSONDecode(pJSON,"tArray")
         put json_ToArray(tArray[tKey]) into tArray[tKey]
      end repeat
      return tArray
   catch e
      return empty
   end try
end json_ToArray

function sha1_HMAC someText, someKey
   /*
   This function should use the built in cypher function
   For now we cal openssl via the shell
   And have to write out a temporary file
   */
   
   set the itemdelimiter to slash
   get the tempname
   put item 1 to -2 of it into tempFolder
   set the defaultfolder to tempFolder
   put item -1 of it & ".txt" into shortTempFile
   
   put someText into url ("file:" & shortTempFile)
   
   -- put "openssl dgst -sha1 -hmac" && kwote(someKey) && "-binary sometext.txt | openssl base64" into someShell
   put "openssl dgst -sha1 -hmac" && quote & someKey & quote && "-binary" && shortTempFile && "| openssl base64" into someShell
   put shell (SomeShell) into shellResult -- includes linebreak at the end
   return word 1 to -1 of shellResult
   
   /*
   -- below are some older / alternative ways of doing this
   -- no key available for sha1digest
   put sha1digest (someText) into someBinaryData
   put base64encode (someBinaryData) into oAuthSig
   
   -- openssl works in terminal but gives different result using "Shell()"
   put "echo -n '" & someText & "' | openssl dgst -sha1 -binary -hmac '" & someKey & "'" into someShell
   
   -- this seems to work some time (requires php)
   -- echo '<?= hash_hmac("sha1", "value", "key") ?>' | php  
   put "echo '<?= hash_hmac(" & kwote("sha1") & comma && kwote(someText) & comma && kwote(someKey) & ") ?>' | php" into someShell
   put shell (someShell) into oAuthSig
   return oAuthSig
   */
end sha1_HMAC

function kwote someText, pQuoteChar
   if pQuoteChar is empty then put quote into pQuoteChar
   return pQuoteChar & someText & pQuoteChar
end kwote


--> Deps  | Why
-
/*
Not clear why these are needed. Perhaps it is the pass-by-reference variables?
*/

function libUrlMultipartFormData @pFormData, pParam
   local tNumParams,tNumParts,tBoundary,tKeys,tKey,tValue,tPart
   local tFile,tNumFiles,tFilepath,tFilename,tSubBoundary
   
   put the paramcount into tNumParams
   if tNumParams < 1 then return "error Insufficient parameters"
   put (tNumParams - 1) div 2 into tNumParts
   
   put empty into pFormData ##ensure it is empty
   
   ##create initial boundary
   put "__Part__" into tBoundary
   put ulFormBoundary() after tBoundary
   
   put "Content-type: multipart/form-data; boundary=" & quote & tBoundary & quote & return into pFormData
   
   if tNumParams < 2 then
      ## do nothing for now, this will create empty shell for use with libUrlMultipartFormAddPart
   else if tNumParams = 2 then ##treat as array
      put keys(pParam) into tKeys
      sort tKeys numeric
      repeat for each line tKey in tKeys
         put "--" & tBoundary & CRLF after pFormData
         put "Content-Disposition: form-data; name=" & quote & item 1 of pParam[tKey] & quote after pFormData
         put item 2 to -1 of pParam[tKey] into tValue
         if char 1 to 6 of tValue = "<file>" then
            put tValue into tFile
            put empty into tValue
            put char 7 to -1 of tFile into tFilepath
            set the itemDel to "/"
            put item -1 of tFilepath into tFilename
            set the itemDel to comma
            put ";" && "filename=" & quote & tFilename & quote after pFormData
            put CRLF & "Content-Type: application/octet-stream" after pFormData
            put url ("binfile:" & tFilepath) into tValue
            if the result <> empty then
               return "error" && the result
            end if
         end if
         put CRLF & CRLF after pFormData
         put tValue after pFormData
         put CRLF after pFormData
         
      end repeat
      
   else if tNumParts > 0 then ##treat as key/value pairs
      put 0 into tPart
      repeat with i = 2 to tNumParams
         
         if i mod 2 = 0 then ##stage 1 of part
            add 1 to tPart
            if tPart > tNumParts then exit repeat
            put "--" & tBoundary & CRLF after pFormData
            put "Content-Disposition: form-data; name=" & quote & param(i) & quote after pFormData
            
         else
            put param(i) into tValue
            
            if char 1 to 6 of tValue = "<file>" then
               put tValue into tFile
               put empty into tValue
               put char 7 to -1 of tFile into tFilepath
               set the itemDel to "/"
               put item -1 of tFilepath into tFilename
               set the itemDel to comma
               put ";" && "filename=" & quote & tFilename & quote after pFormData
               put CRLF & "Content-Type: application/octet-stream" after pFormData
               put url ("binfile:" & tFilepath) into tValue
               if the result <> empty then
                  return "error" && the result
               end if
            end if
            put CRLF & CRLF after pFormData
            put tValue after pFormData
            put CRLF after pFormData
         end if
      end repeat
      
   end if
   
   put  "--" & tBoundary & "--" after pFormData ##end boundary
   return empty
   
end libUrlMultipartFormData

function libUrlMultipartFormAddPart @pFormData,pName,pValue,pMimeType,pEncoding
   local tLastLine,tBoundary,tPartData,tFile,tNumFiles,tFilepath,tFilename
   local tSubBoundary,tSubEncodings,tSubMimeTypes
   
   put the number of lines of pFormData into tLastLine
   put line -1 of pFormData into tBoundary
   delete char -2 to -1 of tBoundary ##remove final 2 hyphens
   put tBoundary & CRLF into tPartData
   put "Content-Disposition: form-data; name=" & quote & pName & quote after tPartData
   if char 1 to 6 of pValue is "<file>" then
      
      put   pValue into tFile
      put empty into pValue
      put char 7 to -1 of tFile into tFilepath
      
      set the itemDel to "/"
      put item -1 of tFilepath into tFilename
      set the itemDel to comma
      put ";" && "filename=" & quote & tFilename & quote after tPartData
      
      put url ("binfile:" & tFilepath) into pValue
      if the result <> empty then return "error" && the result
      
      if pMimeType is empty then put "application/octet-stream" into pMimeType
      if pEncoding is empty then
         put "Binary" into pEncoding
      end if
      
   end if
   if pMimeType <> empty then
      put CRLF & "Content-Type:" && pMimeType after tPartData
   end if
   if pEncoding <> empty then
      put CRLF & "Content-transfer-encoding:" && pEncoding after tPartData
   end if
   put CRLF & CRLF after tPartData
   put pValue after tPartData
   put CRLF after tPartData
   put tBoundary & "--" after tPartData
   put tPartData into line -1 of pFormData
   return empty
end libUrlMultipartFormAddPart

function ulFormBoundary
   local tBoundary
   
   repeat 25
      put any char of "1234567890abcdefghijklmnopqrstuvwxyz" after tBoundary
   end repeat
   return tBoundary
end ulFormBoundary
