script "lib_Claude"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Claude
type: library
version: 0.1

/*Some help*/


--> Working on
-
command test_VisionData pImagePath
   if the shiftKey is "Down" then
      put image_Get (pImagePath) into sImage
      put image_ToDataImageUrl (sImage, "jpeg") into imageUrl
   else
      put "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg" into imageUrl
   end if
   
   -- put "What’s in this image?" into imageQuestion
   put "What's in this image?" into imageQuestion
   
   put openAI_VisionData (imageUrl, imageQuestion) into sData
   put imageUrl
end test_VisionData

function test_ClaudeImage
   /*
   "messages": [
   {"role": "user", "content": [
   {"type": "image", "source": {
   "type": "base64",
   "media_type": "'$IMAGE_MEDIA_TYPE'",
   "data": "'$IMAGE_BASE64'"
   }},
   {"type": "text", "text": "What is in the above image?"}
   ]}]
   */   
   
   if the shiftKey is "Down" then
      put image_Get() into sImage
      put image_ToDataImageUrl (sImage, "jpeg") into encodedImageData
      delete item 1 of encodedImageData
   else
      put "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg" into imageUrl
      -- put "https://upload.wikimedia.org/wikipedia/commons/a/a7/Camponotus_flavomarginatus_ant.jpg" into imageUrl
      
      put url imageUrl into sImage
      put base64Encode (sImage) into base64Image
      put textDecode (base64Image, "UTF-8") into encodedImageData
   end if
   
   
   put "image/jpeg" into mediaType
   put "What is in the above image?" into sText
   put claude_ImagePostData (encodedImageData, mediaType, sText) into postData
   
   -- return json_FromArray (postData, "", true)
   
   put claude_PostData (postData) into rData
   --
   return json_FromArray (rData, "", true)
end test_ClaudeImage

function test_Claude
   /*
   "max_tokens": 1024,
   "messages": [
   {"role": "user", "content": "Hello, Claude"}
   ]
   */
   
   put claude_ModelFromName("Haiku") into postData ["model"]
   -- put "claude-3-opus-20240229" into postData ["model"]
   put 1024 into postData ["max_tokens"]
   
   # Construct message data
   put "user" into postData ["messages"][1]["role"]
   put "Hello, Claude" into postData ["messages"][1]["content"]
   
   -- return json_FromArray (postData, "", true)
   put claude_PostData (postData) into rData
   return json_FromArray (rData, "", true)
   
   /*
   {
   "content": [
   {
   "text": "Hello! It's nice to meet you. How are you doing today?",
   "type": "text"
   }
   ],
   "id": "msg_01RqfQB1pVdPvHveNsXwLcL7",
   "model": "claude-3-opus-20240229",
   "role": "assistant",
   "stop_reason": "end_turn",
   "stop_sequence": null,
   "type": "message",
   "usage": {
   "input_tokens": 10,
   "output_tokens": 18
   }
   }
   */
end test_Claude

function claude_ImagePostData encodedImageData, mediaType, sText
   # Basics
   put claude_ModelFromName("Haiku") into postData ["model"]
   put 1024 into postData ["max_tokens"]
   
   # Construct message data
   put "user" into postData ["messages"][1]["role"]
   
   # Image content setup
   put "image" into postData ["messages"][1]["content"][1]["type"]
   put "base64" into postData ["messages"][1]["content"][1]["source"]["type"]
   put mediaType into postData ["messages"][1]["content"][1]["source"]["media_type"]
   put encodedImageData into postData ["messages"][1]["content"][1]["source"]["data"]
   
   # Text content setup
   put "text" into postData ["messages"][1]["content"][2]["type"]
   put sText into postData ["messages"][1]["content"][2]["text"]
   
   return postData
end claude_ImagePostData


--> Claude
-
function claude_ParseMessageReplyData rData
   /*
   {
   "content": [
   {
   "text": "Hello! How can I assist you today?",
   "type": "text"
   }
   ],
   "id": "msg_0139wuYfEirVM1bDiZ6mAcZX",
   "model": "claude-3-haiku-20240307",
   "role": "assistant",
   "stop_reason": "end_turn",
   "stop_sequence": null,
   "type": "message",
   "usage": {
   "input_tokens": 10,
   "output_tokens": 12
   }}*/
   
   # Content
   put rData ["content"]["text"] into rContentText
   put rData ["content"]["type"] into rContentType
   
   # Message
   put rData ["id"] into rMessageID
   put rData ["type"] into rType
   put rData ["stop_reason"] into stopReason
   
   # Useage
   put rData ["usage"] into usageArray
   
   return rContentText
end claude_ParseMessageReplyData


--> Claude | Api
-
function claude_ModelFromName modelName, pModelType
   if pModelType is empty then
      put "1P API" into pModelType
   end if
   
   put claude_ModelArray() into claude3ModelArray
   return claude3ModelArray [modelName][pModelType]
end claude_ModelFromName

function claude_ListModels
   put claude_ModelArray() into claude3ModelArray
   return keys (claude3ModelArray)
end claude_ListModels

function claude_ModelArray
   -- https://docs.anthropic.com/claude/docs/models-overview
   put "claude-3-opus-20240229" into claude3ModelArray ["Opus"]["1P API"]
   put "anthropic.claude-3-opus-20240229-v1:0"	into claude3ModelArray ["Opus"]["AWS Bedrock"]
   put "claude-3-opus@20240229" into claude3ModelArray ["Opus"]["Vertex AI"]
   
   put "claude-3-sonnet-20240229" into claude3ModelArray ["Sonnet"]["1P API"]
   put "anthropic.claude-3-sonnet-20240229-v1:0"	into claude3ModelArray ["Sonnet"]["AWS Bedrock"]
   put "claude-3-sonnet@20240229" into claude3ModelArray ["Sonnet"]["Vertex AI"]
   
   put "claude-3-haiku-20240307" into claude3ModelArray ["Haiku"]["1P API"]
   put "anthropic.claude-3-haiku-20240307-v1:0	"	into claude3ModelArray ["Haiku"]["AWS Bedrock"]
   put "claude-3-haiku-20240307" into claude3ModelArray ["Haiku"]["Vertex AI"]
   
   return claude3ModelArray
end claude_ModelArray

function claude_RestURL pRestBit
   put "https://api.anthropic.com/v1/messages" into restURL
   put pRestBit after restURL
   return restURL
end claude_RestURL

function claude_GetApiKey
   return secret_Get ("claudeAIApiKey")
end claude_GetApiKey

command claude_SetApiKey apiKey
   secret_Set "claudeAIApiKey", apiKey
end claude_SetApiKey


--> Private
-
private function claude_PostData postData, pRestBit
   put claude_RestURL (pRestBit) into restUrl
   
   # Decode postData to JSON
   put json_FromArray (postData) into postJSON
   put textDecode (postJSON, "UTF-8") into postJSON -- seems to cause an issue sometimes???
   
   # POST JSON
   set the cursor to watch
   set socketTimeoutInterval to 90000  --90 seconds
   claude_SetJsonHeaders
   post postJSON to url restUrl
   put it into utf8Json
   set socketTimeoutInterval to 10000  -- deafult
   
   # Encode JSON result to array
   put textEncode (utf8Json, "UTF-8") into rPageJson
   put json_ToArray (rPageJson) into rPageArray
   
   return rPageArray
end claude_PostData

private command claude_SetJsonHeaders
   /*
   --header "x-api-key: $ANTHROPIC_API_KEY" \
   --header "anthropic-version: 2023-06-01" \
   --header "content-type: application/json" \
   
   POST /v1/messages HTTP/1.1
   Host: api.anthropic.com
   User-Agent: curl/7.64.1
   x-api-key: [Your_Anthropic_API_Key]
   anthropic-version: 2023-06-01
   content-type: application/json
   Content-Length: [Length_of_the_Body_Content]
   */
   
   # JSON headers
   put "content-type: application/json; charset=utf-8" into someHeader
   put CR & "Accept: application/json" after someHeader
   
   # Version headers
   put CR & "anthropic-version:" && "2023-06-01" after someHeader
   
   # Claude xApiKey
   put claude_GetApiKey() into xApiKey
   put CR & "x-api-key:" && xApiKey after someHeader
   
   set the httpHeaders to someHeader
   return someHeader
end claude_SetJsonHeaders


--> Image
-
function image_Get pImagePath
   if pImagePath is empty then
      answer file "Choose an image..."
      if it is empty then return empty
      put it into pImagePath
   end if
   
   # Open the image file in binary mode
   put url ("binfile:/" & pImagePath) into sImage
   return sImage
   
   /*
   open file pImagePath for binary read
   if the result is not empty then
      return "Error, failed to open image file: " & the result
   end if
   
   # Read the entire content of the file
   read from file pImagePath until end
   close file pImagePath
   return it
   */
end image_Get

function image_GetBase64Encoded pImagePath
   put image_Get (pImagePath) into sImage
   
   # Encode the binary data to base64
   put base64Encode (sImage) into tBase64EncodedData
   
   # Return the base64-encoded string
   return tBase64EncodedData
end image_GetBase64Encoded


--> Private
-
private function _FetchResultData postData, restUrl
   put _FetchPostResult (postData, restUrl) into postResult
   put json_ToArray(postResult) into postData
   if postData is false then
      return postResult
   else
      return postData
   end if
end _FetchResultData

private function _FetchPostResult postData, restUrl
   put claude_GetApiKey() into apiKey
   -- put jsonrpc_PostArray (postData, restUrl, apiKey) into responseData
   put json_FromArray (postData) into postJSON
   put jsonrpc_POST (postJSON, restUrl, apiKey) into postResult
   return postResult
end _FetchPostResult

