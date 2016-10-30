import packet, message
import sequtils


## Fixed header for CONNECT PACKET
##
## 7                          3                          0
## +--------------------------+--------------------------+
## |     CONNECT (1) NIBBLE   |     RESERVED             |
## +--------------------------+--------------------------+
## | Remaining Len = Len of Varable header(10) + Payload |
## +-----------------------------------------------------+
## 
##
## Variable header ( LENGTH = 10 Bytes)
##
## +--------------------------+--------------------------+
## |            PROTOCOL Name Length MSB (VALUE = 0)     |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |            PROTOCOL Name Length LSB (VALUE = 4)     |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          M                          |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          Q                          |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          T                          |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                          T                          |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |         PROTOCOL LEVEL (VALUE = 4 for MQTT 3.1.1)   |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |  CONNECT FLAGS                                      |
## |  UN(1 bit), PW(1), WR(1), WQ(2), W(1), CS(1), R(1)  |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                  KEEP ALIVE MSB                     |
## +-----------------------------------------------------+
## +--------------------------+--------------------------+
## |                  KEEP ALIVE LSB                     |
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


const BYTES_MQTT311: seq[byte] = toSeq("MQTT".items)
const MQTT311: byte = 4

type ConnectPacket* = ref object
  clientId: string
  keepAlive: uint16
  userName: string
  password: string
  cleanSession: bool
  will: Message
  version: byte

proc newConnectPacket*(clientId: string, keepAlive: uint16 = 10,
                      userName = "", password = "",
                      cleanSession = true, will: Message = nil): ConnectPacket =
  ConnectPacket(
        clientId: clientId,
        keepAlive: keepAlive,
        userName: userName,
        password: password,
        cleanSession: cleanSession,
        will: will,
        version: 4
  )

#
# Variable header length for CONNECT packet
proc len(connect: ConnectPacket): int =
  var total = 0

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

  total



