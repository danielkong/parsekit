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
    TOKEN_TYPE_BUILTIN_EOF = -1,
    TOKEN_TYPE_BUILTIN_INVALID = 0,
    TOKEN_TYPE_BUILTIN_NUMBER = 1,
    TOKEN_TYPE_BUILTIN_QUOTED_STRING = 2,
    TOKEN_TYPE_BUILTIN_SYMBOL = 3,
    TOKEN_TYPE_BUILTIN_WORD = 4,
    TOKEN_TYPE_BUILTIN_WHITESPACE = 5,
    TOKEN_TYPE_BUILTIN_COMMENT = 6,
    TOKEN_TYPE_BUILTIN_DELIMITED_STRING = 7,
    TOKEN_TYPE_BUILTIN_URL = 8,
    TOKEN_TYPE_BUILTIN_EMAIL = 9,
    TOKEN_TYPE_BUILTIN_TWITTER = 10,
    TOKEN_TYPE_BUILTIN_HASHTAG = 11,
    TOKEN_TYPE_BUILTIN_ANY = 12,
};

@interface PKSParser : NSObject

- (id)parse:(NSString *)input error:(NSError **)outErr;

@property (nonatomic, retain) PKTokenizer *tokenizer;

// for subclasses
- (void)match:(NSInteger)x;
- (void)consume;
- (BOOL)predicts:(NSSet *)set;

- (NSInteger)userTypeForString:(NSString *)name;
//- (NSInteger)builtInUserTypeForString:(NSString *)name;

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
