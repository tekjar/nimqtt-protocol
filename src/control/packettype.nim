
type
  ControlType = enum
    CONNECT = 1, CONNACK, PUBLISH, PUBACK, PUBREC, PUBREL,
    PUBCOMP, SUBSCRIBE, SUBACK, UNSUBSCRIBE, UNSUBACK,
    PINGREQ, PINGRESP, DISCONNECT

type InvalidPacket = ref object of Exception
  error: ControlType
  description: string

proc newPacketException(error: ControlType, desc: string): InvalidPacket =
  InvalidPacket(error: error, description: desc)

##
## PacketType represents mqtt BYTE containing the encoded information
## packet type(e.g connect, ping etc) and flags associated with it
##
type
  PacketType* = ref object
    control: ControlType
    flags: uint8

proc newPacketType(control: ControlType, flags: uint8): PacketType =
  PacketType(control: control, flags: flags)

proc newPacketType(packed: uint8): PacketType =
  var control = ControlType(packed shr 4)
  var flags =  packed and 0x0F

  case control:
    of CONNECT:
      if flags != 0x00:
        raise newPacketException(control, "Invalid connect packet")
    of CONNACK:
      if flags != 0x00:
        raise newPacketException(control, "Invalid connack packet")
    of PUBLISH:
      if flags != 0x00:
        raise newPacketException(control, "Invalid publish packet")
    of PUBACK:
      if flags != 0x00:
        raise newPacketException(control, "Invalid puback packet")
    of PUBREC:
      if flags != 0x00:
        raise newPacketException(control, "Invalid pubrec packet")
    of PUBREL:
      if flags != 0x02:
        raise newPacketException(control, "Invalid pubrel packet")
    of PUBCOMP:
      if flags != 0x00:
        raise newPacketException(control, "Invalid pubcomp packet")
    of SUBSCRIBE:
      if flags != 0x02:
        raise newPacketException(control, "Invalid subscribe packet")
    of SUBACK:
      if flags != 0x00:
        raise newPacketException(control, "Invalid suback packet")
    of UNSUBSCRIBE:
      if flags != 0x02:
        raise newPacketException(control, "Invalid unsubscribe packet")
    of UNSUBACK:
      if flags != 0x00:
        raise newPacketException(control, "Invalid unsuback packet")
    of PINGREQ:
      if flags != 0x00:
        raise newPacketException(control, "Invalid pingreq packet")
    of PINGRESP:
      if flags != 0x00:
        raise newPacketException(control, "Invalid pingresp packet")
    of DISCONNECT:
      if flags != 0x00:
        raise newPacketException(control, "Invalid disconnect packet")
  
  newPacketType(control, flags)

##
## Encode based on control type and flags
##
proc pack(self: PacketType): uint8 =
  uint8(self.control.ord() shl 4) or (self.flags and 0x0F)