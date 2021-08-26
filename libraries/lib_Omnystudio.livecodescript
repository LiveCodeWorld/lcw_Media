script "lib_Omnystudio"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_Omnystudio
type: library
version: 0.1

/
/

constant RestBase = "https://api.omnystudio.com"
constant ApiVersion = "v0"


--> Working on
-
function soundgarden_ListPlaylistClips playListName
   put soundgarden_FestchPlaylistArray (playListName) into playListArray
   put playListArray ["Id"] into playListID
   
end soundgarden_ListPlaylistClips

command display_ProgramClips programName, pProgramData
   put omnystudio_FetchAndFindProgramID (programName, pProgramData) into programID
   --
   put omnystudio_FetchProgramClipData (programID) into clipData
   --
   repeat for each key clipNum in clipData
      put clipData [clipNum]["Title"] into clipTitle
      --
      repeat for each item someKey in "AudioUrl,Description,DescriptionHTML,Id,ImageUrlTags,VideoUrl,Visibility,PublishState"
         put clipData [clipNum][someKey] into clipNameArray [clipTitle][someKey]
      end repeat
   end repeat
   --
   display_Data clipNameArray, "Clips", pStackLabel
   return clipTitles
end display_ProgramClips


--> SoundGarden
-
function soundgarden_FetchPlaylistArray playListName
   put soundgarden_FetchPlaylistData() into playlistData
   --
   repeat for each key pNum in playlistData
      put playlistData [pNum] into playListArray
      put playListArray ["Title"] into testTitle
      if testTitle = playListName then
         return playListArray
      end if
   end repeat
   return empty
end soundgarden_FetchPlaylistArray

function soundgarden_FetchPlaylistData
   put omnystudio_FetchProgramData() into programData
   put omnystudio_FetchAndFindProgramID ("Sound Garden", programData) into programID
   put omnystudio_FetchPlaylistData (programID) into playlistData
   return playlistData
end soundgarden_FetchPlaylistData

function soundgarden_ListPlaylists
   put omnystudio_FetchProgramData() into programData
   put omnystudio_FetchAndFindProgramID ("Sound Garden", programData) into programID
   put omnystudio_ListPlaylistTitles (programID, programData) into playlistTitles
   return playlistTitles
end soundgarden_ListPlaylists


--> Omnystudio
-
function omnystudio_FetchAndFindProgramID programName, pProgramData
   if pProgramData is empty then put omnystudio_FetchProgramData() into pProgramData
   --
   repeat for each key pNum in pProgramData
      put pProgramData [pNum]["Name"] into testName
      if programName = programName then
         put pProgramData [pNum]["id"] into programID
         return programID
      end if
   end repeat
   return empty
end omnystudio_FetchAndFindProgramID

function omnystudio_ListClipTitles programID
   put omnystudio_FetchProgramClipData (programID) into clipData
   --
   repeat for each key clipNum in clipData
      put clipData [clipNum]["Title"] into clipTitle
      put clipTitle & CR after clipTitles
   end repeat
   delete char -1 of clipTitles
   return clipTitles
end omnystudio_ListClipTitles

function omnystudio_FetchProgramClipData programID
   -- https://api.omnystudio.com/v0/programs/8eafa0cb-7540-4eeb-bf72-abee00e1b8d0/clips
   put "programs/" & programID & "/clips" into apiPath
   put _RestFetchArray (apiPath) into replyArray
   put replyArray ["clips"] into clipData
   return clipData
end omnystudio_FetchProgramClipData

function omnystudio_FetchPlaylistArray playlistID, pProgramData
   -- https://api.omnystudio.com/v0/playlists/3abbaff8-6820-4f77-84e8-abee00e2bb45
   if pProgramData is empty then put omnystudio_FetchProgramData() into pProgramData
   --
   put "playlists/" & playlistID into apiPath
   put _RestFetchArray (apiPath) into playlistData
   return playlistData
end omnystudio_FetchPlaylistArray

function omnystudio_ListPlaylistTitles programID, pProgramData
   put omnystudio_FetchPlaylistData (programID) into playlistData
   --
   repeat for each key pNum in playlistData
      put playlistData[pNum]["Title"] into playlistTitle
      put playlistTitle & CR after playlistTitles
   end repeat
   delete char -1 of playlistTitles
   return playlistTitles
end omnystudio_ListPlaylistTitles

function omnystudio_ListPlaylistIDs programID, pProgramData
   put omnystudio_FetchPlaylistData (programID) into playlistData
   --
   repeat for each key pNum in playlistData
      put playlistData[pNum]["id"] into playlistID
      put playlistID & CR after playlistIDs
   end repeat
   delete char -1 of playlistIDs
   return playlistIDs
end omnystudio_ListPlaylistIDs

function omnystudio_FetchPlaylistData programID
   -- https://api.omnystudio.com/v0/programs/8eafa0cb-7540-4eeb-bf72-abee00e1b8d0/playlists
   if pProgramData is empty then put omnystudio_FetchProgramData() into pProgramData
   --
   put "programs/" & programID & "/playlists" into apiPath
   put _RestFetchArray (apiPath) into replyArray
   put replyArray ["Playlists"] into playlistData
   return playlistData
end omnystudio_FetchPlaylistData

function omnystudio_ListProgramNames pProgramData
   if pProgramData is empty then put omnystudio_FetchProgramData() into pProgramData
   --
   repeat for each key pNum in pProgramData
      put pProgramData [pNum]["Name"] into pName
      put pName & CR after pNames
   end repeat
   delete char -1 of pNames
   return pNames
end omnystudio_ListProgramNames

function omnystudio_ListProgramIds pProgramData
   if pProgramData is empty then put omnystudio_FetchProgramData() into pProgramData
   --
   repeat for each key pNum in pProgramData
      put pProgramData [pNum]["id"] into programID
      put programID & CR after programIDs
   end repeat
   delete char -1 of programIDs
   return programIDs
end omnystudio_ListProgramIds

function omnystudio_FetchProgramData
   put _RestFetchArray ("programs") into replyArray
   put replyArray ["programs"] into pProgramData
   return pProgramData
end omnystudio_FetchProgramData


--> Omnistudio | REST | Auth
-
function omnystudio_GetAuthToken
   put secret_Get ("Omnystudio_AuthToken") into authToken
   return authToken
end omnystudio_GetAuthToken

command omnystudio_SetAuthToken authToken
   secret_Set "Omnystudio_AuthToken", authToken
end omnystudio_SetAuthToken


--> Deps
-
function secret_Get secretName
   -- for server use only
   if the environment is not "server" then pass "secret_Get"
   --
   put rigFetchConfigItem (secretName) into someSecret
   return someSecret
end secret_Get

function _RestFetchArray apiPath
   put _RestFetch (apiPath) into replyJSON
   put json_ToArray (replyJSON) into replyArray
   return replyArray
end _RestFetchArray

function _RestFetch apiPath
   put RestBase & slash & ApiVersion & slash & apiPath into restURL
   _RestSetJsonHeaders
   put url restURL into replyJSON
   return replyJSON
end _RestFetch

command _RestSetJsonHeaders
   put omnystudio_GetAuthToken() into authToken
   --
   put "Content-type: application/json" into someHeader
   put CR & "Accept: application/json" after someHeader
   put CR & "Accept-Charset: utf-8" after someHeader
   --
   put CR & "Authorization: OmnyToken" && authToken after someHeader
   --
   set the httpHeaders to someHeader
   --
   return someHeader
end _RestSetJsonHeaders


--> Deps
-
