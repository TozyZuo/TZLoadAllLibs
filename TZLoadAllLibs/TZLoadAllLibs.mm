//
//  TZLoadAllLibs.mm
//  TZLoadAllLibs
//
//  Created by TozyZuo on 2018/9/5.
//  Copyright (c) 2018年 ___ORGANIZATIONNAME___. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import "CaptainHook/CaptainHook.h"

static NSDictionary *TZLoadLibsInDirectoryWithLoadedDylibPaths(NSString *directoryPath, NSArray *loadedDylibPaths)
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSFileManager *fm = NSFileManager.defaultManager;
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:directoryPath error:nil]) {
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        if ([fileName hasSuffix:@".framework"]) {
            NSBundle *bundle = [NSBundle bundleWithPath:filePath];
            if (bundle.isLoaded) {
                NSLog(@"TZLoadAllLibs: Bundle has been loaded. %@ %@", fileName, bundle);
            } else {
                if ([bundle load]) {
                    NSLog(@"TZLoadAllLibs: Load bundle success. %@ %@", fileName, bundle);
                } else {
                    NSLog(@"TZLoadAllLibs: Load bundle failed. %@ %@", fileName, bundle);
                }
            }
            dic[fileName] = @"";
        } else if ([fileName hasSuffix:@".bundle"] ||
                   [fileName hasSuffix:@".momd"] ||
                   [fileName hasSuffix:@".strings"] ||
                   [fileName hasSuffix:@".appex"] ||
                   [fileName hasSuffix:@".app"] ||
                   [fileName hasSuffix:@".lproj"] ||
                   [fileName hasSuffix:@".storyboardc"]) {
            dic[fileName] = @"";
        }
        else {
            BOOL isDirectory;
            [fm fileExistsAtPath:filePath isDirectory:&isDirectory];
            if (isDirectory) {
                dic[fileName] = TZLoadLibsInDirectoryWithLoadedDylibPaths(filePath, loadedDylibPaths);
            } else {
                if ([fileName hasSuffix:@".dylib"]) {
                    if ([loadedDylibPaths containsObject:filePath]) {
                        NSLog(@"TZLoadAllLibs: dylib has been loaded. %@ %@", fileName, filePath);
                    } else {
                        if (dlopen(filePath.UTF8String, RTLD_GLOBAL | RTLD_LAZY)) {
                            NSLog(@"TZLoadAllLibs: Load dylib success. %@ %@", fileName, filePath);
                        } else {
                            NSLog(@"TZLoadAllLibs: Load dylib failed. %@ %@", fileName, filePath);
                        }
                    }
                }
                dic[fileName] = @"";
            }
        }
    }

    return dic;
}

CHConstructor // code block that runs immediately upon load
{
	@autoreleasepool
	{
        NSString *appID = NSBundle.mainBundle.bundleIdentifier;
        if (!appID) {
            appID = NSProcessInfo.processInfo.processName;//A Fix By https://github.com/radj
            NSLog(@"TZLoadAllLibs: Process has no bundle ID, use process name instead: %@", appID);
        }
        NSLog(@"TZLoadAllLibs: %@ detected", appID);

        if ([[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/Tozy.TZLoadAllLibs.plist"][[NSString stringWithFormat:@"Enabled-%@", appID]] boolValue])
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                [NSBundle allFrameworks]; // 这句执行完所需framework应该都加载了

                NSMutableArray *loadedDylibPaths = [[NSMutableArray alloc] init];
                NSString *appPath = NSBundle.mainBundle.bundlePath;
                uint32_t count = _dyld_image_count();
                for (uint32_t i = 0; i < count; i++) {
                    NSString *dylibPath = @(_dyld_get_image_name(i));
                    if ([dylibPath hasPrefix:appPath]) {
                        [loadedDylibPaths addObject:dylibPath];
                    }
                }

                NSDictionary *dic = TZLoadLibsInDirectoryWithLoadedDylibPaths(appPath, loadedDylibPaths);
                NSLog(@"TZLoadAllLibs: File list\n%@", [dic.description stringByReplacingOccurrencesOfString:@" = \"\"" withString:@""]);
            });
        }
	}
}
