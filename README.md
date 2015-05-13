TabContainerViewController
==========

容器控制器，可以显示多标签Tab页及标签所对应的内容页。类似UITabBarController，只是这个TabBar是显示在页面顶部。

[![](https://raw.github.com/ReyZhang/TabContainerViewController/master/Screens/1.gif)](https://raw.github.com/ReyZhang/TabContainerViewController/master/Screens/1.gif)
[![](https://raw.github.com/ReyZhang/TabContainerViewController/master/Screens/2.gif)](https://raw.github.com/ReyZhang/TabContainerViewController/master/Screens/2.gif)
How to use
==========
写一个继承自TabContainerViewController的控制器，在控制器中通过调用[self reloadData]来加载。在这之前需要实现TabContainerViewController的代理

``` objective-c
@interface ViewController () <TabContainerDelegate,TabContainerDataSource>
@property (nonatomic) NSUInteger numberOfTabs;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = self;
    self.delegate = self;
    self.numberOfTabs = 5;   ///////当设置数量时，去调用setter方法去加载控件

}
- (void)setNumberOfTabs:(NSUInteger)numberOfTabs {
    
    // Set numberOfTabs
    _numberOfTabs = numberOfTabs;
    
    // Reload data
    [self reloadData];
    
}

```

代理方法
``` objective-c
#pragma mark - Interface Orientation Changes
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Update changes after screen rotates
    [self performSelector:@selector(setNeedsReloadOptions) withObject:nil afterDelay:duration];
}

#pragma mark --TabContainerDataSource
-(NSUInteger)numberOfTabsForTabContainer:(TabContainerViewController *)tabContainer {
    return self.numberOfTabs;
}

-(UIView *)tabContainer:(TabContainerViewController *)tabContainer viewForTabAtIndex:(NSUInteger)index {
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = [NSString stringWithFormat:@"Tab #%ld", index];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [label sizeToFit];
    
    return label;
}

-(UIViewController *)tabContainer:(TabContainerViewController *)tabContainer contentViewControllerForTabAtIndex:(NSUInteger)index {
    ContentViewController *cvc = [self.storyboard instantiateViewControllerWithIdentifier:@"contentViewController"];
    
    cvc.labelString = [NSString stringWithFormat:@"Content View #%ld", index];
    
    return cvc;
}


#pragma mark --TabContainerDelegate
-(CGFloat)heightForTabInTabContainer:(TabContainerViewController *)tabContainer {
    return 44;
}

-(UIColor *)tabContainer:(TabContainerViewController *)tabContainer colorForComponent:(TabContainerComponent)component withDefault:(UIColor *)color {
    switch (component) {
        case TabContainerIndicator:
            return [[UIColor redColor] colorWithAlphaComponent:0.64];
        case TabContainerTabsView:
            return [[UIColor whiteColor] colorWithAlphaComponent:0.32];
        case TabContainerContent:
            return [[UIColor darkGrayColor] colorWithAlphaComponent:0.32];
        default:
            return color;
    }
}

```

Requirements
============
TabContainerViewController requires either iOS 5.0 and above.

License
============
TabContainerViewController is available under the MIT License. See the LICENSE file for more info.

ARC
============
TabContainerViewController uses ARC.

Contact
============
[Rey Zhang](http://github.com/ReyZhang) 
