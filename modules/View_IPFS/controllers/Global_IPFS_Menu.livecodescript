script "Global | IPFS | Menu"
--> MetaData
-
license: GPLv3
name: Global | IPFS | Menu
type: controller
version: 0.2


--> Menu | Props
-
getprop menu_Target [tObject]
   put the long id of tObject into tObject
   switch word 1 of tObject
      case "button"
      case "card"
         -- display_DebugHistory
         -- exit to top
         break
      case "widget"
         break
   end switch
   
   put the browser_View of tObject into bView
   if exists (bView) then return bView
   
   put display_GetObject(tObject) into dView
   put the browser_View of dView into bView
   if exists (bView) then return bView
   
   return _IpfsView()
end menu_Target

private function _IpfsView
   if exists (group 1 of stack "View|IPFS") is false then return empty
   put the long id of group 1 of stack "View|IPFS" into vObject
   return vObject
end _IpfsView

getprop menu_CheckTarget [ipfsView]
   return exists (group 1 of stack "View|IPFS")
end menu_CheckTarget


--> Global | IPFS | Menu | Props
-
getprop display_Param [ipfsView]
   put the display_Type of ipfsView into whichView
   return whichView
end display_Param

getprop display_Params [ipfsView]
   put the view_Types of ipfsView into whichViews
   return whichViews
end display_Params

getprop displayIpfsUrl_Params
   return menu_GetCaseParams (the params)
end displayIpfsUrl_Params

getprop displayIpfsVideo_Params
   return menu_GetCaseParams (the params)
end displayIpfsVideo_Params

getprop enableTrack_Param [ipfsView]
   put the long id of player 1 of ipfsView into playerObject
   put the enabledtracks of playerObject into playerTrack
   return playerTrack
end enableTrack_Param

getprop enableTrack_Params [ipfsView]
   put the long id of player 1 of ipfsView into playerObject
   put the tracks of playerObject into playerTracks
   /*
   1,vide,0,226947420
   2,soun,0,226942976
   3,soun,0,226942976
   */
   
   repeat for each line trackLine in playerTracks
      put item 1 of trackLine into trackNum
      put item 4 of trackLine into trackID
      put trackNum & comma after trackNums
      put trackID & comma after trackIDs
   end repeat
   delete char -1 of trackNums
   return trackNums
end enableTrack_Params

getprop player_Tracks [ipfsView]
   put the tracks of player 1 of ipfsView into playerTracks
   /*
   1,vide,0,226947420
   2,soun,0,226942976
   3,soun,0,226942976
   */
   
   repeat for each line trackLine in playerTracks
      put item 4 of trackLine into trackID
      put trackID & comma after trackIDs
   end repeat
   delete char -1 of trackIDs
   return trackIDs
end player_Tracks

getprop disabled_DisplayIpfsCatPicture
   get the openprocesses
   if "ipfs daemon" is among the lines of it then
      return false
   else
      return true
   end if
end disabled_DisplayIpfsCatPicture

getprop disabled_DisplayIpfsVideoPlayer
   get the openprocesses
   if "ipfs daemon" is among the lines of it then
      return false
   else
      return true
   end if
end disabled_DisplayIpfsVideoPlayer

getprop disabled_StartIpfs
   get the openprocesses
   if "ipfs daemon" is among the lines of it then
      return true
   else
      return false
   end if
end disabled_StartIpfs

getprop disabled_StopIpfs
   get the openprocesses
   if "ipfs daemon" is among the lines of it then
      return false
   else
      return true
   end if
end disabled_StopIpfs


--> Global | IPFS | Menu
-
on menu_StartIpfs ipfsView
   set the cursor to watch
   open process "ipfs daemon" for update
   -- IPFS server listening on 8080
   read from process "ipfs daemon" until "Daemon is ready"
   put it into ipfsInfoToParse
   
   -- launch url "http://localhost:5001/webui"
   set the browser_URL of ipfsView to "http://localhost:5001/webui"
   set the display_Type of ipfsView to "browser"
end menu_StartIpfs

on menu_StopIpfs
   if the platform = "MacOS" then
      kill process "ipfs daemon"
   else
      close process "ipfs daemon"
   end if
   -- put the openprocesses
end menu_StopIpfs

on _
end _

on menu_DisplayIpfsUrl ipfsView, urlName
   switch urlName
      case "Bogota Clip"
         put "https://ipfs.io/ipfs/QmQKT83zmDKDZX45XPzAX5i5XwvyHexhCFazq81LQy5wVY?filename=Bogota_Change.mp4#t=04:21,04:50" into ipfsURL
         break
      case "Bogota Change"
         put "QmQKT83zmDKDZX45XPzAX5i5XwvyHexhCFazq81LQy5wVY" into cid
         put "https://ipfs.io/ipfs/QmQKT83zmDKDZX45XPzAX5i5XwvyHexhCFazq81LQy5wVY?filename=Bogota_Change.mp4" into ipfsURL
         break
      case "Cat"
         put "http://127.0.0.1:8080/ipfs/QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ/cat.jpg" into ipfsURL
         break
      case "Quick Ipfs.io"
         put "https://ipfs.io/ipfs/QmUoW7x29q2rkMWK8Be3bpCfG9AdhPiZbvsUZJUBWT6eRS?filename=quick.mp4" into ipfsURL
         break
      case "Quick"
         put "http://127.0.0.1:8080/ipfs/QmUoW7x29q2rkMWK8Be3bpCfG9AdhPiZbvsUZJUBWT6eRS?filename=quick.mp4" into ipfsURL
         break
      case "Rif Cafe"
         put "https://ipfs.io/ipfs/QmeJYxFe2gETNaVkxVzveiufVCjqzFC8Y5yyJD2i5S9SDM?filename=Rif%20Cafe.m4v" into ipfsURL
         break
      case "Hitchiker"
         put "QmWKGLKMFF3nM2VkxU9gCvt8UHfjXMTwBWZtgLH4H3y6YX" into cid
         put merge ("http://127.0.0.1:8080/ipfs/[[cid]]") into ipfsURL
         break
      case "Added"
         put "QmRTj1RFZc52SYFYwNhEGo6kjEm2Cb9P2rbhCuBPTHb5J8" into cid
         put merge ("http://127.0.0.1:8080/ipfs/[[cid]]/cat.jpg") into ipfsURL
         break
      case "-"
         break
      case "Webui"
         put "http://localhost:5001/webui" into ipfsURL
         break
   end switch
   --
   set the browser_URL of ipfsView to ipfsURL
   set the display_Type of ipfsView to "browser"
end menu_DisplayIpfsUrl

on menu_DisplayIpfsVideo ipfsView, videoName
   switch videoName
      case "Quick"
         put "https://ipfs.io/ipfs/QmUoW7x29q2rkMWK8Be3bpCfG9AdhPiZbvsUZJUBWT6eRS?filename=quick.mp4" into ipfsURL
         break
      case "Rif Cafe"
         put "https://ipfs.io/ipfs/QmeJYxFe2gETNaVkxVzveiufVCjqzFC8Y5yyJD2i5S9SDM?filename=Rif%20Cafe.m4v" into ipfsURL
         break
   end switch
   --
   set the player_FileName of ipfsView to ipfsURL
   set the display_Type of ipfsView to "player"
end menu_DisplayIpfsVideo

on menu_DisplayIpfsCatPicture ipfsView
   -- put view_GetTemplateObject ("View|IPFS") into ipfsView
   put "http://127.0.0.1:8080/ipfs/QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ/cat.jpg" into ipfsURL
   
   set the browser_URL of ipfsView to ipfsURL
   --
   if exists (image 1 of ipfsView) then
      set the image_FileName of ipfsView to empty
      set the text of image 1 of ipfsView to url ipfsURL
      --set the image_FileName of ipfsView to ipfsURL
      set the display_Type of ipfsView to "image"
      --
      -- launch url ipfsURL
   end if
end menu_DisplayIpfsCatPicture

on _
end _

on menu_Display ipfsView, whichView
   set the display_Type of ipfsView to whichView
end menu_Display

on menu_Documentation
   launch url "https://ipfs.io/ipfs/QmYxvrFbqasNV8jgT7TCzSnoG2Aa19tn7fFx1p59RTJ3ot/docs/install/"
end menu_Documentation

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_InstallIpfs
   -- https://dist.ipfs.io/#go-ipfs
   -- tar xvfz go-ipfs.tar.gz
   -- mv go-ipfs/ipfs /usr/local/bin/ipfs
   put shell ("brew install ipfs")
end menu_InstallIpfs

on _
end _

on menu_DisplayIpfsStackArray
   put ipfs_FetchArray() into ipfsArray
   display_Data ipfsArray, "ipfs_FetchArray()", "IPFS"
end menu_DisplayIpfsStackArray

on _
end _

on menu_EditBehavior ipfsView
   put the behavior of ipfsView into bObject
   edit the script of bObject
end menu_EditBehavior

on menu_EditIpfsLibrary
   edit the script of stack "lib_IPFS"
end menu_EditIpfsLibrary

on _
end _

on menu_DisplayIpfsVideoPlayer
   ipfs_Go "IPFS video Player"
end menu_DisplayIpfsVideoPlayer

on menu_TestMultiHash
   answer file "Select a file..."
   put it into someFile
   
   put the ticks into startTicks
   ipfs_ShellAddFile someFile, true
   put the result into multiHash
   
   put the ticks - startTicks into elapsedTime
   put elapsedTime/60 & CR & multiHash
end menu_TestMultiHash

on menu_TestAddFile
   answer file "Select a file..."
   put it into someFile
   
   put the ticks into startTicks
   ipfs_ShellAddFile someFile
   put the result into multiHash
   
   put the ticks - startTicks into elapsedTime
   put elapsedTime/60 & CR & multiHash
end menu_TestAddFile

on _
end _

on menu_EnableTrack ipfsView, trackNum
   put the long id of player 1 of ipfsView into playerObject
   put the enabledtracks of playerObject into trackNumsEnabled
   put lineoffset (trackNum, trackNumsEnabled) into lineNum
   put trackNumsEnabled into newTrackNums
   if lineNum = 0 then
      put CR & trackNum before newTrackNums
   else
      delete line lineNum of newTrackNums
   end if
   sort numeric lines of newTrackNums
   put word 1 to -1 of newTrackNums into newTrackNums
   set the enabledTracks of playerObject to newTrackNums
end menu_EnableTrack

on _
end _

on menu_SetMovie ipfsView
   answer file "Select a movie..."
   put it into someFile
   if someFile is empty then exit to top
   
   put the long id of player 1 of ipfsView into playerObject
   set the filename of playerObject to someFile
end menu_SetMovie

on menu_IpfsViewBehavior
   put view_GetTemplateObject ("View|IPFS") into ipfsView
   edit the script of the behavior of ipfsView
end menu_IpfsViewBehavior

on menu_TestMultihash
   put url "http://127.0.0.1:8080/ipfs/QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ/cat.jpg"
end menu_TestMultihash

on menu_TestLoadData
   ipfs_SetMultiHash "IPFS video Player", "QmdbejVfgCQSEwhutDovDAv2gfKhGrXZTdrmBp179Dn3kK"
end menu_TestLoadData

command menu_TestPost
   ipfs_AddFile
   put the result into someArray
   -- display_Array someArray
   put someArray ["Hash"] into someHash
   put someArray ["Name"] into shortFileName
   
   set the itemdelimiter to "."
   put item -1 of shortFileName into fType
   set the itemdelimiter to comma
   
   switch
      case fType is among the items of "livecode,rev"
         put ipfs_Cat (someHash) into stackData
         -- could save it to a file
         go to stack stackData
         put the result
         break
      case fType is among the items of "jpg,png,gif,html"
         ipfs_LaunchBrowserUrl someHash
      default
         put ipfs_Cat (someHash) -- into someData
   end switch
end menu_TestPost
