import type, header

## Fixed header for SUBACK PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |      SUBACK (1) NIBBLE   |     RESERVED             |   0
## +--------------------------+--------------------------+
## |    Remaining Len = Len of Varable header(2)         |   1
## +-----------------------------------------------------+
## 
## Variable header ( LENGTH = 2 Bytes)
##
## +--------------------------+--------------------------+
## |                 Packet Identifier MSB               |   2
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                 Packet Identifier LSB               |   3
## +-----------------------------------------------------+
#

type SubackPacket* = ref object
   pkid: uint16

proc remainingLen(suback: SubackPacket): uint32 =
    2

proc newSubackPacket*(pkid: uint16): SubackPacket =
   SubackPacket(pkid: pkid)

proc encode*(suback: SubackPacket): seq[byte] =
   result = newSeq[byte]()
   let fixedHeader = newFixedHeader(SUBACK)
   fixedHeader.remainingLen = suback.remainingLen

   # Encoding fixed header (includes remaining length of var header + payload)
   result.add(fixedHeader.encode(0))

   result.add(uint8(suback.pkid shr 8)) # MSB byte of pkid
   result.add(uint8(suback.pkid))       # LSB byte of pkid

proc decode*(suback: seq[byte]): SubackPacket =
   var fixedHeader = suback.decodeFixed()

   if fixedHeader.remainingLen != 2:
      raise newException(OsError, "Invalid Remaining Length")

   let pkid = (uint16(suback[2]) shl 8) or uint16(suback[3]) 

   #TODO: Add exception if returncode doesn't belong to subackRet enum
   result = newSubackPacket(pkid)


when isMainModule:
  block:
      var connect = newSubackPacket(100)
      let e = connect.encode()
      let d = e.decode()
      doAssert d.pkid == connect.pkid

