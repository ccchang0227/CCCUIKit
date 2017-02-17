//
//  CCCFloatRange.h
//
//  Created by realtouchapp on 2016/5/30.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#ifndef CCCFloatRange_h
#define CCCFloatRange_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef struct _CCCFloatRange {
    CGFloat location;
    CGFloat length;
} CCCFloatRange;

FOUNDATION_EXPORT CCCFloatRange const kCCCFloatEmptyRange;

FOUNDATION_EXPORT CCCFloatRange CCCMakeRange(CGFloat loc, CGFloat len);

FOUNDATION_EXPORT CGFloat CCCMaxRange(CCCFloatRange range);

FOUNDATION_EXPORT BOOL CCCLocationInRange(CGFloat loc, CCCFloatRange range);

FOUNDATION_EXPORT BOOL CCCEqualRanges(CCCFloatRange range1, CCCFloatRange range2);

FOUNDATION_EXPORT CCCFloatRange CCCUnionRange(CCCFloatRange range1, CCCFloatRange range2);

FOUNDATION_EXPORT CCCFloatRange CCCIntersectionRange(CCCFloatRange range1, CCCFloatRange range2);

FOUNDATION_EXPORT NSString *NSStringFromCCCFloatRange(CCCFloatRange range);

FOUNDATION_EXPORT CCCFloatRange CCCFloatRangeFromString(NSString *aString);


@interface NSValue (CCCValueRangeExtensions)

+ (NSValue *)valueWithCCCFloatRange:(CCCFloatRange)range;
@property (readonly) CCCFloatRange cccFloatRangeValue;

@end


#endif /* CCCFloatRange_h */
