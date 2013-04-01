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
@end

@interface MiniMathParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation MiniMathParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"+" : @(TOKEN_KIND_PLUS),
           @"*" : @(TOKEN_KIND_STAR),
           @"^" : @(TOKEN_KIND_CARET),
        };
	}
	return self;
}

- (void)dealloc {
	self._tokenKindTab = nil;
	[super dealloc];
}

- (NSInteger)tokenKindForString:(NSString *)s {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[s];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)_start {
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
    
    [self mult]; 
    while (LA(1) == TOKEN_KIND_PLUS) {
        if ([self speculate:^{ [self match:TOKEN_KIND_PLUS]; [self discard:1];[self mult]; [self execute:(id)^{ PUSH_FLOAT(POP_FLOAT()+POP_FLOAT()); }];}]) {
            [self match:TOKEN_KIND_PLUS]; [self discard:1];
            [self mult]; 
            [self execute:(id)^{
                 PUSH_FLOAT(POP_FLOAT()+POP_FLOAT()); 
            }];
        } else {
            return;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)mult {
    
    [self pow]; 
    while (LA(1) == TOKEN_KIND_STAR) {
        if ([self speculate:^{ [self match:TOKEN_KIND_STAR]; [self discard:1];[self pow]; [self execute:(id)^{ PUSH_FLOAT(POP_FLOAT()*POP_FLOAT()); }];}]) {
            [self match:TOKEN_KIND_STAR]; [self discard:1];
            [self pow]; 
            [self execute:(id)^{
                 PUSH_FLOAT(POP_FLOAT()*POP_FLOAT()); 
            }];
        } else {
            return;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMult:)];
}

- (void)pow {
    
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

- (void)atom {
    
    [self Number]; 
    [self execute:(id)^{
        PUSH_FLOAT(POP_FLOAT());
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end