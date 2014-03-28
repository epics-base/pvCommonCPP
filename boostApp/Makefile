# Makefile to install Boost headers

TOP = ..
include $(TOP)/configure/CONFIG

BOOST_SRC = $(TOP)/boostApp

SRC_DIRS += $(BOOST_SRC)/boost

# Recursive wildcard function. $1=path, $2=pattern
rwildcard = $(foreach d, $(wildcard $1*),\
    $(call rwildcard,$d/,$2)\
    $(filter $(subst *,%,$2), $d))

# Install all of Boost's .hpp files
INC += $(subst $(BOOST_SRC)/boost/,,\
    $(call rwildcard, $(BOOST_SRC)/boost/boost, *.hpp))

# Base doesn't have a vpath for .hpp files
vpath %.hpp $(USR_VPATH) $(ALL_SRC_DIRS)

include $(TOP)/configure/RULES
