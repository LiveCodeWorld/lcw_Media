﻿script "behavior_ViewImage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewImage
type: behavior
version: 0.1

/*
Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.
*/

--> Variables
-
local LocalArray


--> Working on
-

--> Events
-
on mouseUp
   beep
end mouseUp

on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl


--> Events | Custom
-
on refreshDisplay
   put the rect of me into viewRect
   LayoutControl viewRect
end refreshDisplay

command LayoutControl pRect
   if pRect is empty then put the rect of me into pRect
   
   put the fitInside_Rect [pRect] of me into pRect
   set the rect of me to pRect
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
function rect_FitInside fWidth, fHeight, someRect
   if (fWidth > 0 and fHeight > 0) is false then
      put the params
      return someRect
   end if 
   
   put item 3 of someRect - item 1 of someRect into oWidth
   put item 4 of someRect - item 2 of someRect into oHeight
   put oWidth / fWidth into xScaleFactor
   put oHeight / fHeight into yScaleFactor
   --
   put min (xScaleFactor, yScaleFactor) into sFactor
   put fWidth * sFactor into newW
   put fHeight * sFactor into newH
   --
   put rect_GetCentre (someRect) into someLoc
   put rect_LocWidthHeight (someLoc, newW, newH) into newRect
   return newRect
end rect_FitInside

function rect_LocWidthHeight someLoc, newW, newH
   put newW/2 into leftBit
   put newW - leftBit into rightBit
   put item 1 of someLoc into someX
   put someX - leftBit into item 1 of someRect
   put someX + rightBit into item 3 of someRect
   
   put newH/2 into upBit
   put newH - upBit into downBit
   put item 2 of someLoc into someY
   put someY - upBit into item 2 of someRect
   put someY + downBit into item 4 of someRect
   
   return someRect
end rect_LocWidthHeight

function rect_GetCentre someRect
   -- removed truncation
   put item 1 of someRect into someLeft
   put (item 3 of someRect - someLeft)/2 into halfWidth
   put item 2 of someRect into someTop
   put (item 4 of someRect - someTop)/2 into halfHeight
   put someLeft + halfWidth into item 1 of someMiddle
   put someTop + halfHeight into item 2 of someMiddle
   return someMiddle
end rect_GetCentre


--> Deps | Not needed?
-
function rect_FromWidthAndHeight someRect, sWidth, sHeight
   put rect_GetCentre (someRect) into someLoc
   put rect_LocWidthHeight (someLoc, sWidth, sHeight) into sRect
   return sRect
end rect_FromWidthAndHeight

function rect_GetProportional someRect, fWidth, fHeight, pDontCentre
   -- for an image we can get the original rect
   rect_SetWidth someRect, fWidth, pDontCentre
   rect_SetHeight someRect, fHeight, pDontCentre
   return someRect
end rect_GetProportional

command rect_SetWidth @someRect, newWidth, pDontCentre
   if pDontCentre is true then
      put item 1 of someRect + newWidth into item 3 of someRect
   else
      put item 1 of rect_GetCentre (someRect) into centreX
      put round (newWidth/2) into leftWidth
      put newWidth - leftWidth into rightWidth
      put centreX - leftWidth into item 1 of someRect
      put centreX + rightWidth into item 3 of someRect
   end if
end rect_SetWidth

command rect_SetHeight @someRect, newHeight, pDontCentre
   if pDontCentre is true then
      put item 2 of someRect + newHeight into item 4 of someRect
   else
      put item 2 of rect_GetCentre (someRect) into centreY
      put round (newHeight/2) into bottomHeight
      put newHeight - bottomHeight into topHeight
      put centreY - topHeight into item 2 of someRect
      put centreY + bottomHeight into item 4 of someRect
   end if
end rect_SetHeight


--> Objects
-
getprop view_Object
   return the long id of me
end view_Object