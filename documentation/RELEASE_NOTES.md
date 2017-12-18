# pvCommonCPP Release Notes

## Release 4.2.3

The `mb.h` header has been updated to build properly against EPICS Base
versions prior to 3.15.0.1.

## Release 4.2.0

The Boost header files are now only installed for VxWorks target architectures,
since they are only essential for that OS. This prevents clashes with sofware
that has been built with a different version of Boost.

