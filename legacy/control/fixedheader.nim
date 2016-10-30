import packettype, algorithm
  
type FixedHeaderException = ref object of Exception
  description: string

proc newFixedHeaderException(description: string): FixedHeaderException =
  FixedHeaderException(description: description)

## Fixed header for each MQTT control packet
##
## Format:
##
## ```plain
## 7                          3                          0
## +--------------------------+--------------------------+
## | MQTT Control Packet Type | Flags for each type      |
## +--------------------------+--------------------------+
## | Remaining Length ...                                |
## +-----------------------------------------------------+
## ```
type
  FixedHeader* = ref object
    packetType: PacketType
    # The Remaining Length is the number of bytes remaining within the current packet,
    # including data in the variable header and the payload. The Remaining Length does
    # not include the bytes used to encode the Remaining Length.
    remainingLen: uint32

proc newFixedHeader(packetType: PacketType, remainingLen: uint32 ): FixedHeader =
  FixedHeader(packetType: packetType, remainingLen: remainingLen)

proc encode(self: FixedHeader): seq[byte] =
  result.add(self.packetType.pack())
  var curLen = self.remainingLen

  while true:
    var byt = byte(curLen and 0x7F)
    curLen = curLen shr 7

    if curLen > uint32(0):
      byt = byt or 0x80

    result.add(byt)

    if curLen == 0:
      break

proc encodedLen(self: FixedHeader): uint32 =
  let remSize: uint32 = 
    if self.remainingLen >= 2_097_152'u32:
      4
    elif self.remainingLen >= 16_384'u32:
      3
    elif self.remainingLen >= 128'u32:
      2
    else:
      1
  remSize + 1

proc decode(e: seq[byte]): FixedHeader =
  var e = e
  e.reverse()

  var packetTypeEncoded = e.pop()

  var cur: uint32 = 0
  var i = 0

  while true:
    let byt = e.pop()
    cur = cur or uint32((uint32(byt) and 0x7F) shl (7 * i))

    if i >= 4:
      raise newFixedHeaderException("Mal Formed Remaining Length")
    if (byt and 0x80) == 0:
      break
  let remainingLen = cur
  let packetType = newPacketType(packetTypeEncoded)
  FixedHeader(packetType: packetType, remainingLen: remainingLen)
