//
//  KIColorPicker.m
//  Kitaler
//
//  Created by kitaler on 14/7/23.
//  Copyright (c) 2014年 杨烽. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef NS_ENUM(int, KIColorPickerViewTouchType) {
    KIColorPickerViewTouchBegan,
    KIColorPickerViewTouchsMoved,
    KIColorPickerViewTouchsCancelled,
    KIColorPickerViewTouchsEnded,
};

@class KIColorPickerView;

typedef void(^KIColorPickerViewDidUpdateColorBlock) (KIColorPickerView *view, KIColorPickerViewTouchType type, UIColor *color);

@interface KIColorPickerView : UIControl {
}

@property (nonatomic, readonly) UIImage *colorImage;
@property (nonatomic, readonly) UIImage *indicatorImage;
@property (nonatomic, assign) CGFloat innerRadius;
@property (nonatomic, assign) CGFloat padding;

- (void)setColorImage:(UIImage *)image;
- (void)setIndicatorImage:(UIImage *)image withSize:(CGFloat)size;

- (void)setDidUpdateColorBlock:(KIColorPickerViewDidUpdateColorBlock)block;

- (UIColor *)selectedColor;

@end
