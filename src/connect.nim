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
        clientId: clientId,
        keepAlive: keepAlive,
        userName: userName,
        password: password,
        cleanSession: cleanSession,
        will: will,
        version: 4
  )


proc encode*(connect: ConnectPacket): seq[byte] =
  result = newSeq[byte]()

  let fixedHeader = newFixedHeader(CONNECT)
  fixedHeader.remainingLen = connect.remainingLen()  
  # Encoding fixed header (includes remaining length of var header + payload)
  result.add(fixedHeader.encode(0))
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

    # Encode Will QoS
    connectFlags = (connectFlags and 0b1100_0111) or (connect.will.qos shl 3)
    # Encode Will Retain
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
    connectFlags = connectFlags and 0b1111_1101

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

    # read flags
    let usernameFlag = ((connectFlags shr 7) and 0x1) == 1
    let passwordFlag = ((connectFlags shr 6) and 0x1) == 1
    let willFlag = ((connectFlags shr 2) and 0x1) == 1
    let willRetain = ((connectFlags shr 5) and 0x1) == 1
    let willQOS = (connectFlags shr 3) and 0x3
    let cleanSession = ((connectFlags shr 1) and 0x1) == 1

    if (connectFlags and 0x01) != 0:
      raise newException(OsError, "Reserve bit should be 0")

    if usernameFlag == false and passwordFlag == true:
      raise newException(OsError, "User name flag not set but Password flag set")

    var keepAlive = uint16(connect[10] shl 8) or uint16(connect[11])

    var next = 12
    var clientId = connect[12..^1].decodeNextPayload()
    next += 2 + len(clientId)

    var will: Message
    if willFlag:
        var topic = connect[next..^1].decodeNextPayload()
        next += 2 + len(topic)
        var load = connect[next..^1].decodeNextPayload()
        next += 2 + len(load)
        will = Message(topic: topic.toString, payload: load, qos: willQOS, retain: willRetain)

    var username: string
    if usernameFlag:
        username = connect[next..^1].decodeNextPayload().toString
        next += 2 + len(userName)
    var password: string
    if passwordFlag:
        password = connect[next..^1].decodeNextPayload().toString

    result = newConnectPacket(clientId.toString, keepAlive, username, password, cleanSession, will)


when isMainModule:
  block:
      var connect = newConnectPacket("new-id", 25, "hello", "world", false)
      let e = connect.encode()
      let d = e.decodeConnect()
      doAssert d.clientId == "new-id"
      doAssert d.keepAlive == 25
      doAssert d.userName == "hello"
      doAssert d.password == "world"
      doAssert d.will == nil

  block:
      var will = Message(topic: "good/bye", payload: "take care".toSeq2, qos: 2, retain: true) 
      var connect = newConnectPacket("new-id", 25, "hello", "world", false, will)
      let e = connect.encode()
      let d = e.decodeConnect()
      doAssert d.clientId == "new-id"
      doAssert d.keepAlive == 25
      doAssert d.userName == "hello"
      doAssert d.password == "world"
      doAssert d.will.topic == will.topic
      doAssert d.will.payload == will.payload
      doAssert d.will.qos == will.qos
      doAssert d.will.retain == will.retain






