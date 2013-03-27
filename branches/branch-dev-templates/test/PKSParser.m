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

@interface PKSParser ()
@property (nonatomic, retain) PKToken *lookahead;
@property (nonatomic, retain) id target;
@end

@implementation PKSParser

- (void)dealloc {
    self.tokenizer = nil;
    self.lookahead = nil;
    self.target = nil;
    [super dealloc];
}


- (id)parse:(NSString *)s error:(NSError **)outError {
    id result = nil;
    
    PKTokenizer *t = self.tokenizer;
    if (!t) t = [PKTokenizer tokenizer];
    t.string = s;
    self.tokenizer = t;

    @try {

        @autoreleasepool {
            [self consume];
            [self _start];
            
            result = [_target retain]; // +1
            self.target = nil;
        }
        [result autorelease]; // -1

    }
    @catch (NSException *ex) {
        if (outError) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[ex userInfo]];
            
            // get reason
            NSString *reason = [ex reason];
            if ([reason length]) [userInfo setObject:reason forKey:NSLocalizedFailureReasonErrorKey];
            
            // get domain
            NSString *exName = [ex name];
            NSString *domain = exName ? exName : @"PKParseException";
            
            // convert to NSError
            NSError *err = [NSError errorWithDomain:domain code:47 userInfo:[[userInfo copy] autorelease]];
            *outError = err;
        } else {
            [ex raise];
        }
    }
    
    return result;
}


- (void)match:(NSInteger)x {
    NSParameterAssert(x != TOKEN_TYPE_BUILTIN_EOF);
    NSParameterAssert(x != TOKEN_TYPE_BUILTIN_INVALID);
    NSAssert(_lookahead, @"");
    
    NSLog(@"%@", [_lookahead debugDescription]);
    if (_lookahead.userType == x || TOKEN_TYPE_BUILTIN_ANY == x) {
        [self consume];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"expecting %ld; found %@", x, _lookahead];
    }
}


- (void)consume {
    self.lookahead = [_tokenizer nextToken];
    NSInteger x = [self userTypeForString:_lookahead.stringValue];
    _lookahead.userType = x;
}


- (BOOL)predicts:(NSSet *)set {
    NSInteger x = _lookahead.userType;
    BOOL result = [set containsObject:@(x)];
    return result;
}


- (NSInteger)builtInUserTypeForString:(NSString *)name {
    static NSDictionary *d = nil;
    if (!d) {
        d = [@{
			@"NUMBER": @(TOKEN_TYPE_BUILTIN_NUMBER),
			@"QUOTED_STRING": @(TOKEN_TYPE_BUILTIN_QUOTED_STRING),
			@"SYMBOL": @(TOKEN_TYPE_BUILTIN_SYMBOL),
			@"WORD": @(TOKEN_TYPE_BUILTIN_WORD),
			@"WHITESPACE": @(TOKEN_TYPE_BUILTIN_WHITESPACE),
			@"COMMENT": @(TOKEN_TYPE_BUILTIN_COMMENT),
			@"DELIMITED_STRING": @(TOKEN_TYPE_BUILTIN_DELIMITED_STRING),
			@"URL": @(TOKEN_TYPE_BUILTIN_URL),
			@"EMAIL": @(TOKEN_TYPE_BUILTIN_EMAIL),
			@"TWITTER": @(TOKEN_TYPE_BUILTIN_TWITTER),
			@"HASHTAG": @(TOKEN_TYPE_BUILTIN_HASHTAG),
			@"ANY": @(TOKEN_TYPE_BUILTIN_ANY),
        } retain];
    }
    
    NSInteger x = TOKEN_TYPE_BUILTIN_INVALID;
    id obj = d[[name uppercaseString]];
    if (obj) {
        x = [obj integerValue];
    }
    return x;
}


- (NSInteger)userTypeForString:(NSString *)name {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return TOKEN_TYPE_BUILTIN_INVALID;
}


- (void)_start {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
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
