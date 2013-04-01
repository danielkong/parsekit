#import "LabelEBNFParser.h"
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

@interface LabelEBNFParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation LabelEBNFParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"=" : @(TOKEN_KIND_EQUALS),
           @"return" : @(TOKEN_KIND_RETURN),
           @":" : @(TOKEN_KIND_COLON),
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
    
    [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)s {
    
    if ([self speculate:^{ [self label]; [self Word]; [self match:TOKEN_KIND_EQUALS]; [self expr]; }]) {
        [self label]; 
        [self Word]; 
        [self match:TOKEN_KIND_EQUALS]; 
        [self expr]; 
    } else if ([self speculate:^{ [self label]; [self match:TOKEN_KIND_RETURN]; [self expr]; }]) {
        [self label]; 
        [self match:TOKEN_KIND_RETURN]; 
        [self expr]; 
    } else {
        [self raise:@"no viable alternative found in s"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchS:)];
}

- (void)label {
    
    while (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self Word]; 
        [self match:TOKEN_KIND_COLON]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLabel:)];
}

- (void)expr {
    
    [self Number]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end