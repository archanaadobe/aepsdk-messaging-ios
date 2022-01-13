export EXTENSION_NAME = AEPMessaging
export APP_NAME = MessagingDemoApp
CURRENT_DIRECTORY := ${CURDIR}
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = AEPMessagingXCF

SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
SIMULATOR_ARCHIVE_DSYM_PATH = $(CURRENT_DIRECTORY)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURRENT_DIRECTORY)/build/ios.xcarchive/dSYMs/

setup:
	(pod install)
	(cd SampleApps/$(APP_NAME) && pod install)

setup-tools: install-githook

pod-repo-update:
	(pod repo update)
	(cd SampleApps/$(APP_NAME) && pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(pod install --repo-update)
	(cd SampleApps/$(APP_NAME) && pod install --repo-update)

ci-pod-install:
	(bundle exec pod install --repo-update)
	(cd SampleApps/$(APP_NAME) && bundle exec pod install --repo-update)

pod-update: pod-repo-update
	(pod update)
	(cd SampleApps/$(APP_NAME) && pod update)

open:
	open $(PROJECT_NAME).xcworkspace

open-app:
	open ./SampleApps/$(APP_NAME)/*.xcworkspace

clean:
	(rm -rf build)

archive: pod-install
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework \
		-framework $(SIMULATOR_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM \
		-framework $(IOS_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM \
		-output ./build/$(TARGET_NAME_XCFRAMEWORK)

test:
	@echo "######################################################################"
	@echo "### Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES

install-githook:
	./tools/git-hooks/setup.sh

format: swift-format lint-autocorrect

swift-format:
	swiftformat . --swiftversion 5.1

lint-autocorrect:
	./Pods/SwiftLint/swiftlint autocorrect --format

lint:
	./Pods/SwiftLint/swiftlint lint AEPMessaging/Sources

check-version:
	(sh ./Script/version.sh $(VERSION))

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

test-podspec:
	(sh ./Script/test-podspec.sh)

functional-test: pod-install
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme FunctionalTests -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out
