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
#import "PKSRecognitionException.h"

@interface PKAssembly ()
- (id)next;
- (BOOL)hasMore;
@end

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *assembly;
@property (nonatomic, retain) NSMutableArray *lookahead;
@property (nonatomic, retain) NSMutableArray *markers;
@property (nonatomic, assign) NSUInteger p;
@property (nonatomic, assign, readonly) BOOL isSpeculating;
@end

@implementation PKSParser

- (void)dealloc {
    self.tokenizer = nil;
    self.assembler = nil;
    self.assembly = nil;
    self.lookahead = nil;
    self.markers = nil;
    [super dealloc];
}


- (id)parse:(NSString *)s error:(NSError **)outError {
    id result = nil;
    
    // setup tokenizer
    PKTokenizer *t = self.tokenizer;
    if (!t) t = [PKTokenizer tokenizer];
    t.string = s;
    self.tokenizer = t;

    // setup assembly
    self.assembly = [PKTokenAssembly assemblyWithTokenizer:t];

    // setup speculation
    self.p = 0;
    self.lookahead = [NSMutableArray array];
    self.markers = [NSMutableArray array];

    @try {

        @autoreleasepool {
            [self __consume]; // prime the lookahead token
            [self __start];
            
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


- (void)__match:(NSInteger)x {
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_EOF);
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_INVALID);
    NSAssert(_lookahead, @"");
    
    //NSLog(@"lookahead %@", [_lookahead debugDescription]);
    //NSLog(@"assembly %@", [_assembly description]);

    // always match empty
    if (TOKEN_KIND_BUILTIN_EMPTY == x) return;
    
    PKToken *lt = [self __lt:1];
    if (lt.tokenKind == x || TOKEN_KIND_BUILTIN_ANY == x) {
        [_assembly push:lt];
        
        [self __consume];
    } else {
        // This is a "Runtime" (rather than "checked" exception) in Java parlance.
        // An obvious programmer error has been made and must be fixed.
        [NSException raise:@"PKRuntimeException" format:@"expecting %ld; found %@", x, lt];
    }
}


- (void)__consume {
    if ([_assembly hasMore]) {
        
        // advance
        PKToken *lt = [_assembly next];
        _lookahead[_p] = lt; // TODO
        
        // set token kind
        lt.tokenKind = [self __tokenKindForToken:lt];
    }
}


- (void)__discard {
    NSAssert(![_assembly isStackEmpty], @"");
    [_assembly pop];
}


- (BOOL)__predicts:(NSSet *)set {
    PKToken *lt = [self __lt:1];
    NSInteger x = lt.tokenKind;
    BOOL result = [set containsObject:@(x)];
    return result;
}


- (void)__fireAssemblerSelector:(SEL)sel {
    if (self.isSpeculating) return;
    
    if (_assembler && [_assembler respondsToSelector:sel]) {
        [_assembler performSelector:sel withObject:self withObject:_assembly];
    }
}


- (PKToken *)__lt:(NSInteger)i {
    [self __sync:i];
    
    return _lookahead[_p + i - 1];
}


- (NSInteger)__la:(NSInteger)i {
    return [[self __lt:i] tokenKind];
}


- (BOOL)__speculate:(SEL)sel {
    BOOL success = YES;
    [self __mark];
    
    @try {
        [self performSelector:sel];
    }
    @catch (PKSRecognitionException *ex) {
        success = NO;
    }

    [self __unmark];
    return success;
}


- (NSUInteger)__mark {
    [_markers addObject:_p];
    return _p;
}


- (void)__unmark {
    NSUInteger pop = [_markers count] - 1;
    NSUInteger marker = _markers[pop];
    [_markers removeLastObject];
    [self __seek:marker];
}


- (void)__seek:(NSInteger)index {
    self.p = index;
}


- (void)__sync:(NSInteger)i {
    return; // TODO
    
    NSUInteger lastNeededIndex = _p + i - 1;
    NSUInteger lastFullIndex = [_lookahead count] - 1;
    
    if (lastNeededIndex > lastFullIndex) { // out of tokens ?
        NSUInteger n = lastNeededIndex - lastFullIndex; // get n tokens
        [self __fill:n];
    }
}


- (BOOL)isSpeculating {
    return [_markers count] > 0;
}


- (void)__fill:(NSInteger)n {
    return; // TODO

    for (NSUInteger i = 0; i <= n; ++i) {
        PKToken *tok = [_assembly next];

        // set token kind
        tok.tokenKind = [self __tokenKindForToken:tok];
        
        // buffer in lookahead
        [_lookahead addObject:tok];
    }
}


- (NSInteger)__tokenKindForToken:(PKToken *)tok {
    NSInteger x = [self __tokenKindForString:tok.stringValue];
    
    if (TOKEN_KIND_BUILTIN_INVALID == x) {
        x = tok.tokenType;
    }
    
    return x;
}


- (NSInteger)__tokenKindForString:(NSString *)name {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return TOKEN_KIND_BUILTIN_INVALID;
}


- (void)__start {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)Any {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_ANY];
}


- (void)Empty {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
}


- (void)Word {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_WORD];
}


- (void)Number {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_NUMBER];
}


- (void)Symbol {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_SYMBOL];
}


- (void)Comment {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_COMMENT];
}


- (void)Whitespace {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_WHITESPACE];
}


- (void)QuotedString {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_QUOTEDSTRING];
}


- (void)DelimitedString {
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self __match:TOKEN_KIND_BUILTIN_DELIMITEDSTRING];
}

@end
