type Message* = ref object
  topic*: string
  payload*: seq[byte]
  qos*: byte
  retain*: bool

proc newMessage*(topic: string, payload: seq[byte], qos: byte = 0, retain = false): Message =
   Message(
     topic: topic,
     payload: payload,
     qos: qos,
     retain: retain
   )
