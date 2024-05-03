script "lib_Transcribe"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Transcribe
type: library
version: 0.2

/*
*/


--> Working on
-

--> Move
-
command wikiServer_Restart pNotify, pNotifyText
   if pNotify is not false then
      if pNotifyText is empty then put "Restarted wiki server!" into pNotifyText
      lcw_Notify pNotifyText
   end if
   
   put view_GetTemplateObject ("View|Wiki|Server") into serverObject
   set the daemon_IsRunning of serverObject to false
   set the daemon_IsRunning of serverObject to true
   return serverObject
end wikiServer_Restart


--> Transcribe
-
command transcribe_AddTidied @pageArray, sTranscript, pTidySlug, pNotify
   if pTidySlug is empty then put "tidy-hitchhikers" into pTidySlug
   
   if pNotify is not false then
      lcw_Notify "Using ChatGPT and the 'Tidy Hitchhikers' prompt to tidy the original transcript."
   end if
   put openAI_GetText (sTranscript, pTidySlug, "gpt-4") into tidiedTranscript -- better if included in "graph-and-summary"
   
   switch
      case item 1 of tidiedTranscript is "Error"
         if pNotify is not false then
            lcw_Notify tidiedTranscript
         end if
         break
      case tidiedTranscript is empty
         if pNotify is not false then
            lcw_Notify "ChatGPT tidied transcript is empty!."
         end if
         break
   end switch
   
   local storyArray
   storyArray_AddItemArray storyArray, "markdown", "# Tidied Transcript" 
   storyArray_AddItemArray storyArray, "markdown", tidiedTranscript 
   pageArray_AddSection pageArray, storyArray, "Tidied Transcript", "Summary"
   
   /*
   # Add Tidied Transcript
   pageArray_AddMarkdown pageArray, "# Tidied Transcript"
   pageArray_AddMarkdown pageArray, tidiedTranscript
   */
end transcribe_AddTidied

function transcribe_GetWavText pageSlug, pTranscriptDomain
   put transcribe_TextFile (pageSlug, pTranscriptDomain) into textFile
   if textFile is empty then return empty
   
   put url ("file:" & textFile) into sTranscript
   
   # Tidy
   replace "[BLANK_AUDIO]" with empty in sTranscript
   return word 1 to -1 of sTranscript
end transcribe_GetWavText

function transcribe_GetGraphAndSummaryText pageSlug, pTranscriptDomain
   -- was "transcribe_GetGptText"
   put transcribe_GraphAndSummaryFile (pageSlug, pTranscriptDomain) into textFile
   put url ("file:" & textFile) into graphAndSummaryText
   return word 1 to -1 of graphAndSummaryText
end transcribe_GetGraphAndSummaryText

function transcribe_GraphAndSummaryFile pageSlug, pTranscriptDomain
   put transcribe_ConstructGraphAndSummaryFile (pageSlug, pTranscriptDomain) into chatGptFile
   if there is a file chatGptFile then
      return chatGptFile
   else
      return empty
   end if
end transcribe_GraphAndSummaryFile


--> Transcribe | Edit
-
function transcribe_EditPage lastPageSlug, wikiDomain
   /*
   Used by "get_EditPage" in case "transcript.thought.garden"
   */
   
   # Fetch dialogue from "dialogue.fedwiki.org"
   put wikiPage_Dialogue (lastPageSlug, wikiDomain, "transcription-dialogue", "Transcribe Page") into editPageArray
   
   # Add Create Section
   wikiPage_AddCreateButtons editPageArray, wikiDomain, lastPageSlug
   
   # Add Transporter Section
   wikiPage_AddTransporters editPageArray
   
   return editPageArray
end transcribe_EditPage


--> Transcribe
-
command transcribe_CreateGraphAndSummary pageSlug, wikiDomain
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
   put openAI_GetText (sTranscript, "graph-and-summary", "gpt-4") into graphAndSummaryText
   --
   put transcribe_ConstructGraphAndSummaryFile (pageSlug, wikiDomain) into chatGptFile
   text_Set chatGptFile, graphAndSummaryText
   --
   return graphAndSummaryText
end transcribe_CreateGraphAndSummary

function transcribe_ConstructSummaryStoryArray mdText
   local storyArray
   
   # Add Summary Section
   storyArray_AddItemArray storyArray, "markdown", "# Summary"
   put markdown_GetSection (mdText) into summarySection
   storyArray_AddItemArray storyArray, "markdown", summarySection
   
   # Add Keyword Section
   put markdown_GetSection (mdText, "Keywords") into keyWordSection
   storyArray_AddItemArray storyArray, "markdown", keyWordSection
   
   # Add Graph Section
   put markdown_GetSection (mdText, "Graph", mdText) into graphSection
   put line 1 of graphSection into graphTitle
   storyArray_AddItemArray storyArray, "markdown", graphTitle
   --
   put line 2 to -1 of graphSection into pDot
   if char 1 to 3 of pDot = "```" then delete char 1 to 3 of pDot
   storyArray_AddGraphviz storyArray, pDot, pDot
   if char -3 to -1 of pDot = "```" then delete char -3 to -1 of pDot
   
   return storyArray
end transcribe_ConstructSummaryStoryArray

function transcribe_ConstructGraphAndSummaryFile pageSlug, pTranscriptDomain
   put transcribe_PageAssetFolder (pageSlug, pTranscriptDomain) into wavFolder
   put wavFolder & "chatgpt.txt" into chatGptFile
   return chatGptFile
end transcribe_ConstructGraphAndSummaryFile
   
command transcribe_CreateWav oggFile, pageSlug, wikiDomain
   put transcribe_ConstructWavFile (pageSlug, wikiDomain) into wavFile
   if there is a file wavFile then
      -- return "Error, file already exists:" && wavFile
      return wavFile
   else
      set the cursor to watch
      ffmpeg_ExportAudioAsWav oggFile, wavFile
      put the result into shellResult
      return wavFile
   end if
end transcribe_CreateWav

function transcribe_FindOggFile pageSlug, pTranscriptDomain
   if pTranscriptDomain is empty then
      put "transcript.thought.garden" into pTranscriptDomain
   end if
   put transcribe_FindAudioUrl (pageSlug, pTranscriptDomain) into audioURL
   put _AudioFileFromUrl (audioURL) into audioFile
   return audioFile
end transcribe_FindOggFile

function transcribe_FindAudioUrl pageSlug, pTranscriptDomain
   -- for now this is fixed
   if pTranscriptDomain is empty then
      put "transcript.thought.garden" into pTranscriptDomain
   end if
   put pageArray_Get (pTranscriptDomain, "astral-thoughts") into pageArray
   
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   put "[[" & pageTitle & "]]" into sText
   --
   put pageArray_FindItemOfType (sText, "audio", pageArray) into itemNum
   put pageArray ["story"][itemNum]["text"] into audioText
   --
   get line 1 of audioText
   put URLDecode (it) into audioURL
   return audioURL
end transcribe_FindAudioUrl

function transcribe_AudioFile wikiDomain, pageSlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   put pageArray_GetFirstItemValue (pageArray, "audio", "text") into audioText
   put line 1 of audioText into audioURL
   
   -- http://thought.garden/assets/astral-thoughts/023_astral-intelligence.ogg
   set the itemdelimiter to slash
   put item 5 to -1 of audioURL into relPath
   put item 3 of audioURL into wikiDomain
   --
   put wikiFile_ConstructAsset (relPath, wikiDomain) into audioFile
   if there is a file audioFile then
      return audioFile
   else
      return empty
   end if
end transcribe_AudioFile

function transcribe_TextFile pageSlug, pTranscriptDomain
   put transcribe_ConstructWavFile (pageSlug, pTranscriptDomain) into wavFile
   put wavFile & ".txt" into textFile
   if there is a file textFile then
      return textFile
   else
      return empty
   end if
end transcribe_TextFile

function transcribe_WavURL pageSlug, pTranscriptDomain
   if pTranscriptDomain is empty then
      put "transcript.thought.garden" into pTranscriptDomain
   end if
   put transcribe_ShortAudioFile (pageSlug) into shortFile
   put merge ("http://[[pTranscriptDomain]]/assets/[[pageSlug]]/[[shortFile]]") into wavURL
   return wavURL
end transcribe_WavURL

function transcribe_WavFile pageSlug, pTranscriptDomain
   put transcribe_ConstructWavFile (pageSlug, pTranscriptDomain) into wavFile
   if there is a file wavFile then
      return wavFile
   else
      return empty
   end if
end transcribe_WavFile

function transcribe_ConstructRawAudioFile audioPageSlug, folderPageSlug, pTranscriptDomain, pFileExt
   put fedwiki_ConstructTitle (audioPageSlug) into audioPageTitle
   --
   put transcribe_ShortAudioFile (audioPageTitle, pFileExt) into shortFile
   put transcribe_PageAssetFolder (folderPageSlug, pTranscriptDomain) into audioFolder
   put audioFolder & shortFile into audioFile
   return audioFile
end transcribe_ConstructRawAudioFile

function transcribe_ConstructWavFile pageSlug, pTranscriptDomain
   put transcribe_ConstructAudioFile (pageSlug, "wav", pTranscriptDomain) into wavFile
   return wavFile
end transcribe_ConstructWavFile

function transcribe_ConstructAudioFile pageSlug, pFileExt, pTranscriptDomain
   put transcribe_ShortAudioFile (pageSlug, pFileExt) into shortFile
   put transcribe_PageAssetFolder (pageSlug, pTranscriptDomain) into wavFolder
   put wavFolder & shortFile into audioFile
   return audioFile
end transcribe_ConstructAudioFile

function transcribe_ShortAudioFile pageSlug, pFileExt
   if pFileExt is empty then put "wav" into pFileExt
   --
   put pageSlug & "." & pFileExt into shortFile
   return shortFile
end transcribe_ShortAudioFile

function transcribe_PageAssetFolder pageSlug, pTranscriptDomain
   put transcribe_ConstructPageAssetFolder (pageSlug, pTranscriptDomain) into pageAssetFolder
   folder_CreateNested pageAssetFolder
   return pageAssetFolder
end transcribe_PageAssetFolder

function transcribe_ConstructPageAssetFolder pageSlug, pTranscriptDomain
   if pTranscriptDomain is empty then
      put "transcript.thought.garden" into pTranscriptDomain
   end if
   
   put wikiFile_ConstructAsset (pageSlug, pTranscriptDomain) into pageAssetFolder
   text_AddTrailing pageAssetFolder, slash
   return pageAssetFolder
end transcribe_ConstructPageAssetFolder

function transcribe_WavFromOgg oggFile
   set the itemdelimiter to "."
   put "wav" into item -1 of oggFile
   return oggFile
end transcribe_WavFromOgg


--> Private
-
private function _AudioFileFromUrl audioURL
   -- http://thought.garden/assets/astral-thoughts/023_astral-intelligence.ogg
   set the itemdelimiter to slash
   put item 5 to -1 of audioURL into relPath
   put item 3 of audioURL into wikiDomain
   --
   put wikiFile_ConstructAsset (relPath, wikiDomain) into audioFile
   if there is a file audioFile then
      return audioFile
   else
      return empty
   end if
end _AudioFileFromUrl
