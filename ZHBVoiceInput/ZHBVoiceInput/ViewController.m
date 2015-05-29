//
//  ViewController.m
//  ZHBVoiceInput
//
//  Created by icode on 15/5/29.
//  Copyright (c) 2015年 sinitek. All rights reserved.
//

#import "ViewController.h"
#import "CustomBDVController.h"

@interface ViewController ()<CustomBDVControllerDelegate>

@property (nonatomic,strong) CustomBDVController *baiduVoiceController;

@end

@implementation ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField.enabled = NO;
    [self addChildViewController:self.baiduVoiceController];
    [self.inputView addSubview:self.baiduVoiceController.view];
    self.baiduVoiceController.view.frame = self.inputView.bounds;
    self.baiduVoiceController.view.backgroundColor = [UIColor clearColor];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CustomBDVControllerDelegate

-(void)CustomBDVController:(CustomBDVController *)controller resultString:(NSString *)voiceString{
    NSString *text = self.textField.text;
    text = [text stringByAppendingString:voiceString];
    self.textField.text = text;
}

#pragma mark - event response

- (IBAction)clearButtonOnClick:(UIButton *)sender {
    self.textField.text = @"";
}

- (IBAction)sendButtonOnClick:(UIButton *)sender {
    
}

#pragma mark - getter & setter
-(CustomBDVController *)baiduVoiceController{
    if (!_baiduVoiceController) {
        _baiduVoiceController = [[CustomBDVController alloc] init];
        _baiduVoiceController.delegate = self;
    }
    return _baiduVoiceController;
}

@end
