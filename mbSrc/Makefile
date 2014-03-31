TOP = ..
include $(TOP)/configure/CONFIG

ifdef WITH_MICROBENCH
USR_CPPFLAGS += -DPV_MB

PROD_HOST += mb_stat
endif

LIBRARY = pvMB

INSTALL_INCLUDE = $(INSTALL_LOCATION)/include/pv

INC += mb.h

pvMB_SRCS += mb.cpp
pvMB_LIBS = Com

mb_stat_SRCS += mb_stat.cpp
mb_stat_LIBS += pvMB Com

include $(TOP)/configure/RULES

