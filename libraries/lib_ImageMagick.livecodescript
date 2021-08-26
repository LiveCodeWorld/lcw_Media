script "lib_ImageMagick"
--> MetaData
-
license: GPLv3
name: lib_ImageMagick
type: library
version: 0.1


--> Working on
-
on testClone pHow, whichImage
   put _ImageURL (whichImage) into imageURL
   put _TestImage (imageURL, pHow) into someImage
   --
   put the stack_BelowRect of stack "Image 1" into sRect
   put empty into sRect
   --
   display_Clone "View|Image|Fit Inside", "Special Image", someImage, "image_Contents", sRect
   put the result into displayView
   --
   display_SetMenu displayView, "View | Image", "title_Menu"
   --
   return displayView
end testClone

private function _TestImage imageURL, pHow
   put imageMagick_FetchImageType (imageURL) into imageType
   switch pHow
      case 1
         put imageMagick_GrayScale (imageURL, imageType) into someImage
         break
      case 2
         put imageMagick_Sketch (imageURL, imageType, 60) into someImage
         break
      case 3
         put imageMagick_Charcoal (imageURL, imageType, 3) into someImage
         break
      default
         put imageMagick_Shrink (imageURL, 420, 420, imageType) into someImage
   end switch
   return someImage
end _TestImage

private function _ImageURL whichImage
   switch whichImage
      case 1
         return "http://finsburypark.spacenet.work/assets/A%20Taste%20of%20Italy.jpeg"
      case 2
         return "https://i.redd.it/pbdxgecnv3w41.jpg"
      default
         return "http://visualjam.org/assets/original.jpeg"
   end switch
end _ImageURL

on testMagic
   put _ImageURL() into imageURL
   --
   put imageMagick_FetchImageType (imageURL) into imageType
   -- put imageMagick_Shrink (imageURL, 64, 64, imageType) into someImage
   -- put imageMagick_GraySketch (imageURL, 125, imageType) into someImage
   -- put imageMagick_Sketch (imageURL, imageType, 60) into someImage
   put imageMagick_GrayScale (imageURL, imageType) into someImage
   -- put imageMagick_Charcoal (imageURL, imageType, 3) into someImage
   --
   display_Image someImage, "ImageMagick"
   put the result into displayView
   display_SetMenu displayView, gMenuTitle, "title_Menu"
   
   -- put imageMagick_ExtractExifArray (identityInfo) into someData
   -- display_Data someData, "exifArray", "Exif"
end testMagic


--> ImageMagick
-
function imageMagick_Shrink imageURL, sWidth, sHeight, pFormat
   put "curl -s [[imageURL]] | convert" into sTemplate
   --
   _AddInput sTemplate, pFormat
   _AddResize sTemplate, sWidth, sHeight, pFormat
   _AddOutput sTemplate, pFormat
   --
   put merge (sTemplate) into someShell
   put shell (someShell) into someImage
   return someImage
end imageMagick_Shrink

function imageMagick_Sketch imageURL, pFormat, sRadius, sWidth, sHeight
   -- http://www.fmwconcepts.com/imagemagick/sketch/index.php 
   put "curl -s [[imageURL]] | convert" into sTemplate
   --
   _AddInput sTemplate, pFormat
   --
   if sRadius is a number then
      put space & "-sketch" && sRadius after sTemplate
   end if
   --
   if sWidth is a number AND sHeight is a number then
      _AddResize sTemplate, sWidth, sHeight, pFormat
   end if
   --
   _AddOutput sTemplate, pFormat
   --
   put merge (sTemplate) into someShell
   put shell (someShell) into someImage
   return someImage
end imageMagick_Sketch

function imageMagick_GrayScale imageURL, pFormat, sWidth, sHeight
   -- https://imagemagick.org/script/command-line-options.php#grayscale
   
   put "curl -s [[imageURL]] | magick" into sTemplate
   _AddInput sTemplate, pFormat
   --
   put space & "-colorspace RGB -colorspace Gray" after sTemplate
   --
   if sWidth is a number AND sHeight is a number then _AddResize sTemplate, sWidth, sHeight, pFormat
   _AddOutput sTemplate, pFormat
   --
   put merge (sTemplate) into someShell
   put shell (someShell) into someImage
   return someImage
end imageMagick_GrayScale

function imageMagick_Charcoal imageURL, pFormat, sRadius, sWidth, sHeight   
   put "curl -s [[imageURL]] | magick" into sTemplate
   --
   _AddInput sTemplate, pFormat
   --
   put space & "-charcoal" && sRadius after sTemplate
   --
   if sWidth is a number AND sHeight is a number then
      _AddResize sTemplate, sWidth, sHeight, pFormat
   end if
   --
   _AddOutput sTemplate, pFormat
   --
   put merge (sTemplate) into someShell
   put shell (someShell) into someImage
   return someImage
end imageMagick_Charcoal

function imageMagick_GraySketch imageURL, pFormatsWidth, sHeight
   -- http://www.fmwconcepts.com/imagemagick/sketch/index.php 
   
end imageMagick_GraySketch

function imageMagick_Auto
   /*
   -auto-gamma	automagically adjust gamma level of image
   -auto-level	automagically adjust color levels of image
   -auto-orient	automagically orient image
   -auto-threshold method	automatically perform image thresholdin
   */
end imageMagick_Auto

function imageMagick_Edge
   /*
   -edge radius	apply a filter to detect edges in the image
   -emboss radius	emboss an image
   */
end imageMagick_Edge

on imageMagick_Canny
   /*
   -canny geometry	use a multi-stage algorithm to detect a wide range of edges in the image
   */
end imageMagick_Canny

private command _AddInput @someShell, pFormat
   if pFormat is empty then
      put space & "-" after someShell
   else
      put space & "[[pFormat]]:-" after someShell
   end if
end _AddInput

private command _AddOutput @someShell, pFormat
   if pFormat is empty then
      put space & "-" after someShell
   else
      put space & "[[pFormat]]:-" after someShell
   end if
end _AddOutput

private command _AddResize @someShell, sWidth, sHeight, pFormat
   if pFormat is empty then
      put space & "-resize [[sWidth]]x[[sHeight]]\>" after someShell
   else
      put space & "-resize [[sWidth]]x[[sHeight]]\>" after someShell
   end if
end _AddResize


--> ImageMagick | Type
-
function imageMagick_FetchImageType imageURL
   put imageMagick_FetchIdentity (imageURL) into identityInfo
   put imageMagick_GetImageType (identityInfo) into imageType
   return imageType
end imageMagick_FetchImageType

function imageMagick_GetImageType identityInfo
   put imageMagick_ConstructIdentityData (identityInfo) into identityData
   --
   set the itemdelimiter to slash
   get identityData ["Image"]["Mime type"]
   put item 2 of it into imageType
   --
   if imageType is empty then
      -- put image_DetectType (someImage) into imageType 
      get word 1 of identityData ["Image"]["Format"]
      put tolower (it) into imageType
   end if
   return imageType
end imageMagick_GetImageType


--> ImageMagick | Exif
-
function imageMagick_ExtractExifArray identityInfo
   filter identityInfo with "    exif:*"
   if identityInfo is empty then return empty
   replace "    exif:" with empty in identityInfo
   split identityInfo with CR and ":"
   return identityInfo
end imageMagick_ExtractExifArray

function imageMagick_ExtractGpsArray identityInfo
   filter identityInfo with "exif:*"
   replace "exif:" with empty in identityInfo
   split identityInfo with CR and "="
   return identityInfo
end imageMagick_ExtractGpsArray


--> ImageMagick
-
function imageMagick_FetchIdentity imageURL, pVerbose
   if pVerbose is not false then
      get "curl -s [[imageURL]] | identify -verbose -"
   else
      get "curl -s [[imageURL]] | identify -"
   end if
   put merge (it) into someShell
   --
   put shell (someShell) into identityInfo
   return identityInfo
end imageMagick_FetchIdentity

function text_IndentCount someLine, pSpacesPerIndent
   if pSpacesPerIndent is not a number then put 2 into pSpacesPerIndent
   repeat with cNum = 1 to the number of chars of someLine
      if char cNum of someLine is not space then
         subtract 1 from cNum
         put cNum / pSpacesPerIndent into indentNum
         return indentNum
      end if
   end repeat
   return 0
end text_IndentCount

function imageMagick_ConstructIdentityData identityInfo
   local arrayKey
   --
   /*
   get line 1 of identityInfo
   if item 1 of it is not "Image" then return empty
   put item 2 of it into tmpFile
   delete line 1 of identityInfo
   --
   put "Image" into arrayKey [1]
   put tmpFile into identityArray [arrayKey]
   */
   repeat for each line someLine in identityInfo
      put text_IndentCount (someLine, 2) into itemNum
      add 1 to itemNum
      --
      set the itemdelimiter to comma
      put item 2 of the extents of arrayKey into maxNum
      repeat with dNum = (itemNum + 1) to maxNum
         delete variable arrayKey [dNum]
      end repeat
      --
      set the itemdelimiter to ":"
      put word 1 to -1 of item 1 of someLine into keyName
      put item 2 of someLine into someValue
      --
      put keyName into arrayKey [itemNum]
      --
      if someValue is empty then
         next repeat
      else
         put someValue into identityArray [arrayKey]
      end if
   end repeat
   return identityArray
end imageMagick_ConstructIdentityData

function imageMagick_FetchGpsArray imageURL
   put merge ("curl -s '[[imageURL]]' | identify -format '%[EXIF:GPS*]' -") into someShell
   put shell (someShell) into gpsInfo
   put imageMagick_ExtractGpsArray (gpsInfo) into gpsArray
   return gpsArray
end imageMagick_FetchGpsArray


--> ImageMagick | GpsArray (old)
-
function imageMagick_Identity imagePath, pVerbose
   put "identify" into someShell
   if pVerbose is true then put space & "-verbose" after someShell
   put space & kwote (imagePath) after someShell
   --
   put shell (someShell) into identityInfo
   return identityInfo
end imageMagick_Identity

function imageMagick_FetchIdentityArray imageURL
   -- put merge ("wget -O - [[imageURL]] | identify -") into someShell
   put the tempname into imagePath
   put url imageURL into url ("binfile:" & imagePath)
   
   put imagePath into gpsArray ["imagePath"]
   put "identify" && imagePath into someShell
   put shell (someShell) into identityInfo
   put identityInfo into gpsArray ["identify"]
   return gpsArray
end imageMagick_FetchIdentityArray
