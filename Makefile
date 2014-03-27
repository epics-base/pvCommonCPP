# Makefile for the EPICS V4 pvCommon module

TOP = .
include $(TOP)/configure/CONFIG

DIRS := configure

DIRS += boostApp
boostApp_DEPEND_DIRS = configure

DIRS += mbApp
mbApp_DEPEND_DIRS = boostApp

DIRS += testApp
testApp_DEPEND_DIRS = mbApp

include $(TOP)/configure/RULES_TOP
