//
//  MSCAppDelegate.m
//  MSCDemo
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "MSCAppDelegate.h"
#import "iflyMSC/IFlyMSC.h"
#import "Definition.h"
#import <UserNotifications/UserNotifications.h>
//#import <AVFoundation/AVSpeechSynthesis.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


@implementation MSCAppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
//    <#!!!特别提醒：                                                                #>
//
//    <#  1、在集成讯飞语音SDK前请特别关注下面设置，主要包括日志文件设置、工作路径设置和appid设置。#>
//
//    <#2、在启动语音服务前必须传入正确的appid。#>
//
//    <#3、SDK运行过程中产生的音频文件和日志文件等都会保存在设置的工作路径下。#>
    
    
    //设置sdk的log等级，log保存在下面设置的工作路径中
    [IFlySetting setLogFile:LVL_ALL];
    
    //打开输出在console的log开关
    [IFlySetting showLogcat:YES];

    //设置sdk的工作路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    [IFlySetting setLogFilePath:cachePath];
    
    //创建语音配置,appid必须要传入，仅执行一次则可
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",APPID_VALUE];
    
    //所有服务启动前，需要确保执行createUtility
    [IFlySpeechUtility createUtility:initString];
    
    [self registerPushNotificationsapplication:application];
    NSError *error = NULL;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if(error) {
        // Do some error handling
    }
    [session setActive:YES error:&error];
    if (error) {
        // Do some error handling
    }
    //让app支持接受远程控制事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self initAudiopath];
    [self initSynthesizer];
    return YES;
}

#define IOS10 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
-(void)registerPushNotificationsapplication:(UIApplication *)application {
    
//    if (IOS10){
//
//        UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
//        [center setDelegate:self];
//        UNAuthorizationOptions type = UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert|UNAuthorizationOptionCarPlay;
//        [center requestAuthorizationWithOptions:type completionHandler:^(BOOL granted, NSError * _Nullable error) {
//
//            if (granted) {
//                NSLog(@"注册成功");
//
//            }else{
//                NSLog(@"注册失败");
//            }
//        }];
//    }else{
//
//        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
//        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
//        [application registerUserNotificationSettings:settings];
//    }
    
    UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    [application registerUserNotificationSettings:settings];
    
    // 注册获得device Token
    [application registerForRemoteNotifications];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [[IFlySpeechUtility getUtility] handleOpenURL:url];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskPortrait;
}



#pragma mark - APNS Delegate
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSLog(@"regisger success:%@", deviceToken);
    // 传给服务器注册deviceToken
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    
    // 处理推送消息
    NSLog(@"userinfo:%@",userInfo);
    NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
    [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Registfail%@",error);
}

//在前台
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    
    // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    completionHandler(UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert|UNAuthorizationOptionCarPlay);
    //回调
    //    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler{
    
    //处理推送过来的数据
    //    [self handlePushMessage:response.notification.request.content.userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}



// 收到推送
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo fetchCompletionHandler:(void (^ _Nonnull)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"didReceiveRemoteNotification:%@",userInfo);
    
    //回调
    completionHandler(UIBackgroundFetchResultNewData);
    _message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
//    [self uriSynthesizeBtnHandler:_message];
    [self startSynBtnHandler:_message];
}


-(void) initAudiopath {
#pragma mark - 初始化uri合成的音频存放路径和播放器
    
    //     使用-(void)synthesize:(NSString *)text toUri:(NSString*)uri接口时， uri 需设置为保存音频的完整路径
    //     若uri设为nil,则默认的音频保存在library/cache下
    NSString *prePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //uri合成路径设置
    _uriPath = [NSString stringWithFormat:@"%@/%@",prePath,@"uri.pcm"];
    //pcm播放器初始化
    _audioPlayer = [[PcmPlayer alloc] init];
}


#pragma mark - 设置合成参数
- (void)initSynthesizer{
    
    TTSConfig *instance = [TTSConfig sharedInstance];
    if (instance == nil) {
        return;
    }
    //合成服务单例
    if (_iFlySpeechSynthesizer == nil) {
        _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    }
    
    _iFlySpeechSynthesizer.delegate = self;
    
    //本地资源打包在app内
    NSString *resPath = [[NSBundle mainBundle] resourcePath];
    //本地demo本地发音人仅包含xiaoyan资源,由于auto模式为本地优先，为避免找不发音人错误，也限制为xiaoyan
    NSString *newResPath = [[NSString alloc] initWithFormat:@"%@/tts64res/common.jet;%@/tts64res/xiaoyan.jet",resPath,resPath];
    [[IFlySpeechUtility getUtility] setParameter:@"tts" forKey:[IFlyResourceUtil ENGINE_START]];
    [_iFlySpeechSynthesizer setParameter:newResPath forKey:@"tts_res_path"];
    
    //设置语速1-100
    [_iFlySpeechSynthesizer setParameter:instance.speed forKey:[IFlySpeechConstant SPEED]];
    
    //设置音量1-100
    [_iFlySpeechSynthesizer setParameter:instance.volume forKey:[IFlySpeechConstant VOLUME]];
    
    //设置音调1-100
    [_iFlySpeechSynthesizer setParameter:instance.pitch forKey:[IFlySpeechConstant PITCH]];
    
    //设置采样率
    [_iFlySpeechSynthesizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
    
    //设置发音人
    [_iFlySpeechSynthesizer setParameter:instance.vcnName forKey:[IFlySpeechConstant VOICE_NAME]];
    
    //设置文本编码格式
    [_iFlySpeechSynthesizer setParameter:@"unicode" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    
    //设置引擎类型
    [_iFlySpeechSynthesizer setParameter:instance.engineType forKey:[IFlySpeechConstant ENGINE_TYPE]];
//    NSDictionary* languageDic=@{@"Guli":@"text_uighur", //维语
//                                @"XiaoYun":@"text_vietnam",//越南语
//                                @"Abha":@"text_hindi",//印地语
//                                @"Gabriela":@"text_spanish",//西班牙语
//                                @"Allabent":@"text_russian",//俄语
//                                @"Mariane":@"text_french"};//法语
//
//    NSString* textNameKey=[languageDic valueForKey:instance.vcnName];
//    NSString* textSample=nil;
//    if(textNameKey && [textNameKey length]>0){
//        textSample=NSLocalizedStringFromTable(textNameKey, @"tts/tts", nil);
//    }else{
//        textSample=NSLocalizedStringFromTable(@"text_chinese", @"tts/tts", nil);
//    }
//    [_textView setText:textSample];
}


/**
 合成结束（完成）回调
 
 对uri合成添加播放的功能
 ****/
- (void)onCompleted:(IFlySpeechError *) error{
    
    NSLog(@"%s,error=%d",__func__,error.errorCode);
    if (error.errorCode != 0) {
        return;
    }
    _state = NotStart;
    if (_synType == UriType) {//Uri合成类型
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:_uriPath]) {
//            [self playUriAudio];//播放合成的音频
            // 本地音频文件播放
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"Cosmic" ofType:@"m4r"];
            //组装并播放音效
//            SystemSoundID soundID;
//            NSURL *filePath = [NSURL fileURLWithPath:_uriPath isDirectory:NO];
//            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
//            AudioServicesPlaySystemSound(soundID);
        }
    }
}




/**
 开始uri合成
 ****/
- (void) uriSynthesizeBtnHandler:(NSString*)message {
    
    if ([message isEqualToString:@""]) {
        return;
    }
    
    if (_audioPlayer != nil && _audioPlayer.isPlaying == YES) {
        [_audioPlayer stop];
    }
    _synType = UriType;
    [NSThread sleepForTimeInterval:0.05];
//    self.isCanceled = NO;
    
    _iFlySpeechSynthesizer.delegate = self;
    [_iFlySpeechSynthesizer synthesize:message toUri:_uriPath];
    if (_iFlySpeechSynthesizer.isSpeaking) {
        _state = Playing;
    }
}


- (void)startSynBtnHandler:(NSString*)message {
    
    if ([message isEqualToString:@""]) {
        return;
    }
    
    if (_audioPlayer != nil && _audioPlayer.isPlaying == YES) {
        [_audioPlayer stop];
    }
    _synType = NomalType;
    [NSThread sleepForTimeInterval:0.05];
//    self.isCanceled = NO;
    
    _iFlySpeechSynthesizer.delegate = self;
    [_iFlySpeechSynthesizer startSpeaking:message];
    if (_iFlySpeechSynthesizer.isSpeaking) {
        _state = Playing;
    }
}


@end
