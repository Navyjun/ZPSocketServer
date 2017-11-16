//
//  LocationFileViewController.m
//  ZPS
//
//  Created by 张海军 on 2017/11/16.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "LocationFileViewController.h"
#import "ServerSocketManager.h"

@interface LocationFileViewController ()

@end

@implementation LocationFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ServerSocketManager *serverM = [ServerSocketManager shareServerSocketManager];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator<NSString *> * myDirectoryEnumerator;
    NSString *strPath = serverM.dataSavePath;
    myDirectoryEnumerator=  [fileManager enumeratorAtPath:strPath];
    while (strPath = [myDirectoryEnumerator nextObject]) {
        for (NSString * namePath in strPath.pathComponents) {
            NSLog(@"-----AAA-----%@", namePath  );
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
