import nimqtt.connect, nimqtt.connack, nimqtt.publish
import nimqtt.subscribe, nimqtt.ack, nimqtt.pingreq, nimqtt.pingresp
import nimqtt.payload, nimqtt.type, nimqtt.header
import net

type 
   PacketKind = enum
      kConnect,
      kConnack,
      kPublish,
      kPuback,
      kPubrec,
      kPubrel,
      kPubcomp,
      kSubscribe,
      kSuback,
      kPingreq,
      kPingresp
   Packet = ref object 
      case kind*: PacketKind
      of kConnect:
         connect: ConnectPacket
      of kConnack:
         connack*: ConnackPacket
      of kPublish:
         publish: PublishPacket
      of kPuback:
         puback: AckPacket
      of kPubrec:
         pubrec: AckPacket
      of kPubrel:
         pubrel: AckPacket
      of kPubcomp:
         pubcomp: AckPacket
      of kSubscribe:
         subscribe: SubscribePacket
      of kSuback:
         suback: AckPacket
      of kPingreq:
         pingreq: PingreqPacket
      of kPingresp:
         pingresp: PingrespPacket


proc packetDecode*(socket: Socket): Packet =
   let fixedHeaderRaw = socket.recv(2)
   let fixedHeader = decodeFixed(fixedHeaderRaw.toSeq2)

   var buffer = newSeq[byte]()
   buffer.add(fixedHeaderRaw.toSeq2)
   let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
   buffer.add(variableHeaderRaw.toSeq2)

   case fixedHeader.control
   of CONNECT:
      let connect = connect.decode(buffer)
      return Packet(kind: kConnect, connect: connect)
   of CONNACK:
      let connack = connack.decode(buffer)
      return Packet(kind: kConnack, connack: connack)
   of PUBLISH:
      let publish = publish.decode(buffer)
      return Packet(kind: kPublish, publish: publish)
   of PUBACK:
      let puback = ack.decode(buffer)
      return Packet(kind: kPuback, puback: puback)
   of PUBREC:
      let pubrec = ack.decode(buffer)
      return Packet(kind: kPubrec, pubrec: pubrec)
   of PUBREL:
      let pubrel = ack.decode(buffer)
      return Packet(kind: kPubrel, pubrel: pubrel)
   of PUBCOMP:
      let pubcomp = ack.decode(buffer)
      return Packet(kind: kPubcomp, pubcomp: pubcomp)
   of SUBSCRIBE:
      let subscribe = subscribe.decode(buffer)
      return Packet(kind: kSubscribe, subscribe: subscribe)
   of SUBACK:
      let suback = ack.decode(buffer)
      return Packet(kind: kSuback, suback: suback)
   of UNSUBSCRIBE, UNSUBACK:
      discard
   of PINGREQ:
      let pingreq = pingreq.decode(buffer)
      return Packet(kind: kPingreq, pingreq: pingreq)
   of PINGRESP:
      let pingresp = pingresp.decode(buffer)
      return Packet(kind: kPingresp, pingresp: pingresp)
   of DISCONNECT:
      discard