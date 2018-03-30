script "lib_FlickrAuthOld"
--> MetaData
-
license: GPLv3
name: lib_FlickrAuthOld
type: library
version: 0.2

constant cRestEndPoint = "https://www.flickr.com/services/rest/"
constant cUploadPhotoEndPoint = "https://up.flickr.com/services/upload/"


--> Flickr | REST | Authentication
-
function flickr_GetAuthenticated methodName, paramArray
   put flickr_ConstructAuthenticationUrl (methodName, paramArray) into someUrl
   put url someUrl into someXml
   return someXml
end flickr_GetAuthenticated

function flickr_ConstructAuthenticationUrl methodName, paramArray
   put the flickr_AuthenticationToken of me into authToken
   put authToken into paramArray["auth_token"]
   put flickr_GetMethodSignature (methodName, authToken, paramArray) into someSig
   
   put flickr_ConstructRestUrl (methodName, paramArray, someSig) into someUrl
   return someUrl
end flickr_ConstructAuthenticationUrl

on flickr_PostAuthenticated methodName, paramArray
   put the flickr_AuthenticationToken of me into authToken
   put flickr_GetMethodSignature (methodName, authToken, paramArray) into someSig
   put authToken into paramArray["auth_token"]
   
   put cFlickrApiConsumerKey into paramArray["api_key"]
   put cRestEndPoint & "?method=" & methodName into someUrl
   
   put keys(paramArray) into recordKeys
   sort recordKeys
   put empty into postData
   repeat for each line recordKey in recordKeys
      put paramArray [recordKey] into recordValue
      form_AddToPostData recordKey, recordValue, postData
   end repeat
   
   -- not sure if it eeds to be at the end here
   form_AddToPostData "api_sig", someSig, postData
   
   post postData to url someUrl
   return it
end flickr_PostAuthenticated


--> Flickr | REST | Authentication | Stubs
-
/*
These are now stored as custom properties.
An authenticatio token is set when the user registers the application.
It can but does not usualy expire. it can be revoked by the user on her web site.
*/

getprop flickr_AuthenticationToken
   put flickr_GetStoredSessionAuthToken() into authToken -- fortyfoxes
   put flickr_GetAuthToken() into authToken
   set the uOPN ["flickr_AuthenticationToken"] of me to authToken
   return the uOPN ["flickr_AuthenticationToken"] of me
end flickr_AuthenticationToken

setprop flickr_AuthenticationToken authToken
   set the uOPN ["flickr_AuthenticationToken"] of me to authToken
end flickr_AuthenticationToken

function flickr_ConstructRestUrl methodName, paramArray, someSig
   /*
   -- old version
   */
   
   put cFlickrApiConsumerKey into paramArray ["api_key"]
   put cRestEndPoint & "?method=" & methodName into someUrl
   
   put keys (paramArray) into paramkeys
   sort paramKeys -- not really needed
   repeat for each line paramKey in paramkeys
      get paramArray[paramKey]
      if it is not empty then
         -- not sure if we need to url encode it
         put "&" & paramKey & "=" & urlencode(it) after someUrl
      end if
   end repeat
   
   if someSig is not empty then
      put "&" & "api_sig=" & someSig after someUrl
   end if
   return someUrl
end flickr_ConstructRestUrl


--> Flickr | REST | Authentication | First Time | Old
-
function flickr_GetMethodSignature methodName, authToken, sigArray
   -- old frob version
    
   if methodName is not empty then put methodName into sigArray["method"]
   put cFlickrApiConsumerKey into sigArray["api_key"]
   put authToken into sigArray["auth_token"]
   
   put flickr_GetSignatureString (sigArray) into signatureString
   put text_Hash (signatureString, "sha1") into someSig
   return someSig
end flickr_GetMethodSignature

function flickr_GetSignatureString paramArray
   -- old version for frob
   -- can sort paramArray
   put cConsumerSecret into signatureString
   
   put keys (paramArray) into paramkeys
   sort paramKeys
   repeat for each line paramKey in paramkeys
      put paramArray[paramKey] into paramValue
      if paramValue is not empty then
         put paramKey & paramValue after signatureString
      end if
   end repeat
   return signatureString
end flickr_GetSignatureString

function flickr_CheckAuthenticationToken
   put "flickr.auth.checkToken" into methodName
   
   put the flickr_AuthenticationToken of me into authToken
   
   put methodName into sigArray["method"]
   put cFlickrApiConsumerKey into sigArray["api_key"]
   put authToken into sigArray["auth_token"]
   
   put flickr_GetSignatureString(sigArray) into signatureString
   put text_Hash (signatureString, "sha1") into someSig
   
   put cFlickrApiConsumerKey into paramArray["api_key"]
   put authToken into paramArray["auth_token"]
   put flickr_ConstructRestUrl (methodName, paramArray, someSig) into someUrl
   return url someUrl
end flickr_CheckAuthenticationToken

-- on flickr_AddSigToParamArray @paramArray
   put flickr_GetSignatureString (paramArray) into signatureString
   put text_Hash (signatureString, "sha1") into someSig
   put someSig into paramArray["api_sig"]
end flickr_AddSigToParamArray

function flickr_GetAuthToken
   put "flickr.auth.getToken" into methodName
   put flickr_GetFrob() into frob
   
   put cFlickrApiConsumerKey into paramArray["api_key"]
   put frob into paramArray["frob"]
   put methodName into sigArray["method"]
   
   union sigArray with paramArray
   
   put flickr_GetSignatureString (sigArray) into signatureString
   -- put text_Hash (signatureString, "sha1") into someSig
   put text_Hash (signatureString) into someSig
   
   put flickr_ConstructRestUrl (methodName, paramArray, someSig) into someUrl
   -- invalid frob
   get url someUrl
   return it
end flickr_GetAuthToken

function flickr_GetFrob 
   put "flickr.auth.getFrob" into methodName
   /*
   -- request frob
   var sorted_params = shared_secret + 'api_key' + apikey + 'methodflickr.auth.getFrob';
   var signature = hex_md5(sorted_params);
   url.postData = "method=flickr.auth.getFrob&api_key=" + apikey +"&api_sig=" + signature; 
   */
   
   put cFlickrApiConsumerKey into paramArray["api_key"]
   put flickr_GetFrobSig() into paramArray["api_sig"]
   
   put flickr_ConstructRestUrl (methodName, paramArray) into someUrl
   put url someUrl into restResponse
   
   put flickr_ExtractRSP (restResponse) into rspStatus
   if rspStatus is "ok" then
      put xml_GetTagContents ("frob", restResponse) into someFrob
      return someFrob
   else if rspStatus is "fail" then
      put restResponse
      answer rspStatus
   else
      answer restResponse
   end if
   exit to top
end flickr_GetFrob

function flickr_GetFrobSig
   put "flickr.auth.getFrob" into methodName
   put methodName into paramArray["method"]
   put cFlickrApiConsumerKey into paramArray["api_key"]
   
   put flickr_GetSignatureString (paramArray) into frobSignatureString
   -- put text_Hash (frobSignatureString, "sha1") into frobSig
   put text_Hash (frobSignatureString) into frobSig
   return frobSig
end flickr_GetFrobSig

on flickr_PostAuthToken frob
   -- not sure  if frob should come from earlier call
   /*
   -- request token
   sorted_params=shared_secret+'api_key'+apikey+'frob'+frob_data+'methodflickr.auth.getToken';
   signature=hex_md5(sorted_params);
   url.postData = "method=flickr.auth.getToken&api_key="+apikey+"&frob="+frob_data+"&api_sig="+signature;
   */
   
   --- put flickr_GetFrob() into frob
   put flickr_GetAuthSig(frob) into someSig
   
   /*
   url.postData =
   "method=flickr.auth.getToken&api_key="+apikey+"&frob="+frob_data+"&api_sig="+ signature;
   contents = url.fetch("http://flickr.com/services/rest/");
   */
   
   put cFlickrApiConsumerKey into paramArray["api_key"]
   put frob into paramArray["frob"]
   put flickr_ConstructRestUrl("flickr.auth.getToken", paramArray, someSig) into someUrl
   put url someUrl
end flickr_PostAuthToken

function flickr_GetAuthSig frob
   put cFlickrApiConsumerKey into sigArray["api_key"]
   put frob into sigArray["frob"]
   put "flickr.auth.getToken" into sigArray["method"]
   
   put flickr_GetSignatureString (sigArray) into signatureString
   put text_Hash (signatureString, "sha1") into someSig
   return someSig
end flickr_GetAuthSig

on flickr_AuthenticateApplication
   put flickr_GetFrob() into frob
   put flickr_GetLoginUrl ("delete", frob) into someUrl
   revGoURL someUrl
   return frob
end flickr_AuthenticateApplication

function flickr_GetLoginUrl perms, frob
   put flickr_GetLoginSig(frob, perms) into api_sig
   
   get "http://flickr.com/services/auth/?api_key=[[cFlickrApiConsumerKey]]&perms=[[perms]]&frob=[[frob]]&api_sig=[[api_sig]]"
   put merge(it) into someUrl
   return someUrl
end flickr_GetLoginUrl

function flickr_GetLoginSig frob, perms
   /*
   sorted_params=shared_secret+'api_key'+apikey+'frob'+frob_data+'permswrite';
   signature=hex_md5(sorted_params);
   
   -- shared_secret + 'api_key' + 'frob' + 'permswrite'
   */
   
   put cFlickrApiConsumerKey into paramArray["api_key"]
   put frob into paramArray["frob"]
   put perms into paramArray["perms"]
   
   put flickr_GetSignatureString(paramArray) into signatureString
   put text_Hash (signatureString, "sha1") into loginSig
   return loginSig
end flickr_GetLoginSig


--> Deps
-
function text_Hash someText, pWhichDigest
   local tHexDigest
   switch pWhichDigest
      case "sha1"
         put sha1digest (someText) into someBinaryData
         break
      default
         put md5digest (someText) into someBinaryData
   end switch
   get binarydecode("H*", someBinaryData, tHexDigest)
   return tHexDigest
end text_Hash 
