#import "MultipleParser.h"
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

@interface MultipleParser ()
@property (nonatomic, retain) NSMutableDictionary *s_memo;
@property (nonatomic, retain) NSMutableDictionary *ab_memo;
@property (nonatomic, retain) NSMutableDictionary *a_memo;
@property (nonatomic, retain) NSMutableDictionary *b_memo;
@end

@implementation MultipleParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"a"] = @(TOKEN_KIND_A);
        self._tokenKindTab[@"b"] = @(TOKEN_KIND_B);
    }
	return self;
}

- (void)dealloc {
    self.s_memo = nil;
    self.ab_memo = nil;
    self.a_memo = nil;
    self.b_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [self.s_memo removeAllObjects];
    [self.ab_memo removeAllObjects];
    [self.a_memo removeAllObjects];
    [self.b_memo removeAllObjects];
}

- (void)_start {
    
    [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__s {
    
    do {
        [self ab]; 
    } while ((LA(1) == TOKEN_KIND_A) && ([self speculate:^{ [self ab]; }]));
    [self a]; 

    [self fireAssemblerSelector:@selector(parser:didMatchS:)];
}

- (void)s {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.s_memo]) return;
    @try {
        [self __s];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.s_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__ab {
    
    [self a]; 
    [self b]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAb:)];
}

- (void)ab {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.ab_memo]) return;
    @try {
        [self __ab];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.ab_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__a {
    
    [self match:TOKEN_KIND_A]; 

    [self fireAssemblerSelector:@selector(parser:didMatchA:)];
}

- (void)a {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.a_memo]) return;
    @try {
        [self __a];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.a_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__b {
    
    [self match:TOKEN_KIND_B]; 

    [self fireAssemblerSelector:@selector(parser:didMatchB:)];
}

- (void)b {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.b_memo]) return;
    @try {
        [self __b];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.b_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end