#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C++ bridge that hides llama.cpp details from the public Swift API.
@interface CocoaLMBridge : NSObject

/// Returns whether the packaged runtime is available to the current process.
+ (BOOL)isRuntimeAvailable;

/// Creates a bridge instance for a specific GGUF model path and context size.
- (instancetype)initWithModelPath:(NSString *)modelPath
                    contextLength:(NSInteger)contextLength NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Generates text from a system prompt and user prompt.
- (void)generateWithSystemPrompt:(NSString *)systemPrompt
                      userPrompt:(NSString *)userPrompt
                       maxTokens:(NSInteger)maxTokens
                     temperature:(double)temperature
                      completion:(void (^)(NSString * _Nullable output, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
