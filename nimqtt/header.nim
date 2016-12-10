import type
import algorithm

const maxRemainingLength: uint32 = 268435455 #bytes, or 256 MB

## Fixed header for each MQTT control packet
##
## Format:
##
## ```plain
## 7                          3                          0
## +--------------------------+--------------------------+
## | MQTT Control Packet Type | Flags for each type      |
## +--------------------------+--------------------------+
## |                  Remaining Length                   |
## +-----------------------------------------------------+
## ```
type
  FixedHeader* = ref object
    control*: Control
    # The Remaining Length is the number of bytes remaining within the current packet,
    # including data in the variable header and the payload. The Remaining Length does
    # not include the bytes used to encode the Remaining Length.
    remainingLen*: uint32


## Calculate header length from remaining length
proc headerLen*(remainingLen: uint32): uint32 =
  let remSize: uint32 = 
    if remainingLen >= 2_097_152'u32:
      4
    elif remainingLen >= 16_384'u32:
      3
    elif remainingLen >= 128'u32:
      2
    else:
      1
  remSize + 1

proc newFixedHeader*(control: Control): FixedHeader =
  FixedHeader(
    control: control,
    remainingLen: 0
  )

proc encode*(self: FixedHeader, flags: uint8): seq[byte] =
  result = newSeq[byte](0)
  result.add(self.control.pack(flags))

  var curLen = self.remainingLen
  if curLen > maxRemainingLength or curLen < 0:
    raise newException(OSError, "Invalid Remaining Length")

  while true:
    var byt = byte(curLen and 0x7F)
    curLen = curLen shr 7

    if curLen > uint32(0):
      byt = byt or 0x80

    result.add(byt)

    if curLen == 0:
      break

proc decodeFixed*(e: seq[byte]): FixedHeader =
  var e = e
  e.reverse()

  var packetTypeEncoded = e.pop()

  var cur: uint32 = 0
  var i = 0

  while true:
    let byt = e.pop()
    cur = cur or uint32((uint32(byt) and 0x7F) shl (7 * i))

    if i >= 4:
      raise newException(OSError, "Mal Formed Remaining Length")
    if (byt and 0x80) == 0:
      break

  return FixedHeader(control: Control(packetTypeEncoded shr 4), remainingLen: cur)


when isMainModule:
  block:
    var header = FixedHeader(control: CONNECT, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: CONNACK, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PUBLISH, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PUBACK, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PUBREC, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PUBREL, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PUBCOMP, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: SUBSCRIBE, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: SUBACK, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PINGREQ, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: PINGRESP, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control
  block:
    var header = FixedHeader(control: DISCONNECT, remainingLen: 0)
    var e = header.encode(0)
    doAssert e.decodeFixed().control == header.control

