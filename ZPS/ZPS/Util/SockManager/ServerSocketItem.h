//
//  ServerSocketItem.h
//  ZPS
//
//  Created by 张海军 on 2017/11/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>
/*
 {
 "fileType" : 1,
 "fileName" : "IMG_2352.PNG",
 "id" : 0,
 "isCancel" : 0,
 "fileSize" : 1687105
 }
 */
@interface ServerSocketItem : NSObject
/// 文件类型 1:图片 2:视频 3:音频 4:文字
@property (nonatomic, assign) NSInteger fileType;
/// 当前文件在列表中的位置
@property (nonatomic, assign) NSInteger ID;
/// 当前文件是否已取消传输 0:为取消  1:已取消
@property (nonatomic, assign) NSInteger isCancel;
/// 当前文件总大小
@property (nonatomic, assign) NSInteger fileSize;
/// 文件名称
@property (nonatomic, copy) NSString *fileName;
/***** 自增属性 ******/
/// 当前文件保存在本地的路径
@property (nonatomic, copy) NSString *filePath;
/// 已接受的文件大小
@property (nonatomic, assign) NSInteger acceptSize;
/// 文件类型
@property (nonatomic, copy) NSString *typeStr;
/// 开始接受
@property (nonatomic, assign) BOOL beginAccept;
/// 接受完成
@property (nonatomic, assign) BOOL finishAccept;
@end
