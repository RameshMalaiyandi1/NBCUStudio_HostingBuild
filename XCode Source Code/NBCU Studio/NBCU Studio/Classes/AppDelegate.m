/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

//
//  AppDelegate.m
//  NBCU Studio
//
//  Created by Aruna on 09/03/13.
//  Copyright igate 2013. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import <sys/xattr.h>


#ifdef CORDOVA_FRAMEWORK
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVURLProtocol.h>
#else
#import "CDVPlugin.h"
#import "CDVURLProtocol.h"
#endif


@implementation AppDelegate

@synthesize window, viewController;
NSString * const NSURLIsExcludedFromBackupKey =@"NSURLIsExcludedFromBackupKey";

- (id) init
{
	/** If you need to do any extra app-specific initialization, you can do it here
	 *  -jm
	 **/
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    [CDVURLProtocol registerURLProtocol];
    
    
    
    //Begin
    
    
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //
    //    // Get documents directory
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSString *formularyPath = [documentsDirectory stringByAppendingPathComponent:@"OfflineData"];
    //
    //    if (![[NSFileManager defaultManager] fileExistsAtPath:formularyPath])
    //        [[NSFileManager defaultManager] createDirectoryAtPath:formularyPath withIntermediateDirectories:NO attributes:nil error:nil];
    //
    //    // Prevent iCloud backup
    //    u_int8_t b = 1;
    //    setxattr([formularyPath fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
    
    
    //End
    
    
    
    return [super init];
}

#pragma UIApplicationDelegate implementation

/**
 * This is main kick off after the app inits, the views and Settings are setup here. (preferred - iOS4 and up)
 */
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [self addSkipBackupAttributeToItemAtURL:[self applicationDocumentsDirectory]];
    
    /* Fix problem with ios 5.0.1+ and Webkit databases described at the following urls:
     *   https://issues.apache.org/jira/browse/CB-347
     *   https://issues.apache.org/jira/browse/CB-330
     * My strategy is to move any existing database from default paths
     * to Documents/ and then changing app preferences accordingly
     */
    
    NSString* library = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    //    NSString* documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *localStorageSubdir = (IsAtLeastiOSVersion(@"5.1")) ? @"Caches" : @"WebKit/LocalStorage";
    NSString *localStoragePath = [library stringByAppendingPathComponent:localStorageSubdir];
    NSString *localStorageDb = [localStoragePath stringByAppendingPathComponent:@"file__0.localstorage"];
    
    NSString *WebSQLSubdir = (IsAtLeastiOSVersion(@"5.1")) ? @"Caches" : @"WebKit/Databases";
    NSString *WebSQLPath = [library stringByAppendingPathComponent:WebSQLSubdir];
    NSString *WebSQLIndex = [WebSQLPath stringByAppendingPathComponent:@"Databases.db"];
    NSString *WebSQLDb = [WebSQLPath stringByAppendingPathComponent:@"file__0"];
    
    NSString *ourLocalStoragePath = [library stringByAppendingPathComponent:@"LocalStorage"];;
    //NSString *ourLocalStorageDb = [documents stringByAppendingPathComponent:@"file__0.localstorage"];
    NSString *ourLocalStorageDb = [ourLocalStoragePath stringByAppendingPathComponent:@"file__0.localstorage"];
    
    NSString *ourWebSQLPath = [library stringByAppendingPathComponent:@"Databases"];
    NSString *ourWebSQLIndex = [ourWebSQLPath stringByAppendingPathComponent:@"Databases.db"];
    NSString *ourWebSQLDb = [ourWebSQLPath stringByAppendingPathComponent:@"file__0"];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    BOOL copy;
    NSError *err = nil;
    copy = [fileManager fileExistsAtPath:localStorageDb] && ![fileManager fileExistsAtPath:ourLocalStorageDb];
    if (copy) {
        [fileManager createDirectoryAtPath:ourLocalStoragePath withIntermediateDirectories:YES attributes:nil error:&err];
        [fileManager copyItemAtPath:localStorageDb toPath:ourLocalStorageDb error:&err];
        if (err == nil)
            [fileManager removeItemAtPath:localStorageDb error:&err];
    }
    
    err = nil;
    copy = [fileManager fileExistsAtPath:WebSQLPath] && ![fileManager fileExistsAtPath:ourWebSQLPath];
    if (copy) {
        [fileManager createDirectoryAtPath:ourWebSQLPath withIntermediateDirectories:YES attributes:nil error:&err];
        [fileManager copyItemAtPath:WebSQLIndex toPath:ourWebSQLIndex error:&err];
        [fileManager copyItemAtPath:WebSQLDb toPath:ourWebSQLDb error:&err];
        if (err == nil)
            [fileManager removeItemAtPath:WebSQLPath error:&err];
    }
    
    NSUserDefaults* appPreferences = [NSUserDefaults standardUserDefaults];
    NSBundle* mainBundle = [NSBundle mainBundle];
    
    NSString *bundlePath = [[mainBundle bundlePath] stringByDeletingLastPathComponent];
    NSString *bundleIdentifier = [[mainBundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString* libraryPreferences = @"Library/Preferences";
    
    NSString* appPlistPath = [[bundlePath stringByAppendingPathComponent:libraryPreferences]    stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", bundleIdentifier]];
    NSMutableDictionary* appPlistDict = [NSMutableDictionary dictionaryWithContentsOfFile:appPlistPath];
    
    BOOL dirty = NO;
    
    NSString *value;
    NSString *key = @"WebKitLocalStorageDatabasePathPreferenceKey";
    value = [appPlistDict objectForKey: key];
    if (![value isEqual:ourLocalStoragePath]) {
        [appPlistDict setValue:ourLocalStoragePath forKey:key];
        dirty = YES;
    }
    
    key = @"WebDatabaseDirectory";
    value = [appPlistDict objectForKey: key];
    if (![value isEqual:ourWebSQLPath]) {
        [appPlistDict setValue:ourWebSQLPath forKey:key];
        dirty = YES;
    }
    
    if (dirty)
    {
        BOOL ok = [appPlistDict writeToFile:appPlistPath atomically:YES];
        NSLog(@"Fix applied for database locations?: %@", ok? @"YES":@"NO");
        [appPreferences synchronize];
    }
    /* END Fix problem with ios 5.0.1+ and Webkit databases */
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    NSURL* url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    NSString* invokeString = nil;
    
    if (url && [url isKindOfClass:[NSURL class]]) {
        invokeString = [url absoluteString];
		NSLog(@"NBCU Studio launchOptions = %@", url);
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
    self.window.autoresizesSubviews = YES;
    
    CGRect viewBounds = [[UIScreen mainScreen] applicationFrame];
    
    self.viewController = [[[MainViewController alloc] init] autorelease];
    self.viewController.useSplashScreen = YES;
    self.viewController.wwwFolderName = @"www";
    self.viewController.startPage = @"html/universalLanding.html";
    self.viewController.invokeString = invokeString;
    self.viewController.view.frame = viewBounds;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    // check whether the current orientation is supported: if it is, keep it, rather than forcing a rotation
    BOOL forceStartupRotation = YES;
    UIDeviceOrientation curDevOrientation = [[UIDevice currentDevice] orientation];
    
    if (UIDeviceOrientationUnknown == curDevOrientation) {
        // UIDevice isn't firing orientation notifications yet… go look at the status bar
        curDevOrientation = (UIDeviceOrientation)[[UIApplication sharedApplication] statusBarOrientation];
    }
    
    if (UIDeviceOrientationIsValidInterfaceOrientation(curDevOrientation)) {
        for (NSNumber *orient in self.viewController.supportedOrientations) {
            if ([orient intValue] == curDevOrientation) {
                forceStartupRotation = NO;
                break;
            }
        }
    }
    
    if (forceStartupRotation) {
        NSLog(@"supportedOrientations: %@", self.viewController.supportedOrientations);
        // The first item in the supportedOrientations array is the start orientation (guaranteed to be at least Portrait)
        UIInterfaceOrientation newOrient = [[self.viewController.supportedOrientations objectAtIndex:0] intValue];
        NSLog(@"AppDelegate forcing status bar to: %d from: %d", newOrient, curDevOrientation);
        [[UIApplication sharedApplication] setStatusBarOrientation:newOrient];
    }
    
    
    [self.window setRootViewController:self.viewController];
    [self.window makeKeyAndVisible];
    
    return YES;
}

//- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
//{
//    if (&NSURLIsExcludedFromBackupKey == nil) { // iOS <= 5.0.1
//        const char* filePath = [[URL path] fileSystemRepresentation];
//
//        const char* attrName = "com.apple.MobileBackup";
//        u_int8_t attrValue = 1;
//
//        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
//        return result == 0;
//    } else { // iOS >= 5.1
//        NSError *error = nil;
//        [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
//        return error == nil;
//    }
//}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    if (&NSURLIsExcludedFromBackupKey == nil) { // iOS <= 5.0.1
        const char* filePath = [[URL path] fileSystemRepresentation];
        
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        return result == 0;
    } else { // iOS >= 5.1
        return [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
}


// this happens while we are running ( in the background, or from within our own app )
// only valid if NBCU Studio-Info.plist specifies a protocol to handle
- (BOOL) application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
    if (!url) {
        return NO;
    }
    
	// calls into javascript global function 'handleOpenURL'
    NSString* jsString = [NSString stringWithFormat:@"handleOpenURL(\"%@\");", url];
    [self.viewController.webView stringByEvaluatingJavaScriptFromString:jsString];
    
    // all plugins will get the notification, and their handlers will be called
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
    
    return YES;
}

- (void) dealloc
{
	[super dealloc];
}

@end
