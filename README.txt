This repo contains a shell script to build pyodide with PyQt5. Can be used to port applications written in Python to the web.

How to build:
.............

  - Ensure to have all build-dependencies for Pyodide and Qt5 installed, as well as git, wget, sed and > 10GB of free space
  - Clone or download the repo
  - Exec ./build.sh and grab a beer...

This will download Pyodide, Qt5, Sip and PyQt5, apply some patches and hopefully produce a working build as pyodide/build/console.html.
Currently, QtCore, QtGui, QtWidgets and QtSvg will be built - but this should be easy to extend to other modules (as long they’re supported by Qt on the wasm platform; see https://wiki.qt.io/Qt_for_WebAssembly for more details).

This will be a static build (i.e. all Qt-dependend parts will be built directly into pyodide - not as a standard pyodide package that only gets loaded when imported). Shared builds are not possible at the moment as Qt itself only supports static builds for the web.

How to use:
...........
The package PyQt5 should be importable as usual. The only exception is QtWidgets.QApplication: Do *not* create a QApplication yourself. There's already one called "qtApp". Handle with care - it's the only one you'll get. Also, do *not* call exec_() on that qtApp - if the control flow is passed to python that one is already running. (You cannot use a standard event loop in wasm, so Emscripten uses some hacks to emulate one - which will crash pyodide if happening from within one of it's Python frames).


Known issues:
.............
When using the interactive shell, graphical updates may not be visible unless you emit some events to Qt (like moving the cursor over the canvas). Force a repaint with "qtApp.processEvents()".
