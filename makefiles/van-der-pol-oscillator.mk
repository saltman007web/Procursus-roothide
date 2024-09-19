ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += van-der-pol-oscillator
VAN_DER_POL_OSCILLATOR_VERSION := 0.1
DEB_VAN_DER_POL_OSCILLATOR_V   ?= $(VAN_DER_POL_OSCILLATOR_VERSION)

van-der-pol-oscillator-setup: setup
	$(call GIT_CLONE,https://github.com/A-lida/Van-der-Pol-Oscillator.git,main,van-der-pol-oscillator)

	mkdir -p $(BUILD_WORK)/van-der-pol-oscillator/build

ifneq ($(wildcard $(BUILD_WORK)/van-der-pol-oscillator/.build_complete),)
van-der-pol-oscillator:
	@echo "Using previously built van-der-pol-oscillator."
else
van-der-pol-oscillator: van-der-pol-oscillator-setup sfml
	cd $(BUILD_WORK)/van-der-pol-oscillator/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) -DSFML_DIR=$(BUILD_BASE)/usr/lib/cmake/SFML \
		..
	+$(MAKE) -C $(BUILD_WORK)/van-der-pol-oscillator/build
	+$(MAKE) -C $(BUILD_WORK)/van-der-pol-oscillator/build install \
		DESTDIR="$(BUILD_STAGE)/van-der-pol-oscillator"
	$(call AFTER_BUILD)
endif

van-der-pol-oscillator-package: van-der-pol-oscillator-stage
	# van-der-pol-oscillator.mk Package Structure
	rm -rf $(BUILD_DIST)/van-der-pol-oscillator

	# van-der-pol-oscillator.mk Prep van-der-pol-oscillator
	cp -a $(BUILD_STAGE)/van-der-pol-oscillator $(BUILD_DIST)

	# van-der-pol-oscillator.mk Sign
	$(call SIGN,van-der-pol-oscillator,general.xml)

	# van-der-pol-oscillator.mk Make .debs
	$(call PACK,van-der-pol-oscillator,DEB_VAN_DER_POL_OSCILLATOR_V)

	# van-der-pol-oscillator.mk Build cleanup
	rm -rf $(BUILD_DIST)/van-der-pol-oscillator

.PHONY: van-der-pol-oscillator van-der-pol-oscillator-package
