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
@property (nonatomic, assign) id assembler; // weak ref
@end

@interface PKSParser (Subclass)
// underscores prevent name clash with grammar production names.
- (void)__match:(NSInteger)x;
- (void)__consume;
- (void)__discard;
- (BOOL)__predicts:(NSSet *)set;
- (void)__fireAssemblerSelector:(SEL)sel;
- (NSInteger)__tokenKindForString:(NSString *)name;

// speculation
- (PKToken *)__lt;
- (NSInteger)__la;
- (BOOL)__speculate:(SEL)sel;
- (void)__mark;
- (void)__unmark;
- (void)__sync:(NSInteger)i;
- (void)__fill:(NSInteger)n;

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
