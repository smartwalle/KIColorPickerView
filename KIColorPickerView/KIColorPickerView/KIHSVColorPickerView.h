//
//  KIHSVColorPickerView.h
//  Kitalker
//
//  Created by kitaler on 14/7/23.
//  Copyright (c) 2014年 杨烽. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct {float h, s, v;} HSVColor;
typedef struct {float r, g, b;} RGBColor;

typedef NS_ENUM(int, KIHSVColorPickerViewTouchType) {
    KIHSVColorPickerViewTouchsBegan,
    KIHSVColorPickerViewTouchsMoved,
    KIHSVColorPickerViewTouchsCancelled,
    KIHSVColorPickerViewTouchsEnded,
    KIHSVColorPickerViewPassive,
};

@class  KIHSVColorPickerView;

typedef void(^KIHSVColorPickerViewDidUpdateColorBlock) (KIHSVColorPickerView *view,KIHSVColorPickerViewTouchType touchType, HSVColor hsvColor, UIColor *color);

@interface KIHSVColorPickerView : UIControl

@property (nonatomic, readonly) UIImage *colorImage;
@property (nonatomic, readonly) UIImage *indicatorImage;
@property (nonatomic, assign) CGFloat innerRadius;
@property (nonatomic, assign) CGFloat padding;

@property (nonatomic, assign) CGFloat colorBrightness;
@property (nonatomic, assign) CGFloat colorAlpha;

- (void)setColorImage:(UIImage *)colorImage;
- (void)setIndicatorImage:(UIImage *)indicatorImage withSize:(CGFloat)size;

- (UIColor *)selectedColor;
- (void)setSelectedColor:(UIColor *)color;
- (void)setSelectedColor:(UIColor *)color animated:(BOOL)animated;

- (void)setDidUpdateColorBlock:(KIHSVColorPickerViewDidUpdateColorBlock)block;

- (UIColor *)color;
- (HSVColor)hsvColor;
- (RGBColor)rgbColor;

@end
