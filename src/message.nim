type Message* = ref object
  topic*: string
  payload*: seq[byte]
  qos: byte
  retain: bool
