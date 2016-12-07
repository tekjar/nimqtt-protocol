import connect, connack, publish, subscribe, ack, pingreq, pingresp
import payload, type, header
import net

type 
   PacketKind = enum
      c,
      cack,
      p,
      pack,
      prec,
      prel,
      pcom,
      s,
      sack,
      preq,
      pres
    
   Packet = ref object
      case kind: PacketKind
      of c:
         connect: ConnectPacket
      of cack:
         connack: ConnackPacket
      of p:
         publish: PublishPacket
      of pack:
         puback: AckPacket
      of prec:
         pubrec: AckPacket
      of prel:
         pubrel: AckPacket
      of pcom:
         pubcomp: AckPacket
      of s:
         subscribe: SubscribePacket
      of sack:
         suback: AckPacket
      of preq:
         pingreq: PingreqPacket
      of pres:
         pingresp: PingrespPacket


proc packetDecode*(socket: Socket): Packet =
   let fixedHeaderRaw = socket.recv(2)
   let fixedHeader = decodeFixed(fixedHeaderRaw.toSeq2)

   case fixedHeader.control
   of CONNECT:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let connect = connect.decode(buffer)
      return Packet(kind: c, connect: connect)
   of CONNACK:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let connack = connack.decode(buffer)
      return Packet(kind: cack, connack: connack)
   of PUBLISH:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let publish = publish.decode(buffer)
      return Packet(kind: p, publish: publish)
   of PUBACK:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let puback = ack.decode(buffer)
      return Packet(kind: pack, puback: puback)
   of PUBREC:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let pubrec = ack.decode(buffer)
      return Packet(kind: prec, pubrec: pubrec)
   of PUBREL:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let pubrel = ack.decode(buffer)
      return Packet(kind: prel, pubrel: pubrel)
   of PUBCOMP:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let pubcomp = ack.decode(buffer)
      return Packet(kind: pcom, pubcomp: pubcomp)
   of SUBSCRIBE:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let subscribe = subscribe.decode(buffer)
      return Packet(kind: s, subscribe: subscribe)
   of SUBACK:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let suback = ack.decode(buffer)
      return Packet(kind: sack, suback: suback)
   of UNSUBSCRIBE, UNSUBACK:
      discard
   of PINGREQ:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let pingreq = pingreq.decode(buffer)
      return Packet(kind: preq, pingreq: pingreq)
   of PINGRESP:
      var buffer = newSeq[byte]()
      buffer.add(fixedHeaderRaw.toSeq2)
      let variableHeaderRaw = socket.recv(int(fixedHeader.remainingLen))
      buffer.add(variableHeaderRaw.toSeq2)
      let pingresp = pingresp.decode(buffer)
      return Packet(kind: pres, pingresp: pingresp)
   of DISCONNECT:
      discard