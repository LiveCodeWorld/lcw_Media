script "lib_Ffmpeg"
--> MetaData
-
license: GPLv3
name: lib_Ffmpeg
type: library
version: 0.1


--> ffmpeg
-
command ffmpeg_SplitVideo someVideoFile, sSeconds, eSeconds, pExportFileName, pMakeAccurate
   file_Deconstruct someVideoFile, someRoot, shortName, fileExtension
   if pExportFileName is empty then 
      put someRoot & "/" & shortName & "_trimmed." & fileExtension into pExportFileName
      put pExportFileName into pExportFilePath
   end if
   --
   put ffmpeg_ConstructSplitVideoShell (someVideoFile, sSeconds, eSeconds, pExportFileName, pMakeAccurate) into someShell
   put someShell
   --
   set the cursor to watch
   put shell (someShell) into shellResult
   return shellResult
end ffmpeg_SplitVideo

function ffmpeg_ConstructSplitVideoShell someVideoFile, sSeconds, eSeconds, exportFileName, pMakeAccurate
   shell_BashParamEscape someVideoFile
   shell_BashParamEscape exportFileName
   --
   put "ffmpeg" into someShell
   if pMakeAccurate is true then
      put space & "-i" && someVideoFile after someShell
      put space & "-ss" && sSeconds after someShell -- fastest if first
   else
      put space & "-ss" && sSeconds after someShell -- fastest if first
      put space & "-i" && someVideoFile after someShell
   end if
   --
   put eSeconds - sSeconds into dSeconds
   put space & "-t" && dSeconds after someShell
   -- put space & "-to" && eSeconds after someShell
   --
   put space & "-c copy" after someShell -- keeps codecs the same and avoids reencoding
   put space & exportFileName after someShell
   --
   return someShell
end ffmpeg_ConstructSplitVideoShell

command ffmpeg_TrimVideo someVideoFile, sTime, cDuration
   set the cursor to watch
   file_Deconstruct someVideoFile, someRoot, shortName, fileExtension
   put someRoot & "/" & shortName & "_trimmed." & fileExtension into exportFileName
   put exportFileName into exportedVideoPath
   
   shell_BashParamEscape someVideoFile
   shell_BashParamEscape exportFileName
   
   put "ffmpeg -i" && someVideoFile into someShell
   put space & "-ss" && sTime && "-t" && cDuration after someShell
   put space & "-c:a copy" after someShell -- keeps the audio codec the same
   put space & exportFileName after someShell
   
   put shell (someShell) into shellResult
   put line -1 of shellResult into fileBit
   if fileBit ends with "Overwrite ? [y/N] Not overwriting - exiting" then
      -- File '/Users/.../.mp4' already exists. Overwrite ? [y/N] Not overwriting - exiting
      return empty
   else
      return exportedVideoPath
   end if
end ffmpeg_TrimVideo


--> YouTube
-
function youtube_DownloadVideo pTestUrl, pDownloadFolder
   if pTestUrl is empty then
      put "https://www.youtube.com/watch?v=ns-qtoxnAS8" into testUrl
      put opn_Ask ("Enter a YouTube video url...", testUrl) into pTestUrl
   end if
   
   if pDownloadFolder is empty then
      put specialFolderPath("Desktop") into pDownloadFolder
   end if
   folder_Format pDownloadFolder
   put the defaultfolder into oFolder
   set the defaultfolder to pDownloadFolder
   
   set the cursor to watch
   put youtube_ConstructDownloadShell (pTestUrl) into someShell
   put shell (someShell) into shellResult
   
   youtube_DownloadParseShellResult shellResult, shortDownloadedFile
   put pDownloadFolder & shortDownloadedFile into downloadedFile
   set the defaultfolder to oFolder
   return downloadedFile
end youtube_DownloadVideo

command youtube_DownloadParseShellResult shellResult, @shortDownloadedFile
   /*
   [youtube] ns-qtoxnAS8: Downloading webpage
   [youtube] ns-qtoxnAS8: Downloading video info webpage
   [youtube] ns-qtoxnAS8: Extracting video information
   [youtube] ns-qtoxnAS8: Searching for annotations.
   [youtube] ns-qtoxnAS8: Downloading MPD manifest
   [info] Writing video description to: Paddy's Lamentation - Gangs of New York (6_12) Movie CLIP (2002) HD-ns-qtoxnAS8.description
   [info] Writing video annotations to: Paddy's Lamentation - Gangs of New York (6_12) Movie CLIP (2002) HD-ns-qtoxnAS8.annotations.xml
   [info] Writing video description metadata as JSON to: Paddy's Lamentation - Gangs of New York (6_12) Movie CLIP (2002) HD-ns-qtoxnAS8.info.json
   [download] Destination: Paddy's Lamentation - Gangs of New York (6_12) Movie CLIP (2002) HD-ns-qtoxnAS8.mp4
   [download]   0.0% of 33.43MiB at Unknown speed ETA Unknown ETA
   [download]   0.0% of 33.43MiB at 138.07KiB/s ETA 04:08
   [download]   0.0% of 33.43MiB at 316.21KiB/s ETA 
   */
   
   -- [download] Destination: Paddy's Lamentation - Gangs of New York (6_12) Movie CLIP (2002) HD-ns-qtoxnAS8.mp4
   set the wholematches to false
   put lineoffset ("[download] Destination: ", shellResult) into lineNum
   put line lineNum of shellResult into downloadLine
   set the itemdelimiter to ":"
   delete item 1 of downloadLine
   put word 1 to -1 of downloadLine into shortDownloadedFile
end youtube_DownloadParseShellResult

function youtube_ConstructDownloadShell youtubeVideoURL
   /*
   --write-description
   Write video description to a .description file
   
   --write-info-json
   Write video metadata to a .info.json file
   
   --write-annotations
   Write video annotations to a .annotations.xml file
   */
   
   shell_BashParamEscape youtubeVideoURL
   put "youtube-dl -f mp4" && youtubeVideoURL into someShell
   put space & "--write-description" after someShell
   put space & "--write-info-json" after someShell
   put space & "--write-annotations" after someShell
   return someShell
end youtube_ConstructDownloadShell


--> Mplayer
-
/*
http://automatist.org/wiki/CLVE/Examples
*/

command display_Video mFile
   mplayer_Play mFile
end display_Video

command mplayer_Play mFile
   -- don't use this to play
   -- need to open insead
   -- use this as a template for non-gui
   shell_BashParamEscape mFile
   
   -- put "./mplayer" && mFile into someShell
   put "mplayer" && mFile into someShell
   put mplayer_RootPath() into someRoot
   put shell_ExecuteAtRoot(someShell, someRoot) into shellResult
   return shellResult
end mplayer_Play

function mplayer_RootPath
    put "/Library/Application Support/ffmpegX/" into someRoot
    -- shell_BashParamEscape someRoot
    return someRoot
end mplayer_RootPath


--> Deps
-
command shell_BashParamEscape @someParam
   put word 1 to -1 of someParam into someParam
   if text_IsQuoted(someParam) is false then
      repeat for each char someChar in " |()"
         replace someChar with ("\" & someChar) in someParam
      end repeat
   end if
end shell_BashParamEscape

command file_Deconstruct someFile, @someRoot, @shortName, @fileExtension
    -- was "deconstruct_File"
    -- should turn someRoot into someFolder and add "/" to end
    
    if someFile is empty then
        put the effective filename of this stack into someFile
    end if
    put someFile into someRoot
    put the itemdelimiter into originalDelim
     
    set the itemdelimiter to "/"
    put last item of someFile into shortName
    delete last item of someRoot
     
    if shortName contains "." then
        set the itemdelimiter to "."
        put last item of shortName into fileExtension
        delete last item of shortName
    else
        put empty into fileExtension
    end if
    set the itemdelimiter to originalDelim
end file_Deconstruct

function time_HmsfToSeconds hmsf
   set the itemdelimiter to ":"
   put item 1 of hmsf into someHours
   put item 2 of hmsf into someMinutes
   put item 3 of hmsf into someSeconds
   put item 4 of hmsf into someFrames
   
   add someHours * 3600 to someSeconds
   add someMinutes * 60 to someSeconds
   add someFrames / 25 to someSeconds
   
   return someSeconds
end time_HmsfToSeconds

function time_SecondsToHMSF someSeconds, someFrames
   put the numberformat into oFormat
   set the numberformat to "##"
   
   put someSeconds div 3600 into someHours 
   put someSeconds mod 3600 into secondsLeft
   
   put secondsLeft div 60 into someMinutes
   put secondsLeft mod 60 into secondsLeft
   
   put trunc(secondsLeft) into someSeconds
   put secondsLeft - someSeconds into someFraction
   
   if someFrames is empty then put round(someFraction * 25) into someFrames
   add 0 to someFrames
   
   get someHours & ":" & someMinutes  & ":" & someSeconds  & ":" & someFrames
   set the numberformat to oFormat
   return it
end time_SecondsToHMSF
