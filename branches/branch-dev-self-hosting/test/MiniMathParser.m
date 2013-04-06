#import "MiniMathParser.h"
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

@interface MiniMathParser ()
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *mult_memo;
@property (nonatomic, retain) NSMutableDictionary *pow_memo;
@property (nonatomic, retain) NSMutableDictionary *atom_memo;
@end

@implementation MiniMathParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"+"] = @(TOKEN_KIND_PLUS);
        self._tokenKindTab[@"*"] = @(TOKEN_KIND_STAR);
        self._tokenKindTab[@"^"] = @(TOKEN_KIND_CARET);

        self.expr_memo = [NSMutableDictionary dictionary];
        self.mult_memo = [NSMutableDictionary dictionary];
        self.pow_memo = [NSMutableDictionary dictionary];
        self.atom_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.expr_memo = nil;
    self.mult_memo = nil;
    self.pow_memo = nil;
    self.atom_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_expr_memo removeAllObjects];
    [_mult_memo removeAllObjects];
    [_pow_memo removeAllObjects];
    [_atom_memo removeAllObjects];
}

- (void)_start {
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__expr {
    
    [self mult]; 
    while (LA(1) == TOKEN_KIND_PLUS) {
        if ([self speculate:^{ [self match:TOKEN_KIND_PLUS]; [self discard:1];[self mult]; [self execute:(id)^{ PUSH_FLOAT(POP_FLOAT()+POP_FLOAT()); }];}]) {
            [self match:TOKEN_KIND_PLUS]; [self discard:1];
            [self mult]; 
            [self execute:(id)^{
                 PUSH_FLOAT(POP_FLOAT()+POP_FLOAT()); 
            }];
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)expr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_expr_memo]) return;
    @try {
        [self __expr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_expr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__mult {
    
    [self pow]; 
    while (LA(1) == TOKEN_KIND_STAR) {
        if ([self speculate:^{ [self match:TOKEN_KIND_STAR]; [self discard:1];[self pow]; [self execute:(id)^{ PUSH_FLOAT(POP_FLOAT()*POP_FLOAT()); }];}]) {
            [self match:TOKEN_KIND_STAR]; [self discard:1];
            [self pow]; 
            [self execute:(id)^{
                 PUSH_FLOAT(POP_FLOAT()*POP_FLOAT()); 
            }];
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMult:)];
}

- (void)mult {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_mult_memo]) return;
    @try {
        [self __mult];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_mult_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__pow {
    
    [self atom]; 
    if ((LA(1) == TOKEN_KIND_CARET) && ([self speculate:^{ [self match:TOKEN_KIND_CARET]; [self discard:1];[self pow]; [self execute:(id)^{ 		double exp = POP_FLOAT();		double base = POP_FLOAT();		double result = base;	for (NSUInteger i = 1; i < exp; i++) 			result *= base;		PUSH_FLOAT(result); 	}];}])) {
        [self match:TOKEN_KIND_CARET]; [self discard:1];
        [self pow]; 
        [self execute:(id)^{
             
		double exp = POP_FLOAT();
		double base = POP_FLOAT();
		double result = base;
	    for (NSUInteger i = 1; i < exp; i++) 
			result *= base;
		PUSH_FLOAT(result); 
	
        }];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPow:)];
}

- (void)pow {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_pow_memo]) return;
    @try {
        [self __pow];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_pow_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__atom {
    
    [self Number]; 
    [self execute:(id)^{
        PUSH_FLOAT(POP_FLOAT());
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)atom {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_atom_memo]) return;
    @try {
        [self __atom];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_atom_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end