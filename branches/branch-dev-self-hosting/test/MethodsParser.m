#import "MethodsParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self._assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self._assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self._assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *_assembly;
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@end

@interface MethodsParser ()
@property (nonatomic, retain) NSMutableDictionary *method_memo;
@property (nonatomic, retain) NSMutableDictionary *type_memo;
@property (nonatomic, retain) NSMutableDictionary *args_memo;
@property (nonatomic, retain) NSMutableDictionary *arg_memo;
@end

@implementation MethodsParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"int"] = @(TOKEN_KIND_INT);
        self._tokenKindTab[@"}"] = @(TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"void"] = @(TOKEN_KIND_VOID);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"{"] = @(TOKEN_KIND_OPEN_CURLY);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@";"] = @(TOKEN_KIND_SEMI_COLON);

        self.method_memo = [NSMutableDictionary dictionary];
        self.type_memo = [NSMutableDictionary dictionary];
        self.args_memo = [NSMutableDictionary dictionary];
        self.arg_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.method_memo = nil;
    self.type_memo = nil;
    self.args_memo = nil;
    self.arg_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_method_memo removeAllObjects];
    [_type_memo removeAllObjects];
    [_args_memo removeAllObjects];
    [_arg_memo removeAllObjects];
}

- (void)_start {
    
    do {
        [self method]; 
    } while ((LA(1) == TOKEN_KIND_INT || LA(1) == TOKEN_KIND_VOID) && ([self speculate:^{ [self method]; }]));

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__method {
    
    if ([self speculate:^{ [self testAndThrow:(id)^{ return NO; }]; [self type]; [self Word]; [self match:TOKEN_KIND_OPEN_PAREN]; [self args]; [self match:TOKEN_KIND_CLOSE_PAREN]; [self match:TOKEN_KIND_SEMI_COLON]; }]) {
        [self type]; 
        [self Word]; 
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self args]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
        [self match:TOKEN_KIND_SEMI_COLON]; 
    } else if ([self speculate:^{ [self testAndThrow:(id)^{ return 1; }]; [self type]; [self Word]; [self match:TOKEN_KIND_OPEN_PAREN]; [self args]; [self match:TOKEN_KIND_CLOSE_PAREN]; [self match:TOKEN_KIND_OPEN_CURLY]; [self match:TOKEN_KIND_CLOSE_CURLY]; }]) {
        [self type]; 
        [self Word]; 
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self args]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
        [self match:TOKEN_KIND_OPEN_CURLY]; 
        [self match:TOKEN_KIND_CLOSE_CURLY]; 
    } else {
        [self raise:@"no viable alternative found in method"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMethod:)];
}

- (void)method {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_method_memo]) return;
    @try {
        [self __method];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_method_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__type {
    
    if (LA(1) == TOKEN_KIND_VOID) {
        [self match:TOKEN_KIND_VOID]; 
    } else if (LA(1) == TOKEN_KIND_INT) {
        [self match:TOKEN_KIND_INT]; 
    } else {
        [self raise:@"no viable alternative found in type"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchType:)];
}

- (void)type {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_type_memo]) return;
    @try {
        [self __type];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_type_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__args {
    
    if (LA(1) == TOKEN_KIND_INT) {
        [self arg]; 
        while (LA(1) == TOKEN_KIND_COMMA) {
            if ([self speculate:^{ [self match:TOKEN_KIND_COMMA]; [self arg]; }]) {
                [self match:TOKEN_KIND_COMMA]; 
                [self arg]; 
            } else {
                break;
            }
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgs:)];
}

- (void)args {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_args_memo]) return;
    @try {
        [self __args];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_args_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__arg {
    
    [self match:TOKEN_KIND_INT]; 
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchArg:)];
}

- (void)arg {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_arg_memo]) return;
    @try {
        [self __arg];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_arg_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end