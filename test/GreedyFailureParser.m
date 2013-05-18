#import "GreedyFailureParser.h"
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

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface GreedyFailureParser ()
@end

@implementation GreedyFailureParser

- (id)init {
    self = [super init];
    if (self) {
        self.enableAutomaticErrorRecovery = YES;

        self._tokenKindTab[@"{"] = @(GREEDYFAILURE_TOKEN_KIND_LCURLY);
        self._tokenKindTab[@"}"] = @(GREEDYFAILURE_TOKEN_KIND_RCURLY);
        self._tokenKindTab[@":"] = @(GREEDYFAILURE_TOKEN_KIND_COLON);

        self._tokenKindNameTab[GREEDYFAILURE_TOKEN_KIND_LCURLY] = @"{";
        self._tokenKindNameTab[GREEDYFAILURE_TOKEN_KIND_RCURLY] = @"}";
        self._tokenKindNameTab[GREEDYFAILURE_TOKEN_KIND_COLON] = @":";

    }
    return self;
}

- (void)_start {
    [self struct];
}

- (void)struct {
    
    [self tryAndRecover:TOKEN_KIND_BUILTIN_EOF block:^{
        [self lcurly]; 
        [self tryAndRecover:TOKEN_KIND_BUILTIN_QUOTEDSTRING block:^{ 
            [self name]; 
        } completion:^{ 
            [self name]; 
        }];
        [self colon]; 
        [self tryAndRecover:TOKEN_KIND_BUILTIN_WORD block:^{ 
            [self value]; 
        } completion:^{ 
            [self value]; 
        }];
        [self rcurly]; 
        [self matchEOF:YES]; 
    } completion:^{
        [self matchEOF:YES];
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchStruct:)];
}

- (void)name {
    
    [self matchQuotedString:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchName:)];
}

- (void)value {
    
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchValue:)];
}

- (void)lcurly {
    
    [self match:GREEDYFAILURE_TOKEN_KIND_LCURLY discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLcurly:)];
}

- (void)rcurly {
    
    [self match:GREEDYFAILURE_TOKEN_KIND_RCURLY discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchRcurly:)];
}

- (void)colon {
    
    [self match:GREEDYFAILURE_TOKEN_KIND_COLON discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchColon:)];
}

@end