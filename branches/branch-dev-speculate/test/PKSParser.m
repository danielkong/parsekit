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
#import "PKSTokenAssembly.h"
#import "PKSRecognitionException.h"

@interface PKSTokenAssembly ()
- (void)consume:(PKToken *)tok;
@end

@interface PKSParser ()
@property (nonatomic, retain) PKTokenizer *_tokenizer;
@property (nonatomic, assign) id _assembler; // weak ref
@property (nonatomic, retain) PKSTokenAssembly *_assembly;
@property (nonatomic, retain) NSMutableArray *_lookahead;
@property (nonatomic, retain) NSMutableArray *_markers;
@property (nonatomic, assign) NSInteger _p;
@property (nonatomic, assign, readonly) BOOL _isSpeculating;

- (NSInteger)_mark;
- (void)_unmark;
- (void)_seek:(NSInteger)index;
- (void)_sync:(NSInteger)i;
- (void)_fill:(NSInteger)n;
@end

@implementation PKSParser

- (void)dealloc {
    self._tokenizer = nil;
    self._assembler = nil;
    self._assembly = nil;
    self._lookahead = nil;
    self._markers = nil;
    [super dealloc];
}


- (id)parseStream:(NSInputStream *)input assembler:(id)a error:(NSError **)outError {
    self._assembler = a;
    
    // setup tokenizer
    if (!_tokenizer) self._tokenizer = [PKTokenizer tokenizer];
    _tokenizer.stream = input;

    return [self _doParse:outError];
}


- (id)parseString:(NSString *)input assembler:(id)a error:(NSError **)outError {
    self._assembler = a;

    // setup tokenizer
    if (!_tokenizer) self._tokenizer = [PKTokenizer tokenizer];
    _tokenizer.string = input;
    
    return [self _doParse:outError];
}


- (id)_doParse:(NSError **)outError {
    id result = nil;
    
    // setup assembly
    self._assembly = [PKSTokenAssembly assemblyWithTokenizer:_tokenizer];
    
    // setup speculation
    self._p = 0;
    self._lookahead = [NSMutableArray array];
    self._markers = [NSMutableArray array];

    @try {

        @autoreleasepool {
            // parse
            [self _start];
            
            // get result
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
    
    // always match empty without consuming
    if (TOKEN_KIND_BUILTIN_EMPTY == x) return;
    
    PKToken *lt = [self _lt:1];
    if (lt.tokenKind == x || TOKEN_KIND_BUILTIN_ANY == x) {
        if (!self.isSpeculating) {
            [_assembly consume:lt];
        }
        
        [self _consume];
    } else {
        [NSException raise:@"PKRuntimeException" format:@"expecting %ld; found %@", x, lt];
    }
}


- (void)_consume {
    self._p++;
    
    // have we hit end of buffer when not backtracking?
    if (_p == [_lookahead count] && !self.isSpeculating) {
        // if so, it's an opp to start filling at index 0 again
        self._p = 0;
        [_lookahead removeAllObjects]; // size goes to 0, but retains memory on heap
    }

    [self _sync:1];
}


- (void)_discard {
    if (self.isSpeculating) return;
    
    NSAssert(![_assembly isStackEmpty], @"");
    [_assembly pop];
}


- (BOOL)_predicts:(NSSet *)set {
    NSInteger x = [self _la:1];
    BOOL result = [set containsObject:@(x)];
    return result;
}


- (void)_fireAssemblerSelector:(SEL)sel {
    if (self.isSpeculating) return;
    
    if (_assembler && [_assembler respondsToSelector:sel]) {
        [_assembler performSelector:sel withObject:self withObject:_assembly];
    }
}


- (PKToken *)_lt:(NSInteger)i {
    [self _sync:i];
    
    NSUInteger idx = _p + i - 1;
    NSAssert(idx < [_lookahead count], @"");

    PKToken *tok = _lookahead[idx];
    //NSLog(@"lt : %@", [tok debugDescription]);
    return tok;
}


- (NSInteger)_la:(NSInteger)i {
    return [[self _lt:i] tokenKind];
}


- (NSInteger)_mark {
    [_markers addObject:@(_p)];
    return _p;
}


- (void)_unmark {
    NSInteger marker = [[_markers lastObject] integerValue];
    [_markers removeLastObject];
    
    [self _seek:marker];
}


- (void)_seek:(NSInteger)index {
    self._p = index;
}


- (BOOL)isSpeculating {
    return [_markers count] > 0;
}


- (void)_sync:(NSInteger)i {
    NSInteger lastNeededIndex = _p + i - 1;
    NSInteger lastFullIndex = [_lookahead count] - 1;
    
    if (lastNeededIndex > lastFullIndex) { // out of tokens ?
        NSInteger n = lastNeededIndex - lastFullIndex; // get n tokens
        [self _fill:n];
    }
}


- (void)_fill:(NSInteger)n {
    for (NSUInteger i = 0; i <= n; ++i) { // <= ?? fetches an extra lookahead tok
        PKToken *tok = [_tokenizer nextToken];

        // set token kind
        tok.tokenKind = [self _tokenKindForToken:tok];
        
        // buffer in lookahead
        NSAssert(tok, @"");
        //NSLog(@"-nextToken: %@", [tok debugDescription]);
        [_lookahead addObject:tok];
    }
}


- (NSInteger)_tokenKindForToken:(PKToken *)tok {
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


- (BOOL)_speculate:(SEL)sel {
    BOOL success = YES;
    [self _mark];
    
    @try {
        [self performSelector:sel];
    }
    @catch (PKSRecognitionException *ex) {
        success = NO;
    }
    
    [self _unmark];
    return success;
}


- (void)_start {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)Any {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_ANY];
}


- (void)Empty {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
}


- (void)Word {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_WORD];
}


- (void)Number {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_NUMBER];
}


- (void)Symbol {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_SYMBOL];
}


- (void)Comment {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_COMMENT];
}


- (void)Whitespace {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_WHITESPACE];
}


- (void)QuotedString {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_QUOTEDSTRING];
}


- (void)DelimitedString {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self _match:TOKEN_KIND_BUILTIN_DELIMITEDSTRING];
}

@synthesize _tokenizer = _tokenizer;
@synthesize _assembler = _assembler;
@synthesize _assembly = _assembly;
@synthesize _lookahead = _lookahead;
@synthesize _markers = _markers;
@synthesize _p = _p;
@synthesize _isSpeculating = _isSpeculating;
@end
