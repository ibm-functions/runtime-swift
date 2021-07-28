OW_USER?=whisk
OW_COMPILER?=$(OW_USER)/action-swift-v4.2
OUT?=../../build/swift4.2
OW_COMPILER_5?=$(OW_USER)/action-swift-v5.4
OUT_5?=../../build/swift5.4

define Build4
	cd $(1); \
	docker run -i $(OW_COMPILER) -compile main <./Sources/main.swift >$(OUT)/$(1).zip
endef

define Build5
	cd $(1); \
	docker run -i $(OW_COMPILER_5) -compile main <./Sources/main.swift >$(OUT_5)/$(1).zip
endef

define BuildWithLib
	cd $(1); \
	sed -i.bak 's/4.0/4.2/' Package.swift; \
	zip - -r Package.swift Sources/main.swift | docker run -i $(OW_COMPILER) -compile main >$(OUT)/$(1).zip; \
	mv Package.swift.bak Package.swift
endef

define BuildWithLib5
	cd $(1); \
	sed -i.bak 's/4.0/5.3/' Package.swift; \
	zip - -r Package.swift Sources/main.swift | docker run -i $(OW_COMPILER_5) -compile main >$(OUT_5)/$(1).zip; \
	mv Package.swift.bak Package.swift
endef

Hello:
	$(call Build,HelloSwift4)
	$(call Build5,HelloSwift5)

HelloCodable:
	$(call Build,HelloSwift4Codable)
	$(call Build5,HelloSwift5Codable)

Swifty:
	$(call BuildWithLib,SwiftyRequest)
	$(call BuildWithLib5,SwiftyRequest)

SwiftyCodable:
	$(call BuildWithLib,SwiftyRequestCodable)
	$(call BuildWithLib5,SwiftyRequestCodable)

all: Hello HelloCodable Swifty SwiftyCodable

.PHONY: Hello HelloCodable Swifty SwiftyCodable