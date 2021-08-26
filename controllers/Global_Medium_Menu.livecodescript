script "Global | Medium | Menu"
--> MetaData
-
license: GPLv3
local ApiStem =  "https: //api.medium.com/v1/"
name: Global | Medium | Menu
type: controller
version: 0.1


--> Global | Medium | Menu
-
on menu_FetchAuthenticatedUser mTarget
   put apiStem & "me" into restURL
   put medium_GetAccessToken() into oAuthToken
   put jsonrpc_GET (restURL, oAuthToken) into resultJSON
   --
   display_Json resultJSON
end menu_FetchAuthenticatedUser

on menu_FetchPublications
   put "1c3f0e7d6ac495d0b686ca47ff35ba60373b6185ac23ea1af3dffef86d6dbf5bb" into userId
   --
   put apiStem & "users/" & userId & "/publications" into restURL
   put medium_GetAccessToken() into oAuthToken
   put jsonrpc_GET (restURL, oAuthToken) into resultJSON
   --
   display_Json resultJSON
end menu_FetchPublications

on menu_FetchContributors
   put "f63c83f44e1d" into publicationId
   --
   put apiStem & "publications/" & publicationId & "/contributors" into restURL
   put medium_GetAccessToken() into oAuthToken
   put jsonrpc_GET (restURL, oAuthToken) into resultJSON
   --
   display_Json resultJSON
end menu_FetchContributors

on _
end _

on menu_TestPost
   /*
   {
   "title": "Liverpool FC",
   "contentFormat": "html",
   "content": "<h1>Liverpool FC</h1><p>You’ll never walk alone.</p>",
   "canonicalUrl": "http://jamietalbot.com/posts/liverpool-fc",
   "tags": ["football", "sport", "Liverpool"],
   "publishStatus": "public"
   }
   */
   
   put script_GetCommentAboveMe() into someJSON
   
   -- POST https://api.medium.com/v1/users/{{authorId}}/posts
   put "1c3f0e7d6ac495d0b686ca47ff35ba60373b6185ac23ea1af3dffef86d6dbf5bb" into authorID
   --
   put apiStem & "users/" & authorID & "/posts" into restURL
   put medium_GetAccessToken() into oAuthToken
   put jsonrpc_POST (someJSON, restUrl, oAuthToken) into resultJSON
   --
   display_Json resultJSON
end menu_TestPost


--> Global | Medium | Menu | Props
-

--> Global | Medium | Menu | Disabled
-
