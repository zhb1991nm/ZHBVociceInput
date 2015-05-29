//
//  ViewController.h
//  ZHBVoiceInput
//
//  Created by icode on 15/5/29.
//  Copyright (c) 2015年 sinitek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UIView *inputView;

- (IBAction)clearButtonOnClick:(UIButton *)sender;

- (IBAction)sendButtonOnClick:(UIButton *)sender;

@end

