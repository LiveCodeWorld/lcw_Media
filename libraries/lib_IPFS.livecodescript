﻿script "lib_IPFS"
--> MetaData
-
license: GPLv3
name: lib_IPFS
type: library
version: 0.2


/* Notes
This is a library for interfacing with the IPFS.

The aim here is to enable true decentralised, serverless Livecode, which we can use for rapid development of Dapps.
*/


--> IPFS | Model
-
function ipfs_GetMultiHash stackName
   put ipfs_FetchArray() into ipfsArray
   put ipfsArray [stackName] into ipfsMultiHash
   return ipfsMultiHash
end ipfs_GetMultiHash

command ipfs_SetMultiHash stackName, ipfsMultiHash
   put ipfs_FetchArray() into ipfsArray
   put ipfsMultiHash into ipfsArray [stackName]
   ipfs_SaveArray ipfsArray
end ipfs_SetMultiHash

function ipfs_FetchArray
   put empty into pPrefKey
   put pref_FetchValue ("ipfsArray", pPrefKey) into ipfsArray
   -- put pref_GetValue ("ipfsArray") into ipfsArray   
   return ipfsArray
end ipfs_FetchArray

command ipfs_SaveArray ipfsArray
   put empty into pPrefKey
   pref_SaveValue "ipfsArray", ipfsArray, pPrefKey
end ipfs_SaveArray


--> IPFS | Stacks
-
command ipfs_SaveStack stackName
   save stack stackName
   put the filename of stack stackName into someFile
   --
   ipfs_AddFile someFile
   -- ipfs_ShellAddFile someFile
   put the result into resultArray
   --
   put resultArray ["Hash"] into ipfsMultiHash
   ipfs_SetMultiHash stackName, ipfsMultiHash
   return ipfsMultiHash
end ipfs_SaveStack
 
command ipfs_Go stackName
   if exists (stack stackName) then
      save stack stackName
      delete stack stackName
   end if
   
   put ipfs_GetMultiHash (stackName) into ipfsMultiHash
   if ipfsMultiHash is empty then
      return empty
   end if
   
   put "http://localhost:8080/ipfs/" & ipfsMultiHash into localURL
   go to stack url localURL
   return ipfsMultiHash
end ipfs_Go


--> IPFS | Url
-
command ipfs_LaunchBrowserUrl someHash, pPath, pPort
   put ipfs_ConstructBrowserUrl (someHash, pPath, pPort) into someUrl
   launch url someUrl
   return the result
end ipfs_LaunchBrowserUrl

function ipfs_ConstructBrowserUrl someHash, pPath, pPort
   -- http://127.0.0.1:8080/ipfs/QmQy1iYDG86WMNnwFZXxWUBgtG4dFtHtyNodz6jaqSNKNj
   if pPort is empty then put 8080 into pPort
   put "http://localhost:" & pPort & "/ipfs/" & someHash into someUrl
   if pPath is not empty then put "/" & pPath after someUrl
   return someUrl
end ipfs_ConstructBrowserUrl

function ipfs_ConstructUrl ipfsPath, pArgs, pFlags, pPort, pDomain
   /*
   http://127.0.0.1:5001/api/v0/swarm/peers
   Gateway (writable) server listening on /ip4/127.0.0.1/tcp/8080
   API server listening on /ip4/127.0.0.1/tcp/5001
   */
   if pPort is empty then put 5001 into ipfsPort
   if pDomain is empty then put "localhost" into pDomain
   
   put "http://" & pDomain & ":" & ipfsPort & "/api/v0/" & ipfsPath into someUrl
   if pArgs is not empty then
      repeat for each line someArg in pArgs
         --  ?arg=QmaaqrHyAQm7gALkRW8DcfGX3u8q9rWKnxEMmf7m9z515w
         put "?arg=" & someArg after someURL
      end repeat
   end if
   if pFlags is not empty then
      -- Flags are added through the query string. 
      -- For example, the --encoding=json flag is the &encoding=json
      if pArgs is empty then
         put "?" after someURL
      else
         put "&" after someURL
      end if
      put pFlags after someURL
   end if
   return someURL
end ipfs_ConstructUrl


--> IPFS | Shell
-
command ipfs_AddFolder someFolder
   /*
   david:Audioboom BabyBlue$ ipfs add -r 2455591/
   */
   
   ipfs_AddToPATH
   shell_BashParamEscape someFolder
   put "ipfs add -r" && someFolder into someShell
   put shell (someShell) into shellResult
   put ipfs_ParseAddFolderResult (shellResult, someFolder) into ipfsTable
   return ipfsTable
end ipfs_AddFolder

function ipfs_ParseAddFolderResult shellResult, someFolder
   /*
   added QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH 
   added QmWZWvdwZS1G1dcuyLdcWHKGAFCKUukDnnH8SiYAN6s497 /Users/BabyBlue/Desktop/Audioboom/2455591/10618993.jpg
   added QmSHfQqKQSfACwwisUbL76FExT7EfDVQnBnvdQBzF5cBEM /Users/BabyBlue/Desktop/Audioboom/2455591/2455591-chris-before-ethereum.mp3
   added QmTxQweL5zinurit4eJ1wNuHR1nSt7Dnwc79FPP9zeHtrd /Users/BabyBlue/Desktop/Audioboom/2455591/2455591-chris-before-ethereum.ogg
   added QmVmk2po9GsYsamiHhx3pnkpua4yp4X74L3eU4A9djLYcy /Users/BabyBlue/Desktop/Audioboom/2455591/audio.json
   added QmdKe32rSQ8fCeNmCYyacHZGbFuHwUWX3g6GWJfN1ATNKz /Users/BabyBlue/Desktop/Audioboom/2455591/
   */
   local ipfsTable
   set the itemdelimiter to "/"
   folder_Format someFolder
   put the number of chars of someFolder -1 into lastNum
   repeat for each line someLine in shellResult
      put word 1 of someLine into isPinned
      put word 2 of someLine into someHash
      put word 3 to -1 of someLine into relPath
      delete char 1 to lastNum of relPath
      put relPath & tab & someHash & tab & isPinned & CR after ipfsTable
   end repeat
   delete last char of ipfsTable
   return ipfsTable
end ipfs_ParseAddFolderResult

command ipfs_AddFile pFile, pPort, pDomain
   if pFile is empty then
      answer file "Select a file to add to IPFS..."
      put it into pFile
      if pFile is empty then return empty
   end if
   
   put empty into tForm
   -- http://localhost:5001/api/v0/add?stream-channels=true
   put empty into pArgs
   put ipfs_ConstructUrl ("add", pArgs, "stream-channels=true", pPort, pDomain) into tUrl  
   put "<file>" & pFile into tFile
   
   if libURLMultipartFormData (tForm, "file", tFile) is not empty then
      put it into someError
      put someError into someArray ["Error"]
   else
      put line 1 of tForm into postHeaders
      set the httpHeaders to postHeaders
      post line 2 to -1 of tForm to url tUrl
      ## check the result, etc., here
      put it into someJSON
      -- set the httpHeaders to empty
      
      put json_ToArray (someJSON) into someArray
   end if
   return someArray
end ipfs_AddFile

command ipfs_ShellAddFile someFile, pOnlyHash
   /*
   ipfs add <path>... - Add an object to ipfs.
   ipfs add /ipfs/QmPXME1oRtoT627YKaDPDQ3PwA8tdP9rWuAAweLzqSwAWT/readme
   */
   ipfs_AddToPATH
   put "ipfs add" into someShell
   if pOnlyHash is true then
      put space & "-t" after someShell
   end if
   put space & kwote(someFile) after someShell
   put shell (someShell) into shellResult
   
   /*
   
   256.00 KB / 552.62 KB   46.33% 0s
   512.00 KB / 552.62 KB   92.65% 0s
   552.62 KB / 552.62 KB  100.00% 0s[2K
   added QmePDvP8MAVS2oiePrEDDqnP39SeHgEBinTgy5fLXq3ofH ILLINOIS_panopticon.jpg
   */
   put wordoffset ("added", shellResult) into wordNum
   put word (wordNum+1) of shellResult into multiHash
   put word (wordNum+2) to -1 of lastLine into shortFile
   return multiHash
end ipfs_ShellAddFile


--> IPFS | Rest
-
function ipfs_GetObject someHash
   /*
   curl "http://127.0.0.1:5001/api/v0/object/get
   ?arg=QmaaqrHyAQm7gALkRW8DcfGX3u8q9rWKnxEMmf7m9z515w
   &encoding=json"
   */
   put ipfs_RestGet ("object/get", someHash) into someJSON
   return someJSON
end ipfs_GetObject

function ipfs_GetSwarmPeers
   put ipfs_RestGet ("swarm/peers") into someResult
   return someResult
end ipfs_GetSwarmPeers

function ipfs_GetVersion
   put ipfs_RestGetArray ("version") into someArray
   put someArray ["Version"] into versionNum
   return versionNum
end ipfs_GetVersion

function ipfs_Cat someHash, pUseRest
   /*
   -- for some reason "put shell ("ipfs cat 'QmaSRYp3f8Psd7Ryp4f9n9qhv4QMMepVTVKim7iANNfkFC'") complains
   -- but the following works
   -- put shell ("echo 'QmaSRYp3f8Psd7Ryp4f9n9qhv4QMMepVTVKim7iANNfkFC' | ipfs cat")
   */
   
   if pUseRest is true then
      put ipfs_RestGet ("cat", someHash) into someJSON
   else
      --   ipfs cat /ipfs/QmPXME1oRtoT627YKaDPDQ3PwA8tdP9rWuAAweLzqSwAWT/readme
      -- put "ipfs cat" && someHash into thisIsStangelyBroken
      
      ipfs_AddToPATH
      put merge ("echo [[someHash]] | ipfs cat") into someShell
      put shell (someShell) into someJSON
   end if
   return someJSON
end ipfs_Cat

function ipfs_Cat someHash
    return someJSON
 end ipfs_Cat
 
 
 --> IPFS | Rest
 -
 function ipfs_RestGetArray ipfsPath
   put ipfs_RestGet (ipfsPath) into someJSON
   put json_ToArray (someJSON) into someArray
   return someArray
end ipfs_RestGetArray

function ipfs_RestGet ipfsPath, someArg
   put ipfs_ConstructUrl (ipfsPath, someArg) into someUrl
   put url someUrl into someJSON
   return someJSON
end ipfs_RestGet


 --> IPFS | Shell
 -
command ipfs_AddToPATH
   put "/Users/BabyBlue/go/bin/" into goPath
   set the itemdelimiter to ":"
   if goPath is among the items of $PATH then
      return $PATH
   else
      put ":" & goPath after $PATH
      return $PATH
   end if
end ipfs_AddToPATH
