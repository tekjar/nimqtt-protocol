import type, payload, header, message
import sequtils


## Fixed header for CONNECT PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |     CONNECT (1) NIBBLE   |     RESERVED             |   0
## +--------------------------+--------------------------+
## | Remaining Len = Len of Varable header(10) + Payload |   1
## +-----------------------------------------------------+
## 
##
## Variable header ( LENGTH = 10 Bytes)
##
## +--------------------------+--------------------------+
## |            PROTOCOL Name Length MSB (VALUE = 0)     |   2
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |            PROTOCOL Name Length LSB (VALUE = 4)     |   3
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          M                          |   4
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          Q                          |   5
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          T                          |   6
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          T                          |   7
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |         PROTOCOL LEVEL (VALUE = 4 for MQTT 3.1.1)   |   8
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |  CONNECT FLAGS                                      |
## |  UN(1 bit), PW(1), WR(1), WQ(2), W(1), CS(1), R(1)  |   9
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                  KEEP ALIVE MSB                     |   10
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                  KEEP ALIVE LSB                     |   11
## +-----------------------------------------------------+
##
##
## Payload: Set these optionals depending on CONNECT flags in variable header
##
##     2 bytes client id length + client id
##     +
##     2 bytes len of will topic +  will topic
##     +
##     2 bytes len of will payload +  will payload
##     +
##     2 bytes len of username +  username
##     +
##     2 bytes len of password +  password
##


#const BYTES_MQTT311: seq[byte] = toSeq("MQTT".items)
const MQTT311: byte = 4

type ConnectPacket* = ref object
  fixedHeader: FixedHeader
  clientId: string
  keepAlive: uint16
  userName: string
  password: string
  cleanSession: bool
  will: Message
  version: byte

#
# Variable header + payload length for CONNECT packet
proc remainingLen(connect: ConnectPacket): uint32 =
  var total: int = 0

  # 2 bytes protocol name length
  # 4 bytes protocol name
  # 1 byte protocol version
  total += 2 + 4 + 1

  # 1 byte connect flags
  # 2 bytes keep_alive
  total += 1 + 2

  # Client ID length (2 bytes) + Client Id
  total += 2 + len(connect.clientId)

  # add the will topic and will message length
  if connect.will != nil:
    total += 2 + len(connect.will.topic) + 2 + len(connect.will.payload)

  # username length
  if len(connect.userName) > 0:
    total += 2 + len(connect.userName)

  # password length
  if len(connect.password) > 0:
    total += 2 + len(connect.password)

  result = uint32(total)

proc newConnectPacket*(clientId: string, keepAlive: uint16 = 10,
                      userName = "", password = "",
                      cleanSession = true, will: Message = nil): ConnectPacket =
  result = ConnectPacket(
        fixedHeader: newFixedHeader(CONNECT),
        clientId: clientId,
        keepAlive: keepAlive,
        userName: userName,
        password: password,
        cleanSession: cleanSession,
        will: will,
        version: 4
  )
  result.fixedHeader.remainingLen = result.remainingLen()



proc encode*(connect: ConnectPacket): seq[byte] =
  result = newSeq[byte]()

  # Encodeing fixed header (includes remaining length of var header + payload)
  result.add(connect.fixedHeader.encode(0))

  # Encoding version string. This is similar to payload encoding
  result.add("MQTT".encodePayload())

  # Encode protocol version
  result.add(connect.version)

  # Create connect flags

  var connectFlags: byte = 0

  if len(connect.userName) > 0:
    connectFlags = connectFlags or 0b1000_0000
  else:
    connectFlags = connectFlags and 0b0111_1111

  if len(connect.password) > 0:
    connectFlags = connectFlags or 0b0100_0000
  else:
    connectFlags = connectFlags and 0b1011_1111

  if connect.will != nil:
    connectFlags = connectFlags or 0b0000_0100

    if len(connect.will.topic) == 0:
      raise newException(OsError, "Will flag is set but will topic is empty")

    #TODO: Do Qos validation

    connectFlags = (connectFlags and 0b1100_0111) or (connect.will.qos shl 3)

    if connect.will.retain:
      connectFlags = connectFlags or 0b0010_0000
    else:
      connectFlags = connectFlags and 0b1101_1111
  else:
    connectFlags = connectFlags and 0b1111_1011

  # Set clean session
  if connect.cleanSession:
    connectFlags = connectFlags or 0b0000_0010
  else:
    connectFlags = connectFlags or 0b1111_1101

  # Set reserve bit to 0
  connectFlags = connectFlags and 0b1111_1110

  # Add all the above encoded connect flags
  result.add(connectFlags)

  # Write keep alive
  result.add(byte(connect.keepAlive shr 8))
  result.add(byte(connect.keepAlive))

  # Start writing payload
  
  # Write client id
  result.add(connect.clientId.encodePayload())

  if connect.will != nil:
    result.add(connect.will.topic.encodePayload())
    result.add(connect.will.payload.encodePayload())

  if len(connect.userName) == 0 and len(connect.password) > 0:
    raise newException(OsError, "Empty username but non empty password")

  if len(connect.userName) > 0:
    result.add(connect.userName.encodePayload())
  if len(connect.password) > 0:
    result.add(connect.password.encodePayload())

proc decodeConnect*(connect: seq[byte]): ConnectPacket =
    var fixedHeader = connect.decodeFixed()
    var protoName = connect[2..^1].decodeNextPayload()
    var protoVersion = connect[8]
    var connectFlags = connect[9]
    echo connectFlags

    # read flags
    let usernameFlag = ((connectFlags shr 7) and 0x1) == 1
    let passwordFlag = ((connectFlags shr 6) and 0x1) == 1
    let willFlag = ((connectFlags shr 2) and 0x1) == 1
    let willRetain = ((connectFlags shr 5) and 0x1) == 1
    let willQOS = (connectFlags shr 3) and 0x3
    let cleanSession = ((connectFlags shr 1) and 0x1) == 1

    if (connectFlags and 0x01) != 0:
      raise newException(OsError, "Reserve bit should be 0")

    #TODO: Validate QoS
    if willFlag:
      var qos = willQOS
      var retain = willRetain

    if usernameFlag == false and passwordFlag == true:
      raise newException(OsError, "User name flag not set but Password flag set")

    var keepAlive = uint16(connect[10] shl 8) or uint16(connect[11])
    echo keepAlive

    var clientId = connect[12..^1].decodeNextPayload()
    echo payload.toString clientId

    var next = 2 + len(clientId) - 1

    if willFlag:
        var topic = connect[next..^1].decodeNextPayload()
        echo payload.toString topic
        next = 2 + len(topic) - 1
        var load = connect[next..^1].decodeNextPayload()
        echo payload.toString load
        next = 2 + len(load) - 1


    if usernameFlag:
        echo connect[next..^1]
        var userName = connect[next..^1].decodeNextPayload()
        echo payload.toString userName
        next = 2 + len(userName) - 1

    if passwordFlag:
        var password = connect[next..^1].decodeNextPayload()
        echo payload.toString password

    


when isMainModule:
  block:
      var connect = newConnectPacket("new-id", 25, "hello", "world", false)
      let e = connect.encode()
      let d = e.decodeConnect()






