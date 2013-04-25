#import "ElementAssignParser.h"
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

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface ElementAssignParser ()
@end

@implementation ElementAssignParser

- (id)init {
    self = [super init];
    if (self) {
        self.enableAutomaticErrorRecovery = YES;

        self._tokenKindTab[@"]"] = @(ELEMENTASSIGN_TOKEN_KIND_RBRACKET);
        self._tokenKindTab[@"["] = @(ELEMENTASSIGN_TOKEN_KIND_LBRACKET);
        self._tokenKindTab[@","] = @(ELEMENTASSIGN_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"="] = @(ELEMENTASSIGN_TOKEN_KIND_EQ);
        self._tokenKindTab[@";"] = @(ELEMENTASSIGN_TOKEN_KIND_SEMI);
        self._tokenKindTab[@"."] = @(ELEMENTASSIGN_TOKEN_KIND_DOT);

    }
    return self;
}


- (void)_start {
    
    [self pushFollow:TOKEN_KIND_BUILTIN_EOF];
    @try {
    do {
        [self stat]; 
    } while ([self speculate:^{ [self stat]; }]);
    [self matchEOF:YES]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
            [self matchEOF:YES];
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:TOKEN_KIND_BUILTIN_EOF];
    }

}

- (void)stat {
    
    if ([self speculate:^{ [self pushFollow:ELEMENTASSIGN_TOKEN_KIND_DOT];@try {[self assign]; [self dot]; }@catch (PKSRecognitionException *ex) {if ([self resync]) {[self dot]; } else {@throw ex;}}@finally {[self popFollow:ELEMENTASSIGN_TOKEN_KIND_DOT];}}]) {
        [self pushFollow:ELEMENTASSIGN_TOKEN_KIND_DOT];
        @try {
        [self assign]; 
        [self dot]; 
        }
        @catch (PKSRecognitionException *ex) {
            if ([self resync]) {
                [self dot]; 
            } else {
                @throw ex;
            }
        }
        @finally {
            [self popFollow:ELEMENTASSIGN_TOKEN_KIND_DOT];
        }
    } else if ([self speculate:^{ [self pushFollow:ELEMENTASSIGN_TOKEN_KIND_SEMI];@try {[self list]; [self semi]; }@catch (PKSRecognitionException *ex) {if ([self resync]) {[self semi]; } else {@throw ex;}}@finally {[self popFollow:ELEMENTASSIGN_TOKEN_KIND_SEMI];}}]) {
        [self pushFollow:ELEMENTASSIGN_TOKEN_KIND_SEMI];
        @try {
        [self list]; 
        [self semi]; 
        }
        @catch (PKSRecognitionException *ex) {
            if ([self resync]) {
                [self semi]; 
            } else {
                @throw ex;
            }
        }
        @finally {
            [self popFollow:ELEMENTASSIGN_TOKEN_KIND_SEMI];
        }
    } else {
        [self raise:@"no viable alternative found in stat"];
    }
    [self fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)assign {
    
    [self pushFollow:ELEMENTASSIGN_TOKEN_KIND_EQ];
    @try {
    [self list]; 
    [self eq]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self eq]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:ELEMENTASSIGN_TOKEN_KIND_EQ];
    }
    [self list]; 
    [self fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)list {
    
    [self pushFollow:ELEMENTASSIGN_TOKEN_KIND_RBRACKET];
    @try {
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self rbracket]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:ELEMENTASSIGN_TOKEN_KIND_RBRACKET];
    }
    [self fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
    
    [self element]; 
    while ([self predicts:ELEMENTASSIGN_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self comma]; [self element]; }]) {
            [self comma]; 
            [self element]; 
        } else {
            break;
        }
    }
    [self fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self matchNumber:NO];
    } else if ([self predicts:ELEMENTASSIGN_TOKEN_KIND_LBRACKET, 0]) {
        [self list]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }
    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_LBRACKET discard:NO];
    [self fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_RBRACKET discard:YES];
    [self fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_COMMA discard:YES];
    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)eq {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_EQ discard:NO];
    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)dot {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_DOT discard:NO];
    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)semi {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_SEMI discard:NO];
    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

@end