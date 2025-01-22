script "lib_ImageData"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Imagedata
type: library
version: 0.1

/*Some help*/


--> Working on
-
function binary_CRC32 pData
   -- Implements the standard CRC32 algorithm used in PNGs
   local tTable, tCRC, i, j, tByte
   
   # Initialize CRC Table (256 entries for all byte values)
   put "" into tTable
   repeat with i = 0 to 255
      put i into tCRC
      repeat with j = 1 to 8
         if (tCRC bitAnd 1) = 1 then
            put (tCRC div 2) bitXor 0xEDB88320 into tCRC
         else
            put tCRC div 2 into tCRC
         end if
      end repeat
      put tCRC & CR after tTable 
   end repeat
   
   -- Calculate the CRC for the provided data
   put 0xFFFFFFFF into tCRC
   repeat with i = 1 to the number of bytes of pData
      put byteToNum(byte i of pData) bitXor (tCRC bitAnd 0xFF) into tByte
      put line (tByte + 1) of tTable into tCRC
      put (tCRC div 256) bitXor 0xFFFFFFFF into tCRC
   end repeat
   
   -- Return the CRC value as an unsigned 32-bit integer
   return tCRC bitAnd 0xFFFFFFFF
end binary_CRC32


--> Pixel
-
function pixel_RandomColour
   local rPixel
   
   repeat 3
      put random(255) into rColourValue
      put numToByte (rColourValue) after rPixel
   end repeat
   
   # Each byte set to zero (black with full opacity)
   -- put numToByte (255) into opaqueByte 
   put null after rPixel -- full opacity
   --
   return rPixel
end pixel_RandomColour


--> ImageData
-
function imageData_GenerateRandom tWidth, tHeight
   local tImageData
   
   -- Prepare an empty imagedata string (all pixels set to black with full opacity)
   put _PixelNum (tWidth, tHeight) into pixelNum
   repeat pixelNum
      put pixel_RandomColour() into rPixel
      put rPixel after tImageData
   end repeat
   return tImageData
end imageData_GenerateRandom

function imageData_GenerateBlack tWidth, tHeight
   local tImageData
   
   -- Prepare an empty imagedata string (all pixels set to black with full opacity)
   put _MaxImageBites (tWidth, tHeight) into tMaxBytes
   put _RepeatChar (null, tMaxBytes) into tImageData
   return tImageData
end imageData_GenerateBlack

command imageData_SetPixelFromEncoded @tImageData, pixelNum, sBytes
   local tPixel
   put fish_Encode(sBytes) into tPixel
   put pixelNum - 1 into tOffset
   put 4 * tOffset + 1 into bNum
   
   -- Set the encoded pixel data into the imagedata
   put char 1 to 4 of tPixel into byte bNum to (bNum + 3) of tImageData
end imageData_SetPixelFromEncoded

function imageData_GetPixel tImageData, pixelNum
   local tOffset, tPixel
   put pixelNum - 1 into tOffset -- Pixel positions start at 0
   put 4 * tOffset + 1 into bNum -- Including the alpha channel
   
   -- Extract the entire pixel (RGBA)
   put byteToNum(byte bNum of tImageData) into alphaNum
   put byteToNum(byte (bNum + 1) of tImageData) into redNum
   put byteToNum(byte (bNum + 2) of tImageData) into greenNum
   put byteToNum(byte (bNum + 3) of tImageData) into blueNum
   
   return alphaNum, redNum, greenNum, blueNum
end imageData_GetPixel

command imageData_SetPixel @tImageData, pixelNum, alphaNum, redNum, greenNum, blueNum
   put pixelNum - 1 into tOffset -- Pixel positions start at 0
   put 4 * tOffset + 1 into bNum
   
   -- Store RGBA values directly
   put numToChar(alphaNum) into byte bNum of tImageData
   put numToChar(redNum) into byte (bNum + 1) of tImageData
   put numToChar(greenNum) into byte (bNum + 2) of tImageData
   put numToChar(blueNum) into byte (bNum + 3) of tImageData
end imageData_SetPixel


--> ImageData |RGB
-
function imageData_GetRGB tImageData, pixelNum
   local tRed, tGreen, tBlue, tOffset, tData
   put pixelNum - 1 into tOffset -- Pixel positions start at 0
   put 4 * tOffset + 2 into bNum
   
   -- put byteToNum (byte ((4 * tOffset) + 2) of tImageData) into tRed
   put byte bNum of tImageData into sByte
   put byteToNum (sByte) into redNum
   
   -- put byteToNum (byte ((4 * tOffset) + 3) of tImageData) into tGreen
   put byte (bNum + 1) of tImageData into sByte
   put byteToNum (sByte) into greenNum
   
   -- put byteToNum (byte ((4 * tOffset) + 4) of tImageData) into tBlue
   put byte (bNum + 2) of tImageData into sByte
   put byteToNum (sByte) into blueNum
   
   return redNum,greenNum,blueNum
end imageData_GetRGB

command imageData_SetRGB @tImageData, pixelNum, redNum, greenNum, blueNum
   put pixelNum - 1 into tOffset -- Pixel positions start at 0
   --
   put 4 * tOffset + 2 into bNum
   put numToByte (redNum) into sByte 
   put sByte into byte bNum of tImageData
   
   put numToByte (greenNum) into sByte 
   put sByte into byte (bNum + 1) of tImageData
   
   put numToByte (blueNum) into sByte 
   put sByte into byte (bNum + 1) of tImageData
   --
   return redNum,greenNum,blueNum
end imageData_SetRGB



--> Private
-
private function _PixelNum tWidth, tHeight
   put tWidth * tHeight into tPixelNum
   return tPixelNum
end _PixelNum

private function _MaxImageBites tWidth, tHeight
   put _PixelNum (tWidth, tHeight) * 4 into tMaxBytes
   return tMaxBytes
end _MaxImageBites
