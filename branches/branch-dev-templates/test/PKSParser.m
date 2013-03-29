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
- (id)next;
- (BOOL)hasMore;
@end

@interface PKSParser ()
@property (nonatomic, retain) PKToken *lookahead;
@property (nonatomic, assign) BOOL speculating;
@property (nonatomic, retain) PKAssembly *assembly;
@end

@implementation PKSParser

- (void)dealloc {
    self.tokenizer = nil;
    self.assembler = nil;
    self.assembly = nil;
    self.lookahead = nil;
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
            [self _consume]; // get a lookahead token
            [self _start];
            
            if (_assembly.target) {
                result = _assembly.target;
            } else {
                result = _assembly;
            }

            [result retain]; // +1
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


- (void)_match:(NSInteger)x {
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_EOF);
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_INVALID);
    NSAssert(_lookahead, @"");
    
    //NSLog(@"lookahead %@", [_lookahead debugDescription]);
    //NSLog(@"assembly %@", [_assembly description]);

    // always match empty
    if (TOKEN_KIND_BUILTIN_EMPTY == x) return;
    
    if (_lookahead.tokenKind == x || TOKEN_KIND_BUILTIN_ANY == x) {
        [_assembly push:_lookahead];
        
        [self _consume];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"expecting %ld; found %@", x, _lookahead];
    }
}


- (void)_consume {
    if ([_assembly hasMore]) {
        
        // advance
        self.lookahead = [_assembly next];
                
        // set token kind
        _lookahead.tokenKind = [self tokenKindForToken:_lookahead];
    }
}


- (void)_discard {
    NSAssert(![_assembly isStackEmpty], @"");
    [_assembly pop];
}


- (BOOL)_predicts:(NSSet *)set {
    NSInteger x = _lookahead.tokenKind;
    BOOL result = [set containsObject:@(x)];
    return result;
}


- (void)_fireAssemblerSelector:(SEL)sel {
    if (_speculating) return;
    
    if (_assembler && [_assembler respondsToSelector:sel]) {
        [_assembler performSelector:sel withObject:self withObject:_assembly];
    }
}


- (NSInteger)tokenKindForToken:(PKToken *)tok {
    NSInteger x = [self _tokenKindForString:tok.stringValue];
    
    if (TOKEN_KIND_BUILTIN_INVALID == x) {
        x = tok.tokenType;
    }
    
    return x;
}


- (NSInteger)_tokenKindForString:(NSString *)name {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return TOKEN_KIND_BUILTIN_INVALID;
}


- (void)_start {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)Any {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_ANY];
}


- (void)Empty {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
}


- (void)Word {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_WORD];
}


- (void)Number {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_NUMBER];
}


- (void)Symbol {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_SYMBOL];
}


- (void)Comment {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_COMMENT];
}


- (void)Whitespace {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_WHITESPACE];
}


- (void)QuotedString {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_QUOTEDSTRING];
}


- (void)DelimitedString {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _match:TOKEN_KIND_BUILTIN_DELIMITEDSTRING];
}

@end
