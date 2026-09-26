#!/usr/bin/env python3
"""Generate a dependency-free, deterministic Xcode project for the two iOS targets."""
from pathlib import Path
import hashlib, json
root = Path(__file__).resolve().parents[1]
ios = root / 'apps/ios'
project = ios / 'MementoMori.xcodeproj'
project.mkdir(exist_ok=True)
objects = {}
def uid(key): return hashlib.sha1(key.encode()).hexdigest()[:24].upper()
def add(key, body):
    objects[uid(key)] = body
    return uid(key)
def quote(value): return json.dumps(str(value))
def array(values): return '(' + ', '.join(values) + (',)' if values else ')')
def settings(values): return '{ ' + ' '.join(f'{key} = {quote(value)};' for key,value in values.items()) + ' }'
app_files = sorted(ios.glob('App/*.swift')) + sorted(ios.glob('Shared/*.swift'))
widget_files = sorted(ios.glob('Widgets/*.swift')) + sorted(ios.glob('Shared/*.swift'))
test_files = sorted(ios.glob('UITests/*.swift'))
resources = [ios/'Resources/PretendardVariable.ttf', ios/'Resources/pretendard-license.txt', ios/'Resources/PrivacyInfo.xcprivacy', ios/'Resources/Assets.xcassets']
all_files = sorted(set(app_files + widget_files + test_files + resources + [ios/'App/Info.plist',ios/'Widgets/Info.plist']))
refs=[]
for path in all_files:
    suffix=path.suffix
    kind={'.swift':'sourcecode.swift','.plist':'text.plist.xml','.ttf':'file','.txt':'text','.xcprivacy':'text.xml','.xcassets':'folder.assetcatalog'}[suffix]
    relative=path.relative_to(ios).as_posix()
    refs.append(add('file:'+relative, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(relative)}; sourceTree = "<group>";'))
products={}
for target,name,kind in [('app','MementoMori.app','wrapper.application'),('widget','MementoWidgets.appex','wrapper.app-extension'),('test','MementoMoriUITests.xctest','wrapper.cfbundle')]:
    products[target]=add('product:'+target,f'isa = PBXFileReference; explicitFileType = {kind}; path = {quote(name)}; sourceTree = BUILT_PRODUCTS_DIR;')
package=add('core-package','isa = XCLocalSwiftPackageReference; relativePath = ../../packages/memento-core;')
product_group=add('products','isa = PBXGroup; children = '+array(list(products.values()))+'; name = Products; sourceTree = "<group>";')
main_group=add('main-group','isa = PBXGroup; children = '+array(refs+[product_group])+'; sourceTree = "<group>";')
base={'SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'iphoneos','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','TARGETED_DEVICE_FAMILY':'1','CODE_SIGN_STYLE':'Automatic','MARKETING_VERSION':'0.1.0','CURRENT_PROJECT_VERSION':'1','CLANG_ENABLE_MODULES':'YES','ENABLE_USER_SCRIPT_SANDBOXING':'YES'}
project_configs=[]
for config in ['Debug','Release']:
    opts=base|({'ONLY_ACTIVE_ARCH':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG','DEBUG_INFORMATION_FORMAT':'dwarf'} if config=='Debug' else {'ONLY_ACTIVE_ARCH':'NO','SWIFT_OPTIMIZATION_LEVEL':'-O','DEBUG_INFORMATION_FORMAT':'dwarf-with-dsym'})
    project_configs.append(add('project:'+config, 'isa = XCBuildConfiguration; buildSettings = '+settings(opts)+'; name = '+config+';'))
project_config=add('project-config','isa = XCConfigurationList; buildConfigurations = '+array(project_configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
def dependency(source,target):
    proxy=add('proxy:'+source+target, f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("target:"+target)}; remoteInfo = {target};')
    return add('dependency:'+source+target,f'isa = PBXTargetDependency; target = {uid("target:"+target)}; targetProxy = {proxy};')
for target,files,name,bundle,kind in [('app',app_files,'MementoMori','com.rlagudals95.mementomori','com.apple.product-type.application'),('widget',widget_files,'MementoWidgets','com.rlagudals95.mementomori.widgets','com.apple.product-type.app-extension'),('test',test_files,'MementoMoriUITests','com.rlagudals95.mementomori.uitests','com.apple.product-type.bundle.ui-testing')]:
    builds=[]
    for path in files:
        relative=path.relative_to(ios).as_posix()
        builds.append(add('build:'+target+relative,f'isa = PBXBuildFile; fileRef = {uid("file:"+relative)};'))
    source_phase=add('sources:'+target,'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = '+array(builds)+'; runOnlyForDeploymentPostprocessing = 0;')
    res=[]
    if target!='test':
        for path in resources:
            if target=='widget' and path.suffix=='.xcassets': continue
            relative=path.relative_to(ios).as_posix()
            res.append(add('resource:'+target+relative,f'isa = PBXBuildFile; fileRef = {uid("file:"+relative)};'))
    resource_phase=add('resources:'+target,'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = '+array(res)+'; runOnlyForDeploymentPostprocessing = 0;')
    package_products=[]; frameworks=[]
    if target!='test':
        core=add('core:'+target,f'isa = XCSwiftPackageProductDependency; productName = MementoCore;')
        package_products.append(core)
        frameworks.append(add('linkcore:'+target,f'isa = PBXBuildFile; productRef = {core};'))
    framework_phase=add('frameworks:'+target,'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = '+array(frameworks)+'; runOnlyForDeploymentPostprocessing = 0;')
    phases=[source_phase,framework_phase,resource_phase]; deps=[]
    opts={'PRODUCT_NAME':name,'PRODUCT_BUNDLE_IDENTIFIER':bundle,'SWIFT_EMIT_LOC_STRINGS':'YES'}
    if target=='app':
        opts|={'INFOPLIST_FILE':'App/Info.plist','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','SUPPORTS_MACCATALYST':'NO'}
        embed=add('embedwidget',f'isa = PBXBuildFile; fileRef = {products["widget"]}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy,); }};')
        phases.append(add('embedphase','isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = '+array([embed])+'; name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;'))
        deps.append(dependency('app','widget'))
    elif target=='widget': opts|={'INFOPLIST_FILE':'Widgets/Info.plist','APPLICATION_EXTENSION_API_ONLY':'YES','SKIP_INSTALL':'YES'}
    else:
        opts|={'GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'MementoMori'}
        deps.append(dependency('test','app'))
    configs=[]
    for config in ['Debug','Release']:
        configs.append(add(target+config,'isa = XCBuildConfiguration; buildSettings = '+settings(opts)+'; name = '+config+';'))
    configlist=add('config:'+target,'isa = XCConfigurationList; buildConfigurations = '+array(configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    add('target:'+target,f'isa = PBXNativeTarget; buildConfigurationList = {configlist}; buildPhases = {array(phases)}; buildRules = (); dependencies = {array(deps)}; name = {name}; packageProductDependencies = {array(package_products)}; productName = {name}; productReference = {products[target]}; productType = {quote(kind)};')
add('project',f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{ {uid("target:app")} = {{ CreatedOnToolsVersion = 16.0; }}; {uid("target:widget")} = {{ CreatedOnToolsVersion = 16.0; }}; {uid("target:test")} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {uid("target:app")}; }}; }}; }}; buildConfigurationList = {project_config}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ko; knownRegions = (en, ko, Base); mainGroup = {main_group}; packageReferences = {array([package])}; productRefGroup = {product_group}; projectDirPath = ""; projectRoot = ""; targets = {array([uid("target:"+t) for t in ["app","widget","test"]])};')
content='// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'
content+='\n'.join(f'    {key} = {{ {value} }};' for key,value in sorted(objects.items()))
content+='\n}; rootObject = '+uid('project')+'; }\n'
(project/'project.pbxproj').write_text(content)
schemes=project/'xcshareddata/xcschemes'; schemes.mkdir(parents=True,exist_ok=True)
def ref(target,name): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:"+target)}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:MementoMori.xcodeproj" />'
(schemes/'MementoMori.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref('app','MementoMori.app')}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref('test','MementoMoriUITests.xctest')}</TestableReference></Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('app','MementoMori.app')}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{ref('app','MementoMori.app')}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated apps/ios/MementoMori.xcodeproj')
