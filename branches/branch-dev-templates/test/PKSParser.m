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
    
    if (_lookahead.userType == x) {
        [self consume];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"expecting %ld; found %@", x, _lookahead];
    }
}


- (void)matchString:(NSString *)s {
    NSAssert(_lookahead, @"");
    
    if ([_lookahead.stringValue isEqualToString:@"s"]) {
        [self consume];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"expecting '%@'; found %@", s, _lookahead];
    }
}


- (void)consume {
    self.lookahead = [_tokenizer nextToken];
}


- (void)Any {

}


- (void)Empty {

}


- (void)Word {

}


- (void)Number {

}


- (void)Symbol {

}


- (void)Comment {

}


- (void)Whitespace {

}


- (void)QuotedString {

}


- (void)DelimitedString {

}


- (void)Pattern {

}

@end
