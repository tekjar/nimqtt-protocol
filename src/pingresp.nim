import type, header

## Fixed header for PINGRESP PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |     PINGRESP (1) NIBBLE  |     RESERVED             |   0
## +--------------------------+--------------------------+
## |                   Remaining Len =  0                |   1
## +-----------------------------------------------------+
##

type PingResp* = ref object

proc encode*(pingreq: PingResp): seq[byte] =
   result = newSeq[byte]()
   let fixedHeader = newFixedHeader(type.PINGRESP)
   fixedHeader.remainingLen = 0 
   # Encoding fixed header (includes remaining length of var header + payload)
   result.add(fixedHeader.encode(0))