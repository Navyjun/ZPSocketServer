//
//  ViewController.m
//  ZPS
//
//  Created by 张海军 on 2017/11/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ViewController.h"
#import "ServerSocketManager.h"
#import "NSString+path.h"
#import "ZPHomeCell.h"
#import "HJWifiUtil.h"
#import "ImageViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
<UITableViewDelegate,
UITableViewDataSource,
ServerSocketManagerDelegate>
/// tableView
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *wifiStateLabel;
///
@property (nonatomic, strong) NSArray *itemArray;
/// 当前选中的位置
@property (nonatomic, strong) NSIndexPath *seleteIndexPath;
/// 刷新当前网络名称
@property (nonatomic, weak) NSTimer *refreshTime;
@property (weak, nonatomic) IBOutlet UITextField *portTextFiled;
@property (weak, nonatomic) IBOutlet UILabel *acceptStateLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = @"智屏";
    
    ServerSocketManager *serverM = [ServerSocketManager shareServerSocketManager];
    serverM.delegate = self;
    self.portTextFiled.text = @"67543";

    // tb011923_33
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 80;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator<NSString *> * myDirectoryEnumerator;
    NSString *strPath = serverM.dataSavePath;
    myDirectoryEnumerator=  [fileManager enumeratorAtPath:strPath];
    while (strPath = [myDirectoryEnumerator nextObject]) {
        for (NSString * namePath in strPath.pathComponents) {
            NSLog(@"-----AAA-----%@", namePath  );
        }
    }
    
    
    self.wifiStateLabel.text = [NSString stringWithFormat:@"当前连接wifi:%@",[HJWifiUtil fetchWiFiName]];
    // 定时器
    self.refreshTime = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshWifiName) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
- (void)refreshWifiName{
    self.wifiStateLabel.text = [NSString stringWithFormat:@"当前连接wifi:%@",[HJWifiUtil fetchWiFiName]];
    if (self.itemArray.count) {
        [self.tableView reloadData];
    }
}
- (IBAction)acceptPortButtonDidClick:(id)sender {
    NSString *portStr = self.portTextFiled.text;
    if (portStr.length > 0) {
        [self.view endEditing:YES];
        ServerSocketManager *manager = [ServerSocketManager shareServerSocketManager];
        BOOL isSucces = [[ServerSocketManager shareServerSocketManager] startListenPort:portStr.intValue]; //67543
        self.acceptStateLabel.text = [NSString stringWithFormat:@"监听%@端口%@",self.portTextFiled.text,isSucces?@"成功":@"失败"];
        NSLog(@"connectedHost:%@\nconnectedPort:%hu\nlocalHost:%@\nlocalPort:%hu",[manager connectedHost],[manager connectedPort],[manager localHost],[manager localPort]);
    }
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.itemArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZPHomeCell *cell = [ZPHomeCell homeCell:tableView];
    ServerSocketItem *item = self.itemArray[indexPath.row];
    cell.dataItem = item;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ServerSocketItem *dataItem = self.itemArray[indexPath.row];
    if (!dataItem.finishAccept) {
        return;
    }
    if (dataItem.fileType == 2 ) {
        AVPlayerViewController *playVC = [[AVPlayerViewController alloc] init];
        playVC.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:dataItem.filePath]];
        [self presentViewController:playVC animated:YES completion:nil];
    }else if (dataItem.fileType == 1){
        self.seleteIndexPath = indexPath;
        
        ImageViewController *imageVC = [[ImageViewController alloc] init];
        imageVC.imgPath = dataItem.filePath;
        [self presentViewController:imageVC animated:YES completion:nil];
    }
}




#pragma mark - ServerSocketManagerDelegate
- (void)serverSocketManager:(ServerSocketManager *)server fileAccepting:(ServerSocketItem *)item{
     [self.tableView reloadData];
}

- (void)serverSocketManager:(ServerSocketManager *)server fileHeadAccept:(ServerSocketItem *)item{
     [self.tableView reloadData];
}

- (void)serverSocketManager:(ServerSocketManager *)server fileListAccept:(NSArray *)fileList{
    self.itemArray = fileList;
    NSLog(@"%zd",fileList.count);
    [self.tableView reloadData];
}

@end
