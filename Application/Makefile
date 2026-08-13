.PHONY: all clean build_clean

all: GreenSn0w.ipa

GreenSn0w.ipa: build/Build/Products/Debug-iphoneos/GreenSn0w.app
	@echo Ad-Hoc signing GreenSn0w
	xattr -rc build/Build/Products/Debug-iphoneos/GreenSn0w.app
	ldid -SGreenSn0w/GreenSn0w.entitlements build/Build/Products/Debug-iphoneos/GreenSn0w.app/GreenSn0w
	ldid -s build/Build/Products/Debug-iphoneos/GreenSn0w.app
	rm -rf Payload GreenSn0w.ipa
	mkdir Payload
	cp -r build/Build/Products/Debug-iphoneos/GreenSn0w.app Payload/GreenSn0w.app
	zip -Ar GreenSn0w.ipa Payload
	rm -rf Payload
	rm -rf GreenSn0w.tipa
	cp GreenSn0w.ipa GreenSn0w.tipa

ifeq ($(NIGHTLY), 1)
build/Build/Products/Debug-iphoneos/GreenSn0w.app: FORCE
	xcodebuild -scheme GreenSn0w -derivedDataPath build -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO GCC_PREPROCESSOR_DEFINITIONS='NIGHTLY=1 COMMIT_HASH=\"$(COMMIT_HASH)\"'
else
build/Build/Products/Debug-iphoneos/GreenSn0w.app: FORCE
	xcodebuild -scheme GreenSn0w -derivedDataPath build -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
endif

clean:
	rm -rf build Payload GreenSn0w.ipa GreenSn0w.tipa

build_clean:
	rm -rf Payload build

FORCE: ;