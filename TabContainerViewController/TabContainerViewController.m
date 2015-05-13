//
//  TabContainerViewController.m
//  TabContainerViewController
//
//  Created by Zhang Rey on 5/12/15.
//  Copyright (c) 2015 Zhang Rey. All rights reserved.
//

#import "TabContainerViewController.h"
#define IOS_VERSION_7 [[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending
#define kTabHeight 44.0
#define kTabViewTag 38
#define kContentViewTag 34

#define kIndicatorColor [UIColor colorWithRed:178.0/255.0 green:203.0/255.0 blue:57.0/255.0 alpha:0.75]
#define kTabsViewBackgroundColor [UIColor colorWithRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:0.75]
#define kContentViewBackgroundColor [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:0.75]


@interface UIColor (Equality)
- (BOOL)isEqualToColor:(UIColor *)otherColor;
@end

@implementation UIColor (Equality)
// This method checks if two UIColors are the same
// Thanks to @samvermette for this method: http://stackoverflow.com/a/8899384/1931781
- (BOOL)isEqualToColor:(UIColor *)otherColor {
    
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    UIColor *(^convertColorToRGBSpace)(UIColor *) = ^(UIColor *color) {
        if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            return [UIColor colorWithCGColor:CGColorCreate(colorSpaceRGB, components)];
        } else {
            return color;
        }
    };
    
    UIColor *selfColor = convertColorToRGBSpace(self);
    otherColor = convertColorToRGBSpace(otherColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:otherColor];
}
@end


#pragma mark --TabView
//////显示tab的tabview
@class TabView;
@interface TabView : UIView
@property (nonatomic,getter=isSelected) BOOL selected;
@property (nonatomic) UIColor *indicatorColor;
@end

@implementation TabView

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)setSelected:(BOOL)selected {
    _selected = selected;
    [self setNeedsDisplay]; ////当状态改变时重绘view
}

-(void)drawRect:(CGRect)rect {
    UIBezierPath *bezierPath;
    
    bezierPath = [UIBezierPath bezierPath];
    /////绘制顶部的线
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(rect), 0)];
    [[UIColor colorWithWhite:197.0/255.0 alpha:0.75] setStroke];
    [bezierPath setLineWidth:1.0];
    [bezierPath stroke];
    
    /////绘制底部的线
    bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, CGRectGetHeight(rect))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(rect),CGRectGetHeight(rect))];
    [[UIColor colorWithWhite:197.0/255.0 alpha:0.75] setStroke];
    [bezierPath setLineWidth:1.0];
    [bezierPath stroke];
    
    /////根据选中的状态isSelected绘制颜色为indicatorColor的线
    if(self.selected) {
        bezierPath = [UIBezierPath bezierPath];
        
        [bezierPath moveToPoint:CGPointMake(0.0, CGRectGetHeight(rect)-1.0)];
        [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(rect), CGRectGetHeight(rect) - 1.0)];
        [bezierPath setLineWidth:5.0];
//        [[UIColor redColor] setStroke];
        [self.indicatorColor setStroke];
        [bezierPath stroke];
    }
    
    
}

@end

#pragma mark -- TabContainerViewController

@interface TabContainerViewController ()<UIPageViewControllerDataSource,UIPageViewControllerDelegate>

@property (nonatomic) UIView *tabsView;   /////组装及显示tabs的视图
@property (nonatomic) UIView *contentView;  ////显示内容的视图

@property (nonatomic) UIPageViewController *pageViewController; ///////视图间的切换主要依赖于这个pageviewcontroller


////接收所有的tabs,contents 的数据源
@property (nonatomic) NSMutableArray *tabs;
@property (nonatomic) NSMutableArray *contents;

//////options
@property (nonatomic) NSNumber *tabHeight;  /////接收指定的tab高度
@property (nonatomic) NSNumber *tabWidth;  /////计算得到指定的tab宽度
@property (nonatomic) NSUInteger tabCount;  ////计算得到所有的tab的总数
@property (nonatomic) NSUInteger activeTabIndex; ////当前活动的tab索引
@property (nonatomic) NSUInteger activeContentIndex;   ////当前活动的内容索引

@property (getter = isAnimatingToTab, assign) BOOL animatingToTab;
@property (getter = isDefaultSetupDone, assign) BOOL defaultSetupDone;

// Colors
@property (nonatomic) UIColor *indicatorColor;
@property (nonatomic) UIColor *tabsViewBackgroundColor;
@property (nonatomic) UIColor *contentViewBackgroundColor;

@end

@implementation TabContainerViewController

#pragma mark - Init

//////通过在storyboard中指定class加载时会触发
-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self defaultSettings]; /////所有用到变量的初始化
    }
    return self;
}

//////通过指定xib加载时触发
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self defaultSettings];
    }
    
    return self;
}

/////通过代码创建时触发
-(id)init {
    if (self = [super init]) {
        [self defaultSettings];
    }
    return self;
}

#pragma mark - View life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // Do setup if it's not done yet
    if (![self isDefaultSetupDone]) {
        [self defaultSetup];
    }
}


///////控制器旋转时会触发，需要重新布局
- (void)viewWillLayoutSubviews {
    
    // Re-layout sub views
    [self layoutSubviews]; //////子视图的创建在这里进行
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)layoutSubviews {
    CGFloat topLayoutGuid = 0.0;
    if (IOS_VERSION_7) {
        topLayoutGuid = 20.0;  //////statusbar的高度
        if (self.navigationController && !self.navigationController.navigationBarHidden) {
            //////如果是ios7及以前版本，需要去除naivgationbar的高度
            topLayoutGuid +=self.navigationController.navigationBar.frame.size.height;
        }
    }
    
    
    //////定义tabsView的位置及大小
    CGRect frame = self.tabsView.frame;
    frame.origin.x = 0.0;
    frame.origin.y = topLayoutGuid; //////固定在了顶部，也可根据需求进行修改
    frame.size.width = CGRectGetWidth(self.view.frame);
    frame.size.height = [self.tabHeight floatValue];
    
    self.tabsView.frame = frame;
    
    
    /////定义contentView的位置及大小
    frame = self.contentView.frame;
    frame.origin.x = 0.0 ;
    frame.origin.y = CGRectGetMaxY(self.tabsView.frame);
    frame.size.width = CGRectGetWidth(self.view.frame);
    frame.size.height = CGRectGetHeight(self.view.frame) - self.tabsView.frame.size.height - topLayoutGuid;
    self.contentView.frame = frame;
}

#pragma mark --IBAction
-(void)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    UIView *tabView = tapGestureRecognizer.view;
    
    __block NSUInteger index = [self.tabs indexOfObject:tabView];
    
    if (self.activeTabIndex != index) {
        [self selectTabAtIndex:index
                      didSwipe:NO];
    }
}


#pragma mark -- Public Method
-(void)reloadData {
    // Empty all options
    _tabHeight = nil;
    _tabWidth = nil;

    
    // Empty all colors
    _indicatorColor = nil;
    _tabsViewBackgroundColor = nil;
    _contentViewBackgroundColor = nil;
    
    // Call to setup again with the updated data
    [self defaultSetup];

}

-(void)selectTabAtIndex:(NSUInteger)index {
    [self selectTabAtIndex:index didSwipe:NO];
}

-(void)selectTabAtIndex:(NSUInteger)index didSwipe:(BOOL)didSwipe {
    if (index >= self.tabCount)
        return;
    
    self.animatingToTab = YES; ////动画
    NSUInteger previousIndex = self.activeTabIndex;  //////获取上一个tab的索引
    
    /////将当前位置的索引设置为活动索引
    self.activeTabIndex = index;      //////自定义了setter方法去处理tab的切换逻辑
    self.activeContentIndex = index;
    
    // Inform delegate about the change
    if ([self.delegate respondsToSelector:@selector(tabContainer:didChangeTabToIndex:)]) {
        [self.delegate tabContainer:self didChangeTabToIndex:self.activeTabIndex];
    }
    else if([self.delegate respondsToSelector:@selector(tabContainer:didChangeTabToIndex:fromIndex:)]){
        [self.delegate tabContainer:self didChangeTabToIndex:self.activeTabIndex fromIndex:previousIndex];
    }

}


- (void)setNeedsReloadOptions {
    _tabHeight = nil;
    _tabWidth = nil;
    
    // Update every tab's frame
    for (NSUInteger i = 0; i < self.tabCount; i++) {
        
        UIView *tabView = [self tabViewAtIndex:i];
        
        CGRect frame = tabView.frame;
        frame.origin.x = i * [self.tabWidth floatValue];
        frame.size.width = [self.tabWidth floatValue];
        tabView.frame = frame;

    }

    CGRect bounds = [UIScreen mainScreen].bounds;

    CGFloat topLayoutGuid = 0.0;
    if (IOS_VERSION_7) {
        CGRect statusBar = [[UIApplication sharedApplication] statusBarFrame];
        topLayoutGuid = statusBar.size.height;  //////statusbar的高度
        if (self.navigationController && !self.navigationController.navigationBarHidden) {
            //////如果是ios7及以前版本，需要去除naivgationbar的高度
            topLayoutGuid +=self.navigationController.navigationBar.frame.size.height;
        }
    }
    
    self.tabsView.frame = CGRectMake(self.tabsView.frame.origin.x, topLayoutGuid, bounds.size.width, [self.tabHeight floatValue]);
    
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, CGRectGetMaxY(self.tabsView.frame), bounds.size.width, bounds.size.height-topLayoutGuid);
    
}
- (void)setNeedsReloadColors {
    
    // If our delegate doesn't respond to our colors method, return
    // Otherwise reload colors
    if (![self.delegate respondsToSelector:@selector(tabContainer:colorForComponent:withDefault:)]) {
        return;
    }
    
    // These colors will be updated
    UIColor *indicatorColor;
    UIColor *tabsViewBackgroundColor;
    UIColor *contentViewBackgroundColor;
    
    // Get indicatorColor and check if it is different from the current one
    // If it is, update it
    indicatorColor = [self.delegate tabContainer:self colorForComponent:TabContainerIndicator withDefault:kIndicatorColor];
    
    if (![self.indicatorColor isEqualToColor:indicatorColor]) {
        
        // We will iterate through all of the tabs to update its indicatorColor
        [self.tabs enumerateObjectsUsingBlock:^(TabView *tabView, NSUInteger index, BOOL *stop) {
            tabView.indicatorColor = indicatorColor;
        }];
        
        // Update indicatorColor to check again later
        self.indicatorColor = indicatorColor;
    }
    
    // Get tabsViewBackgroundColor and check if it is different from the current one
    // If it is, update it
    tabsViewBackgroundColor = [self.delegate tabContainer:self colorForComponent:TabContainerTabsView withDefault:kTabsViewBackgroundColor];
    
    if (![self.tabsViewBackgroundColor isEqualToColor:tabsViewBackgroundColor]) {
        
        // Update it
        self.tabsView.backgroundColor = tabsViewBackgroundColor;
        
        // Update tabsViewBackgroundColor to check again later
        self.tabsViewBackgroundColor = tabsViewBackgroundColor;
    }
    
    // Get contentViewBackgroundColor and check if it is different from the current one
    // Yeah update it, too
    contentViewBackgroundColor = [self.delegate tabContainer:self colorForComponent:TabContainerContent withDefault:kContentViewBackgroundColor];
    
    if (![self.contentViewBackgroundColor isEqualToColor:contentViewBackgroundColor]) {
        
        // Yup, update
        self.contentView.backgroundColor = contentViewBackgroundColor;
        
        // Update this, too, to check again later
        self.contentViewBackgroundColor = contentViewBackgroundColor;
    }
    
}


-(UIColor *)colorForComponent:(TabContainerComponent)component {
    switch (component) {
        case TabContainerIndicator:
            return [self indicatorColor];
        case TabContainerTabsView:
            return [self tabsViewBackgroundColor];
        case TabContainerContent:
            return [self contentViewBackgroundColor];
        default:
            return [UIColor clearColor];
    }
}

#pragma mark --Private Method

-(void)defaultSettings {
    self.pageViewController =  [[UIPageViewController alloc]
                                initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                options:nil];
    [self addChildViewController:self.pageViewController];  //////建立逻辑上的父子关系
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    self.animatingToTab = NO;
    self.defaultSetupDone = NO;
}

-(void)defaultSetup {
    /////移除所有的tabView
    for(TabView *tabView in self.tabs) {
        [tabView removeFromSuperview];
    }
    
    /////清空数组中的元素，完成内存释放
    [self.tabs removeAllObjects];
    [self.contents removeAllObjects];
    
    self.tabCount = [self.dataSource numberOfTabsForTabContainer:self];   //////从委托方法中得到tab的数量
    
    /////构造tabs数据，缓存tabView
    self.tabs = [NSMutableArray arrayWithCapacity:self.tabCount];
    for (int i=0 ; i<self.tabCount; i++) {
        [self.tabs addObject:[NSNull null]];
    }
    
    //////构造contents的数据,缓存contentView
    self.contents = [NSMutableArray arrayWithCapacity:self.tabCount];
    for (int i=0 ; i<self.tabCount; i++) {
        [self.contents addObject:[NSNull null]];
    }
    
    
    ////根据tag去视图中查找，没找到，重新创建。确保有实例
    self.tabsView  = (UIView *)[self.view viewWithTag:kTabViewTag];
    if (!self.tabsView) {
        /////创建tabsView
        self.tabsView = [[UIView alloc]
                         initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), [self.tabHeight floatValue])];
        self.tabsView.autoresizingMask = UIViewAutoresizingFlexibleWidth; /////旋转时自动拉伸宽度
        self.tabsView.tag = kTabViewTag;
        self.tabsView.backgroundColor = self.tabsViewBackgroundColor;
        
        [self.view insertSubview:self.tabsView atIndex:0];  //////添加到子视图
        
    }
    
//    CGFloat contentSizeWidth = 0;
    //////将TabView 添加到self.tabsView上，完成tabbar的创建
    for (NSUInteger i = 0 ; i<self.tabCount; i++) {
        TabView *tabView = [self tabViewAtIndex:i];
        
        CGRect frame = tabView.frame;
        frame.origin.x = i*[self.tabWidth floatValue];
        frame.size.width = [self.tabWidth floatValue];
        
        tabView.frame = frame;
        [self.tabsView addSubview:tabView]; /////添加到子视图
        
        ////添加按下去的手势
        UITapGestureRecognizer *tapGestureRecognizer =[[UITapGestureRecognizer alloc]
                                                       initWithTarget:self action:@selector(handleTapGesture:)];
        [tabView addGestureRecognizer:tapGestureRecognizer];
    }
    
    
    ///////构造self.contentView
    self.contentView = [self.view viewWithTag:kContentViewTag];
    if (!self.contentView) {
        self.contentView = self.pageViewController.view; ///////重点：将pageviewcontroller.view赋给self.contentview
        self.contentView.autoresizingMask  = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.contentView.backgroundColor = self.contentViewBackgroundColor;
        self.contentView.bounds = self.view.bounds;
        self.contentView.tag = kContentViewTag;
        
        [self.view insertSubview:self.contentView atIndex:0];
    }
    
    /////设置第一个tab页默认选中
    NSUInteger index = 0;
    [self selectTabAtIndex:index];
    
    /////更新状态，表示设置完成
    self.defaultSetupDone = YES;

}



-(TabView *)tabViewAtIndex:(NSUInteger)index {
    
    if (index >= self.tabCount) {
        return nil;
    }
    
    if ([[self.tabs objectAtIndex:index] isEqual:[NSNull null]]) {
        
        // Get view from dataSource
        UIView *tabViewContent = [self.dataSource tabContainer:self viewForTabAtIndex:index];
        tabViewContent.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // Create TabView and subview the content
        TabView *tabView = [[TabView alloc] initWithFrame:CGRectMake(0.0, 0.0, [self.tabWidth floatValue], [self.tabHeight floatValue])];
        [tabView addSubview:tabViewContent]; ////添加tab内容
        ////设置属性
        [tabView setClipsToBounds:YES];
        [tabView setIndicatorColor:self.indicatorColor];
        
        tabViewContent.center = tabView.center; /////内容居中
        
        // Replace the null object with tabView
        [self.tabs replaceObjectAtIndex:index withObject:tabView]; /////替换缓存中的对象
    }
    
    return [self.tabs objectAtIndex:index];
}
                     
#pragma mark --Getter 
-(NSNumber *)tabHeight {
    if (!_tabHeight) {
        CGFloat value = kTabHeight;
        if ([self.delegate respondsToSelector:@selector(heightForTabInTabContainer:)])
            value = [self.delegate heightForTabInTabContainer:self];  /////从委托方法中获取
        self.tabHeight = [NSNumber numberWithFloat:value];  /////setter
    }
    return _tabHeight;
}

-(NSNumber *)tabWidth {
    if (!_tabWidth) {
        CGRect bounds = [UIScreen mainScreen].bounds;
        CGFloat width = bounds.size.width/self.tabCount;
        self.tabWidth = [NSNumber numberWithFloat:width];
    }
    
    return _tabWidth;
}

- (UIColor *)indicatorColor {
    
    if (!_indicatorColor) {
        UIColor *color = kIndicatorColor;
        if ([self.delegate respondsToSelector:@selector(tabContainer:colorForComponent:withDefault:)]) {
            color = [self.delegate tabContainer:self colorForComponent:TabContainerIndicator withDefault:color];
        }
        self.indicatorColor = color;
    }
    return _indicatorColor;
}

-(UIColor *)tabsViewBackgroundColor {
    if (!_tabsViewBackgroundColor) {
        UIColor *color = kTabsViewBackgroundColor;
        if ([self.delegate respondsToSelector:@selector(tabContainer:colorForComponent:withDefault:)]) {
            color = [self.delegate tabContainer:self colorForComponent:TabContainerTabsView withDefault:color];
        }
        self.tabsViewBackgroundColor = color;
    }
    return  _tabsViewBackgroundColor;
}
                     
- (UIColor *)contentViewBackgroundColor {
    
    if (!_contentViewBackgroundColor) {
        UIColor *color = kContentViewBackgroundColor;
        if ([self.delegate respondsToSelector:@selector(tabContainer:colorForComponent:withDefault:)]) {
            color = [self.delegate tabContainer:self colorForComponent:TabContainerContent withDefault:color];
        }
        self.contentViewBackgroundColor = color;
    }
    return _contentViewBackgroundColor;
}


#pragma mark -- Setter
-(void)setActiveTabIndex:(NSUInteger)activeTabIndex {
    TabView *activeTabView;
    activeTabView = [self tabViewAtIndex:self.activeTabIndex]; ////根据索引从缓存中取是一个TabView实例
    activeTabView.selected = NO;
    
    activeTabView = [self tabViewAtIndex:activeTabIndex];
    activeTabView.selected = YES;  //////这时会重绘indicator.
    
    _activeTabIndex = activeTabIndex ; /////给成员变量赋值。
    
    
}

-(void)setActiveContentIndex:(NSUInteger)activeContentIndex {
    
    /////从缓存中读取当前的控制器。
    UIViewController *viewController = [self viewControllerAtIndex:activeContentIndex];
    
    if (!viewController) {
        viewController = [[UIViewController alloc] init];
        viewController.view = [[UIView alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
    }
    
//    __weak UIPageViewController *weakPageViewController = self.pageViewController;
    __weak typeof(self) weakSelf = self;
    
    ///////如果点击的控制器与当前显示的控制器是一个控制器
    [self.pageViewController setViewControllers:@[viewController]
                                      direction:(activeContentIndex < self.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:^(BOOL completed) {
                                         weakSelf.animatingToTab = NO;
                                     }];

    ///////未完待续。。。。。
    NSInteger index;
    index = self.activeContentIndex - 1;
    if (index >= 0 &&
        index != activeContentIndex &&
        index != activeContentIndex - 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    index = self.activeContentIndex;
    if (index != activeContentIndex - 1 &&
        index != activeContentIndex &&
        index != activeContentIndex + 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    index = self.activeContentIndex + 1;
    if (index < self.contents.count &&
        index != activeContentIndex &&
        index != activeContentIndex + 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    
    _activeContentIndex = activeContentIndex;
    
    
    
}




#pragma mark -- UIPageViewControllerDataSource
-(UIViewController *)viewControllerAtIndex:(NSInteger)index {
    if (index >= self.tabCount) {
        return nil;
    }
    
    UIViewController *viewController = self.contents[index];
    if ([viewController isEqual:[NSNull null]]) {
        viewController = [self.dataSource tabContainer:self contentViewControllerForTabAtIndex:index];
        
        [self.contents replaceObjectAtIndex:index
                                 withObject:viewController];
    }
    return self.contents[index];
}


- (NSUInteger)indexForViewController:(UIViewController *)viewController {
    
    return [self.contents indexOfObject:viewController];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [self indexForViewController:viewController];
    index++;
    return [self viewControllerAtIndex:index];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [self indexForViewController:viewController];  /////得到当前viewcontroller的索引
    index--;
    return [self viewControllerAtIndex:index];
}

#pragma mark -- UIPageViewControllerDelegate
-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    UIViewController *viewController = self.pageViewController.viewControllers[0];
    // Select tab
    NSUInteger index = [self indexForViewController:viewController];
    [self selectTabAtIndex:index didSwipe:YES];
}

@end
