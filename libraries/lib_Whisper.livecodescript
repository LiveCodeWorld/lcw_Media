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

command display_Magic pageSlug, wikiDomain
   put magic_Summarize (pageSlug, wikiDomain, "https") into pageArray
   display_PageArray pageArray, "Magic"
   return the result
end display_Magic


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


--> Magic | Working on
-
function magic_CreateMissingPageArray wikiDomain, pageSlug, pageTitle, valueArray
   # Check if page already exists!
   put wikiFile_Construct (wikiDomain, pageSlug) into pageJsonFile
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   
   # Create new pageArray
   if pageArray is an array then
      # Add Edit Tools
      _AddEditTools pageArray, valueArray
   else -- Create new pageArray
      # Notify
      lcw_Notify ("Creating ghost page for" && kwote (pageTitle))
      
      # Create wav
      breakpoint
      put transcribe_ConstructWavFile (pageSlug, wikiDomain) into wavFile
      transcribe_CreateWav oggFile, pageSlug, wikiDomain
      put the result into wavFile
      
      # Transcode audio
      if there is a file wavFile then         
         # Transcribe wav file
         put transcribe_TextFile (pageSlug, wikiDomain) into transcriptFile
         if there is not a file transcriptFile then
            lcw_Notify "Transcribing file using Whisper..."
            
            set the cursor to watch
            whisper_CreateTranscript wavFile
            get the result
         end if
         
         put transcribe_ConstructGraphAndSummaryFile (pageSlug, wikiDomain) into chatGptFile
         if there is a file chatGptFile then
            put wikiPage_GetGraphAndSummary (pageSlug, wikiDomain) into pageArray
         else
            lcw_Notify "Creating ghost-page using 'Graph and Summary' prompt for ChatGPT. This can take some time..."
            
            transcribe_CreateGraphAndSummary pageSlug, wikiDomain
            put the result into graphAndSummaryText
            put wikiPage_GetGraphAndSummary (pageSlug, wikiDomain, graphAndSummaryText) into pageArray
         end if
         
         # Add Edit Tools
         _AddEditTools pageArray, valueArray
      else
         put pageArray_Construct ("Error", "Converted wav file does not exist!", "markdown") into pageArray 
      end if
   end if
   --
   put valueArray ["folderPageTitle"] into folderPageTitle 
   curly_ReplacePageArray pageArray, "folderPageTitle", folderPageTitle
   --
   return pageArray
end magic_CreateMissingPageArray


--> Magic
-
function magic_CreateTranscript pageSlug
   put transcribe_ConstructWavFile (pageSlug) into wavFile
   
   # Transcode audio
   if there is a file wavFile then
      -- put whisper_GetTranscript (wavFile) into sTranscript
      whisper_CreateTranscript wavFile
      put the result into sTranscript
      put pageArray_Construct ("Transcript", sTranscript, "markdown") into pageArray 
   else
      put pageArray_Construct ("Error", "Converted wav file does not exist!", "markdown") into pageArray 
   end if
   return pageArray
end magic_CreateTranscript

function magic_ConvertToWav pageSlug, wikiDomain
   put transcribe_FindOggFile (pageSlug) into oggFile
   
   # Transcode audio
   transcribe_CreateWav oggFile, pageSlug, wikiDomain
   put the result into wavFile
   
   put pageArray_Construct ("Converted Audio", shellResult, "markdown") into pageArray
   return pageArray
end magic_ConvertToWav

function magic_Summarize pageSlug, wikiDomain, pProtocol, pPort
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
   put magic_Process (sTranscript, pageSlug, wikiDomain, pProtocol, pPort) into pageArray
   return pageArray
end magic_Summarize

function magic_Process sTranscript, pageSlug, wikiDomain, pProtocol, pPort
   if pProtocol is empty then
      put pageArray_Get (wikiDomain, pageSlug) into pageArray
   else
      put pageArray_Fetch (wikiDomain, pageSlug, pPort, pProtocol) into pageArray
   end if
   
   put prompt_Process (sTranscript, "graph-and-summary", "gpt-4") into mdText
   --
   wikiPage_ReplaceTranscriptSummary pageArray, mdText
   curly_ReplacePageArray pageArray, "folderPageTitle", pageTitle
   --
   return pageArray
end magic_Process

function magic_SummarizeCombined pageTitle, pageSlug, wikiDomian, tShortFolders
   put transcript_Combine (tShortFolders, wikiDomain) into sTranscript
   put wikiPage_CombinedTranscript (sTranscript, pageTitle, pageSlug, wikiDomian, tShortFolders) into pageArray
   return pageArray
end magic_SummarizeCombined

function magic_AddCred wikiDomain, pageSlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   pageArray_StripJournal pageArray
   pageArray_AddChatGptCred pageArray
   return pageArray
end magic_AddCred

function magic_TidyTranscript pageSlug, wikiDomain, pageTitle
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript   
   put wikiPage_CombinedTranscript (sTranscript, pageTitle, pageSlug, wikiDomian, pageTitle) into pageArray
   -- put _TidyPageArray (sTranscript) into pageArray
   return pageArray
end magic_TidyTranscript

function magic_Tidy wikiDomain, pageSlug, pageTitle
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      put "Page [[" & pageTitle & "]] already exists!" into someMarkdown
      put pageArray_Construct ("Eror", someMarkdown, "markdown") into pageArray
   else
      put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
      put pageTitle into tShortTitles
      put wikiPage_CombinedTranscript (sTranscript, pageTitle, pageSlug, wikiDomian, tShortTitles) into pageArray
   end if
   return pageArray
end magic_Tidy

function magic_TidyTranscript pageSlug, wikiDomain
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
   --
   if sTranscript is empty then
      put pageArray_Construct ("Error", "Transcript is empty?", "markdown") into pageArray 
   else
      put pageArray_Get (wikiDomain, pageSlug) into pageArray
      transcript_AddTidied pageArray, sTranscript, pPromptSlug
   end if
   --
   return pageArray
end magic_TidyTranscript


--> Transcript
-
function transcript_ConstructPageArray pageSlug, wikiDomain, pageTitle
   put pageTitle && "Transcript" into dTitle
   --
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
   put pageArray_Construct (dTitle, sTranscript) into pageArray
   return pageArray
end transcript_ConstructPageArray


--> Prompty
-
function prompt_Process userText, promptSlug, pModel
   put prompt_Get (promptSlug) into sPrompt
   put openAI_FetchChatData (userText, sPrompt, pModel) into rData
   if item 1 of rData is "Error" then
      wikiServer_Restart true, rData
      return rData
   else
      put rData ["choices"][1]["message"]["content"] into sText
      return sText
   end if
end prompt_Process

function prompt_List
   put prompt_Domain() into promptDomain
   put fedwiki_ListSitemapTitles (promptDomain) into pTitles
   --
   filter pTitles without "* Template"
   line_Delete "Edit Page", pTitles
   line_Delete "Welcome Visitors", pTitles
   --
   sort pTitles
   return pTitles
end prompt_List

function prompt_Fetch pageSlug, pProtocol, pPort
   put prompt_Domain() into wikiDomain
   put pageArray_Fetch (wikiDomain, pageSlug, pPort, pProtocol) into pageArray
   --
   put pageArray_SectionOrCode (pageArray) into sPrompt
   return sPrompt
end prompt_Fetch

function prompt_Get pageSlug
   put prompt_Domain() into promptDomain
   put pageArray_Get (promptDomain, pageSlug) into pageArray
   --
   put pageArray_SectionOrCode (pageArray) into sPrompt
   return sPrompt
end prompt_Get

function pageArray_SectionOrCode pageArray
   put pageArray_GetFirstCode (pageArray) into sPrompt
   if sPrompt is empty then
      put pageArray_GetSectionText (pageArray, "Prompt") into sPrompt
   end if
   return sPrompt
end pageArray_SectionOrCode

function prompt_Domain
   return "prompt.vibefish.club"
end prompt_Domain


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
   display_Xterm someShell, pXtermBrowser
   --
   set the defaultfolder to oFolder
   return whisperFolder
end whisper_Transcribe


--> Private
-
private function _ShellResult someShell, whisperFolder
   put the defaultfolder into oFolder
   set the defaultfolder to whisperFolder
   put shell (someShell) into shellResult
   set the defaultfolder to oFolder
   return shellResult
end _ShellResult
