TOP = ..
include $(TOP)/configure/CONFIG

MBTOP = $(TOP)/mbApp/

INSTALL_INCLUDE = $(INSTALL_LOCATION)/include/pv

SRC_DIRS += $(MBTOP)/mb
INC += mb.h
LIBSRCS += mb.cpp

PROD_HOST += mb_stat
mb_stat_CXXFLAGS += -DPV_MB
mb_stat_SRCS += mb_stat.cpp
mb_stat_LIBS += Com pvMB

LIBRARY = pvMB
pvMV_LIBS = Com

include $(TOP)/configure/RULES

