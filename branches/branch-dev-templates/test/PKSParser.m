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
    NSParameterAssert(x != TOKEN_TYPE_BUILTIN_INVALID);
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
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_ANY];
}


- (void)Empty {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
}


- (void)Word {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_WORD];
}


- (void)Number {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_NUMBER];
}


- (void)Symbol {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_SYMBOL];
}


- (void)Comment {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_COMMENT];
}


- (void)Whitespace {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_WHITESPACE];
}


- (void)QuotedString {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_QUOTED_STRING];
}


- (void)DelimitedString {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_TYPE_BUILTIN_DELIMITED_STRING];
}

@end
