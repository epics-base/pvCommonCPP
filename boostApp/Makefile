TOP = ..
include $(TOP)/configure/CONFIG

rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

SRC_DIRS += $(TOP)/boostApp/boost
INC += $(subst $(TOP)/boostApp/boost/,,$(call rwildcard,$(TOP)/boostApp/boost/boost,*.hpp))

vpath %.hpp $(USR_VPATH) $(ALL_SRC_DIRS)
include $(TOP)/configure/RULES
