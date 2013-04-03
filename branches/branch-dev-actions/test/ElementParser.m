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
@end

@interface ElementParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation ElementParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
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
    
    @try {
        [self list]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)list {
    
    @try {
        [self lbracket]; 
        [self elements]; 
        [self rbracket]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
    
    @try {
        [self element]; 
        while (LA(1) == TOKEN_KIND_COMMA) {
            if ([self speculate:^{ [self comma]; [self element]; }]) {
                [self comma]; 
                [self element]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
            [self Number]; 
        } else if (LA(1) == TOKEN_KIND_LBRACKET) {
            [self list]; 
        } else {
            [self raise:@"no viable alternative found in element"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
    
    @try {
        [self match:TOKEN_KIND_LBRACKET]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
    
    @try {
        [self match:TOKEN_KIND_RBRACKET]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
    
    @try {
        [self match:TOKEN_KIND_COMMA]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end