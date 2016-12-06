import type, payload, header, message
import sequtils

## Fixed header for SUBSCRIBE PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |   SUBSCRIBE (1) NIBBLE   |     RESERVED             |   0
## +--------------------------+--------------------------+
## | Remaining Len = Len of Variable header(2) + Payload |   1
## +-----------------------------------------------------+
## 
##
## Variable header ( LENGTH = 2 Bytes)
##
## +--------------------------+--------------------------+
## |                 Packet Identifier MSB               |   2
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                 Packet Identifier LSB               |   3
## +-----------------------------------------------------+
##
## Payload: Set these optionals
##
##     2 bytes subscribe topic length + subscribe topic + 1 byte qos
##
##     ... for all the topics
##
#

type SubscribePacket* = ref object
    subscriptions: seq[(string, uint8)]
    pkid: uint16

proc remainingLen(subscribe: SubscribePacket): uint32 =
   var total: int = 0

   # 2 byte variable header for packet identifier 
   total += 2

   for s in subscribe.subscriptions:
      total += 2 + s[0].len + 1

   uint32(total)

proc newSubscribePacket*(pkid: uint16, subscriptions: seq[(string, uint8)]): SubscribePacket =
   SubscribePacket(
       subscriptions: subscriptions,
       pkid: pkid
   )

proc encode*(subscribe: SubscribePacket): seq[byte] =
   result = newSeq[byte]()

   # Encoding fixed header (includes remaining length of var header + payload)
   let fixedHeader = newFixedHeader(SUBSCRIBE)
   fixedHeader.remainingLen = subscribe.remainingLen()
   # encode(0) ??? --> fixed header flags nibble 
   result.add(fixedHeader.encode(0))

   # Encoding pkid in variable header + encoding payload (subscriptions)
   result.add(uint8(subscribe.pkid shr 8)) # MSB Byte 
   result.add(uint8(subscribe.pkid))       # LSB Byte 
   for s in subscribe.subscriptions:
      result.add(s[0].encodePayload())
      result.add(byte(s[1]))

proc decode*(subscribe: seq[byte]): SubscribePacket =
   var fixedHeader = subscribe.decodeFixed()
   let pkid = (uint16(subscribe[2]) shl 8) or uint16(subscribe[3])

   var next = 4
   var subscriptionsLen = uint32(fixedHeader.remainingLen) - 2

   var subscriptions = newSeq[(string, uint8)]() 
   while subscriptionsLen > uint32(0):
      var topic = subscribe[next..^1].decodeNextStrPayload()
      next += 2 + topic.len 
      var qos = uint8(subscribe[next])
      next += 1
      subscriptions.add((topic, qos))
      subscriptionsLen -= uint32(2 + topic.len + 1)

   result = newSubscribePacket(pkid, subscriptions)



when isMainModule:
   block:
      var subscribe = newSubscribePacket(25, @[("hello/world", uint8(0)), ("hello/nim", uint8(1)), ("world/nim", uint8(2))])
      let e = subscribe.encode()
      let d = e.decode()
      doAssert d.pkid == 25
      doAssert d.subscriptions == subscribe.subscriptions
