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
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://juejin.cn/post/6844903582739726350"]];
    [_webView loadRequest:request];
}

#pragma mark - setters and getters

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
