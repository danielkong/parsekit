//
//  PKSParser.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import <ParseKit/PKSParser.h>
#import <ParseKit/PKToken.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKSTokenAssembly.h>
#import "PKSRecognitionException.h"

#define FAILED -1

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]

@interface PKSTokenAssembly ()
- (void)consume:(PKToken *)tok;
@end

@interface PKSParser ()
@property (nonatomic, retain) PKSRecognitionException *_exception;
@property (nonatomic, retain) PKTokenizer *_tokenizer;
@property (nonatomic, assign) id _assembler; // weak ref
@property (nonatomic, retain) PKSTokenAssembly *_assembly;
@property (nonatomic, retain) NSMutableArray *_lookahead;
@property (nonatomic, retain) NSMutableArray *_markers;
@property (nonatomic, assign) NSInteger _p;
@property (nonatomic, assign, readonly) BOOL _isSpeculating;
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;

- (NSInteger)tokenKindForString:(NSString *)s;
- (BOOL)tokenKind:(NSInteger)x predicts:(NSInteger)tokenKind;

// conenience
- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;
- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;

// backtracking
- (void)_consume;
- (NSInteger)_mark;
- (void)_unmark;
- (void)_seek:(NSInteger)index;
- (void)_sync:(NSInteger)i;
- (void)_fill:(NSInteger)n;

// memoization
- (BOOL)alreadyParsedRule:(NSMutableDictionary *)memoization;
- (void)memoize:(NSMutableDictionary *)memoization atIndex:(NSInteger)startTokenIndex failed:(BOOL)failed;
- (void)_clearMemo;
@end

@implementation PKSParser

- (id)init {
    self = [super init];
    if (self) {
        // create a single exception for reuse in control flow
        self._exception = [[[PKSRecognitionException alloc] initWithName:NSStringFromClass([PKSRecognitionException class]) reason:nil userInfo:nil] autorelease];
        
        self._tokenKindTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self._exception = nil;
    self._tokenizer = nil;
    self._assembler = nil;
    self._assembly = nil;
    self._lookahead = nil;
    self._markers = nil;
    self._tokenKindTab = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark PKTokenizerDelegate

- (NSInteger)tokenizer:(PKTokenizer *)t tokenKindForStringValue:(NSString *)str {
    NSParameterAssert([str length]);
    return [self tokenKindForString:str];
}


- (NSInteger)tokenKindForString:(NSString *)s {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;
    
    id obj = self._tokenKindTab[s];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}


- (id)parseStream:(NSInputStream *)input assembler:(id)a error:(NSError **)outError {
    NSParameterAssert(input);
    
    [input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [input open];
    
    PKTokenizer *t = [PKTokenizer tokenizerWithStream:input];

    id result = [self _doParseWithTokenizer:t assembler:a error:outError];
    
    [input close];
    [input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    return result;
}


- (id)parseString:(NSString *)input assembler:(id)a error:(NSError **)outError {
    NSParameterAssert(input);

    PKTokenizer *t = [PKTokenizer tokenizerWithString:input];
    
    id result = [self _doParseWithTokenizer:t assembler:a error:outError];
    return result;
}


- (id)_doParseWithTokenizer:(PKTokenizer *)t assembler:(id)a error:(NSError **)outError {
    id result = nil;
    
    // setup
    self._assembler = a;
    self._tokenizer = t;
    self._assembly = [PKSTokenAssembly assemblyWithTokenizer:_tokenizer];
    
    self._tokenizer.delegate = self;
    
    // setup speculation
    self._p = 0;
    self._lookahead = [NSMutableArray array];
    self._markers = [NSMutableArray array];

    [self _clearMemo];
    
    @try {

        @autoreleasepool {
            // parse
            [self _start];
            
            //NSLog(@"%@", _assembly);
            
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
    @finally {
        self._tokenizer.delegate = nil;
        self._tokenizer = nil;
        self._assembler = nil;
        self._assembly = nil;
        self._lookahead = nil;
        self._markers = nil;
    }
    
    return result;
}


- (void)match:(NSInteger)x {
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_EOF);
    NSParameterAssert(x != TOKEN_KIND_BUILTIN_INVALID);
    NSAssert(_lookahead, @"");
    
    // always match empty without consuming
    if (TOKEN_KIND_BUILTIN_EMPTY == x) return;
    
    PKToken *lt = LT(1);
//    NSLog(@"%@", lt);
    if (lt.tokenKind == x || TOKEN_KIND_BUILTIN_ANY == x) {
        if (!self._isSpeculating) {
            [_assembly consume:lt];
//            NSLog(@"%@", _assembly);
        }
        
        [self _consume];
    } else {
        [self raise:@"expecting %ld; found %@", x, lt];
    }
}


- (void)_consume {
    self._p++;
    
    // have we hit end of buffer when not backtracking?
    if (_p == [_lookahead count] && !self._isSpeculating) {
        // if so, it's an opp to start filling at index 0 again
        self._p = 0;
        [_lookahead removeAllObjects]; // size goes to 0, but retains memory on heap
        [self _clearMemo]; // clear all rule_memo dictionaries
    }

    [self _sync:1];
}


- (void)discard:(NSInteger)n {
    if (self._isSpeculating) return;
    
    while (n > 0) {
        NSAssert(![_assembly isStackEmpty], @"");
        [_assembly pop];
        --n;
    }
}


- (void)fireAssemblerSelector:(SEL)sel {
    if (self._isSpeculating) return;
    
    if (_assembler && [_assembler respondsToSelector:sel]) {
        [_assembler performSelector:sel withObject:self withObject:_assembly];
    }
}


- (PKToken *)LT:(NSInteger)i {
    [self _sync:i];
    
    NSUInteger idx = _p + i - 1;
    NSAssert(idx < [_lookahead count], @"");

    PKToken *tok = _lookahead[idx];
    //NSLog(@"LT(%ld) : %@", i, [tok debugDescription]);
    return tok;
}


- (NSInteger)LA:(NSInteger)i {
    return [LT(i) tokenKind];
}


- (double)LF:(NSInteger)i {
    return [LT(i) floatValue];
}


- (NSString *)LS:(NSInteger)i {
    return [LT(i) stringValue];
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


- (BOOL)_isSpeculating {
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
        if (TOKEN_KIND_BUILTIN_INVALID == tok.tokenKind) {
            tok.tokenKind = [self _tokenKindForToken:tok];
        }
        
        // buffer in lookahead
        NSAssert(tok, @"");
        //NSLog(@"-nextToken: %@", [tok debugDescription]);
        [_lookahead addObject:tok];
    }
}


- (NSInteger)_tokenKindForToken:(PKToken *)tok {
    NSString *key = tok.stringValue;
    
    NSInteger x = tok.tokenKind;
    
    if (TOKEN_KIND_BUILTIN_INVALID == x) {
        x = [self tokenKindForString:key];
    
        if (TOKEN_KIND_BUILTIN_INVALID == x) {
            x = tok.tokenType;
        }
    }
    
    return x;
}


- (void)raise:(NSString *)fmt, ... {
    va_list vargs;
    va_start(vargs, fmt);
    
    NSString *str = [[[NSString alloc] initWithFormat:fmt arguments:vargs] autorelease];
    _exception.currentReason = str;

    // reuse
    @throw _exception;
    
    va_end(vargs);
}


- (BOOL)predicts:(NSInteger)firstTokenKind, ... {
    NSParameterAssert(firstTokenKind != TOKEN_KIND_BUILTIN_INVALID);
    
    NSInteger x = LA(1);
    
    if ([self tokenKind:x predicts:firstTokenKind]) {
        return YES;
    }
    
//    va_list vargs;
//    va_start(vargs, firstTokenKind);
//
//    NSInteger nextTokenKind;
//    while ((nextTokenKind = va_arg(vargs, NSInteger))) {
//        if ([self tokenKind:x predicts:nextTokenKind]) {
//            return YES;
//        }
//    }
//
//    va_end(vargs);

    return NO;
}


- (BOOL)tokenKind:(NSInteger)x predicts:(NSInteger)tokenKind {
    BOOL result = NO;
    
    if (TOKEN_KIND_BUILTIN_ANY == tokenKind && x != TOKEN_KIND_BUILTIN_EOF) {
        result = YES;
    } else if (x == tokenKind) {
        result = YES;
    }
    
    return result;
}


- (BOOL)speculate:(PKSSpeculateBlock)block {
    NSParameterAssert(block);
    
    BOOL success = YES;
    [self _mark];
    
    @try {
        if (block) block();
    }
    @catch (PKSRecognitionException *ex) {
        success = NO;
    }
    
    [self _unmark];
    return success;
}


- (id)execute:(PKSActionBlock)block {
    NSParameterAssert(block);
    if (self._isSpeculating || _disableActions) return nil;

    id result = nil;
    if (block) result = block();
    return result;
}


- (BOOL)test:(PKSPredicateBlock)block {
    NSParameterAssert(block);
    
    BOOL result = YES;
    if (block) result = block();
    return result;
}


- (void)testAndThrow:(PKSPredicateBlock)block {
    NSParameterAssert(block);
    
    if (![self test:block]) {
        [self raise:@"Predicate Failed"];
    }
}


- (void)parseRule:(SEL)ruleSelector withMemo:(NSMutableDictionary *)memoization {
    BOOL failed = NO;
    NSInteger startTokenIndex = self._p;
    if (self._isSpeculating && [self alreadyParsedRule:memoization]) return;
                                
    @try { [self performSelector:ruleSelector]; }
    @catch (PKSRecognitionException *ex) { failed = YES; @throw ex; }
    @finally {
        if (self._isSpeculating) [self memoize:memoization atIndex:startTokenIndex failed:failed];
    }
}


- (BOOL)alreadyParsedRule:(NSMutableDictionary *)memoization {
    
    id idxKey = @(self._p);
    NSNumber *memoObj = memoization[idxKey];
    if (!memoObj) return NO;
    
    NSInteger memo = [memoObj integerValue];
    if (FAILED == memo) {
        [self raise:@"already failed prior attempt at start token index %@", idxKey];
    }
    
    [self _seek:memo];
    return YES;
}


- (void)memoize:(NSMutableDictionary *)memoization atIndex:(NSInteger)startTokenIndex failed:(BOOL)failed {
    id idxKey = @(startTokenIndex);
    
    NSInteger stopTokenIdex = failed ? FAILED : self._p;
    id idxVal = @(stopTokenIdex);

    memoization[idxKey] = idxVal;
}


- (void)_clearMemo {
    
}


- (BOOL)_popBool {
    id obj = [self._assembly pop];
    return [obj boolValue];
}


- (NSInteger)_popInteger {
    id obj = [self._assembly pop];
    return [obj integerValue];
}


- (double)_popDouble {
    id obj = [self._assembly pop];
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return [obj doubleValue];
    } else {
        return [(PKToken *)obj floatValue];
    }
}


- (PKToken *)_popToken {
    PKToken *tok = [self._assembly pop];
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    return tok;
}


- (NSString *)_popString {
    id obj = [self._assembly pop];
    if ([obj respondsToSelector:@selector(stringValue)]) {
        return [obj stringValue];
    } else {
        return [obj description];
    }
}


- (void)_pushBool:(BOOL)yn {
    [self._assembly push:(id)(yn ? kCFBooleanTrue : kCFBooleanFalse)];
}


- (void)_pushInteger:(NSInteger)i {
    [self._assembly push:@(i)];
}


- (void)_pushDouble:(double)d {
    [self._assembly push:@(d)];
}


- (void)_start {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)Any {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_ANY];
}


- (void)Empty {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
}


- (void)Word {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_WORD];
}


- (void)LowercaseWord {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    NSString *str = [self LS:1];
    if ([str length] && islower([str characterAtIndex:0])) {
        [self match:TOKEN_KIND_BUILTIN_WORD];
    }
}


- (void)UppercaseWord {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    NSString *str = [self LS:1];
    if ([str length] && isupper([str characterAtIndex:0])) {
        [self match:TOKEN_KIND_BUILTIN_WORD];
    }
}


- (void)Number {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_NUMBER];
}


- (void)Symbol {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_SYMBOL];
}


- (void)Comment {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_COMMENT];
}


- (void)Whitespace {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_WHITESPACE];
}


- (void)QuotedString {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_QUOTEDSTRING];
}


- (void)DelimitedString {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_DELIMITEDSTRING];
}

@synthesize _exception = _exception;
@synthesize _tokenizer = _tokenizer;
@synthesize _assembler = _assembler;
@synthesize _assembly = _assembly;
@synthesize _lookahead = _lookahead;
@synthesize _markers = _markers;
@synthesize _p = _p;
@synthesize _tokenKindTab = _tokenKindTab;
@end
