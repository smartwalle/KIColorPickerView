//
//  KIColorPicker.m
//  Kitaler
//
//  Created by kitaler on 14/7/23.
//  Copyright (c) 2014年 杨烽. All rights reserved.
//


#import "KIColorPickerView.h"
#import "Util.h"
#import <math.h>

@interface KIColorPickerView () {
    unsigned char *_imagePixel;
}
@property (nonatomic, strong) UIImageView *indicatorImageView;

@property (nonatomic, assign) CGFloat   radius;
@property (nonatomic, assign) CGPoint   originalPoint;
@property (nonatomic, assign) BOOL      shouldResponse;
@property (nonatomic, assign) CGSize    imageSize;
@property (nonatomic, assign) CGFloat   indicatorImageWidth;
@property (nonatomic, strong) UIColor   *selectedColor;

@property (nonatomic, strong) KIColorPickerViewDidUpdateColorBlock didUpdateColorBlock;
@end

@implementation KIColorPickerView

void *bitmapData; //内存空间的指针，该内存空间的大小等于图像使用RGB通道所占用的字节数。

static CGContextRef CreateRGBABitmapContext(CGImageRef inImage) {
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace;
	unsigned long bitmapByteCount;
	unsigned long bitmapBytesPerRow;
    
	size_t pixelsWide = CGImageGetWidth(inImage); //获取横向的像素点的个数
	size_t pixelsHigh = CGImageGetHeight(inImage);
    
	bitmapBytesPerRow	= (pixelsWide * 4); //每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit(0-255)的空间
	bitmapByteCount	= (bitmapBytesPerRow * pixelsHigh); //计算整张图占用的字节数
    
	colorSpace = CGColorSpaceCreateDeviceRGB();//创建依赖于设备的RGB通道
	//分配足够容纳图片字节数的内存空间
	bitmapData = malloc( bitmapByteCount );
    //创建CoreGraphic的图形上下文，该上下文描述了bitmaData指向的内存空间需要绘制的图像的一些绘制参数
	context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    //Core Foundation中通过含有Create、Alloc的方法名字创建的指针，需要使用CFRelease()函数释放
	CGColorSpaceRelease(colorSpace);
	return context;
}

// 返回一个指针，该指针指向一个数组，数组中的每四个元素都是图像上的一个像素点的RGBA的数值(0-255)，用无符号的char是因为它正好的取值范围就是0-255
static unsigned char *RequestImagePixelData(UIImage *inImage) {
	CGImageRef img = [inImage CGImage];
	CGSize size = [inImage size];
    //使用上面的函数创建上下文
	CGContextRef cgctx = CreateRGBABitmapContext(img);
	CGRect rect = {{0,0},{size.width, size.height}};
    //将目标图像绘制到指定的上下文，实际为上下文内的bitmapData。
	CGContextDrawImage(cgctx, rect, img);
	unsigned char *data = CGBitmapContextGetData (cgctx);
    //释放上面的函数创建的上下文
	CGContextRelease(cgctx);
	return data;
}

// 得到两点之间的弧度
+ (float)getRadian:(CGPoint)p1 orignalPoint:(CGPoint)p0 {
    // 算出斜边长
    float xie = [self getDistanceFromCircle:p1 orginalPoint:p0];
    // 得到这个角度的余弦值（通过三角函数中的定理：邻边/斜边=角度余弦值)
    float cosAngle = (p1.x-p0.x)/xie;
    // 通过反余弦定理获取到其角度的弧度
    float rad = (float)acosf(cosAngle);
    // 注意：当触屏的位置Y坐标<摇杆的Y坐标我们要取反值-0~180
    if(p0.y>p1.y) {
        rad = -rad;
    }
    return rad;
}

// 点到圆心的距离
+ (float)getDistanceFromCircle:(CGPoint)p1 orginalPoint:(CGPoint)p0 {
    float x = p1.x - p0.x;
    float y = p1.y -p0.y;
    float d = sqrtf(powf(x, 2) + powf(y, 2));
    return d;
}

- (void)dealloc {
    _colorImage = nil;
    _indicatorImage = nil;
    _selectedColor = nil;
    _didUpdateColorBlock = nil;
    _indicatorImageView = nil;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)layoutSubviews {
    [self updateView];
}

- (void)updateView {
    
    if (_colorImage) {
        CGSize size = self.frame.size;
        
        UIImage *newImage;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:_colorImage];
        [imageView setFrame:self.bounds];
        
        UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
        [_colorImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [self setBackgroundColor:[UIColor colorWithPatternImage:newImage]];
        
        self.imageSize = newImage.size;
        
        _imagePixel = RequestImagePixelData(newImage);
    }
    
    //重新计算指针的坐标
    CGRect frame = CGRectMake((CGRectGetWidth(self.frame)-self.indicatorImageWidth) * 0.5,
                              10,
                              self.indicatorImageWidth,
                              self.indicatorImageWidth);
    [self.indicatorImageView setFrame:frame];
    
    //计算出半径
    self.radius = (CGRectGetHeight(self.frame) - self.indicatorImageWidth) * 0.5;
    
    //计算圆心
    self.originalPoint = CGPointMake(self.radius, self.radius);
}

- (CGFloat)radius {
    return _radius - _padding;
}

- (UIImageView *)indicatorImageView {
    if (_indicatorImageView == nil) {
        _indicatorImageView = [[UIImageView alloc] init];
        [self addSubview:_indicatorImageView];
    }
    return _indicatorImageView;
}

- (void)setColorImage:(UIImage *)image {
    _colorImage = image;
    
    [self updateView];
}

- (void)setIndicatorImage:(UIImage *)image withSize:(CGFloat)size {
    _indicatorImage = image;
    [self.indicatorImageView setImage:_indicatorImage];
    self.indicatorImageWidth = size;
    [self updateView];
}

- (void)setDidUpdateColorBlock:(KIColorPickerViewDidUpdateColorBlock)block {
    _didUpdateColorBlock = [block copy];
}

- (void)updateIndicatorImageViewFrameWithPoint:(CGPoint)point {
    CGRect frame = self.indicatorImageView.frame;
    frame.origin = point;
    [self.indicatorImageView setFrame:frame];
}

- (UIColor *)selectedColor {
    return _selectedColor;
}

- (void)setSelectedColorWithPoint:(CGPoint)point type:(KIColorPickerViewTouchType)type {
    UIColor *color = [self getColorWithPoint:point];
    
    [self setSelectedColor:color];
    
    if (self.didUpdateColorBlock != nil) {
        self.didUpdateColorBlock(self, type, self.selectedColor);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    NSSet *allTouches = [event allTouches];  
    UITouch *touch = [allTouches anyObject];  
    CGPoint point=[touch locationInView:[touch view]];
    
    float distance = [KIColorPickerView getDistanceFromCircle:point orginalPoint:self.originalPoint];
    
    if (distance <= self.radius && distance >= self.innerRadius) {
        self.shouldResponse = YES;
        
        [self updateIndicatorImageViewFrameWithPoint:point];
        [self setSelectedColorWithPoint:point type:KIColorPickerViewTouchBegan];
    } else {
        self.shouldResponse =NO;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.shouldResponse == NO) {
        return;
    }
    
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [allTouches anyObject];
    CGPoint point=[touch locationInView:[touch view]];
   
    float distance = [KIColorPickerView getDistanceFromCircle:point orginalPoint:self.originalPoint];
    float rad = [KIColorPickerView getRadian:point orignalPoint:self.originalPoint];
    
    if (distance <= self.radius && distance >= self.innerRadius) {
        //在半径以内，内径以外
    } else if (distance >= self.radius && distance >= self.innerRadius) {
        //在半径以外，内径以外
        point = [self getXY:rad orignalPoint:self.originalPoint];
    } else if (distance <= self.radius && distance <= self.innerRadius) {
        //在半径以内，内径以内
        return;
    }
    
    [self updateIndicatorImageViewFrameWithPoint:point];
    [self setSelectedColorWithPoint:point type:KIColorPickerViewTouchsMoved];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [allTouches anyObject];
    CGPoint point=[touch locationInView:[touch view]];
    
    [self updateIndicatorImageViewFrameWithPoint:point];
    [self setSelectedColorWithPoint:point type:KIColorPickerViewTouchsCancelled];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.shouldResponse == NO) {
        return;
    }
    
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [allTouches anyObject];
    CGPoint point=[touch locationInView:[touch view]];
   
    float distance = [KIColorPickerView getDistanceFromCircle:point orginalPoint:self.originalPoint];
    
    if(distance <= self.radius && distance >= self.innerRadius) {
        [self updateIndicatorImageViewFrameWithPoint:point];
        [self setSelectedColorWithPoint:point type:KIColorPickerViewTouchsEnded];
    } else {
        [self setSelectedColorWithPoint:self.indicatorImageView.frame.origin type:KIColorPickerViewTouchsEnded];
    }
}

//获取圆周运动坐标
- (CGPoint)getXY:(double)rad orignalPoint:(CGPoint)p0 {
    float x = self.radius*cos(rad) + p0.x;
    float y = self.radius*sin(rad) + p0.y;
    
    return CGPointMake(x,y);
}

//计算颜色
- (UIColor*)getColorWithPoint:(CGPoint)aPoint {

    int index = 4 * self.imageSize.width * round(aPoint.y+self.indicatorImageWidth/2) + 4 * round(aPoint.x+self.indicatorImageWidth/2);
    
    int r = (unsigned char)_imagePixel[index];
    int g = (unsigned char)_imagePixel[index+1];
    int b = (unsigned char)_imagePixel[index+2];
    
    UIColor *color = [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0];
    
    return color;
}

@end
