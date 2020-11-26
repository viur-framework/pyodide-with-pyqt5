#!/usr/bin/bash
set -e # Exit on first error

# Pyodide && emsdk
git clone https://github.com/iodide-project/pyodide.git
pushd pyodide/
git checkout 8c22c98a43e228c213f3f1dd7eae79ac88da4e90
PYODIDE_PACKAGES="toolz,attrs" make
pushd emsdk/emsdk/
source ./emsdk_env.sh
popd
popd

# Qt5
git clone https://code.qt.io/qt/qt5.git
pushd qt5/
git checkout 5.14
perl init-repository
./configure -xplatform wasm-emscripten -nomake examples -prefix $PWD/qtbase -feature-thread -opensource -confirm-license
make module-qtbase module-qtdeclarative qtsvg
popd


# Build a suitable SIP Tool into our HostPython
#wget https://www.riverbankcomputing.com/static/Downloads/sip/sip-5.5.0.dev2010281546.tar.gz
tar -xf sources/sip-5.5.0.dev2010281546.tar.gz
pushd sip-5.5.0.dev2010281546
../pyodide/cpython/build/3.8.2/host/bin/python3 setup.py install
popd

# SIP-Lib
#wget https://files.pythonhosted.org/packages/73/8c/c662b7ebc4b2407d8679da68e11c2a2eb275f5f2242a92610f6e5024c1f2/PyQt5_sip-12.8.1.tar.gz
tar -xf sources/PyQt5_sip-12.8.1.tar.gz
pushd PyQt5_sip-12.8.1/
mkdir build
emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c apiversions.c -o build/apiversions.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c voidptr.c -o build/voidptr.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c threads.c -o build/threads.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c objmap.c -o build/objmap.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c descriptors.c -o build/descriptors.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c array.c -o build/array.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall  -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c qtlib.c -o build/qtlib.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c int_convertors.c -o build/int_convertors.o && emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -DSIP_STATIC_MODULE=1 -g -fwrapv -O3 -Wall -I../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../pyodide/cpython/build/3.8.2/Python-3.8.2 -c siplib.c -o build/siplib.o && emar cqs libsip.a build/*.o
popd

# PY5-QT
#wget https://www.riverbankcomputing.com/static/Downloads/PyQt5/PyQt5-5.15.2.dev2011131516.tar.gz
tar -xf sources/PyQt5-5.15.2.dev2011131516.tar.gz
pushd PyQt5-5.15.2.dev2011131516/
patch < ../patches/pyqt5-configure.patch  # Patch configure.py to scope with non-executable test programms
../pyodide/cpython/build/3.8.2/host/bin/python3 ./configure.py --qmake ../qt5/qtbase/bin/qmake --static --confirm-license --sip ../pyodide/cpython/build/3.8.2/host/bin/sip5 --sip-incdir=../PyQt5_sip-12.8.1/
patch -p0 < ../patches/pyqt5-qpy-dir.patch  # Remove unsupported GL_DOUBLE

pushd QtCore
sed -i "s+-I../../pyodide/cpython/build/3.8.2/host/include/python3.8+-I../../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../../pyodide/cpython/build/3.8.2/Python-3.8.2+g" Makefile
patch < ../../patches/pyqt5-qtcore.patch  # Patch Make to include the correct python interpreter
make
popd

pushd QtGui
sed -i "s+-I../../pyodide/cpython/build/3.8.2/host/include/python3.8+-I../../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../../pyodide/cpython/build/3.8.2/Python-3.8.2+g" Makefile
patch <../../patches/pyqt5-qtgui.patch
make
popd

pushd QtWidgets
sed -i "s+-I../../pyodide/cpython/build/3.8.2/host/include/python3.8+-I../../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../../pyodide/cpython/build/3.8.2/Python-3.8.2+g" Makefile
patch < ../../patches/pyqt5-qtwidgets.patch
make
popd

pushd QtSvg
sed -i "s+-I../../pyodide/cpython/build/3.8.2/host/include/python3.8+-I../../pyodide/cpython/build/3.8.2/Python-3.8.2/Include -I../../pyodide/cpython/build/3.8.2/Python-3.8.2+g" Makefile
make
popd


popd # Exit PyQt

pushd pyodide
pushd src
patch -p0 < ../../patches/pyodide-main.patch  # Provide PyQt5 to Python
popd

# Rebuild main.c after patching
emcc -o src/main.bc -c src/main.c -O3 -g -Icpython/build/3.8.2/Python-3.8.2/Include -I cpython/build/3.8.2/Python-3.8.2 -Wno-warn-absolute-paths -Isrc/type_conversion/

# Re-Link Pyodide with static Qt/PyQt
em++ -s EXPORT_NAME="'pyodide'" -o build/pyodide.asm.html src/main.bc src/type_conversion/jsimport.bc src/type_conversion/jsproxy.bc src/type_conversion/js2python.bc src/type_conversion/pyimport.bc src/type_conversion/pyproxy.bc src/type_conversion/python2js.bc src/type_conversion/python2js_buffer.bc src/type_conversion/runpython.bc src/type_conversion/hiwire.bc -O3 -s MODULARIZE=1 cpython/installs/python-3.8.2/lib/libpython3.8.a packages/lz4/lz4-1.8.3/lib/liblz4.a -s "BINARYEN_METHOD='native-wasm'" -s TOTAL_MEMORY=20971520 -s ALLOW_MEMORY_GROWTH=1 -s MAIN_MODULE=1 -s EMULATED_FUNCTION_POINTERS=1 -s EMULATE_FUNCTION_POINTER_CASTS=1 -s LINKABLE=1 -s EXPORTED_FUNCTIONS='["___cxa_guard_acquire", "__ZNSt3__28ios_base4initEPv", "LZ4", "loadPackage", "LZ4.loadPackage", "pyodide", "runPython", "pyodide.runPython", "_main", "_LZ4_decompress_safe", "__runPython", "_runPython", "__js2python_jsproxy", "__pyimport", "__pyproxy_get", "__js2python_allocate_string", "__js2python_get_ptr", "__pyproxy_apply", "__findImports", "__js2python_none", "__js2python_pyproxy", "__js2python_number", "UTF16ToString","stringToUTF16"]'  -s WASM=1 -s SWAPPABLE_ASM_MODULE=1 -s USE_FREETYPE=1 -s USE_LIBPNG=1 -std=c++14 -Lcpython/build/sqlite-autoconf-3270200/.libs -lsqlite3 cpython/build/bzip2-1.0.2/libbz2.a -lstdc++ --memory-init-file 0 -s "BINARYEN_TRAP_MODE='clamp'" -s TEXTDECODER=0 -s LZ4=1 -s FORCE_FILESYSTEM=1 -l QtCore -L ../PyQt5-5.15.2.dev2011131516/QtCore -l Qt5Core -L ../qt5/qtbase/lib -l sip -L ../PyQt5_sip-12.8.1  -L ../PyQt5-5.15.2.dev2011131516/QtGui -l QtGui -L ../PyQt5-5.15.2.dev2011131516/QtWidgets -l QtWidgets -l Qt5Core -l Qt5Gui -l Qt5Widgets -l libqwasm -L ../qt5/qtbase/plugins/platforms -l Qt5FontDatabaseSupport -l libqminimal -l libQt5EventDispatcherSupport -l libqoffscreen --bind -s EXTRA_EXPORTED_RUNTIME_METHODS=["UTF16ToString","stringToUTF16"]  -s FULL_ES2=1 -s USE_WEBGL2=1 -l qtharfbuzz -l QtSvg -L ../PyQt5-5.15.2.dev2011131516/QtSvg -l qsvgicon -L ../qt5/qtbase/plugins/iconengines -L ../qt5/qtbase/plugins/imageformats -l libqjpeg -l libqsvg -l Qt5Svg

# Post-Process generated files to include a canvas
patch -p0 < ../patches/pyodide-builddir.patch

popd

echo "Done :)"





