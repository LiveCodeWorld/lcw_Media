script "model_Flickr"
--> MetaData
-
license: GPLv3
name: model_Flickr
type: model
version: 0.2

/*
Here are some extras and local models for the lib_Flick library.
*/


--> Flickr
-
/*
This library provides interface to all or nearly all of Flickr's web services.
*/

getprop flickr_Folder
   put the uOPN ["flickr_Folder"] of me into someFolder
   return someFolder
end flickr_Folder

setprop flickr_Folder someFolder
   set the uOPN ["flickr_Folder"] of me to someFolder
end flickr_Folder

getprop flickr_Sizes
   /*
   s = small square 75x75
   t = thumbnail, 100 on longest side, small, 240 on longest side
   m = medium, 500 on longest side
   b = large, 1024 on longest side (only exists for very large original images)
   o = original image, either a jpg, gif or png, depending on source format
   */
   return "small square,-,thumbnail,medium,large,-,original image"
end flickr_Sizes

getprop flickr_PerPage
   put the uOPN ["flickr_PerPage"] of me into perPage
   if perpage is empty then
      return 200
   else
      return perpage
   end if
end flickr_PerPage

setprop flickr_PerPage perPage
   set the uOPN ["flickr_PerPage"] of me to perPage
end flickr_PerPage

getprop flickr_SetName
   put the uOPN ["flickr_SetName"] of me into setName
   if setName is empty then return "Default"
   return setName
end flickr_SetName

setprop flickr_SetName setName
   set the uOPN ["flickr_SetName"] of me to setName
end flickr_SetName

getprop flickr_LoadWatchStyle
   put the uOPN ["flickr_LoadWatchStyle"] of me into watchStyle
   return watchStyle
end flickr_LoadWatchStyle

getprop flickr_LoadWatchStyles
   put the hkey_CaseConditions ["flickr_LoadWatchStyle,s"] of me into watchStyles
   return watchStyles
end flickr_LoadWatchStyles

setprop flickr_LoadWatchStyle watchStyle
   -- a wrapper to make it easier to set the event_Triggers
   set the uOPN ["flickr_LoadWatchStyle"] of me to watchStyle
   
   put the flickr_Library of me into flickrLibrary
   put the long id of cd 1 of flickrLibrary into flickrLibraryCard
   
   put "display_ThumbnailLoaded,display_PhotoInfoLoaded,display_GeoDataLoaded" into displayMessages
   switch
      case watchStyle = "default display"
         repeat for each item displayMessage in displayMessages
            put hkey_Construct (displayMessage, "c", flickrLibraryCard, 1) into hKey
            set the event_Trigger [displayMessage] of flickrLibrary to hKey
         end repeat
         break
      case watchStyle = "monitor"
         repeat for each item displayMessage in displayMessages
            put hkey_Construct ("flickr_CheckAllDataLoaded", "c", flickrLibraryCard, 1) into hKey
            set the event_Trigger [displayMessage] of flickrLibrary to hKey
         end repeat
         break
      case watchStyle = empty -- "empty"
         repeat for each item displayMessage in displayMessages
            set the event_Trigger [displayMessage] of flickrLibrary to empty
         end repeat
         break
      default
         -- assume watchStyle is a list of objects to "display" the load progress
         repeat for each item displayMessage in displayMessages
            repeat for each line controllerObject in watchStyle
               put hkey_Construct (displayMessage, "c", controllerObject, 1) into hKey
               put hKey & CR after hKeys
            end repeat
            delete char -1 of hKeys
            set the event_Trigger [displayMessage] of flickrLibrary to hKeys
         end repeat
   end switch
   return empty
end flickr_LoadWatchStyle

-- getprop event_Watchers [eventParam]
   put the long id of cd 1 of me into controllerObject
   return controllerObject
   
   switch eventParam
      case "flickr_ThumbnailLoaded"
      case "flickr_PhotoInfoLoaded"
      case "flickr_GeoDataLoaded"
   end switch
end event_Watchers

-- getprop event_Trigger [eventParam]  
   put the long id of cd 1 of me into controllerObject
   put hkey_Construct ("flickr_UpdateRecordDisplay", "c", controllerObject, 1) into hKey
   return hKey
   
   switch eventParam
      case "flickr_ThumbnailLoaded"
      case "flickr_PhotoInfoLoaded"
      case "flickr_GeoDataLoaded"
   end switch
end event_Trigger
  
  
  --> Flickr | Keywords
  -
  command flickr_DisplayKeywordGraph
   put the long id of cd 1 of me into cardObject
   put the overlay_PropertyArray of cardObject into pGraphArray
   put the dot_PropertyArray of cardObject into pDotPropertyArray
   
   put flickr_ConstructKeyWordDotText (pGraphArray, pDotPropertyArray) into dotText
   display_Dot dotText, pGraphStyle, empty, "flickr_DisplayKeywordGraph"
   put the result into displayedView
   return displayedView
end flickr_DisplayKeywordGraph

function flickr_ConstructKeyWordDotText pDotArray, pDotPropertyArray
   set the cursor to watch
   keyword_FetchSkipArray reducedSkipArray, skipArray, tagArray
   put keyword_ConstructDefSection (reducedSkipArray, tagArray) into defSection
   put linkArray_ConstructDot (skipArray, pDotArray, defSection) into dotText
   
   return dotText
end flickr_ConstructKeyWordDotText


--> Flickr | Google Earth
-
function flickr_ConstructWikiMapPoint photoID
   flickr_GetPhotoValues photoID, photoUrl, photoSecret, thumbUrl, photoTitle, imageOwner, photoTags, imageLicense
   flickr_GetMorePhotoValues photoID, geoLatitude, geoLongitude, geoAccuracy, iconServer, iconFarm, ispublic, isfriend, isfamily
   put flickr_ConstructPhotoLink(photoID, imageOwner) into photoLink
   
   -- put flickr_GetPhotoDescription(photoID) into description
   -- put flickr_GetUserNameFromArray(imageOwner) into flickrUserName
   -- put flickr_FetchUserUrl(imageOwner) into flickrUserUrl
   -- put kml_ConstructPhotoDescription(photoTitle, description, photoUrl, photoLink, flickrUserName, flickrUserName, photoLink) into description
   
   put merge("[[geoLatitude]], [[geoLongitude]], <center>[[thumbUrl]]</center><center>") into mapLine
   put "[" & photoLink && photoTitle & "]</center>" after mapLine
   return mapLine
end flickr_ConstructWikiMapPoint

on flickr_AddPhotoToGoogleEarth photoID
   put flickr_ConstructKmlPlaceMark(photoID) into someKML
   if the shiftkey is "Down" then
      put photoTitle
      put geoLatitude, geoLongitude, geoAccuracy
      put someKML
      put description
   else
      googleEarth_SaveAndFlyKML someKML
      -- googleEarth_SetView geoLatitude, geoLongitude, 600
   end if
end flickr_AddPhotoToGoogleEarth

function flickr_ConstructKmlPlaceMark photoID
   flickr_GetPhotoValues photoID, photoUrl, photoSecret, thumbUrl, photoTitle, imageOwner, photoTags, imageLicense
   flickr_GetMorePhotoValues photoID, geoLatitude, geoLongitude, geoAccuracy, iconServer, iconFarm, ispublic, isfriend, isfamily
   
   put flickr_GetPhotoDescription(photoID) into description
   put flickr_GetUserNameFromArray(imageOwner) into flickrUserName
   put flickr_FetchUserUrl(imageOwner) into flickrUserUrl
   put flickr_ConstructPhotoLink(photoID, imageOwner) into photoLink
   
   text_XmlEscape photoTitle
   text_XmlEscape flickrUserName
   
   put kml_ConstructPhotoDescription(photoTitle, description, photoUrl, photoLink, flickrUserName, flickrUserName, photoLink) into description
   
   put 0 into alititude
   put googleEarth_AccuracyToAltitude(geoAccuracy) into range
   put 0 into altitude
   put 0 into someTilt
   put 0 into heading
   put kml_ConstructPlaceMark(photoTitle, description, geoLatitude, geoLongitude, altitude, range, someTilt, heading) into someKML
   return someKML
end flickr_ConstructKmlPlaceMark


--> Flickr | File Export
-
command flickr_ConvertThumbFile photoID, pFolder
   switch the platform
      case "MacOS"
         -- shoud check for SIPS on OSX here
         if pFolder is empty then put the flickr_Folder of me into pFolder
         put flickr_ConstructImageFile (photoID, "thumbnail", pFolder, "jpg") into thumbJPG
         if there is a file thumbJPG then
            put flickr_ConstructImageFile (photoID, "thumbnail", pFolder, "png") into thumbPNG
            file_ConvertImageFormat thumbJPG, thumbPNG, "png" -- just using SIPS on OSX for now
            -- opn_Notify the result
            -- display_Lines (photoID & CR & thumbPNG), "flickr_ConvertThumbFile"
         else
            -- display_Lines (photoID & CR & thumbJPG), "flickr_ConvertThumbFile"
            beep
         end if
         break
      default
   end switch 
end flickr_ConvertThumbFile

function flickr_LocalThumbFile photoID, pFolder, pExtension
   put flickr_ConstructImageFile (photoID, "thumbnail", pFolder, pExtension) into imageFile
   return imageFile
end flickr_LocalThumbFile

function flickr_ConstructImageFile photoID, pImageType, pFolder, pExtension
   if pFolder is empty then put the flickr_Folder of me into pFolder
   if pExtension is empty then put "jpg" into pExtension
   
   flickr_NormalizeTypeChar pImageType
   put "*_" & pImageType & "." & pExtension into someFilter
   
   folder_Format pFolder
   put pFolder & photoID & "/" into photoFolder
   folder_CreateNested photoFolder
   
   put photoID & "." & pExtension into shortFile
   put photoFolder & shortFile into imageFile
   return imageFile
end flickr_ConstructImageFile

function flickr_FindLocalImageFile photoID, pImageType, pFolder, pExtension
   -- old? Why find?
   if pFolder is empty then put the flickr_Folder of me into pFolder
   if pExtension is empty then put "jpg" into pExtension
   
   flickr_NormalizeTypeChar pImageType
   put "*_" & pImageType & "." & pExtension into someFilter
   
   folder_Format pFolder
   put pFolder & photoID & "/" into photoFolder
   put folder_ShortFiles(photoFolder) into shortFiles
   filter shortFiles with someFilter
   if shortFiles is empty then return empty
   put any line of shortFiles into shortFile
   return photoFolder & shortFile
end flickr_FindLocalImageFile

function flickr_PhotoUrlToShortFile someUrl, pExtension
   set the itemdelimiter to "/" 
   put item -1 of someUrl into shortFile
   
   set the itemdelimiter to "_" 
   delete item 2 of shortFile
   
   if pExtension is not empty then
      set the itemdelimiter to "." 
      put pExtension into item -1 of shortFile
   end if
   return shortFile
end flickr_PhotoUrlToShortFile

function flickr_PhotoUrlToFile someUrl, pExtension, pFolder
   if pFolder is empty then put the flickr_Folder of me into pFolder
   
   set the itemdelimiter to "/" 
   put item -1 of someUrl into shortFile
   
   set the itemdelimiter to "_" 
   put item 1 of shortFile into photoID
   put item 2 of shortFile into photoSecret
   put item 3 of shortFile into imageType
   delete item 2 of shortFile
   
   folder_Format pFolder
   put pFolder & photoID & "/" into photoFolder
   folder_CreateNested recordFolder
   put photoFolder & shortFile into imageFile
   return imageFile
end flickr_PhotoUrlToFile


--> Flickr | Photo ID | Model
-
on flickr_SetOldPhotoArrayTags latestTags, photoID
   put flickr_GetOldPhotoArray(photoID) into photoArray
   replace CR with space in latestTags
   put word 1 to -1 of latestTags into tagWords
   put tagWords into photoArray ["tags"]
   flickr_SetOldPhotoArray photoID, photoArray
   return photoArray
end flickr_SetOldPhotoArrayTags

function flickr_GetPhotoIDs
   put flickr_GetPhotoTableArray() into photoTableArray
   put photoTableArray ["PhotoID Index"] into photoIDs
   return photoIDs
end flickr_GetPhotoIDs

on flickr_SetPhotoValues photoID, photoUrl, photoSecret, smallUrl, photoTitle, imageOwner, photoTags, imageLicense, description, notes, geoList, relatedList
   -- does not set:  serverID, photoSecret, farm
   -- flickr_SetPhotoFlickrValues photoArray, serverID, photoSecret, farm
   
   put flickr_GetOldPhotoArray(photoID) into photoArray
   
   flickr_SetOldPhotoArrayValues photoArray, photoID, photoUrl, photoSecret, smallUrl, photoTitle, imageOwner, photoTags, imageLicense, description, notes
   flickr_DeconstructGeoList geoList, geoLatitude, geoLongitude, geoAccuracy   
   flickr_DeconstructRelatedList geoList, ispublic, isfriend, isfamily
   flickr_SetExtraArrayValues photoArray, geoLatitude, geoLongitude, geoAccuracy, ispublic, isfriend, isfamily
   
   flickr_SetOldPhotoArray photoID, photoArray
end flickr_SetPhotoValues

on flickr_SetOldPhotoArrayValues @photoArray, photoUrl, photoSecret, smallUrl, photoTitle, imageOwner, photoTags, imageLicense, description, notes
   put photoUrl into photoArray ["photoURL"]
   put photoSecret into photoArray ["secret"]
   
   -- put smallUrl into photoArray ["photoURL_Small"]
   put smallUrl into photoArray ["Small"]
   
   put photoTitle into photoArray ["title"]
   put imageOwner into photoArray ["owner"]
   put photoTags into photoArray ["tags"]
   put imageLicense into photoArray ["license"]
   put description into photoArray ["description"]
   put notes into photoArray ["notes"]
end flickr_SetOldPhotoArrayValues

on flickr_SetExtraArrayValues @photoArray, geoLatitude, geoLongitude, geoAccuracy, ispublic, isfriend, isfamily
   -- could comine into a geoRecord?
   put geoLatitude into photoArray ["latitude"]
   put geoLongitude into photoArray ["longitude"]
   put geoAccuracy into photoArray["accuracy"]
   
   put ispublic into photoArray ["ispublic"]
   put isfriend into photoArray ["isfriend"]
   put isfamily into photoArray ["isfamily"]
end flickr_SetExtraArrayValues

on flickr_SetPhotoFlickrValues @photoArray, serverID, photoSecret, farm
   -- may work and is certaily more general to set icon and image urls as in a sizeURLArray
   
   -- flickr stuff
   put serverID into photoArray ["server"]
   put photoSecret into photoArray ["secret"]
   put farmID into photoArray ["farm"]
end flickr_SetPhotoFlickrValues

function flickr_ConstructGeoList geoLatitude, geoLongitude, geoAccuracy
   return geoLatitude,geoLongitude,geoAccuracy
end flickr_ConstructGeoList

on flickr_DeconstructGeoList geoList, @geoLatitude, @geoLongitude, @geoAccuracy
   put item 1 of geoList into geoLatitude
   put item 2 of geoList into geoLongitude
   put item 3 of geoList into geoAccuracy
end flickr_DeconstructGeoList

function flickr_ConstructRelatedList ispublic, isfriend, isfamily
   return ispublic,isfriend,isfamily
end flickr_ConstructRelatedList

on flickr_DeconstructRelatedList relatedList, @ispublic, @isfriend, @isfamily
   put item 1 of relatedList into ispublic
   put item 2 of relatedList into isfriend
   put item 3 of relatedList into isfamily
end flickr_DeconstructRelatedList

on flickr_GetPhotoValues photoID, @photoUrl, @photoSecret, @smallUrl, @photoTitle, @imageOwner, @photoTags, @imageLicense
   put flickr_GetOldPhotoArray(photoID) into photoArray
   
   put photoArray ["secret"] into photoSecret
   put photoArray ["photoURL"] into photoUrl
   -- put line 1 of photoArray ["photoURL_Small"] into smallUrl
   put photoArray ["Small"] into smallUrl
   -- put photoArray ["Medium"] into mediumUrl
   -- put photoArray ["Thumbnail"] into thumbUrl
   
   
   put photoArray ["title"] into photoTitle
   put uniencode(photoTitle,"UTF8") into someU16
   put unidecode(someU16, "ANSI") into photoTitle
   
   put photoArray ["owner"] into imageOwner
   
   put photoArray ["tags"] into photoTags
   put uniencode(photoTags,"UTF8") into someU16
   put unidecode(someU16, "ANSI") into photoTags
   
   put photoArray ["license"] into imageLicense
end flickr_GetPhotoValues

on flickr_GetPhotoTech photoID, @iconServer, @iconFarm
   put flickr_GetOldPhotoArray(photoID) into photoArray
   
   put photoArray ["iconserver"] into iconServer
   put photoArray ["iconfarm"] into iconFarm
end flickr_GetPhotoTech

on flickr_GetMorePhotoValues photoID, @geoLatitude, @geoLongitude, @geoAccuracy, @serverID, @farmID, @ispublic, @isfriend, @isfamily
   put flickr_GetOldPhotoArray(photoID) into photoArray
   
   put photoArray ["latitude"] into geoLatitude
   put photoArray ["longitude"] into geoLongitude
   put photoArray ["accuracy"] into geoAccuracy
   
   put photoArray ["server"] into serverID
   put photoArray ["farm"] into farmID
   
   put photoArray ["ispublic"] into ispublic
   put photoArray ["isfriend"] into isfriend
   put photoArray ["isfamily"] into isfamily
end flickr_GetMorePhotoValues

function flickr_ExtractTagsFromPhotoTableArray
   local allTags
   put flickr_GetPhotoTableArray() into photoTableArray
   put photoTableArray ["PhotoID Index"] into photoIDs
   repeat for each line photoID in photoIDs
      set the cursor to busy
      put photoTableArray [photoID] into photoTable
      put photoTable into photoArray
      split photoArray using return and tab
      
      put photoArray["tags"] into photoTags
      put uniencode(photoTags,"UTF8") into someU16
      put unidecode(someU16, "ANSI") into photoTags
      repeat for each word someTag in photoTags
         line_Add someTag, allTags
      end repeat
      if the shiftkey is "Down" then exit to top
   end repeat
   sort allTags
   return allTags
end flickr_ExtractTagsFromPhotoTableArray

function flickr_GetPhotoExtraInfoFlag photoID
   put flickr_GetOldPhotoArray(photoID) into photoArray
   return photoArray ["extraInfoHasBeenSet"]
end flickr_GetPhotoExtraInfoFlag

on flickr_SetPhotoExtraInfoFlag photoID, boolean
   put flickr_GetOldPhotoArray(photoID) into photoArray
   put boolean into photoArray ["extraInfoHasBeenSet"]
   flickr_SetOldPhotoArray photoID, photoArray
end flickr_SetPhotoExtraInfoFlag

function flickr_GetPhotoSizeArray photoID
   local sizeArray
   put flickr_GetOldPhotoArray(photoID) into photoArray
   put photoArray ["AvailableSizeList"] into sizeList
   
   if sizeList is empty then
      -- lets fetch xml and update (could be sperated???)
      put flickr_FetchSizeArray(photoID) into sizeArray
      
      if keys(sizeArray) is empty then
         breakpoint
         flickr_GuessAndSetPhotoSizes photoArray, photoID, serverID, photoSecret, farmID
         put the result into sizeArray
         
         -- probably should only set when fetched from server?
         flickr_SetPhotoSizeArray photoID, sizeArray
         return sizeArray
      end if
      return sizeArray
   else
      repeat for each item someSize in sizeList
         put photoArray [someSize] into sizeUrl
         put sizeUrl into sizeArray [someSize]
      end repeat
   end if
   return sizeArray
end flickr_GetPhotoSizeArray

on flickr_SetPhotoSizeArray photoID, sizeArray
   put flickr_GetOldPhotoArray(photoID) into photoArray
   union photoArray with sizeArray
   get keys(sizeArray)
   replace CR with comma in it
   put it into photoArray ["AvailableSizeList"]
   flickr_SetOldPhotoArray photoID, photoArray
end flickr_SetPhotoSizeArray

function flickr_GetPhotoDescription photoID
   put flickr_GetOldPhotoArray(photoID) into photoArray
   return photoArray ["description"]
end flickr_GetPhotoDescription

on flickr_SetPhotoDescription photoID, description
   put flickr_GetOldPhotoArray(photoID) into photoArray
   put description into photoArray ["description"]
   flickr_SetOldPhotoArray photoID, photoArray
end flickr_SetPhotoDescription

function flickr_GetPhotoNotes photoID
   put flickr_GetOldPhotoArray(photoID) into photoArray
   return photoArray ["notes"]
end flickr_GetPhotoNotes

on flickr_SetPhotoNotes photoID, notes
   put flickr_GetOldPhotoArray(photoID) into photoArray
   put description into photoArray ["notes"]
   flickr_SetOldPhotoArray photoID, photoArray
end flickr_SetPhotoNotes

--> Flickr | Person | Model
-
function flickr_GetPeopleInTable
   put flickr_GetUserTableArray() into userTableArray
   put flickr_ExtractUserLookUpArray(userTableArray) into userLookUpArray
   return word 1 to -1 of keys(userLookUpArray)
   
   put the long id of me into modelObject
   get model_GetValue("UserName Index", modelObject, "uOPN_PersonInfoTableArray", "array")
   return word 1 to -1 of it
end flickr_GetPeopleInTable

function flickr_GetUserIDFromArray userName
   put flickr_GetUserTableArray() into userTableArray
   put flickr_ExtractUserLookUpArray(userTableArray) into userLookUpArray
   return userLookUpArray [userName]
end flickr_GetUserIDFromArray

function flickr_GetUserNameFromArray personID
   put flickr_GetPersonInfoArray(personID) into personInfoArray
   return personInfoArray ["userName"]
end flickr_GetUserNameFromArray

function flickr_GetPersonInfoArray personID
   put flickr_GetPersonInfoTable(personID) into personInfoTable
   split personInfoTable with CR and tab
   return personInfoTable
end flickr_GetPersonInfoArray

on flickr_SetPersonInfoArray personID, personInfoArray
   combine personInfoArray with CR and tab
   flickr_SetPersonInfoTable personID, personInfoArray
end flickr_SetPersonInfoArray

function flickr_GetPersonInfoTable personID
   put the long id of me into modelObject
   return model_GetValue(personID, modelObject, "uOPN_PersonInfoTableArray", "array")
end flickr_GetPersonInfoTable

on flickr_SetPersonInfoTable personID, personInfoTable
   put personInfoTable into personInfoArray
   split personInfoArray with CR and tab
   put personInfoArray ["userName"] into userName
   
   put flickr_GetUserTableArray() into userTableArray
   
   put flickr_ExtractUserLookUpArray(userTableArray) into userLookUpArray
   -- put userName into userLookUpArray [personID]
   put personID into userLookUpArray [userName]
   flickr_SetUserLookUpArray userLookUpArray, userTableArray
   
   put personInfoTable into userTableArray [personID]
   -- array_AddToIndex userName, "UserName Index", userTableArray 
   
   flickr_SetUserTableArray userTableArray
end flickr_SetPersonInfoTable

function flickr_ExtractUserLookUpArray userTableArray
   put userTableArray ["User Lookup Table"] into userLookUpTable
   split userLookUpTable with CR and tab
   return userLookUpTable
end flickr_ExtractUserLookUpArray

on flickr_SetUserLookUpArray userLookUpArray, @userTableArray
   combine userLookUpArray with CR and tab
   put userLookUpArray into userTableArray ["User Lookup Table"]
end flickr_SetUserLookUpArray

function flickr_GetUserTableArray
   put the long id of me into modelObject
   return model_GetArray("uOPN_PersonInfoTableArray", modelObject, "array")
end flickr_GetUserTableArray

on flickr_SetUserTableArray userTableArray
   put the long id of me into modelObject
   model_SetArray "uOPN_PersonInfoTableArray", modelObject, userTableArray, "array"
end flickr_SetUserTableArray


--> Flickr | Groups | Model
-
function flickr_GetGroupTitles
   put the long id of me into modelObject
   return model_GetValue("Title Index", modelObject, "uOPN_FlickrGroupArray", "array")
end flickr_GetGroupTitles

function flickr_GetGroupArray
   put the long id of me into modelObject
   put model_GetArray("uOPN_FlickrGroupArray", modelObject, "array") into dataArray
   return dataArray
end flickr_GetGroupArray

on flickr_SetGroupArray someArray
   put the long id of me into modelObject
   model_SetArray "uOPN_FlickrGroupArray", modelObject, someArray, "array"
end flickr_SetGroupArray


--> Flickr | PhotoSets | Model
-
function flickr_GetPhotoSetTitles
   put the long id of me into modelObject
   return model_GetValue("Title Index", modelObject, "uOPN_PhotoSetArray", "array")
end flickr_GetPhotoSetTitles

function flickr_GetPhotoSetArray
   put the long id of me into modelObject
   put model_GetArray("uOPN_PhotoSetArray", modelObject, "array") into dataArray
   return dataArray
end flickr_GetPhotoSetArray

on flickr_SetPhotoSetArray someArray
   put the long id of me into modelObject
   model_SetArray "uOPN_PhotoSetArray", modelObject, someArray, "array"
end flickr_SetPhotoSetArray


--> Flickr | Licences | Model
-
function flickr_GetLicenseArray
   put the long id of me into modelObject
   put the customproperties ["uOPN_FlickrLicenseArray"] of me into licenseArray
   return licenseArray
end flickr_GetLicenseArray

on flickr_SetLicenseArray licenseArray
   put the long id of me into modelObject
   set the customproperties ["uOPN_FlickrLicenseArray"] of me to licenseArray
end flickr_SetLicenseArray


--> Flickr | Async | Model
-
/*
These handlers allow asynchronous laoding of Flickr MetaData.
The data is stored in a local array Flickr_PhotoArray, and updated as the Async loads come in.
Flags are also stored in the local array Flickr_PhotoArray so it is possible to avoid repeat loads and recursion.
All the information you need to display and fetch further info is therefore in Flickr_PhotoArray

Triggers are sent out when loads have completed allowing for the display to be updated.

Once all the data has been loaded for a particular photo.
A message "flickr_CheckAllDataLoaded" is sent to allow the data to be processed and stored to disk.
While in the data is still be loaded a message can be sent  to display each chunk as it comes in,
These messages are stored as event_Trigger of this stack (see flickr_LoadWatchStyle"
*/

on flickr_LoadAndUpdateRecordArray photoID
   --  set the mvc display of "flickr_DisplayLoadProgress" to "monitor"
   set the flickr_LoadWatchers of me to "monitor"
   
   -- fetch the stored recordArray
   put flickr_GetPhotoRecordArray (photoID) into recordArray
   
   -- load
   flickr_LoadThumbail photoID, recordArray ["Thumbnail"]
   flickr_LoadPhotoInfo photoID, recordArray ["secret"]
   flickr_LoadGeoData photoID
end flickr_LoadAndUpdateRecordArray

command flickr_UpdatePhotoRecordArray photoID, recordArrayBits, pSetName
   if keys(recordArrayBits) is empty then return empty
   
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   if keys(recordArray) is empty then
      flickr_SetPhotoRecordArray photoID, recordArrayBits, pSetName
   else
      union recordArrayBits with recordArray
      flickr_SetPhotoRecordArray photoID, recordArrayBits, pSetName
   end if
   return recordArrayBits
end flickr_UpdatePhotoRecordArray


--> Flickr | Async | Load | Thumbnail
-
command flickr_LoadThumbail photoID, thumbnailURL, pSetName
   put flag_GetThumbnailLoading (photoID, pSetName) into isLoading
   put flag_GetThumbnailLoaded (photoID, pSetName) into isLoaded
   
   switch
      case isLoading = true
         -- opn_Notify ("Already loading url for thumbNail:" && photoID), true
         break
      case isLoaded = true
         -- opn_Notify ("Don't fetch and update flickr_LoadThumbail if already loaded:" && photoID), true
         break
      case isLoaded is false
         -- not loaded thumbnail yet (so load thumnail and all metadata)
         -- opn_Notify ("loading dg_DisplayThumbNail"), true
         flag_SetThumbnailLoading photoID, true, pSetName
         load url thumbnailURL with message "flickr_ThumbnailLoaded"
   end switch
end flickr_LoadThumbail

on flickr_ThumbnailLoaded thumbnailURL, statusOfFile
   switch statusOfFile 
      case "error"
         opn_Notify ("Error loading thumbnail" && thumbnailURL), true
         break
      case "cached"
         -- fetch new data
         put url thumbnailURL into someImage
         unload url thumbnailURL
         
         -- update recordArray
         put the flickr_SetName of me into pSetName
         put flickr_FindRecordArray ("Thumbnail", thumbnailURL, pSetName) into recordArray
         put someImage into recordArray ["thumbnail image"]
         put recordArray ["id"] into photoID
         flickr_SetPhotoRecordArray photoID, recordArray, pSetName
         
         -- update flags
         put recordArray ["id"] into photoID
         flag_SetThumbnailLoaded photoID, true, pSetName
         flag_SetThumbnailLoading photoID, false, pSetName
         
         -- mvc display
         flickr_DisplayLoadProgress "display_ThumbnailLoaded", recordArray, someImage
   end switch
end flickr_ThumbnailLoaded


--> Flickr | Async | Load | PhotoInfo
-
command flickr_LoadPhotoInfo photoID, pPhotoSecret, pSetName
   put flag_GetPhotoInfoLoading (photoID, pSetName) into isLoading
   put flag_GetPhotoInfoLoaded (photoID, pSetName) into isLoaded
   
   switch
      case isLoading = true
         -- opn_Notify ("Don't fetch and update 'flickr_LoadPhotoInfo' as it is currently loading:" && photoID), true
         break
      case isLoaded = true
         -- opn_Notify ("Don't fetch and update 'flickr_LoadPhotoInfo' if already loaded:" && photoID), true
         break
      case isLoaded is false
         flag_SetPhotoInfoLoading photoID, true, pSetName
         put flickr_ConstructPhotoInfoUrl (photoID, pPhotoSecret) into photoInfoUrl
         
         -- opn_Notify ("Loading flickr_LoadPhotoInfo for:" && photoID), true
         load photoInfoUrl with message "flickr_PhotoInfoLoaded"
         break
      default
         breakPoint
   end switch
end flickr_LoadPhotoInfo

on flickr_PhotoInfoLoaded photoInfoUrl, statusOfFile
   switch statusOfFile 
      case "error"
         opn_Notify ("Error loading photoInfo" && kwote(photoInfoUrl)), true
         break
      case "cached"
         -- opn_Notify ("flickr_PhotoInfoLoaded"), true
         put url photoInfoUrl into someXML
         unload photoInfoUrl
         
         -- update recordArray
         put flickr_ParsePhotoInfo (someXml) into photoRecordArrayBits
         put photoRecordArrayBits ["id"] into photoID
         put the flickr_SetName of me into pSetName
         flickr_UpdatePhotoRecordArray photoID, photoRecordArrayBits, pSetName
         put the result into recordArray
         
         -- update flags
         flag_SetPhotoInfoLoaded photoID, true, pSetName
         flag_SetPhotoInfoLoading photoID, false, pSetName
         
         -- mvc display
         flickr_DisplayLoadProgress "display_PhotoInfoLoaded", recordArray, photoRecordArrayBits
   end switch
end flickr_PhotoInfoLoaded


--> Flickr | Async | Load | GeoData
-
command flickr_LoadGeoData photoID, pSetName
   put flag_GetGeoDataLoading (photoID, pSetName) into isLoading
   put flag_GetGeoDataLoaded (photoID, pSetName) into isLoaded
   
   switch
      case isLoading = true
         -- opn_Notify ("Photo geo url for photo id" && photoID && "is currently loading"), true
         break
      case isLoaded = true
         -- opn_Notify ("Don't fetch and update 'flickr_LoadGeoData' if already loaded:" && photoID), true
         break
      case isLoaded is false
         -- opn_Notify ("Loading flickr_LoadGeoData for:" && photoID), true
         flag_SetGeoDataLoading photoID, true, pSetName
         put photoID into paramArray ["photo_id"]
         put flickr_ConstructAuthenticationUrl ("flickr.photos.geo.getLocation", paramArray) into flickrGeoUrl
         load flickrGeoUrl with message "flickr_GeoDataLoaded"
   end switch
end flickr_LoadGeoData

on flickr_GeoDataLoaded flickrGeoUrl, statusOfFile
   switch statusOfFile 
      case "error"
         opn_Notify ("Error loading geodata" && flickrGeoUrl), true
         break
      case "cached"
         -- opn_Notify ("flickr_GeoDataLoaded"), true
         put the flickr_SetName of me into pSetName
         
         put flickr_ExtractPhotoIDFromUrl (flickrGeoUrl) into photoID
         put url flickrGeoUrl into someXML
         unload flickrGeoUrl
         
         -- update recordArray
         put flickr_ParsePhotoGeoLocation (someXML) into locationArray
         if keys(locationArray) is empty then
            -- no location info (nothing to update)
            put flickr_GetPhotoRecordArray (photoID) into recordArray
         else
            -- update the recordArray
            flickr_UpdatePhotoRecordArray photoID, locationArray, pSetName
            put the result into recordArray
         end if
         
         -- update flags
         flag_SetGeoDataLoaded photoID, true, pSetName
         flag_SetGeoDataLoading photoID, false, pSetName
         
         -- mvc display
         flickr_DisplayLoadProgress "display_GeoDataLoaded", recordArray, locationArray
   end switch
end flickr_GeoDataLoaded

function flickr_ExtractPhotoIDFromUrl someUrl
   -- not futere proofed use recordArray based id look up instead
   put url_ConstructParamArray (someUrl) into paramArray -- could deconstruct url
   put paramArray ["photo_id"] into photoID
   return photoID
end flickr_ExtractPhotoIDFromUrl


--> Flickr | Async | Display
-
/*
These MVC like display contrllers should be able to dispatch messages to urls as well as stacks.
Can use triggers to do this.
*/

on flickr_DisplayLoadProgress displayMessage, recordArray, newData
   -- eventParam = "flickr_ThumbnailLoaded"
   
   put recordArray ["id"] into photoID
   
   put the event_Trigger [displayMessage] of me into hKeys
   repeat for each line hKey in hKeys
      hkey_Deconstruct hKey, handlerName, handlerType, controllerObject, handlerNum
      dispatch handlerName to controllerObject with photoID, newData, recordArray, displayMessage
   end repeat
   return empty
   
   put the event_Watchers [eventParam] of me into controllerObjects
   repeat for each line controllerObject in controllerObjects
      dispatch displayMessage to controllerObject with photoID,newData,recordArray
      -- set the displayMessage[photoID] of controllerObject to newData
      -- set the flickr_DisplayedRecord [photoID] of controllerObject to recordArray
   end repeat
   return empty
end flickr_DisplayLoadProgress


--> Flickr | Async | Events
-
on flickr_CheckAllDataLoaded photoID, newData, recordArray, displayMessage
   -- because of Async nature - this can clear array before last load
   -- need to use tripple flag test, to confirm all data is loaded
   put the flickr_SetName of me into pSetName
   if flickr_AllPhotoDataLoaded (photoID, pSetName) then
      -- beep
      -- opn_Notify ("All data for record" && photoID && "has loaded!"), true
      put the flickr_Folder of me into someFolder
      flickr_StorePhotoRecordArray someFolder, recordArray
   else
      -- opn_Notify ("Still loading" && displayMessage && "for record" && photoID)
   end if
end flickr_CheckAllDataLoaded


--> Flickr | Stored | PhotoArray
-
function flickr_FetchPhotoArray urlOrFolder
   -- url could be a local "file:" or a remote "http:" or "ftp:"
   url_Deconstruct urlOrFolder, someProtocol, urlDomain, urlPath, shortName, fileExtension, uName, pWord
   switch someProtocol
      case "ftp"
         break
      case "http"
         break
      case "file"
         break
      case empty
         put urlOrFolder into someFolder
         folder_Format someFolder
         put someFolder & "recordArray" into someFile
         put array_Fetch (someFile) into photoArray
         return photoArray
   end switch
end flickr_FetchPhotoArray

on flickr_SavePhotoArray someFolder, photoArray
   folder_Format someFolder
   put someFolder & "recordArray" into someFile
   array_Save someFile, photoArray
end flickr_SavePhotoArray
   
   
   --> Flickr | Stored | TagArray
   -
function flickr_FetchTagArray someFolder
   folder_Format someFolder
   put someFolder & "tagArray" into someFile
   put array_Fetch (someFile) into tagArray
   return tagArray
end flickr_FetchTagArray

on flickr_SaveTagArray someFolder, tagArray
   folder_Format someFolder
   put someFolder & "tagArray" into someFile
   array_Save someFile, tagArray
end flickr_SaveTagArray

on flickr_StorePhotoArray urlOrFolder, photoArray
   -- url could be a local "file:" or a remote "http:" or "ftp:"
   url_Deconstruct urlOrFolder, someProtocol, urlDomain, urlPath, shortName, fileExtension, uName, pWord
   switch someProtocol
      case "ftp"
         break
      case "http"
         break
      case "file"
         break
      case empty
         -- export each record in photoArray
         put urlOrFolder into someFolder
         repeat for each key photoID in photoArray
            put photoArray [photoID] into recordArray
            flickr_ExportPhotoRecord recordArray, someFolder
         end repeat
   end switch
   return flickrPhotoArray
end flickr_StorePhotoArray


--> Flickr | PhotoRecordArray
-
command flickr_StorePhotoRecordArray urlOrFolder, recordArray
   url_Deconstruct urlOrFolder, someProtocol, urlDomain, urlPath, shortName, fileExtension, uName, pWord
   switch someProtocol
      case "ftp"
         break
      case "http"
         break
      case "file"
         break
      case empty
         put urlOrFolder into someFolder
         flickr_ExportPhotoRecord recordArray, someFolder
   end switch
end flickr_StorePhotoRecordArray

on flickr_ExportPhotoRecord recordArray, someFolder
   if there is not a folder someFolder then return empty
   put recordArray ["id"] into photoID 
   
   folder_Format someFolder
   put flickr_FetchPhotoArray (someFolder) into photoArray
   
   put someFolder & photoID & "/" into recordFolder
   folder_CreateNested recordFolder
   
   put recordArray ["thumbnail"] into thumbUrl
   put flickr_ConstructImageFile (photoID, "thumbnail", someFolder, "jpg") into thumbJpgFile
   
   put recordArray ["thumbnail image"] into someImage
   put someImage into url ("binfile:" & thumbJpgFile)
   put thumbJpgFile into recordArray ["thumbnail image"]
   
   flickr_ConvertThumbFile photoID, someFolder
   
   put recordArray ["tags"] into tagLines
   put flickr_FetchTagArray (someFolder) into tagArray
   repeat for each line tagLine in tagLines
      put tagArray [tagLine] into linkedIDs
      line_Add photoID, linkedIDs
      put linkedIDs into tagArray [tagLine]
   end repeat
   flickr_SaveTagArray someFolder, tagArray
   
   put recordArray into photoArray [photoID]
   flickr_SavePhotoArray someFolder, photoArray
end flickr_ExportPhotoRecord  

function flickr_AllPhotoDataLoaded photoID, pSetName
   put flag_GetThumbnailLoaded(photoID, pSetName) into doneThumb
   put flag_GetPhotoInfoLoaded(photoID, pSetName) into doneInfo
   put flag_GetGeoDataLoaded(photoID, pSetName) into doneGeo
   
   -- display_Lines (photoID && doneThumb,doneInfo,doneGeo)
   
   put doneGeo and doneInfo and doneThumb into someBoolean
   -- put doneInfo and doneThumb into someBoolean
   return someBoolean
end flickr_AllPhotoDataLoaded

--> Flickr | Async | Model
-
function flickr_FindRecordArray someKey, someVaue, pSetName
   -- uses the dg_FindRecordArray library handler to search stadard dgArray data structure
   put flickr_GetPhotoArray (pSetName) into photoArray
   put dg_FindRecordArray (someKey, someVaue, photoArray) into recordArray
   return recordArray
end flickr_FindRecordArray


--> Flickr | Async | Model | Flags | Thumbnail
-
function flag_GetThumbnailLoading photoID, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put pRecordArray ["loading"]["thumbnail"] into someBoolean 
   return someBoolean is true
end flag_GetThumbnailLoading

command flag_SetThumbnailLoading photoID, someBoolean, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put someBoolean into recordArray ["loading"]["thumbnail"]
   flickr_SetPhotoRecordArray photoID, recordArray, pSetName
end flag_SetThumbnailLoading

function flag_GetThumbnailLoaded photoID, recordArray, pSetName
   -- return recordArray ["thumbnail image"] is not empty
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put recordArray ["loaded"]["thumbnail"] into someBoolean
   return someBoolean is true
end flag_GetThumbnailLoaded

command flag_SetThumbnailLoaded photoID, someBoolean, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put someBoolean into recordArray ["loaded"]["thumbnail"]
   flickr_SetPhotoRecordArray photoID, recordArray, pSetName
end flag_SetThumbnailLoaded


--> Flickr | Async | Model | Flags | Photo Info
-
function flag_GetPhotoInfoLoading photoID, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put recordArray ["loading"]["photo info"] into someBoolean 
   return someBoolean is true
end flag_GetPhotoInfoLoading

command flag_SetPhotoInfoLoading photoID, someBoolean, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put someBoolean into recordArray ["loading"]["photo info"]
   flickr_SetPhotoRecordArray photoID, recordArray, pSetName
end flag_SetPhotoInfoLoading

function flag_GetPhotoInfoLoaded photoID, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put recordArray ["loaded"]["photo info"] into someBoolean
   return someBoolean is true
end flag_GetPhotoInfoLoaded

command flag_SetPhotoInfoLoaded photoID, someBoolean, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put someBoolean into recordArray ["loaded"]["photo info"]
   flickr_SetPhotoRecordArray photoID, recordArray, pSetName
end flag_SetPhotoInfoLoaded


--> Flickr | Async | Model | Flags | GeoData
-
function flag_GetGeoDataLoading photoID, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put recordArray ["loading"]["geo data"] into someBoolean 
   return someBoolean is true
end flag_GetGeoDataLoading

command flag_SetGeoDataLoading photoID, someBoolean, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put someBoolean into recordArray ["loading"]["geo data"]
   flickr_SetPhotoRecordArray photoID, recordArray, pSetName
end flag_SetGeoDataLoading

function flag_GetGeoDataLoaded photoID, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put recordArray ["loaded"]["geo data"] into someBoolean
   return someBoolean is true
end flag_GetGeoDataLoaded

command flag_SetGeoDataLoaded photoID, someBoolean, pSetName
   put flickr_GetPhotoRecordArray (photoID, pSetName) into recordArray
   put someBoolean into recordArray ["loaded"]["geo data"]
   flickr_SetPhotoRecordArray photoID, recordArray, pSetName
end flag_SetGeoDataLoaded


--> Flickr | Photo | Model
-
/*
This new model is datagrid compatible. Each entry is stored under the photoID key,
but also has an id = photoID property
*/

local Flickr_PhotoArray

function flickr_GetPhotoRecordArray photoID, pSetName
   if pSetName is empty then put "Default" into pSetName
   put Flickr_PhotoArray [pSetName][photoID] into recordArray
   return recordArray
end flickr_GetPhotoRecordArray

command flickr_SetPhotoRecordArray photoID, recordArray, pSetName
   if pSetName is empty then put "Default" into pSetName
   put recordArray into Flickr_PhotoArray [pSetName][photoID]
end flickr_SetPhotoRecordArray

command flickr_DeletePhotoRecordArray photoID, pSetName
   if pSetName is empty then put "Default" into pSetName
   put Flickr_PhotoArray [pSetName][photoID] into recordArray
   delete local Flickr_PhotoArray [pSetName][photoID]
   return recordArray
end flickr_DeletePhotoRecordArray

command flickr_DeletePhotoArray pSetName
   if pSetName is empty then put "Default" into pSetName
   put Flickr_PhotoArray [pSetName] into photoArray
   delete local Flickr_PhotoArray [pSetName]
   delete local Flickr_PhotoArray
   return photoArray
end flickr_DeletePhotoArray

function flickr_GetPhotoArray pSetName
   if pSetName is empty then put "Default" into pSetName
   return Flickr_PhotoArray [pSetName]
end flickr_GetPhotoArray

command flickr_SetPhotoArray flickrPhotoArray, pSetName
   if pSetName is empty then put "Default" into pSetName
   put flickrPhotoArray into Flickr_PhotoArray [pSetName]
end flickr_SetPhotoArray

function flickr_ConstructDatagridArray flickrPhotoArray
   local dgArray
   put 1 into indexNum
   repeat for each key photoID in flickrPhotoArray
      put flickrPhotoArray [photoID] into dgArray [indexNum]
      add 1 to indexNum
   end repeat
   return dgArray
end flickr_ConstructDatagridArray


--> Flickr | Photo | Model
-
function flickr_GetOldPhotoArray photoID
    put flickr_GetPhotoTableArray() into photoTableArray
    put photoTableArray [photoID] into photoTable
    put photoTable into photoArray
    split photoArray using return and tab
    return photoArray
end flickr_GetOldPhotoArray

on flickr_SetOldPhotoArray photoID, photoArray
    put flickr_GetPhotoTableArray() into photoTableArray
     
    put photoArray into photoTable
    combine photoTable using return and tab
    
    put photoTable into photoTableArray [photoID]
    flickr_SetPhotoTableArray photoTableArray
    return photoTableArray
end flickr_SetOldPhotoArray

function flickr_GetPhotoTableArray
    put the long id of me into modelObject
    return model_GetArray("uOPN_PhotoTableArray", modelObject, "array")
end flickr_GetPhotoTableArray

on flickr_SetPhotoTableArray photoTableArray
    put the long id of me into modelObject
    model_SetArray "uOPN_PhotoTableArray", modelObject, photoTableArray, "array"
end flickr_SetPhotoTableArray


--> Private
-
private command flickr_NormalizeTypeChar @imageType
   /*
   s = small square 75x75
   t = thumbnail, 100 on longest side, small, 240 on longest side
   m = medium, 500 on longest side
   b = large, 1024 on longest side (only exists for very large original images)
   o = original image, either a jpg, gif or png, depending on source format
   */
   if imageType is empty then
      put "s" into imageType
   else
      put char 1 of imageType into imageType
   end if
end flickr_NormalizeTypeChar

