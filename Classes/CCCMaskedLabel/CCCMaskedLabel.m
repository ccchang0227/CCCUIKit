//
//  CCCMaskedLabel.m
//
//  Created by CHIEN-HSU WU on 2015/3/20.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCMaskedLabel.h"


@interface CCCMaskedLabel () {
    UIColor *_backgroundColor;
}

@end

@implementation CCCMaskedLabel
@dynamic shadowColor;
@dynamic shadowOffset;

- (void)_setup {
    self.textStroked = NO;
    self.textStrokeWidth = 1.0f;
    self.backgroundLayer = nil;
    
    _backgroundColor = [[super backgroundColor] copy];
    [super setBackgroundColor:[UIColor clearColor]];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.textStroked = NO;
        self.textStrokeWidth = 1.0f;
        self.backgroundLayer = nil;
    }
    return self;
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [_backgroundLayer release];
    [super dealloc];
#endif
}

- (UIColor *)backgroundColor {
    return _backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        [_backgroundColor release];
        
        _backgroundColor = [backgroundColor copy];
        [super setBackgroundColor:[UIColor clearColor]];
    }
}

// Shadow effect not allowed.
- (void)setShadowColor:(UIColor *)shadowColor {
}
- (void)setShadowOffset:(CGSize)shadowOffset {
}

- (void)setTextStroked:(BOOL)textStroked {
    if (textStroked != _textStroked) {
        _textStroked = textStroked;
        
        [self setNeedsDisplay];
    }
}

- (void)setTextStrokeWidth:(CGFloat)textStrokeWidth {
    if (textStrokeWidth != _textStrokeWidth) {
        _textStrokeWidth = textStrokeWidth;
        
        [self setNeedsDisplay];
    }
}

- (void)setBackgroundLayer:(CALayer *)backgroundLayer {
    if (backgroundLayer != _backgroundLayer) {
#if !__has_feature(objc_arc)
        if (_backgroundColor) {
            [_backgroundColor release];
        }
#endif
        _backgroundLayer = [backgroundLayer retain];
        
        [self setNeedsDisplay];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    //[super drawRect:rect];return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, rect);
    
    if (self.backgroundLayer) {
        CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
        
        UIImage *textImage = [self _textImage:rect];
        
        CGContextSaveGState(context);
        CGContextClipToMask(context, rect, textImage.CGImage);
        
        CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
        
        CGLayerRef drawableLayer = CGLayerCreateWithContext(context, self.backgroundLayer.bounds.size, NULL);
        CGContextRef renderCtx = CGLayerGetContext(drawableLayer);
        
        [self.backgroundLayer renderInContext:renderCtx];
        
        CGContextDrawLayerInRect(context, rect, drawableLayer);
        
        CGLayerRelease(drawableLayer);
        drawableLayer = NULL;
        
        CGContextRestoreGState(context);
        
        CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
    }
    
    CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
    
    UIImage *mask = [self _maskImage:rect];
    
    CGContextSaveGState(context);
    CGContextClipToMask(context, rect, mask.CGImage);
    
    [_backgroundColor set];
    CGContextFillRect(context, rect);
    
    CGContextRestoreGState(context);
    
    if (_textStroked) {
        CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
        
        [self _drawTextInContext:context withDrawingMode:kCGTextStroke];
    }
}

- (UIImage *)_textImage:(CGRect)rect {
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 儲存textColor/attributedString屬性 (textColor的r, g, b其中一個為1時才能產生字是透明的mask)
    NSArray *attributions;
    UIColor *textColor;
    if (self.attributedText) {
        __block NSMutableArray *arrayAttrs = [NSMutableArray arrayWithCapacity:0];
        [self.attributedText enumerateAttributesInRange:NSMakeRange(0, self.attributedText.string.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
            NSMutableDictionary *dicAttr = [NSMutableDictionary dictionaryWithDictionary:attrs];
            dicAttr[@"range"] = [NSValue valueWithRange:range];
            [arrayAttrs addObject:dicAttr];
        }];
        attributions = arrayAttrs;
    }
    else {
        textColor = self.textColor;
    }
    
    [self setTextColor:[UIColor whiteColor]];
    [self _drawTextInContext:context withDrawingMode:kCGTextFill];
    
    // 回復原來的textColor/attributedString屬性
    if (self.attributedText) {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.attributedText.string];
        for (NSMutableDictionary *attrs in attributions) {
            NSRange range = [attrs[@"range"] rangeValue];
            attrs[@"range"] = nil;
            [string setAttributes:attrs range:range];
        }
        self.attributedText = string;
        [string release];
    }
    else {
        [self setTextColor:textColor];
    }
    
    CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
    
    // create a mask from the normally rendered text
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    UIGraphicsEndImageContext();
    
    UIImage *textImage = [UIImage imageWithCGImage:image];
    
    CFRelease(image);
    image = NULL;
    
    return textImage;
}

- (UIImage *)_maskImage:(CGRect)rect {
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 儲存textColor/attributedString屬性 (textColor的r, g, b其中一個為1時才能產生字是透明的mask)
    NSArray *attributions;
    UIColor *textColor;
    if (self.attributedText) {
        __block NSMutableArray *arrayAttrs = [NSMutableArray arrayWithCapacity:0];
        [self.attributedText enumerateAttributesInRange:NSMakeRange(0, self.attributedText.string.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
            NSMutableDictionary *dicAttr = [NSMutableDictionary dictionaryWithDictionary:attrs];
            [dicAttr setObject:[NSValue valueWithRange:range] forKey:@"range"];
            [arrayAttrs addObject:dicAttr];
        }];
        attributions = arrayAttrs;
    }
    else {
        textColor = self.textColor;
    }
    
    [self setTextColor:[UIColor whiteColor]];
    [self _drawTextInContext:context withDrawingMode:kCGTextFill];
    
    // 回復原來的textColor/attributedString屬性
    if (self.attributedText) {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.attributedText.string];
        for (NSMutableDictionary *attrs in attributions) {
            NSRange range = [attrs[@"range"] rangeValue];
            attrs[@"range"] = nil;
            [string setAttributes:attrs range:range];
        }
        self.attributedText = string;
        [string release];
    }
    else {
        [self setTextColor:textColor];
    }
    
    CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, CGRectGetHeight(rect)));
    
    // create a mask from the normally rendered text
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(image),
                                        CGImageGetHeight(image),
                                        CGImageGetBitsPerComponent(image),
                                        CGImageGetBitsPerPixel(image),
                                        CGImageGetBytesPerRow(image),
                                        CGImageGetDataProvider(image),
                                        CGImageGetDecode(image),
                                        CGImageGetShouldInterpolate(image));
    CFRelease(image);
    image = NULL;
    
    UIGraphicsEndImageContext();
    
    UIImage *maskImage = [UIImage imageWithCGImage:mask];
    
    CFRelease(mask);
    mask = NULL;
    
    return maskImage;
}

- (void)_drawTextInContext:(CGContextRef)ctx withDrawingMode:(CGTextDrawingMode)drawingMode {
    CGRect drawRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    CGFloat dy = (CGRectGetHeight(self.bounds) - CGRectGetHeight(drawRect)) / 2.0;
    drawRect = CGRectInset(self.bounds, 0, dy);
    
    //CGFloat width = [self textRectForBounds:CGRectMake(0, 0, CGFLOAT_MAX, CGRectGetHeight(self.bounds)) limitedToNumberOfLines:self.numberOfLines].size.width;
    //CGFloat height = [self textRectForBounds:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGFLOAT_MAX) limitedToNumberOfLines:self.numberOfLines].size.height;
    
    CGContextSetTextDrawingMode(ctx, drawingMode);
    CGContextSetLineWidth(ctx, self.textStrokeWidth);
    
    [self drawTextInRect:drawRect];
    
    /*
    if (self.attributedText) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        
        [attributedString drawInRect:drawRect];
        CCC_ARG_RELEASE(attributedString);
    }
    else {
        NSString *string = self.text;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            NSMutableParagraphStyle *paragraphStyle = CCC_EXP_AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
            paragraphStyle.lineBreakMode = self.lineBreakMode;
            paragraphStyle.alignment = self.textAlignment;
            NSDictionary *attribute = @{NSFontAttributeName:self.font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName:self.textColor};
            
            CGContextSetStrokeColorWithColor(ctx, self.textColor.CGColor);
            CGContextSetFillColorWithColor(ctx, self.textColor.CGColor);
            
            
            [string drawInRect:drawRect withAttributes:attribute];
        }
        else {
            CGContextSetStrokeColorWithColor(ctx, self.textColor.CGColor);
            CGContextSetFillColorWithColor(ctx, self.textColor.CGColor);
            CGContextSetFont(ctx, (CGFontRef)self.font);
            CGContextSetFontSize(ctx, self.font.pointSize);
            
            [string drawInRect:drawRect withFont:self.font lineBreakMode:self.lineBreakMode alignment:self.textAlignment];
        }
    }
    //*/
}

@end
