OUT_DIR=../../public/blog
RESIZE=-resize 1280x
SOURCES=$(wildcard *-banner.jpg)
TARGETS=$(patsubst %-banner.jpg, $(OUT_DIR)/%.jpg, $(SOURCES))

define DEFINE_RULE
$(OUT_DIR)/$(1).jpg : $(1)-banner.jpg
	echo - $(1) && magick $(1)-banner.jpg $(RESIZE) JPG:- | cjpeg -quality $(2) > $(OUT_DIR)/$(1).jpg
endef

ADD_IMAGE=$(eval $(call DEFINE_RULE,$(strip $1), $(strip $2)))

autorun : $(TARGETS);

$(call ADD_IMAGE, exhaustiveness-checks-in-typescript, 75)
