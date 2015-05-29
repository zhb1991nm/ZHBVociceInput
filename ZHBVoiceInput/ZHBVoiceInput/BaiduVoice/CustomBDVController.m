//
//  CustomBDVController.m
//  BDVRClientSample
//
//  Created by icode on 15/4/30.
//  Copyright (c) 2015年 Baidu. All rights reserved.
//

#import "CustomBDVController.h"
#import <QuartzCore/QuartzCore.h>
#
#import "BDVoiceRecognitionClient.h"
#import "Toast+UIView.h"

#define _IMAGE_MIC_TALKING [UIImage imageNamed:@"mic_talk"]
#define _IMAGE_MIC_WAVE [UIImage imageNamed:@"wave2"]

#warning 请修改为您在百度开发者平台申请的API_KEY和SECRET_KEY
#define API_KEY @"s15fmWSwXfgEnFwpZmXdjrsa" // 请修改为您在百度开发者平台申请的API_KEY
#define SECRET_KEY @"xAPXvfca7Os7P7dsR6ArGei8t6oLLHkT" // 请修改您在百度开发者平台申请的SECRET_KEY

#define VOICE_LEVEL_INTERVAL 0.1 // 音量监听频率为1秒中10次


typedef NS_ENUM(NSInteger, WorkStatus) {
    WorkStatusNotStart = 0,
    WorkStatusWaitForRecord,
    WorkStatusRecording,
    WorkStatusHandling
};

@interface CustomBDVController(){
    UIImageView         * _talkingImageView;
    LCPorgressImageView * _dynamicProgress;
    UIButton *talkButton;
    WorkStatus workStatus;
}

@end

@implementation CustomBDVController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initSubViews];
    [self initBDVoiceRecognitionClient];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateSubViewFrames];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)initBDVoiceRecognitionClient{
    
    // 设置开发者信息
    [[BDVoiceRecognitionClient sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    // 设置语音识别模式，默认是输入模式
    [[BDVoiceRecognitionClient sharedInstance] setPropertyList:@[[NSNumber numberWithInteger:EVoiceRecognitionPropertyInput]]];
     // 设置城市ID，当识别属性包含EVoiceRecognitionPropertyMap时有效
     [[BDVoiceRecognitionClient sharedInstance] setCityID: 1];
     // 设置是否需要语义理解，只在搜索模式有效
     [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:NO];
     // 是否打开语音音量监听功能，可选
     BOOL res = [[BDVoiceRecognitionClient sharedInstance] listenCurrentDBLevelMeter];
     if (res == NO)  // 如果监听失败
     {
         NSLog(@"语音监听打开失败");
     }
     // 设置播放开始说话提示音开关，可选
     [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecStart isPlay:NO];
     // 设置播放结束说话提示音开关，可选
     [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecEnd isPlay:NO];
}

-(void)initSubViews{
    
    _talkingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 45)];
    _talkingImageView.image = _IMAGE_MIC_TALKING;
    [self.view addSubview:_talkingImageView];
    
    _dynamicProgress = [[LCPorgressImageView alloc] initWithFrame:CGRectMake(0, 0, 18, 35)];
    _dynamicProgress.image = _IMAGE_MIC_WAVE;
    [self.view addSubview:_dynamicProgress];
    
    /* set */
    _dynamicProgress.progress = 0;
    _dynamicProgress.hasGrayscaleBackground = NO;
    _dynamicProgress.verticalProgress = YES;
    
    
    
    talkButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
    talkButton.backgroundColor = [UIColor clearColor];
    talkButton.layer.borderWidth = 0.5f;
    talkButton.layer.cornerRadius = 10.0f;
    talkButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [talkButton addTarget:self action:@selector(recordButttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:talkButton];
}

-(void)updateSubViewFrames{
    _talkingImageView.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, CGRectGetHeight(self.view.frame)/2);
    _dynamicProgress.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, CGRectGetHeight(self.view.frame)/2 - 5);
    talkButton.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, CGRectGetHeight(self.view.frame)/2);
}

-(void)startWaitingAnimation{
    _dynamicProgress.progress = 1;
    [_dynamicProgress.layer addAnimation:[self opacityForever_Animation:0.5] forKey:@"twinkle"];
}

-(void)stopWaitingAnimation{
    [_dynamicProgress.layer removeAnimationForKey:@"twinkle"];
    _dynamicProgress.progress = 0;
}

-(CABasicAnimation *)opacityForever_Animation:(float)time
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];//必须写opacity才行。
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];///没有的话是均匀的动画。
    return animation;
}

-(void)autoStartRecord{
    if (talkButton) {
        [talkButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)hideCancel{
    if (workStatus != WorkStatusNotStart) {
        [self cancel:talkButton];
    }
}

#pragma mark - button action methods
-(void)recordButttonClicked:(UIButton *)sender{
    switch (workStatus) {
        case WorkStatusNotStart:
            [self startRecord:sender];
            break;
        case WorkStatusWaitForRecord:
            [self cancel:sender];
            break;
        case WorkStatusRecording:
            [self finishRecord:sender];
            break;
        case WorkStatusHandling:
            [self cancel:sender];
            break;
            
        default:
            break;
    }
}

- (void)startRecord:(UIButton *)sender{
    int startStatus = -1;
    [self startWaitingAnimation];
    startStatus = [[BDVoiceRecognitionClient sharedInstance] startVoiceRecognition:self];
    if (startStatus != EVoiceRecognitionStartWorking) // 创建失败则报告错误
    {
        NSString *statusString = [NSString stringWithFormat:@"%d",startStatus];
        [self performSelector:@selector(firstStartError:) withObject:statusString afterDelay:0.3];  // 延迟0.3秒，以便能在出错时正常删除view
        return;
    }
    workStatus = WorkStatusWaitForRecord;
}

- (void)finishRecord:(UIButton *)sender
{
    [self startWaitingAnimation];
    [[BDVoiceRecognitionClient sharedInstance] speakFinish];
}

- (void)cancel:(UIButton *)sender
{
    [[BDVoiceRecognitionClient sharedInstance] stopVoiceRecognition];
    workStatus = WorkStatusNotStart;
}

#pragma mark - MVoiceRecognitionClientDelegate

- (void)VoiceRecognitionClientErrorStatus:(int) aStatus subStatus:(int)aSubStatus
{
    // 为了更加具体的显示错误信息，此处没有使用aStatus参数
    [self createErrorViewWithErrorType:aSubStatus];
    [self stopWaitingAnimation];
    workStatus = WorkStatusNotStart;
}

- (void)VoiceRecognitionClientWorkStatus:(int)aStatus obj:(id)aObj
{
    switch (aStatus)
    {
        case EVoiceRecognitionClientWorkStatusFlushData: // 连续上屏中间结果
        {
            NSString *text = [aObj objectAtIndex:0];
            
            if ([text length] > 0)
            {
                NSLog(@"%@",text);
            }
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: // 识别正常完成并获得结果
        {
            [self createRunLogWithStatus:aStatus];
            
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
            {

            }
            else
            {
                NSMutableArray *audioResultData = (NSMutableArray *)aObj;
                NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
                for (NSArray *result in audioResultData)
                {
                    NSDictionary *dic = [result objectAtIndex:0];
                    if ([dic allKeys].count > 0) {
                        NSString *candidateWord = [[dic allKeys] objectAtIndex:0];
                        [tmpString appendString:candidateWord];
                    }
                }
                
                NSLog(@"%@",tmpString);
                if (_delegate && [_delegate respondsToSelector:@selector(CustomBDVController:resultString:)]) {
                    [_delegate CustomBDVController:self resultString:tmpString];
                }
            }
            
            [self stopWaitingAnimation];
            workStatus = WorkStatusNotStart;
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData:
        {
            // 此状态只有在输入模式下使用
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: // 用户说话完成，等待服务器返回识别结果
        {
            workStatus = WorkStatusHandling;
            [self createRunLogWithStatus:aStatus];
            [self freeVoiceLevelMeterTimerTimer];
            
            [self startWaitingAnimation];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel:
        {
            [self freeVoiceLevelMeterTimerTimer];
            
            [self createRunLogWithStatus:aStatus];
            [self stopWaitingAnimation];
            workStatus = WorkStatusNotStart;
            break;
        }
        case EVoiceRecognitionClientWorkStatusStartWorkIng: // 识别库开始识别工作，用户可以说话
        {
            [self stopWaitingAnimation];
            [self startVoiceLevelMeterTimer];
            [self createRunLogWithStatus:aStatus];
            workStatus = WorkStatusRecording;
            break;
        }
        case EVoiceRecognitionClientWorkStatusNone:
        case EVoiceRecognitionClientWorkPlayStartTone:
        case EVoiceRecognitionClientWorkPlayStartToneFinish:
        case EVoiceRecognitionClientWorkStatusStart:
        case EVoiceRecognitionClientWorkPlayEndToneFinish:
        case EVoiceRecognitionClientWorkPlayEndTone:
        {
            [self createRunLogWithStatus:aStatus];
            break;
        }
        case EVoiceRecognitionClientWorkStatusNewRecordData:
        {
            workStatus = WorkStatusRecording;
            break;
        }
        default:
        {
            [self createRunLogWithStatus:aStatus];
            [self freeVoiceLevelMeterTimerTimer];
            
            break;
        }
    }
}

- (void)VoiceRecognitionClientNetWorkStatus:(int) aStatus
{
    switch (aStatus)
    {
        case EVoiceRecognitionClientNetWorkStatusStart:
        {
            [self createRunLogWithStatus:aStatus];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
        case EVoiceRecognitionClientNetWorkStatusEnd:
        {
            [self createRunLogWithStatus:aStatus];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;   
        }          
    }
}

#pragma mark - voice search error result

- (void)firstStartError:(NSString *)statusString
{
    [self stopWaitingAnimation];
    [self createErrorViewWithErrorType:[statusString intValue]];
}

- (void)createErrorViewWithErrorType:(int)aStatus
{
    NSString *errorMsg = @"";
    
    switch (aStatus)
    {
        case EVoiceRecognitionClientErrorStatusIntrerruption:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonInterruptRecord", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusChangeNotAvailable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonChangeNotAvailable", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusUnKnow:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonStatusError", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusNoSpeech:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoSpeech", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusShort:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoShort", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusException:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonException", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusError:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNetWorkError", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoNetWork", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusTimeOut:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNetWorkTimeOut", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusParseError:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonParseError", nil);
            break;
        }
        case EVoiceRecognitionStartWorkNoAPIKEY:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchNoAPIKEY", nil);
            break;
        }
        case EVoiceRecognitionStartWorkGetAccessTokenFailed:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchGetTokenFailed", nil);
            break;
        }
        case EVoiceRecognitionStartWorkDelegateInvaild:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoDelegateMethods", nil);
            break;
        }
        case EVoiceRecognitionStartWorkNetUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoNetWork", nil);
            break;
        }
        case EVoiceRecognitionStartWorkRecorderUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonCantRecord", nil);
            break;
        }
        case EVoiceRecognitionStartWorkNOMicrophonePermission:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchNOMicrophonePermission", nil);
            break;
        }
            //服务器返回错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerNoFindResult:     //没有找到匹配结果
        case EVoiceRecognitionClientErrorNetWorkStatusServerSpeechQualityProblem:    //声音过小
            
        case EVoiceRecognitionClientErrorNetWorkStatusServerParamError:       //协议参数错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerRecognError:      //识别过程出错
        case EVoiceRecognitionClientErrorNetWorkStatusServerAppNameUnknownError: //appName验证错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerUnknownError:      //未知错误
        {
            errorMsg = [NSString stringWithFormat:@"%@-%d",NSLocalizedString(@"StringVoiceRecognitonServerError", nil),aStatus] ;
            break;
        }
        default:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonDefaultError", nil);
            break;
        }
    }
    
    [self.view makeToast:errorMsg duration:1.0 position:@"top"];
}

#pragma mark - voice search log

- (void)createRunLogWithStatus:(int)aStatus
{
    NSString *statusMsg = nil;
    switch (aStatus)
    {
        case EVoiceRecognitionClientWorkStatusNone: //空闲
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNone", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayStartTone:  //播放开始提示音
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayStartTone", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayStartToneFinish: //播放开始提示音完成
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayStartToneFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusStartWorkIng: //识别工作开始，开始采集及处理数据
        {
            statusMsg = NSLocalizedString(@"StringLogStatusStartWorkIng", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: //检测到用户开始说话
        {
            statusMsg = NSLocalizedString(@"StringLogStatusStart", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayEndTone: //播放结束提示音
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayEndTone", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayEndToneFinish: //播放结束提示音完成
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayEndToneFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData: //语音识别功能完成，服务器返回正确结果
        {
            statusMsg = NSLocalizedString(@"StringLogStatusSentenceFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: //语音识别功能完成，服务器返回正确结果
        {
            statusMsg = NSLocalizedString(@"StringLogStatusFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: //本地声音采集结束结束，等待识别结果返回并结束录音
        {
            statusMsg = NSLocalizedString(@"StringLogStatusEnd", nil);
            break;
        }
        case EVoiceRecognitionClientNetWorkStatusStart: //网络开始工作
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusStart", nil);
            break;
        }
        case EVoiceRecognitionClientNetWorkStatusEnd:  //网络工作完成
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusEnd", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel:  // 用户取消
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusCancel", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: // 出现错误
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusErorr", nil);
            break;
        }
        default:
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusDefaultErorr", nil);
            break;
        }
    }
    
    if (statusMsg)
    {
        NSLog(@"%@",statusMsg);
    }
}

#pragma mark - VoiceLevelMeterTimer methods

- (void)startVoiceLevelMeterTimer
{
    [self freeVoiceLevelMeterTimerTimer];
    
    NSDate *tmpDate = [[NSDate alloc] initWithTimeIntervalSinceNow:VOICE_LEVEL_INTERVAL];
    NSTimer *tmpTimer = [[NSTimer alloc] initWithFireDate:tmpDate interval:VOICE_LEVEL_INTERVAL target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    voiceLevelMeterTimer = tmpTimer;
    [[NSRunLoop currentRunLoop] addTimer:voiceLevelMeterTimer forMode:NSDefaultRunLoopMode];
}

- (void)freeVoiceLevelMeterTimerTimer
{
    if(voiceLevelMeterTimer)
    {
        if([voiceLevelMeterTimer isValid])
            [voiceLevelMeterTimer invalidate];
        voiceLevelMeterTimer = nil;
    }
}

- (void)timerFired:(id)sender
{
    // 获取语音音量级别
    int voiceLevel = [[BDVoiceRecognitionClient sharedInstance] getCurrentDBLevelMeter];
    _dynamicProgress.progress = (voiceLevel / 100.00) > 1 ?  1 : (voiceLevel / 100.00);
    NSString *statusMsg = [NSLocalizedString(@"StringLogVoiceLevel", nil) stringByAppendingFormat:@": %d", voiceLevel];
    NSLog(@"%@",statusMsg);
}









#pragma mark - Custom Accessor

-(void) setProgress:(float)progress{
    
    if (_dynamicProgress){
        
        _dynamicProgress.progress = progress;
    }
    
}

-(float) progress{
    
    if (_dynamicProgress) return _dynamicProgress.progress;
    
    return 0.f;
    
}

-(void)didReceiveMemoryWarning
{
    [self cancel:nil];
    [self.view makeToast:@"内存警告，停止本次识别" duration:1.0 position:@"center"];
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    self.delegate = nil;
}

@end



@implementation UIImage (Grayscale)

//http://stackoverflow.com/questions/1298867/convert-image-to-grayscale
- (UIImage *) partialImageWithPercentage:(float)percentage vertical:(BOOL)vertical grayscaleRest:(BOOL)grayscaleRest {
    const int ALPHA = 0;
    const int RED = 1;
    const int GREEN = 2;
    const int BLUE = 3;
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, self.size.width * self.scale, self.size.height * self.scale);
    
    int width = imageRect.size.width;
    int height = imageRect.size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [self CGImage]);
    
    int x_origin = vertical ? 0 : width * percentage;
    int y_to = vertical ? height * (1.f -percentage) : height;
    
    for(int y = 0; y < y_to; y++) {
        for(int x = x_origin; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            if (grayscaleRest) {
                // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
                uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
                
                // set the pixels to gray
                rgbaPixel[RED] = gray;
                rgbaPixel[GREEN] = gray;
                rgbaPixel[BLUE] = gray;
            }
            else {
                rgbaPixel[ALPHA] = 0;
                rgbaPixel[RED] = 0;
                rgbaPixel[GREEN] = 0;
                rgbaPixel[BLUE] = 0;
            }
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image
                                                 scale:self.scale
                                           orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}

@end

@interface LCPorgressImageView ()

@property(nonatomic,retain) UIImage * originalImage;

- (void)commonInit;
- (void)updateDrawing;

@end

@implementation LCPorgressImageView

@synthesize progress               = _progress;
@synthesize hasGrayscaleBackground = _hasGrayscaleBackground;
@synthesize verticalProgress       = _verticalProgress;

- (void)dealloc
{
}

- (id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self commonInit];
    }
    return self;
    
}

- (void)commonInit{
    
    _progress = 0.f;
    _hasGrayscaleBackground = YES;
    _verticalProgress = YES;
    _originalImage = self.image;
    
}

#pragma mark - Custom Accessor

- (void)setImage:(UIImage *)image{
    
    [super setImage:image];
    
    if (!_internalUpdating) {
        self.originalImage = image;
        [self updateDrawing];
    }
    
    _internalUpdating = NO;
}

- (void)setProgress:(float)progress{
    
    _progress = MIN(MAX(0.f, progress), 1.f);
    [self updateDrawing];
    
}

- (void)setHasGrayscaleBackground:(BOOL)hasGrayscaleBackground{
    
    _hasGrayscaleBackground = hasGrayscaleBackground;
    [self updateDrawing];
    
}

- (void)setVerticalProgress:(BOOL)verticalProgress{
    
    _verticalProgress = verticalProgress;
    [self updateDrawing];
    
}

#pragma mark - drawing

- (void)updateDrawing{
    
    _internalUpdating = YES;
    self.image = [_originalImage partialImageWithPercentage:_progress vertical:_verticalProgress grayscaleRest:_hasGrayscaleBackground];
    
}

@end