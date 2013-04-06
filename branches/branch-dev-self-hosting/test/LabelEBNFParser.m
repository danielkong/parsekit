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
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@end

@interface LabelEBNFParser ()
@property (nonatomic, retain) NSMutableDictionary *s_memo;
@property (nonatomic, retain) NSMutableDictionary *label_memo;
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@end

@implementation LabelEBNFParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQUALS);
        self._tokenKindTab[@"return"] = @(TOKEN_KIND_RETURN);
        self._tokenKindTab[@":"] = @(TOKEN_KIND_COLON);
    }
	return self;
}

- (void)dealloc {
    self.s_memo = nil;
    self.label_memo = nil;
    self.expr_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [self.s_memo removeAllObjects];
    [self.label_memo removeAllObjects];
    [self.expr_memo removeAllObjects];
}

- (void)_start {
    
    [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__s {
    
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

- (void)__label {
    
    while (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        if ([self speculate:^{ [self Word]; [self match:TOKEN_KIND_COLON]; }]) {
            [self Word]; 
            [self match:TOKEN_KIND_COLON]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLabel:)];
}

- (void)label {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.label_memo]) return;
    @try {
        [self __label];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.label_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

- (void)__expr {
    
    [self Number]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)expr {
    BOOL failed = NO;
    NSInteger startTokenIndex = [self _index];
    if (self._isSpeculating && [self alreadyParsedRule:self.expr_memo]) return;
    @try {
        [self __expr];
    }
    @catch (PKSRecognitionException *ex) {
        failed = YES;
        @throw ex;
    }
    @finally {
        if (self._isSpeculating) {
            [self memoize:self.expr_memo atIndex:startTokenIndex failed:failed];
        }
    }
}

@end