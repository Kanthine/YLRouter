//
//  ViewController.m
//  YLRouterOtherApp
//
//  Created by long on 2020/12/26.
//

#import "ViewController.h"

@interface ViewController ()
<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) NSMutableArray<NSString *> *itemsArray;
@property (nonatomic ,strong) UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"跳转到 Main App 的指定页面";
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.tableView];
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
        NSString *url = @"YLRouterMain://reader";
        UIPasteboard.generalPasteboard.string = url;
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:url] options:@{@"key":@"reader"}  completionHandler:^(BOOL success) {
                    
        }];
    }else if ([item isEqualToString:@"阅读器"]) {
       
    }else if ([item isEqualToString:@"阅读器 翻页"]) {
       
    }else if ([item isEqualToString:@""]) {
        
    }else if ([item isEqualToString:@""]) {
        
    }
    
}

#pragma mark - setters and getters

- (NSMutableArray<NSString *> *)itemsArray{
    if (_itemsArray == nil) {
        _itemsArray = [NSMutableArray array];
        [_itemsArray addObject:@"WebView"];
        [_itemsArray addObject:@"阅读器"];
        [_itemsArray addObject:@"阅读器 翻页"];
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
