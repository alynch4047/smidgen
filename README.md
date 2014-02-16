smidgen
=======

C++ binding generator for D2.

This project when built creates a binary called smidgen. This binary can then
be used to create a D wrapper for C++ libraries. 

A simple example, which is used for testing, can be seen in the morsel
and morseld directories. morsel is a simple set of C++ classes and morseld
is the result of using smidgen to wrap morsel. Once smidgen has been built you
can see the example C++ and D wrapper files inside the morseld/build directory.
You can also use the morseld/sip directory to see what sip files etc. are required
to wrap a C++ library. See USAGE for more info.

A fuller example
----------------
See the project smidgen-qt for a more complete example that is the
beginnings of a Qt5 wrapper.

Working platforms
-----------------
Currently working on Linux 64bit with dmd 2.064.

I believe it should be fairly simple to make it work for Windows and also for 32bit.

Installation
------------
See INSTALL for how to compile / install.

Using smidgen to wrap a C++ library
-----------------------------------
Read the USAGE document.
