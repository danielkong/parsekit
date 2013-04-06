#import "AltParser.h"
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

@interface AltParser ()
@property (nonatomic, retain) NSMutableDictionary *s_memo;
@property (nonatomic, retain) NSMutableDictionary *a_memo;
@property (nonatomic, retain) NSMutableDictionary *b_memo;
@property (nonatomic, retain) NSMutableDictionary *foo_memo;
@property (nonatomic, retain) NSMutableDictionary *bar_memo;
@property (nonatomic, retain) NSMutableDictionary *baz_memo;
@end

@implementation AltParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"foo"] = @(TOKEN_KIND_FOO);
        self._tokenKindTab[@"bar"] = @(TOKEN_KIND_BAR);
        self._tokenKindTab[@"baz"] = @(TOKEN_KIND_BAZ);

        self.s_memo = [NSMutableDictionary dictionary];
        self.a_memo = [NSMutableDictionary dictionary];
        self.b_memo = [NSMutableDictionary dictionary];
        self.foo_memo = [NSMutableDictionary dictionary];
        self.bar_memo = [NSMutableDictionary dictionary];
        self.baz_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.s_memo = nil;
    self.a_memo = nil;
    self.b_memo = nil;
    self.foo_memo = nil;
    self.bar_memo = nil;
    self.baz_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_s_memo removeAllObjects];
    [_a_memo removeAllObjects];
    [_b_memo removeAllObjects];
    [_foo_memo removeAllObjects];
    [_bar_memo removeAllObjects];
    [_baz_memo removeAllObjects];
}

- (void)_start {
    
    [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__s {
    
    if ([self speculate:^{ [self a]; }]) {
        [self a]; 
    } else if ([self speculate:^{ [self b]; }]) {
        [self b]; 
    } else {
        [self raise:@"no viable alternative found in s"];
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

- (void)__a {
    
    [self foo]; 
    [self baz]; 

    [self fireAssemblerSelector:@selector(parser:didMatchA:)];
}

- (void)a {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_a_memo]) return;
    @try {
        [self __a];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_a_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__b {
    
    if ([self speculate:^{ [self a]; }]) {
        [self a]; 
    } else if ([self speculate:^{ [self foo]; [self bar]; }]) {
        [self foo]; 
        [self bar]; 
    } else {
        [self raise:@"no viable alternative found in b"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchB:)];
}

- (void)b {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_b_memo]) return;
    @try {
        [self __b];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_b_memo atIndex:startTokenIndex failed:failed];
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

- (void)__bar {
    
    [self match:TOKEN_KIND_BAR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBar:)];
}

- (void)bar {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_bar_memo]) return;
    @try {
        [self __bar];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_bar_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__baz {
    
    [self match:TOKEN_KIND_BAZ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBaz:)];
}

- (void)baz {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:_baz_memo]) return;
    @try {
        [self __baz];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:_baz_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end