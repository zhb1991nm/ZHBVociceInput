//
//  CustomBDVController.h
//  BDVRClientSample
//
//  Created by icode on 15/4/30.
//  Copyright (c) 2015年 Baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDVoiceRecognitionClient.h"

@class CustomBDVController;

@protocol CustomBDVControllerDelegate <NSObject>

-(void)CustomBDVController:(CustomBDVController *)controller resultString:(NSString *)voiceString;

@end

@interface CustomBDVController : UIViewController<MVoiceRecognitionClientDelegate>{
    NSTimer *voiceLevelMeterTimer; // 获取语音音量界别定时器
}

@property (nonatomic,weak) id <CustomBDVControllerDelegate>delegate;

-(void)autoStartRecord;

-(void)hideCancel;

@end

#pragma mark - <CLASS> - UIImageGrayscale

@interface UIImage (Grayscale)

- (UIImage *) partialImageWithPercentage:(float)percentage
                                vertical:(BOOL)vertical
                           grayscaleRest:(BOOL)grayscaleRest;

@end

#pragma mark - <CLASS> - LCPorgressImageView

@interface LCPorgressImageView : UIImageView {
    
    UIImage * _originalImage;
    
    BOOL      _internalUpdating;
    
}

@property (nonatomic) float progress;
@property (nonatomic) BOOL  hasGrayscaleBackground;

@property (nonatomic, getter = isVerticalProgress) BOOL verticalProgress;

@end