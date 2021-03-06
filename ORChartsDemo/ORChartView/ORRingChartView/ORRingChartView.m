//
//  ORRingChartView.m
//  QLAnimateTest
//
//  Created by 欧阳荣 on 2019/4/24.
//  Copyright © 2019 欧阳荣. All rights reserved.
//

#import "ORRingChartView.h"
#import "ORRingConfiger.h"


@implementation NSObject (ORRingChartView)

- (NSArray <UIColor *> *)chartView:(ORRingChartView *)chartView graidentColorsAtRingIndex:(NSInteger)index {return @[[[UIColor or_randomColor] colorWithAlpha:0.6],[[UIColor or_randomColor] colorWithAlpha:0.4]];}
- (UIColor *)chartView:(ORRingChartView *)chartView lineColorForRingAtRingIndex:(NSInteger)index {return [UIColor whiteColor];}
- (UIColor *)chartView:(ORRingChartView *)chartView lineColorForInfoLineAtRingIndex:(NSInteger)index {return nil;}

- (UIView *)viewForRingCenterOfChartView:(ORRingChartView *)chartView {return nil;}
- (UIView *)chartView:(ORRingChartView *)chartView viewForTopInfoAtRingIndex:(NSInteger)index {return nil;}
- (UIView *)chartView:(ORRingChartView *)chartView viewForBottomInfoAtRingIndex:(NSInteger)index {return nil;}

- (CGFloat)chartView:(ORRingChartView *)chartView marginForInfoLineAtRingIndex:(NSInteger)index {return 0;}
- (CGFloat)chartView:(ORRingChartView *)chartView marginForInfoLineToRingAtRingIndex:(NSInteger)index {return 0;}
- (CGFloat)chartView:(ORRingChartView *)chartView marginForInfoViewToLineAtRingIndex:(NSInteger)index {return 0;}
- (CGFloat)chartView:(ORRingChartView *)chartView breakMarginForInfoLineAtRingIndex:(NSInteger)index {return 0;}
- (CGFloat)chartView:(ORRingChartView *)chartView pointWidthForInfoLineAtRingIndex:(NSInteger)index {return 0;};

@end

@interface ORRingModel : NSObject

@property (nonatomic, assign) CGFloat value;

@property (nonatomic, strong) NSArray <UIColor *>*gradientColors;
@property (nonatomic, strong) UIColor *ringLineColor;
@property (nonatomic, strong) UIColor *ringInfoColor;

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAShapeLayer *ringLineLayer;
@property (nonatomic, strong) CAShapeLayer *infoLineLayer;
@property (nonatomic, strong) CALayer *infoLinePointLayer;
@property (nonatomic, strong) UIView *topInfoView;
@property (nonatomic, strong) UIView *bottomInfoView;

@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, assign) CGFloat endAngle;
@property (nonatomic, assign, readonly) BOOL leftToRight;

@property (nonatomic, assign) CGFloat margin;
@property (nonatomic, assign) CGFloat inMargin;
@property (nonatomic, assign) CGFloat infoMargin;
@property (nonatomic, assign) CGFloat breakMargin;
@property (nonatomic, assign) CGFloat pointWidth;

@end

@implementation ORRingModel

- (BOOL)leftToRight {
    
    CGFloat midAngle = [ORRingConfiger or_middleAngleWithStartAngle:self.startAngle endAngle:self.endAngle];
    BOOL ltor = (midAngle >=  M_PI * 3 / 2 && midAngle <= M_PI * 2.0) ||  (midAngle >= M_PI / 2 && midAngle <= M_PI);
    return ltor;
}

- (UIColor *)ringInfoColor {
    if (!_ringInfoColor) {
        _ringInfoColor = self.gradientColors.firstObject;
    }
    return _ringInfoColor;
}

- (UIView *)topInfoView {
    
    if (!_topInfoView) {
        _topInfoView = [self labelWithText:[NSString stringWithFormat:@"value : %lf", self.value]];
    }
    return _topInfoView;
}

- (UILabel *)labelWithText:(NSString *)text {
    UILabel *label = [UILabel new];
    label.frame = CGRectMake(0, 0, 60, 25);
    label.font = [UIFont systemFontOfSize:12];
    label.text = text;
    return label;
}

@end

@interface ORRingChartView ()

@property (nonatomic, strong) NSMutableArray <ORRingModel *>* ringModels;

@property (nonatomic, strong) UIView *centerInfoView;

@property (nonatomic, assign) CGFloat maxMarginWidthSum;
@property (nonatomic, assign) CGFloat maxMarginHeightSum;

@end

@implementation ORRingChartView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _or_initData];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _or_initData];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _or_layoutLayers];
}

- (void)reloadData {
    
    if (!_dataSource || [_dataSource numberOfRingsOfChartView:self] == 0) {
        return;
    }
    
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.ringModels removeAllObjects];

    NSInteger items = [_dataSource numberOfRingsOfChartView:self];
    
    CGFloat maxValue = 0;
    
    _centerInfoView = [_dataSource viewForRingCenterOfChartView:self];
    [self addSubview:_centerInfoView];
    
    for (int i = 0; i < items; i ++) {
        ORRingModel *model  = [ORRingModel new];
        
        model.value = [_dataSource chartView:self valueAtRingIndex:i];
        model.gradientColors = [_dataSource chartView:self graidentColorsAtRingIndex:i];
        model.ringLineColor = [_dataSource chartView:self lineColorForRingAtRingIndex:i];
        model.ringInfoColor = [_dataSource chartView:self lineColorForInfoLineAtRingIndex:i];
        
        model.topInfoView = [_dataSource chartView:self viewForTopInfoAtRingIndex:i];
        model.bottomInfoView = [_dataSource chartView:self viewForBottomInfoAtRingIndex:i];

        model.margin = [_delegate chartView:self marginForInfoLineAtRingIndex:i] ?: 10;
        model.inMargin = [_delegate chartView:self marginForInfoLineToRingAtRingIndex:i] ?: 10;
        model.breakMargin = [_delegate chartView:self breakMarginForInfoLineAtRingIndex:i] ?: 15;
        model.infoMargin = [_delegate chartView:self marginForInfoViewToLineAtRingIndex:i] ?: 4;
        model.pointWidth = [_delegate chartView:self pointWidthForInfoLineAtRingIndex:i] ?: 4;
        
        [self addSubview:model.topInfoView];
        [self addSubview:model.bottomInfoView];
        
        _maxMarginWidthSum = MAX(MAX(model.topInfoView.bounds.size.width, model.bottomInfoView.bounds.size.width) + model.margin + model.inMargin, _maxMarginWidthSum);
        _maxMarginHeightSum = MAX(model.topInfoView.bounds.size.height + model.bottomInfoView.bounds.size.height + model.margin + model.inMargin + model.infoMargin * 2 + model.breakMargin, _maxMarginHeightSum);
        
        maxValue += model.value;
        
        [self.ringModels addObject:model];
    }
    
    __block CGFloat startAngle = self.startAngle;
    
    [self.ringModels enumerateObjectsUsingBlock:^(ORRingModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CGFloat angle = [ORRingConfiger or_angle:startAngle byAddAngle:ORInterpolation(0, M_PI * 2, obj.value / maxValue)];
        obj.startAngle = startAngle;
        obj.endAngle = angle;
        
        startAngle = angle;
        
        [self _or_addLayerstWithModel:obj];
    }];
    
    [self setNeedsLayout];
}

- (void)_or_initData {
    
    _ringLineWidth = 2;
    _infoLineWidth = 1;
    
    _ringWidth = 60;
    
    _startAngle = M_PI * 3 / 2;
    _ringModels = [NSMutableArray array];
    
    _clockwise = YES;
}

- (void)_or_layoutLayers {
    
    if (self.ringModels.count == 0) {
        return;
    }

    CGFloat width = MIN(self.bounds.size.width - (_maxMarginWidthSum ) * 2, self.bounds.size.height - (_maxMarginHeightSum) * 2);

    CGFloat ringWidth = _ringWidth;
    
    if (self.centerInfoView) {
        ringWidth = (width - MAX(self.centerInfoView.bounds.size.width, self.centerInfoView.bounds.size.height)) / 2;
    }
    
    ringWidth = MAX(ringWidth, 10);
    ringWidth = MIN(ringWidth, width / 2.0);
    
    if (self.style == ORChartStyleFan || self.style == ORChartStylePie) {
        ringWidth = width / 2.0;
    }
    
    CGRect bounds = CGRectMake(0, 0, width, width);
    CGPoint position = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    
    [self.ringModels enumerateObjectsUsingBlock:^(ORRingModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.gradientLayer.bounds = bounds;
        obj.gradientLayer.position = position;
        CAShapeLayer *shapeLayer = obj.gradientLayer.mask;
        CGPathRef path = [ORRingConfiger or_ringPathWithRect:bounds startAngle:obj.startAngle endAngle:obj.endAngle ringWidth:ringWidth closckWise:self.clockwise isPie:self.style == ORChartStylePie].CGPath;
        shapeLayer.path = path;
        
        obj.ringLineLayer.bounds = bounds;
        obj.ringLineLayer.position = position;
        obj.ringLineLayer.path = path;
        
        CGPathRef linePath = [ORRingConfiger or_breakLinePathWithRawRect:self.bounds circleWidth:width startAngle:obj.startAngle endAngle:obj.endAngle margin:obj.margin inMargin:obj.inMargin breakMargin:obj.breakMargin detailInfoBlock:^(CGPoint edgePoint, CGPoint endPoint) {
            
            obj.infoLinePointLayer.frame = CGRectMake(endPoint.x - obj.pointWidth / 2.0, endPoint.y - obj.pointWidth / 2.0, obj.pointWidth, obj.pointWidth);
            obj.infoLinePointLayer.cornerRadius = obj.pointWidth / 2.0;

            CGRect frame = obj.topInfoView.frame;
            CGFloat fx = edgePoint.x > self.bounds.size.width / 2.0 ? edgePoint.x - frame.size.width : edgePoint.x;
            frame.origin = CGPointMake(fx, edgePoint.y - obj.infoMargin - frame.size.height);
            obj.topInfoView.frame = frame;

            CGRect bottomFrame = obj.bottomInfoView.frame;
            CGFloat bfx = edgePoint.x > self.bounds.size.width / 2.0 ? edgePoint.x - bottomFrame.size.width : edgePoint.x;
            bottomFrame.origin = CGPointMake(bfx, edgePoint.y + obj.infoMargin - bottomFrame.size.height);
            obj.bottomInfoView.frame = bottomFrame;
            
        }].CGPath;
        obj.infoLineLayer.path = linePath;
        
        [shapeLayer addAnimation:[ORRingConfiger animationWithDurantion:2] forKey:nil];
        [obj.ringLineLayer addAnimation:[ORRingConfiger animationWithDurantion:2] forKey:nil];
        [obj.infoLineLayer addAnimation:[ORRingConfiger animationWithDurantion:2] forKey:nil];

    }];
}

- (void)_or_addLayerstWithModel:(ORRingModel *)model {
    
    CAGradientLayer *gradientLayer = [ORRingConfiger or_grandientLayerWithColors:model.gradientColors leftToRight:model.leftToRight];
    gradientLayer.mask = [CAShapeLayer layer];
    [self.layer addSublayer:gradientLayer];
    
    CAShapeLayer *ringLineLayer = [ORRingConfiger or_shapelayerWithLineWidth:self.ringLineWidth strokeColor:model.ringLineColor];
    [self.layer addSublayer:ringLineLayer];
    
    CAShapeLayer *infoLineLayer = [ORRingConfiger or_shapelayerWithLineWidth:self.infoLineWidth strokeColor:model.ringInfoColor];
    [self.layer addSublayer:infoLineLayer];
  
    CALayer *infoLinePointLayer = [CALayer layer];
    infoLinePointLayer.backgroundColor = model.ringInfoColor.CGColor;
    [self.layer addSublayer:infoLinePointLayer];
    
    model.gradientLayer = gradientLayer;
    model.ringLineLayer = ringLineLayer;
    model.infoLineLayer = infoLineLayer;
    model.infoLinePointLayer = infoLinePointLayer;
}


- (void)setDataSource:(id<ORRingChartViewDatasource>)dataSource {
    
    if (_dataSource != dataSource) {
        
        _dataSource = dataSource;
        if (_dataSource) {
            [self reloadData];
        }
    }
}


- (void)setStyle:(ORChartStyle)style {
    _style = style;
    [self setNeedsLayout];
}

@end



