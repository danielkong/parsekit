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
#import <ParseKit/PKTokenAssembly.h>

@interface PKAssembly ()
//- (id)peek;
- (id)next;
- (BOOL)hasMore;
//@property (nonatomic, readonly) NSUInteger objectsConsumed;
@end

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
    self.assembly = [PKTokenAssembly assemblyWithTokenizer:t];

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
    if ([_assembly hasMore]) {
        
        // advance
        self.lookahead = [_assembly next];
        
        BOOL discard = NO; // TODO
        if (!discard) {
            [_assembly push:_lookahead];
        }

        // set token user type
        _lookahead.userType = [self tokenUserTypeForToken:_lookahead];
    }
}


- (BOOL)predicts:(NSSet *)set {
    NSInteger x = _lookahead.userType;
    BOOL result = [set containsObject:@(x)];
    return result;
}


- (NSInteger)tokenUserTypeForToken:(PKToken *)tok {
    NSInteger x = [self tokenUserTypeForString:tok.stringValue];
    
    if (TOKEN_TYPE_BUILTIN_INVALID == x) {
        x = tok.tokenType;
    }
    
    return x;
}


- (NSInteger)tokenUserTypeForString:(NSString *)name {
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
