//
//  ZPHomeCell.m
//  ZPW
//
//  Created by 张海军 on 2017/11/2.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ZPHomeCell.h"

#import <UIImageView+WebCache.h>

static NSString *NIBNAME = @"ZPHomeCell";

@implementation ZPHomeCell

+ (instancetype)homeCell:(UITableView *)tableView{
    ZPHomeCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class])];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:NIBNAME owner:nil options:nil][0];
        cell.separatorInset = UIEdgeInsetsZero;
        if ([cell respondsToSelector:@selector(layoutMargins)]) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }
    return cell;
}

- (void)setDataItem:(ServerSocketItem *)dataItem{
    _dataItem = dataItem;

    if (dataItem.fileType == 2) {
        self.videoTypeImage.hidden = NO;
    }else{
        self.videoTypeImage.hidden = YES;
    }
    
    if (!dataItem.isCancel){
        self.cancleButton.hidden = YES;
    }else{
        self.cancleButton.hidden = NO;
        self.cancleButton.enabled = NO;
    }
    
    self.fileNameLable.text = dataItem.fileName;
    self.fileTypeLabel.text = dataItem.typeStr;
    self.fileSizeLabel.text = [NSString stringWithFormat:@"%0.2fM",(dataItem.fileSize * 1.0 / 1024.0 / 1024.0)];
    if (dataItem.beginAccept) {
        self.upProgressLabel.hidden = NO;
        self.upProgressLabel.text = [NSString stringWithFormat:@"%.0f%%",(1.0 * dataItem.acceptSize / dataItem.fileSize) * 100];
    }else{
        self.upProgressLabel.text = nil;
        self.upProgressLabel.hidden = YES;
    }
    if (dataItem.finishAccept) {
        self.upProgressLabel.hidden = NO;
        self.upProgressLabel.text = @"100%";
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)cancleButtonDidClick:(UIButton *)sender {
    
}

@end
