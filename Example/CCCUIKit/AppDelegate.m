//
//  AppDelegate.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/25.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "AppDelegate.h"

/*
 2018-11-23 11:28:13.769709+0800 CCCUIKit[74441:1301979] iPad6,12 (Simulator)
 2018-11-23 11:28:13.769995+0800 CCCUIKit[74441:1301979] iPad (5th generation) Simulator
 2018-11-23 11:28:13.770185+0800 CCCUIKit[74441:1301979] 9.7 inch
 2018-11-23 11:28:13.770371+0800 CCCUIKit[74441:1301979] 1536x2048
 2018-11-23 11:28:13.770762+0800 CCCUIKit[74441:1301979] x2
 2018-11-23 11:28:13.771108+0800 CCCUIKit[74441:1301979] {{0, 0}, {768, 1024}}
 2018-11-23 11:28:13.771381+0800 CCCUIKit[74441:1301979] {{0, 0}, {1536, 2048}}
 2018-11-23 11:28:13.771546+0800 CCCUIKit[74441:1301979] 2.000000
 2018-11-23 11:28:13.771792+0800 CCCUIKit[74441:1301979] 2.000000
 
 2018-11-23 11:32:03.651352+0800 CCCUIKit[74627:1305453] iPad7,6 (Simulator)
 2018-11-23 11:32:03.651639+0800 CCCUIKit[74627:1305453] iPad (6th generation) Simulator
 2018-11-23 11:32:03.651846+0800 CCCUIKit[74627:1305453] 9.7 inch
 2018-11-23 11:32:03.652023+0800 CCCUIKit[74627:1305453] 1536x2048
 2018-11-23 11:32:03.652149+0800 CCCUIKit[74627:1305453] x2
 2018-11-23 11:32:03.652338+0800 CCCUIKit[74627:1305453] {{0, 0}, {768, 1024}}
 2018-11-23 11:32:03.652507+0800 CCCUIKit[74627:1305453] {{0, 0}, {1536, 2048}}
 2018-11-23 11:32:03.652638+0800 CCCUIKit[74627:1305453] 2.000000
 2018-11-23 11:32:03.652770+0800 CCCUIKit[74627:1305453] 2.000000
 
 2018-11-23 11:35:27.801571+0800 CCCUIKit[74867:1310063] iPad4,2 (Simulator)
 2018-11-23 11:35:27.801854+0800 CCCUIKit[74867:1310063] iPad Air Simulator
 2018-11-23 11:35:27.802038+0800 CCCUIKit[74867:1310063] 9.7 inch
 2018-11-23 11:35:27.802180+0800 CCCUIKit[74867:1310063] 1536x2048
 2018-11-23 11:35:27.802302+0800 CCCUIKit[74867:1310063] x2
 2018-11-23 11:35:27.802470+0800 CCCUIKit[74867:1310063] {{0, 0}, {768, 1024}}
 2018-11-23 11:35:27.802632+0800 CCCUIKit[74867:1310063] {{0, 0}, {1536, 2048}}
 2018-11-23 11:35:27.802755+0800 CCCUIKit[74867:1310063] 2.000000
 2018-11-23 11:35:27.802880+0800 CCCUIKit[74867:1310063] 2.000000
 
 2018-11-23 11:40:55.398898+0800 CCCUIKit[75091:1316837] iPad5,4 (Simulator)
 2018-11-23 11:40:55.399184+0800 CCCUIKit[75091:1316837] iPad Air 2 Simulator
 2018-11-23 11:40:55.399370+0800 CCCUIKit[75091:1316837] 9.7 inch
 2018-11-23 11:40:55.399535+0800 CCCUIKit[75091:1316837] 1536x2048
 2018-11-23 11:40:55.399665+0800 CCCUIKit[75091:1316837] x2
 2018-11-23 11:40:55.399835+0800 CCCUIKit[75091:1316837] {{0, 0}, {768, 1024}}
 2018-11-23 11:40:55.399975+0800 CCCUIKit[75091:1316837] {{0, 0}, {1536, 2048}}
 2018-11-23 11:40:55.400101+0800 CCCUIKit[75091:1316837] 2.000000
 2018-11-23 11:40:55.400232+0800 CCCUIKit[75091:1316837] 2.000000
 
 2018-11-23 11:42:39.386584+0800 CCCUIKit[75269:1319763] iPad6,4 (Simulator)
 2018-11-23 11:42:39.386868+0800 CCCUIKit[75269:1319763] iPad Pro (9.7-inch) Simulator
 2018-11-23 11:42:39.387072+0800 CCCUIKit[75269:1319763] 9.7 inch
 2018-11-23 11:42:39.387269+0800 CCCUIKit[75269:1319763] 1536x2048
 2018-11-23 11:42:39.387393+0800 CCCUIKit[75269:1319763] x2
 2018-11-23 11:42:39.387617+0800 CCCUIKit[75269:1319763] {{0, 0}, {768, 1024}}
 2018-11-23 11:42:39.387981+0800 CCCUIKit[75269:1319763] {{0, 0}, {1536, 2048}}
 2018-11-23 11:42:39.388121+0800 CCCUIKit[75269:1319763] 2.000000
 2018-11-23 11:42:39.388815+0800 CCCUIKit[75269:1319763] 2.000000
 
 2018-11-23 11:45:24.394172+0800 CCCUIKit[75442:1323858] iPad7,4 (Simulator)
 2018-11-23 11:45:24.394614+0800 CCCUIKit[75442:1323858] iPad Pro (10.5-inch) Simulator
 2018-11-23 11:45:24.394854+0800 CCCUIKit[75442:1323858] 10.5 inch
 2018-11-23 11:45:24.395036+0800 CCCUIKit[75442:1323858] 1668x2224
 2018-11-23 11:45:24.395179+0800 CCCUIKit[75442:1323858] x2
 2018-11-23 11:45:24.395554+0800 CCCUIKit[75442:1323858] {{0, 0}, {834, 1112}}
 2018-11-23 11:45:24.395731+0800 CCCUIKit[75442:1323858] {{0, 0}, {1668, 2224}}
 2018-11-23 11:45:24.395862+0800 CCCUIKit[75442:1323858] 2.000000
 2018-11-23 11:45:24.396231+0800 CCCUIKit[75442:1323858] 2.000000
 
 2018-11-23 11:59:22.451877+0800 CCCUIKit[75843:1335723] iPad8,1 (Simulator)
 2018-11-23 11:59:22.452187+0800 CCCUIKit[75843:1335723] iPad Pro (11-inch) Simulator
 2018-11-23 11:59:22.452368+0800 CCCUIKit[75843:1335723] 11 inch
 2018-11-23 11:59:22.452540+0800 CCCUIKit[75843:1335723] 1668x2388
 2018-11-23 11:59:22.452663+0800 CCCUIKit[75843:1335723] x2
 2018-11-23 11:59:22.452839+0800 CCCUIKit[75843:1335723] {{0, 0}, {834, 1194}}
 2018-11-23 11:59:22.453010+0800 CCCUIKit[75843:1335723] {{0, 0}, {1668, 2388}}
 2018-11-23 11:59:22.453119+0800 CCCUIKit[75843:1335723] 2.000000
 2018-11-23 11:59:22.453253+0800 CCCUIKit[75843:1335723] 2.000000
 
 2018-11-23 12:01:05.766653+0800 CCCUIKit[76009:1338151] iPad6,8 (Simulator)
 2018-11-23 12:01:05.766920+0800 CCCUIKit[76009:1338151] iPad Pro (12.9-inch) Simulator
 2018-11-23 12:01:05.767111+0800 CCCUIKit[76009:1338151] 12.9 inch
 2018-11-23 12:01:05.767265+0800 CCCUIKit[76009:1338151] 2048x2732
 2018-11-23 12:01:05.767390+0800 CCCUIKit[76009:1338151] x2
 2018-11-23 12:01:05.767603+0800 CCCUIKit[76009:1338151] {{0, 0}, {1024, 1366}}
 2018-11-23 12:01:05.767784+0800 CCCUIKit[76009:1338151] {{0, 0}, {2048, 2732}}
 2018-11-23 12:01:05.767926+0800 CCCUIKit[76009:1338151] 2.000000
 2018-11-23 12:01:05.768053+0800 CCCUIKit[76009:1338151] 2.000000
 
 2018-11-23 12:02:53.371028+0800 CCCUIKit[76168:1340789] iPad7,1 (Simulator)
 2018-11-23 12:02:53.371291+0800 CCCUIKit[76168:1340789] iPad Pro (12.9-inch)(2nd generation) Simulator
 2018-11-23 12:02:53.371478+0800 CCCUIKit[76168:1340789] 12.9 inch
 2018-11-23 12:02:53.371627+0800 CCCUIKit[76168:1340789] 2048x2732
 2018-11-23 12:02:53.371822+0800 CCCUIKit[76168:1340789] x2
 2018-11-23 12:02:53.372007+0800 CCCUIKit[76168:1340789] {{0, 0}, {1024, 1366}}
 2018-11-23 12:02:53.372191+0800 CCCUIKit[76168:1340789] {{0, 0}, {2048, 2732}}
 2018-11-23 12:02:53.372376+0800 CCCUIKit[76168:1340789] 2.000000
 2018-11-23 12:02:53.372926+0800 CCCUIKit[76168:1340789] 2.000000
 
 2018-11-23 12:55:47.802514+0800 CCCUIKit[76381:1347076] iPad Pro (12.9-inch)(3rd generation) Simulator
 2018-11-23 12:55:47.802781+0800 CCCUIKit[76381:1347076] 12.9 inch
 2018-11-23 12:55:47.803016+0800 CCCUIKit[76381:1347076] 2048x2732
 2018-11-23 12:55:47.803170+0800 CCCUIKit[76381:1347076] x2
 2018-11-23 12:55:47.803428+0800 CCCUIKit[76381:1347076] {{0, 0}, {1024, 1366}}
 2018-11-23 12:55:47.803792+0800 CCCUIKit[76381:1347076] {{0, 0}, {2048, 2732}}
 2018-11-23 12:55:47.810999+0800 CCCUIKit[76381:1347076] 2.000000
 2018-11-23 12:55:47.811697+0800 CCCUIKit[76381:1347076] 2.000000
 */

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

@implementation CCCUINavigationController

- (BOOL)shouldAutorotate {
    return self.topViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.topViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}

@end
