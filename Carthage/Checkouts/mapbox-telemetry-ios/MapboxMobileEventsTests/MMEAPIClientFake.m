#import "MMEAPIClientFake.h"
#import "MMEEvent.h"

@implementation MMEAPIClientFake

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self store:_cmd args:@[events, completionHandler]];
    self.callingCompletionHandler = completionHandler;
}

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self store:_cmd args:@[event, completionHandler]];    
    self.callingCompletionHandler = completionHandler;
}

- (void)completePostingEventsWithError:(NSError * _Nullable)error {
    if (self.callingCompletionHandler) {
        self.callingCompletionHandler(error);
    }
}

@end
