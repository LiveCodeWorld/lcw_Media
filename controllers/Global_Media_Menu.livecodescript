script "Global_Media_Menu"
--> MetaData
-
license: GPLv3
name: Global_Media_Menu
type: controller
version: 0.1


--> Global | Media | Menu
-
on submenu_Ipfs
   return "Global | IPFS | Menu"
end submenu_Ipfs

on _
end _

on menu_TestAudioBoomAccount
   put audioboom_GetAccountArray() into accountArray
   display_Array accountArray
end menu_TestAudioBoomAccount

on menu_TestPostAudioBoom
   constant kAuthToken = "xoxp-30525850577-217902599698-222567234947-f6b062907634dfe7372e99021a509f90"
   put mTarget
end menu_TestPostAudioBoom

on menu_AuthenticateAudioboom
   audioboom_Authenticate
end menu_AuthenticateAudioboom

on _
end _

on menu_AudioboomDocs mTarget, whichDoc
   switch whichDoc
      case "Audioboom API"
         launch url "https://github.com/audioboom/api/blob/master/sections/reference_index.md"
         break
      case "Audioboom Authentication"
         launch url "https://github.com/audioboom/api/blob/master/sections/authentication.md"
         break
      case "Notes"
         launch url "http://api.c0de.academy/view/welcome-visitors/view/audioboom-api"
         break
   end switch
end menu_AudioboomDocs


--> Global | Media | Menu | Props
-

--> Global | Media | Menu | Disabled
-
getprop disabled_TestLoadData
   put ipfs_GetMultiHash ("IPFS video Player") = "QmdbejVfgCQSEwhutDovDAv2gfKhGrXZTdrmBp179Dn3kK" into foundHash
   if foundHash is true then
      return true
   else
      return false
   end if
end disabled_TestLoadData
   
getprop disabled_StartIpfs
   get the openProcesses
   if it contains "ipfs daemon" then
      return true
   else
      return false
   end if
end disabled_StartIpfs

getprop disabled_StopIpfs
   get the openProcesses
   if it contains "ipfs daemon" then
      return false
   else
      return true
   end if
end disabled_StopIpfs
