//
//  CCCDevice.h
//  
//
//  Created by realtouchapp on 2016/10/11.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 裝置資訊
 *
 * @version 1.2.1
 * @author Chih-chieh Chang
 * @date 2019-10-14
 */
NS_ROOT_CLASS
@interface CCCDevice

/// 取得裝置型號識別字串 (Apple自定義的)
+ (NSString *)machine;
/// 取得裝置型號 (人們比較熟悉的格式)
+ (NSString *)model;
/// OS系統版本
+ (NSString *)version;

/// 螢幕像素點數 (Width x Height)
+ (NSString *)screenPixels;
/// 螢幕解析度
+ (NSString *)screenResolution;
/// 螢幕解析度縮放比
+ (NSString *)screenScale;
/// 螢幕是否為retina
+ (BOOL)isRetina;

/// 目前的app版本
+ (NSString *)appVersion;
/// 目前的app build版本號
+ (NSString *)appBuildVersion;

@end
