import type, header

## Fixed header for SUBACK/PUBACK/PUBREC/PUBCOMP/PUBREL PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |         ACK (1) NIBBLE   |     RESERVED             |   0
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

type
  Ack* = enum
    PUBACK = 4, PUBREC, PUBREL, PUBCOMP, SUBACK = 9, UNSUBACK = 11

type AckPacket* = ref object
   pkid: uint16
   acktype: Ack

proc remainingLen(ack: AckPacket): uint32 =
    2

proc newAckPacket*(acktype: Ack, pkid: uint16): AckPacket =
   AckPacket(pkid: pkid, acktype: acktype)

proc encode*(ack: AckPacket): seq[byte] =
   result = newSeq[byte]()
   let fixedHeader = newFixedHeader(Control(ack.acktype))
   fixedHeader.remainingLen = ack.remainingLen

   # Encoding fixed header (includes remaining length of var header + payload)
   result.add(fixedHeader.encode(0))

   result.add(uint8(ack.pkid shr 8)) # MSB byte of pkid
   result.add(uint8(ack.pkid))       # LSB byte of pkid

proc decode*(ack: seq[byte]): AckPacket =
   var fixedHeader = ack.decodeFixed()

   if fixedHeader.remainingLen != 2:
      raise newException(OsError, "Invalid Remaining Length")

   let pkid = (uint16(ack[2]) shl 8) or uint16(ack[3]) 

   #TODO: Add exception if returncode doesn't belong to subackRet enum
   result = newAckPacket(Ack(fixedHeader.control), pkid)


when isMainModule:
  block:
      var connect = newAckPacket(PUBACK, 100)
      let e = connect.encode()
      let d = e.decode()
      doAssert d.pkid == connect.pkid