#!/usr/bin/env python3
"""
Generates WalkableShanghai.xcodeproj/project.pbxproj.

Why this exists: neither xcodegen nor tuist is installed on this machine, and we
did not want to add a global tool dependency for a two-target project. This
script emits the pbxproj directly and deterministically.

It uses Xcode 16+ "file system synchronized groups" (objectVersion 77), which
means the project file does NOT enumerate source files. It points at the
Sources/ and Tests/ folders and Xcode picks up whatever is inside them. So you
almost never need to re-run this: adding, renaming or deleting a .swift file
requires no project change at all. Re-run it only to change targets, build
settings, or the deployment target.

Usage:  python3 Scripts/generate_project.py
"""

import os

PROJECT_NAME = "WalkableShanghai"
BUNDLE_ID = "com.walkableshanghai.app"
DEPLOYMENT_TARGET = "18.0"
# Swift 6 language mode, adopted in Phase 4.
#
# Phases 1-3 ran in Swift 5 mode on the reasoning that strict concurrency
# checking bought nothing on a single-actor SwiftUI app, with a note to revisit
# when real concurrency arrived. Phase 4's location stream is that moment:
# CoreLocation delivers fixes from its own queue, and the tracking session runs
# a ticker task alongside them.
#
# The migration cost turned out to be zero - the code already compiled clean
# under Swift 6 - because the concurrency was written down explicitly as it was
# added: the session and the location providers are `@MainActor`, and the
# CLLocationManagerDelegate callbacks are `nonisolated` and hop to the main
# actor by hand. Strict checking now holds that line for us instead of relying
# on it staying true by habit.
SWIFT_VERSION = "6.0"

# Deterministic 24-hex-char object IDs. Hand-assigned so regenerating the file
# produces a byte-identical result and diffs stay readable.
ID = {
    "project":          "A1000000000000000000001",
    "mainGroup":        "A1000000000000000000002",
    "productsGroup":    "A1000000000000000000003",
    "srcGroup":         "A1000000000000000000004",
    "testGroup":        "A1000000000000000000005",
    "appTarget":        "A1000000000000000000006",
    "testTarget":       "A1000000000000000000007",
    "appProductRef":    "A1000000000000000000008",
    "testProductRef":   "A1000000000000000000009",
    "appSources":       "A100000000000000000000A",
    "appFrameworks":    "A100000000000000000000B",
    "appResources":     "A100000000000000000000C",
    "testSources":      "A100000000000000000000D",
    "testFrameworks":   "A100000000000000000000E",
    "testResources":    "A100000000000000000000F",
    "projectCfgList":   "A1000000000000000000010",
    "appCfgList":       "A1000000000000000000011",
    "testCfgList":      "A1000000000000000000012",
    "projectDebug":     "A1000000000000000000013",
    "projectRelease":   "A1000000000000000000014",
    "appDebug":         "A1000000000000000000015",
    "appRelease":       "A1000000000000000000016",
    "testDebug":        "A1000000000000000000017",
    "testRelease":      "A1000000000000000000018",
    "testDependency":   "A1000000000000000000019",
    "testProxy":        "A100000000000000000001A",
    "uiGroup":          "A100000000000000000001B",
    "uiTarget":         "A100000000000000000001C",
    "uiProductRef":     "A100000000000000000001D",
    "uiSources":        "A100000000000000000001E",
    "uiFrameworks":     "A100000000000000000001F",
    "uiResources":      "A1000000000000000000020",
    "uiCfgList":        "A1000000000000000000021",
    "uiDebug":          "A1000000000000000000022",
    "uiRelease":        "A1000000000000000000023",
    "uiDependency":     "A1000000000000000000024",
    "uiProxy":          "A1000000000000000000025",
}
# pbxproj IDs are 24 characters; pad the readable ones out.
ID = {k: (v + "0" * 24)[:24] for k, v in ID.items()}


def settings_block(pairs, indent):
    pad = "\t" * indent
    return "\n".join(f"{pad}{k} = {v};" for k, v in pairs)


PROJECT_COMMON = [
    ("ALWAYS_SEARCH_USER_PATHS", "NO"),
    ("CLANG_ENABLE_MODULES", "YES"),
    ("CLANG_ENABLE_OBJC_ARC", "YES"),
    ("CODE_SIGNING_ALLOWED", "NO"),
    ("CODE_SIGNING_REQUIRED", "NO"),
    ("CODE_SIGN_IDENTITY", '"-"'),
    ("COPY_PHASE_STRIP", "NO"),
    ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
    ("GCC_NO_COMMON_BLOCKS", "YES"),
    ("IPHONEOS_DEPLOYMENT_TARGET", DEPLOYMENT_TARGET),
    ("SDKROOT", "iphoneos"),
    ("SWIFT_VERSION", SWIFT_VERSION),
    ("TARGETED_DEVICE_FAMILY", '"1"'),
]

PROJECT_DEBUG = PROJECT_COMMON + [
    ("DEBUG_INFORMATION_FORMAT", "dwarf"),
    ("ENABLE_TESTABILITY", "YES"),
    ("GCC_OPTIMIZATION_LEVEL", "0"),
    ("GCC_PREPROCESSOR_DEFINITIONS", '(\n\t\t\t\t\t"DEBUG=1",\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t)'),
    ("MTL_ENABLE_DEBUG_INFO", "INCLUDE_SOURCE"),
    ("ONLY_ACTIVE_ARCH", "YES"),
    ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", '"DEBUG $(inherited)"'),
    ("SWIFT_OPTIMIZATION_LEVEL", '"-Onone"'),
]

PROJECT_RELEASE = PROJECT_COMMON + [
    ("DEBUG_INFORMATION_FORMAT", '"dwarf-with-dsym"'),
    ("ENABLE_NS_ASSERTIONS", "NO"),
    ("MTL_ENABLE_DEBUG_INFO", "NO"),
    ("SWIFT_COMPILATION_MODE", "wholemodule"),
    ("VALIDATE_PRODUCT", "YES"),
]

APP_COMMON = [
    ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
    ("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME", "AccentColor"),
    ("CURRENT_PROJECT_VERSION", "1"),
    ("DEVELOPMENT_ASSET_PATHS", '""'),
    ("ENABLE_PREVIEWS", "YES"),
    ("GENERATE_INFOPLIST_FILE", "YES"),
    ("INFOPLIST_KEY_UIApplicationSceneManifest_Generation", "YES"),
    ("INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents", "YES"),
    ("INFOPLIST_KEY_UILaunchScreen_Generation", "YES"),
    ("INFOPLIST_KEY_UISupportedInterfaceOrientations", '"UIInterfaceOrientationPortrait"'),
    ("INFOPLIST_KEY_CFBundleDisplayName", "WalkableShanghai"),
    # Location. The base (English) values live here; zh-Hans comes from
    # Resources/InfoPlist.xcstrings, so the permission sheet is bilingual too.
    ("INFOPLIST_KEY_NSLocationWhenInUseUsageDescription",
     '"Walkable Shanghai uses your location to record the walk you are on: how far you have gone, how long it took, and how much of the route is left."'),
    ("INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription",
     '"Walkable Shanghai keeps recording your walk when the screen is locked, so putting your phone away does not cut the track short."'),
    # UIBackgroundModes has no INFOPLIST_KEY_ equivalent, so it comes from a
    # partial Info.plist that the generated keys are merged into. See
    # Config/Info.plist.
    ("INFOPLIST_FILE", "Config/Info.plist"),
    ("MARKETING_VERSION", "0.1"),
    ("PRODUCT_BUNDLE_IDENTIFIER", BUNDLE_ID),
    ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
    ("SWIFT_EMIT_LOC_STRINGS", "YES"),
]

TEST_COMMON = [
    ("BUNDLE_LOADER", '"$(TEST_HOST)"'),
    ("GENERATE_INFOPLIST_FILE", "YES"),
    ("PRODUCT_BUNDLE_IDENTIFIER", f"{BUNDLE_ID}.tests"),
    ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
    ("TEST_HOST", f'"$(BUILT_PRODUCTS_DIR)/{PROJECT_NAME}.app/{PROJECT_NAME}"'),
]

# UI tests drive the app from outside, so they get no BUNDLE_LOADER/TEST_HOST —
# they launch the app as a separate process and talk to it over the automation
# channel.
UITEST_COMMON = [
    ("GENERATE_INFOPLIST_FILE", "YES"),
    ("PRODUCT_BUNDLE_IDENTIFIER", f"{BUNDLE_ID}.uitests"),
    ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
    ("TEST_TARGET_NAME", PROJECT_NAME),
]


def build_pbxproj():
    i = ID
    return f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 77;
	objects = {{

/* Begin PBXFileReference section */
		{i['appProductRef']} /* {PROJECT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{i['testProductRef']} /* {PROJECT_NAME}Tests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {PROJECT_NAME}Tests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
		{i['uiProductRef']} /* {PROJECT_NAME}UITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {PROJECT_NAME}UITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		{i['srcGroup']} /* Sources */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			explicitFileTypes = {{
			}};
			explicitFolders = (
			);
			path = Sources;
			sourceTree = "<group>";
		}};
		{i['testGroup']} /* Tests */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			explicitFileTypes = {{
			}};
			explicitFolders = (
			);
			path = Tests;
			sourceTree = "<group>";
		}};
		{i['uiGroup']} /* UITests */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			explicitFileTypes = {{
			}};
			explicitFolders = (
			);
			path = UITests;
			sourceTree = "<group>";
		}};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXGroup section */
		{i['mainGroup']} = {{
			isa = PBXGroup;
			children = (
				{i['srcGroup']} /* Sources */,
				{i['testGroup']} /* Tests */,
				{i['uiGroup']} /* UITests */,
				{i['productsGroup']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{i['productsGroup']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{i['appProductRef']} /* {PROJECT_NAME}.app */,
				{i['testProductRef']} /* {PROJECT_NAME}Tests.xctest */,
				{i['uiProductRef']} /* {PROJECT_NAME}UITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXSourcesBuildPhase section */
		{i['appSources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{i['testSources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{i['uiSources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXFrameworksBuildPhase section */
		{i['appFrameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{i['testFrameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{i['uiFrameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXResourcesBuildPhase section */
		{i['appResources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{i['testResources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{i['uiResources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXContainerItemProxy section */
		{i['testProxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {i['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {i['appTarget']};
			remoteInfo = {PROJECT_NAME};
		}};
		{i['uiProxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {i['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {i['appTarget']};
			remoteInfo = {PROJECT_NAME};
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXTargetDependency section */
		{i['testDependency']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {i['appTarget']} /* {PROJECT_NAME} */;
			targetProxy = {i['testProxy']} /* PBXContainerItemProxy */;
		}};
		{i['uiDependency']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {i['appTarget']} /* {PROJECT_NAME} */;
			targetProxy = {i['uiProxy']} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin PBXNativeTarget section */
		{i['appTarget']} /* {PROJECT_NAME} */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {i['appCfgList']} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}" */;
			buildPhases = (
				{i['appSources']} /* Sources */,
				{i['appFrameworks']} /* Frameworks */,
				{i['appResources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				{i['srcGroup']} /* Sources */,
			);
			name = {PROJECT_NAME};
			packageProductDependencies = (
			);
			productName = {PROJECT_NAME};
			productReference = {i['appProductRef']} /* {PROJECT_NAME}.app */;
			productType = "com.apple.product-type.application";
		}};
		{i['testTarget']} /* {PROJECT_NAME}Tests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {i['testCfgList']} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}Tests" */;
			buildPhases = (
				{i['testSources']} /* Sources */,
				{i['testFrameworks']} /* Frameworks */,
				{i['testResources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{i['testDependency']} /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				{i['testGroup']} /* Tests */,
			);
			name = {PROJECT_NAME}Tests;
			packageProductDependencies = (
			);
			productName = {PROJECT_NAME}Tests;
			productReference = {i['testProductRef']} /* {PROJECT_NAME}Tests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
		{i['uiTarget']} /* {PROJECT_NAME}UITests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {i['uiCfgList']} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}UITests" */;
			buildPhases = (
				{i['uiSources']} /* Sources */,
				{i['uiFrameworks']} /* Frameworks */,
				{i['uiResources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{i['uiDependency']} /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				{i['uiGroup']} /* UITests */,
			);
			name = {PROJECT_NAME}UITests;
			packageProductDependencies = (
			);
			productName = {PROJECT_NAME}UITests;
			productReference = {i['uiProductRef']} /* {PROJECT_NAME}UITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{i['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2600;
				LastUpgradeCheck = 2600;
				TargetAttributes = {{
					{i['appTarget']} = {{
						CreatedOnToolsVersion = 26.0;
					}};
					{i['testTarget']} = {{
						CreatedOnToolsVersion = 26.0;
						TestTargetID = {i['appTarget']};
					}};
					{i['uiTarget']} = {{
						CreatedOnToolsVersion = 26.0;
						TestTargetID = {i['appTarget']};
					}};
				}};
			}};
			buildConfigurationList = {i['projectCfgList']} /* Build configuration list for PBXProject "{PROJECT_NAME}" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				"zh-Hans",
				Base,
			);
			mainGroup = {i['mainGroup']};
			minimizedProjectReferenceProxies = 1;
			preferredProjectObjectVersion = 77;
			productRefGroup = {i['productsGroup']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{i['appTarget']} /* {PROJECT_NAME} */,
				{i['testTarget']} /* {PROJECT_NAME}Tests */,
				{i['uiTarget']} /* {PROJECT_NAME}UITests */,
			);
		}};
/* End PBXProject section */

/* Begin XCBuildConfiguration section */
		{i['projectDebug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(PROJECT_DEBUG, 4)}
			}};
			name = Debug;
		}};
		{i['projectRelease']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(PROJECT_RELEASE, 4)}
			}};
			name = Release;
		}};
		{i['appDebug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(APP_COMMON, 4)}
			}};
			name = Debug;
		}};
		{i['appRelease']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(APP_COMMON, 4)}
			}};
			name = Release;
		}};
		{i['testDebug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(TEST_COMMON, 4)}
			}};
			name = Debug;
		}};
		{i['testRelease']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(TEST_COMMON, 4)}
			}};
			name = Release;
		}};
		{i['uiDebug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(UITEST_COMMON, 4)}
			}};
			name = Debug;
		}};
		{i['uiRelease']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings_block(UITEST_COMMON, 4)}
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{i['projectCfgList']} /* Build configuration list for PBXProject "{PROJECT_NAME}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{i['projectDebug']} /* Debug */,
				{i['projectRelease']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{i['appCfgList']} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{i['appDebug']} /* Debug */,
				{i['appRelease']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{i['testCfgList']} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}Tests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{i['testDebug']} /* Debug */,
				{i['testRelease']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{i['uiCfgList']} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}UITests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{i['uiDebug']} /* Debug */,
				{i['uiRelease']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {i['project']} /* Project object */;
}}
"""


SCHEME = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ID['appTarget']}"
               BuildableName = "{PROJECT_NAME}.app"
               BlueprintName = "{PROJECT_NAME}"
               ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ID['testTarget']}"
               BuildableName = "{PROJECT_NAME}Tests.xctest"
               BlueprintName = "{PROJECT_NAME}Tests"
               ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ID['uiTarget']}"
               BuildableName = "{PROJECT_NAME}UITests.xctest"
               BlueprintName = "{PROJECT_NAME}UITests"
               ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ID['appTarget']}"
            BuildableName = "{PROJECT_NAME}.app"
            BlueprintName = "{PROJECT_NAME}"
            ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ID['appTarget']}"
            BuildableName = "{PROJECT_NAME}.app"
            BlueprintName = "{PROJECT_NAME}"
            ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    proj = os.path.join(root, f"{PROJECT_NAME}.xcodeproj")
    schemes = os.path.join(proj, "xcshareddata", "xcschemes")
    os.makedirs(schemes, exist_ok=True)

    with open(os.path.join(proj, "project.pbxproj"), "w") as f:
        f.write(build_pbxproj())
    with open(os.path.join(schemes, f"{PROJECT_NAME}.xcscheme"), "w") as f:
        f.write(SCHEME)

    print(f"wrote {proj}/project.pbxproj")
    print(f"wrote {schemes}/{PROJECT_NAME}.xcscheme")


if __name__ == "__main__":
    main()
