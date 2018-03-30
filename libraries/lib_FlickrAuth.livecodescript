script "lib_FlickrAuth"
--> MetaData
-
license: GPLv3
name: lib_FlickrAuth
type: library
version: 0.5

/*
Moving over to newer oAuth  1.0 authentication
See http://www.wackylabs.net/2011/12/oauth-and-flickr-part-2/
*/


--> Variables
-
/*
This oauth_token should be stored securely after it was obtained when logging into the service for the first time
and may be refresshed from time to time (or revoked)
*/

constant cFlickrModelShortFile = "flickr_Authentication.array"
constant cRestEndPoint = "https://www.flickr.com/services/rest/"
constant cUploadPhotoEndPoint = "https://up.flickr.com/services/upload/"
constant cFlickrCallBackURL = "http://127.0.0.1:54303"

local FickrAuthenticationToken
local FickrRequestTokenSecret

local FlickrAccessToken
local FlickrAccessTokenSecret
local FlickrConsumerKey
local FlickrConsumerSecret


--> Flickr | Variables
-
function flickr_GetAccessToken
   -- cached
   if FlickrAccessToken is empty then
      put user_GetValue ("FlickrAccessToken", cFlickrModelShortFile) into FlickrAccessToken
      if FlickrAccessToken is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if
   return FlickrAccessToken
end flickr_GetAccessToken

command flickr_SetAccessToken pAccessToken
   user_SetValue "FlickrAccessToken", cFlickrModelShortFile, pAccessToken
   put the result into modelDataFile
   return modelDataFile
end flickr_SetAccessToken

function flickr_GetAccessTokenSecret
   -- cached
   if FlickrAccessTokenSecret is empty then
      put user_GetValue ("FlickrAccessTokenSecret", cFlickrModelShortFile) into FlickrAccessTokenSecret
      if FlickrAccessTokenSecret is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if   
   return FlickrAccessTokenSecret
end flickr_GetAccessTokenSecret

command flickr_SetAccessTokenSecret pAccessTokenSecret
   user_SetValue "FlickrAccessToken", cFlickrModelShortFile, pAccessTokenSecret
   put the result into modelDataFile
   return modelDataFile
end flickr_SetAccessTokenSecret

function flickr_GetConsumerKey
   -- cached
   if FlickrConsumerKey is empty then
      put user_GetValue ("FlickrConsumerKey", cFlickrModelShortFile) into FlickrConsumerKey
      if FlickrConsumerKey is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if   
   return FlickrConsumerKey
end flickr_GetConsumerKey

command flickr_SetConsumerKey pConsumerKey
   user_SetValue "FlickrConsumerKey", cFlickrModelShortFile, pConsumerKey
   put the result into modelDataFile
   return modelDataFile
end flickr_SetConsumerKey

function flickr_GetConsumerSecret
   -- cached
   if FlickrConsumerSecret is empty then
      put user_GetValue ("FlickrConsumerSecret", cFlickrModelShortFile) into FlickrConsumerSecret
      if FlickrConsumerSecret is empty then -- something is broken
         breakpoint
         exit to top
      end if
   end if   
   return FlickrConsumerSecret
end flickr_GetConsumerSecret

command flickr_SetConsumerSecret pConsumerSecret
   user_SetValue "FlickrConsumerSecret", cFlickrModelShortFile, pConsumerSecret
   put the result into modelDataFile
   return modelDataFile
end flickr_SetConsumerSecret

function flickr_GetCallBackUrl
   return cFlickrCallBackURL
end flickr_GetCallBackUrl


--> Flickr | Authentication | Signature
-
function flickr_FetchAccessString requestTokenUrl, callBackURL
   put flickr_ConstructAccessTokenUrl (requestTokenUrl, callBackURL) into someURL
   put url someURL into accessTokenString
   
   flickr_SetAccessTokenAndSecret accessTokenString
   return accessTokenString
end flickr_FetchAccessString

command flickr_SetAccessTokenAndSecret accessTokenString  
   split accessTokenString with "&" and "="
   put urldecode (accessTokenString ["fullname"]) into fullname
   put urldecode (accessTokenString ["user_nsid"]) into userNSID
   
   put urldecode (accessTokenString ["oauth_token"]) into FlickrAccessToken
   put urldecode (accessTokenString ["oauth_token_secret"]) into FlickrAccessTokenSecret
end flickr_SetAccessTokenAndSecret


--> Flickr | Authentication | Signature
-
function flickr_GetRequestTokenSecret
   return FickrRequestTokenSecret
end flickr_GetRequestTokenSecret

command flickr_SetRequestTokenSecret oAuthTokenSecret
   put oAuthTokenSecret into FickrRequestTokenSecret
end flickr_SetRequestTokenSecret

command flickr_SetAuthenticationToken flickrAuthenticationToken
   put flickrAuthenticationToken into FickrAuthenticationToken
end flickr_SetAuthenticationToken


--> Flickr | Access Token
-
/*
So after the user has viewed the presented oAuth dialogue using the authenticationURL that you get from:
flickr_PresentAuthDialogue confirmationString

We need to extract theinformation from the redirected url
This can be tested by pasting it into Chrome or any browser and authenticating with Flickr which will result in a url like:

http://127.0.0.1:54303/?oauth_token=xxx&oauth_verifier=yyy

This oAouthToken contained in the redirect url is what we can call a "request token", so let's call ths url  a requestTokenUrl
From there we need to make a HTTP GET call to exchange the requestToken for an acessToken
See - https://www.flickr.com/services/api/auth.oauth.html#request_token
*/

function flickr_GetAuthenticationToken
   /*
   This token should be stored securely after it was obtained when logging into the service for the first time
   and may be refresshed from time to time (or revoked)
   
   Currently stored as a local variable of this stack
   */
   return FickrAuthenticationToken
end flickr_GetAuthenticationToken

function flickr_ConstructAccessTokenUrl requestTokenUrl, callBackURL
   local oAuthToken, oAuthVerifier, urlParamBit, baseString
   
   -- put "http://127.0.0.1:54303/?oauth_token=xxx&oauth_verifier=yyy" into requestTokenUrl
   -- put "http://127.0.0.1:54303/" into callBackURL
   
   put "https://www.flickr.com/services/oauth/access_token" into someUrl
   
   flickr_DeconstructRequestTokenUrl requestTokenUrl, callBackURL, oAuthToken, oAuthVerifier
   
   put _constructAccessTokenArray (oAuthToken, oauthVerifier) into paramArray
   flickr_ConstructParamBits "GET", someUrl, paramArray, urlParamBit, baseString
   put "?" & urlParamBit after someUrl
   
   if pDontSign is true then
      return someUrl
   else
      -- calculate (hash) and then add the signature to the url
      
      put flickr_GetRequestTokenSecret() into tokenSecret
      put flickr_ConstructOauthKey (tokenSecret) into oauthKey
      put sha1_HMAC (baseString, oauthKey) into oauthSignature  
      put "&oauth_signature=" & urlencode (oauthSignature) after someURL
      
      return someUrl
   end if
end flickr_ConstructAccessTokenUrl

command flickr_DeconstructRequestTokenUrl requestTokenUrl, callBackURL, @oAuthToken, @oAuthVerifier
   -- put "http://127.0.0.1:54303/?oauth_token=xxxx&oauth_verifier=yyyy" into accessTokenString
   -- put "http://127.0.0.1:54303/" into callBackURL
   
   set the itemdelimiter to "?"
   get item 1 of requestTokenUrl
   put item 2 of requestTokenUrl into authenticationArray
   
   set the itemdelimiter to slash
   put item 1 to 3 of it into testCallBackURL
   put item 1 to 3 of callBackURL into callBackURL
   if testCallBackURL is not callBackURL then
      return false
   end if
   
   split authenticationArray with "&" and "="
   put authenticationArray ["oauth_token"] into oAuthToken
   put authenticationArray ["oauth_verifier"] into oAuthVerifier
   
   return true
end flickr_DeconstructRequestTokenUrl


--> Flickr | Authentication Token
-
command flickr_PresentAuthDialogue confirmationString
   -- put flickr_DeconstructAuthCallbackConfirmed (confirmationString) into oAuthToken
   split confirmationString with "&" and "="
   put confirmationString ["oauth_callback_confirmed"] into someBoolean
   put confirmationString ["oauth_token"] into oAuthToken
   put confirmationString ["oauth_token_secret"] into tokenSecret
   if someBoolean is false then
      breakpoint
      return empty
   end if
   
   flickr_SetRequestTokenSecret tokenSecret
   
   put "https://www.flickr.com/services/oauth/authorize" into authenticationURL
   put "?oauth_token=" & oAuthToken after authenticationURL
   
   -- put "&perms=read" after authenticationURL
   -- put "&perms=write" after authenticationURL
   put "&perms=delete" after authenticationURL
   
   -- here we need a local server listening on callbackurl
   -- set the browser_Url of stack "Flickr Authentication" to authenticationURL
   launch url authenticationURL
   -- put authenticationURL
   return authenticationURL
end flickr_PresentAuthDialogue

function flickr_DeconstructAuthCallbackConfirmed confirmationString
   -- put "oauth_callback_confirmed=true&oauth_token=xxx&oauth_token_secret=yyy" into confirmationString
   
   split confirmationString with "&" and "="
   put confirmationString ["oauth_callback_confirmed"] into someBoolean
   put confirmationString ["oauth_token"] into oAuthToken
   put confirmationString ["oauth_token_secret"] into oAuthTokenSecret
   if someBoolean is false then
      return empty
   end if
   
   return oAuthToken
end flickr_DeconstructAuthCallbackConfirmed


--> Flickr | Request Token
-
function flickr_FetchRequestToken callBackUrl
   put flickr_ConstructRequestTokenParamArray (callBackUrl) into paramArray
   put "https://www.flickr.com/services/oauth/request_token" into someURL
   flickr_ConstructParamBits "GET", someUrl, paramArray, urlParamBit, baseString
   
   put flickr_ConstructOauthKey() into oauthKey
   put sha1_HMAC (baseString, oauthKey) into oauthSignature  
   
   put "?" & urlParamBit after someUrl
   put "&oauth_signature=" & urlencode (oauthSignature) after someURL
   
   put url someURL into someResponse
   return someResponse
end flickr_FetchRequestToken

function flickr_ConstructRequestTokenParamArray callBackUrl
   put uuid() into paramArray ["oauth_nonce"]
   put the ticks into paramArray ["oauth_timestamp"]
   put "HMAC-SHA1" into paramArray ["oauth_signature_method"]
   put "1.0" into paramArray ["oauth_version"]
   put flickr_GetConsumerKey() into paramArray ["oauth_consumer_key"]
   put callBackUrl into paramArray ["oauth_callback"]
   --
   return paramArray
end flickr_ConstructRequestTokenParamArray

function flickr_OauthConstructSig callBackUrl, consumerKey, someTicks, oauthNonce, restEndPoint, pTokenSecret
   put flickr_OauthConstructBaseString (callBackUrl, consumerKey, someTicks, oauthNonce, restEndPoint) into baseString
   put flickr_ConstructOauthKey (pTokenSecret) into oauthKey
   put sha1_HMAC (baseString, oauthKey) into oAuthSig  
   return oAuthSig
end flickr_OauthConstructSig

function flickr_OauthConstructBaseString callBackUrl, consumerKey, someTicks, oauthNonce, restEndPoint
   put flickr_OauthEncode (restEndPoint) into secondBit
   put _EncodeSecondBit (callBackUrl, consumerKey, someTicks, oauthNonce) into thirdBit
   put "GET&" & secondBit & "&" & thirdBit into baseString
   return baseString
end flickr_OauthConstructBaseString

function flickr_ConstructOauthTokenUrl callBackUrl, consumerKey, consumerSecret, pSomeTicks, pOauthNonce, pRequestEndPoint, pTokenSecret
   put flickr_OauthConstructSig (callBackUrl, consumerKey, pSomeTicks, pOauthNonce, pRequestEndPoint, pTokenSecret) into oAuthSig
   --
   put pRequestEndPoint into someURL
   put "?oauth_callback=" & urlencode (callBackUrl) after someURL
   put "&" after someURL
   put "oauth_consumer_key=" & consumerKey after someURL
   put "&" after someURL
   put "oauth_nonce=" & pOauthNonce after someURL
   put "&" after someURL
   put "oauth_timestamp=" & pSomeTicks after someURL
   put "&" after someURL
   put "oauth_signature_method=HMAC-SHA1" after someURL
   put "&" after someURL
   put "oauth_version=1.0" after someURL
   put "&" after someURL
   put "oauth_signature=" & urlencode (oAuthSig) after someURL
   --
   return someURL
end flickr_ConstructOauthTokenUrl


--> Flickr | REST
-
function flickr_OauthRestUrl methodName, paramArray, pRestMethod, pDontSign, pReturnXML
   if pRestMethod is empty then put "GET" into pRestMethod
   put cRestEndPoint & "?" into someUrl
   
   if pDontSign is true then
      put methodName into paramArray ["method"]
      put 1 into paramArray ["nojsoncallback"]
      put "json" into paramArray ["format"]
      
      put flickr_GetConsumerKey() into paramArray ["oauth_consumer_key"]
      
      flickr_ConstructParamBits pRestMethod, cRestEndPoint, paramArray, urlParamBit, baseString -- overkill
      put urlParamBit after someUrl
      
      return someUrl
   else
      put methodName into paramArray ["method"]
      put flickr_GetAccessToken() into paramArray ["oauth_token"]
      
      if pReturnXML is not true then
         put 1 into paramArray ["nojsoncallback"]
         put "json" into paramArray ["format"]
      end if
      flickr_AddDefaultsToParamArray paramArray 
      
      -- prepare
      flickr_ConstructParamBits pRestMethod, cRestEndPoint, paramArray, urlParamBit, baseString
      put urlParamBit after someUrl
      
      -- calculate (hash) and then add the signature to the url
      put flickr_GetAccessTokenSecret() into tokenSecret
      put flickr_ConstructOauthKey (tokenSecret) into oauthKey
      put sha1_HMAC (baseString, oauthKey) into oauthSignature  
      put "&oauth_signature=" & oauthSignature after someUrl
      return someUrl
   end if
end flickr_OauthRestUrl

function flickr_ConstructOauthSignature baseString
   put flickr_GetAccessTokenSecret() into tokenSecret
   put flickr_ConstructOauthKey (tokenSecret) into oAuthKey
   put sha1_HMAC (baseString, oAuthKey) into oAuthSignature  
   return oAuthSignature
end flickr_ConstructOauthSignature

function flickr_OauthEncode someText
   /*
   This is a modified version of urlencode used in creating sigs
   The current version is a quick hack.
   Todo: look at the documentation and code a complete verison of this function  (http://www.marcworrell.com/article-2943-en.html)
   
   OAuth encoding only allows letters, numbers and the following 4 punctuation marks: “_”, “-“, “.” and “~”. All other characters must be encoded.
   
   You will likely not notice the difference until you come to call methods that include things like title etc, as most parameters will not contain data that is encoded differently with the above compared to standard url encoding.
   
   A little post I found covering some of the differences is here: http://www.marcworrell.com/article-2943-en.html
   */
   
   put urlencode (someText) into someText
   replace "+" with "%20" in someText
   replace "%7E" with "~" in someText
   return someText
end flickr_OauthEncode

function flickr_ExtractRSP restResponse
   put "<rsp stat='ok'>" into okResponse
   replace "'" with quote in okResponse
   
   if restResponse contains okResponse then
      return "ok"
   else
      put "<rsp stat='fail'>" into failResponse
      replace "'" with quote in failResponse
      if restResponse contains failResponse then
         return "fail"
      else
         return restResponse
      end if
   end if
end flickr_ExtractRSP


--> Flickr | Debug
-
function flickr_CheckOauthToken
   put flickr_OauthRestUrl ("flickr.auth.oauth.checkToken") into someURL
   put url someURL into someResponse
   return someResponse
end flickr_CheckOauthToken

function flickr_TestLogin
   put flickr_OauthRestUrl ("flickr.test.login") into someURL
   put url someURL into someResponse
   return someResponse
end flickr_TestLogin

function flickr_TestEcho paramArray
   put flickr_OauthRestUrl ("flickr.test.echo", paramArray) into someURL
   put url someURL into someResponse
   return someResponse
end flickr_TestEcho


--> Private 
-
private function flickr_ConstructOauthKey pTokenSecret, pConsumerSecret
   /*
   The key that is used together with the sha1 digest function in creating and HMAC signature is derived from
   the concatenated values of the Consumer Secret and Token Secret, separated by an '&'.
   
   The tokenSecret may be given in a previous call to the api for that particular stage of the provess,
   or it may be empty
   
   -- http://www.wackylabs.net/2011/12/oauth-and-flickr-part-2/
   
   Key = Consumer Secret + “&” + Token Secret
   
   To generate a SHA1 signature you require two things. 
   First a key. For OAuth the signature key is made up of two parts, your consumer secret, and your token secret (for whichever token you are using at the time). 
   As this is the first stage you have neither, so your token secret is simply an empty string.
   */
   
   if pConsumerSecret is empty then
      -- never reveal the consumerSecret
      -- should be stored securely on the server, or a locked Livecode script
      put flickr_GetConsumerSecret() into pConsumerSecret
   end if
   put pConsumerSecret &"&"& pTokenSecret into oauthKey
   return oauthKey
end flickr_ConstructOauthKey

private function _EncodeSecondBit callbackURL, consumerKey, someTicks, oauthNonce
   put "oauth_callback=" & flickr_OauthEncode (callbackURL) into secondBit
   put "&" after secondBit
   
   put "oauth_consumer_key=" & flickr_OauthEncode (consumerKey) after secondBit
   put "&" after secondBit
   
   put "oauth_nonce=" & oauthNonce after secondBit
   put "&" after secondBit
   
   put "oauth_signature_method=HMAC-SHA1" after secondBit
   put "&" after secondBit
   
   put "oauth_timestamp=" & someTicks after secondBit
   put "&" after secondBit
   
   put "oauth_version=1.0" after secondBit
   
   put flickr_OauthEncode (secondBit) into encodedSecondBit
   
   return encodedSecondBit
end _EncodeSecondBit

private function _constructAccessTokenArray oAuthToken, oauthVerifier
   /*
   This sets the params from stored constants or local variables if they are not explicitly passed
   We can treat these stored variables then as defaults which we can override using the params for testing purposes
   */
   
   put oAuthToken into paramArray ["oauth_token"]
   put oauthVerifier into paramArray ["oauth_verifier"]
   flickr_AddDefaultsToParamArray paramArray 
   return paramArray
end _constructAccessTokenArray
