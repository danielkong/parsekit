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
@end

@interface NegationParser ()
@property (nonatomic, retain) NSMutableDictionary *s_memo;
@property (nonatomic, retain) NSMutableDictionary *foo_memo;
@end

@implementation NegationParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"foo"] = @(TOKEN_KIND_FOO);

        self.s_memo = [NSMutableDictionary dictionary];
        self.foo_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.s_memo = nil;
    self.foo_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_s_memo removeAllObjects];
    [_foo_memo removeAllObjects];
}

- (void)_start {
    
    [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__s {
    
    if (LA(1) != TOKEN_KIND_FOO) {
        [self match:TOKEN_KIND_BUILTIN_ANY];
    } else {
        [self raise:@"negation test failed in s"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchS:)];
}

- (void)s {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_s_memo]) return;
    @try {
        [self __s];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_s_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__foo {
    
    [self match:TOKEN_KIND_FOO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFoo:)];
}

- (void)foo {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_foo_memo]) return;
    @try {
        [self __foo];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_foo_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end