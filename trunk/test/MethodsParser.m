#import "MethodsParser.h"
#import <ParseKit/ParseKit.h>

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

#define MATCHES(pattern, str)               ([[NSRegularExpression regularExpressionWithPattern:(pattern) options:0                                  error:nil] numberOfMatchesInString:(str) options:0 range:NSMakeRange(0, [(str) length])] > 0)
#define MATCHES_IGNORE_CASE(pattern, str)   ([[NSRegularExpression regularExpressionWithPattern:(pattern) options:NSRegularExpressionCaseInsensitive error:nil] numberOfMatchesInString:(str) options:0 range:NSMakeRange(0, [(str) length])] > 0)

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;
@property (nonatomic, retain) NSString *_startRuleName;
@property (nonatomic, retain) NSString *_statementTerminator;

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
@property (nonatomic, retain) NSMutableDictionary *start_memo;
@property (nonatomic, retain) NSMutableDictionary *method_memo;
@property (nonatomic, retain) NSMutableDictionary *type_memo;
@property (nonatomic, retain) NSMutableDictionary *args_memo;
@property (nonatomic, retain) NSMutableDictionary *arg_memo;
@end

@implementation MethodsParser

- (id)init {
    self = [super init];
    if (self) {
        self._startRuleName = @"start";
        self._tokenKindTab[@"int"] = @(METHODS_TOKEN_KIND_INT);
        self._tokenKindTab[@"}"] = @(METHODS_TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@","] = @(METHODS_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"void"] = @(METHODS_TOKEN_KIND_VOID);
        self._tokenKindTab[@"("] = @(METHODS_TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"{"] = @(METHODS_TOKEN_KIND_OPEN_CURLY);
        self._tokenKindTab[@")"] = @(METHODS_TOKEN_KIND_CLOSE_PAREN);
        self._tokenKindTab[@";"] = @(METHODS_TOKEN_KIND_SEMI_COLON);

        self._tokenKindNameTab[METHODS_TOKEN_KIND_INT] = @"int";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_CLOSE_CURLY] = @"}";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_COMMA] = @",";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_VOID] = @"void";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_OPEN_PAREN] = @"(";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_OPEN_CURLY] = @"{";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_CLOSE_PAREN] = @")";
        self._tokenKindNameTab[METHODS_TOKEN_KIND_SEMI_COLON] = @";";

        self.start_memo = [NSMutableDictionary dictionary];
        self.method_memo = [NSMutableDictionary dictionary];
        self.type_memo = [NSMutableDictionary dictionary];
        self.args_memo = [NSMutableDictionary dictionary];
        self.arg_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.start_memo = nil;
    self.method_memo = nil;
    self.type_memo = nil;
    self.args_memo = nil;
    self.arg_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_start_memo removeAllObjects];
    [_method_memo removeAllObjects];
    [_type_memo removeAllObjects];
    [_args_memo removeAllObjects];
    [_arg_memo removeAllObjects];
}

- (void)_start {
    [self start];
}

- (void)__start {
    
    do {
        [self method]; 
    } while ([self speculate:^{ [self method]; }]);
    [self matchEOF:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStart:)];
}

- (void)start {
    [self parseRule:@selector(__start) withMemo:_start_memo];
}

- (void)__method {
    
    if ([self speculate:^{ [self testAndThrow:(id)^{ return NO; }]; [self type]; [self matchWord:NO]; [self match:METHODS_TOKEN_KIND_OPEN_PAREN discard:NO]; [self args]; [self match:METHODS_TOKEN_KIND_CLOSE_PAREN discard:NO]; [self match:METHODS_TOKEN_KIND_SEMI_COLON discard:NO]; }]) {
        [self testAndThrow:(id)^{ return NO; }]; 
        [self type]; 
        [self matchWord:NO]; 
        [self match:METHODS_TOKEN_KIND_OPEN_PAREN discard:NO]; 
        [self args]; 
        [self match:METHODS_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
        [self match:METHODS_TOKEN_KIND_SEMI_COLON discard:NO]; 
    } else if ([self speculate:^{ [self testAndThrow:(id)^{ return 1; }]; [self type]; [self matchWord:NO]; [self match:METHODS_TOKEN_KIND_OPEN_PAREN discard:NO]; [self args]; [self match:METHODS_TOKEN_KIND_CLOSE_PAREN discard:NO]; [self match:METHODS_TOKEN_KIND_OPEN_CURLY discard:NO]; [self match:METHODS_TOKEN_KIND_CLOSE_CURLY discard:NO]; }]) {
        [self testAndThrow:(id)^{ return 1; }]; 
        [self type]; 
        [self matchWord:NO]; 
        [self match:METHODS_TOKEN_KIND_OPEN_PAREN discard:NO]; 
        [self args]; 
        [self match:METHODS_TOKEN_KIND_CLOSE_PAREN discard:NO]; 
        [self match:METHODS_TOKEN_KIND_OPEN_CURLY discard:NO]; 
        [self match:METHODS_TOKEN_KIND_CLOSE_CURLY discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'method'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMethod:)];
}

- (void)method {
    [self parseRule:@selector(__method) withMemo:_method_memo];
}

- (void)__type {
    
    if ([self predicts:METHODS_TOKEN_KIND_VOID, 0]) {
        [self match:METHODS_TOKEN_KIND_VOID discard:NO]; 
    } else if ([self predicts:METHODS_TOKEN_KIND_INT, 0]) {
        [self match:METHODS_TOKEN_KIND_INT discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'type'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchType:)];
}

- (void)type {
    [self parseRule:@selector(__type) withMemo:_type_memo];
}

- (void)__args {
    
    if ([self predicts:METHODS_TOKEN_KIND_INT, 0]) {
        [self arg]; 
        while ([self speculate:^{ [self match:METHODS_TOKEN_KIND_COMMA discard:NO]; [self arg]; }]) {
            [self match:METHODS_TOKEN_KIND_COMMA discard:NO]; 
            [self arg]; 
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgs:)];
}

- (void)args {
    [self parseRule:@selector(__args) withMemo:_args_memo];
}

- (void)__arg {
    
    [self match:METHODS_TOKEN_KIND_INT discard:NO]; 
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchArg:)];
}

- (void)arg {
    [self parseRule:@selector(__arg) withMemo:_arg_memo];
}

@end