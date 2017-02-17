//
//  CCCFloatRange.m
//
//  Created by realtouchapp on 2016/5/30.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCFloatRange.h"


CCCFloatRange const kCCCFloatEmptyRange = {0, 0};

CCCFloatRange CCCMakeRange(CGFloat loc, CGFloat len) {
    CCCFloatRange r;
    r.location = loc;
    r.length = len;
    return r;
}

CGFloat CCCMaxRange(CCCFloatRange range) {
    return (range.location + range.length);
}

BOOL CCCLocationInRange(CGFloat loc, CCCFloatRange range) {
    return (!(loc < range.location) && (loc - range.location) < range.length) ? YES : NO;
}

BOOL CCCEqualRanges(CCCFloatRange range1, CCCFloatRange range2) {
    return (range1.location == range2.location && range1.length == range2.length);
}

CCCFloatRange CCCUnionRange(CCCFloatRange range1, CCCFloatRange range2) {
    CGFloat minRange1 = MIN(range1.location, CCCMaxRange(range1));
    CGFloat maxRange1 = MAX(range1.location, CCCMaxRange(range1));
    CGFloat minRange2 = MIN(range2.location, CCCMaxRange(range2));
    CGFloat maxRange2 = MIN(range2.location, CCCMaxRange(range2));
    
    CCCFloatRange newRange = kCCCFloatEmptyRange;
    
    CGFloat minValue = MIN(minRange1, minRange2);
    CGFloat maxValue = MAX(maxRange1, maxRange2);
    newRange.location = minValue;
    newRange.length = maxValue-minValue;
    
    return newRange;
}

CCCFloatRange CCCIntersectionRange(CCCFloatRange range1, CCCFloatRange range2) {
    CGFloat minRange1 = MIN(range1.location, CCCMaxRange(range1));
    CGFloat maxRange1 = MAX(range1.location, CCCMaxRange(range1));
    CGFloat minRange2 = MIN(range2.location, CCCMaxRange(range2));
    CGFloat maxRange2 = MIN(range2.location, CCCMaxRange(range2));
    
    CCCFloatRange newRange = kCCCFloatEmptyRange;
    if ((maxRange1 < minRange2) || (maxRange2 < minRange1)) {
        // No Intersection
        return newRange;
    }
    
    newRange.location = MAX(minRange1, minRange2);
    newRange.length = MIN(maxRange1, maxRange2)-newRange.location;
    
    return newRange;
}

NSString *NSStringFromCCCFloatRange(CCCFloatRange range) {
    return [NSString stringWithFormat:@"{%f, %f}", range.location, range.length];
}

CCCFloatRange CCCFloatRangeFromString(NSString *aString) {
    CCCFloatRange range = kCCCFloatEmptyRange;
    if (!aString || aString.length == 0) {
        return range;
    }
    
    aString = [aString stringByReplacingOccurrencesOfString:@"{" withString:@""];
    aString = [aString stringByReplacingOccurrencesOfString:@"}" withString:@""];
    aString = [aString stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (!aString || aString.length == 0) {
        return range;
    }
    
    NSArray *seperatedString = [aString componentsSeparatedByString:@","];
    if (seperatedString.count > 0) {
        range.location = [seperatedString[0] floatValue];
        if (seperatedString.count > 1) {
            range.length = [seperatedString[1] floatValue];
        }
    }
    
    return range;
}


@implementation NSValue (CCCValueRangeExtensions)

+ (NSValue *)valueWithCCCFloatRange:(CCCFloatRange)range {
    return [NSValue value:&range withObjCType:@encode(CCCFloatRange)];
}

- (CCCFloatRange)cccFloatRangeValue {
    if (strcmp(self.objCType, @encode(CCCFloatRange)) != 0) {
        return kCCCFloatEmptyRange;
    }
    
    CCCFloatRange range = kCCCFloatEmptyRange;
    [self getValue:&range];
    
    return range;
}

@end
