#import "OptionalParser.h"
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

@interface OptionalParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation OptionalParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"foo" : @(TOKEN_KIND_FOO),
           @"bar" : @(TOKEN_KIND_BAR),
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
    
    if (LA(1) == TOKEN_KIND_FOO) {
        [self expr]; 
    }
    [self foo]; 
    [self bar]; 

    [self fireAssemblerSelector:@selector(parser:didMatchS:)];
}

- (void)expr {
    
    [self foo]; 
    [self bar]; 
    [self bar]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)foo {
    
    [self match:TOKEN_KIND_FOO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFoo:)];
}

- (void)bar {
    
    [self match:TOKEN_KIND_BAR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBar:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end