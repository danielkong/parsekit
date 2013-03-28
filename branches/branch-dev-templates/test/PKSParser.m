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
            [self consume]; // get a lookahead token
            [self _start:NO];
            
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


- (void)match:(NSInteger)x andDiscard:(BOOL)discard {
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_EOF);
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_INVALID);
    NSAssert(_lookahead, @"");
    
    NSLog(@"lookahead %@", [_lookahead debugDescription]);
    NSLog(@"assembly %@", [_assembly description]);

    // handle empty
    if (TOKEN_KIND_BUILTIN_EMPTY == x) return;
    
    if (_lookahead.tokenKind == x || TOKEN_KIND_BUILTIN_ANY == x) {
        if (!discard) {
            [_assembly push:_lookahead];
        }

        [self consume];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"expecting %ld; found %@", x, _lookahead];
    }
}


- (void)consume {
    if ([_assembly hasMore]) {
        
        // advance
        self.lookahead = [_assembly next];
                
        // set token user type
        _lookahead.tokenKind = [self tokenKindForToken:_lookahead];
    }
}


- (BOOL)predicts:(NSSet *)set {
    NSInteger x = _lookahead.tokenKind;
    BOOL result = [set containsObject:@(x)];
    return result;
}


- (NSInteger)tokenKindForToken:(PKToken *)tok {
    NSInteger x = [self tokenKindForString:tok.stringValue];
    
    if (TOKEN_KIND_BUILTIN_INVALID == x) {
        x = tok.tokenType;
    }
    
    return x;
}


- (NSInteger)tokenKindForString:(NSString *)name {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return TOKEN_KIND_BUILTIN_INVALID;
}


- (void)_start:(BOOL)discard {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)Any:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_ANY andDiscard:discard];
}


- (void)Empty:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
}


- (void)Word:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_WORD andDiscard:discard];
}


- (void)Number:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_NUMBER andDiscard:discard];
}


- (void)Symbol:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_SYMBOL andDiscard:discard];
}


- (void)Comment:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_COMMENT andDiscard:discard];
}


- (void)Whitespace:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_WHITESPACE andDiscard:discard];
}


- (void)QuotedString:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_QUOTEDSTRING andDiscard:discard];
}


- (void)DelimitedString:(BOOL)discard {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self match:TOKEN_KIND_BUILTIN_DELIMITEDSTRING andDiscard:discard];
}

@end
