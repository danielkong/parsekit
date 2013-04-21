//
//  PKSParser.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import <Foundation/Foundation.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKTokenizer.h>

@class PKToken;
@class PKSTokenAssembly;

typedef id   (^PKSActionBlock)   (void);
typedef void (^PKSSpeculateBlock)(void);
typedef BOOL (^PKSPredicateBlock)(void);

enum {
    TOKEN_KIND_BUILTIN_EOF = -1,
    TOKEN_KIND_BUILTIN_INVALID = 0,
    TOKEN_KIND_BUILTIN_NUMBER = 1,
    TOKEN_KIND_BUILTIN_QUOTEDSTRING = 2,
    TOKEN_KIND_BUILTIN_SYMBOL = 3,
    TOKEN_KIND_BUILTIN_WORD = 4,
    TOKEN_KIND_BUILTIN_LOWERCASEWORD = 4,
    TOKEN_KIND_BUILTIN_UPPERCASEWORD = 4,
    TOKEN_KIND_BUILTIN_WHITESPACE = 5,
    TOKEN_KIND_BUILTIN_COMMENT = 6,
    TOKEN_KIND_BUILTIN_DELIMITEDSTRING = 7,
    TOKEN_KIND_BUILTIN_URL = 8,
    TOKEN_KIND_BUILTIN_EMAIL = 9,
    TOKEN_KIND_BUILTIN_TWITTER = 10,
    TOKEN_KIND_BUILTIN_HASHTAG = 11,
    TOKEN_KIND_BUILTIN_EMPTY = 12,
    TOKEN_KIND_BUILTIN_ANY = 13,
};

@interface PKSParser : NSObject <PKTokenizerDelegate>

- (id)parseString:(NSString *)input assembler:(id)a error:(NSError **)outErr;
- (id)parseStream:(NSInputStream *)input assembler:(id)a error:(NSError **)outErr;

@property (nonatomic, retain) PKTokenizer *tokenizer;
@property (nonatomic, retain) PKSTokenAssembly *assembly;
@property (nonatomic, assign) BOOL disableActions;
@property (nonatomic, assign) BOOL silentlyConsumesWhitespace;
@end

@interface PKSParser (Subclass)

- (PKToken *)LT:(NSInteger)i;
- (NSInteger)LA:(NSInteger)i;
- (double)LF:(NSInteger)i;
- (NSString *)LS:(NSInteger)i;

- (void)match:(NSInteger)x;
- (void)discard:(NSInteger)n;
- (BOOL)predicts:(NSInteger)tokenKind, ...;
- (BOOL)speculate:(PKSSpeculateBlock)block;
- (id)execute:(PKSActionBlock)block;
- (BOOL)test:(PKSPredicateBlock)block;
- (void)testAndThrow:(PKSPredicateBlock)block;
- (void)fireAssemblerSelector:(SEL)sel;
- (void)raise:(NSString *)fmt, ...;

- (void)parseRule:(SEL)ruleSelector withMemo:(NSMutableDictionary *)memoization;

// builtin token types
- (void)Any;
- (void)Empty;
- (void)Word;
- (void)LowercaseWord;
- (void)UppercaseWord;
- (void)Number;
- (void)Symbol;
- (void)Comment;
- (void)Whitespace;
- (void)QuotedString;
- (void)DelimitedString;

@end
