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
@property (nonatomic, assign) BOOL silentlyConsumesWhitespace;
@property (nonatomic, assign) BOOL enableActions; // default YES
@property (nonatomic, assign) BOOL enableAutomaticErrorRecovery; // default NO
@end

@interface PKSParser (Subclass)

- (PKToken *)LT:(NSInteger)i;
- (NSInteger)LA:(NSInteger)i;
- (double)LF:(NSInteger)i;
- (NSString *)LS:(NSInteger)i;

- (void)consume:(PKToken *)tok;
- (void)match:(NSInteger)tokenKind discard:(BOOL)discard;
- (BOOL)predicts:(NSInteger)tokenKind, ...;
- (BOOL)speculate:(PKSSpeculateBlock)block;
- (id)execute:(PKSActionBlock)block;
- (BOOL)test:(PKSPredicateBlock)block;
- (void)testAndThrow:(PKSPredicateBlock)block;
- (void)fireAssemblerSelector:(SEL)sel;
- (void)raise:(NSString *)fmt, ...;

- (void)popFollow:(NSInteger)tokenKind;
- (void)pushFollow:(NSInteger)tokenKind;
- (BOOL)resync;

- (void)parseRule:(SEL)ruleSelector withMemo:(NSMutableDictionary *)memoization;

// builtin token types
- (void)matchEOF:(BOOL)discard;
- (void)matchAny:(BOOL)discard;
- (void)matchEmpty:(BOOL)discard;
- (void)matchWord:(BOOL)discard;
- (void)matchNumber:(BOOL)discard;
- (void)matchSymbol:(BOOL)discard;
- (void)matchComment:(BOOL)discard;
- (void)matchWhitespace:(BOOL)discard;
- (void)matchQuotedString:(BOOL)discard;
- (void)matchDelimitedString:(BOOL)discard;

@end
