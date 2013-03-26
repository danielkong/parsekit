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

@interface PKSParser : NSObject

@property (nonatomic, retain) PKTokenizer *tokenizer;
@property (nonatomic, retain) PKToken *lookahead;

- (void)match:(NSInteger)x;
- (void)matchString:(NSString *)s;
- (void)consume;

- (void)Any;
- (void)Empty;
- (void)Word;
- (void)Number;
- (void)Symbol;
- (void)Comment;
- (void)Whitespace;
- (void)QuotedString;
- (void)DelimitedString;
- (void)Pattern;
@end
