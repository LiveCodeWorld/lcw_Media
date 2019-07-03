script "lib_DropBox"
--> MetaData
-
license: GPLv3
name: lib_DropBox
type: library
version: 0.3


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


--> Dropbox | Paper
-
command paper_LaunchApiHelp
   launch url "https://www.dropbox.com/developers/documentation/http/documentation#paper-docs-list"
end paper_LaunchApiHelp

function paper_ConstructDocUrl docID
   put merge ("https://paper.dropbox.com/doc/[[docID]]") into someURL
   return someURL
end paper_ConstructDocUrl

command paper_CleanMarkdown @someMarkdown
   /*
   # Writing with markdown
   It is not clear to me yet how easy it will be to import [[Dropbox Paper]] document into [[Fedwiki]].
   
   Let’s see what an image looks like as well:
   
   ![](https://d2mxuefqeaa7sj.cloudfront.net/s_4908364456AD72E298549EA4FB2A8ACF9037EB24CFBA90C0BBDB3E125DDD030A_1546019297504_liquid.png)
   */
   -- put script_GetCommentAboveMe() into someMarkdown
   
   -- format external image links
   put ".*\!\[\]" into someReg
   put "(.+)" after someReg
   put "\)" after someReg
   -- put ".*\!\[\]\((imageURL)\)" into someReg
   if matchChunk (someMarkdown, someReg, startChunk, endChunk) is true then
      put startChunk - 3 into startNum
      put endChunk + 2 into endNum
      put char startNum to endNum of someMarkdown into testBit
      delete char startNum to endNum of someMarkdown
   end if
end paper_CleanMarkdown

command paper_CreateDocument newMarkdown
   -- Must provide HTTP header "Dropbox-API-Arg" or URL parameter "arg".
   /*
   curl -X POST https://api.dropboxapi.com/2/paper/docs/create \
   --header "Authorization: Bearer " \
   --header "Dropbox-API-Arg: {\"import_format\": \"markdown\"}" \
   --header "Content-Type: application/octet-stream" \
   --data-binary @local_file.txt
   
   {
   "import_format": "markdown"
   }
   {
   "import_format": "html",
   "parent_folder_id": "e.gGYT6HSafpMej9bUv306GarglI7GGeAM3yvfZvXHO9u4mV"
   }
   */
   
   put "https://api.dropboxapi.com/2/paper/docs/create" into someURL
   --
   put dropbox_GetAuthToken() into dropBoxAuthToken
   put "Authorization: Bearer" && dropBoxAuthToken into someHeaders
   put CR & "Content-Type: application/octet-stream" after someHeaders
   put CR & "Dropbox-API-Arg: {" & kwote("import_format") & ":" && kwote ("markdown") & "}" after someHeaders
   --
   set the httpheaders to someHeaders
   post newMarkdown to url someURL
   put it into resultJSON
   -- {"doc_id": "oomb40FGakBt6mOGabYO7", "revision": 2, "title": "{\"import_format\":\"markdown\"}"}
   return resultJSON
end paper_CreateDocument

command paper_UpdateDocument newMarkdown, docID, pRevisionID, pUpdatePolicy, pExportFormat
   -- pMode = "add"
   /*
   curl -X POST https://api.dropboxapi.com/2/paper/docs/update \
   --header "Authorization: Bearer " \
   --header "Dropbox-API-Arg: {\"doc_id\": \"uaSvRuxvnkFa12PTkBv5q\",\"doc_update_policy\": \"overwrite_all\",\"revision\": 12345,\"import_format\": \"html\"}" \
   --header "Content-Type: application/octet-stream" \
   --data-binary @local_file.txt
   
   PARAMETERS
   Example: Overwrite the doc content with provided content.
   {
   "doc_id": "uaSvRuxvnkFa12PTkBv5q",
   "doc_update_policy": "overwrite_all",
   "revision": 12345,
   "import_format": "html"
   }
   
   PaperDocUpdatePolicy (open union)
   The value will be one of the following datatypes. New values may be introduced as our API evolves.
   append Void The content will be appended to the doc.
   prepend Void The content will be prepended to the doc.
   Note: the doc title will not be affected.
   overwrite_all Void The document will be overwitten at the head with the provided content.
   */
   
   if pUpdatePolicy is empty then put "append" into pUpdatePolicy -- append, prepend, overwrite_all
   if pExportFormat is empty then put "markdown" into pExportFormat -- html, markdown or plain_text
   if pRevisionID is empty then
      put paper_FetchrevisionID (docID) into pRevisionID
   end if
   
   put docID into paramArray ["doc_id"]
   put pUpdatePolicy into paramArray ["doc_update_policy"]
   put pRevisionID into paramArray ["revision"]
   put pExportFormat into paramArray ["import_format"]
   put json_FromArray (paramArray) into paramJSON
   
   --
   put dropbox_GetAuthToken() into dropBoxAuthToken
   put "Authorization: Bearer" && dropBoxAuthToken into someHeaders
   put CR & "Content-Type: application/octet-stream" after someHeaders
   put CR & "Dropbox-API-Arg:" && paramJSON after someHeaders
   --
   set the httpheaders to someHeaders
   post newMarkdown to url "https://api.dropboxapi.com/2/paper/docs/update"
   put it into resultJSON
   -- {"doc_id": "whHrkCBmxXdRm80wqGRzT", "revision": 4, "title": "Test Title"}
   return resultJSON
end paper_UpdateDocument

function paper_FetchrevisionID docID
   -- does not work on the server
   put paper_FetchDoc (docID) into docMarkdown
   put paper_GetApiResultJSON() into apiResultJSON
   put json_ToArray (apiResultJSON) into apiResultArray
   put apiResultArray ["revision"] into revisionID
   return revisionID
end paper_FetchrevisionID

function paper_FetchDocumentInfo docID
   put "https://api.dropboxapi.com/2/paper/docs/sharing_policy/get" into restURL
   --
   put docID into paramArray ["doc_id"]
   put json_FromArray (paramArray) into paramJSON
   --
   get dropbox_ReturnPost (paramJSON, restURL)
   return it
end paper_FetchDocumentInfo

function paper_FetchFolderList
   /*
   -- https://www.dropbox.com/developers/documentation/http/documentation#paper-docs-list
   
   curl -X POST https://api.dropboxapi.com/2/paper/docs/list \
   --header "Authorization: Bearer " \
   --header "Content-Type: application/json" \
   --data "{\"filter_by\": \"docs_created\",\"sort_by\": \"modified\",\"sort_order\": \"descending\",\"limit\": 100}"
   */
   
   put "https://api.dropboxapi.com/2/paper/docs/list" into someURL
   --
   put "docs_created" into paramArray ["filter_by"]
   put "modified" into paramArray ["sort_by"]
   put "descending" into paramArray ["sort_order"]
   put 100 into paramArray ["limit"]
   --
   put json_FromArray (paramArray) into someJSON
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end paper_FetchFolderList

function paper_FetchSharingPolicy docID
   /*   
   curl -X POST https://api.dropboxapi.com/2/paper/docs/sharing_policy/get \
   --header "Authorization: Bearer " \
   --header "Content-Type: application/json" \
   --data "{\"doc_id\": \"uaSvRuxvnkFa12PTkBv5q\"}"
   
   {
   "doc_id": "uaSvRuxvnkFa12PTkBv5q"
   }
   */
   
   put "https://api.dropboxapi.com/2/paper/docs/sharing_policy/get" into someURL
   --
   put docID into paramArray ["doc_id"]
   put json_FromArray (paramArray) into someJSON
   --
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end paper_FetchSharingPolicy

function paper_FetchDoc docID, pExportFormat
   /*   
   curl -X POST https://api.dropboxapi.com/2/paper/docs/download \
   --header "Authorization: Bearer " \
   --header "Dropbox-API-Arg: {\"doc_id\": \"uaSvRuxvnkFa12PTkBv5q\",\"export_format\": \"markdown\"}" 
   
   {
   "doc_id": "uaSvRuxvnkFa12PTkBv5q",
   "export_format": "markdown" or "html"
   }
   */
   
   if pExportFormat is empty then put "markdown" into pExportFormat
   put docID into paramArray ["doc_id"]
   put pExportFormat into paramArray ["export_format"]
   --
   put "paper/docs/download" into apiPath
   put dropbox_RestGet (apiPath, paramArray) into docMarkdown
   return docMarkdown
end paper_FetchDoc

function paper_GetApiResultJSON
   put http_GetReceivedHeaderArray() into headerArray
   put headerArray ["Dropbox-Api-Result"] into apiResultJSON
   return apiResultJSON
end paper_GetApiResultJSON


--> Dropbox | Auth
-
function dropbox_RestGet apiPath, paramArray
   put "https://api.dropboxapi.com/2/" & apiPath into restURL
   put json_FromArray (paramArray) into paramJSON
   --
   put dropbox_GetAuthToken() into dropBoxAuthToken
   put "Authorization: Bearer" && dropBoxAuthToken & CR & "Content-Type: text/plain" into newHeaders
   set the httpheaders to newHeaders
   --
   get url (restURL & "?arg=" & paramJSON)
   return it
end dropbox_RestGet

function dropbox_GetAuthToken
   put secret_Get ("dropBoxAuthToken", "dropbox") into oAuthToken
   return oAuthToken
end dropbox_GetAuthToken

command dropbox_SetAuthToken oAuthToken
   secret_Set "dropBoxAuthToken", oAuthToken, "dropbox"
   put the result into modelDataFile
   return modelDataFile
end dropbox_SetAuthToken


--> DropBox
-
function dropbox_GetAccount
   put dropbox_GetAuthToken() into dropBoxAuthToken
   dropboxGetCurrentAccount dropBoxAuthToken
   put it into jsonResult
   return jsonResult
end dropbox_GetAccount

function dropbox_ListFolders
   put dropbox_GetAuthToken() into dropBoxAuthToken
   dropboxListFolders dropBoxAuthToken
   put it into jsonResult
   return jsonResult
   
   put "https://api.dropboxapi.com/2/sharing/list_folders" into someURL
   -- put "https://api.dropboxapi.com/2/sharing/list_mountable_folders" into someURL
   --
   put 1000 into paramArray ["limit"]
   -- put "" into paramArray ["actions"]
   put json_FromArray (paramArray) into someJSON
   
   get dropbox_ReturnPost (someJSON, someURL)
   return it
end dropbox_ListFolders

function dropbox_GetFileInfo fileID
   put "https://api.dropboxapi.com/2/sharing/get_file_metadata" into someURL
   --
   put merge ("{'file': 'id:[[fileID]]','actions': []}") into paramJSON
   replace "'" with quote in paramJSON
   /*
   put "id:" & fileID into paramArray ["file"]
   put "" into paramArray ["actions"]
   put json_FromArray (paramArray) into paramJSON
   */
   --
   put dropbox_ReturnPost (paramJSON, someURL) into someJSON
   put json_ToArray (someJSON) into returnedArray
   return returnedArray
end dropbox_GetFileInfo

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
   /*
   Error in call to API function "files/get_metadata": request body: path: 'Updated Title' 
   did not match pattern '(/(.|[\r\n])*|id:.*)|(rev:[0-9a-f]{9,})|(ns:[0-9]+(/.*)?)'
         
   -- put "/Screenshots/test.png" into somePath
   {
   "path": "id:a4ayc_80_OEAAAAAAAAAYa",
   "include_media_info": false,
   "include_deleted": false,
   "include_has_explicit_shared_members": false
   }
   */
   
   put "https://api.dropboxapi.com/2/files/get_metadata" into someURL
   --   
   put somePath into paramArray ["path"]
   put "false" into paramArray ["include_media_info"]
   put "false" into paramArray ["include_deleted"]
   put "false" into paramArray ["include_has_explicit_shared_members"]
   put json_FromArray (paramArray) into paramJSON
   --
   put dropbox_ReturnPost (paramJSON, someURL) into jsonResult
   -- {"error_summary": "path/not_found/.", "error": {".tag": "path", "path": {".tag": "not_found"}}}
   put json_ToArray (jsonResult) into returnedArray
   return returnedArray
end dropbox_FetchMetadata

function dropbox_ListFolder somePath, pRecurseFolders, pIncludeMediaInfo
   -- '(/(.|[\r\n])*)?|id:.*|(ns:[0-9]+(/.*)?)'
   local pIncludeDeleted, pIncludeSharedMembers
   put dropbox_FetchListFolderJson (somePath, pRecurseFolders, pIncludeMediaInfo, pIncludeDeleted, pIncludeSharedMembers) into someJSON
   /*
   put dropbox_GetAuthToken() into dropBoxAuthToken
   dropboxListFolder dropBoxAuthToken, somePath, pRecurseFolders, pIncludeMediaInfo
   put it into someJSON
   */
   --
   put json_ToArray (someJSON) into fetchArray
   put fetchArray ["cursor"] into lastCursor
   put fetchArray ["has_more"] into someBoolean
   put fetchArray ["entries"] into entryArray
   
   put dropbox_FetchListFolderContinueJson (lastCursor) into continueJSON
   return continueJSON
end dropbox_ListFolder

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
