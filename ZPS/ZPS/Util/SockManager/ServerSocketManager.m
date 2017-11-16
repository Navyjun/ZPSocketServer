//
//  ServerSocketManager.m
//  ZPS
//
//  Created by 张海军 on 2017/11/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ServerSocketManager.h"
#import "GCDAsyncSocket.h"
#import "NSString+path.h"
#import <MJExtension/MJExtension.h>

// 客户端 发送列表过来的头部标识
static NSString *const SENDFILEINFOLIST = @"SENDFILE_TYPE_FILEINFOLIST";
// 客户端 传输文件头部的标识符
static NSString *const SENDFILEHEADINFO = @"SENDFILE_TYPE_FILEHEADINFO";

// 当接受到SENDFILEINFOLIST  服务端发送的字符
static NSString *const FILE_LIST_SEND_END = @"FILE_LIST_SEND_END\n";
// 当接受到SENDFILEHEADINFO  服务端发送的字符
static NSString *const FILE_HEAD_SEND_END = @"FILE_HEAD_SEND_END";

@interface ServerSocketManager () <GCDAsyncSocketDelegate>
/// 服务端socket
@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
/// 客户端socket集合
@property (nonatomic, strong) NSMutableArray *clientSocketArray;
/// 输出流
@property (nonatomic, strong) NSOutputStream *outputStream;

/// 当前传输的文件模型对象
@property (nonatomic, strong) ServerSocketItem *currentSendItem;
/// 列表模型集合
@property (nonatomic, strong) NSMutableArray *socketItemArray;
@end


@implementation ServerSocketManager

static ServerSocketManager *socketManager = nil;
+ (instancetype)shareServerSocketManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        socketManager = [[ServerSocketManager alloc] init];
    });
    return socketManager;
}

// 67543
- (BOOL)startListenPort:(uint16_t)prot{
    if (prot <= 0) {
        NSAssert(prot > 0, @"prot must be more zero");
    }
    
    if (!self.serverSocket) {
        self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    [self.serverSocket disconnect];
    
    NSError *error = nil;
    BOOL result = [self.serverSocket acceptOnPort:prot error:&error];
    if (result && !error) {
        NSLog(@"监听%zd端口成功",prot);
        return YES;
    }else{
        NSLog(@"监听端口失败");
        return NO;
    }
}

/// 列表 / 头部 文件传输 解析替换
- (NSString *)listOrHeadStr:(NSString *)string OfString:(NSString *)ofStr{
    NSString *jsonStr = [string stringByReplacingOccurrencesOfString:ofStr withString:@""];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"end" withString:@""];
    return [jsonStr hj_replaceEmpty];
}

- (NSString *)connectedHost{
    return [self.serverSocket connectedHost];
}
- (uint16_t)connectedPort{
    return [self.serverSocket connectedPort];
}

- (NSString *)localHost{
    return [self.serverSocket localHost];
}

- (uint16_t)localPort{
    return [self.serverSocket localPort];
}

#pragma mark - GCDSocketDelegate

/// 新的客户端连接上
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    NSLog(@"%s \n localHost = %@ \n connectedHost = %@",__func__,newSocket.localHost,newSocket.connectedHost);
    if (!self.clientSocketArray) {
        self.clientSocketArray = [NSMutableArray array];
    }
    [self.clientSocketArray addObject:newSocket];
    [newSocket readDataWithTimeout:- 1 tag:0];
}

/// 客户端连接到的
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
     NSLog(@"%s",__func__);
}

/// 接收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *readStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([readStr containsString:SENDFILEINFOLIST]) { // 接受到列表
        // 解析列表头部
        NSString *jsonStr = [self listOrHeadStr:readStr OfString:SENDFILEINFOLIST];
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        _socketItemArray = [ServerSocketItem mj_objectArrayWithKeyValuesArray:array];
        if ([self.delegate respondsToSelector:@selector(serverSocketManager:fileListAccept:)]) {
            [self.delegate serverSocketManager:self fileListAccept:_socketItemArray];
        }
        NSLog(@"listjsonStr = %@",jsonStr);
        
        for (GCDAsyncSocket *clientSock in self.clientSocketArray) {
            [clientSock writeData:[FILE_LIST_SEND_END dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        }
    }else if ([readStr containsString:SENDFILEHEADINFO]){ // 接受到头部
        // 解析头部信息
        NSString *jsonStr = [self listOrHeadStr:readStr OfString:SENDFILEHEADINFO];
        NSLog(@"headjsonStr = %@",jsonStr);
        NSDictionary *dic = [jsonStr hj_jsonStringToDic];
        ServerSocketItem *item = [ServerSocketItem mj_objectWithKeyValues:dic];
        self.currentSendItem = item;
        if (item.ID < self.socketItemArray.count) {
            [self.socketItemArray replaceObjectAtIndex:item.ID withObject:item];
            if ([self.delegate respondsToSelector:@selector(serverSocketManager:fileHeadAccept:)]) {
                [self.delegate serverSocketManager:self fileHeadAccept:item];
            }
        }
        // 通知客户端已经接受完成
        for (GCDAsyncSocket *clientSock in self.clientSocketArray) {
            NSString *str = [NSString stringWithFormat:@"%@%zd\n",FILE_HEAD_SEND_END,item.ID];
            [clientSock writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        }
    }else{
    
        if (_currentSendItem && _currentSendItem.isCancel == 0) {
            _currentSendItem.acceptSize += data.length;
            _currentSendItem.beginAccept = YES;
            NSLog(@"acceptSize = %zd",_currentSendItem.acceptSize);
            if (!self.outputStream) {
                _currentSendItem.filePath = [self.dataSavePath stringByAppendingPathComponent:[_currentSendItem.fileName lastPathComponent]];
                self.outputStream = [[NSOutputStream alloc] initToFileAtPath:_currentSendItem.filePath append:YES];
                [self.outputStream open];
            }
            // 输出流 写数据
            NSInteger byt = [self.outputStream write:data.bytes maxLength:data.length];
            NSLog(@"byt = %zd",byt);
            
            if (_currentSendItem.acceptSize >= _currentSendItem.fileSize) {
                _currentSendItem.finishAccept = YES;
                [self.outputStream close];
                self.outputStream = nil;
            }
            
            if ([self.delegate respondsToSelector:@selector(serverSocketManager:fileAccepting:)]) {
                [self.delegate serverSocketManager:self fileAccepting:_currentSendItem];
            }
        }
        
    }
    
    [sock readDataWithTimeout:- 1 tag:0];
}

/// 大文件  分段读取数据
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    NSLog(@"%s",__func__);
}


///
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    NSLog(@"%s",__func__);
}

/// 断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"%s",__func__);
}

///
- (void)socketDidSecure:(GCDAsyncSocket *)sock{
    NSLog(@"%s",__func__);
}

#pragma mark - lazy
- (NSString *)dataSavePath{
    if (!_dataSavePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filePath = [@"socketData" cacheDir];
        if(![fileManager fileExistsAtPath:filePath]){
            [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _dataSavePath = filePath;
        NSLog(@"%@",filePath);
    }
    return _dataSavePath;
}

@end
