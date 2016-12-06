import type, payload, header, message
import sequtils

## Fixed header for PUBLISH PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |     PUBLISH (1) NIBBLE   | DUP(1), QoS(2), Retain(1)|   0
## +--------------------------+--------------------------+
## | Remaining Len = Len of Variable header(10) + Payload|   1
## +-----------------------------------------------------+
## 
##
## Variable header ( LENGTH = 2 Bytes)
##
## +--------------------------+--------------------------+
## |            TOPIC Name Length MSB (VALUE = 0)        |   2
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |            TOPIC Name Length LSB (VALUE = 4)        |   3
## +-----------------------------------------------------+
##
##                          TOPIC
##
## Payload: Set these optionals
## +--------------------------+--------------------------+
## |                 Packet Identifier MSB               |   n
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                 Packet Identifier LSB               |   n + 1
## +-----------------------------------------------------+
##
## Application payload
#

type PublishPacket* = ref object
    message: Message
    pkid: uint16
    dup: bool

proc remainingLen(publish: PublishPacket): uint32 =
   var total: int = 0

   # 2 byte variable header for packet identifier 
   total += 2 + publish.message.topic.len + publish.message.payload.len

   uint32(total)

proc newPublishPacket*(pkid: uint16, dup: bool, message: Message): PublishPacket =
   PublishPacket(
       message: message,
       pkid: pkid,
       dup: dup
   )

proc encode*(publish: PublishPacket): seq[byte] =
   result = newSeq[byte]()

   if publish.message.topic.len == 0:
      raise newException(OsError, "Empty publish topic")

   # Encoding fixed header (includes remaining length of var header + payload)
   let fixedHeader = newFixedHeader(PUBLISH)
   fixedHeader.remainingLen = publish.remainingLen()
   var flags = byte(0)
   if publish.dup:
      flags = flags or 0b0000_1000
   else:
      flags = flags and 0b1111_0111

   if publish.message.retain:
      flags = flags or 0b0000_0001
   else:
      flags = flags and 0b1111_1110

   if publish.message.qos < 0 and publish.message.qos > uint8(2):
      raise newException(OsError, "Invalid QoS")
   flags = (flags and 0b1111_1001) or (publish.message.qos shl 1)
   # encode(0) ??? --> fixed header flags nibble 
   result.add(fixedHeader.encode(flags))

   # Encoding topic name
   result.add(publish.message.topic.encodePayload())

   # Encode optionals (pkid and application payload)
   if publish.message.qos != 0:
      result.add(uint8(publish.pkid shr 8)) # MSB Byte 
      result.add(uint8(publish.pkid))       # LSB Byte
   result.add(publish.message.payload)

proc decode*(publish: seq[byte]): PublishPacket =
   var fixedHeader = publish.decodeFixed()
   let dup = ((publish[0] shr 3) and 0b0000_0001) == 1
   let retain = (publish[0] and 0b0000_0001) == 1
   let qos = (publish[0] shr 1) and 0b0000_0011
   if qos < 0 and qos > uint8(2):
      raise newException(OsError, "Invalid QoS")

   var next = 2
   let topic = publish[next..^1].decodeNextStrPayload()
   next += 2 + topic.len 

   var pkid: uint16 = 0
   if qos != 0:
     pkid = (uint16(publish[next]) shl 8) or uint16(publish[next + 1])
     next += 2
   
   let payloadLen = 
      if pkid == 0:
         fixedHeader.remainingLen - uint32(2 + topic.len)
      else:
         fixedHeader.remainingLen - uint32(2  + topic.len + 1)

   let payload = publish[next..(next + int(payloadLen))]
   let message = newMessage(topic, payload, qos, retain)
   result = newPublishPacket(pkid, dup, message)



when isMainModule:
   block:
      let message = newMessage("hello/world", "hello world".toSeq2, 1, true)
      var publish = newPublishPacket(1000, false, message)
      let e = publish.encode()
      let d = e.decode()
      doAssert d.pkid == 1000
      doAssert d.dup == false
      doAssert d.message.topic == "hello/world"
      doAssert d.message.qos == 1
      doAssert d.message.retain == true
      doAssert d.message.payload == message.payload

   block:
      let message = newMessage("hello/world", "hello world".toSeq2, 2, true)
      var publish = newPublishPacket(1000, true, message)
      let e = publish.encode()
      let d = e.decode()
      doAssert d.pkid == 1000
      doAssert d.dup == true
      doAssert d.message.topic == "hello/world"
      doAssert d.message.qos == 2
      doAssert d.message.retain == true
      doAssert d.message.payload == message.payload