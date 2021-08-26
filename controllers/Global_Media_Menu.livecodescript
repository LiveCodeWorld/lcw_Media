script "Global | Media | Menu"
--> MetaData
-
license: GPLv3
name: Global | Media | Menu
type: controller
version: 0.1


--> Menu | Init
-
getprop audioboomDocs_Params
   return "Audioboom API,Audioboom Authentication,Notes"
end audioboomDocs_Params

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


--> Global | Media | Menu
-
on submenu_Ipfs
   return "Global | IPFS | Menu"
end submenu_Ipfs

on _
end _

on menu_PinterestAuthenticatonArray
   put user_GetArray (cPinterestModelShortFile) into authenticationArray
   display_Array authenticationArray
end menu_PinterestAuthenticatonArray

on _
end _

on menu_TestPageJson
   put "https://audioboom.com/posts/3836093-raspberrypad" into someURL
   put audioboom_ClipJsonFromUrl (someURL)
end menu_TestPageJson

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
   put the result into audioboomAuthArray
   
   display_Array audioboomAuthArray, "audioboom_Authenticate", "Global | Media | Menu"
end menu_AuthenticateAudioboom

on menu_RefreshToken
   audioboom_RefreshAccessToken
   put the result into audioboomAuthArray
   
   display_Array audioboomAuthArray, "audioboom_Authenticate", "Global | Media | Menu"
end menu_RefreshToken

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
