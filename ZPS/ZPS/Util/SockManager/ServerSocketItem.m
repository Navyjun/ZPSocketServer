//
//  ServerSocketItem.m
//  ZPS
//
//  Created by 张海军 on 2017/11/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ServerSocketItem.h"

@implementation ServerSocketItem
+ (NSDictionary *)mj_replacedKeyFromPropertyName
{
    return @{@"ID" : @"id"};
}

- (NSString *)typeStr{
    if (self.fileType == 1) {
        return @"图片";
    }else if (self.fileType == 2){
        return @"视频";
    }else if (self.fileType == 3){
        return @"音频";
    }else if (self.fileType == 4){
        return @"文本";
    }else{
        return @"";
    }
}

//- (NSString *)filePath{
//    if (self.fileType == 1) {
//        return [NSString stringWithFormat:@"%@%@",FILETYPEIMAGE,_filePath];
//    }else if (self.fileType == 2){
//        return [NSString stringWithFormat:@"%@%@",FILETYPEVIDEO,_filePath];
//    }else if (self.fileType == 3){
//        return [NSString stringWithFormat:@"%@%@",FILETYPEVIDEO,_filePath];
//    }else if (self.fileType == 4){
//        return [NSString stringWithFormat:@"%@%@",FILETYPETEXT,_filePath];
//    }else{
//        return _filePath;
//    }
//}
@end
