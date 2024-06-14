script "behavior_ViewImage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewImage
type: behavior
version: 0.2

/*
Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.
*/

--> Variables
-
local LocalArray


--> Working on
-
getprop menu_Title
   put the menu_Title of me into mTitle
   if mTitle is empty then
      put the view_MenuTitle of me into mTitle
   end if
   return mTitle
end menu_Title

setprop menu_Title mTitle
   set the menu_Title of me to mTitle
end menu_Title


--> Events
-
on mouseDown pButtonNumber
   switch pButtonNumber
      case 3
         put the menu_Title of me into mTitle
         menu_PopUp mTitle
         break
      default
         pass mouseDown
   end switch
end mouseDown

on mouseDoubleUp pButtonNumber
   put the icon_Data of me into iconData
   launch_NounIcon iconData
end mouseDoubleUp

on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl


--> Displayed
-
getprop displayed_Data
   put the filename of me into urlORFile
   if urlORFile is empty then
      put the text of me into someImage
      return someImage
   else
      return urlORFile
   end if
end displayed_Data

setprop displayed_Data fileImageOrURL
   switch token 1 of fileImageOrURL
      case "https"
      case "http"
      case "/"
         set the image_URL of me to fileImageOrURL
         break
      case empty
         set the filename of me to empty
         set the text of me to empty
         break
      default
         set the text of me to fileImageOrURL
   end switch
end displayed_Data


--> Displayed
-
getprop image_Folder
   put the image_Folder of me into imagefolder
   if there is not a folder imagefolder then
      put the home folder & "/Downloads/" into imagefolder
   end if
   return imagefolder
end image_Folder

setprop image_Folder imagefolder
   set the image_Folder of me to imagefolder
end image_Folder

getprop image_Contents
   -- put the image_Object of me into imageObject
   put the filename of me into sFile
   if sFile is empty then
      put the text of me into someImage
   else
      put "binfile:/" & sFile into imageURL
      put url imageURL into someImage
   end if
   return someImage
end image_Contents

setprop image_Contents someImage
   set the text of me to someImage
   return the image_Object of me
end image_Contents

getprop image_File
   return the image_URL of me
end image_File

setprop image_File imageFile
   set the filename of me to someFile
   --
   set the itemdelimiter to slash
   put item 1 to -2 of someFile into imageFolder
   set the image_Folder of me to imageFolder
   return imageFolder
end image_File

getprop image_URL
   return the filename of me
end image_URL

setprop image_URL someFile
   lock screen
   put the rect of me into oRect
   set the filename of me to someFile
   Layoutcontrol oRect
   unlock screen
   --
   return imageObject
end image_URL


--> Events | Custom
-
command LayoutControl pRect
   if pRect is empty then put the rect of me into pRect
   
   switch the uOPN ["resize_Style"] of me
      case "resize"
         put pRect into imageRect
         break
      case "square"
         put rect_GetSquare (pRect) into imageRect
         break
      case "inside"
      default
         put the fitInside_Rect [pRect] of me into imageRect
   end switch
   --
   set the rect of me to imageRect
end LayoutControl

getprop fitInside_Rect [pRect]
   if pRect is empty then put the rect of the target into pRect
   put the formattedwidth of the target into fWidth
   put the formattedheight of the target into fHeight
   --
   put rect_FitInside (fWidth, fHeight, pRect) into insideRect
   return insideRect
end fitInside_Rect


--> Deps
-
function rect_FitInside fWidth, fHeight, sRect
   if (fWidth > 0 and fHeight > 0) is false then
      return sRect
   end if 
   
   put item 3 of sRect - item 1 of sRect into oWidth
   put item 4 of sRect - item 2 of sRect into oHeight
   put oWidth / fWidth into xScaleFactor
   put oHeight / fHeight into yScaleFactor
   --
   put min (xScaleFactor, yScaleFactor) into sFactor
   put fWidth * sFactor into newW
   put fHeight * sFactor into newH
   --
   put rect_GetCentre (sRect) into sLoc
   put rect_LocWidthHeight (sLoc, newW, newH) into newRect
   return newRect
end rect_FitInside

function rect_LocWidthHeight sLoc, newW, newH
   put newW/2 into leftBit
   put newW - leftBit into rightBit
   put item 1 of sLoc into someX
   put someX - leftBit into item 1 of sRect
   put someX + rightBit into item 3 of sRect
   
   put newH/2 into upBit
   put newH - upBit into downBit
   put item 2 of sLoc into someY
   put someY - upBit into item 2 of sRect
   put someY + downBit into item 4 of sRect
   
   return sRect
end rect_LocWidthHeight

function rect_GetCentre sRect
   put item 1 of sRect into sLeft
   put (item 3 of sRect - sLeft)/2 into hWidth
   put item 2 of sRect into sTop
   put (item 4 of sRect - sTop)/2 into hHeight
   put sLeft + hWidth into item 1 of sMiddle
   put sTop + hHeight into item 2 of sMiddle
   return sMiddle
end rect_GetCentre

function rect_GetSquare sRect
   put item 1 of sRect into sLeft
   put item 2 of sRect into sTop
   put item 3 of sRect into sRight
   put item 4 of sRect into sBottom
   
   put (sLeft + sRight) / 2 into sCenterX
   put (sTop + sBottom) / 2 into sCenterY
   put min (sRight - sLeft, sBottom - sTop) / 2 into sSize
   
   put sCenterX - sSize into sNewLeft
   put sCenterY - sSize into sNewTop
   put sCenterX + sSize into sNewRight
   put sCenterY + sSize into sNewBottom
   --
   return sNewLeft,sNewTop,sNewRight,sNewBottom
end rect_GetSquare


--> Deps | Not needed?
-
function rect_FromWidthAndHeight sRect, sWidth, sHeight
   put rect_GetCentre (sRect) into sLoc
   put rect_LocWidthHeight (sLoc, sWidth, sHeight) into sRect
   return sRect
end rect_FromWidthAndHeight

function rect_GetProportional sRect, fWidth, fHeight, pDontCentre
   -- for an image we can get the original rect
   rect_SetWidth sRect, fWidth, pDontCentre
   rect_SetHeight sRect, fHeight, pDontCentre
   return sRect
end rect_GetProportional

command rect_SetWidth @sRect, newWidth, pDontCentre
   if pDontCentre is true then
      put item 1 of sRect + newWidth into item 3 of sRect
   else
      put item 1 of rect_GetCentre (sRect) into centreX
      put round (newWidth/2) into leftWidth
      put newWidth - leftWidth into rightWidth
      put centreX - leftWidth into item 1 of sRect
      put centreX + rightWidth into item 3 of sRect
   end if
end rect_SetWidth

command rect_SetHeight @sRect, newHeight, pDontCentre
   if pDontCentre is true then
      put item 2 of sRect + newHeight into item 4 of sRect
   else
      put item 2 of rect_GetCentre (sRect) into centreY
      put round (newHeight/2) into bottomHeight
      put newHeight - bottomHeight into topHeight
      put centreY - topHeight into item 2 of sRect
      put centreY + bottomHeight into item 4 of sRect
   end if
end rect_SetHeight


--> Objects
-
getprop image_Object
   return the long id of me
end image_Object

getprop view_Object
   return the long id of me
end view_Object
