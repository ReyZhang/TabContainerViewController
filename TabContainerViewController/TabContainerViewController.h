//
//  TabContainerViewController.h
//  TabContainerViewController
//
//  Created by Zhang Rey on 5/12/15.
//  Copyright (c) 2015 Zhang Rey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TabContainerComponent) {
    TabContainerIndicator,
    TabContainerTabsView,
    TabContainerContent
};


@protocol TabContainerDataSource;
@protocol TabContainerDelegate;

@interface TabContainerViewController : UIViewController


@property (weak) id<TabContainerDataSource> dataSource;
@property (weak) id<TabContainerDelegate> delegate;


//////加载数据
-(void)reloadData;
/////设置选中哪个Tab页。
-(void)selectTabAtIndex:(NSUInteger)index;

/////处理控制器旋转
- (void)setNeedsReloadColors;
- (void)setNeedsReloadOptions;


////获取三部分的颜色。选中时的indicatorColor, tabsView的backgroundColor, contentView的backgroundcolor
- (UIColor *)colorForComponent:(TabContainerComponent)component;

@end


@protocol TabContainerDataSource <NSObject>

/////返回tabs的数量
-(NSUInteger)numberOfTabsForTabContainer:(TabContainerViewController *)tabContainer;

/////返回每个tab上显示的内容
-(UIView *)tabContainer:(TabContainerViewController *)tabContainer viewForTabAtIndex:(NSUInteger)index;


/////提供内容相关的控制器
-(UIViewController *)tabContainer:(TabContainerViewController *)tabContainer contentViewControllerForTabAtIndex:(NSUInteger)index;

@end

@protocol TabContainerDelegate <NSObject>


@optional
-(CGFloat)heightForTabInTabContainer:(TabContainerViewController *)tabContainer;

//////事件，tab切换后触发
-(void)tabContainer:(TabContainerViewController *)tabContainer didChangeTabToIndex:(NSUInteger)index;

/////监听这个回调可以得到从哪个tab到哪个tab
- (void)tabContainer:(TabContainerViewController *)tabContainer didChangeTabToIndex:(NSUInteger)index fromIndex:(NSUInteger)previousIndex;

//////返回三个组件的颜色，选中时的指示颜色，tabView的背景颜色，contentView的背景颜色
- (UIColor *)tabContainer:(TabContainerViewController *)tabContainer colorForComponent:(TabContainerComponent)component withDefault:(UIColor *)color;

@end