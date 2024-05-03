script "lib_Whisper"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Whisper
type: library
version: 0.1

/*
See Global | Whisper | Install | Menu

/*
--output-txt        [false  ] output result in a text file
-ovtt,     --output-vtt        [false  ] output result in a vtt file
-osrt,     --output-srt        [false  ] output result in a srt file
-olrc,     --output-lrc        [false  ] output result in a lrc file
-owts,     --output-words      [false  ] output script for generating karaoke video
-fp,       --font-path         [/System/Library/Fonts/Supplemental/Courier New Bold.ttf] path to a monospace font for karaoke video
-ocsv,     --output-csv        [false  ] output result in a CSV file
-oj,       --output-json       [false  ] output result in a JSON file
-ojf,      --output-json-full  [false  ] include more information in the JSON file
-of FNAME, --output-file FNAME [       ] output file path (without file extension)
*/
*/

--> Move
-
command launch_WhisperHelp
   launch url "https://github.com/ggerganov/whisper.cpp"
end launch_WhisperHelp

function platform_GetPrompt pageSlug
   put pageArray_Get ("prompt.platform.earth", pageSlug) into pageArray
   put pageArray_GetSectionText (pageArray, "Prompt") into sPrompt
   if sPrompt is empty then
      breakpoint
      put pageArray_GetFirstCode (pageArray) into sPrompt
   end if
   return sPrompt
end platform_GetPrompt


--> Working on
-
function whisper_AssetFolder
   put project_GetFolder ("lcw_Media") into projectFolder
   put module_GetFolder ("View_Audio", projectFolder) into moduleFolder
   put asset_GetFolder (moduleFolder, "whisper.cpp/") into whisperFolder
   return whisperFolder
end whisper_AssetFolder

function whisper_DefaultAudioFile whisperFolder
   put whisperFolder & "samples/jfk.wav" into audioFile
   return audioFile
end whisper_DefaultAudioFile


--> Whisper
-
function whisper_GetTranscript wavFile
   whisper_CreateTranscript wavFile
   return the result
end whisper_GetTranscript

command whisper_CreateTranscript wavFile
   put whisper_AssetFolder() into whisperFolder
   if there is not a folder whisperFolder then return "Error, Whisper folder does not exist:" && whisperFolder
   
   if wavFile is empty then put whisper_DefaultAudioFile (whisperFolder) into wavFile
   if there is not a file wavFile then
      return "Error, audio file does not exist:" && audioFile
   end if
   --
   put "./main -m models/ggml-small.bin" into someShell
   put " --output-txt" after someShell
   put " -ojf" after someShell
   put " -f" && kwote (wavFile) after someShell
   --
   put _ShellResult (someShell, whisperFolder) into shellResult
   return shellResult
end whisper_CreateTranscript

command whisper_Transcribe audioFile, pXtermBrowser
   put whisper_AssetFolder() into whisperFolder
   if there is not a folder whisperFolder then
      return "Error, Whisper folder does not exist:" && whisperFolder
   end if
   
   if audioFile is empty then
      put whisperFolder & "samples/jfk.wav" into audioFile
   end if
   if there is not a file audioFile then
      return "Error, audio file does not exist:" && audioFile
   end if
   
   put "./main -m models/ggml-small.bin -f" && kwote (audioFile) into someShell
   
   put the defaultfolder into oFolder
   set the defaultfolder to whisperFolder
   --
   -- put shell (someShell) into shellResult
   -- ttyd_Paste someShell, xtermView
   display_Xterm pXtermBrowser, someShell
   --
   set the defaultfolder to oFolder
   return whisperFolder
end whisper_Transcribe


--> OpenAI | Image
-
command openAI_CreateImage sPrompt
   if sPrompt is empty then
      put "a white siamese cat" into sPrompt
   end if
   
   put openAI_GenerateImageArray (sPrompt) into imageArray
   -- return json_FromArray (imageArray, "", true)
   -- display_Data imageArray
   
   openAI_DeconstructImageArray imageArray, sImage, revisedPrompt
   --
   display_Image sImage, sPrompt
   put the result into imageObject
   --
   set the revised_Prompt of imageObject to revisedPrompt
   set the image_Prompt of imageObject to sPrompt
   --
   return revisedPrompt
end openAI_CreateImage

function openAI_GenerateImageArray sPrompt, pImageDimensions
   /*
   The image generations endpoint allows you to create an original image given a text prompt. 
   When using DALL·E 3, images can have a size of 1024x1024, 1024x1792 or 1792x1024 pixels.
   By default, images are generated at standard quality, but when using DALL·E 3 you can set quality: "hd" for enhanced detail. 
   Square, standard quality images are the fastest to generate.
   */
   
   put "https://api.openai.com/v1/images/generations" into restURL
   if pImageDimensions is empty then
      put "1024x1024" into pImageDimensions
   end if
   
   # Image content setup
   put "dall-e-3" into postData ["model"]
   put sPrompt into postData ["prompt"]
   put 1 into postData ["n"]
   put pImageDimensions into postData ["size"]
   put "b64_json" into postData ["response_format"]
   
   # Fetch
   put _FetchPostData (postData, "images/generations") into imageArray
   return imageArray
end openAI_GenerateImageArray

command openAI_DeconstructImageArray imageArray, @sImage, @revisedPrompt
   put imageArray ["data"][1]["revised_prompt"] into revisedPrompt
   put imageArray ["data"][1]["url"] into imageURL
   put imageArray ["data"][1]["b64_json"] into base64image
   put base64Decode (base64image) into sImage
   
   return sImage
end openAI_DeconstructImageArray

function openAI_VisionData imageUrl, imageQuestion, pTemp
   # Basics
   put "" into sPrompt
   put "" into pUserText
   put _ConstructMessagePostData (pUserText, sPrompt, "gpt-4-turbo", pTemp, 300) into postData
   
   # Image content setup
   put "user" into postData ["messages"][1]["role"]
   put "text" into postData ["messages"][1]["content"][1]["type"]
   put imageQuestion into postData ["messages"][1]["content"][1]["text"]
   --
   put "image_url" into postData ["messages"][1]["content"][2]["type"]
   put imageUrl into postData ["messages"][1]["content"][2]["image_url"]["url"]
   
   -- return json_FromArray (postData, "", true)
   
   # Fetch Vision Data
   put _FetchPostData (postData, "chat/completions") into rData
   --
   -- return json_FromArray (rData, "", true)
   display_Data rData
   return rData
end openAI_VisionData


--> OpenAI
-
command openAI_TextToSpeech someText, pAudioFile, pWhisperVoice, pUseHD
   if pWhisperVoice is empty then put "alloy" into pWhisperVoice
   if someText is empty then put "Thanks for all the Fish!" into someText   
   if pUseHD is not false then
      put "tts-1-hd" into postData ["model"]
   else
      put "tts-1" into postData ["model"]
   end if
   if pAudioFile is empty then put the tempname & ".mp3" into pAudioFile
   
   # Construct postData
   put someText into postData ["input"]
   put pWhisperVoice into postData ["voice"]
   put "https://api.openai.com/v1/audio/speech" into restURL
   
   # Create and Fetch audio
   put _FetchPostResult (postData, restUrl) into someAudio
   -- put textEncode (someAudio, "UTF-8") into someAudio
   
   # Create audio file
   put someAudio into url ("binfile:" & pAudioFile)
   --
   return pAudioFile
end openAI_TextToSpeech

function openAI_GetChatResponse promptSlug, wikiDomain, pageSlug, pModel
   put wikiPage_GetText (wikiDomain, pageSlug) into userText
   
   # Get ChatGPT reply
   put openAI_GetText (userText, promptSlug, pModel) into sText
   return sText
end openAI_GetChatResponse

function openAI_GetText userText, promptSlug, pModel
   put platform_GetPrompt (promptSlug) into sPrompt
   put openAI_FetchChatData (userText, sPrompt, pModel) into rData
   if item 1 of rData is "Error" then
      wikiServer_Restart true, rData
      return rData
   else
      put rData ["choices"][1]["message"]["content"] into sText
      return sText
   end if
end openAI_GetText

function openAI_Chat pUserText, pSystemPrompt, pModel, pTemp, pMaxTokens, pTopP
   put openAI_FetchChatData (pUserText, pSystemPrompt, pModel, pTemp, pMaxTokens, pTopP) into postData
   if postData is not an array then
      -- display_Data postData
      return empty
   else
      put postData ["choices"][1]["message"]["content"] into chatReply
      return chatReply
   end if
end openAI_Chat


--> Whisper
-
function openAI_ListModels
   /*
   babbage-002
   dall-e-2
   dall-e-3
   davinci-002
   gpt-3.5-turbo
   gpt-3.5-turbo-0301
   gpt-3.5-turbo-0613
   gpt-3.5-turbo-1106
   gpt-3.5-turbo-16k
   gpt-3.5-turbo-16k-0613
   gpt-3.5-turbo-instruct
   gpt-3.5-turbo-instruct-0914
   gpt-4
   gpt-4-0125-preview
   gpt-4-0613
   gpt-4-1106-preview
   gpt-4-turbo-preview
   gpt-4-vision-preview
   text-embedding-3-large
   text-embedding-3-small
   text-embedding-ada-002
   tts-1
   tts-1-1106
   tts-1-hd
   tts-1-hd-1106
   whisper-1
   */
   
   put openAI_GetApiKey() into apiKey
   put openAI_RestURL ("models") into restUrl
   put jsonrpc_GetArray (restURL, apiKey) into rData
   put rData ["data"] into indexArray
   --
   -- display_Data rData
   repeat with itemNum = 1 to item 2 of the extents of indexArray
      put indexArray [itemNum]["id"] into modelName
      put modelName & CR after modelNames
   end repeat
   delete char -1 of modelNames
   sort modelNames
   return modelNames
end openAI_ListModels

function openAI_FetchChatData pUserText, pSystemPrompt, pModel, pTemp, pMaxTokens, pTopP
   if pTemp is empty then put 0.7 into pTemp
   if pUserText is empty then put "Hello!" into pUserText
   if pSystemPrompt is empty then put "You are a helpful assistant." into pSystemPrompt
   
   put _ConstructMessagePostData (pUserText, pSystemPrompt, pModel, pTemp, pMaxTokens, pTopP) into postData
   put _FetchPostData (postData, "chat/completions") into rData
   switch
      case rData ["error"] is an array
         put rData ["error"]["message"] into sError
         return "Error," && sError
      case rData is not an array
         if postResult is empty then
            return "Error, postJSON is empty." & CR & postJSON
         else
            return "Error, postResult is empty." & CR & postResult
         end if
      default
         return rData
   end switch
end openAI_FetchChatData

function openAI_FetchChatJson pUserText, pSystemPrompt, pModel, pTemp, pMaxTokens, pTopP
   if pUserText is empty then put "Hello!" into pUserText
   if pSystemPrompt is empty then put "You are a helpful assistant designed to output JSON" into pSystemPrompt
   
   if pSystemPrompt contains "JSON" is false then return "Error, system prompt must contina the word JSON."
   put "json_object" into postData ["response_format"]["type"]
   
   if pModel is empty then
      put "gpt-4-turbo-preview" into pModel
      -- put "gpt-4" into pModel
   end if
   
   if pTemp is empty then put 0.7 into pTemp
   put pTemp into postData ["temperature"]
   
   /*
   if pMaxTokens is empty then put 64 into pMaxTokens
   put pMaxTokens into postData ["max_tokens"]
   if pTopP is empty then put 1 into pTopP
   put pTopP into postData ["top_p"]   --
   */
   
   put openAI_RestURL ("chat/completions") into restUrl
   --
   put pModel into postData ["model"]
   --
   put "system" into postData ["messages"][1]["role"]
   put pSystemPrompt into postData ["messages"][1]["content"]
   --
   put "user" into postData ["messages"][1]["role"]
   put pUserText into postData ["messages"][1]["content"]
   --
   put _FetchResultData (postData, restUrl) into postData
   return postData
end openAI_FetchChatJson

function openAI_RestURL pRestBit
   put "https://api.openai.com/v1/" into restURL
   put pRestBit after restURL
   return restURL
end openAI_RestURL

function openAI_GetApiKey
   return secret_Get ("openAIApiKey")
end openAI_GetApiKey

command openAI_SetApiKey apiKey
   secret_Set "openAIApiKey", apiKey
end openAI_SetApiKey


--> Private
-
function _ParseVisionData
   /*
   {
   "choices": [
   {
   "finish_reason": "stop",
   "index": 0,
   "logprobs": null,
   "message": {
   "content": "This image depicts a serene natural landscape featuring a wooden boardwalk extending through a vibrant green field. The field is lush, filled with tall grasses that sway gently, and is bordered by dense foliage. The sky above is expansive and clear with some speckled clouds, contributing to the overall picturesque and tranquil atmosphere. This scene is indicative of a well-preserved natural reserve or a rural area designed for leisure walks and nature observation.",
   "role": "assistant"
   }
   }
   ],
   "created": 1713972474,
   "id": "chatcmpl-9HYpGOcy2GUm3tW7LfEgAm7fifbGm",
   "model": "gpt-4-turbo-2024-04-09",
   "object": "chat.completion",
   "system_fingerprint": "fp_67e6987839",
   "usage": {
   "completion_tokens": 86,
   "prompt_tokens": 1118,
   "total_tokens": 1204
   }
   }
   */
end _ParseVisionData

private function _ConstructMessagePostData pUserText, pSystemPrompt, pModel, pTemp, pMaxTokens, pTopP
   if pModel is empty then
      -- put "gpt-4" into pModel
      put "gpt-4-turbo" into pModel
   end if
   
   if pTemp is not empty then
      put pTemp into postData ["temperature"]
   end if
   if pMaxTokens is not empty then
      put pMaxTokens into postData ["max_tokens"]
   end if
   if pTopP is not empty then
      --  put 1 into pTopP
      put pTopP into postData ["top_p"]
   end if
   
   put pModel into postData ["model"]
   
   # System Prompt (option)
   put 1 into indexNum
   if pSystemPrompt is not empty then
      put "system" into postData ["messages"][indexNum]["role"]
      put pSystemPrompt into postData ["messages"][indexNum]["content"]
      add 1 to indexNum
   end if
   
   # UserText
   if pUserText is not empty then
      put "user" into postData ["messages"][indexNum]["role"]
      put pUserText into postData ["messages"][indexNum]["content"]
   end if
   --
   return postData
end _ConstructMessagePostData

private function _FetchPostData postData, restPath
   put openAI_RestURL (restPath) into restUrl
   
   put openAI_GetApiKey() into apiKey
   put json_FromArray (postData) into postJSON
   
   # Here we could try tsNet to make it more reliable
   set the cursor to watch
   set socketTimeoutInterval to 120000  --120 seconds
   put jsonrpc_POST (postJSON, restUrl, apiKey) into postResult
   set socketTimeoutInterval to 10000  -- default
   
   # Process result
   put json_ToArray (postResult) into rData
   return rData
end _FetchPostData

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
   put openAI_GetApiKey() into apiKey
   -- put jsonrpc_PostArray (postData, restUrl, apiKey) into responseData
   put json_FromArray (postData) into postJSON
   -- put postJSON
   put jsonrpc_POST (postJSON, restUrl, apiKey) into postResult
   return postResult
end _FetchPostResult

private function _ShellResult someShell, whisperFolder
   put the defaultfolder into oFolder
   set the defaultfolder to whisperFolder
   put shell (someShell) into shellResult
   set the defaultfolder to oFolder
   return shellResult
end _ShellResult
