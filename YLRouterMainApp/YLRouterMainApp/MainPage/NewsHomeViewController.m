//
//  NewsHomeViewController.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/29.
//

#import "NewsHomeViewController.h"
#import <YLReaderSDK/YLReaderSDK.h>
#import <JLRoutes/JLRRouteDefinition.h>
#import <JLRoutes/JLRRouteRequest.h>
#import <JLRoutes/JLRRouteResponse.h>

@interface NewsHomeViewController ()
<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) NSMutableArray<NSString *> *itemsArray;
@property (nonatomic ,strong) UITableView *tableView;

@end

@implementation NewsHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.redColor;

    NSString *pattern = @"YLRouterMain://webView";
    pattern = @"://webView";
    JLRRouteDefinition *route = [[JLRRouteDefinition alloc] initWithPattern:pattern priority:0 handlerBlock:^BOOL(NSDictionary * _Nonnull parameters) {
        NSLog(@"parameters === %@",parameters);
        return YES;
    }];
    NSLog(@"route =====%@",route);

    JLRRouteRequest *request = [[JLRRouteRequest alloc] initWithURL:[NSURL URLWithString:pattern] options:JLRRouteRequestOptionDecodePlusSymbols additionalParameters:@{@"testKey":@"testValue"}];
    NSLog(@"request =====%@",request);
    
    JLRRouteResponse *response = [route routeResponseForRequest:request];
    NSLog(@"response =====%@",response);
    
    [self.view addSubview:self.tableView];
    [YLReaderManager shareReader];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.itemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.itemsArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *item = self.itemsArray[indexPath.row];
    
    if ([item isEqualToString:@"WebView"]) {
        [YLRouterService openURL:kYLRouteURLWebview];
    }else if ([item isEqualToString:@"阅读器"]) {
        [YLRouterService openURL:kYLRouteURLReader];
    }else if ([item isEqualToString:@"个人"]) {
        [YLRouterService openURL:kYLRouteURL_Tab_User];
    }else if ([item isEqualToString:@"个人-设置"]) {
        [YLRouterService openURL:kYLRouteURL_User_Set parameters:@{kYLRouterSegueTabNameKey:@"User"}];
    }else if ([item isEqualToString:@"个人-设置-昵称设置"]) {
        [YLRouterService openURL:kYLRouteURL_User_Set_NickName parameters:@{kYLRouterSegueTabNameKey:@"User"}];
    }else if ([item isEqualToString:@"https://www.baidu.com/"]) {
        [YLRouterService openURL:@"https://www.baidu.com/"];
    }else if ([item isEqualToString:@"YLRouterOther"]) {
        NSString *url = @"YLRouterOther://";
        UIPasteboard.generalPasteboard.string = url;
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:url] options:@{@"key":@"reader"}  completionHandler:^(BOOL success) {
                
        }];
    }else if ([item isEqualToString:@""]) {
        
    }
}

#pragma mark - setters and getters

- (NSMutableArray<NSString *> *)itemsArray{
    if (_itemsArray == nil) {
        _itemsArray = [NSMutableArray array];
        [_itemsArray addObject:@"WebView"];
        [_itemsArray addObject:@"阅读器"];
        [_itemsArray addObject:@"个人"];
        [_itemsArray addObject:@"个人-设置"];
        [_itemsArray addObject:@"个人-设置-昵称设置"];
        [_itemsArray addObject:@"YLRouterOther"];
        [_itemsArray addObject:@"https://www.baidu.com/"];

    }
    return _itemsArray;
}

- (UITableView *)tableView{
    if (_tableView == nil) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:UIScreen.mainScreen.bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
        
        _tableView = tableView;
    }
    return _tableView;
}

@end
