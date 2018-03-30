script "Global_IPFS_Menu"
--> MetaData
-
license: GPLv3
name: Global_IPFS_Menu
type: controller
version: 0.2


--> Global | IPFS | Menu
-
on menu_Display ipfsView, whichView
   set the display_Type of ipfsView to whichView
end menu_Display

on menu_DisplayIpfsStackArray
   put ipfs_FetchArray() into ipfsArray
   display_Array ipfsArray
end menu_DisplayIpfsStackArray

on _
end _

on menu_SetMovie ipfsView
   answer file "Select a movie..."
   put it into someFile
   if someFile is empty then exit to top
   
   put the long id of player 1 of ipfsView into playerObject
   set the filename of playerObject to someFile
end menu_SetMovie

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

on menu_DisplayIpfsVideoPlayer
   ipfs_Go "IPFS video Player"
end menu_DisplayIpfsVideoPlayer

on menu_DisplayIpfsCatPicture
   put "http://127.0.0.1:8080/ipfs/QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ/cat.jpg" into ipfsURL
   
   put view_GetTemplateObject ("View|IPFS") into ipfsView
   set the browser_URL of ipfsView to ipfsURL
   set the image_FileName of ipfsView to ipfsURL
   set the display_Type of ipfsView to "image"
   
   launch url ipfsURL
end menu_DisplayIpfsCatPicture

on _
end _

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

on menu_StartIpfs
   set the cursor to watch
   open process "ipfs daemon" for update
   -- IPFS server listening on 8080
   read from process "ipfs daemon" until "Daemon is ready"
   put it into ipfsInfoToParse
   
   launch url "http://localhost:5001/webui"
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

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Global | IPFS | Menu | Props
-
getprop which_View [ipfsView]
   put the display_Type of ipfsView into whichView
   return whichView
end which_View

getprop which_Views [ipfsView]
   put the view_Types of ipfsView into whichViews
   return whichViews
end which_Views

getprop track_Num [ipfsView]
   put the long id of player 1 of ipfsView into playerObject
   put the enabledtracks of playerObject into playerTrack
   return playerTrack
end track_Num

getprop track_Nums [ipfsView]
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
end track_Nums

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


--> Global | IPFS | Menu | Disabled
-
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


--> Dev | Menu
-
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
