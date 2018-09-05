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
#import "CaptainHook/CaptainHook.h"

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
                NSString *path = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks"];
                for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil])
                {
                    if ([file hasSuffix:@".framework"]) {
                        NSBundle *bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:file]];
                        if (bundle.isLoaded) {
                            NSLog(@"TZLoadAllLibs: Bundle has been loaded. %@ %@", file, bundle);
                        } else {
                            if ([bundle load]) {
                                NSLog(@"TZLoadAllLibs: Load bundle success. %@ %@", file, bundle);
                            } else {
                                NSLog(@"TZLoadAllLibs: Load bundle failed. %@ %@", file, bundle);
                            }
                        }
                    }
                }
            });
        }
	}
}
