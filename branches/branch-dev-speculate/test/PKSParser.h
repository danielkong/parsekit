//
//  PKSParser.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import <Foundation/Foundation.h>

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

- (id)parseString:(NSString *)input assembler:(id)a error:(NSError **)outErr;
- (id)parseStream:(NSInputStream *)input assembler:(id)a error:(NSError **)outErr;

@end

@interface PKSParser (Subclass)
// underscores prevent name collision with grammar production names.
- (void)_match:(NSInteger)x;
- (void)_consume;
- (void)_discard;
- (BOOL)_predicts:(NSSet *)set;
- (void)_fireAssemblerSelector:(SEL)sel;
- (NSInteger)_tokenKindForString:(NSString *)name;

// speculation
- (PKToken *)_lt:(NSInteger)i;
- (NSInteger)_la:(NSInteger)i;
- (BOOL)_speculate:(SEL)sel;

// builtin token types
- (void)Any;
- (void)Empty;
- (void)Word;
- (void)Number;
- (void)Symbol;
- (void)Comment;
- (void)Whitespace;
- (void)QuotedString;
- (void)DelimitedString;
@end
