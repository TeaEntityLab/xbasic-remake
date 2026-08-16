FUNCTION Main
' Test bit reinterpretation builtins
' DHIGH: high 32 bits of double (1.0 = 0x3FF0000000000000)
PRINT DHIGH(1.0)
' DLOW: low 32 bits of double
PRINT DLOW(1.0)
' DHIGH of 2.0 (0x4000000000000000)
PRINT DHIGH(2.0)
' SMAKE: reinterpret int as float (0x3F800000 = 1.0)
PRINT SMAKE(1065353216)
' XMAKE: reinterpret float as int (1.0 -> 0x3F800000)
PRINT XMAKE(1.0)
' GMAKE: assemble from two ints (returns low 32 bits)
PRINT GMAKE(0, 42)
END FUNCTION
