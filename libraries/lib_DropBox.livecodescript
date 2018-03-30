script "lib_DropBox"
--> MetaData
-
license: GPLv3
name: lib_DropBox
type: library
version: 0.3


--> Events
-
on libraryStack
   if the environment = "server" then
      get rigLoadConfigFile("rest")
   end if
end libraryStack


--> Screenshot
-
command screenshots_UploadToFlickr pFolderJSON
   if pFolderJSON is empty then
      put dropbox_FetchListFolderJson ("/screenshots") into pFolderJSON
   end if
   
   put json_ToArray (pFolderJSON) into fetchArray
   put fetchArray ["entries"] into entryArray
   
   -- probably only one new image
   put item 2 of the extents of entryArray into maxNum
   
   repeat with itemNum = 1 to maxNum
      put entryArray [itemNum]["id"] into idPath
      screenshot_DropToFlickr idPath
      put the result into photoID
      put photoID & CR after photoIDs
   end repeat
   
   repeat for each line photoID in photoIDs
      put flickr_FetchPhotoInfo (photoID) into photoInfoArray
      put merge("https://www.flickr.com/photos/152869685@N06/[[photoID]]/in/album-72157684427120031/") into someURL
      put someURL & CR after flickrURLs
      
      -- put merge ("flickr_AddToAlbum [[photoID]], 72157684427120031") into someMessage
      -- send someMessage to me in 10 seconds -- add to Screenshots
      flickr_AddToAlbum photoID, "72157684427120031"
   end repeat
   delete char -1 of flickrURLs
   return flickrURLs
end screenshots_UploadToFlickr

command screenshot_DropToFlickr dropPath
   -- put "/screenshots/test.png" into dropPath
   -- put "id:VUrEqWb9bpAAAAAAAAAAGQ" into dropPath
   --
   try
      put dropbox_FetchData (dropPath) into somePhoto
      if somePhoto is empty then
         return "Error, could not fetch photo from Dropbox."
      end if
   catch e
      return "error, problem with dropbox_FetchData()"
   end try
   --
   try
      put dropbox_FetchTitle (dropPath) into photoTitle
   catch e
      return "error, problem with dropbox_FetchTitle()"
   end try
   
   put "This screenshot as imported from DropBox" into description
   put " - https://www.dropbox.com/home/Screenshots?preview=" & urlencode (photoTitle) after description
   put "screenshot" into tags
   
   flickr_UploadPhoto somePhoto, photoTitle, description, tags, true
   put the result into photoID
   return photoID
end screenshot_DropToFlickr


--> Dropbox | Auth
-
function dropbox_GetAuthToken
   if the environment = "server" then
      put gConfig["dropBoxAuthToken"] into dropBoxAuthToken
   else
      put pref_FetchValue ("dropBoxAuthToken", "rest") into dropBoxAuthToken
   end if
   return dropBoxAuthToken
end dropbox_GetAuthToken

command dropbox_SetAuthToken dropBoxAuthToken
   if the environment = "server" then
      -- this is only temporary
      -- need to figure out how best to store configs (maybe a json file)
      rigSetConfigItem "dropBoxAuthToken", dropBoxAuthToken
   else
      pref_SaveValue "dropBoxAuthToken", dropBoxAuthToken, "rest"
      return the result
   end if
end dropbox_SetAuthToken


--> DropBox
-
function dropbox_FetchTitle dropPath  
   /*
   put "id:VUrEqWb9bpAAAAAAAAAAGQ" into dropPath
   put "/Screenshots/test.png" into dropPath
   
   put http_GetReceivedHeader ("dropbox-api-result") into resultJSON
   put json_ToArray (resultJSON) into dropboxResultArray
   put dropboxResultArray ["name"] into photoTitle
   */
   put dropbox_FetchMetadata (dropPath) into someArray
   --
   put someArray ["name"] into photoTitle
   if photoTitle is empty then put "Dropbox Screenshot" into photoTitle
   return photoTitle 
end dropbox_FetchTitle

function dropbox_ListFolder somePath, pRecurseFolders, pIncludeMediaInfo, pIncludeDeleted, pIncludeSharedMembers
   put dropbox_FetchListFolderJson (somePath, pRecurseFolders, pIncludeMediaInfo, pIncludeDeleted, pIncludeSharedMembers) into someJSON
   --
   put json_ToArray (someJSON) into fetchArray
   put fetchArray ["cursor"] into lastCursor
   put fetchArray ["has_more"] into someBoolean
   put fetchArray ["entries"] into entryArray
   
   put dropbox_FetchListFolderContinueJson (lastCursor) into continueJSON
   return continueJSON
end dropbox_ListFolder

command dropbox_StoreListFolderCursor somePath
   put asset_GetJSON ("list_folder.json") into folderJSON
   if folderJSON is empty then
      put dropbox_FetchListFolderJson (somePath, pRecurseFolders, pIncludeMediaInfo, pIncludeDeleted, pIncludeSharedMembers) into folderJSON
      asset_SetJSON "list_folder.json", folderJSON
   end if
   
   put json_ToArray (folderJSON) into listFolderArray
   put listFolderArray ["cursor"] into lastCursor
   put listFolderArray ["cursor"] into lastCursor
   --
   return listFolderArray
end dropbox_StoreListFolderCursor

command dropbox_InitScreenshotsFolder
   put dropbox_FetchListFolderJson ("/screenshots") into folderJSON
   asset_SetJSON "screenshots_folder.json", folderJSON
   put the result into jsonFile
   return jsonFile
end dropbox_InitScreenshotsFolder

function dropbox_FetchListFolderJson somePath, pRecurseFolders, pIncludeMediaInfo, pIncludeDeleted, pIncludeSharedMembers
   put "https://api.dropboxapi.com/2/files/list_folder" into someURL
   --
   put somePath into paramArray ["path"]
   if pRecurseFolders is not empty then put pRecurseFolders into paramArray ["recursive"]
   if pIncludeMediaInfo is not empty then put pIncludeMediaInfo into paramArray ["include_media_info"]
   if pIncludeDeleted is not empty then put pIncludeDeleted into paramArray ["include_deleted"]
   if pIncludeSharedMembers is not empty then put pIncludeSharedMembers into paramArray ["include_has_explicit_shared_members"]
   put json_FromArray (paramArray) into someJSON
   --
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end dropbox_FetchListFolderJson

function dropbox_FetchListFolderContinueJson lastCursor
   put "https://api.dropboxapi.com/2/files/list_folder/continue" into someURL
   put lastCursor into paramArray ["cursor"]   
   put json_FromArray (paramArray) into someJSON
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end dropbox_FetchListFolderContinueJson

function dropbox_ListFolders
   put "https://api.dropboxapi.com/2/sharing/list_folders" into someURL
   -- put "https://api.dropboxapi.com/2/sharing/list_mountable_folders" into someURL
   --
   put 1000 into paramArray ["limit"]
   -- put "" into paramArray ["actions"]
   put json_FromArray (paramArray) into someJSON
   
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end dropbox_ListFolders

function dropbox_FetchData pathOrID
   put "https://content.dropboxapi.com/2/files/download" into someURL
   --
   put pathOrID into paramArray ["path"]
   put json_FromArray (paramArray) into someJSON
   put dropbox_GetAuthToken() into dropBoxAuthToken
   put "Authorization: Bearer" && dropBoxAuthToken & CR & "Content-Type: text/plain" & CR & "Dropbox-API-Arg:" && someJSON into newHeaders
   set the httpheaders to newHeaders
   --
   post empty to url someURL
   put it into someData
   --
   return someData
end dropbox_FetchData

function dropbox_FetchTempLink pathOrID
   put pathOrID into paramArray ["path"]
   put json_FromArray (paramArray) into someJSON
   put "https://api.dropboxapi.com/2/files/get_temporary_link" into someURL
   put dropbox_ReturnPost (someJSON, someURL) into someJSON
   put json_ToArray (someJSON) into resultArray
   -- display_Array resultArray
   put resultArray ["link"] into tempURL
   return tempURL
end dropbox_FetchTempLink

function dropbox_ReturnPost someJSON, someURL
   put dropbox_GetAuthToken() into dropBoxAuthToken
   set the httpheaders to "Authorization: Bearer" && dropBoxAuthToken & CR & "Content-Type: application/json"
   post someJSON to url someURL
   return it
end dropbox_ReturnPost

function dropbox_FetchListFolder folderPath
   put "https://api.dropboxapi.com/2/files/list_folder" into someURL
   
   put folderPath into paramArray ["path"]
   
   put "false" into paramArray ["include_media_info"]
   put "false" into paramArray ["include_deleted"]
   put "false" into paramArray ["include_has_explicit_shared_members"]
   put json_FromArray (paramArray) into someJSON
   
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end dropbox_FetchListFolder

function dropbox_FetchFolderMetadata folderID
   -- put "1521901553" into folderID
   --
   put "https://api.dropboxapi.com/2/sharing/get_folder_metadata" into someURL
   --
   put merge ("{'shared_folder_id': '[[folderID]]','actions': []}") into someJSON
   replace "'" with quote in someJSON
   /*
   put folderID into paramArray ["shared_folder_id"]
   -- put folderActions into paramArray ["actions"]
   put json_FromArray (paramArray) into someJSON
   */
   
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end dropbox_FetchFolderMetadata   

function dropbox_FetchMetadata somePath
   -- put "/Screenshots/test.png" into somePath
   
   put "https://api.dropboxapi.com/2/files/get_metadata" into someURL
   --   
   put somePath into paramArray ["path"]
   put "false" into paramArray ["include_media_info"]
   put "false" into paramArray ["include_deleted"]
   put "false" into paramArray ["include_has_explicit_shared_members"]
   put json_FromArray (paramArray) into someJSON
   --
   put dropbox_ReturnPost (someJSON, someURL) into someJSON
   put json_ToArray (someJSON) into returnedArray
   return returnedArray
end dropbox_FetchMetadata


--> Deps
-
