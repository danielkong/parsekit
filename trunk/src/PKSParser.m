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
#import <ParseKit/PKSRecognitionException.h>

#define FAILED -1

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]

@interface PKSTokenAssembly ()
- (void)consume:(PKToken *)tok;
@end

@interface PKSParser ()
@property (nonatomic, retain) PKSRecognitionException *_exception;
@property (nonatomic, assign) id _assembler; // weak ref
@property (nonatomic, retain) NSMutableArray *_lookahead;
@property (nonatomic, retain) NSMutableArray *_markers;
@property (nonatomic, assign) NSInteger _p;
@property (nonatomic, assign) NSInteger _skip;
@property (nonatomic, assign, readonly) BOOL _isSpeculating;
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSCountedSet *_resyncSet;

- (NSInteger)tokenKindForString:(NSString *)s;
- (BOOL)lookahead:(NSInteger)x predicts:(NSInteger)tokenKind;

- (void)_discard;
- (void)_attemptSingleTokenInsertionDeletion:(NSInteger)tokenKind;

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
    self.tokenizer = nil;
    self.assembly = nil;
    self._exception = nil;
    self._assembler = nil;
    self._lookahead = nil;
    self._markers = nil;
    self._tokenKindTab = nil;
    self._resyncSet = nil;
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

    id result = [self _parseWithTokenizer:t assembler:a error:outError];
    
    [input close];
    [input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    return result;
}


- (id)parseString:(NSString *)input assembler:(id)a error:(NSError **)outError {
    NSParameterAssert(input);

    PKTokenizer *t = [PKTokenizer tokenizerWithString:input];
    
    id result = [self _parseWithTokenizer:t assembler:a error:outError];
    return result;
}


- (id)_parseWithTokenizer:(PKTokenizer *)t assembler:(id)a error:(NSError **)outError {
    id result = nil;
    
    // setup
    self._assembler = a;
    self.tokenizer = t;
    self.assembly = [PKSTokenAssembly assemblyWithTokenizer:_tokenizer];
    
    self.tokenizer.delegate = self;
    
    // setup speculation
    self._p = 0;
    self._lookahead = [NSMutableArray array];
    self._markers = [NSMutableArray array];

    if (_enableAutomaticErrorRecovery) {
        self._skip = 0;
        self._resyncSet = [NSCountedSet set];
    }

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
        self.tokenizer.delegate = nil;
        self.tokenizer = nil;
        self._assembler = nil;
        self.assembly = nil;
        self._lookahead = nil;
        self._markers = nil;
    }
    
    return result;
}


- (void)match:(NSInteger)tokenKind discard:(BOOL)discard {
    NSParameterAssert(tokenKind != TOKEN_KIND_BUILTIN_EOF);
    NSParameterAssert(tokenKind != TOKEN_KIND_BUILTIN_INVALID);
    NSAssert(_lookahead, @"");
    
    // always match empty without consuming
    if (TOKEN_KIND_BUILTIN_EMPTY == tokenKind) return;

    if (_skip > 0) {
        self._skip--;
    } else {
        [self _attemptSingleTokenInsertionDeletion:tokenKind];
    }

    if (_skip > 0) {
        // skip

    } else {
        PKToken *lt = LT(1); //NSLog(@"%@", lt);
        
        BOOL matches = lt.tokenKind == tokenKind || TOKEN_KIND_BUILTIN_ANY == tokenKind;

        if (matches) {
            [self consume:lt];
            if (discard) [self _discard];
        } else {
            [self raise:@"expecting %ld; found %@", tokenKind, lt];
        }
    }
}


- (void)consume:(PKToken *)tok {
    if (!self._isSpeculating) {
        [_assembly consume:tok];
        //NSLog(@"%@", _assembly);
    }

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


- (void)_discard {
    if (self._isSpeculating) return;
    
    NSAssert(![_assembly isStackEmpty], @"");
    [_assembly pop];
}


- (void)fireAssemblerSelector:(SEL)sel {
    if (self._isSpeculating) return;
    
    if (_assembler && [_assembler respondsToSelector:sel]) {
        [_assembler performSelector:sel withObject:self withObject:_assembly];
    }
}


- (PKToken *)LT:(NSInteger)i {
    PKToken *tok = nil;
    
    for (;;) {
        [self _sync:i];

        NSUInteger idx = _p + i - 1;
        NSAssert(idx < [_lookahead count], @"");
        
        tok = _lookahead[idx];
        if (_silentlyConsumesWhitespace && tok.isWhitespace) {
            [self consume:tok];
        } else {
            //NSLog(@"LT(%ld) : %@", i, [tok debugDescription]);
            break;
        }
    }
    
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
    for (NSInteger i = 0; i <= n; ++i) { // <= ?? fetches an extra lookahead tok
        PKToken *tok = [_tokenizer nextToken];

        // set token kind
        if (TOKEN_KIND_BUILTIN_INVALID == tok.tokenKind) {
            tok.tokenKind = [self _tokenKindForToken:tok];
        }
        
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


- (void)_attemptSingleTokenInsertionDeletion:(NSInteger)tokenKind {
    NSParameterAssert(TOKEN_KIND_BUILTIN_INVALID != tokenKind);

    if (_enableAutomaticErrorRecovery && LA(1) != tokenKind) {
        if (LA(2) == tokenKind) {
            [self consume:LT(1)]; // single token deletion
        } else {
            self._skip++; // single token insertion
        }
    }
}


- (void)pushFollow:(NSInteger)tokenKind {
    NSParameterAssert(TOKEN_KIND_BUILTIN_INVALID != tokenKind);
    if (!_enableAutomaticErrorRecovery) return;
    
    NSAssert(_resyncSet, @"");
    [_resyncSet addObject:@(tokenKind)];
}


- (void)popFollow:(NSInteger)tokenKind {
    NSParameterAssert(TOKEN_KIND_BUILTIN_INVALID != tokenKind);
    if (!_enableAutomaticErrorRecovery) return;

    NSAssert(_resyncSet, @"");
    [_resyncSet removeObject:@(tokenKind)];
}


- (BOOL)resync {
//    NSParameterAssert(TOKEN_KIND_BUILTIN_INVALID != tokenKind);

    BOOL result = NO;
    if (_enableAutomaticErrorRecovery) {
        while (LT(1) != [PKToken EOFToken]) {
            NSAssert([_resyncSet count], @"");
            result = [_resyncSet containsObject:@(LA(1))];

            if (result) break;
            [self consume:LT(1)];
        }
    }
    
    return result;
}


- (BOOL)predicts:(NSInteger)firstTokenKind, ... {
    NSParameterAssert(firstTokenKind != TOKEN_KIND_BUILTIN_INVALID);
    
    NSInteger la = LA(1);
    
    if ([self lookahead:la predicts:firstTokenKind]) {
        return YES;
    }
    
    BOOL result = NO;
    
    va_list vargs;
    va_start(vargs, firstTokenKind);
    
    int nextTokenKind;
    while ((nextTokenKind = va_arg(vargs, int))) {
        if ([self lookahead:la predicts:nextTokenKind]) {
            result = YES;
            break;
        }
    }
    
    va_end(vargs);
    
    return result;
}


- (BOOL)lookahead:(NSInteger)la predicts:(NSInteger)tokenKind {
    BOOL result = NO;
    
    if (TOKEN_KIND_BUILTIN_ANY == tokenKind && la != TOKEN_KIND_BUILTIN_EOF) {
        result = YES;
    } else if (la == tokenKind) {
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
    id obj = [self.assembly pop];
    return [obj boolValue];
}


- (NSInteger)_popInteger {
    id obj = [self.assembly pop];
    return [obj integerValue];
}


- (double)_popDouble {
    id obj = [self.assembly pop];
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return [obj doubleValue];
    } else {
        return [(PKToken *)obj floatValue];
    }
}


- (PKToken *)_popToken {
    PKToken *tok = [self.assembly pop];
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    return tok;
}


- (NSString *)_popString {
    id obj = [self.assembly pop];
    if ([obj respondsToSelector:@selector(stringValue)]) {
        return [obj stringValue];
    } else {
        return [obj description];
    }
}


- (void)_pushBool:(BOOL)yn {
    [self.assembly push:(id)(yn ? kCFBooleanTrue : kCFBooleanFalse)];
}


- (void)_pushInteger:(NSInteger)i {
    [self.assembly push:@(i)];
}


- (void)_pushDouble:(double)d {
    [self.assembly push:@(d)];
}


- (void)_start {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)matchEOF:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_EOF discard:discard];
}


- (void)matchAny:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_ANY discard:discard];
}


- (void)matchEmpty:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
}


- (void)matchWord:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_WORD discard:discard];
}


- (void)matchNumber:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_NUMBER discard:discard];
}


- (void)matchSymbol:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_SYMBOL discard:discard];
}


- (void)matchComment:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_COMMENT discard:discard];
}


- (void)matchWhitespace:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_WHITESPACE discard:discard];
}


- (void)matchQuotedString:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_QUOTEDSTRING discard:discard];
}


- (void)matchDelimitedString:(BOOL)discard {
	//NSLog(@"%s", _PRETTY_FUNCTION_);
    
    [self match:TOKEN_KIND_BUILTIN_DELIMITEDSTRING discard:discard];
}

@synthesize _exception = _exception;
@synthesize _assembler = _assembler;
@synthesize _lookahead = _lookahead;
@synthesize _markers = _markers;
@synthesize _p = _p;
@synthesize _skip = _skip;
@synthesize _tokenKindTab = _tokenKindTab;
@synthesize _resyncSet = _resyncSet;
@end
