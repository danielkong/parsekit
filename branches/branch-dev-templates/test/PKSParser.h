//
//  PKSParser.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import <Foundation/Foundation.h>

@class PKAssembly;
@class PKTokenizer;
@class PKToken;

enum {
    TOKEN_KIND_BUILTIN_EOF = -1,
    TOKEN_KIND_BUILTIN_INVALID = 0,
    TOKEN_KIND_BUILTIN_NUMBER = 1,
    TOKEN_KIND_BUILTIN_QUOTEDSTRING = 2,
    TOKEN_KIND_BUILTIN_SYMBOL = 3,
    TOKEN_KIND_BUILTIN_WORD = 4,
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

@interface PKSParser : NSObject

- (id)parse:(NSString *)input error:(NSError **)outErr;

@property (nonatomic, retain) PKTokenizer *tokenizer;
@property (nonatomic, retain) PKAssembly *assembly;
@property (nonatomic, assign) id assembler;
@property (nonatomic, assign) id preassembler;

// for subclasses
- (void)match:(NSInteger)x andDiscard:(BOOL)discard;
- (void)consume;
- (BOOL)predicts:(NSSet *)set;

- (NSInteger)tokenKindForString:(NSString *)name;

- (void)Any:(BOOL)discard;
- (void)Empty:(BOOL)discard;
- (void)Word:(BOOL)discard;
- (void)Number:(BOOL)discard;
- (void)Symbol:(BOOL)discard;
- (void)Comment:(BOOL)discard;
- (void)Whitespace:(BOOL)discard;
- (void)QuotedString:(BOOL)discard;
- (void)DelimitedString:(BOOL)discard;
@end
