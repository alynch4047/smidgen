export LIBS=../../libs

rdmd -unittest --build-only -I$LIBS/Pegged -I$LIBS -ofsmidgen make_wrapping.d ast_classes.d parse_sip.d make_c_wrapper.d make_d_wrapper.d test_extras.d 