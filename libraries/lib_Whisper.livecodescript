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
*/


--> Working on
-
command launch_WhisperHelp
   launch url "https://github.com/ggerganov/whisper.cpp"
end launch_WhisperHelp


--> Whisper
-


--> OpenAI
-
function openAI_FetchSpeech someText
   if someText is empty then
      put "Thanks for all the Fish!" into someText
   end if
   
   -- put "tts-1" into postData ["model"]
   put "tts-1-hd" into postData ["model"]
   put someText into postData ["input"]
   put "alloy" into postData ["voice"]
   
   put "https://api.openai.com/v1/audio/speech" into restURL
   put openAI_GetApiKey() into apiKey
   --
   -- put jsonrpc_PostArray (postData, restUrl, apiKey) into responseData
   put json_FromArray (postData) into postJSON
   put jsonrpc_POST (postJSON, restUrl, apiKey) into someAudio
   --
   -- put textEncode (someAudio, "UTF-8") into someAudio
   put the tempname & ".mp3" into audioFile
   put someAudio into url ("binfile:" & audioFile)
   --
   return audioFile
end openAI_FetchSpeech

function openAI_GetApiKey
   return secret_Get ("openAIApiKey")
end openAI_GetApiKey

command openAI_SetApiKey apiKey
   secret_Set "openAIApiKey", apiKey
end openAI_SetApiKey
