#import "ElementAssignParser.h"
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

@interface ElementAssignParser ()
@property (nonatomic, retain) NSMutableDictionary *stat_memo;
@property (nonatomic, retain) NSMutableDictionary *assign_memo;
@property (nonatomic, retain) NSMutableDictionary *list_memo;
@property (nonatomic, retain) NSMutableDictionary *elements_memo;
@property (nonatomic, retain) NSMutableDictionary *element_memo;
@property (nonatomic, retain) NSMutableDictionary *lbracket_memo;
@property (nonatomic, retain) NSMutableDictionary *rbracket_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *eq_memo;
@property (nonatomic, retain) NSMutableDictionary *dot_memo;
@property (nonatomic, retain) NSMutableDictionary *semi_memo;
@end

@implementation ElementAssignParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"]"] = @(TOKEN_KIND_RBRACKET);
        self._tokenKindTab[@"["] = @(TOKEN_KIND_LBRACKET);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQ);
        self._tokenKindTab[@";"] = @(TOKEN_KIND_SEMI);
        self._tokenKindTab[@"."] = @(TOKEN_KIND_DOT);
    }
	return self;
}

- (void)dealloc {
    self.stat_memo = nil;
    self.assign_memo = nil;
    self.list_memo = nil;
    self.elements_memo = nil;
    self.element_memo = nil;
    self.lbracket_memo = nil;
    self.rbracket_memo = nil;
    self.comma_memo = nil;
    self.eq_memo = nil;
    self.dot_memo = nil;
    self.semi_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [self.stat_memo removeAllObjects];
    [self.assign_memo removeAllObjects];
    [self.list_memo removeAllObjects];
    [self.elements_memo removeAllObjects];
    [self.element_memo removeAllObjects];
    [self.lbracket_memo removeAllObjects];
    [self.rbracket_memo removeAllObjects];
    [self.comma_memo removeAllObjects];
    [self.eq_memo removeAllObjects];
    [self.dot_memo removeAllObjects];
    [self.semi_memo removeAllObjects];
}

- (void)_start {
    
    [self stat]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__stat {
    
    if ([self speculate:^{ [self assign]; [self dot]; }]) {
        [self assign]; 
        [self dot]; 
    } else if ([self speculate:^{ [self list]; [self semi]; }]) {
        [self list]; 
        [self semi]; 
    } else {
        [self raise:@"no viable alternative found in stat"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)stat {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.stat_memo]) return;
    @try {
        [self __stat];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.stat_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__assign {
    
    [self list]; 
    [self eq]; 
    [self list]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)assign {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.assign_memo]) return;
    @try {
        [self __assign];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.assign_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__list {
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)list {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.list_memo]) return;
    @try {
        [self __list];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.list_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__elements {
    
    [self element]; 
    while (LA(1) == TOKEN_KIND_COMMA) {
        if ([self speculate:^{ [self comma]; [self element]; }]) {
            [self comma]; 
            [self element]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)elements {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.elements_memo]) return;
    @try {
        [self __elements];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.elements_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__element {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self Number]; 
    } else if (LA(1) == TOKEN_KIND_LBRACKET) {
        [self list]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)element {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.element_memo]) return;
    @try {
        [self __element];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.element_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__lbracket {
    
    [self match:TOKEN_KIND_LBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)lbracket {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.lbracket_memo]) return;
    @try {
        [self __lbracket];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.lbracket_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__rbracket {
    
    [self match:TOKEN_KIND_RBRACKET]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)rbracket {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.rbracket_memo]) return;
    @try {
        [self __rbracket];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.rbracket_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__comma {
    
    [self match:TOKEN_KIND_COMMA]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)comma {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.comma_memo]) return;
    @try {
        [self __comma];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.comma_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__eq {
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)eq {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.eq_memo]) return;
    @try {
        [self __eq];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.eq_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__dot {
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)dot {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.dot_memo]) return;
    @try {
        [self __dot];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.dot_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__semi {
    
    [self match:TOKEN_KIND_SEMI]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

- (void)semi {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.semi_memo]) return;
    @try {
        [self __semi];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.semi_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end