script "Global | Dropbox | Menu"
--> MetaData
-
license: GPLv3
name: Global | Dropbox | Menu
type: controller
version: 0.1


--> Global | Dropbox | Menu
-
on menu_ListFolder mTarget
   -- put dropbox_ListFolders() into folderJSON
   put dropbox_GetAuthToken() into aToken
   dropboxListFolder aToken, "/audio/podcasts", true, true
   put it into folderJSON
   
   put json_ToArray (folderJSON) into responseArray
   display_Array responseArray
   /*
   --
   put responseArray ["entries"] into entryArray
   repeat for each key entryNum in entryArray
      put entryArray [entryNum] into itemArray
      --
      put itemArray ["name"] into folderName
      put itemArray ["path_lower"] into folderPath
      put itemArray ["shared_folder_id"] into sharedFolderID
      --
      delete char 1 of folderPath
      split folderPath by slash
      put folderName into pathArray [folderPath]["name"]
      put sharedFolderID into pathArray [folderPath]["shared_folder_id"]
   end repeat
   --
   display_Array pathArray
   */
end menu_ListFolder

on menu_DownloadFile
   put dropbox_GetAuthToken() into aToken
   put "/wiki/beingarthur.org/pages/about-arthur" into pPath
   put "/audio/podcasts/radiolab_space.mp3" into pPath
   --
   dropboxDownload aToken, pPath
   -- dropboxGetSharedLinkFile pAccessToken, pUrl, [pPath, pLinkPassword]
   put it into binaryData
end menu_DownloadFile

on menu_AccountDetails
   put dropbox_GetAuthToken() into aToken
   dropboxGetCurrentAccount aToken
   put it into someJson
   display_JSON someJson
end menu_AccountDetails


--> Global | Dropbox | Menu | Props
-

--> Global | Dropbox | Menu | Disabled
-
