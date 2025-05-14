TARGET = iphone:clang:8.4
THEOS_DEVICE_IP = # TODO

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoDismissSiri
AutoDismissSiri_FILES = Tweak.xm
AutoDismissSiri_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

# SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
