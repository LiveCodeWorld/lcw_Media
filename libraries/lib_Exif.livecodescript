script "lib_Exif"
--> MetaData
-
license: GPLv3
name: lib_Exif
type: library
version: 0.1


--> Exif
-
function exif_GetInfoArray imagePath   
   put "exiv2 -ptxi" && kwote (imagePath) into someShell
   put "exiv2 -pa" && kwote (imagePath) into someShell
   put shell (someShell) into identityInfo
   
   repeat for each line someLine in identityInfo
      put token 1 of someLine into exifName
      put token 2 of someLine into exifType
      put token 3 of someLine into exifNum
      put token 4 to -1 of someLine into exifValue
      
      split exifName with "."
      put exifValue into infoArray [exifName]
   end repeat
   return infoArray
end exif_GetInfoArray

command exif_ExtractLatLong exifArray, @mapLat, @mapLong
   -- put resultArray ["exifArray"] into exifArray
   put exifArray ["exif"]["GPSInfo"] into gpsArray
   put gpsArray ["GPSLatitude"] into latInfo
   put gpsArray ["GPSLongitude"] into longInfo
   
   if latInfo is empty or longInfo is empty then
      put empty into mapLat
      put empty into mapLong
      return false
   end if
   
   put exif_GpsToDegrees (latInfo) into mapLat
   put exif_GpsToDegrees (longInfo) into mapLong
   
   if gpsArray ["GPSLongitudeRef"] = "West" then
      put -1 * mapLong into mapLong
   end if
   if gpsArray ["GPSLatitudeRef"] = "South" then
      put -1 * mapLat into mapLat
   end if
   return true
end exif_ExtractLatLong

function exif_GpsToDegrees gpsInfo
   /*
   According to the exif standard, there are three "rational" fields for each, containing degrees, minutes, and seconds. 
   exiftool normalizes imporoper decimal degrees into D,M,S while assigning these values, 
   (exiftool -GPSLongitude="0.5 90 63.12345" junk.jpg" -> GPS Longitude: 2 deg 1' 3.12" W") 
   So if you need decimal degrees, you do dd=x0+x1/60.+x2/3600. and could ignore the non-normalization.
   
   $d = $deg + ((($min/60) + ($sec/3600))/100);
   $d = $deg + (($min/60) + ($sec/3600));
   
   GPSLatitude = 57 38 56.83 (57/1 38/1 5683/100)
   GPSLongitude = 10 24 26.79 (10/1 24/1 2679/100)
   
   GPS Latitude                    : 57 deg 38' 56.83" N
   GPS Longitude                   : 10 deg 24' 26.79" E
   
   GPS Longitude                   : 10.40744
   GPS Position                    : 57.64911 10.40744
   
   */
   
   switch
      case word 1 of gpsInfo ends with "deg"
         -- 2deg 55' 54.240
         -- 2deg 55' 17.040"
         replace "deg" with empty in gpsInfo
         put word 1 of gpsInfo into someDegrees
         put word 2 of gpsInfo into someMinutes
         if char -1 of someMinutes = "'" then delete char -1 of someMinutes
         put word 3 of gpsInfo into someSeconds
         if char -2 to -1 of someSeconds = "''" then delete char -2 to -1 of someSeconds
         break
      default
         -- imageMagick exif results 
         -- 2/1, 55/1, 5424/100
         -- 10/1 24/1 2679/100 => 10 deg 24' 26.79" E => 10.40744
         
         put item 1 of gpsInfo into degreeInfo
         put item 2 of gpsInfo into minuteInfo
         put item 3 of gpsInfo into secondInfo
         
         set the itemdelimiter to slash
         put item 1 of degreeInfo / item 2 of degreeInfo into someDegrees
         put item 1 of minuteInfo / item 2 of minuteInfo into someMinutes
         put item 1 of secondInfo / item 2 of secondInfo into someSeconds
   end switch
   
   put someDegrees + someMinutes / 60 + someSeconds / 3600 into decValue
   return decValue
end exif_GpsToDegrees


--> EXIF
-
function exif_IsInstalled
   put shell ("exiftool --help") into shellResult
   
   if shellResult contains "exiftool: command not found" then
      return false
   else
      return true
   end if
end exif_IsInstalled

function exif_GetTag tagName, imageFile, padded
    put exif_GetTagLine(tagName, imageFile, empty) into tagLine
    return tagLine
    
    -- using exif (http://libexif.sourceforge.net/ http://exif.darwinports.com/)
    shell_BashParamEscape imageFile
    shell_BashParamEscape tagName
    put "exif -t" && tagName && imageFile into someShell
    return shell(someShell)
end exif_GetTag

function exif_GetTagLine tagName, imageFile, padded
    --  Using exiftool (http://sno.phy.queensu.ca/%7Ephil/exiftool/exiftool_pod.html#reading_examples)
    shell_BashParamEscape imageFile
    
    if padded is true then
        put "exiftool -s -" & tagName && imageFile into someShell
    else
        put "exiftool -s -s -" & tagName  && imageFile into someShell
    end if
    put someShell
    return shell(someShell)
end exif_GetTagLine

function exif_GetMetaDataArray imageFile
    put exif_GetMetaData(imageFile) into metaDataArray
    replace ": " with tab in metaDataArray
    split metaDataArray with CR and tab
    return metaDataArray
end exif_GetMetaDataArray

function exif_GetMetaData imageFile, pretty
    /*
    Using exiftool (http://sno.phy.queensu.ca/%7Ephil/exiftool/exiftool_pod.html#reading_examples)
    print all meta information in an image, including duplicate and unknown tags, sorted by group (for family 1).
    */
    
    shell_BashParamEscape imageFile
    if pretty is true then
        put "exiftool -s -a -u -g1" && imageFile into someShell
    else
        put "exiftool -s -s -u" && imageFile into someShell
    end if
    return word 1 to -1 of shell(someShell)
end exif_GetMetaData

-- on exif_SetTag tagName, imageFile, tagValue
    shell_BashParamEscape imageFile
    shell_BashParamEscape tagName
    put "exif -t" && tagName && imageFile into someShell
    return shell(someShell)
end exif_SetTag

function exif_ListTags imageFile
    shell_BashParamEscape imageFile
    
    -- using exiftool (http://sno.phy.queensu.ca/%7Ephil/exiftool/exiftool_pod.html#reading_examples)
    put "exiftool -list" && imageFile into someShell
    put shell(someShell) into shellResult
    put exif_ParseExifToolResult(shellResult, tagArray) into tagNames
    return tagNames
    
    get keys(tagArray)
    sort it
    replace "/" with "_" in it
    return it
     
    -- using exif (http://libexif.sourceforge.net/ http://exif.darwinports.com/)
    put "exif -l" && imageFile into someShell
    return exif_ParseTagList(shellResult, tagArray)
end exif_ListTags

function exif_ParseExifToolResult shellResult, @tagArray
    put lineoffset("Command-line shortcuts:",shellResult) into lineNum
    put line 2 to (lineNum-1) of shellResult into availableTagNames
    -- put line (lineNum+1) of shellResult into shortCuts
    put line (lineNum+2) to -1 of shellResult into exifTable
     
    set the itemdelimiter to ":"
    repeat for each line exifLine in exifTable
        put word 1 to -1 of item 1 of exifLine into tagName
        put word 1 to -1 of item 2 of exifLine into tagValue
        put tagValue into tagArray [tagName]
    end repeat
     
    replace CR & "  " with CR in availableTagNames
    replace space with CR in availableTagNames
    delete char 1 to 2 of availableTagNames
    
    return word 1 to -1 of availableTagNames
end exif_ParseExifToolResult

function exif_ParseTagList shellResult, @tagArray, allTags
    set the itemdelimiter to tab
    -- put shellResult
    delete line 1 of shellResult
    replace "  " with tab in shellResult
    -- if allTags is not true then filter shellResult with "*[*]*"
    -- put shellResult
    repeat for each line someLine in shellResult
        get item 2 of shellResult
        put word 1 of it into someID
        put word 2 to -1 of item 2 of someLine into tagName
        put someID into tagArray [tagName]
    end repeat
    put keys(tagArray) into tagNames
    sort tagNames
    return tagNames
end exif_ParseTagList


--> Image | SIPS
-
/*
Ian Wood <revlist@azurevision.co.uk>

-r degreesCW
--rotate degreesCW

-f horizontal|vertical
--flip horizontal|vertical

-c pixelsH pixelsW
--cropToHeightWidth pixelsH pixelsW
Crop image to fit specified size.

-p pixelsH pixelsW
--padToHeightWidth pixelsH pixelsW
Pad image with pixels to fit specified size.

--padColor hexcolor
Use this color when padding. White=FFFFFF, Red=FF0000, Default=Black=000000

-z pixelsH pixelsW
--resampleHeightWidth pixelsH pixelsW
Resample image at specified size. Image apsect ratio may be altered.

--resampleWidth pixelsW
Resample image to specified width.

--resampleHeight pixelsH
Resample image to specified height.
*/

on sips_ConvertImageFormat inputFile, saveToFile, imageExportFormat
    -- need to be long file names or set the default folder
    if imageExportFormat = "jpg" then put "jpeg" into imageExportFormat
    if imageExportFormat is not among the items of sips_ExportFormats() then
        put "Export format not recognised by sips" into someError
        log_Error someError, imageExportFormat, true, true
        return someError
    end if
     
    shell_BashParamEscape inputFile
    shell_BashParamEscape saveToFile
    put merge("sips -s format [[imageExportFormat]] [[inputFile]] --out [[saveToFile]]") into someShell
    put shell(someShell) into shellResult
    return shellResult
end sips_ConvertImageFormat

command sips_SetWidth imageFile, someWidth
   /*
   --resampleWidth pixelsW
   Resample image to specified width.
   */
   put shell_MakeOSXShellPath (imageFile) into imageFile
   put "sips --resampleWidth" && someWidth && imageFile into someShell
   put shell (someShell) into shellResult
   return shellResult
end sips_SetWidth

function sips_RotateImage tInput, tDegrees, tOutput
    -- was "ijwAPLIB_SIPSRotateImage"
    if tDegrees = 0 then return true
    put shell_MakeOSXShellPath(tInput) into tShellInput
    put "sips -r" && tDegrees && tShellInput into tScript
    if tOutput is not empty then
        put shell_MakeOSXShellPath(tOutput) into tShellOutput
        put space & tShellOutput after tScript
    end if
    return shell(tScript)
end sips_RotateImage

function sips_ImageInfo tPath, tInfo
    -- was "ijwAPLIB_SIPSImageInfo"
    put shell_MakeOSXShellPath(tPath) into tPath
    put "sips -g" && tInfo into tScript
    put space & tPath after tScript
    get shell(tScript)
    put last word of it into tResult
    if tResult = "<nil>" then return empty
    return tResult
end sips_ImageInfo

function sips_ExportFormats
    return "jpeg,tiff,png,gif,-,jp2,pict,bmp,qtif,psd,sgi,tga"
end sips_ExportFormats

function sips_Formats
   return "jpeg,tiff,png,gif,jp2,pict,bmp,qtif,psd,sgi,tga"
end sips_Formats

function shell_MakeOSXShellPath tPath
    -- was "ijwAPLIB_MakeOSXShellPath"
    put "set tOut to quoted form of POSIX path of tPath" into tScript
    replace "tPath" with quote & revMacFromUnixPath(tPath) & quote in tScript
    do tScript as applescript
    put the result into tNewPath
    delete char 1 of tNewPath
    delete last char of tNewPath
    return tNewPath
end shell_MakeOSXShellPath
