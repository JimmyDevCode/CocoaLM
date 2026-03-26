#import "CocoaLMBridge.h"

#import <llama/ggml-backend.h>
#import <llama/llama.h>

#include <mutex>
#include <string>
#include <vector>

static NSString * const CocoaLMBridgeErrorDomain = @"CocoaLM.Bridge";

static void CocoaLMLogCallback(enum ggml_log_level level, const char * text, void * user_data) {
    #pragma unused(user_data)
    if (level >= GGML_LOG_LEVEL_ERROR && text != nullptr) {
        fprintf(stderr, "[CocoaLM] %s", text);
    }
}

static void CocoaLMInitializeRuntime(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        llama_backend_init();
        ggml_backend_load_all();
        llama_log_set(CocoaLMLogCallback, nullptr);
    });
}

@implementation CocoaLMBridge {
    NSString *_modelPath;
    NSInteger _contextLength;
    dispatch_queue_t _queue;
    struct llama_model *_model;
    std::mutex _modelMutex;
}

+ (BOOL)isRuntimeAvailable {
    return YES;
}

- (instancetype)initWithModelPath:(NSString *)modelPath contextLength:(NSInteger)contextLength {
    self = [super init];
    if (self) {
        _modelPath = [modelPath copy];
        _contextLength = contextLength;
        _queue = dispatch_queue_create("com.cocoalm.runtime.bridge", DISPATCH_QUEUE_SERIAL);
        _model = nullptr;
    }
    return self;
}

- (void)dealloc {
    if (_model != nullptr) {
        llama_model_free(_model);
        _model = nullptr;
    }
}

- (void)generateWithSystemPrompt:(NSString *)systemPrompt
                      userPrompt:(NSString *)userPrompt
                       maxTokens:(NSInteger)maxTokens
                     temperature:(double)temperature
                      completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    dispatch_async(_queue, ^{
        NSError *error = nil;
        struct llama_model *model = [self ensureModelLoaded:&error];
        if (model == nullptr) {
            completion(nil, error);
            return;
        }

        NSString *formattedPrompt = [self formattedPromptWithSystemPrompt:systemPrompt
                                                               userPrompt:userPrompt
                                                                    model:model];
        if (formattedPrompt.length == 0) {
            NSError *promptError = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                                       code:2
                                                   userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to format the chat prompt."
            }];
            completion(nil, promptError);
            return;
        }

        NSString *output = [self runInferenceWithPrompt:formattedPrompt
                                                  model:model
                                              maxTokens:maxTokens
                                            temperature:temperature
                                                  error:&error];
        completion(output, error);
    });
}

- (struct llama_model *)ensureModelLoaded:(NSError * __autoreleasing *)error {
    std::lock_guard<std::mutex> lock(_modelMutex);
    if (_model != nullptr) {
        return _model;
    }

    CocoaLMInitializeRuntime();

    llama_model_params params = llama_model_default_params();
    params.n_gpu_layers = 999;
    params.use_mmap = true;
    params.use_mlock = false;

    fprintf(stderr, "[CocoaLM] Loading GGUF model from %s\n", _modelPath.fileSystemRepresentation);

    _model = llama_model_load_from_file(_modelPath.fileSystemRepresentation, params);
    if (_model == nullptr && error != nullptr) {
        *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                     code:3
                                 userInfo:@{
            NSLocalizedDescriptionKey: @"Failed to load the GGUF model file.",
            @"modelPath": _modelPath ?: @""
        }];
    }

    return _model;
}

- (NSString *)formattedPromptWithSystemPrompt:(NSString *)systemPrompt
                                   userPrompt:(NSString *)userPrompt
                                        model:(struct llama_model *)model {
    const char *templateName = llama_model_chat_template(model, nullptr);
    if (templateName == nullptr) {
        return [NSString stringWithFormat:
                @"<system>\n%@\n</system>\n<user>\n%@\n</user>\n<assistant>\n",
                systemPrompt,
                userPrompt];
    }

    std::vector<llama_chat_message> messages;
    llama_chat_message systemMessage;
    systemMessage.role = "system";
    systemMessage.content = systemPrompt.UTF8String;
    messages.push_back(systemMessage);

    llama_chat_message userMessageValue;
    userMessageValue.role = "user";
    userMessageValue.content = userPrompt.UTF8String;
    messages.push_back(userMessageValue);

    std::vector<char> buffer(2048);
    int32_t length = llama_chat_apply_template(
        templateName,
        messages.data(),
        messages.size(),
        true,
        buffer.data(),
        static_cast<int32_t>(buffer.size())
    );

    if (length < 0) {
        return @"";
    }

    if (length > static_cast<int32_t>(buffer.size())) {
        buffer.resize(length);
        length = llama_chat_apply_template(
            templateName,
            messages.data(),
            messages.size(),
            true,
            buffer.data(),
            static_cast<int32_t>(buffer.size())
        );
        if (length < 0) {
            return @"";
        }
    }

    return [[NSString alloc] initWithBytes:buffer.data()
                                    length:length
                                  encoding:NSUTF8StringEncoding] ?: @"";
}

- (NSString *)runInferenceWithPrompt:(NSString *)prompt
                               model:(struct llama_model *)model
                           maxTokens:(NSInteger)maxTokens
                         temperature:(double)temperature
                               error:(NSError * __autoreleasing *)error {
    const llama_vocab *vocab = llama_model_get_vocab(model);
    if (vocab == nullptr) {
        if (error != nullptr) {
            *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                         code:4
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"The loaded model does not expose a vocabulary."
            }];
        }
        return nil;
    }

    llama_context_params contextParams = llama_context_default_params();
    contextParams.n_ctx = MAX(512, (int32_t)_contextLength);
    contextParams.n_batch = contextParams.n_ctx;
    contextParams.n_ubatch = contextParams.n_ctx;
    contextParams.n_threads = MAX(1, (int32_t)NSProcessInfo.processInfo.activeProcessorCount - 1);
    contextParams.n_threads_batch = contextParams.n_threads;

    llama_context *context = llama_init_from_model(model, contextParams);
    if (context == nullptr) {
        if (error != nullptr) {
            *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                         code:5
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to create the llama context."
            }];
        }
        return nil;
    }

    llama_sampler *sampler = nullptr;
    NSString *response = nil;

    @try {
        const std::string promptUTF8 = prompt.UTF8String ?: "";
        int32_t tokenCount = -llama_tokenize(
            vocab,
            promptUTF8.c_str(),
            (int32_t)promptUTF8.size(),
            nullptr,
            0,
            true,
            true
        );

        if (tokenCount <= 0) {
            if (error != nullptr) {
                *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                             code:6
                                         userInfo:@{
                    NSLocalizedDescriptionKey: @"Failed to tokenize the prompt."
                }];
            }
            return nil;
        }

        if (tokenCount >= (int32_t)llama_n_ctx(context)) {
            if (error != nullptr) {
                *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                             code:7
                                         userInfo:@{
                    NSLocalizedDescriptionKey: @"The prompt exceeds the configured context length."
                }];
            }
            return nil;
        }

        std::vector<llama_token> tokens(tokenCount);
        if (llama_tokenize(
            vocab,
            promptUTF8.c_str(),
            (int32_t)promptUTF8.size(),
            tokens.data(),
            (int32_t)tokens.size(),
            true,
            true
        ) < 0) {
            if (error != nullptr) {
                *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                             code:8
                                         userInfo:@{
                    NSLocalizedDescriptionKey: @"Failed to prepare prompt tokens."
                }];
            }
            return nil;
        }

        llama_batch promptBatch = llama_batch_get_one(tokens.data(), (int32_t)tokens.size());
        if (llama_decode(context, promptBatch) != 0) {
            if (error != nullptr) {
                *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                             code:9
                                         userInfo:@{
                    NSLocalizedDescriptionKey: @"The runtime failed to decode the initial prompt."
                }];
            }
            return nil;
        }

        sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
        if (temperature <= 0.01) {
            llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
        } else {
            llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40));
            llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9f, 1));
            llama_sampler_chain_add(sampler, llama_sampler_init_temp((float)temperature));
            llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
        }

        std::string output;
        int32_t generatedCount = 0;
        int32_t usedContext = tokenCount;

        while (generatedCount < maxTokens && usedContext < (int32_t)llama_n_ctx(context)) {
            llama_token nextToken = llama_sampler_sample(sampler, context, -1);
            if (llama_vocab_is_eog(vocab, nextToken)) {
                break;
            }

            std::vector<char> pieceBuffer(256);
            int32_t pieceLength = llama_token_to_piece(
                vocab,
                nextToken,
                pieceBuffer.data(),
                (int32_t)pieceBuffer.size(),
                0,
                true
            );

            if (pieceLength < 0) {
                pieceBuffer.resize(-pieceLength);
                pieceLength = llama_token_to_piece(
                    vocab,
                    nextToken,
                    pieceBuffer.data(),
                    (int32_t)pieceBuffer.size(),
                    0,
                    true
                );
            }

            if (pieceLength > 0) {
                output.append(pieceBuffer.data(), pieceLength);
            }

            llama_batch nextBatch = llama_batch_get_one(&nextToken, 1);
            if (llama_decode(context, nextBatch) != 0) {
                if (error != nullptr) {
                    *error = [NSError errorWithDomain:CocoaLMBridgeErrorDomain
                                                 code:10
                                             userInfo:@{
                        NSLocalizedDescriptionKey: @"The runtime failed during token generation."
                    }];
                }
                return nil;
            }

            generatedCount += 1;
            usedContext += 1;
        }

        fprintf(stderr, "[CocoaLM] Generation finished successfully (%d tokens)\n", generatedCount);

        response = [[NSString alloc] initWithBytes:output.data()
                                            length:output.size()
                                          encoding:NSUTF8StringEncoding] ?: @"";
    } @finally {
        if (sampler != nullptr) {
            llama_sampler_free(sampler);
        }
        llama_free(context);
    }

    return response;
}

@end
