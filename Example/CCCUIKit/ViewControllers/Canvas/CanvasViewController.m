//
//  CanvasViewController.m
//  CCCUIKit
//
//  Created by CHIEN-HSU WU on 2015/5/19.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CanvasViewController.h"
#import <CCCUIKit/CCCCanvas.h>
#import <CCCUIKit/CCCRatingControl.h>

@interface CanvasViewController () <CCCCanvasDelegate>

@property (weak, nonatomic) IBOutlet CCCCanvas *canvas;

@property (weak, nonatomic) IBOutlet UIButton *btnPen;
@property (weak, nonatomic) IBOutlet UIButton *btnLine;
@property (weak, nonatomic) IBOutlet UIButton *btnCurve;
@property (weak, nonatomic) IBOutlet UIButton *btnEraser;
@property (weak, nonatomic) IBOutlet UIButton *btnStrokePolygon;
@property (weak, nonatomic) IBOutlet UIButton *btnFillPolygon;
@property (weak, nonatomic) IBOutlet UIButton *btnFillRect;
@property (weak, nonatomic) IBOutlet UIButton *btnStrokeRect;
@property (weak, nonatomic) IBOutlet UIButton *btnFillEllipse;
@property (weak, nonatomic) IBOutlet UIButton *btnStrokeEllipse;

@property (strong, nonatomic) NSArray *arrayModeButtons;

@property (weak, nonatomic) IBOutlet UIButton *btnUndo;
@property (weak, nonatomic) IBOutlet UIButton *btnRedo;

@end

@implementation CanvasViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Canvas";
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:starImage(CGSizeMake(20, 20), [UIColor yellowColor], [UIColor yellowColor], YES) style:UIBarButtonItemStylePlain target:self action:@selector(unsecretStarAction:)];
    self.navigationItem.rightBarButtonItem = barButton;
    
    self.canvas.delegate = self;
    
    [self.btnPen setTag:CCCCanvasPathPen];
    [self.btnLine setTag:CCCCanvasPathStraightLine];
    [self.btnCurve setTag:CCCCanvasPathCurveLine];
    [self.btnEraser setTag:CCCCanvasPathEraser];
    [self.btnFillPolygon setTag:CCCCanvasPathFillPolygon];
    [self.btnStrokePolygon setTag:CCCCanvasPathStrokePolygon];
    [self.btnFillRect setTag:CCCCanvasPathFillRect];
    [self.btnStrokeRect setTag:CCCCanvasPathStrokeRect];
    [self.btnFillEllipse setTag:CCCCanvasPathFillEllipse];
    [self.btnStrokeEllipse setTag:CCCCanvasPathStrokeEllipse];
    
    [self.btnFillPolygon setImage:[CanvasViewController buttonImageForCanvasPath:self.btnFillPolygon.tag] forState:UIControlStateNormal];
    [self.btnStrokePolygon setImage:[CanvasViewController buttonImageForCanvasPath:self.btnStrokePolygon.tag] forState:UIControlStateNormal];
    [self.btnFillRect setImage:[CanvasViewController buttonImageForCanvasPath:self.btnFillRect.tag] forState:UIControlStateNormal];
    [self.btnStrokeRect setImage:[CanvasViewController buttonImageForCanvasPath:self.btnStrokeRect.tag] forState:UIControlStateNormal];
    [self.btnFillEllipse setImage:[CanvasViewController buttonImageForCanvasPath:self.btnFillEllipse.tag] forState:UIControlStateNormal];
    [self.btnStrokeEllipse setImage:[CanvasViewController buttonImageForCanvasPath:self.btnStrokeEllipse.tag] forState:UIControlStateNormal];
    
    self.arrayModeButtons = @[self.btnPen, self.btnLine, self.btnCurve, self.btnEraser, self.btnFillPolygon, self.btnStrokePolygon, self.btnFillRect, self.btnStrokeRect, self.btnFillEllipse, self.btnStrokeEllipse];
    
//    self.canvas.backgroundErasable = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setSelectMode:self.btnPen];
    
    [self.canvas clear];
    
    [self checkUndoAndRedo];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -

- (void)setSelectMode:(UIButton*)modeButton {
    [self.arrayModeButtons makeObjectsPerformSelector:@selector(setBackgroundColor:) withObject:[UIColor whiteColor]];
    
    self.canvas.canvasMode = modeButton.tag;
    
    modeButton.backgroundColor = [UIColor yellowColor];
    
}

- (void)checkUndoAndRedo {
    if (self.canvas.canUndo)
        self.btnUndo.hidden = NO;
    else
        self.btnUndo.hidden = YES;
    
    if (self.canvas.canRedo)
        self.btnRedo.hidden = NO;
    else
        self.btnRedo.hidden = YES;
}

+ (UIImage*)buttonImageForCanvasPath:(CCCCanvasPath)path {
    
    CGSize size = CGSizeMake(30, 30);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    [[UIColor blackColor] set];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rect = CGRectInset(CGRectMake(0, 0, size.width, size.height), 2, 2);
    
    switch (path) {
        case CCCCanvasPathFillRect: {
            CGContextAddRect(context, rect);
            CGContextDrawPath(context, kCGPathFillStroke);
            break;
        }
        case CCCCanvasPathStrokeRect: {
            CGContextAddRect(context, rect);
            CGContextDrawPath(context, kCGPathStroke);
            break;
        }
        case CCCCanvasPathFillEllipse: {
            CGContextAddEllipseInRect(context, rect);
            CGContextDrawPath(context, kCGPathFillStroke);
            break;
        }
        case CCCCanvasPathStrokeEllipse: {
            CGContextAddEllipseInRect(context, rect);
            CGContextDrawPath(context, kCGPathStroke);
            break;
        }
        case CCCCanvasPathFillPolygon: {
            CGContextMoveToPoint(context, 12, 5);
            CGContextAddLineToPoint(context, 3, 27);
            CGContextAddLineToPoint(context, 27, 27);
            CGContextAddLineToPoint(context, 27, 20);
            CGContextAddLineToPoint(context, 12, 20);
            CGContextAddLineToPoint(context, 17, 5);
            CGContextClosePath(context);
            
            CGContextDrawPath(context, kCGPathFillStroke);
            break;
        }
        case CCCCanvasPathStrokePolygon: {
            CGContextMoveToPoint(context, 12, 5);
            CGContextAddLineToPoint(context, 3, 27);
            CGContextAddLineToPoint(context, 27, 27);
            CGContextAddLineToPoint(context, 27, 20);
            CGContextAddLineToPoint(context, 12, 20);
            CGContextAddLineToPoint(context, 17, 5);
            CGContextClosePath(context);
            
            CGContextDrawPath(context, kCGPathStroke);
            break;
        }
        default:
            break;
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Button Actions

- (IBAction)selectModeAction:(id)sender {
    [self setSelectMode:sender];
    
    [self checkUndoAndRedo];
}

- (IBAction)clearAction:(id)sender {
    [self.canvas clear];
    
    [self checkUndoAndRedo];
}

- (IBAction)undoAction:(id)sender {
    if (!self.canvas.canUndo) return;
    
    [self.canvas undo];
    
    [self checkUndoAndRedo];
}

- (IBAction)redoAction:(id)sender {
    if (!self.canvas.canRedo) return;
    
    [self.canvas redo];
    
    [self checkUndoAndRedo];
}

- (IBAction)selectWidthAction:(id)sender {
    [self.canvas.lineWidthSelectionView showInView:self.view.window.rootViewController.view animated:YES];
}

- (IBAction)selectColorAction:(id)sender {
    [self.canvas.paletteView showInView:self.view.window.rootViewController.view animated:YES];
}

- (IBAction)saveAction:(id)sender {
    [self test:self.canvas];
    
//    UIImage *image = [self.canvas outputImage];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString* docDir = [paths objectAtIndex:0];
//    [UIImagePNGRepresentation(image) writeToFile:[NSString stringWithFormat:@"%@/ccccanvas.png", docDir] atomically:YES];
    
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Image has been saved to Album!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Save to album failed!" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)unsecretStarAction:(id)sender {
    self.canvas.hasShadowEffect = !self.canvas.hasShadowEffect;
}

#pragma mark - CCCCanvasDelegate

- (void)canvasDidBeginPainting:(CCCCanvas*)canvas {
    [self checkUndoAndRedo];
}

- (void)canvasIsPainting:(CCCCanvas*)canvas {
//    [self test:self.canvas];
}

- (void)canvasDidEndPainting:(CCCCanvas*)canvas {
    [self checkUndoAndRedo];
}

- (void)canvas:(CCCCanvas*)canvas didClosePaletteView:(CCCCanvasPaletteView *)paletteView {
    
}

- (void)canvas:(CCCCanvas*)canvas didCloseLineWidthSelectionView:(CCCCanvasLineWidthSelectionView*)lineWidthSelectionView {
    
}

#pragma mark -

- (void)test:(UIView*)view {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    if (!view) {
        return;
    }
    
    size_t bytePerPixel = 4;
    CGSize size = view.bounds.size;
    CGFloat scale = 300.0/MAX(size.width, size.height);
    size = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale));
    
    size_t totalByteCount = ((size_t)size.width)*((size_t)size.height)*bytePerPixel;
    
    unsigned char *bitmapData = malloc(totalByteCount);
    memset(bitmapData, 0, totalByteCount);
    if (bitmapData == NULL) {
        return;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate (bitmapData,
                                                  ((size_t)size.width),
                                                  ((size_t)size.height),
                                                  8,
                                                  ((size_t)size.width)*bytePerPixel,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    colorSpace = NULL;
    
    if (context == NULL) {
        free(bitmapData);
        bitmapData = NULL;
        
        return;
    }
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, scale, scale);
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        UIGraphicsPushContext(context);
        [view drawViewHierarchyInRect:CGRectMake(0, 0, size.width, size.height) afterScreenUpdates:NO];
        UIGraphicsPopContext();
    }
    else {
        [view.layer renderInContext:context];
        view.layer.contents = NULL;
    }
    CGContextRestoreGState(context);
    
    CGContextRelease(context);
    context = NULL;
    
    size_t clearAlphaNumber = 0;
    for (int i = 0; i < totalByteCount; i += 4) {
        CGFloat alpha = (CGFloat)bitmapData[i]/255.0;
        if (alpha == 0) {
            clearAlphaNumber ++;
        }
    }
    
    free(bitmapData);
    bitmapData = NULL;
    
    CGFloat percent = ((CGFloat)clearAlphaNumber*4/(CGFloat)totalByteCount);
    
    NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"USED:%f, percent:%f%%", end-start, 100*percent);
//    NSLog(@"clear/all = %ld/%ld percent:%f%%", clearAlphaNumber, totalByteCount/4, 100*((CGFloat)clearAlphaNumber*4/(CGFloat)totalByteCount));
}

@end
