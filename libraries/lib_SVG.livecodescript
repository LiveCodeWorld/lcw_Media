script "lib_SVG"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_SVG
type: library
version: 0.1

/*
See also
- lcw_SvgLibrary
*/


--> Working on
-

--> Working on
-

--> SVG
-
function svg_GetPathText svgXML
   -- should find "path d=" anywhere in the svg?
   put revCreateXMLTree (svgXML, true, true, false) into treeID
   if treeID is not a number then
      revXMLDeleteTree treeID
      return false
   end if
   --
   put revXMLAttributeValues (treeID, "/svg", "path", "d", CR, -1) into dLines
   revXMLDeleteTree treeID
   return dLines
   
   /*
   -- for simple icon style svgs
   put revCreateXMLTree (svgXML, true, true, false) into treeID
   if treeID is not a number then
      revXMLDeleteTree treeID
      return false
   end if
   --
   -- put revXMLTree (treeID, svg, CR, tab, true, -1) into nodeOutline
   put "/svg/g" into gNode
   put revXMLChildNames (treeID, gNode, CR, "path", true) into shortPaths
   --
   repeat for each line pathName in shortPaths
      put gNode & slash & pathName into pathNode
      -- put revXMLAttributes (treeID, pathNode, comma, CR) 
      put revXMLAttribute (treeID, pathNode, "d") into svgPathLine
      if svgPathLine is not empty then
         put svgPathLine & CR after svgPathText
      end if
   end repeat
   delete char -1 of svgPathText
   --
   revXMLDeleteTree treeID
   return svgPathText
   */
end svg_GetPathText

function svg_GetNodeOutline svgXML
   -- for simple icon style svgs
   put revCreateXMLTree (svgXML, true, true, false) into treeID
   if treeID is not a number then
      revXMLDeleteTree treeID
      return false
   end if
   --
   put revXMLTree (treeID, svg, CR, tab, true, -1) into nodeOutline
   --
   revXMLDeleteTree treeID
   return nodeOutline
end svg_GetNodeOutline

function svg_Get someHTML
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   put revXMLRootNode (treeID) into rootNode
   put rootNode & "/body/svg" into svgNode
   put revXMLText (treeID, svgNode, true) into svgXML
   revXMLDeleteTree treeID
   return svgXML
end svg_Get

command svg_Set @someHTML, newSvgXml
   local startChar, endChar
   text_SetOffsets "<svg ", "</svg>", someHTML, startChar, endChar
   put the result into oldSvgXML
   put newSvgXml into char startChar to endChar of someHTML
   return oldSvgXML
end svg_Set

command svg_SetDimensions @svgXML, svgWidth, svgHeight
   put svg_CreateXmlTree (svgXML) into treeID
   revXMLSetAttribute treeID, "/svg","width", svgWidth
   revXMLSetAttribute treeID, "/svg","height", svgHeight
   put revXMLText (treeID, empty, true) into svgXML
   svg_DeleteXmlTree
   
   delete line 1 of svgXML -- the xml header
   put word 1 to -1 of svgXML into svgXML
end svg_SetDimensions

command text_SetOffsets startText, endText, someText, @startChar, @endChar, pStartAfterCharNum
   if pStartAfterCharNum is a number then   
      delete char 1 to pStartAfterCharNum of someText
   end if
   
   put offset (startText, someText) into startChar
   if startChar is 0 then
      put 0 into startChar
      put 0 into endChar
      return empty
   end if
   put the length of startText - 1 into startBit
   if endText = empty then
      put startChar + startBit into endChar
   else
      put text_OffsetAfter (endText, someText, startChar + startBit) into endChar
      if endChar is 0 then
         put 0 into startChar
         put 0 into endChar
         return empty
      end if
      add the length of endText - 1 to endChar
   end if
   
   add startAfterCharNum to startChar
   add startAfterCharNum to endChar
   return char startChar to endChar of someText
end text_SetOffsets

function text_OffsetAfter stringToFind, textToSearch, pStartSearchAt
   put offset (stringToFind, textToSearch, pStartSearchAt) into foundCharNum
   if foundCharNum is not 0 then
      add pStartSearchAt to foundCharNum
   end if
end text_OffsetAfter

command old_ExtractDimensions svgXML, @svgWidth, @svgHeight, @lineNum
   -- <svg width="880pt" height="480pt"  
   set the wholematches to false
   put lineOffset ("<svg ", svgXML) into lineNum
   put line lineNum of svgXML into firstLine
   put "<svg width=\'(.+)pt\' height=\'(.+)pt\'" into someReg
   replace "'" with quote in someReg
   get matchText (firstLine, someReg, svgWidth, svgHeight)
end old_ExtractDimensions

command old_SetDimensions @svgXML, svgWidth, svgHeight
   -- <svg width="880pt" height="480pt"  
   set the wholematches to false
   put lineOffset ("<svg ", svgXML) into lineNum
   put line lineNum of svgXML into firstLine
   put "<svg width=\'(.+)pt\' height=\'(.+)pt\'" into someReg
   replace "'" with quote in someReg
   get matchChunk (firstLine, someReg, sWidth, eWidth, sHeight, eHeight)
   
   put char sWidth to eWidth of line lineNum of svgXML into oldWidth
   put char sHeight to eHeight of line lineNum of svgXML into oldHeight
   
   put svgWidth into char sWidth to eWidth of line lineNum of svgXML
   put svgHeight into char sHeight to eHeight of line lineNum of svgXML
   return oldWidth,oldHeight
end old_SetDimensions


--> SVG | Templates
-
function svg_GetHTMLTemplate
   /*
   <!DOCTYPE html>
   <html>
   <head>
   <title>[[svgTitle]]</title>
   </head>
   <body>
   [[svgXML]]
   </body>
   </html>
   */
   put "<!DOCTYPE html><html><head><title>[[svgTitle]]</title></head><body>[[svgXML]]</body></html>" into htmlTemplate
   return htmlTemplate
end svg_GetHTMLTemplate
