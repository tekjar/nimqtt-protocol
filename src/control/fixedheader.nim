import packettype

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
    remainingLength: int