#import "SemanticPredicateParser.h"
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

#define MATCHES(pattern, str)               ([[NSRegularExpression regularExpressionWithPattern:(pattern) options:0                                  error:nil] numberOfMatchesInString:(str) options:0 range:NSMakeRange(0, [(str) length])] > 1)
#define MATCHES_IGNORE_CASE(pattern, str)   ([[NSRegularExpression regularExpressionWithPattern:(pattern) options:NSRegularExpressionCaseInsensitive error:nil] numberOfMatchesInString:(str) options:0 range:NSMakeRange(0, [(str) length])] > 1)

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;
@property (nonatomic, retain) NSString *_startRuleName;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface SemanticPredicateParser ()
@property (nonatomic, retain) NSMutableDictionary *start_memo;
@property (nonatomic, retain) NSMutableDictionary *nonReserved_memo;
@end

@implementation SemanticPredicateParser

- (id)init {
    self = [super init];
    if (self) {
        self._startRuleName = @"start";


        self.start_memo = [NSMutableDictionary dictionary];
        self.nonReserved_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.start_memo = nil;
    self.nonReserved_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_start_memo removeAllObjects];
    [_nonReserved_memo removeAllObjects];
}

- (void)_start {
    [self start];
}

- (void)__start {
    
    do {
        [self nonReserved]; 
    } while ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]);
    [self matchEOF:YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStart:)];
}

- (void)start {
    [self parseRule:@selector(__start) withMemo:_start_memo];
}

- (void)__nonReserved {
    
    [self testAndThrow:(id)^{ return ![@[@"goto", @"const"] containsObject:LS(1)]; }]; 
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNonReserved:)];
}

- (void)nonReserved {
    [self parseRule:@selector(__nonReserved) withMemo:_nonReserved_memo];
}

@end