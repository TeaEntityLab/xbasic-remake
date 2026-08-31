#ifndef _XBCONS_H_
#define _XBCONS_H_

/*
  Ported from xlib.s.
  copyright 2000 Wade Maxfield
  licensed under LGPL -- see COPYING_LIB
*/
/*
#
#
# #######################
# #####  CONSTANTS  #####  assembly language constants for this file
# #######################
#
# the following $$ErrorObject and $$ErrorNature constants need
# to be kept in sync with the constants in the standard library.
#
*/
#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#define $$ErrorObjectNone                 0x0000
#define $$ErrorObjectData                 0x0100
#define $$ErrorObjectDisk                 0x0200
#define $$ErrorObjectFile                 0x0300
#define $$ErrorObjectFont                 0x0400
#define $$ErrorObjectGrid                 0x0500
#define $$ErrorObjectIcon                 0x0600
#define $$ErrorObjectName                 0x0700
#define $$ErrorObjectNode                 0x0800
#define $$ErrorObjectPipe                 0x0900
#define $$ErrorObjectUser                 0x0A00
#define $$ErrorObjectArray                0x0B00
#define $$ErrorObjectImage                0x0C00
#define $$ErrorObjectMedia                0x0D00
#define $$ErrorObjectQueue                0x0E00
#define $$ErrorObjectStack                0x0F00
#define $$ErrorObjectTimer                0x1000
#define $$ErrorObjectBuffer               0x1100
#define $$ErrorObjectCursor               0x1200
#define $$ErrorObjectDevice               0x1300
#define $$ErrorObjectDriver               0x1400
#define $$ErrorObjectMemory               0x1500
#define $$ErrorObjectSocket               0x1600
#define $$ErrorObjectString               0x1700
#define $$ErrorObjectSystem               0x1800
#define $$ErrorObjectThread               0x1900
#define $$ErrorObjectWindow               0x1A00
#define $$ErrorObjectCommand              0x1B00
#define $$ErrorObjectDisplay              0x1C00
#define $$ErrorObjectLibrary              0x1D00
#define $$ErrorObjectMessage              0x1E00
#define $$ErrorObjectNetwork              0x1F00
#define $$ErrorObjectPrinter              0x2000
#define $$ErrorObjectProcess              0x2100
#define $$ErrorObjectProgram              0x2200
#define $$ErrorObjectArgument             0x2300
#define $$ErrorObjectComputer             0x2400
#define $$ErrorObjectFunction             0x2500
#define $$ErrorObjectIdentity             0x2600
#define $$ErrorObjectPassword             0x2700
#define $$ErrorObjectClipboard            0x2800
#define $$ErrorObjectDirectory            0x2900
#define $$ErrorObjectSemaphore            0x2A00
#define $$ErrorObjectStatement            0x2B00
#define $$ErrorObjectSystemRoutine        0x2C00
#define $$ErrorObjectSystemFunction       0x2D00
#define $$ErrorObjectSystemResource       0x2E00
#define $$ErrorObjectOperatingSystem      0x2F00
#define $$ErrorObjectIntegerLogicUnit     0x3000
#define $$ErrorObjectFloatingPointUnit    0x3100
#define $$ErrorNatureNone                 0x0000
#define $$ErrorNatureBusy                 0x0001
#define $$ErrorNatureFull                 0x0002
#define $$ErrorNatureError                0x0003
#define $$ErrorNatureEmpty                0x0004
#define $$ErrorNatureReset                0x0005
#define $$ErrorNatureExists               0x0006
#define $$ErrorNatureFailed               0x0007
#define $$ErrorNatureHalted               0x0008
#define $$ErrorNatureExpired              0x0009
#define $$ErrorNatureInvalid              0x000A
#define $$ErrorNatureMissing              0x000B
#define $$ErrorNatureTimeout              0x000C
#define $$ErrorNatureTooMany              0x000D
#define $$ErrorNatureUnknown              0x000E
#define $$ErrorNatureBreakKey             0x000F
#define $$ErrorNatureDeadlock             0x0010
#define $$ErrorNatureDisabled             0x0011
#define $$ErrorNatureNotEmpty             0x0012
#define $$ErrorNatureObsolete             0x0013
#define $$ErrorNatureOverflow             0x0014
#define $$ErrorNatureTooLarge             0x0015
#define $$ErrorNatureTooSmall             0x0016
#define $$ErrorNatureAbandoned            0x0017
#define $$ErrorNatureAvailable            0x0018
#define $$ErrorNatureDuplicate            0x0019
#define $$ErrorNatureExhausted            0x001A
#define $$ErrorNaturePrivilege            0x001B
#define $$ErrorNatureUndefined            0x001C
#define $$ErrorNatureUnderflow            0x001D
#define $$ErrorNatureAllocation           0x001E
#define $$ErrorNatureBreakpoint           0x001F
#define $$ErrorNatureContention           0x0020
#define $$ErrorNaturePermission           0x0021
#define $$ErrorNatureTerminated           0x0022
#define $$ErrorNatureUndeclared           0x0023
#define $$ErrorNatureUnexpected           0x0024
#define $$ErrorNatureWouldBlock           0x0025
#define $$ErrorNatureInterrupted          0x0026
#define $$ErrorNatureMalfunction          0x0027
#define $$ErrorNatureNonexistent          0x0028
#define $$ErrorNatureUnavailable          0x0029
#define $$ErrorNatureUnspecified          0x002A
#define $$ErrorNatureDisconnected         0x002B
#define $$ErrorNatureDivideByZero         0x002C
#define $$ErrorNatureIncompatible         0x002D
#define $$ErrorNatureNotConnected         0x002E
#define $$ErrorNatureLimitExceeded        0x002F
#define $$ErrorNatureNotInitialized       0x0030
#define $$ErrorNatureHigherDimension      0x0031
#define $$ErrorNatureLowestDimension      0x0032
#define $$ErrorNatureCannotInitialize     0x0033
#define $$ErrorNatureInitializeFailed     0x0034
#define $$ErrorNatureAlreadyInitialized   0x0035
#define $$ErrorNatureInvalidAccess        0x0036
#define $$ErrorNatureInvalidAddress       0x0037
#define $$ErrorNatureInvalidAlignment     0x0038
#define $$ErrorNatureInvalidArgument      0x0039
#define $$ErrorNatureInvalidCheck         0x003A
#define $$ErrorNatureInvalidCoordinates   0x003B
#define $$ErrorNatureInvalidCommand       0x003C
#define $$ErrorNatureInvalidData          0x003D
#define $$ErrorNatureInvalidDimension     0x003E
#define $$ErrorNatureInvalidEntry         0x003F
#define $$ErrorNatureInvalidFormat        0x0040
#define $$ErrorNatureInvalidKind          0x0041
#define $$ErrorNatureInvalidIdentity      0x0042
#define $$ErrorNatureInvalidInstruction   0x0043
#define $$ErrorNatureInvalidLocation      0x0044
#define $$ErrorNatureInvalidMessage       0x0045
#define $$ErrorNatureInvalidName          0x0046
#define $$ErrorNatureInvalidNode          0x0047
#define $$ErrorNatureInvalidNumber        0x0048
#define $$ErrorNatureInvalidOperand       0x0049
#define $$ErrorNatureInvalidOperation     0x004A
#define $$ErrorNatureInvalidReply         0x004B
#define $$ErrorNatureInvalidRequest       0x004C
#define $$ErrorNatureInvalidResult        0x004D
#define $$ErrorNatureInvalidSelection     0x004E
#define $$ErrorNatureInvalidSignature     0x004F
#define $$ErrorNatureInvalidSize          0x0050
#define $$ErrorNatureInvalidType          0x0051
#define $$ErrorNatureInvalidValue         0x0052
#define $$ErrorNatureInvalidVersion       0x0053
#define $$ErrorNatureInvalidDistribution  0x0054
#define $$ErrorOperatingSystem            0x2E00
#define $$ErrorMemoryAllocation           0x151D
#define $$ErrorInvalidFunctionCall        0x2431
#define $$ErrorOverflow                   0x0013
#define $$ErrorOutOfBounds                0x0B37
#define $$ErrorAttachNeedsNullNode        0x0B11
#define $$ErrorUnexpectedHigherDimension  0x0B2C
#define $$ErrorUnexpectedLowestDimension  0x0B2D
#define SECTION_QUERY                     0x00000001
#define SECTION_MAP_WRITE                 0x00000002
#define SECTION_MAP_READ                  0x00000004
#define SECTION_MAP_EXECUTE               0x00000008
#define SECTION_EXTEND_SIZE               0x00000010
#define PAGE_NOACCESS                     0x00000001
#define PAGE_READONLY                     0x00000002     
#define PAGE_READWRITE                    0x00000004     
#define MEM_COMMIT                        0x00001000     
#define MEM_RESERVE                       0x00002000     
#define MEM_DECOMMIT                      0x00004000     
#define MEM_RELEASE                       0x00008000     
#define MEM_FREE                          0x00010000     
#define MEM_PRIVATE                       0x00020000     

#endif
