import control.fixedheader

type
  ConnectPacket = ref object
    fixedHeader: FixedHeader
    protocolName: string
    protocolVer: byte
    cleanSession: bool
    willFlag: bool
    willQos: byte
    willRetain: bool
    usernameFlag: bool
    passwordFlag: bool
    reservedBit: byte
    keepaliveTimer: uint16
    clientIdentifier: string
    willTopic: string
    willMessage: seq[byte]
    username: string
    password: seq[byte]