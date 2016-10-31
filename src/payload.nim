const MAXPAYLOADSIZE = 65535


proc toSeq2(s: string): seq[byte] =
  result = @[]
  for x in s:
    result.add byte(x)



proc toString*(s: seq[byte]): string =
  result = ""
  for x in s:
    result.add char(x)



proc encodePayload*(payload: seq[byte]): seq[byte] =
  result = newSeq[byte]()
  var payloadLen = len(payload)

  if payloadLen > MAXPAYLOADSIZE:
    raise newException(OsError, "Payload Too Big")

  # split payload length into 2 bytes
  result.add(uint8(payloadLen shr 8))
  result.add(uint8(payloadLen))
  result.add(payload)



proc encodePayload*(payload: string): seq[byte] =
  var payload = toSeq2(payload)
  encodePayload(payload)



proc decodeNextPayload*(ePayLoad: seq[byte]): seq[byte] =
  if len(ePayLoad) < 2:
    raise newException(OsError, "Invalid Encoded Payload")

  result = newSeq[byte]()
  let payloadLen = (uint16(ePayLoad[0]) shl 8) or uint16(ePayLoad[1])

  for b in ePayLoad[2..2 + int(payloadLen - 1)]:
    result.add(b)



proc decodeNextStrPayload*(ePayload: seq[byte]): string =
    result = decodeNextPayload(ePayload).toString


when isMainModule:
  block:
    var e = "hellooooooooooooo".encodePayload()
    var d = e.decodeNextPayload()
    doAssert "hellooooooooooooo" == d.toString
