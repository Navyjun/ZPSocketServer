//
//  ImageViewController.m
//  ZPS
//
//  Created by 张海军 on 2017/11/10.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController ()
///
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation ImageViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.imageView];
    self.imageView.image = [UIImage imageWithContentsOfFile:_imgPath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)setImgPath:(NSString *)imgPath{
    _imgPath = imgPath;
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
