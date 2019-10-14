//
//  CCCDevice.m
//
//
//  Created by realtouchapp on 2016/10/11.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCDevice.h"
#import <sys/utsname.h>


@implementation CCCDevice

+ (NSString *)identifierString {
    if (TARGET_IPHONE_SIMULATOR) {
        return [NSString stringWithUTF8String:getenv("SIMULATOR_MODEL_IDENTIFIER")];
//        return @"Simulator";
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    return [NSString stringWithFormat:@"%@", deviceString];
    
    /*
     NSString *deviceName = nil;
     if (TARGET_IPHONE_SIMULATOR) deviceName = @"Simulator";
     else if ([deviceString compare:@"iPod1,1"] == NSOrderedSame) deviceName = @"iPod Touch";
     else if ([deviceString compare:@"iPod2,1"] == NSOrderedSame) deviceName = @"iPod Touch Second Generation";
     else if ([deviceString compare:@"iPod3,1"] == NSOrderedSame) deviceName = @"iPod Touch Third Generation";
     else if ([deviceString compare:@"iPod4,1"] == NSOrderedSame) deviceName = @"iPod Touch Fourth Generation";
     else if ([deviceString compare:@"iPhone1,1"] == NSOrderedSame) deviceName = @"iPhone";
     else if ([deviceString compare:@"iPhone1,2"] == NSOrderedSame) deviceName = @"iPhone 3G";
     else if ([deviceString compare:@"iPhone2,1"] == NSOrderedSame) deviceName = @"iPhone 3GS";
     else if ([deviceString compare:@"iPad1,1"] == NSOrderedSame) deviceName = @"iPad";
     else if ([deviceString compare:@"iPad2,1"] == NSOrderedSame) deviceName = @"iPad 2";
     else if ([deviceString compare:@"iPad2,2"] == NSOrderedSame) deviceName = @"iPad 2";
     else if ([deviceString compare:@"iPhone3,1"] == NSOrderedSame) deviceName = @"iPhone 4";
     else if ([deviceString compare:@"iPhone4,1"] == NSOrderedSame) deviceName = @"iPhone 4S";
     else if ([deviceString compare:@"iPhone5,1"] == NSOrderedSame) deviceName = @"iPhone 5";
     else if ([deviceString compare:@"iPhone5,2"] == NSOrderedSame) deviceName = @"iPhone 5";
     
     return deviceName;
     */
}

+ (NSString *)machine {
    NSString *machine = [self identifierString];
    if (TARGET_IPHONE_SIMULATOR) {
        machine = [machine stringByAppendingString:@" (Simulator)"];
    }
    
    return machine;
}

+ (NSString *)model {
    NSString *deviceIdentifier = [self identifierString];
    NSString *model = deviceIdentifier;
    
    if ([deviceIdentifier isEqualToString:@"iPhone1,1"]) {
        model = @"iPhone";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone1,2"]) {
        model = @"iPhone 3G";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone2,1"]) {
        model = @"iPhone 3Gs";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone3,1"] ||
             [deviceIdentifier isEqualToString:@"iPhone3,2"] ||
             [deviceIdentifier isEqualToString:@"iPhone3,3"]) {
        model = @"iPhone 4";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone4,1"] ||
             [deviceIdentifier isEqualToString:@"iPhone4,2"] ||
             [deviceIdentifier isEqualToString:@"iPhone4,3"]) {
        model = @"iPhone 4s";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone5,1"] ||
             [deviceIdentifier isEqualToString:@"iPhone5,2"]) {
        model = @"iPhone 5";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone5,3"] ||
             [deviceIdentifier isEqualToString:@"iPhone5,4"]) {
        model = @"iPhone 5c";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone6,1"] ||
             [deviceIdentifier isEqualToString:@"iPhone6,2"]) {
        model = @"iPhone 5s";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone7,2"]) {
        model = @"iPhone 6";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone7,1"]) {
        model = @"iPhone 6+";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone8,1"]) {
        model = @"iPhone 6s";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone8,2"]) {
        model = @"iPhone 6s+";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone8,4"]) {
        model = @"iPhone SE";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone9,1"] ||
             [deviceIdentifier isEqualToString:@"iPhone9,3"]) {
        model = @"iPhone 7";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone9,2"] ||
             [deviceIdentifier isEqualToString:@"iPhone9,4"]) {
        model = @"iPhone 7+";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone10,1"] ||
             [deviceIdentifier isEqualToString:@"iPhone10,4"]) {
        model = @"iPhone 8";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone10,2"] ||
             [deviceIdentifier isEqualToString:@"iPhone10,5"]) {
        model = @"iPhone 8+";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone10,3"] ||
             [deviceIdentifier isEqualToString:@"iPhone10,6"]) {
        model = @"iPhone X";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone11,2"]) {
        model = @"iPhone XS";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone11,4"] ||
             [deviceIdentifier isEqualToString:@"iPhone11,6"]) {
        model = @"iPhone XS Max";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone11,8"]) {
        model = @"iPhone XR";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone12,1"]) {
        model = @"iPhone 11";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone12,3"]) {
        model = @"iPhone 11 Pro";
    }
    else if ([deviceIdentifier isEqualToString:@"iPhone12,5"]) {
        model = @"iPhone 11 Pro Max";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad1,1"] ||
             [deviceIdentifier isEqualToString:@"iPad1,2"]) {
        model = @"iPad";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad2,1"] ||
             [deviceIdentifier isEqualToString:@"iPad2,2"] ||
             [deviceIdentifier isEqualToString:@"iPad2,3"] ||
             [deviceIdentifier isEqualToString:@"iPad2,4"]) {
        model = @"iPad 2";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad3,1"] ||
             [deviceIdentifier isEqualToString:@"iPad3,2"] ||
             [deviceIdentifier isEqualToString:@"iPad3,3"]) {
        model = @"iPad 3";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad3,4"] ||
             [deviceIdentifier isEqualToString:@"iPad3,5"] ||
             [deviceIdentifier isEqualToString:@"iPad3,6"]) {
        model = @"iPad 4";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad2,5"] ||
             [deviceIdentifier isEqualToString:@"iPad2,6"] ||
             [deviceIdentifier isEqualToString:@"iPad2,7"]) {
        model = @"iPad Mini";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad4,4"] ||
             [deviceIdentifier isEqualToString:@"iPad4,5"] ||
             [deviceIdentifier isEqualToString:@"iPad4,6"]) {
        model = @"iPad Mini 2";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad4,7"] ||
             [deviceIdentifier isEqualToString:@"iPad4,8"] ||
             [deviceIdentifier isEqualToString:@"iPad4,9"]) {
        model = @"iPad Mini 3";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad5,1"] ||
             [deviceIdentifier isEqualToString:@"iPad5,2"]) {
        model = @"iPad Mini 4";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad4,1"] ||
             [deviceIdentifier isEqualToString:@"iPad4,2"] ||
             [deviceIdentifier isEqualToString:@"iPad4,3"]) {
        model = @"iPad Air";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad5,3"] ||
             [deviceIdentifier isEqualToString:@"iPad5,4"]) {
        model = @"iPad Air 2";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad6,3"] ||
             [deviceIdentifier isEqualToString:@"iPad6,4"]) {
        model = @"iPad Pro (9.7-inch)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad7,3"] ||
             [deviceIdentifier isEqualToString:@"iPad7,4"]) {
        model = @"iPad Pro (10.5-inch)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad6,7"] ||
             [deviceIdentifier isEqualToString:@"iPad6,8"]) {
        model = @"iPad Pro (12.9-inch)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad7,1"] ||
             [deviceIdentifier isEqualToString:@"iPad7,2"]) {
        model = @"iPad Pro (12.9-inch)(2nd generation)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad8,5"] ||
             [deviceIdentifier isEqualToString:@"iPad8,6"] ||
             [deviceIdentifier isEqualToString:@"iPad8,7"] ||
             [deviceIdentifier isEqualToString:@"iPad8,8"]) {
        model = @"iPad Pro (12.9-inch)(3rd generation)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad8,1"] ||
             [deviceIdentifier isEqualToString:@"iPad8,2"] ||
             [deviceIdentifier isEqualToString:@"iPad8,3"] ||
             [deviceIdentifier isEqualToString:@"iPad8,4"]) {
        model = @"iPad Pro (11-inch)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad6,11"] ||
             [deviceIdentifier isEqualToString:@"iPad6,12"]) {
        model = @"iPad (5th generation)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPad7,5"] ||
             [deviceIdentifier isEqualToString:@"iPad7,6"]) {
        model = @"iPad (6th generation)";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod1,1"]) {
        model = @"iPodTouch 1";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod2,1"]) {
        model = @"iPodTouch 2";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod3,1"]) {
        model = @"iPodTouch 3";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod4,1"]) {
        model = @"iPodTouch 4";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod5,1"]) {
        model = @"iPodTouch 5";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod7,1"]) {
        model = @"iPodTouch 6";
    }
    else if ([deviceIdentifier isEqualToString:@"iPod9,1"]) {
        model = @"iPodTouch 7";
    }
    else if ([deviceIdentifier isEqualToString:@"AppleTV2,1"]) {
        return @"AppleTV 2";
    }
    else if ([deviceIdentifier isEqualToString:@"AppleTV3,1"] ||
             [deviceIdentifier isEqualToString:@"AppleTV3,2"]) {
        return @"AppleTV 3";
    }
    else if ([deviceIdentifier isEqualToString:@"AppleTV5,3"]) {
        return @"AppleTV 4";
    }
    else if ([deviceIdentifier isEqualToString:@"AppleTV6,2"]) {
        return @"AppleTV 4K";
    }
    else if ([deviceIdentifier isEqualToString:@"AudioAccessory1,1"]) {
        return @"HomePod";
    }
    else if ([deviceIdentifier isEqualToString:@"i386"] ||
             [deviceIdentifier isEqualToString:@"x86_64"]) {
//        model = @"Simulator";
    }
    
    if (TARGET_IPHONE_SIMULATOR) {
        model = [model stringByAppendingString:@" Simulator"];
    }
    
    return model;
}

+ (NSString *)version {
    return [UIDevice currentDevice].systemVersion;
}

+ (NSString *)screenPixels {
#if TARGET_OS_TV
    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
    CGFloat width = screenSize.width;
    CGFloat height = screenSize.height;
    CGFloat screenScale = [UIScreen mainScreen].nativeScale;
#else
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = MIN(screenSize.width, screenSize.height);
    CGFloat height = MAX(screenSize.width, screenSize.height);
    CGFloat screenScale = [UIScreen mainScreen].scale;
#endif
    
    width *= screenScale;
    height *= screenScale;
    
    return [NSString stringWithFormat:@"%ldx%ld", (long)width, (long)height];
}

+ (NSString *)screenResolution {
#if TARGET_OS_IOS
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat height = MAX(screenSize.width, screenSize.height);
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    // (CGSize) screenSize = (width = 414, height = 896)
    // (CGSize) screenSize = (width = 375, height = 812)
    // (CGSize) screenSize = (width = 414, height = 896)
    
    if (height == 480) {
        return @"3.5 inch";
    }
    else if (height == 568) {
        return @"4 inch";
    }
    else if (height == 667) {
        if (screenScale == 3.0) {
            return @"5.5 inch";
        }
        
        return @"4.7 inch";
    }
    else if (height == 736) {
        return @"5.5 inch";
    }
    else if (height == 812) {
        return @"5.8 inch";
    }
    else if (height == 896) {
        if (screenScale == 3.0) {
            return @"6.5 inch";
        }
        
        return @"6.1 inch";
    }
    else if (height == 1024) {
        NSString *model = [self model];
        if ([model hasPrefix:@"iPadMini"]) {
            return @"7.9 inch";
        }
        
        return @"9.7 inch";
    }
    else if (height == 1366) {
        return @"12.9 inch";
    }
    else if (height == 1112) {
        return @"10.5 inch";
    }
    else if (height == 1194) {
        return @"11 inch";
    }
#else
    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
    CGFloat width = screenSize.width;
    CGFloat height = screenSize.height;
//    CGFloat screenScale = [UIScreen mainScreen].nativeScale;
    
    if (width == 720 && height == 480) {
        return @"480p";
    }
    else if (width == 1280 && height == 720) {
        return @"720p(HD)";
    }
    else if (width == 1920 && height == 1080) {
        return @"1080p(FHD)";
    }
    else if (width == 1920 && height == 1200) {
        return @"WUXGA";
    }
    else if (width == 2048) {
        return @"2K";
    }
    else if (width == 2560 && height == 1440) {
        return @"1440p(QHD)";
    }
    else if (width == 3840 && height == 2160) {
        return @"2160p(4K)";
    }
    else if (width == 4096) {
        return @"\"Cinema\" 4K";
    }
    else if (width == 7680 && height == 4320) {
        return @"4320p(8K)";
    }
    else {
        return [NSString stringWithFormat:@"%ldx%ld", (long)width, (long)height];
    }
#endif
    
    return @"unknown";
}

+ (NSString *)screenScale {
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale == 1.0) {
        return @"x1";
    }
    else if (scale == 2.0) {
        return @"x2";
    }
    else if (scale == 3.0) {
        return @"x3";
    }
    
    return @"unknown";
}

+ (BOOL)isRetina {
    return ([UIScreen mainScreen].scale > 1.0);
}

+ (NSString *)appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)appBuildVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

@end
