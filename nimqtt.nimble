# Package

version       = "0.1.0"
author        = "RT"
description   = "Mqtt protocol implementation in nim"
license       = "MIT"

# Dependencies

requires "nim >= 0.15.2"

task test, "Run the Nimble tester!":
  withDir "tests":
    exec "nim c -r alltests"
    exec "./test.sh"

