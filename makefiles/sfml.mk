ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += sfml
SFML_VERSION := 2.6.1
DEB_SFML_V   ?= $(SFML_VERSION)

#https://github.com/SFML/SFML/archive/refs/tags/2.6.1.tar.gz

sfml-setup: setup
	$(call GITHUB_ARCHIVE,SFML,SFML,$(SFML_VERSION),refs/tags/$(SFML_VERSION))
	$(call EXTRACT_TAR,SFML-$(SFML_VERSION).tar.gz,SFML-$(SFML_VERSION),sfml)
	$(call DO_PATCH,sfml,sfml,-p1)
	mkdir -p $(BUILD_WORK)/sfml/build

ifneq ($(wildcard $(BUILD_WORK)/sfml/.build_complete),)
sfml:
	@echo "Using previously built sfml."
else
sfml: sfml-setup freetype libx11 libxcursor libxrandr
	cd $(BUILD_WORK)/sfml/build && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DPROCURSUS=ON -DSFML_BUILD_AUDIO=OFF \
		-DSFML_BUILD_NETWORK=OFF \
		-DSFML_USE_SYSTEM_DEPS=ON \
		-B . -S ..
	+$(MAKE) -C $(BUILD_WORK)/sfml/build
	+$(MAKE) -C $(BUILD_WORK)/sfml/build install \
		DESTDIR="$(BUILD_STAGE)/sfml"
	$(call AFTER_BUILD)
endif

sfml-package: sfml-stage
	# sfml.mk Package Structure
	rm -rf $(BUILD_DIST)/sfml

	# sfml.mk Prep sfml
	cp -a $(BUILD_STAGE)/sfml $(BUILD_DIST)

	# sfml.mk Sign
	$(call SIGN,sfml,general.xml)

	# sfml.mk Make .debs
	$(call PACK,sfml,DEB_SFML_V)

	# sfml.mk Build cleanup
	rm -rf $(BUILD_DIST)/sfml

.PHONY: sfml sfml-package
