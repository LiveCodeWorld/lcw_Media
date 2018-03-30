script "lib_FlickrXml"
--> MetaData
-
license: GPLv3
name: lib_FlickrXml
type: library
version: 0.1

/*
This is the original XML based version of the flickr library.
Currently going through it and replacing it with simplified json based calls and parsing routines.
*/


--> Flickr | Upload
-
command flickr_XmlUploadPhoto somePhoto, photoTitle, description, tags, isPublic, isFriend, isFamily
   local paramArray
   
   if description is not empty then put description into paramArray["description"]
   if tags is not empty then put tags into paramArray["tags"]
   if photoTitle is not empty then put photoTitle into paramArray["title"]
   
   /*
   if isPublic is not empty then put isPublic into paramArray["is_public"]
   if isFriend is not empty then put isFriend into paramArray["is_friend"]
   if isFamily is not empty then put isFamily into paramArray["is_family"]
   */
   
   -- put "http://api.flickr.com/services/upload/" into someURL
   put cUploadPhotoEndPoint into someURL
   
   put "" into methodName
   put the flickr_AuthenticationToken of me into authToken
   put flickr_GetMethodSignature (methodName, authToken, paramArray) into someSig
   
   if libUrlMultipartFormData (tForm, "api_key", cFlickrApiConsumerKey, "auth_token", authToken, "api_sig", someSig) is empty then
      put line 1 of tForm into newHeaders
      set the httpheaders to newHeaders
      put line 2 to -1 of tForm into postData
      
      if description is not empty then get libUrlMultipartFormAddPart (postData, "description", description)
      
      -- put "<file>" & "C:/myfile.gif" into tFile
      put "C:\test.jpg" into shortFile
      put "image/jpeg" into mimeType
      
      -- put "C:\google_photo.png" into shortFile
      -- put "image/png" into mimeType
      
      put "binary" into someEncoding
      
      if libUrlMultipartFormAddPart (postData,"photo", somePhoto, mimeType, someEncoding) is not empty then
         ##handle error and exit
         breakpoint
         put "Error: creating multipart form" into postResult
      else
         if tags is not empty then get libUrlMultipartFormAddPart (postData, "tags", tags)
         if photoTitle is not empty then get libUrlMultipartFormAddPart (postData, "title", photoTitle)
         
         put "Content-Disposition: form-data; name=" & kwote("photo") into testLine
         put lineoffset (testLine, postData) into lineNum
         put testLine & "; filename=" & kwote(shortFile) into fullLine
         put fullLine into line lineNum of postData
         
         post postData to url someURL
         put it into postResult
      end if
      
      ## check the result, etc., here
      set the httpheaders to empty
      return postResult
   else
      breakpoint
      -- some error
      return "Error: creating multipart form"
   end if
end flickr_XmlUploadPhoto


--> Flickr | Photo | Info
-
function flickr_XmlFetchPhotoExif photoID, photoSecret
   put "flickr.photos.getExif" into methodName
   put photoID into paramArray["photo_id"]
   if photoSecret is not empty then put photoSecret into paramArray["secret"]
   
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   
   put url someUrl into someXML
   return someXML
end flickr_XmlFetchPhotoExif

function flickr_XmlFetchPhotoInfo photoID, pReturnXml, pPhotoSecret
   -- older xml version
   put flickr_XmlConstructPhotoInfoUrl (photoID, pPhotoSecret) into someUrl
   put url someUrl into someXML
   return someXML
end flickr_XmlFetchPhotoInfo

function flickr_XmlConstructPhotoInfoUrl photoID, pReturnXml, pPhotoSecret
   /*
   if the correct secret is passed then permissions checking is skipped. 
   This enables the 'sharing' of individual photos by passing around the id and secret.
   */
   put "flickr.photos.getInfo" into methodName
   put photoID into paramArray ["photo_id"]
   if pPhotoSecret is not empty then put pPhotoSecret into paramArray ["secret"]
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   
   if pReturnXml is not true then
      put "&format=json&nojsoncallback=1" after someUrl
   end if
   return someUrl
end flickr_XmlConstructPhotoInfoUrl

function flickr_XmlParsePhotoInfo someXml
   if someXml is empty then return empty
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/photo" into someNode
      
      put revXMLAttributes(treeID, someNode, tab, return) into photoRecordArray
      split photoRecordArray using return and tab
      put photoRecordArray ["id"] into photoID
      
      put someNode & "/owner" into ownerNode
      put someNode & "/title" into titleNode
      put someNode & "/description" into descriptionNode
      get revXMLNodeContents(treeID, descriptionNode)
      put uniencode(it,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into photoRecordArray ["description"]
      
      put someNode & "/visibility" into visibilityNode
      put someNode & "/dates" into datesNode
      put someNode & "/editability" into editabilityNode
      put someNode & "/comments" into commentsNode
      put revXMLNodeContents(treeID, commentsNode) into photoRecordArray ["commentNumber"]
      
      put someNode & "/notes" into notesNode
      get revXMLNodeContents(treeID, notesNode)
      put uniencode(it,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into photoRecordArray ["notes"]
      
      put someNode & "/location" into locationNode
      put someNode & "/geoperms" into geopermsNode
      put someNode & "/urls" into urlsNode
      
      put someNode & "/tags" into tagNode
      put revXMLChildNames(treeID, tagNode, return, "tag", true) into nodeIndex
      put empty into tagNames
      repeat for each line shortNode in nodeIndex
         put tagNode & "/" & shortNode into childNode
         
         put revXMLNodeContents(treeID, childNode) into tagName
         
         put revXMLAttributes(treeID, childNode, tab, return) into tabTable
         put tabTable into recordArray
         split recordArray using return and tab
         
         put recordArray ["id"] into tagID
         put tabTable into tagArray [tagID]
         put tagID into tagArray [tagName]
         
         put tagName & CR after tagNames
      end repeat
      delete last char of tagNames
      put tagNames into photoRecordArray ["tags"]
      revDeleteXMLTree treeID
      
      return photoRecordArray
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_XmlParsePhotoInfo


--> Flickr | Photo | Sizes
-
function flickr_FetchSizeArray photoID
   -- uses xml
   put flickr_FetchPhotoSizeXml (photoID) into someXML
   if someXML is empty then
      return empty
   else
      put flickr_ParsePhotoSizeXml (someXml, sizeArray) into sizeLabels
      return sizeArray
   end if
end flickr_FetchSizeArray

function flickr_FetchPhotoSizeXml photoID
   put "flickr.photos.getSizes" into methodName
   put photoID into paramArray["photo_id"]
   
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   get url someUrl
   return it
end flickr_FetchPhotoSizeXml

function flickr_ParsePhotoSizeXml someXml, @sizeArray
   /*
   -- strange that "m" is "small" ???
   s = small square 75x75
   t = thumbnail, 100 on longest side, small, 240 on longest side
   m = medium, 500 on longest side
   b = large, 1024 on longest side (only exists for very large original images)
   o = original image, either a jpg, gif or png, depending on source format
   */
   
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/sizes" into someNode
      put revXMLChildNames(treeID, someNode, return, "size", true) into nodeIndex
      put empty into sizeLabels
      repeat for each line shortNode in nodeIndex
         put someNode & "/" & shortNode into childNode
         
         put revXMLAttribute(treeID, childNode, "label") into someLabel
         put revXMLAttribute(treeID, childNode, "width") into someWidth
         put revXMLAttribute(treeID, childNode, "height") into someHeight
         put revXMLAttribute(treeID, childNode, "source") into someSource
         put revXMLAttribute(treeID, childNode, "url") into someURL
         
         put someSource into sizeArray [someLabel]
         put someLabel & CR after sizeLabels
      end repeat
      delete last char of sizeLabels
      revDeleteXMLTree treeID
      return sizeLabels
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParsePhotoSizeXml


--> Flickr | Photo | Context
-
function flickr_GetPhotoContext photoID
   put "flickr.photos.getContext" into methodName
   put photoID into paramArray["photo_id"]
   
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   return url someUrl
end flickr_GetPhotoContext

on flickr_ParsePhotoContext contextXML, @prevPhotoID, @prevSecret, @prevTitle, @prevStreamUrl, @prevThumbUrl, @nextPhotoID, @nextSecret, @nextTitle, @nextStreamUrl, @nextThumbUrl
   put revCreateXMLTree(contextXML, false, true, false) into treeID
   
   put "/rsp/count" into countNode
   put "/rsp/prevphoto" into prevPhotoNode
   put "/rsp/prevphoto" into prevPhotoNode
   
   put revXMLAttribute(treeID, "/rsp/prevphoto", "id") into prevPhotoID
   put revXMLAttribute(treeID, "/rsp/prevphoto", "secret") into prevSecret
   put revXMLAttribute(treeID, "/rsp/prevphoto", "title") into prevTitle
   put revXMLAttribute(treeID, "/rsp/prevphoto", "url") into prevStreamUrl
   put revXMLAttribute(treeID, "/rsp/prevphoto", "thumb") into prevThumbUrl
   
   put revXMLAttribute(treeID, "/rsp/nextphoto", "id") into nextPhotoID
   put revXMLAttribute(treeID, "/rsp/nextphoto", "secret") into nextSecret
   put revXMLAttribute(treeID, "/rsp/nextphoto", "title") into nextTitle
   put revXMLAttribute(treeID, "/rsp/nextphoto", "url") into nextStreamUrl
   put revXMLAttribute(treeID, "/rsp/nextphoto", "thumb") into nextThumbUrl
   
   revDeleteXMLTree treeID
end flickr_ParsePhotoContext


--> Flickr | Photo | Geo
-
function flickr_XmlGetPhotoGeoLocation photoID
   put "flickr.photos.geo.getLocation" into methodName
   put photoID into paramArray ["photo_id"]
   put flickr_GetAuthenticated (methodName, paramArray) into someXML
   return someXML
end flickr_XmlGetPhotoGeoLocation

function flickr_XmlParsePhotoGeoLocation someXML
   put revCreateXMLTree(someXml, false, true, false) into treeID
   
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/photo" into photoNode
      put revXMLAttribute(treeID, photoNode, "id") into photoID
      
      put photoNode & "/location" into locationNode
      put revXMLAttributes(treeID, locationNode, tab, return) into locationTable
      put locationTable into locationArray
      split locationArray using CR and tab
      
      revDeleteXMLTree treeID
      return locationArray
   else
      put rootNode & "/err" into errorNode
      put revXMLAttribute(treeID, errorNode, "code") into errorCode
      if errorCode is 2 then
         -- put revXMLAttribute(treeID, errorNode, "msg") -- into errorCode
      else
         set the error_Display of the target to responseStatus
      end if
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_XmlParsePhotoGeoLocation

function flickr_XmlGetPhotoGeoPerms photoID
   put "flickr.photos.geo.getPerms" into methodName
   put photoID into paramArray ["photo_id"]
   return flickr_GetAuthenticated(methodName, paramArray)
end flickr_XmlGetPhotoGeoPerms


--> Flickr | Favourites
-
function flickr_FetchPublicFavouritesXml pUserID
   local paramArray
   put pUserID into paramArray ["user_id"]
   put flickr_ConstructRestUrl ("flickr.favorites.getPublicList", paramArray) into someUrl
   put url someUrl into someXml
   return someXml
end flickr_FetchPublicFavouritesXml

function flickr_FetchFavouritesXml pUserID
   local paramArray
   if pUserID is not empty then put pUserID into paramArray ["user_id"]
   put flickr_ConstructRestUrl ("flickr.favorites.getList", paramArray) into someUrl
   put url someUrl into someXml
   return someXml
end flickr_FetchFavouritesXml


--> Flickr | People
-
function flickr_FindUserByUserName userName, pReturnXml
   put userName into paramArray ["username"]
   put "flickr.people.findByUsername" into methodName
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   if pReturnXml is not true then
      put "&format=json&nojsoncallback=1" after someUrl
   end if
   put url someUrl into someXML
   return someXML
end flickr_FindUserByUserName

function flickr_FindUserByEmail userEmail, pReturnXml
   put userEmail into paramArray ["find_email"]
   put "flickr.people.findByEmail" into methodName
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   if pReturnXml is not true then
      put "&format=json&nojsoncallback=1" after someUrl
   end if
   put url someUrl into someXML
   return someXML
end flickr_FindUserByEmail

on flickr_FetchUserPhotoArrays userID, @photoTableArray, @photoIdArray, @dgArray, @indexHtml
   --  flickr_FetchUserPhotoArrays userID, photoTableArray, photoIdArray, dgArray, indexHtml
   
   put empty into extras
   put 1 into pageNum
   put the flickr_PerPage of me into perPage
   put flickr_GetUserPublicPhotos (userID, extras, pageNum, perPage) into someXML
   if someXML is empty then
      put "No XML for user" && kwote(flickrUserName) into someTitle
      put empty into indexHtml
      put empty into photoArray
      put empty into photoTableArray
   else
      put "User" && kwote(flickrUserName) into someTitle
      put flickr_ConstructPhotoXmlDataArray (someXml) into photoTableArray
      flickr_DeconstructPhotoArray photoTableArray, photoIdArray, dgArray, indexHtml
   end if
end flickr_FetchUserPhotoArrays

function flickr_GetUserPublicPhotos userID, pExtras, pPage, pPerPage
   local paramArray
   
   put userID into paramArray ["user_id"]
   if pExtras is empty then
      -- date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags.
      put "owner_name,geo,tags" into pExtras
   end if
   put pPage into paramArray ["page"]
   if pPerPage is empty then put 200 into pPerPage
   put pPerPage into paramArray ["per_page"]
   
   put "flickr.people.getPublicPhotos" into methodName
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   put url someUrl into someXML
   return someXML
end flickr_GetUserPublicPhotos

function flickr_XmlGetPersonInfo userID
   put "flickr.people.getInfo" into methodName
   put userID into paramArray["user_id"]
   
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   put url someUrl into someXML
   return someXML
end flickr_XmlGetPersonInfo

function flickr_ParsePersonInfo someXml, @personInfoArray
   if someXml is empty then return empty
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/person" into someNode
      
      put revXMLAttributes(treeID, someNode, tab, return) into tabTable
      put tabTable into personInfoArray
      split personInfoArray using return and tab
      
      put personInfoArray ["id"] into personID
      
      put someNode & "/username" into childNode
      get revXMLNodeContents(treeID, childNode)
      put uniencode(it,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into personInfoArray ["userName"]
      
      put someNode & "/realname" into childNode
      get revXMLNodeContents(treeID, childNode)
      put uniencode(it,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into personInfoArray ["realName"]
      
      put someNode & "/location" into childNode
      get revXMLNodeContents(treeID, childNode)
      put uniencode(it,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into personInfoArray ["location"]
      
      put someNode & "/mbox_sha1sum" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["mbox_Sha1Sum"]
      
      put someNode & "/photosurl" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["photosUrl"]
      
      put someNode & "/profileurl" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["profileUrl"]
      
      put someNode & "/mobileurl" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["mobileUrl"]
      
      put someNode & "/photos/firstdatetaken" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["firstPhotoTaken"]
      
      put someNode & "/photos/firstdate" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["dateJoined"]
      
      put someNode & "/photos/count" into childNode
      put revXMLNodeContents(treeID, childNode) into personInfoArray ["photoCount"]
      
      revDeleteXMLTree treeID
      return personInfoArray ["userName"]
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParsePersonInfo


--> Flickr | Tags
-
function flickr_GetMyUnTaggedPhotos
   put "flickr.photos.getUntagged" into methodName
   return flickr_GetAuthenticated(methodName)
end flickr_GetMyUnTaggedPhotos

function flickr_MyPhotosToGeotag
   put "flickr.photos.getWithoutGeoData" into methodName
   return flickr_GetAuthenticated(methodName)
end flickr_MyPhotosToGeotag

function flickr_GetPhotoTags photoID
   put flickr_GetPhotoTagXml(photoID) into someXML
   put flickr_ParsePhotoTagXml(someXml, tagArray) into someTags
   return someTags
end flickr_GetPhotoTags

on flickr_SetPhotoTags photoID, tags
   put "flickr.photos.addTags" into methodName
   put photoID into paramArray["photo_id"]
   put tags into paramArray["tags"]
   
   flickr_PostAuthenticated methodName, paramArray
   return the result
end flickr_SetPhotoTags

function flickr_GetPhotoTagXml photoID
   put "flickr.tags.getListPhoto" into methodName
   put photoID into paramArray["photo_id"]
   
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   put url someUrl into someXML
   return someXML
end flickr_GetPhotoTagXml

function flickr_ParsePhotoTagXml someXml, @tagArray
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/photo" into someNode
      put revXMLAttribute(treeID, someNode, "id") into photoID
      
      put someNode & "/tags" into tagNode
      put revXMLChildNames(treeID, tagNode, return, "tag", true) into nodeIndex
      put empty into tagNames
      repeat for each line shortNode in nodeIndex
         put tagNode & "/" & shortNode into childNode
         
         put revXMLNodeContents(treeID, childNode) into tagName
         
         put revXMLAttributes(treeID, childNode, tab, return) into tabTable
         put tabTable into recordArray
         split recordArray using return and tab
         
         put recordArray ["id"] into tagID
         put tabTable into tagArray [tagID]
         put tagID into tagArray [tagName]
         
         put tagName & CR after tagNames
      end repeat
      delete last char of tagNames
      put tagNames into tagArray ["Tag Index"]
      revDeleteXMLTree treeID
      return tagNames
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParsePhotoTagXml

function flickr_GetRelatedTags someTag
   local paramArray
   put "flickr.tags.getRelated" into methodName
   
   put someTag into paramArray ["tag"]
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   get url someUrl
   return it
end flickr_GetRelatedTags

function flickr_ParseRelatedTagXml someXml
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/tags" into someNode
      put revXMLAttribute(treeID, someNode, "source") into tagSource
      
      put revXMLChildNames(treeID, someNode, return, "tag", true) into nodeIndex
      put empty into tagNames
      repeat for each line shortNode in nodeIndex
         put someNode & "/" & shortNode into childNode
         put revXMLNodeContents(treeID, childNode) into tagName
         put tagName & CR after tagNames
      end repeat
      delete last char of tagNames
      revDeleteXMLTree treeID
      return word 1 to -1 of tagNames
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParseRelatedTagXml

function flickr_GetUserTags userID
   local paramArray
   put "flickr.tags.getListUser" into methodName
   
   if userID is not empty then put userID into paramArray ["user_id"]
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   get url someUrl
   return it
end flickr_GetUserTags

function flickr_GetUserPopularTags userID, maxNum
   local paramArray
   put "flickr.tags.getListUserPopular" into methodName
   
   if userID is not empty then put userID into paramArray ["user_id"]
   if maxNum is not empty then put maxNum into paramArray ["count"]
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   get url someUrl
   return it
end flickr_GetUserPopularTags

function flickr_ParseUserTagXml someXml
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/who" into someNode
      put revXMLAttribute(treeID, someNode, "id") into userID
      
      put someNode & "/tags" into tagNode
      put revXMLChildNames(treeID, tagNode, return, "tag", true) into nodeIndex
      put empty into tagNames
      repeat for each line shortNode in nodeIndex
         put tagNode & "/" & shortNode into childNode
         
         put revXMLNodeContents(treeID, childNode) into tagName
         
         put tagName & CR after tagNames
      end repeat
      delete last char of tagNames
      revDeleteXMLTree treeID
      return tagNames
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParseUserTagXml


--> Flickr | Licenses
-
function flickr_FetchLicences
   put "flickr.photos.licenses.getInfo" into methodName
   put flickr_GetConsumerKey() into paramArray["api_key"]
   
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   return url someUrl
end flickr_FetchLicences

function flickr_ParseLicenseXml someXml, @licenseArray
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put revXMLRootNode(treeID) into rootNode
   put revXMLAttribute(treeID, "/rsp", "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/licenses" into someNode
      put revXMLChildNames(treeID, someNode, return, "", true) into nodeIndex
      repeat for each line shortNode in nodeIndex
         put someNode & "/" & shortNode into childNode
         
         put revXMLAttribute(treeID, childNode, "id") into someID
         put revXMLAttribute(treeID, childNode, "name") into someName
         put revXMLAttribute(treeID, childNode, "url") into someUrl
         
         put someName into licenseArray [someID]
         put someID into licenseArray [someName]
         put someID & ",url" into someKey
         put someUrl into licenseArray [someKey]
         put someName & CR after someNames
      end repeat
      delete last char of someNames
      put someNames into licenseArray ["Title Index"]
      
      revDeleteXMLTree treeID
      return someNames
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParseLicenseXml


--> Flickr | Reflection
-
function flickr_FetchMethodInfoXml flickrMethod
   put flickrMethod into paramArray ["method_name"]
   
   put flickr_GetConsumerKey() into paramArray["api_key"]
   put flickr_ConstructRestUrl("flickr.reflection.getMethodInfo", paramArray) into someUrl
   put url someUrl into someXml
   return someXml
end flickr_FetchMethodInfoXml

function flickr_FetchMethods
   put flickr_GetConsumerKey() into paramArray["api_key"]
   put flickr_ConstructRestUrl("flickr.reflection.getMethods", paramArray) into someUrl
   put url someUrl into someXml
   
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put revXMLRootNode(treeID) into rootNode
   put revXMLAttribute(treeID, "/rsp", "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/methods" into someNode
      put revXMLChildContents(treeID, someNode, tab, CR, false, 1) into nodeTable   
      revDeleteXMLTree treeID
      
      split nodeTable by column
      return nodeTable [2]
   else
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_FetchMethods


--> Deps 
-

--> Private 
-
private command keyword_FetchSkipArray @reducedSkipArray, @skipArray, @tagArray, pFolder, pMinLinkNum
   if pFolder is empty then put the flickr_Folder of me into pFolder
   if pMinLinkNum is empty then put 2 into minLinkNum
   
   put flickr_FetchTagArray (pFolder) into tagArray
   put linkArray_ConstructSkipArray (tagArray) into skipArray
   put linkArray_Reduce (skipArray, pMinLinkNum) into reducedSkipArray
   return reducedSkipArray
end keyword_FetchSkipArray

private function keyword_ConstructDefSection reducedSkipArray, tagArray
   local allKeys, idArray, keyArray, nodeIDs
   linkArray_ConstructIdArray reducedSkipArray, allKeys, idArray, keyArray, nodeIDs
   put the flickr_Folder of me into someFolder
   repeat for each line kName in allKeys
      put tagArray [kName] into photoIDs
      put any line of photoIDs into photoID
      put flickr_LocalThumbFile (photoID, someFolder, "png") into thumbFile
      
      if there is a file thumbFile then
         put thumbFile into defLineArray ["image"]
         put "" into defLineArray ["label"]
         put "rect" into defLineArray ["shape"]
         put "filled" into defLineArray ["style"]
         put "http://www.google.com/" & kName into defLineArray ["URL"]
         put dot_NodeDefLineFromArray (kName, defLineArray) & CR after defSection 
      else
         -- beep
      end if
   end repeat
   delete char -1 of defSection
   return defSection
end keyword_ConstructDefSection

private function googleEarth_AccuracyToAltitude geoAccuracy
   -- ie from Yahoo
   switch geoAccuracy
      case ""
         
         break
      default
         return 2000
   end switch
end googleEarth_AccuracyToAltitude
