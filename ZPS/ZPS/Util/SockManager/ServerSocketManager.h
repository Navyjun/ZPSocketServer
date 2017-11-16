//
//  ServerSocketManager.h
//  ZPS
//
//  Created by 张海军 on 2017/11/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerSocketItem.h"

@class ServerSocketManager;

@protocol ServerSocketManagerDelegate <NSObject>

@optional
// 列表接受完成后的回调
- (void)serverSocketManager:(ServerSocketManager *)server fileListAccept:(NSArray *)fileList;
// 单个文件头部信息接受完成后的回调
- (void)serverSocketManager:(ServerSocketManager *)server fileHeadAccept:(ServerSocketItem *)item;
// 文件正在接受时进度的回调
- (void)serverSocketManager:(ServerSocketManager *)server fileAccepting:(ServerSocketItem *)item;
// 连接状态 连接成功 / 断开 时回调
- (void)serverSocketManager:(ServerSocketManager *)server connect:(BOOL)isConnect connectIp:(NSString *)ip;
@end


@interface ServerSocketManager : NSObject
/// 保存数据的主地址
@property (nonatomic, copy)  NSString *dataSavePath;

/// delegate
@property (nonatomic, weak) id <ServerSocketManagerDelegate> delegate;

/**
 socket管理类

 @return socket管理类
 */
+ (instancetype)shareServerSocketManager;


/**
 开始监听某个端口

 @param prot 端口号
 */
- (BOOL)startListenPort:(uint16_t)prot;

- (NSString *)connectedHost;
- (uint16_t)connectedPort;

- (NSString *)localHost;
- (uint16_t)localPort;

@end
