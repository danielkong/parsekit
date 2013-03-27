//
//  PKSParser.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import "PKSParser.h"
#import <ParseKit/PKToken.h>
#import <ParseKit/PKTokenizer.h>

@implementation PKSParser

- (void)dealloc {
    self.tokenizer = nil;
    self.lookahead = nil;
    [super dealloc];
}


- (void)match:(NSInteger)x {
    NSAssert(_lookahead, @"");
    
    if (_lookahead.userType == x || TOKEN_TYPE_BUILTIN_ANY == x) {
        [self consume];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"expecting %ld; found %@", x, _lookahead];
    }
}


- (void)consume {
    self.lookahead = [_tokenizer nextToken];
}


- (BOOL)predicts:(NSIndexSet *)set {
    NSInteger x = _lookahead.userType;
    BOOL result = [set containsIndex:x];
    return result;
}


- (void)Any {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_ANY];
}


- (void)Empty {
	NSLog(@"Word");
    
}


- (void)Word {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_WORD];
}


- (void)Number {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_NUMBER];
}


- (void)Symbol {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_SYMBOL];
}


- (void)Comment {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_COMMENT];
}


- (void)Whitespace {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_WHITESPACE];
}


- (void)QuotedString {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_QUOTED_STRING];
}


- (void)DelimitedString {
	NSLog(@"Word");
    
    [self match:TOKEN_TYPE_BUILTIN_DELIMITED_STRING];
}

@end
