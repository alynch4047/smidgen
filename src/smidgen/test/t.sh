export LIBS=../libs
export SRC=.
rdmd -I$LIBS -I$SRC -Jsmidgen/test/ smidgen/test/tst.d -d 