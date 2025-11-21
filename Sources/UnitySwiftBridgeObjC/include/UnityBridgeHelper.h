//
//  UnityBridgeHelper.h
//  UnitySwiftBridge
//
//  Objective-C helper for calling Unity methods
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnityBridgeHelper : NSObject

+ (void)sendMessageToUnity:(id)unityFramework
                  selector:(SEL)selector
                objectName:(NSString *)objectName
                    method:(NSString *)method
                   message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
