#import "DotQuestionParser.h"
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

@interface DotQuestionParser ()
@property (nonatomic, retain) NSMutableDictionary *start_memo;
@property (nonatomic, retain) NSMutableDictionary *a_memo;
@end

@implementation DotQuestionParser

- (id)init {
    self = [super init];
    if (self) {
        self._tokenKindTab[@"a"] = @(DOTQUESTION_TOKEN_KIND_A);

        self._tokenKindNameTab[DOTQUESTION_TOKEN_KIND_A] = @"a";

        self.start_memo = [NSMutableDictionary dictionary];
        self.a_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.start_memo = nil;
    self.a_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_start_memo removeAllObjects];
    [_a_memo removeAllObjects];
}

- (void)_start {
    [self start];
}

- (void)__start {
    
    [self a]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_ANY, 0]) {
        [self matchAny:NO]; 
    }
    [self a]; 
    [self matchEOF:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStart:)];
}

- (void)start {
    [self parseRule:@selector(__start) withMemo:_start_memo];
}

- (void)__a {
    
    [self match:DOTQUESTION_TOKEN_KIND_A discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchA:)];
}

- (void)a {
    [self parseRule:@selector(__a) withMemo:_a_memo];
}

@end