#import "NegationParser.h"
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

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface NegationParser ()
@end

@implementation NegationParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"foo"] = @(TOKEN_KIND_FOO);

    }
	return self;
}


- (void)_start {
    
    [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)s {
    
    if (![self predicts:TOKEN_KIND_FOO]) {
        [self match:TOKEN_KIND_BUILTIN_ANY];
    } else {
        [self raise:@"negation test failed in s"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchS:)];
}

- (void)foo {
    
    [self match:TOKEN_KIND_FOO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFoo:)];
}

@end