# Package

version       = "0.1.0"
author        = "Duncan Clarke"
description   = "Dark mode support module for wNim applications"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["examples"]

# Dependencies

requires "nim >= 1.6.0"
requires "wNim >= 0.13.0"
requires "winim >= 3.9.0"

# Tasks

task examples, "Build and run examples":
  exec "nim c -r examples/darkmode.nim"

task docs, "Generate documentation":
  # Note: Requires wNim and winim to be installed
  exec "nim doc --outdir:docs src/wDarkMode.nim"
