TOP = ..
include $(TOP)/configure/CONFIG

LIBRARY = pvMB

INSTALL_INCLUDE = $(INSTALL_LOCATION)/include/pv

#USR_CXXFLAGS += -DPV_MB

INC += mb.h

LIBSRCS += mb.cpp

pvMB_LIBS = Com

#PROD_HOST += mb_stat
#mb_stat_SRCS += mb_stat.cpp
#mb_stat_LIBS += pvMB Com

include $(TOP)/configure/RULES

