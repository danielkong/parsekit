#import "ElementParser.h"
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

@interface ElementParser ()
@property (nonatomic, retain) NSMutableDictionary *list_memo;
@property (nonatomic, retain) NSMutableDictionary *elements_memo;
@property (nonatomic, retain) NSMutableDictionary *element_memo;
@property (nonatomic, retain) NSMutableDictionary *lbracket_memo;
@property (nonatomic, retain) NSMutableDictionary *rbracket_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@end

@implementation ElementParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"["] = @(TOKEN_KIND_LBRACKET);
        self._tokenKindTab[@"]"] = @(TOKEN_KIND_RBRACKET);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
    }
	return self;
}

- (void)dealloc {
    self.list_memo = nil;
    self.elements_memo = nil;
    self.element_memo = nil;
    self.lbracket_memo = nil;
    self.rbracket_memo = nil;
    self.comma_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [self.list_memo removeAllObjects];
    [self.elements_memo removeAllObjects];
    [self.element_memo removeAllObjects];
    [self.lbracket_memo removeAllObjects];
    [self.rbracket_memo removeAllObjects];
    [self.comma_memo removeAllObjects];
}

- (void)_start {
    
    [self list]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
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

@end