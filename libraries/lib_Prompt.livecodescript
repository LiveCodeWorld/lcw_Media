script "lib_Prompt"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Prompt
type: library
version: 0.1


--> Working on
-
function prompt_Domain
   return "prompt.vibefish.club"
end prompt_Domain



--> Prompt
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

function prompt_Fetch pSlug, pPromptDomain, pProtocol, pPort
   if pPromptDomain is empty then put prompt_Domain() into pPromptDomain
   
   put pageArray_Fetch (pPromptDomain, pSlug, pPort, pProtocol) into pageArray
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


--> Deps
-
