//
//  YLWebViewController.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import "YLWebViewController.h"
#import <WebKit/WebKit.h>
@interface YLWebViewController ()
@property (nonatomic ,strong) WKWebView *webView;
@end

@implementation YLWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.webView];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [_webView loadRequest:request];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

#pragma mark - setters and getters

- (NSString *)url{
    if (_url == nil) {
        _url = @"https://juejin.cn/post/6844903582739726350";
    }
    return _url;
}

- (WKWebView *)webView{
    if (_webView == nil) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:UIScreen.mainScreen.bounds configuration:config];
//        _webView.UIDelegate = self;
//        _webView.navigationDelegate = self;
        _webView.allowsBackForwardNavigationGestures = YES;
    }
    return _webView;
}

@end
