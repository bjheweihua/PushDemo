# PushDemo
仿微信语音提醒-在后台或者杀死进程收到推送通知播放语音


收到推送消息，进行语音播报，使用系统的TTS:AVSpeechSynthesizer, 切到后台，或者杀死APP，会被系统打断，导致没有声音：
AVSpeechSynthesizer Audio interruption notification: {
    AVAudioSessionInterruptionTypeKey = 1;
    AVAudioSessionInterruptionWasSuspendedKey = 1; 
}
使用下边的方法也无法解决， so使用科大讯飞的SDK--TTS，能解决这个问题。

https://stackoverflow.com/questions/45121294/avspeechsynthesizer-stopped-after-receive-audio-interruption-notification
I made an app which can speech the word (TTS) in the background.

But the player will stoped after I receive this interruption notification.

AVSpeechSynthesizer Audio interruption notification: {
    AVAudioSessionInterruptionTypeKey = 1;
    AVAudioSessionInterruptionWasSuspendedKey = 1; 
}
After I got the solution in here which shows in below, adding the notification and implement following code.

However, I found that AVAudioSessionInterruptionTypeEnded will never appear. Even I put the start function in AVAudioSessionInterruptionTypeBegan still doesn't work.

My question is, how to keep my AVSpeechSynthesizer work after receive the interrupt notification?

[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:aSession];

- (void)handleAudioSessionInterruption:(NSNotification*)notification {

    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];

    switch (interruptionType.unsignedIntegerValue) {
        case AVAudioSessionInterruptionTypeBegan:{
            [self interruptHandler];
            [self playObject];
        } break;
        case AVAudioSessionInterruptionTypeEnded:{
            if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume) {
                // Here you should continue playback.
                [self playObject];
            }
        } break;
        default:
            break;
    }
}

- (void) interruptHandler {
    @synchronized (self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVAudioSession *aSession = [AVAudioSession sharedInstance];
            [aSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
            [aSession setMode:AVAudioSessionModeDefault error:&error];
            [aSession setActive: YES error: &error];
        });
    }
}
