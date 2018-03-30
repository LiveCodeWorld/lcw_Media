script "lib_FlickrExtras"
--> MetaData
-
license: GPLv3
name: lib_FlickrExtras
type: library
version: 0.2


--> Flickr | User
-
function flickr_GetContacts
   local paramArray
   put "flickr.contacts.getList" into methodName
   return flickr_GetAuthenticated(methodName, paramArray)
end flickr_GetContacts

function flickr_ParseContactXml someXml, @someArray
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/contacts" into someNode
      put revXMLAttribute(treeID, someNode, "page") into somePage
      put revXMLAttribute(treeID, someNode, "pages") into pages
      put revXMLAttribute(treeID, someNode, "perpage") into perPage
      put revXMLAttribute(treeID, someNode, "total") into someTotal
      
      put revXMLChildNames(treeID, someNode, return, "contact", true) into nodeIndex
      put empty into userNames
      repeat for each line shortNode in nodeIndex
         put someNode & "/" & shortNode into childNode
         
         put revXMLAttributes(treeID, childNode, tab, return) into recordTable
         put recordTable into recordArray
         split recordArray using return and tab
         
         put recordArray["nsid"] into userNSID
         put recordArray["username"] into userName
         
         put recordTable into someArray [userNSID]
         put userNSID into someArray [userName]
         put userName & CR after userNames
      end repeat
      delete last char of userNames
      put userNames into someArray ["Username Index"]
      revDeleteXMLTree treeID
      return userNames
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParseContactXml

function flickr_GetBlogsList
   local paramArray
   put "flickr.blogs.getList" into methodName
   return flickr_GetAuthenticated(methodName, paramArray)
end flickr_GetBlogsList


--> Flickr | Urls
-
function flickr_GetPhotoUrl photoID, displaySize
   put flickr_GetPhotoSizeArray(photoID) into sizeArray
   
   -- a local hack in case canot fetch sizearray
   if keys(sizeArray) is empty then return flickr_ConstructPhotoUrl (photoID, photoSize)
   switch displaySize
      case empty
         return sizeArray ["square"]
      case "largest"
         get sizeArray ["original"]
         if it is not empty then return it
         get sizeArray ["large"]
         if it is not empty then return it
         return sizeArray ["medium"]
      case "large"
         -- as it may not exist
         get sizeArray ["large"]
         if it is not empty then return it
         return sizeArray ["medium"]
      default
         return sizeArray [displaySize]
   end switch
end flickr_GetPhotoUrl


--> Flickr | Urls | Guess
-
function flickr_ConstructPhotoLink photoID, userID
   return merge("http://www.flickr.com/photos/[[userID]]/[[photoID]]/")
end flickr_ConstructPhotoLink

function flickr_FetchUserUrl userID
   put "flickr.urls.getUserProfile" into methodName
   if userID is not empty then put userID into paramArray["user_id"]
   
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   put url someUrl into someXML
   
   -- <user nsid="12037949754@N01" url="http://www.flickr.com/people/bees/" />
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put revXMLRootNode(treeID) into rootNode
   put revXMLAttribute(treeID, "/rsp", "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/user" into someNode
      put revXMLAttribute(treeID, someNode, "nsid") into someID
      put revXMLAttribute(treeID, someNode, "url") into someUrl
      revDeleteXMLTree treeID
      return someUrl
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_FetchUserUrl

on flickr_GuessAndSetPhotoSizes @photoArray, photoID, serverID, photoSecret, farmID
   -- not guessing large or oriinal urls as they may not exist of be private
   
   get flickr_ConstructPhotoUrl(photoID, empty, serverID, photoSecret, farmID)
   put it into photoArray ["photoURL"]
   -- put it into sizeArray ["Medium"]
   
   get flickr_ConstructPhotoUrl(photoID, "small", serverID, photoSecret, farmID)
   put it into photoArray ["Small"]
   put it into sizeArray ["Small"]
   
   get flickr_ConstructPhotoUrl(photoID, "thumbnail", serverID, photoSecret, farmID)
   put it into photoArray ["Thumbnail"]
   put it into sizeArray ["Thumbnail"]
   
   get flickr_ConstructPhotoUrl(photoID, "medium", serverID, photoSecret, farmID)
   put it into photoArray ["Medium"]
   put it into sizeArray ["Medium"]
   
   return sizeArray
end flickr_GuessAndSetPhotoSizes

function flickr_ConstructPhotoUrl photoID, photoSize, serverID, photoSecret, farmID
   /*
   You can construct the source URL to a photo once you know its ID, server ID, farm id and secret, as returned by many API methods.
   The URL takes the following format:
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg or
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}_[mstb].jpg or
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{o-secret}_o.(jpg|gif|png)
   
   s = small square 75x75
   t = thumbnail, 100 on longest side, small, 240 on longest side
   m = medium, 500 on longest side
   b = large, 1024 on longest side (only exists for very large original images)
   o = original image, either a jpg, gif or png, depending on source format
   */
   
   if serverID is empty then
      flickr_GetPhotoValues photoID, photoUrl, photoSecret, thumbUrl, photoTitle, imageOwner, photoTags, imageLicense
      flickr_GetMorePhotoValues photoID, geoLatitude, geoLongitude, geoAccuracy, serverID, farmID, ispublic, isfriend, isfamily
   end if
   
   if farmID is empty then
      put empty into someFarm
   else
      put "farm" & farmID & "." into someFarm
   end if
   
   if photoSize is empty then
      put empty into mtsbBit
   else
      put char 1 of photoSize into mstb
      put "_" & mstb into mtsbBit
   end if
   get merge("http://[[someFarm]]static.flickr.com/[[serverID]]/[[photoID]]_[[photoSecret]][[mtsbBit]].jpg")
   return it
end flickr_ConstructPhotoUrl

on flickr_DeconstructPageUrl photoPageURL, @photoID, @userID
   /*
   Takes a url from a browser and ties to uess the photoID
   
   -- http://www.flickr.com/photos/90161705@N00/2657830633/in/set-72157606089063550/
   -- http://www.flickr.com/photos/90161705@N00/2657830633/sizes/m/in/set-72157606089063550/
   -- http://www.flickr.com/photos/striatic/2852209218/
   -- http://www.flickr.com/photos/wttw/14763924/
   -- http://farm4.static.flickr.com/3149/2657830633_6e84923345_d.jpg
   */
   
   url_Deconstruct photoPageURL, someProtocol, urlDomain, urlPath, shortName, fileExtension, userName, pissWord
   
   set the itemdelimiter to "/"
   if item 1 of urlPath = "photos" then
      put item 2 of urlPath into userID
      put item 3 of urlPath into photoID
   else
      put "" into userID
      put "" into photoID
   end if
end flickr_DeconstructPageUrl

function flickr_ConstructShortPhotoFile photoID, photoSecret, pExtension
   if pExtension is empty then put "jpg" into pExtension -- "jpg|gif|png"
   put merge("[[photoID]]_[[photoSecret]]_[[mtsbBit]].[[pExtension]]") into shortFile
   return it
end flickr_ConstructShortPhotoFile

on flickr_DeconstructPhotoUrl photoURL, @serverID, @photoID, @photoSecret, @photoType, @fileExtension, @farmID
   /*
   The URL takes the following format:
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg or
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}_[mstb].jpg or
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{o-secret}_o.(jpg|gif|png)
   */
   
   url_Deconstruct photoURL, someProtocol, urlDomain, urlPath, shortName, fileExtension, userName, pissWord
   
   set the itemdelimiter to "."
   put item 1 of urlDomain into farmBit
   if char 1 to 4 of farmBit is "farm" then
      put char 5 to - 1 of farmBit into farmID
   else
      put empty into farmID
   end if
   
   set the itemdelimiter to "/"
   put item 1 of urlPath into serverID
   
   set the itemdelimiter to "_"
   put item 1 of shortName into photoID
   put item 2 of shortName into photoSecret
   put item 3 of shortName into photoType
   
   switch photoType 
      case empty
         return ""
      case "o"
         return "original"
      default -- mtsb
         return photoType
   end switch
end flickr_DeconstructPhotoUrl


--> Flickr | Urls | Old
-
function flickr_ConstructOriginalPhotoUrl serverID, photoID, photoSecret, someExtension
   if someExtension is empty then put "jpg" into someExtension -- "jpg|gif|png"
   get merge("http://static.flickr.com/[[serverID]]/[[photoID]]_[[photoSecret]]_o.[[someExtension]]")
   return it
end flickr_ConstructOriginalPhotoUrl

on flickr_DeconstructThumbUrl thumbUrl, @serverID, @photoID, @photoSecret, @mstb, @fileExtension
   -- "http://static.flickr.com/27/35305348_139209fd52_s.jpg"
   
   set the itemdelimiter to "/"
   put item - 1 of thumbUrl into shortFile
   put item - 2 of thumbUrl into serverID
   
   set the itemdelimiter to "_"
   put item 1 of shortFile into photoID
   put item 2 of shortFile into photoSecret
   
   put item -1 of shortFile into lastBit
   set the itemdelimiter to "."
   put item 1 of lastBit into mstb
   put item -1 of lastBit into fileExtension
end flickr_DeconstructThumbUrl

function flickr_ConstructSizePhotoUrl serverID, photoID, photoSecret, someSize, farmID
   /*
   You can construct the source URL to a photo once you know its ID, server ID, farm id and secret, as returned by many API methods.
   The URL takes the following format:
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg or
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}_[mstb].jpg or
   http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{o-secret}_o.(jpg|gif|png)
   
   s = small square 75x75
   t = thumbnail, 100 on longest side, small, 240 on longest side
   m = medium, 500 on longest side
   b = large, 1024 on longest side (only exists for very large original images)
   o = original image, either a jpg, gif or png, depending on source format
   */
   
   if farmID is empty then
      put empty into someFarm
   else
      put "farm" & farmID & "." into someFarm
   end if
   put char 1 of someSize into mstb
   get merge("http://[[someFarm]]static.flickr.com/[[serverID]]/[[photoID]]_[[photoSecret]]_[[mstb]].jpg")
   return it
end flickr_ConstructSizePhotoUrl


--> Flickr | Search
-
function flickr_SearchPhotos tagList, tagMode, userID, license, titleText, groupID, perPage, page, bbox, accuracy, extras, minTakenDate, maxTakenDate, minUploadDate, maxUploadDate
   put "flickr.photos.search" into methodName
   
   if tagList is not empty then put tagList into paramArray["tags"]
   if userID is not empty then put userID into paramArray["user_id"]
   if perPage is empty then
      put 200 into paramArray["per_page"]
   else
      put perPage into paramArray["per_page"]
   end if
   if page is not empty then put page into paramArray["page"]
   if tagMode is not empty then put tagMode into paramArray["tag_mode"]
   if titleText is not empty then put titleText into paramArray["text"]
   
   if groupID is not empty then put groupID into paramArray["group_id"]
   if extras is empty then
      put "license,geo,tags,icon_server" into paramArray["extras"]
   else
      put extras into paramArray["extras"]	#  Currently supported fields are: license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags.
   end if
   
   if bbox is not empty then put bbox into paramArray["bbox"]
   if accuracy is not empty then put accuracy into paramArray["accuracy"]
   
   if minUploadDate is not empty then put minUploadDate into paramArray["min_upload_date"]
   if maxUploadDate is not empty then put maxUploadDate into paramArray["max_upload_date"]
   if minTakenDate is not empty then put minTakenDate into paramArray["min_taken_date"]
   if maxTakenDate is not empty then put maxTakenDate into paramArray["max_taken_date"]
   
   if license is not empty then put license into paramArray["license"]
   
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   
   -- can take a while
   put the sockettimeoutinterval into oTimeOut
   set the sockettimeoutinterval to 20000
   get url someUrl
   set the sockettimeoutinterval to oTimeOut
   return it
end flickr_SearchPhotos


--> Flickr | Interesting
-
function flickr_GetInteresting yyyymmdd
   local urlArray, indexHtml
   
   put "flickr.interestingness.getList" into methodName
   if yyyymmdd is not empty then put yyyymmdd into paramArray["date"] 
   -- put "license,date_upload,date_taken,owner_name,icon_server,original_format,last_update" into paramArray["extras"]
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   put url someUrl into photoXML
   
   if the shiftkey is "Down" then put photoXML
   
   if flickr_ExtractRSP (photoXML) is "ok" then
      put flickr_ParsePhotoXml (photoXML, urlArray) into indexHtml
      return indexHtml
   else
      return empty
   end if
end flickr_GetInteresting

function flickr_ParsePhotoXml photoXML, @photoTableArray
   -- <photos page="2" pages="89" perpage="10" total="881">
   
   put empty into photoTableArray
   put revCreateXMLTree(photoXML, false, true, false) into treeID
   
   put revXMLRootNode(treeID) into rootNode
   put rootNode & "/photos" into photosNode
   
   put revXMLAttribute(treeID, photosNode, "page") into photoTableArray ["page"]
   put revXMLAttribute(treeID, photosNode, "perpage") into photoTableArray ["perPage"]
   put revXMLAttribute(treeID, photosNode, "pages") into photoTableArray ["pages"]
   put revXMLAttribute(treeID, photosNode, "total") into photoTableArray ["total"]
   
   put revXMLChildNames(treeID, photosNode, return, "", true) into shortPhotoNodes
   put empty into photoIDs
   repeat for each line shortPhotoNode in shortPhotoNodes
      put photosNode & "/" & shortPhotoNode into photoNode
      
      put revXMLAttributes(treeID, photoNode, tab, return) into photoTable
      put photoTable into photoArray
      split photoArray using return and tab
      
      put photoArray["id"] into photoID
      put photoArray ["title"] into photoTitle
      
      -- construct urls
      put photoArray ["server"] into serverID
      put photoArray ["secret"] into photoSecret
      put photoArray ["farm"] into farmID
      
      -- flickr_GuessAndSetPhotoSizes photoArray, photoID, serverID, photoSecret, farmID
      
      combine photoArray using return and tab
      put photoArray into photoTableArray [photoID]
      
      put uniencode(photoTitle,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into photoTitle
      
      if photoTitle is empty then
         put "Untitled" && photoID into photoTitle
      end if
      put html_ConstructNameLink(photoTitle, photoID) into htmlLine
      put htmlLine & CR after indexHtml
      put photoID & CR after photoIDs
   end repeat
   delete last char of indexHtml
   delete last char of photoIDs
   put photoIDs into photoTableArray ["PhotoID Index"]
   
   revDeleteXMLTree treeID
   return indexHtml
end flickr_ParsePhotoXml


--> Flickr | Group
-
function flickr_SearchForGroups someText
   local paramArray
   put someText into paramArray ["text"]
   put "flickr.groups.search" into methodName
   put flickr_ConstructRestUrl(methodName, paramArray) into someUrl
   get url someUrl
   return it
end flickr_SearchForGroups

function flickr_FetchGroupPhotos groupID, tags, userID, extras, page, perPage
   local paramArray
   
   put userID into paramArray ["user_id"]
   put tags into paramArray ["tags"]
   if extras is empty then
      -- date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags.
      put "geo,tags" into extras
   end if
   if page is empty then
      put 1 into paramArray ["page"]
   else
      put page into paramArray ["page"]
   end if
   if perPage is empty then
      put the flickr_PerPage of me into paramArray ["per_page"]
   else
      put perPage into paramArray ["per_page"]
   end if
   
   put groupID into paramArray ["group_id"]
   put "flickr.groups.pools.getPhotos" into methodName
   
   return flickr_GetAuthenticated(methodName, paramArray)
end flickr_FetchGroupPhotos

function flickr_ParseUserPublicPhotoXML someXML
   put flickr_ConstructPhotoXmlDataArray (someXml) into photoTableArray
   flickr_DeconstructPhotoArray photoTableArray, photoIdArray, dgArray, indexHtml
   return indexHtml
end flickr_ParseUserPublicPhotoXML

on flickr_DeconstructPhotoArray photoTableArray, @photoIdArray, @dgArray, @indexHtml
   put photoTableArray ["data"]["photoIDs"] into photoIdArray
   put photoTableArray ["dgArray"] into dgArray
   put photoTableArray ["data"]["indexHtml"] into indexHtml
   -- put photoTableArray ["data"]["photoIDs"] into photoIDs
end flickr_DeconstructPhotoArray

function flickr_ConstructPhotoXmlDataArray someXml
   put revCreateXMLTree(someXml, false, true, false) into treeID
   
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/photos" into photoGroupNode
      
      put revXMLAttribute(treeID, photoGroupNode, "page") into photoTableArray ["metadata"]["page"]
      put revXMLAttribute(treeID, photoGroupNode, "perpage") into photoTableArray ["metadata"]["perPage"]
      put revXMLAttribute(treeID, photoGroupNode, "pages") into photoTableArray ["metadata"]["pages"]
      put revXMLAttribute(treeID, photoGroupNode, "total") into photoTableArray ["metadata"]["total"]
      
      put revXMLChildNames(treeID, photoGroupNode, return, "photo", true) into shortPhotoNodes
      put empty into photoIDs
      -- repeat for each line shortPhotoNode in shortPhotoNodes
      repeat with lineNum = 1 to the number of lines of shortPhotoNodes
         put line lineNum of shortPhotoNodes into shortPhotoNode
         put photoGroupNode & "/" & shortPhotoNode into photoNode
         
         put revXMLAttributes(treeID, photoNode, tab, return) into photoAttributeTable
         put photoAttributeTable into photoArray
         split photoArray using return and tab
         
         put photoArray ["id"] into photoID
         put photoArray ["title"] into photoTitle
         if photoTitle is empty then put "Untitled" && photoID into photoTitle
         put uniencode(photoTitle,"UTF8") into someU16
         put unidecode(someU16, "ANSI") into photoTitle
         
         -- construct urls
         put photoArray ["server"] into serverID
         put photoArray ["secret"] into photoSecret
         put photoArray ["farm"] into farmID
         
         flickr_GuessAndSetPhotoSizes photoArray, photoID, serverID, photoSecret, farmID
         -- combine photoArray using return and tab
         put photoArray into photoTableArray ["data"]["photoIDs"][photoID]
         put photoArray into photoTableArray ["dgArray"][lineNum]
         
         put html_ConstructNameLink(photoTitle, photoID) into htmlLine
         put htmlLine & CR after indexHtml
         put photoID & CR after photoIDs
      end repeat
      delete last char of indexHtml
      delete last char of photoIDs
      
      put indexHtml into photoTableArray ["data"]["indexHtml"]
      -- put photoIDs into photoTableArray ["data"]["photoIDs"]
      
      revDeleteXMLTree treeID
      return photoTableArray
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ConstructPhotoXmlDataArray

function flickr_FetchMyGroups page, perPage
   local paramArray
   if page is empty then
      put 1 into paramArray ["page"]
   else
      put page into paramArray ["page"]
   end if
   if perPage is empty then
      put the flickr_PerPage of me into paramArray ["per_page"]
   else
      put perPage into paramArray ["per_page"]
   end if
   put "flickr.groups.pools.getGroups" into methodName
   get flickr_GetAuthenticated(methodName, paramArray)
   return it
end flickr_FetchMyGroups

function flickr_ParseGroupXml someXml, @photoGroupArray
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/groups" into someNode
      put revXMLAttribute(treeID, someNode, "page") into somePage
      put revXMLAttribute(treeID, someNode, "pages") into pages
      put revXMLAttribute(treeID, someNode, "perpage") into perPage
      put revXMLAttribute(treeID, someNode, "total") into someTotal
      
      put revXMLChildNames(treeID, someNode, return, "group", true) into nodeIndex
      put empty into groupTitles
      repeat for each line shortNode in nodeIndex
         put someNode & "/" & shortNode into childNode
         
         put revXMLAttributes(treeID, childNode, tab, return) into groupAttributeTable
         put groupAttributeTable into groupArray
         split groupArray using return and tab
         
         put groupArray ["nsid"] into groupNSID
         put groupArray ["name"] into groupTitle
         
         put groupAttributeTable into photoGroupArray [groupNSID]
         put groupNSID into photoGroupArray [groupTitle]
         put groupTitle & CR after groupTitles
      end repeat
      delete last char of groupTitles
      put groupTitles into photoGroupArray ["Title Index"]
      revDeleteXMLTree treeID
      return groupTitles
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParseGroupXml


--> Flickr | PhotoSets
-
function flickr_GetAndIndexPhotoSets userID
   put flickr_FetchPhotoSets (userID) into someXml
   if someXml is empty then
      return "Error: xml is empty"
   else
      put flickr_ParsePhotoSetListXml(someXml, dataArray) into photoSetNames
      
      -- could add rather than overwrite?
      flickr_SetPhotoSetArray dataArray
      return photoSetNames
   end if
end flickr_GetAndIndexPhotoSets

function flickr_PhotoSetPhotos photosetID, perPage, page, extras, privacy
   local paramArray
   put "flickr.photosets.getPhotos" into methodName
   
   put photosetID into paramArray ["photoset_id"]
   
   if page is empty then
      put 1 into paramArray ["page"]
   else
      put page into paramArray ["page"]
   end if
   if perPage is empty then
      put the flickr_PerPage of me into paramArray ["per_page"]
   else
      put perPage into paramArray ["per_page"]
   end if
   if extras is empty then
      -- date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags.
      put "geo,tags" into extras
   end if
   if privacy is empty then
      /*
      * 1 public photos
      * 2 private photos visible to friends
      * 3 private photos visible to family
      * 4 private photos visible to friends & family
      * 5 completely private photos
      */
   else
      put perPage into paramArray ["privacy_filter"]
   end if
   
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   get url someUrl
   return it
end flickr_PhotoSetPhotos

function flickr_FetchPhotoSets userID
   local paramArray
   put "flickr.photosets.getList" into methodName
   if userID is not empty then put userID into paramArray ["user_id"]
   
   get flickr_GetAuthenticated (methodName, paramArray)
   return it
end flickr_FetchPhotoSets

function flickr_ParsePhotoSetXml photoSetXml, @photoTableArray
   put revCreateXMLTree(photoSetXml, false, true, false) into treeID
   
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/photoset" into photoSetNode
      
      put revXMLAttribute(treeID, photoSetNode, "id") into photoSetID
      put revXMLAttribute(treeID, photoSetNode, "primary") into photoSetPrimary
      put revXMLAttribute(treeID, photoSetNode, "owner") into photoSetOwner
      put revXMLAttribute(treeID, photoSetNode, "ownername") into photoSetOwnerName
      put revXMLAttribute(treeID, photoSetNode, "page") into photoSetPage
      put revXMLAttribute(treeID, photoSetNode, "per_page") into photoSetPerPage
      put revXMLAttribute(treeID, photoSetNode, "pages") into photoSetPages
      
      put revXMLChildNames(treeID, photoSetNode, return, "photo", true) into shortPhotoNodes
      put empty into photoIDs
      repeat for each line shortPhotoNode in shortPhotoNodes
         put photoSetNode & "/" & shortPhotoNode into photoNode
         
         put revXMLAttributes(treeID, photoNode, tab, return) into photoAttributeTable
         put photoAttributeTable into photoArray
         split photoArray using return and tab
         
         put photoArray ["id"] into photoID
         put photoArray ["title"] into photoTitle
         if photoTitle is empty then put "Untitled" && photoID into photoTitle
         put uniencode(photoTitle,"UTF8") into someU16
         put unidecode(someU16, "ANSI") into photoTitle
         
         put photoArray ["server"] into serverID
         put photoArray ["secret"] into photoSecret
         put photoArray ["farm"] into farmID
         
         -- construct urls as PhotoSetXml does not contain links
         flickr_GuessAndSetPhotoSizes photoArray, photoID, serverID, photoSecret, farmID
         
         combine photoArray using return and tab
         put photoArray into photoTableArray [photoID]
         
         put html_ConstructNameLink(photoTitle, photoID) into htmlLine
         put htmlLine & CR after indexHtml
         put photoID & CR after photoIDs
      end repeat
      delete last char of indexHtml
      delete last char of photoIDs
      put photoIDs into photoTableArray ["PhotoID Index"]
      
      revDeleteXMLTree treeID
      return indexHtml
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParsePhotoSetXml

function flickr_ParsePhotoSetListXml someXml, @photoSetArray
   -- revDeleteAllXMLTrees
   put empty into photoSetArray
   put revCreateXMLTree(someXml, false, true, false) into treeID
   put "/rsp" into rootNode
   put revXMLAttribute(treeID, rootNode, "stat") into responseStatus
   if responseStatus is "OK" then
      put rootNode & "/photosets" into someNode
      put revXMLAttribute(treeID, someNode, "cancreate") into cancreate
      
      put revXMLChildNames(treeID, someNode, return, "photoset", true) into nodeIndex
      put empty into photoSetTitles
      repeat for each line shortNode in nodeIndex
         put someNode & "/" & shortNode into childNode
         
         put revXMLAttribute(treeID, childNode, "id") into photoSetID
         put revXMLAttribute(treeID, childNode, "primary") into photoSetPrimary
         put revXMLAttribute(treeID, childNode, "secret") into photoSetSecret
         put revXMLAttribute(treeID, childNode, "server") into photoSetServer
         put revXMLAttribute(treeID, childNode, "farm") into photoSetFarm
         put revXMLAttribute(treeID, childNode, "photos") into photoSetPhotoNum
         
         put childNode & "/" & "title" into titleNode
         put revXMLNodeContents(treeID, titleNode) into photoSetTitle
         put childNode & "/" & "description" into descriptionNode
         put revXMLNodeContents(treeID, descriptionNode) into photoSetDescription
         
         flickr_ConstructPhotoSetArray photoSetArray, photoSetID, photoSetTitle, photoSetDescription, photoSetPhotoNum
         flickr_ConstructExtraPhotoSetArray photoSetArray, photoSetID, photoSetPrimary, photoSetSecret, photoSetServer, photoSetFarm
         
         put photoSetTitle & CR after photoSetTitles
      end repeat
      delete last char of photoSetTitles
      put photoSetTitles into photoSetArray ["Title Index"]
      revDeleteXMLTree treeID
      return photoSetTitles
   else
      set the error_Display of the target to responseStatus
      revDeleteXMLTree treeID
      return empty
   end if
end flickr_ParsePhotoSetListXml

on flickr_ConstructPhotoSetArray @photoSetArray, photoSetID, photoSetTitle, photoSetDescription, photoSetPhotoNum
   put photoSetID into photoSetArray [photoSetTitle]
   
   put photoSetID & comma & "photoSetTitle" into someKey
   put photoSetTitle into photoSetArray [someKey]
   
   put photoSetID & comma & "photoSetDescription" into someKey
   put photoSetDescription into photoSetArray [someKey]
   
   put photoSetID & comma & "photoSetPhotoNum" into someKey
   put photoSetPhotoNum into photoSetArray [someKey]
end flickr_ConstructPhotoSetArray

on flickr_ConstructExtraPhotoSetArray @photoSetArray, photoSetID, photoSetPrimary, photoSetSecret, photoSetServer, photoSetFarm
   put photoSetID & comma & "photoSetPrimary" into someKey
   put photoSetPrimary into photoSetArray [someKey]
   
   put photoSetID & comma & "photoSetSecret" into someKey
   put photoSetSecret into photoSetArray [someKey]
   
   put photoSetID & comma & "photoSetServer" into someKey
   put photoSetServer into photoSetArray [someKey]
   
   put photoSetID & comma & "photoSetFarm" into someKey
   put photoSetFarm into photoSetArray [someKey]
end flickr_ConstructExtraPhotoSetArray
