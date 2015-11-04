//
//  KIHSVColorPickerView.m
//  Kitalker
//
//  Created by kitaler on 14/7/23.
//  Copyright (c) 2014年 杨烽. All rights reserved.
//

#import "KIHSVColorPickerView.h"

HSVColor HSVColorMake(float h, float s, float v);
RGBColor RGBColorMake(float r, float g, float b);

inline HSVColor HSVColorMake(float h, float s, float v) {
    HSVColor color = {h, s, v};
    return color;
}

inline RGBColor RGBColorMake(float r, float g, float b) {
    RGBColor color = {r, g, b};
    return color;
}


HSVColor HSVFromrRGB(RGBColor RGB) {
    float R = RGB.r, G = RGB.g, B = RGB.b, v, x, f;
    int i;
	
    x = fminf(R, G);
    x = fminf(x, B);
	
    v = fmaxf(R, G);
    v = fmaxf(v, B);
	
    if(v == x)
		return HSVColorMake(0, 0, v);
	
    f = (R == x) ? G - B : ((G == x) ? B - R : R - G);
    i = (R == x) ? 3 : ((G == x) ? 5 : 1);
	
    return HSVColorMake(((i - f /(v - x))/6), (v - x)/v, v);
}

RGBColor RGBFromHSV(HSVColor HSV) {
    float h = HSV.h * 6, s = HSV.s, v = HSV.v, m, n, f;
    int i;
    
    if (h == 0) h=.01;
    if(h == 0)
		return RGBColorMake(v, v, v);
    i = floorf(h);
    f = h - i;
    if(!(i & 1)) f = 1 - f; // if i is even
    m = v * (1 - s);
    n = v * (1 - s * f);
    switch (i)
	{
        case 6:
        case 0: return RGBColorMake(v, n, m);
        case 1: return RGBColorMake(n, v, m);
        case 2: return RGBColorMake(m, v, n);
        case 3: return RGBColorMake(m, n, v);
        case 4: return RGBColorMake(n, m, v);
        case 5: return RGBColorMake(v, m, n);
	}
    return RGBColorMake(0, 0, 0);
}

RGBColor RGBFromUIColor(UIColor *color) {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
	
	CGFloat r,g,b;
	
	switch (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)))
	{
		case kCGColorSpaceModelMonochrome:
			r = g = b = components[0];
			break;
		case kCGColorSpaceModelRGB:
			r = components[0];
			g = components[1];
			b = components[2];
			break;
		default:	// We don't know how to handle this model
			return RGBColorMake(0, 0, 0);
	}
	
	return RGBColorMake(r, g, b);
}


@interface KIHSVColorPickerView ()
@property (nonatomic, strong) UIImageView   *colorImageView;
@property (nonatomic, strong) UIImageView   *indicatorImageView;
@property (nonatomic, assign) CGPoint       originalPoint;

@property (nonatomic, assign) HSVColor      hsvColor;
@property (nonatomic, assign) CGFloat       indicatorImageWidth;
@property (nonatomic, assign) KIHSVColorPickerViewTouchType touchType;

@property (nonatomic, assign) CGFloat   radius;

@property (nonatomic, strong) KIHSVColorPickerViewDidUpdateColorBlock didUpdateColorBlock;
@end

@implementation KIHSVColorPickerView

- (void)dealloc {
    _colorImageView = nil;
    _indicatorImageView = nil;
    _colorImage = nil;
    _indicatorImage = nil;
    _didUpdateColorBlock = nil;
}

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    [self setColorAlpha:1.0];
    [self setColorBrightness:1.0];
    [self setInnerRadius:0.0];
    [self setPadding:0.0];
    [self setTouchType:KIHSVColorPickerViewTouchsEnded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateView];
}

- (void)updateView {
    
    [self.colorImageView setFrame:self.bounds];
    
    self.radius = CGRectGetWidth(self.frame) * 0.5;
    self.originalPoint = CGPointMake(CGRectGetWidth(self.frame) * 0.5,
                                     CGRectGetWidth(self.frame) * 0.5);
    
    //重新计算指针的坐标
    CGRect frame = CGRectMake((CGRectGetWidth(self.frame)-self.indicatorImageWidth) * 0.5,
                              10,
                              self.indicatorImageWidth,
                              self.indicatorImageWidth);
    [self.indicatorImageView setFrame:frame];
    
    if (self.selectedColor) {
        [self setSelectedColor:self.selectedColor];
    } else {
        [self mapPointToColor:self.indicatorImageView.frame.origin];
    }
    
    [self bringSubviewToFront:self.indicatorImageView];
}

- (CGFloat)radius {
    return _radius - _padding;
}

- (UIImageView *)colorImageView {
    if (_colorImageView == nil) {
        _colorImageView = [[UIImageView alloc] init];
        [_colorImageView setFrame:self.bounds];
        [self addSubview:_colorImageView];
    }
    return _colorImageView;
}

- (UIImageView *)indicatorImageView {
    if (_indicatorImageView == nil) {
        _indicatorImageView = [[UIImageView alloc] init];
        [self addSubview:_indicatorImageView];
    }
    return _indicatorImageView;
}

- (void)setColorImage:(UIImage *)colorImage {
    _colorImage = colorImage;
    [self.colorImageView setImage:_colorImage];
    [self updateView];
}

- (void)setIndicatorImage:(UIImage *)indicatorImage withSize:(CGFloat)size {
    _indicatorImage = indicatorImage;
    [self.indicatorImageView setImage:indicatorImage];
    self.indicatorImageWidth = size;
    [self updateView];
}

- (void)setColorBrightness:(CGFloat)brightness {
    _colorBrightness = brightness;
    //设置亮度之后，需要重新计算HSVColor
    HSVColor hsvColor = HSVColorMake(self.hsvColor.h, self.hsvColor.s, _colorBrightness);
    
    self.touchType = KIHSVColorPickerViewPassive;
    [self updateHSVColor:hsvColor];
}

- (void)setColorAlpha:(CGFloat)alpha {
    _colorAlpha = alpha;
    
    self.touchType = KIHSVColorPickerViewPassive;
    [self dispatchUpdateEvent];
}

- (UIColor *)selectedColor {
    return [UIColor colorWithHue:self.hsvColor.h
                      saturation:self.hsvColor.s
                      brightness:self.hsvColor.v
                           alpha:self.colorAlpha];
}

- (void)setSelectedColor:(UIColor *)color {
    RGBColor rgbColor = RGBFromUIColor(color);
    HSVColor hsvColor = HSVFromrRGB(rgbColor);
    
    //设置Color之后，需要更新一下颜色的亮度
    _colorBrightness = hsvColor.v;
    
    self.touchType = KIHSVColorPickerViewPassive;
    [self updateHSVColor:hsvColor];
}

- (void)setSelectedColor:(UIColor *)color animated:(BOOL)animated {
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [self setSelectedColor:color];
        [UIView commitAnimations];
    } else {
        [self setSelectedColor:color];
    }
}

- (void)setDidUpdateColorBlock:(KIHSVColorPickerViewDidUpdateColorBlock)block {
    _didUpdateColorBlock = block;
}

- (UIColor *)color {
    return self.selectedColor;
}

- (HSVColor)hsvColor {
    return _hsvColor;
}

- (void)updateHSVColor:(HSVColor)hsvColor {
    self.hsvColor = hsvColor;
    
    [self updateIndicatorImageViewCenter:self.hsvColor];
    
    [self dispatchUpdateEvent];
}

- (void)dispatchUpdateEvent {
    if (self.didUpdateColorBlock != nil) {
        self.didUpdateColorBlock(self, self.touchType, self.hsvColor, self.color);
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (RGBColor)rgbColor {
    return RGBFromHSV(self.hsvColor);
}

- (void)mapPointToColor:(CGPoint)point {
    CGPoint center = self.originalPoint;
    double radius = CGRectGetWidth(self.colorImageView.bounds) * 0.5;
    double dx = ABS(point.x - center.x);
    double dy = ABS(point.y - center.y);
    double radian = atan(dy / dx);
    if (isnan(radian)) {
        radian = 0.0f;
    }
    double distance = [self distanceWithPoint:point toOriginalPoint:center];
    
    double saturation = MIN(distance / radius, 1.0);
    if (distance < 10) {
        saturation = 0;
    }
    if (point.x < center.x) {
        radian = M_PI - radian;
    }
    if (point.y > center.y) {
        radian = 2.0 * M_PI - radian;
    }
    
    [self updateHSVColor:HSVColorMake(radian / (2.0 * M_PI), saturation, self.colorBrightness)];
}

- (void)updateIndicatorImageViewCenter:(HSVColor)hsvColor {
    double angle = hsvColor.h * 2.0 * M_PI;
    double radius = self.radius;
    
    radius *= hsvColor.s;
    CGFloat x = self.originalPoint.x + cosf(angle) * radius;
    CGFloat y = self.originalPoint.y - sinf(angle) * radius;
    
    x = roundf(x - self.indicatorImageView.bounds.size.width * 0.5) + self.indicatorImageView.bounds.size.width * 0.5;
	y = roundf(y - self.indicatorImageView.bounds.size.height * 0.5) + self.indicatorImageView.bounds.size.height * 0.5;
    
    CGPoint point = CGPointMake(x + self.colorImageView.frame.origin.x, y + self.colorImageView.frame.origin.y);
    
    //////////
    double distance = [self distanceWithPoint:point toOriginalPoint:self.originalPoint];
    
    if (distance >= self.radius) {
    } else if (distance <= self.radius && distance >= self.innerRadius) {
        //在半径以内，内径以外
    } else if (distance <= self.innerRadius) {
        //在内径以内
        
        double radian = [self radianWithPoint:point toOriginalPoint:self.originalPoint];
        
        point = [self pointWithRadian:radian
                                radius:self.innerRadius
                       toOriginalPoint:self.originalPoint
                                offset:0];
    }
    //////////
    
	self.indicatorImageView.center = point;
}

//计算两点之间的距离
- (CGFloat)distanceWithPoint:(CGPoint)point toOriginalPoint:(CGPoint)originalPoint {
    double distance = 0;
    double dx = ABS(point.x - originalPoint.x);
    double dy = ABS(point.y - originalPoint.y);
    distance = sqrt(pow(dx, 2) + pow(dy, 2));
    return distance;
}

//计算两点之间的孤度（已经修正为负Y轴为0度）
- (CGFloat)radianWithPoint:(CGPoint)point toOriginalPoint:(CGPoint)originalPoint {
    double radian = 0;
    double dx = ABS(point.x - originalPoint.x);
    double dy = ABS(point.y - originalPoint.y);
    radian = atan2(dy, dx);
    
    if (point.x < originalPoint.x) {
        radian = M_PI - radian;
    }
    if (point.y > originalPoint.y) {
        radian = 2.0 * M_PI - radian;
    }
    if (radian > M_PI_2) {
        radian -= M_PI_2;
    } else {
        radian += 3 * M_PI * 0.5;
    }
    
    radian = ABS(2 * M_PI - radian);
    
    return radian;
}

//根据弧度、半径获取圆周运动坐标
- (CGPoint)pointWithRadian:(CGFloat)radian
                    radius:(CGFloat)radius
           toOriginalPoint:(CGPoint)originalPoint
                    offset:(CGFloat)offset {
    CGPoint point;
    
    point.x = round(originalPoint.x + radius * cos(radian - M_PI_2));
    point.y = round(originalPoint.y + radius * sin(radian - M_PI_2));
    
    point.x = point.x - offset;
    point.y = point.y - offset;
    
    return point;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.touchType = KIHSVColorPickerViewTouchsBegan;
    
    CGPoint touchPoint = [touch locationInView:self];
    [self mapPointToColor:touchPoint];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.touchType = KIHSVColorPickerViewTouchsMoved;
    
    CGPoint touchPoint = [touch locationInView:self];
    [self mapPointToColor:touchPoint];
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.touchType = KIHSVColorPickerViewTouchsEnded;
    
    CGPoint touchPoint = [touch locationInView:self];
    [self mapPointToColor:touchPoint];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    self.touchType = KIHSVColorPickerViewTouchsCancelled;
    
    CGPoint touchPoint = [[[event allTouches] anyObject] locationInView:self];
    [self mapPointToColor:touchPoint];
}
@end
