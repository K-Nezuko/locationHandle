//
//  ViewController.m
//  locationHandle
//
//  Created by Dream on 2019/12/3.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "Coordinate.h"
#import "ChangeLoction.h"
#import <Carbon/Carbon.h>
#import "AlertViewController.h"
#import "Location.h"

typedef NS_OPTIONS(NSInteger, MoveDirectionType) {
    MoveDirectionTypeNone = -1,
    MoveDirectionTypeUp = 1<<0,
    MoveDirectionTypeDown = 1<<1,
    MoveDirectionTypeLeft = 1<<2,
    MoveDirectionTypeRight = 1<<3,
};

@interface ViewController() <NSComboBoxDelegate, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>

// UI
@property (weak) IBOutlet NSView *contentView;          // 地图bgView
@property (weak) IBOutlet NSView *cLocationBgView;      // 当前位置背景
@property (weak) IBOutlet NSView *menueView;            // 菜单栏
@property (weak) IBOutlet NSTextField *currentTF;       // 当前位置坐标
@property (weak) IBOutlet NSTextField *prepareTF;       // 目标位置坐标
@property (weak) IBOutlet NSComboBox *collectionBox;    // 收藏
@property (nonatomic, strong) WKWebView *wk_internalWebView; // 承载腾讯地图的浏览器

// data
@property (nonatomic, strong) NSMutableArray *collectionNames;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self didInitialize];
}

#pragma mark - 初始化
- (void)didInitialize {
    // 当前位置
    self.currentTF.stringValue = [Location shareInstance].cLocation.stringValue;
    // 收藏初始化
    self.collectionBox.delegate = self;
    [self.collectionBox addItemsWithObjectValues:self.collectionNames];
    // map初始化
    [self.contentView addSubview:self.wk_internalWebView positioned:NSWindowBelow relativeTo:self.cLocationBgView];
    [self loadWKWebView];
    // 当前位置提示框背景色
    self.cLocationBgView.wantsLayer = true;
    self.cLocationBgView.layer.backgroundColor = [NSColor colorWithWhite:0.9 alpha:0.85].CGColor;
    // 键盘控制
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull aEvent) {
        return [self directionKeyDown:aEvent];;
    }];
}

#pragma mark - action
/// 复制
- (IBAction)copyAction:(id)sender {
    NSString *currentLocation = self.currentTF.stringValue;
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:currentLocation forType:NSPasteboardTypeString];
}

/// 添加收藏
- (IBAction)collectionAction:(NSButton *)sender {
    NSString *location = self.currentTF.stringValue;
    if (location.length == 0) { // 当前位置不存在
        [self showAlertWithMessage:@"收藏地址不能为空"];
    } else {
        Coordinate *c = [[Coordinate alloc] initWithLatLngStr:self.currentTF.stringValue];
        __weak typeof(self)ws = self;
        [self showCollectionAlertWithComplete:^(NSString *cTitle) {
            [ws saveCollectLocation:c.stringValue name:cTitle];
            [ws.collectionNames addObject:cTitle];
            [ws.collectionBox addItemWithObjectValue:cTitle];
        }];
        
    }
}

/// 取消收藏
- (IBAction)cancleCollection:(id)sender {
    NSString *selected = self.collectionBox.objectValueOfSelectedItem;
    NSInteger index = self.collectionBox.indexOfSelectedItem;
    if (selected.length > 0) {
        [self deleteCollectWithIndex:index];
        [self.collectionBox deselectItemAtIndex:index];
        [self.collectionBox removeItemAtIndex:index];
    }
}

/// 前往地点
- (IBAction)gotoCollection:(id)sender {
    NSString *location = self.prepareTF.stringValue;
    if (location.length == 0) return;
    
    Coordinate *c = [[Coordinate alloc] initWithLatLngStr:location];
    [self updateCurrentLocation:c];
}

/// 结束输入状态
- (void)mouseDown:(NSEvent *)event {
    [[NSApplication sharedApplication].mainWindow makeFirstResponder:0];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *method = [NSString stringWithFormat:@"%@:", message.name];
    SEL selector = NSSelectorFromString(method);
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector withObject:message.body afterDelay:0];
    } else {
        NSLog(@"未实行方法：%@", method);
    }
}
/// 点击地图上获取目标位置
- (void)selectedLatLng:(NSString *)param {
    Coordinate *gd = [[Coordinate alloc] initWithLatLngStr:param];
    Coordinate *sys = [self sysLocationFromGaode:gd];
    self.prepareTF.stringValue = sys.stringValue;
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self changeMapCenter:[Location shareInstance].cLocation];
    self.cLocationBgView.hidden = NO;
}

#pragma mark - WKUIDelegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    //修复 WKWebView does not open any links which have target="_blank" aka.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    [self showAlertWithMessage:message];
    completionHandler();
}

#pragma mark - NSComboBoxDelegate
/// 选择收藏
- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
    NSComboBox *box = (NSComboBox *)notification.object;
    if (box.objectValueOfSelectedItem) {
        NSDictionary *dic = [self collectLocations][box.indexOfSelectedItem];
        self.prepareTF.stringValue = dic[@"latLng"];
    }
}

#pragma mark - getter
- (WKWebView *)wk_internalWebView{
    if (!_wk_internalWebView) {
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addScriptMessageHandler:self name:@"selectedLatLng"];
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = userContentController;
        _wk_internalWebView = [[WKWebView alloc] initWithFrame:self.contentView.bounds configuration:configuration];
        _wk_internalWebView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        _wk_internalWebView.autoresizesSubviews                  = YES;
        _wk_internalWebView.allowsBackForwardNavigationGestures  = NO;
        _wk_internalWebView.navigationDelegate                   = self;
        _wk_internalWebView.UIDelegate                           = self;
    }
    return _wk_internalWebView;
}

- (NSMutableArray *)collectionNames {
    if (_collectionNames == nil) {
        _collectionNames = [NSMutableArray array];
        for (NSDictionary *dic in [self collectLocations]) {
            [_collectionNames addObject:dic[@"name"]];
        }
    }
    return _collectionNames;
}

#pragma mark - private 地图
/// 加载地图
- (void)loadWKWebView {
    NSURL * url = [NSURL fileURLWithPath:[[NSBundle mainBundle]bundlePath]];
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSError *error = nil;
    NSString *html = [[NSString alloc] initWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:&error];
    if (error == nil) {
        [self.wk_internalWebView loadHTMLString:html baseURL:url];
    } else {
        NSLog(@"%@", error);
    }
}

/// 更新地图中心点
- (void)changeMapCenter:(Coordinate *)coordinate {
    if (coordinate == nil) return;
    Coordinate *coor = [self gdLocationFromSys:coordinate];
    NSString *jsStr = [NSString stringWithFormat:@"window.changeMapCenter('%@', '%@')", coor.latStr, coor.lngStr];
    [self.wk_internalWebView evaluateJavaScript:jsStr completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        if (error) {
            NSLog(@"错误:%@", error.localizedDescription);
        }
    }];
}

/// 高德坐标转iOS坐标
- (Coordinate *)sysLocationFromGaode:(Coordinate *)gd {
    CLLocationCoordinate2D location2D = CLLocationCoordinate2DMake(gd.latitude, gd.longitude);
    CLLocationCoordinate2D WGSlocation2D = [ChangeLoction gcj02ToWgs84:location2D];
    return [[Coordinate alloc] initWithLat:WGSlocation2D.latitude lng:WGSlocation2D.longitude];
}

/// iOS坐标转高德
- (Coordinate *)gdLocationFromSys:(Coordinate *)sys {
    CLLocationCoordinate2D WGSlocation2D = CLLocationCoordinate2DMake(sys.latitude, sys.longitude);
    CLLocationCoordinate2D location2D = [ChangeLoction wgs84ToGcj02:WGSlocation2D];
    return [[Coordinate alloc] initWithLat:location2D.latitude lng:location2D.longitude];
}

#pragma mark - private 控制
/// 更新当前位置
- (void)updateCurrentLocation:(Coordinate *)c {
    NSString *errMsg = [[Location shareInstance] moveToNewLocation:c];
    if (errMsg.length >0) {
        [self showAlertWithMessage:errMsg];
    } else {
        // 更新"当前"的显示内容
        self.currentTF.stringValue = c.stringValue;
        // 更新地图中心点
        [self changeMapCenter:c];
        // 重置收藏选中
        NSString *selected = self.collectionBox.objectValueOfSelectedItem;
        if (selected.length > 0) [self.collectionBox deselectItemAtIndex:self.collectionBox.indexOfSelectedItem];
    }
}

/// 上下左右控制
- (void)moveToDirection:(MoveDirectionType)type step:(double)step {
    double lat = [Location shareInstance].cLocation.latitude;
    double lng = [Location shareInstance].cLocation.longitude;
    
    if (type & MoveDirectionTypeUp) {
        lat += step;
    }
    if (type & MoveDirectionTypeDown) {
        lat -= step;
    }
    if (type & MoveDirectionTypeLeft) {
        lng -= step;
    }
    if (type & MoveDirectionTypeRight) {
        lng += step;
    }
    
    Coordinate *c = [[Coordinate alloc] initWithLat:lat lng:lng];
    [self updateCurrentLocation:c];
}

/// 键盘控制
- (NSEvent *)directionKeyDown:(NSEvent *)event {
    
    NSWindow *mainWindow = [NSApplication sharedApplication].mainWindow;
    if (mainWindow.firstResponder != mainWindow && mainWindow.firstResponder != self.wk_internalWebView) return event;
    
    unsigned short  keycode = [event keyCode];
    MoveDirectionType type = MoveDirectionTypeNone;
    if (keycode == kVK_ANSI_W || keycode == kVK_UpArrow) {
        type = MoveDirectionTypeUp;
    }
    else if (keycode == kVK_ANSI_S || keycode == kVK_DownArrow) {
        type = MoveDirectionTypeDown;
    }
    else if (keycode == kVK_ANSI_A || keycode == kVK_LeftArrow) {
        type = MoveDirectionTypeLeft;
    }
    else if (keycode == kVK_ANSI_D || keycode == kVK_RightArrow) {
        type = MoveDirectionTypeRight;
    }
    
    if (type == MoveDirectionTypeNone) {
        return event;
    }
    
    [self moveToDirection:type step:0.00015];
    return nil;
}

#pragma mark - private 收藏
/// 获取所有收藏
- (NSArray *)collectLocations {
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"collection"];
}

/// 保存收藏
- (void)saveCollectLocation:(NSString *)latLng name:(NSString *)name {
    NSDictionary *dic = @{@"name":name, @"latLng":latLng};
    NSArray *ls = [[NSUserDefaults standardUserDefaults] valueForKey:@"collection"];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:ls];
    [arr addObject:dic];
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:@"collection"];
}

/// 删除收藏
- (void)deleteCollectWithIndex:(NSInteger)index {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[self collectLocations]];
    [arr removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:@"collection"];
}

#pragma mark - private 弹窗
/// 弹窗提示
- (void)showAlertWithMessage:(NSString *)msg {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = msg;
    [alert beginSheetModalForWindow:[self.view window] completionHandler:nil];
}

/// 收藏弹窗提示
- (void)showCollectionAlertWithComplete:(void(^)(NSString *cTitle))complete {
    AlertViewController *vc = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"AlertViewController"];
    vc.completeBlock = complete;
    [self presentViewControllerAsSheet:vc];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
