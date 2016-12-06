import src.connect
import src.payload
import net, unittest

test "can connect to broker":
   var client = newSocket()
   client.connect("localhost", Port(1883))
   let conn = newConnectPacket("test-id", 30)
   let cpackets = conn.encode()
   client.send(cpackets.toString)




