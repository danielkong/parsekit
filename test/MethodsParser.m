#import "MethodsParser.h"
#import <ParseKit/ParseKit.h>
#import <ParseKit/PKSRecognitionException.h>

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self.assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self.assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
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
    } while ([self speculate:^{ [self method]; }]);

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__method {
    
    if ([self speculate:^{ [self testAndThrow:(id)^{ return NO; }]; [self type]; [self Word]; [self match:TOKEN_KIND_OPEN_PAREN]; [self args]; [self match:TOKEN_KIND_CLOSE_PAREN]; [self match:TOKEN_KIND_SEMI_COLON]; }]) {
        [self testAndThrow:(id)^{ return NO; }]; 
        [self type]; 
        [self Word]; 
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self args]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
        [self match:TOKEN_KIND_SEMI_COLON]; 
    } else if ([self speculate:^{ [self testAndThrow:(id)^{ return 1; }]; [self type]; [self Word]; [self match:TOKEN_KIND_OPEN_PAREN]; [self args]; [self match:TOKEN_KIND_CLOSE_PAREN]; [self match:TOKEN_KIND_OPEN_CURLY]; [self match:TOKEN_KIND_CLOSE_CURLY]; }]) {
        [self testAndThrow:(id)^{ return 1; }]; 
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
    [self parseRule:@selector(__method) withMemo:_method_memo];
}

- (void)__type {
    
    if ([self predicts:TOKEN_KIND_VOID, 0]) {
        [self match:TOKEN_KIND_VOID]; 
    } else if ([self predicts:TOKEN_KIND_INT, 0]) {
        [self match:TOKEN_KIND_INT]; 
    } else {
        [self raise:@"no viable alternative found in type"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchType:)];
}

- (void)type {
    [self parseRule:@selector(__type) withMemo:_type_memo];
}

- (void)__args {
    
    if ([self predicts:TOKEN_KIND_INT, 0]) {
        [self arg]; 
        while ([self predicts:TOKEN_KIND_COMMA, 0]) {
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
    [self parseRule:@selector(__args) withMemo:_args_memo];
}

- (void)__arg {
    
    [self match:TOKEN_KIND_INT]; 
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchArg:)];
}

- (void)arg {
    [self parseRule:@selector(__arg) withMemo:_arg_memo];
}

@end