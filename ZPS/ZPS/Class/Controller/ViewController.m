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
@property (weak, nonatomic) IBOutlet UIImageView *QRCodeImageView;
/// 当前监听的端口
@property (nonatomic, assign) NSInteger currentPort;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
            NSLog(@"----AAAAA----%@/%@",serverM.dataSavePath,namePath);
            NSString *path = [NSString stringWithFormat:@"%@/%@",serverM.dataSavePath,namePath];
            UIImage *imge = [self getScreenShotImageFromVideoPath:path];
            self.QRCodeImageView.image = imge;
            self.QRCodeImageView.hidden = NO;
        }
    }
    
    
    self.wifiStateLabel.text = [NSString stringWithFormat:@"当前连接wifi:%@",[HJWifiUtil fetchWiFiName]];
    // 定时器
    self.refreshTime = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshWifiName) userInfo:nil repeats:YES];
    
    [self.view bringSubviewToFront:self.QRCodeImageView];
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
    self.currentPort = 0;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (portStr.length > 0) {
        [self.view endEditing:YES];
        BOOL isSucces = [[ServerSocketManager shareServerSocketManager] startListenPort:portStr.intValue];
        self.acceptStateLabel.text = [NSString stringWithFormat:@"监听%@端口%@",self.portTextFiled.text,isSucces?@"成功":@"失败"];
        if (isSucces) {
            self.currentPort = portStr.intValue;
            [self rightItemDidClick];
        }
    }
}

- (void)rightItemDidClick{
    // {"ipAddress":"192.168.43.1","port":8059,"wifiName":"NX549J"}
    NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
    infoDic[@"ipAddress"] = [HJWifiUtil getLocalIPAddressForCurrentWiFi];
    infoDic[@"port"] = [NSNumber numberWithInteger:self.currentPort];
    infoDic[@"wifiName"] = [HJWifiUtil fetchWiFiName];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    self.QRCodeImageView.image = [self imageQRCodeActionGenerate:jsonStr];
    self.QRCodeImageView.hidden = NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.QRCodeImageView.hidden = YES;
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

- (void)serverSocketManager:(ServerSocketManager *)server connect:(BOOL)isConnect connectIp:(NSString *)ip{
    if (isConnect) {
        self.QRCodeImageView.hidden = YES;
        self.acceptStateLabel.text = [NSString stringWithFormat:@"%@-连接成功",ip];
    }else{
        self.acceptStateLabel.text = @"未连接";
    }
}

#pragma mark -
//生成二维码
- (UIImage *)imageQRCodeActionGenerate:(NSString *)codess
{
    NSString *text = codess;
    
    NSData *stringData = [text dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    UIColor *onColor = [UIColor blackColor];
    UIColor *offColor = [UIColor whiteColor];
    
    //上色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor" keysAndValues:@"inputImage",qrFilter.outputImage,@"inputColor0",[CIColor colorWithCGColor:onColor.CGColor],@"inputColor1",[CIColor colorWithCGColor:offColor.CGColor],nil];
    
    CIImage *qrImage = colorFilter.outputImage;
    
    //绘制
    CGSize size = CGSizeMake(200, 200);
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}

// 获取视频缩略图
- (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath{
    UIImage *shotImage;
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    shotImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return shotImage;
}

@end
