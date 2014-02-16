export LIBS=../libs
export SRC=.
rdmd -I$LIBS -I$SRC -Jsmidgen/test/ -Jsmidgen smidgen/test/atst.d -d 