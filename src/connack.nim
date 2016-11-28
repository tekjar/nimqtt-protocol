import type, header

## Fixed header for CONNACK PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |     CONNACK (1) NIBBLE   |     RESERVED             |   0
## +--------------------------+--------------------------+
## |    Remaining Len = Len of Varable header(2)         |   1
## +-----------------------------------------------------+
## 
##
## Variable header ( LENGTH = 2 Bytes)
##
## +--------------------------+--------------------------+
## |   Reserved bits 1-7 must be set to 0 (0b0000 0000x) |   2
## |   Bit 0 is 'session present' flag                   |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                  Connect Return Code                |   3
## +-----------------------------------------------------

type ConnackRet* = enum
  ConnectionAccepted = 0, InvalidProtocolVersion, IdentifierRejected,
  ServerUnavailable, BadUsernameOrPassword, NotAuthorized 

type ConnackPacket* = ref object
  sessionPresent: bool
  returnCode: ConnackRet

proc remainingLen(connack: ConnackPacket): uint32 =
    2

proc newConnackPacket*(sessionPresent: bool, returnCode: ConnackRet): ConnackPacket =
    ConnackPacket(sessionPresent: sessionPresent, returnCode: returnCode)

proc encode*(connack: ConnackPacket): seq[byte] =
    result = newSeq[byte]()
    let fixedHeader = newFixedHeader(CONNACK)
    fixedHeader.remainingLen = connack.remainingLen

    # Encoding fixed header (includes remaining length of var header + payload)
    result.add(fixedHeader.encode(0))

    if connack.sessionPresent:
        result.add(0x01)
    else:
        result.add(0x00)
    result.add(byte(connack.returnCode))

proc decode*(connack: seq[byte]): ConnackPacket =
    var fixedHeader = connack.decodeFixed()

    if fixedHeader.remainingLen != 2:
        raise newException(OsError, "Invalid Remaining Length")

    let sessionPresent = (connack[2] and 0x01) == 1
    let returnCode = ConnackRet(connack[3])

    #TODO: Add exception if returncode doesn't belong to ConnackRet enum
    result = newConnackPacket(sessionPresent, returnCode)


when isMainModule:
  block:
      var connect = newConnackPacket(false, ConnackRet(4))
      let e = connect.encode()
      let d = e.decode()
      doAssert d.sessionPresent == false
      doAssert d.returnCode == ConnackRet(4)
