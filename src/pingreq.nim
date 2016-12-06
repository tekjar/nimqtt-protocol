import type, header

## Fixed header for PINGREQ PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |     PINGREQ (1) NIBBLE   |     RESERVED             |   0
## +--------------------------+--------------------------+
## |                   Remaining Len =  0                |   1
## +-----------------------------------------------------+
##

type PingReq* = ref object

proc encode*(pingreq: PingReq): seq[byte] =
   result = newSeq[byte]()
   let fixedHeader = newFixedHeader(type.PINGREQ)
   fixedHeader.remainingLen = 0 
   # Encoding fixed header (includes remaining length of var header + payload)
   result.add(fixedHeader.encode(0))