#import "OKJavaScriptParser.h"
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

@interface OKJavaScriptParser ()
@end

@implementation OKJavaScriptParser

- (id)init {
    self = [super init];
    if (self) {
        self.enableAutomaticErrorRecovery = YES;

        self._tokenKindTab[@"|"] = @(OKJAVASCRIPT_TOKEN_KIND_PIPE);
        self._tokenKindTab[@"!="] = @(OKJAVASCRIPT_TOKEN_KIND_NE);
        self._tokenKindTab[@"("] = @(OKJAVASCRIPT_TOKEN_KIND_OPENPAREN);
        self._tokenKindTab[@"}"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY);
        self._tokenKindTab[@"return"] = @(OKJAVASCRIPT_TOKEN_KIND_RETURNSYM);
        self._tokenKindTab[@"~"] = @(OKJAVASCRIPT_TOKEN_KIND_TILDE);
        self._tokenKindTab[@")"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN);
        self._tokenKindTab[@"*"] = @(OKJAVASCRIPT_TOKEN_KIND_TIMES);
        self._tokenKindTab[@"delete"] = @(OKJAVASCRIPT_TOKEN_KIND_DELETE);
        self._tokenKindTab[@"!=="] = @(OKJAVASCRIPT_TOKEN_KIND_ISNOT);
        self._tokenKindTab[@"+"] = @(OKJAVASCRIPT_TOKEN_KIND_PLUS);
        self._tokenKindTab[@"*="] = @(OKJAVASCRIPT_TOKEN_KIND_TIMESEQ);
        self._tokenKindTab[@"instanceof"] = @(OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF);
        self._tokenKindTab[@","] = @(OKJAVASCRIPT_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"<<="] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFTEQ);
        self._tokenKindTab[@"if"] = @(OKJAVASCRIPT_TOKEN_KIND_IFSYM);
        self._tokenKindTab[@"-"] = @(OKJAVASCRIPT_TOKEN_KIND_MINUS);
        self._tokenKindTab[@"null"] = @(OKJAVASCRIPT_TOKEN_KIND_NULL);
        self._tokenKindTab[@"false"] = @(OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL);
        self._tokenKindTab[@"."] = @(OKJAVASCRIPT_TOKEN_KIND_DOT);
        self._tokenKindTab[@"<<"] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFT);
        self._tokenKindTab[@"/"] = @(OKJAVASCRIPT_TOKEN_KIND_DIV);
        self._tokenKindTab[@"+="] = @(OKJAVASCRIPT_TOKEN_KIND_PLUSEQ);
        self._tokenKindTab[@"<="] = @(OKJAVASCRIPT_TOKEN_KIND_LE);
        self._tokenKindTab[@"^="] = @(OKJAVASCRIPT_TOKEN_KIND_XOREQ);
        self._tokenKindTab[@"["] = @(OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET);
        self._tokenKindTab[@"undefined"] = @(OKJAVASCRIPT_TOKEN_KIND_UNDEFINED);
        self._tokenKindTab[@"typeof"] = @(OKJAVASCRIPT_TOKEN_KIND_TYPEOF);
        self._tokenKindTab[@"||"] = @(OKJAVASCRIPT_TOKEN_KIND_OR);
        self._tokenKindTab[@"function"] = @(OKJAVASCRIPT_TOKEN_KIND_FUNCTION);
        self._tokenKindTab[@"]"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET);
        self._tokenKindTab[@"^"] = @(OKJAVASCRIPT_TOKEN_KIND_CARET);
        self._tokenKindTab[@"=="] = @(OKJAVASCRIPT_TOKEN_KIND_EQ);
        self._tokenKindTab[@"continue"] = @(OKJAVASCRIPT_TOKEN_KIND_CONTINUESYM);
        self._tokenKindTab[@"break"] = @(OKJAVASCRIPT_TOKEN_KIND_BREAKSYM);
        self._tokenKindTab[@"-="] = @(OKJAVASCRIPT_TOKEN_KIND_MINUSEQ);
        self._tokenKindTab[@">="] = @(OKJAVASCRIPT_TOKEN_KIND_GE);
        self._tokenKindTab[@":"] = @(OKJAVASCRIPT_TOKEN_KIND_COLON);
        self._tokenKindTab[@"in"] = @(OKJAVASCRIPT_TOKEN_KIND_INSYM);
        self._tokenKindTab[@";"] = @(OKJAVASCRIPT_TOKEN_KIND_SEMI);
        self._tokenKindTab[@"for"] = @(OKJAVASCRIPT_TOKEN_KIND_FORSYM);
        self._tokenKindTab[@"++"] = @(OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS);
        self._tokenKindTab[@"<"] = @(OKJAVASCRIPT_TOKEN_KIND_LT);
        self._tokenKindTab[@"%="] = @(OKJAVASCRIPT_TOKEN_KIND_MODEQ);
        self._tokenKindTab[@">>"] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHT);
        self._tokenKindTab[@"="] = @(OKJAVASCRIPT_TOKEN_KIND_EQUALS);
        self._tokenKindTab[@">"] = @(OKJAVASCRIPT_TOKEN_KIND_GT);
        self._tokenKindTab[@"void"] = @(OKJAVASCRIPT_TOKEN_KIND_VOID);
        self._tokenKindTab[@"?"] = @(OKJAVASCRIPT_TOKEN_KIND_QUESTION);
        self._tokenKindTab[@"while"] = @(OKJAVASCRIPT_TOKEN_KIND_WHILESYM);
        self._tokenKindTab[@"&="] = @(OKJAVASCRIPT_TOKEN_KIND_ANDEQ);
        self._tokenKindTab[@">>>="] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXTEQ);
        self._tokenKindTab[@"else"] = @(OKJAVASCRIPT_TOKEN_KIND_ELSESYM);
        self._tokenKindTab[@"/="] = @(OKJAVASCRIPT_TOKEN_KIND_DIVEQ);
        self._tokenKindTab[@"&&"] = @(OKJAVASCRIPT_TOKEN_KIND_AND);
        self._tokenKindTab[@"var"] = @(OKJAVASCRIPT_TOKEN_KIND_VAR);
        self._tokenKindTab[@"|="] = @(OKJAVASCRIPT_TOKEN_KIND_OREQ);
        self._tokenKindTab[@">>="] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEQ);
        self._tokenKindTab[@"--"] = @(OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS);
        self._tokenKindTab[@"new"] = @(OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW);
        self._tokenKindTab[@"!"] = @(OKJAVASCRIPT_TOKEN_KIND_NOT);
        self._tokenKindTab[@">>>"] = @(OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXT);
        self._tokenKindTab[@"true"] = @(OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL);
        self._tokenKindTab[@"this"] = @(OKJAVASCRIPT_TOKEN_KIND_THIS);
        self._tokenKindTab[@"with"] = @(OKJAVASCRIPT_TOKEN_KIND_WITH);
        self._tokenKindTab[@"==="] = @(OKJAVASCRIPT_TOKEN_KIND_IS);
        self._tokenKindTab[@"%"] = @(OKJAVASCRIPT_TOKEN_KIND_MOD);
        self._tokenKindTab[@"&"] = @(OKJAVASCRIPT_TOKEN_KIND_AMP);
        self._tokenKindTab[@"{"] = @(OKJAVASCRIPT_TOKEN_KIND_OPENCURLY);

    }
    return self;
}


- (void)_start {
    
    [self pushFollow:TOKEN_KIND_BUILTIN_EOF];
    @try {
    [self execute:(id)^{
        
	
	PKTokenizer *t = self.tokenizer;
	
    // whitespace
    self.silentlyConsumesWhitespace = YES;
    t.whitespaceState.reportsWhitespaceTokens = YES;
    self.assembly.preservesWhitespaceTokens = YES;

	[t.symbolState add:@"||"];
	[t.symbolState add:@"&&"];
	[t.symbolState add:@"!="];
	[t.symbolState add:@"!=="];
	[t.symbolState add:@"=="];
	[t.symbolState add:@"==="];
	[t.symbolState add:@"<="];
	[t.symbolState add:@">="];
	[t.symbolState add:@"++"];
	[t.symbolState add:@"--"];
	[t.symbolState add:@"+="];
	[t.symbolState add:@"-="];
	[t.symbolState add:@"*="];
	[t.symbolState add:@"/="];
	[t.symbolState add:@"%="];
	[t.symbolState add:@"<<"];
	[t.symbolState add:@">>"];
	[t.symbolState add:@">>>"];
	[t.symbolState add:@"<<="];
	[t.symbolState add:@">>="];
	[t.symbolState add:@">>>="];
	[t.symbolState add:@"&="];
	[t.symbolState add:@"^="];
	[t.symbolState add:@"|="];

	t.commentState.reportsCommentTokens = YES;
	
	[t setTokenizerState:t.commentState from:'/' to:'/'];
	[t.commentState addSingleLineStartMarker:@"//"];
	[t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];

    }];
    [self program]; 
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

- (void)ifSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_IFSYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchIfSym:)];
}

- (void)elseSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_ELSESYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchElseSym:)];
}

- (void)whileSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_WHILESYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchWhileSym:)];
}

- (void)forSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_FORSYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchForSym:)];
}

- (void)inSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_INSYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchInSym:)];
}

- (void)breakSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_BREAKSYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchBreakSym:)];
}

- (void)continueSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CONTINUESYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchContinueSym:)];
}

- (void)with {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_WITH discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchWith:)];
}

- (void)returnSym {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_RETURNSYM discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchReturnSym:)];
}

- (void)var {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_VAR discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchVar:)];
}

- (void)delete {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_DELETE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchDelete:)];
}

- (void)keywordNew {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchKeywordNew:)];
}

- (void)this {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_THIS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchThis:)];
}

- (void)falseLiteral {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)trueLiteral {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)null {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_NULL discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchNull:)];
}

- (void)undefined {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_UNDEFINED discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchUndefined:)];
}

- (void)void {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_VOID discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchVoid:)];
}

- (void)typeof {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_TYPEOF discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchTypeof:)];
}

- (void)instanceof {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchInstanceof:)];
}

- (void)function {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_FUNCTION discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchFunction:)];
}

- (void)openCurly {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENCURLY discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchOpenCurly:)];
}

- (void)closeCurly {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchCloseCurly:)];
}

- (void)openParen {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)closeParen {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)openBracket {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchOpenBracket:)];
}

- (void)closeBracket {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchCloseBracket:)];
}

- (void)comma {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_COMMA discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)dot {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_DOT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)semi {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SEMI discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

- (void)colon {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_COLON discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchColon:)];
}

- (void)equals {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_EQUALS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchEquals:)];
}

- (void)not {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_NOT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchNot:)];
}

- (void)lt {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_LT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gt {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_GT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)amp {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_AMP discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchAmp:)];
}

- (void)pipe {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_PIPE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchPipe:)];
}

- (void)caret {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CARET discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchCaret:)];
}

- (void)tilde {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_TILDE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchTilde:)];
}

- (void)question {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_QUESTION discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchQuestion:)];
}

- (void)plus {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_PLUS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchPlus:)];
}

- (void)minus {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_MINUS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchMinus:)];
}

- (void)times {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_TIMES discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchTimes:)];
}

- (void)div {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_DIV discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchDiv:)];
}

- (void)mod {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_MOD discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchMod:)];
}

- (void)or {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OR discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)and {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_AND discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

- (void)ne {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_NE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)isnot {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_ISNOT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchIsnot:)];
}

- (void)eq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_EQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)is {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_IS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchIs:)];
}

- (void)le {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_LE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)ge {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_GE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)plusPlus {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchPlusPlus:)];
}

- (void)minusMinus {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchMinusMinus:)];
}

- (void)plusEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_PLUSEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchPlusEq:)];
}

- (void)minusEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_MINUSEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchMinusEq:)];
}

- (void)timesEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_TIMESEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchTimesEq:)];
}

- (void)divEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_DIVEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchDivEq:)];
}

- (void)modEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_MODEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchModEq:)];
}

- (void)shiftLeft {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchShiftLeft:)];
}

- (void)shiftRight {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRight:)];
}

- (void)shiftRightExt {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXT discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRightExt:)];
}

- (void)shiftLeftEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTLEFTEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchShiftLeftEq:)];
}

- (void)shiftRightEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRightEq:)];
}

- (void)shiftRightExtEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SHIFTRIGHTEXTEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchShiftRightExtEq:)];
}

- (void)andEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_ANDEQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchAndEq:)];
}

- (void)xorEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_XOREQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchXorEq:)];
}

- (void)orEq {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OREQ discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchOrEq:)];
}

- (void)assignmentOperator {
    
    if ([self speculate:^{ [self equals]; }]) {
        [self equals]; 
    } else if ([self speculate:^{ [self plusEq]; }]) {
        [self plusEq]; 
    } else if ([self speculate:^{ [self minusEq]; }]) {
        [self minusEq]; 
    } else if ([self speculate:^{ [self timesEq]; }]) {
        [self timesEq]; 
    } else if ([self speculate:^{ [self divEq]; }]) {
        [self divEq]; 
    } else if ([self speculate:^{ [self modEq]; }]) {
        [self modEq]; 
    } else if ([self speculate:^{ [self shiftLeftEq]; }]) {
        [self shiftLeftEq]; 
    } else if ([self speculate:^{ [self shiftRightEq]; }]) {
        [self shiftRightEq]; 
    } else if ([self speculate:^{ [self shiftRightExtEq]; }]) {
        [self shiftRightExtEq]; 
    } else if ([self speculate:^{ [self andEq]; }]) {
        [self andEq]; 
    } else if ([self speculate:^{ [self xorEq]; }]) {
        [self xorEq]; 
    } else if ([self speculate:^{ [self orEq]; }]) {
        [self orEq]; 
    } else {
        [self raise:@"no viable alternative found in assignmentOperator"];
    }

}

- (void)relationalOperator {
    
    if ([self speculate:^{ [self lt]; }]) {
        [self lt]; 
    } else if ([self speculate:^{ [self gt]; }]) {
        [self gt]; 
    } else if ([self speculate:^{ [self ge]; }]) {
        [self ge]; 
    } else if ([self speculate:^{ [self le]; }]) {
        [self le]; 
    } else if ([self speculate:^{ [self instanceof]; }]) {
        [self instanceof]; 
    } else {
        [self raise:@"no viable alternative found in relationalOperator"];
    }

}

- (void)equalityOperator {
    
    if ([self speculate:^{ [self eq]; }]) {
        [self eq]; 
    } else if ([self speculate:^{ [self ne]; }]) {
        [self ne]; 
    } else if ([self speculate:^{ [self is]; }]) {
        [self is]; 
    } else if ([self speculate:^{ [self isnot]; }]) {
        [self isnot]; 
    } else {
        [self raise:@"no viable alternative found in equalityOperator"];
    }

}

- (void)shiftOperator {
    
    if ([self speculate:^{ [self shiftLeft]; }]) {
        [self shiftLeft]; 
    } else if ([self speculate:^{ [self shiftRight]; }]) {
        [self shiftRight]; 
    } else if ([self speculate:^{ [self shiftRightExt]; }]) {
        [self shiftRightExt]; 
    } else {
        [self raise:@"no viable alternative found in shiftOperator"];
    }

}

- (void)incrementOperator {
    
    if ([self speculate:^{ [self plusPlus]; }]) {
        [self plusPlus]; 
    } else if ([self speculate:^{ [self minusMinus]; }]) {
        [self minusMinus]; 
    } else {
        [self raise:@"no viable alternative found in incrementOperator"];
    }

}

- (void)unaryOperator {
    
    if ([self speculate:^{ [self tilde]; }]) {
        [self tilde]; 
    } else if ([self speculate:^{ [self delete]; }]) {
        [self delete]; 
    } else if ([self speculate:^{ [self typeof]; }]) {
        [self typeof]; 
    } else if ([self speculate:^{ [self void]; }]) {
        [self void]; 
    } else {
        [self raise:@"no viable alternative found in unaryOperator"];
    }

}

- (void)multiplicativeOperator {
    
    if ([self speculate:^{ [self times]; }]) {
        [self times]; 
    } else if ([self speculate:^{ [self div]; }]) {
        [self div]; 
    } else if ([self speculate:^{ [self mod]; }]) {
        [self mod]; 
    } else {
        [self raise:@"no viable alternative found in multiplicativeOperator"];
    }

}

- (void)program {
    
    do {
        [self element]; 
    } while ([self speculate:^{ [self element]; }]);

}

- (void)element {
    
    if ([self speculate:^{ [self func]; }]) {
        [self func]; 
    } else if ([self speculate:^{ [self stmt]; }]) {
        [self stmt]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }

}

- (void)func {
    
    [self pushFollow:TOKEN_KIND_BUILTIN_WORD];
    @try {
    [self function]; 
    [self identifier]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self identifier]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:TOKEN_KIND_BUILTIN_WORD];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self openParen]; 
    [self paramListOpt]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }
    [self compoundStmt]; 

}

- (void)paramListOpt {
    
    if ([self speculate:^{ [self paramList]; }]) {
        [self paramList]; 
    }

}

- (void)paramList {
    
    [self identifier]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaIdentifier]; }]) {
            [self commaIdentifier]; 
        } else {
            break;
        }
    }

}

- (void)commaIdentifier {
    
    [self pushFollow:TOKEN_KIND_BUILTIN_WORD];
    @try {
    [self comma]; 
    [self identifier]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self identifier]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:TOKEN_KIND_BUILTIN_WORD];
    }

}

- (void)compoundStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY];
    @try {
    [self openCurly]; 
    [self stmts]; 
    [self closeCurly]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeCurly]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY];
    }

}

- (void)stmts {
    
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_BREAKSYM, OKJAVASCRIPT_TOKEN_KIND_CONTINUESYM, OKJAVASCRIPT_TOKEN_KIND_DELETE, OKJAVASCRIPT_TOKEN_KIND_FALSELITERAL, OKJAVASCRIPT_TOKEN_KIND_FORSYM, OKJAVASCRIPT_TOKEN_KIND_IFSYM, OKJAVASCRIPT_TOKEN_KIND_KEYWORDNEW, OKJAVASCRIPT_TOKEN_KIND_MINUS, OKJAVASCRIPT_TOKEN_KIND_MINUSMINUS, OKJAVASCRIPT_TOKEN_KIND_NULL, OKJAVASCRIPT_TOKEN_KIND_OPENCURLY, OKJAVASCRIPT_TOKEN_KIND_OPENPAREN, OKJAVASCRIPT_TOKEN_KIND_PLUSPLUS, OKJAVASCRIPT_TOKEN_KIND_RETURNSYM, OKJAVASCRIPT_TOKEN_KIND_SEMI, OKJAVASCRIPT_TOKEN_KIND_THIS, OKJAVASCRIPT_TOKEN_KIND_TILDE, OKJAVASCRIPT_TOKEN_KIND_TRUELITERAL, OKJAVASCRIPT_TOKEN_KIND_TYPEOF, OKJAVASCRIPT_TOKEN_KIND_UNDEFINED, OKJAVASCRIPT_TOKEN_KIND_VAR, OKJAVASCRIPT_TOKEN_KIND_VOID, OKJAVASCRIPT_TOKEN_KIND_WHILESYM, OKJAVASCRIPT_TOKEN_KIND_WITH, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        if ([self speculate:^{ [self stmt]; }]) {
            [self stmt]; 
        } else {
            break;
        }
    }

}

- (void)stmt {
    
    if ([self speculate:^{ [self semi]; }]) {
        [self semi]; 
    } else if ([self speculate:^{ [self ifStmt]; }]) {
        [self ifStmt]; 
    } else if ([self speculate:^{ [self ifElseStmt]; }]) {
        [self ifElseStmt]; 
    } else if ([self speculate:^{ [self whileStmt]; }]) {
        [self whileStmt]; 
    } else if ([self speculate:^{ [self forParenStmt]; }]) {
        [self forParenStmt]; 
    } else if ([self speculate:^{ [self forBeginStmt]; }]) {
        [self forBeginStmt]; 
    } else if ([self speculate:^{ [self forInStmt]; }]) {
        [self forInStmt]; 
    } else if ([self speculate:^{ [self breakStmt]; }]) {
        [self breakStmt]; 
    } else if ([self speculate:^{ [self continueStmt]; }]) {
        [self continueStmt]; 
    } else if ([self speculate:^{ [self withStmt]; }]) {
        [self withStmt]; 
    } else if ([self speculate:^{ [self returnStmt]; }]) {
        [self returnStmt]; 
    } else if ([self speculate:^{ [self compoundStmt]; }]) {
        [self compoundStmt]; 
    } else if ([self speculate:^{ [self variablesOrExprStmt]; }]) {
        [self variablesOrExprStmt]; 
    } else {
        [self raise:@"no viable alternative found in stmt"];
    }

}

- (void)ifStmt {
    
    [self ifSym]; 
    [self condition]; 
    [self stmt]; 

}

- (void)ifElseStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_ELSESYM];
    @try {
    [self ifSym]; 
    [self condition]; 
    [self stmt]; 
    [self elseSym]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self elseSym]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_ELSESYM];
    }
    [self stmt]; 

}

- (void)whileStmt {
    
    [self whileSym]; 
    [self condition]; 
    [self stmt]; 

}

- (void)forParenStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self forParen]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self exprOpt]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self exprOpt]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }
    [self stmt]; 

}

- (void)forBeginStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self forBegin]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self exprOpt]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self exprOpt]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }
    [self stmt]; 

}

- (void)forInStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_INSYM];
    @try {
    [self forBegin]; 
    [self inSym]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self inSym]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_INSYM];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self expr]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }
    [self stmt]; 

}

- (void)breakStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self breakSym]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }

}

- (void)continueStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self continueSym]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }

}

- (void)withStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN];
    @try {
    [self with]; 
    [self openParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self openParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN];
    }
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self expr]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }
    [self stmt]; 

}

- (void)returnStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self returnSym]; 
    [self exprOpt]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }

}

- (void)variablesOrExprStmt {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    @try {
    [self variablesOrExpr]; 
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
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_SEMI];
    }

}

- (void)condition {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self openParen]; 
    [self expr]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }

}

- (void)forParen {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN];
    @try {
    [self forSym]; 
    [self openParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self openParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN];
    }

}

- (void)forBegin {
    
    [self forParen]; 
    [self variablesOrExpr]; 

}

- (void)variablesOrExpr {
    
    if ([self speculate:^{ [self varVariables]; }]) {
        [self varVariables]; 
    } else if ([self speculate:^{ [self expr]; }]) {
        [self expr]; 
    } else {
        [self raise:@"no viable alternative found in variablesOrExpr"];
    }

}

- (void)varVariables {
    
    [self var]; 
    [self variables]; 

}

- (void)variables {
    
    [self variable]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaVariable]; }]) {
            [self commaVariable]; 
        } else {
            break;
        }
    }

}

- (void)commaVariable {
    
    [self comma]; 
    [self variable]; 

}

- (void)variable {
    
    [self identifier]; 
    if ([self speculate:^{ [self assignment]; }]) {
        [self assignment]; 
    }

}

- (void)assignment {
    
    [self equals]; 
    [self assignmentExpr]; 

}

- (void)exprOpt {
    
    if ([self speculate:^{ [self expr]; }]) {
        [self expr]; 
    }

}

- (void)expr {
    
    [self assignmentExpr]; 
    if ([self speculate:^{ [self commaExpr]; }]) {
        [self commaExpr]; 
    }

}

- (void)commaExpr {
    
    [self comma]; 
    [self expr]; 

}

- (void)assignmentExpr {
    
    [self conditionalExpr]; 
    if ([self speculate:^{ [self extraAssignment]; }]) {
        [self extraAssignment]; 
    }

}

- (void)extraAssignment {
    
    [self assignmentOperator]; 
    [self assignmentExpr]; 

}

- (void)conditionalExpr {
    
    [self orExpr]; 
    if ([self speculate:^{ [self ternaryExpr]; }]) {
        [self ternaryExpr]; 
    }

}

- (void)ternaryExpr {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_COLON];
    @try {
    [self question]; 
    [self assignmentExpr]; 
    [self colon]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self colon]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_COLON];
    }
    [self assignmentExpr]; 

}

- (void)orExpr {
    
    [self andExpr]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_OR, 0]) {
        if ([self speculate:^{ [self orAndExpr]; }]) {
            [self orAndExpr]; 
        } else {
            break;
        }
    }

}

- (void)orAndExpr {
    
    [self or]; 
    [self andExpr]; 

}

- (void)andExpr {
    
    [self bitwiseOrExpr]; 
    if ([self speculate:^{ [self andAndExpr]; }]) {
        [self andAndExpr]; 
    }

}

- (void)andAndExpr {
    
    [self and]; 
    [self andExpr]; 

}

- (void)bitwiseOrExpr {
    
    [self bitwiseXorExpr]; 
    if ([self speculate:^{ [self pipeBitwiseOrExpr]; }]) {
        [self pipeBitwiseOrExpr]; 
    }

}

- (void)pipeBitwiseOrExpr {
    
    [self pipe]; 
    [self bitwiseOrExpr]; 

}

- (void)bitwiseXorExpr {
    
    [self bitwiseAndExpr]; 
    if ([self speculate:^{ [self caretBitwiseXorExpr]; }]) {
        [self caretBitwiseXorExpr]; 
    }

}

- (void)caretBitwiseXorExpr {
    
    [self caret]; 
    [self bitwiseXorExpr]; 

}

- (void)bitwiseAndExpr {
    
    [self equalityExpr]; 
    if ([self speculate:^{ [self ampBitwiseAndExpression]; }]) {
        [self ampBitwiseAndExpression]; 
    }

}

- (void)ampBitwiseAndExpression {
    
    [self amp]; 
    [self bitwiseAndExpr]; 

}

- (void)equalityExpr {
    
    [self relationalExpr]; 
    if ([self speculate:^{ [self equalityOpEqualityExpr]; }]) {
        [self equalityOpEqualityExpr]; 
    }

}

- (void)equalityOpEqualityExpr {
    
    [self equalityOperator]; 
    [self equalityExpr]; 

}

- (void)relationalExpr {
    
    [self shiftExpr]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_GE, OKJAVASCRIPT_TOKEN_KIND_GT, OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF, OKJAVASCRIPT_TOKEN_KIND_LE, OKJAVASCRIPT_TOKEN_KIND_LT, 0]) {
        if ([self speculate:^{ [self relationalOperator]; [self shiftExpr]; }]) {
            [self relationalOperator]; 
            [self shiftExpr]; 
        } else {
            break;
        }
    }

}

- (void)shiftExpr {
    
    [self additiveExpr]; 
    if ([self speculate:^{ [self shiftOpShiftExpr]; }]) {
        [self shiftOpShiftExpr]; 
    }

}

- (void)shiftOpShiftExpr {
    
    [self shiftOperator]; 
    [self shiftExpr]; 

}

- (void)additiveExpr {
    
    [self multiplicativeExpr]; 
    if ([self speculate:^{ [self plusOrMinusExpr]; }]) {
        [self plusOrMinusExpr]; 
    }

}

- (void)plusOrMinusExpr {
    
    if ([self speculate:^{ [self plusExpr]; }]) {
        [self plusExpr]; 
    } else if ([self speculate:^{ [self minusExpr]; }]) {
        [self minusExpr]; 
    } else {
        [self raise:@"no viable alternative found in plusOrMinusExpr"];
    }

}

- (void)plusExpr {
    
    [self plus]; 
    [self additiveExpr]; 

}

- (void)minusExpr {
    
    [self minus]; 
    [self additiveExpr]; 

}

- (void)multiplicativeExpr {
    
    [self unaryExpr]; 
    if ([self speculate:^{ [self multiplicativeOperator]; [self multiplicativeExpr]; }]) {
        [self multiplicativeOperator]; 
        [self multiplicativeExpr]; 
    }

}

- (void)unaryExpr {
    
    if ([self speculate:^{ [self memberExpr]; }]) {
        [self memberExpr]; 
    } else if ([self speculate:^{ [self unaryExpr1]; }]) {
        [self unaryExpr1]; 
    } else if ([self speculate:^{ [self unaryExpr2]; }]) {
        [self unaryExpr2]; 
    } else if ([self speculate:^{ [self unaryExpr3]; }]) {
        [self unaryExpr3]; 
    } else if ([self speculate:^{ [self unaryExpr4]; }]) {
        [self unaryExpr4]; 
    } else if ([self speculate:^{ [self unaryExpr6]; }]) {
        [self unaryExpr6]; 
    } else {
        [self raise:@"no viable alternative found in unaryExpr"];
    }

}

- (void)unaryExpr1 {
    
    [self unaryOperator]; 
    [self unaryExpr]; 

}

- (void)unaryExpr2 {
    
    [self minus]; 
    [self unaryExpr]; 

}

- (void)unaryExpr3 {
    
    [self incrementOperator]; 
    [self memberExpr]; 

}

- (void)unaryExpr4 {
    
    [self memberExpr]; 
    [self incrementOperator]; 

}

- (void)callNewExpr {
    
    [self keywordNew]; 
    [self constructor]; 

}

- (void)unaryExpr6 {
    
    [self delete]; 
    [self memberExpr]; 

}

- (void)constructor {
    
    if ([self speculate:^{ [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_DOT];@try {[self this]; [self dot]; }@catch (PKSRecognitionException *ex) {if ([self resync]) {[self dot]; } else {@throw ex;}}@finally {[self popFollow:OKJAVASCRIPT_TOKEN_KIND_DOT];}}]) {
        [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_DOT];
        @try {
        [self this]; 
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
            [self popFollow:OKJAVASCRIPT_TOKEN_KIND_DOT];
        }
    }
    [self constructorCall]; 

}

- (void)constructorCall {
    
    [self identifier]; 
    if ([self speculate:^{ if ([self speculate:^{ [self parenArgListParen]; }]) {[self parenArgListParen]; } else if ([self speculate:^{ [self dot]; [self constructorCall]; }]) {[self dot]; [self constructorCall]; } else {[self raise:@"no viable alternative found in constructorCall"];}}]) {
        if ([self speculate:^{ [self parenArgListParen]; }]) {
            [self parenArgListParen]; 
        } else if ([self speculate:^{ [self dot]; [self constructorCall]; }]) {
            [self dot]; 
            [self constructorCall]; 
        } else {
            [self raise:@"no viable alternative found in constructorCall"];
        }
    }

}

- (void)parenArgListParen {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self openParen]; 
    [self argListOpt]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }

}

- (void)memberExpr {
    
    [self primaryExpr]; 
    if ([self speculate:^{ [self dotBracketOrParenExpr]; }]) {
        [self dotBracketOrParenExpr]; 
    }

}

- (void)dotBracketOrParenExpr {
    
    if ([self speculate:^{ [self dotMemberExpr]; }]) {
        [self dotMemberExpr]; 
    } else if ([self speculate:^{ [self bracketMemberExpr]; }]) {
        [self bracketMemberExpr]; 
    } else if ([self speculate:^{ [self parenMemberExpr]; }]) {
        [self parenMemberExpr]; 
    } else {
        [self raise:@"no viable alternative found in dotBracketOrParenExpr"];
    }

}

- (void)dotMemberExpr {
    
    [self dot]; 
    [self memberExpr]; 

}

- (void)bracketMemberExpr {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET];
    @try {
    [self openBracket]; 
    [self expr]; 
    [self closeBracket]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeBracket]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET];
    }

}

- (void)parenMemberExpr {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self openParen]; 
    [self argListOpt]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }

}

- (void)argListOpt {
    
    if ([self speculate:^{ [self argList]; }]) {
        [self argList]; 
    }

}

- (void)argList {
    
    [self assignmentExpr]; 
    while ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaAssignmentExpr]; }]) {
            [self commaAssignmentExpr]; 
        } else {
            break;
        }
    }

}

- (void)commaAssignmentExpr {
    
    [self comma]; 
    [self assignmentExpr]; 

}

- (void)primaryExpr {
    
    if ([self speculate:^{ [self callNewExpr]; }]) {
        [self callNewExpr]; 
    } else if ([self speculate:^{ [self parenExprParen]; }]) {
        [self parenExprParen]; 
    } else if ([self speculate:^{ [self identifier]; }]) {
        [self identifier]; 
    } else if ([self speculate:^{ [self numLiteral]; }]) {
        [self numLiteral]; 
    } else if ([self speculate:^{ [self stringLiteral]; }]) {
        [self stringLiteral]; 
    } else if ([self speculate:^{ [self falseLiteral]; }]) {
        [self falseLiteral]; 
    } else if ([self speculate:^{ [self trueLiteral]; }]) {
        [self trueLiteral]; 
    } else if ([self speculate:^{ [self null]; }]) {
        [self null]; 
    } else if ([self speculate:^{ [self undefined]; }]) {
        [self undefined]; 
    } else if ([self speculate:^{ [self this]; }]) {
        [self this]; 
    } else {
        [self raise:@"no viable alternative found in primaryExpr"];
    }

}

- (void)parenExprParen {
    
    [self pushFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    @try {
    [self openParen]; 
    [self expr]; 
    [self closeParen]; 
    }
    @catch (PKSRecognitionException *ex) {
        if ([self resync]) {
        [self closeParen]; 
        } else {
            @throw ex;
        }
    }
    @finally {
        [self popFollow:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN];
    }

}

- (void)identifier {
    
    [self matchWord:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchIdentifier:)];
}

- (void)numLiteral {
    
    [self matchNumber:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchNumLiteral:)];
}

- (void)stringLiteral {
    
    [self matchQuotedString:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchStringLiteral:)];
}

@end