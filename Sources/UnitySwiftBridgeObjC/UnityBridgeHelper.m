//
//  UnityBridgeHelper.m
//  UnitySwiftBridge
//
//  Objective-C helper for calling Unity methods
//

#import <Foundation/Foundation.h>
#import "UnityBridgeHelper.h"

@implementation UnityBridgeHelper

+ (void)sendMessageToUnity:(id)unityFramework
                  selector:(SEL)selector
                objectName:(NSString *)objectName
                    method:(NSString *)method
                   message:(NSString *)message {

    // Use NSInvocation for safe multi-argument method call
    NSMethodSignature *signature = [unityFramework methodSignatureForSelector:selector];
    if (!signature) {
        NSLog(@"[UnityBridgeHelper] Error: No method signature for selector");
        return;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:unityFramework];
    [invocation setSelector:selector];
    [invocation setArgument:&objectName atIndex:2];
    [invocation setArgument:&method atIndex:3];
    [invocation setArgument:&message atIndex:4];
    [invocation invoke];
}

@end
