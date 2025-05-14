/* Disabling the preferences settings for now and use the same duration for lockscreen

#define prefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(),@"se.nosskirneh.autodismisssiri.plist"]

static BOOL enabled;
static long long duration;
static long long lockscreenDuration;

static void reloadPrefs() {
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:prefPath];
    enabled = defaults[@"enabled"] ? [defaults[@"enabled"] boolValue] : YES;
    duration = defaults[@"duration"] ? [defaults[@"duration"] integerValue] : 5;
    lockscreenDuration = defaults[@"lockscreenDuration"] ? [defaults[@"lockscreenDuration"] integerValue] : 5;
}

void updateSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo) {
    reloadPrefs();
}


@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isUILocked;
@end

*/

@interface ACSpringBoardPluginController : NSObject
- (void)_requestDismissal;
- (void)callHomeAssistantWebhook;
@end

%group Assistant
%hook ACSpringBoardPluginController

- (void)siriViewController:(id)arg1 siriIdleAndQuietStatusDidChange:(BOOL)idle {
    %orig;

/* enabled by default
    if (!enabled)
        return;
*/

    static NSTimer *timer;
    if (idle) {
        /* no lockscreen duration, use the same duration always
        SBLockScreenManager *lockscreenManager = [%c(SBLockScreenManager) sharedInstance];
        float d = lockscreenManager.isUILocked ? lockscreenDuration : duration;
        if (d == 0)
            return;
        */

        float d = 3; /* 3 seconds as duration */
        timer = [NSTimer scheduledTimerWithTimeInterval:d
                                                 target:self
                                               selector:@selector(dismiss:)
                                               userInfo:nil
                                                repeats:NO];
    }
    else if (timer)
        [timer invalidate];

}

%new
- (void)dismiss:(NSTimer *)timer {
    [timer invalidate];
    [self _requestDismissal];

    // Call Home Assistant webhook
    [self callHomeAssistantWebhook];
}

%new
- (void)callHomeAssistantWebhook {
    NSString *webhookUrl = @"http://your-webhook"; // TODO: change this

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:webhookUrl]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *payload = @{
        @"event": @"siri_dismissed",
        @"device": [[UIDevice currentDevice] name]
    };

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];

    if (!error) {
        [request setHTTPBody:jsonData];

        // Use NSURLConnection for iOS 8.4 compatibility (NSURLSession is better for newer iOS)
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   if (connectionError) {
                                       NSLog(@"AutoDismissSiri: Error calling Home Assistant webhook: %@", connectionError);
                                   } else {
                                       NSLog(@"AutoDismissSiri: Successfully called Home Assistant webhook");
                                   }
                               }];
    } else {
        NSLog(@"AutoDismissSiri: Error creating JSON payload: %@", error);
    }
}

%end
%end

%hook SBAssistantController
- (void)_loadPlugin {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        %init(Assistant);
    });
}
%end


%ctor {
    /* no preferences
    reloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &updateSettings, CFSTR("se.nosskirneh.autodismisssiri/preferencesChanged"), NULL, 0);
    */

    %init;
}
