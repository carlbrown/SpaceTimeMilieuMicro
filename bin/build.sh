#!/bin/bash

swift package fetch
swift package edit Kitura --revision origin/swift-3.1
swift package edit HeliumLogger  --revision 1.6.0
swift package edit SpaceTimeMilieuModel  --revision origin/master
patch -p1 < NetHack.diff 
swift build
