script "lib_Vimeo"
--> MetaData
-
license: GPLv3
name: lib_Vimeo
type: library
version: 0.2

/*
This library is for interfacing with Vimeo.
Check out the documentation for the Vimeo API at:

- https://developer.vimeo.com/api/authentication
*/


--> Workign on
-
function vimeo_GetUnauthenticatedToken
   -- not working
   put vimeo_GetClientID() into clientID
   put vimeo_GetSecret() into clientSecret
   put base64encode (clientID & ":" & clientSecret) into encodedBit
   replace CR with empty in encodedBit
   --
   put "Authorization : basic" && encodedBit after authHeader
   --
   set the httpheaders to authHeader
   -- 
   get libURLFormData ("grant_type", "client_credentials", "scope", "public private")
   post it to url "https://api.vimeo.com/oauth/authorize/client"
   put it into postResult
   return postResult
end vimeo_GetUnauthenticatedToken


--> Vimeo | Authentication
-
command vimeo_SetAccessToken accessToken
   secret_Set "VimeoApiKey", accessToken, "vimeo"
   put the result into modelDataFile
   return modelDataFile
end vimeo_SetAccessToken

function vimeo_GetAccessToken
   put secret_Get ("VimeoApiKey", "vimeo") into vimeoApiKey
   return vimeoApiKey
end vimeo_GetAccessToken

function vimeo_GetClientID
   put secret_Get ("VimeoClientID", "vimeo") into vimeoApiKey
   return vimeoApiKey
end vimeo_GetClientID

command vimeo_SetClientID clientID
   secret_Set "VimeoClientID", clientID, "vimeo"
   put the result into modelDataFile
   return modelDataFile
end vimeo_SetClientID

function vimeo_GetSecret
   put secret_Get ("VimeoClientSecret", "vimeo") into vimeoApiKey
   return vimeoApiKey
end vimeo_GetSecret

command vimeo_SetClientSecret clientSecret
   secret_Set "VimeoClientSecret", clientSecret, "vimeo"
   put the result into modelDataFile
   return modelDataFile
end vimeo_SetClientSecret


--> Vimeo | REST
-
function vimeo_RestGET apiBit
   vimeo_SetAuthentication
   put "https://api.vimeo.com/" & apiBit into restURL
   --
   put url restURL into someJSON
   return someJSON
end vimeo_RestGET

command vimeo_SetAuthentication
   put "Accept: application/vnd.vimeo.*+json;version=3.4" into authHeader
   put vimeo_GetAccessToken() into accessToken
   put CR & "Authorization: Bearer" && accessToken after authHeader
   set the httpheaders to authHeader
end vimeo_SetAuthentication


--> Vimeo
-
function vimeo_ConstructPageArray vimeoID
   put vimeo_FetchVideoJSON (vimeoID) into someJSON
   put json_ToArray (someJSON) into vimeoArray
   --
   put vimeoArray ["name"] into vimeoTitle
   put vimeoArray ["description"] into vimeoDescription
   put vimeoArray ["link"] into vimeoURL
   --
   put vimeoTitle & "." && vimeoDescription into videoDescription
   --
   put pageArray_Construct (vimeoTitle, vimeoDescription) into fedwikiPageArray
   pageArray_AddVideo fedwikiPageArray, vimeoID, "VIMEO", videoDescription
   --
   return fedwikiPageArray
end vimeo_ConstructPageArray

function vimeo_FetchVideoJSON videoID
   put "videos/" & videoID into apiBit
   put vimeo_RestGET (apiBit) into someJSON
   return someJSON
end vimeo_FetchVideoJSON
