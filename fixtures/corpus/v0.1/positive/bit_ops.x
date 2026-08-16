FUNCTION Main
' Test bit manipulation builtins
DIM bs
DIM v
' BITFIELD(width, offset) = (width << 8) | offset
bs = BITFIELD(8, 0)
PRINT bs
' EXTS(value, width, offset) - signed extract
PRINT EXTS(15, 4, 0)
' EXTU(value, bitspec) - unsigned extract with bitspec
PRINT EXTU(255, BITFIELD(4, 0))
' CLR(value, width, offset) - clear bits
PRINT CLR(255, 8, 0)
' SET(value, width, offset) - set bits
PRINT SET(0, 4, 4)
' MAKE(value, width, offset) - shift bits up
PRINT MAKE(15, 4, 8)
' HIGH0 - highest 0 bit
v = 2147483647
PRINT HIGH0(v)
' HIGH1 - highest 1 bit
v = 12588083
PRINT HIGH1(v)
' GHIGH/GLOW
PRINT GHIGH(42)
PRINT GLOW(42)
' SIGN - returns 1 for positive, -1 for negative
PRINT SIGN(3.14)
END FUNCTION
