type
  Control* = enum
    CONNECT = 1, CONNACK, PUBLISH, PUBACK, PUBREC, PUBREL,
    PUBCOMP, SUBSCRIBE, SUBACK, UNSUBSCRIBE, UNSUBACK,
    PINGREQ, PINGRESP, DISCONNECT

type Packet* = byte


proc toString*(t: Packet): string =
    var control = Control(t)
    case control:
        of CONNECT:
            result = "Connect"
        of CONNACK:
            result = "Connack"
        of PUBLISH:
            result = "Publish"
        of PUBACK:
            result = "Puback"
        of PUBREC:
            result = "Pubrec"
        of PUBREL:
            result = "Pubrel"
        of PUBCOMP:
            result = "Pubcomp"
        of SUBSCRIBE:
            result = "Subscribe"
        of SUBACK:
            result = "Suback"
        of UNSUBSCRIBE:
            result = "Unsubscribe"
        of UNSUBACK:
            result = "Unsuback"
        of PINGREQ:
            result = "Pingreq"
        of PINGRESP:
            result = "Pingresp"
        of DISCONNECT:
            result = "Disconnect"
        else:
            result = "Unknown"

proc toControl*(p: Packet): Control =
    result = Control(p)


proc default*(control: Packet): byte =
    var control = Control(control)
    case control:
        of CONNECT:
            result = 0
        of CONNACK:
            result = 0
        of PUBACK:
            result = 0
        of PUBREC:
            result = 0
        of PUBREL:
            result = 2 #00000010
        of PUBCOMP:
            result = 0
        of SUBSCRIBE:
            result = 2 #00000010
        of SUBACK:
            result = 0
        of UNSUBSCRIBE:
            result = 2 #00000010
        of UNSUBACK:
            result = 0
        of PINGREQ:
            result = 0
        of PINGRESP:
            result = 0
        of DISCONNECT:
            result = 0
        else:
            result = 0

##
## Encode control packet and flags into a single byte
##
proc pack*(self: Control , flags: uint8): uint8 =
    let control = self.ord()
    uint8(control shl 4) or (flags and 0x0F)

when isMainModule:
    block:
        doAssert 10.toString() == "Unsubscribe"