//
//  PKParserFactory.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "PKParserFactory.h"
#import <ParseKit/ParseKit.h>
#import "PKGrammarParser.h"
#import "NSString+ParseKitAdditions.h"
#import "NSArray+ParseKitAdditions.h"

#import "PKAST.h"
#import "PKNodeVariable.h"
#import "PKNodeConstant.h"
#import "PKNodeLiteral.h"
#import "PKNodeDelimited.h"
#import "PKNodePattern.h"
#import "PKNodeWhitespace.h"
#import "PKNodeComposite.h"
#import "PKNodeCollection.h"
#import "PKNodeCardinal.h"
#import "PKNodeOptional.h"
#import "PKNodeMultiple.h"
//#import "PKNodeRepetition.h"
//#import "PKNodeDifference.h"
//#import "PKNodeNegation.h"

#import "PKConstructNodeVisitor.h"
#import "PKSimplifyNodeVisitor.h"

#define USE_TRACK 0

#define KEY_AND @"AND"

@interface PKParser (PKParserFactoryAdditionsFriend)
- (void)setTokenizer:(PKTokenizer *)t;
@end

@interface PKCollectionParser ()
@property (nonatomic, readwrite, retain) NSMutableArray *subparsers;
@end

@interface PKRepetition ()
@property (nonatomic, readwrite, retain) PKParser *subparser;
@end

@interface PKNegation ()
@property (nonatomic, readwrite, retain) PKParser *subparser;
@end

@interface PKDifference ()
@property (nonatomic, readwrite, retain) PKParser *subparser;
@property (nonatomic, readwrite, retain) PKParser *minus;
@end

@interface PKPattern ()
@property (nonatomic, assign) PKTokenType tokenType;
@end

void PKReleaseSubparserTree(PKParser *p) {
    if ([p isKindOfClass:[PKCollectionParser class]]) {
        PKCollectionParser *c = (PKCollectionParser *)p;
        NSArray *subs = c.subparsers;
        if (subs) {
            [subs retain];
            c.subparsers = nil;
            for (PKParser *s in subs) {
                PKReleaseSubparserTree(s);
            }
            [subs release];
        }
    } else if ([p isMemberOfClass:[PKRepetition class]]) {
        PKRepetition *r = (PKRepetition *)p;
		PKParser *sub = r.subparser;
        if (sub) {
            [sub retain];
            r.subparser = nil;
            PKReleaseSubparserTree(sub);
            [sub release];
        }
    } else if ([p isMemberOfClass:[PKNegation class]]) {
        PKNegation *n = (PKNegation *)p;
		PKParser *sub = n.subparser;
        if (sub) {
            [sub retain];
            n.subparser = nil;
            PKReleaseSubparserTree(sub);
            [sub release];
        }
    } else if ([p isMemberOfClass:[PKDifference class]]) {
        PKDifference *d = (PKDifference *)p;
		PKParser *sub = d.subparser;
        if (sub) {
            [sub retain];
            d.subparser = nil;
            PKReleaseSubparserTree(sub);
            [sub release];
        }
		PKParser *m = d.minus;
        if (m) {
            [m retain];
            d.minus = nil;
            PKReleaseSubparserTree(m);
            [m release];
        }
    }
}

@interface PKParserFactory ()
- (PKTokenizer *)tokenizerForParsingGrammar;
- (PKTokenizer *)tokenizerFromGrammarSettings;
- (PKParser *)parserFromAST:(PKNodeBase *)rootNode;

- (void)parser:(PKParser *)p didMatchTokenizerDirective:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStartProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a;

@property (nonatomic, retain) PKGrammarParser *grammarParser;
@property (nonatomic, assign) id assembler;
@property (nonatomic, assign) id preassembler;
@property (nonatomic, assign) BOOL wantsCharacters;
@property (nonatomic, retain) PKToken *equals;
@property (nonatomic, retain) PKToken *curly;
@property (nonatomic, retain) PKToken *paren;

@property (nonatomic, retain) PKToken *seqToken;
@property (nonatomic, retain) PKToken *trackToken;
@property (nonatomic, retain) PKToken *altToken;
@property (nonatomic, retain) PKToken *delimToken;
@property (nonatomic, retain) PKToken *patternToken;

@property (nonatomic, retain) NSMutableDictionary *productionTab;
//@property (nonatomic, retain) NSMutableDictionary *callbackTab;
@end

@implementation PKParserFactory {

}

+ (PKParserFactory *)factory {
    return [[[PKParserFactory alloc] init] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.grammarParser = [[[PKGrammarParser alloc] initWithAssembler:self] autorelease];
        self.equals = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"=" floatValue:0.0];
        self.curly = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
        self.paren = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" floatValue:0.0];

        self.seqToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"SEQ" floatValue:0.0];
        self.trackToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"TRACK" floatValue:0.0];
        self.altToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"|" floatValue:0.0];
        self.delimToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"DELIM" floatValue:0.0];

        self.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorOnAll;
    }
    return self;
}


- (void)dealloc {
    self.grammarParser = nil;
    self.assembler = nil;
    self.preassembler = nil;
    self.equals = nil;
    self.curly = nil;
    self.paren = nil;
    
    self.seqToken = nil;
    self.trackToken = nil;
    self.altToken = nil;
    self.delimToken = nil;
    self.patternToken = nil;
    
    self.productionTab = nil;
//    self.callbackTab = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Testing

- (PKCollectionParser *)exprParser {
    return _grammarParser.exprParser;
}


#pragma mark -
#pragma mark Public

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError {
    return [self parserFromGrammar:g assembler:a preassembler:nil error:outError];
}


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError {
    PKParser *result = nil;
    
    @try {
        self.assembler = a;
        self.preassembler = pa;
        
        PKNodeBase *rootNode = (PKNodeBase *)[self ASTFromGrammar:g simplify:NO error:outError];
        
        NSLog(@"rootNode %@", rootNode);

        PKTokenizer *t = [self tokenizerFromGrammarSettings];
        PKParser *start = [self parserFromAST:rootNode];
        
        NSLog(@"start %@", start);

        self.assembler = nil;
//        self.callbackTab = nil;
        self.productionTab = nil;
        
        if (start && [start isKindOfClass:[PKParser class]]) {
            start.tokenizer = t;
            result = start;
        } else {
            [NSException raise:@"PKGrammarException" format:NSLocalizedString(@"An unknown error occurred while parsing the grammar. The provided language grammar was invalid.", @"")];
        }
        
        return result;
        
    }
    @catch (NSException *ex) {
        if (outError) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[ex userInfo]];
            
            // get reason
            NSString *reason = [ex reason];
            if ([reason length]) [userInfo setObject:reason forKey:NSLocalizedFailureReasonErrorKey];
            
            // get domain
            NSString *name = [ex name];
            NSString *domain = name ? name : @"PKGrammarException";
            
            // convert to NSError
            NSError *err = [NSError errorWithDomain:domain code:47 userInfo:[[userInfo copy] autorelease]];
            *outError = err;
        } else {
            [ex raise];
        }
    }
}


- (PKAST *)ASTFromGrammar:(NSString *)g error:(NSError **)outError {
    return [self ASTFromGrammar:g simplify:NO error:outError];
}


- (PKAST *)ASTFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError {
//    self.callbackTab = [NSMutableDictionary dictionary];
    self.productionTab = [NSMutableDictionary dictionary];

    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = g;
    
    _grammarParser.parser.tokenizer = t;
    [_grammarParser.parser parse:g error:outError];
    
    NSLog(@"%@", _productionTab);
    
    PKNodeBase *rootNode = [_productionTab objectForKey:@"@start"];
    
    if (simplify) {
        id <PKNodeVisitor>v = [[[PKSimplifyNodeVisitor alloc] init] autorelease];
        [self visit:rootNode with:v];
    }
    
    return rootNode;
}


#pragma mark -
#pragma mark Private

- (PKTokenizer *)tokenizerForParsingGrammar {
    PKTokenizer *t = [PKTokenizer tokenizer];
    
    t.whitespaceState.reportsWhitespaceTokens = YES;
    
//    // customize tokenizer to find tokenizer customization directives
//    [t setTokenizerState:t.wordState from:'@' to:'@'];
    
    // add support for tokenizer directives like @commentState.fallbackState
    [t.wordState setWordChars:YES from:'.' to:'.'];
    [t.wordState setWordChars:NO from:'-' to:'-'];
    
    // setup comments
    [t setTokenizerState:t.commentState from:'/' to:'/'];
    [t.commentState addSingleLineStartMarker:@"//"];
    [t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];
    
    // comment state should fallback to delimit state to match regex delimited strings
    t.commentState.fallbackState = t.delimitState;
    
    // regex delimited strings
    [t.delimitState addStartMarker:@"/" endMarker:@"/" allowedCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
    
    return t;
}


- (PKTokenizer *)tokenizerFromGrammarSettings {
    self.wantsCharacters = [self boolForTokenForKey:@"@wantsCharacters"];
    
    PKTokenizer *t = [PKTokenizer tokenizer];
    [t.commentState removeSingleLineStartMarker:@"//"];
    [t.commentState removeMultiLineStartMarker:@"/*"];
    
    t.whitespaceState.reportsWhitespaceTokens = [self boolForTokenForKey:@"@reportsWhitespaceTokens"];
    t.commentState.reportsCommentTokens = [self boolForTokenForKey:@"@reportsCommentTokens"];
    t.commentState.balancesEOFTerminatedComments = [self boolForTokenForKey:@"balancesEOFTerminatedComments"];
    t.quoteState.balancesEOFTerminatedQuotes = [self boolForTokenForKey:@"@balancesEOFTerminatedQuotes"];
    t.delimitState.balancesEOFTerminatedStrings = [self boolForTokenForKey:@"@balancesEOFTerminatedStrings"];
    t.numberState.allowsTrailingDecimalSeparator = [self boolForTokenForKey:@"@allowsTrailingDecimalSeparator"];
    t.numberState.allowsScientificNotation = [self boolForTokenForKey:@"@allowsScientificNotation"];
    t.numberState.allowsOctalNotation = [self boolForTokenForKey:@"@allowsOctalNotation"];
    t.numberState.allowsHexadecimalNotation = [self boolForTokenForKey:@"@allowsHexadecimalNotation"];
    
    BOOL yn = YES;
    if ([_productionTab objectForKey:@"allowsFloatingPoint"]) {
        yn = [self boolForTokenForKey:@"allowsFloatingPoint"];
    }
    t.numberState.allowsFloatingPoint = yn;
    
    [self setTokenizerState:t.wordState onTokenizer:t forTokensForKey:@"@wordState"];
    [self setTokenizerState:t.numberState onTokenizer:t forTokensForKey:@"@numberState"];
    [self setTokenizerState:t.quoteState onTokenizer:t forTokensForKey:@"@quoteState"];
    [self setTokenizerState:t.delimitState onTokenizer:t forTokensForKey:@"@delimitState"];
    [self setTokenizerState:t.symbolState onTokenizer:t forTokensForKey:@"@symbolState"];
    [self setTokenizerState:t.commentState onTokenizer:t forTokensForKey:@"@commentState"];
    [self setTokenizerState:t.whitespaceState onTokenizer:t forTokensForKey:@"@whitespaceState"];
    
    [self setFallbackStateOn:t.commentState withTokenizer:t forTokensForKey:@"@commentState.fallbackState"];
    [self setFallbackStateOn:t.delimitState withTokenizer:t forTokensForKey:@"@delimitState.fallbackState"];
    
    NSArray *toks = nil;
    
    // muli-char symbols
    toks = [NSArray arrayWithArray:[_productionTab objectForKey:@"@symbol"]];
    toks = [toks arrayByAddingObjectsFromArray:[_productionTab objectForKey:@"@symbols"]];
    [_productionTab removeObjectForKey:@"@symbol"];
    [_productionTab removeObjectForKey:@"@symbols"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            [t.symbolState add:[tok.stringValue stringByTrimmingQuotes]];
        }
    }
    
    // wordChars
    toks = [NSArray arrayWithArray:[_productionTab objectForKey:@"@wordChar"]];
    toks = [toks arrayByAddingObjectsFromArray:[_productionTab objectForKey:@"@wordChars"]];
    [_productionTab removeObjectForKey:@"@wordChar"];
    [_productionTab removeObjectForKey:@"@wordChars"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
			NSString *s = [tok.stringValue stringByTrimmingQuotes];
			if ([s length]) {
				PKUniChar c = [s characterAtIndex:0];
				[t.wordState setWordChars:YES from:c to:c];
			}
        }
    }
    
    // whitespaceChars
    toks = [NSArray arrayWithArray:[_productionTab objectForKey:@"@whitespaceChar"]];
    toks = [toks arrayByAddingObjectsFromArray:[_productionTab objectForKey:@"@whitespaceChars"]];
    [_productionTab removeObjectForKey:@"@whitespaceChar"];
    [_productionTab removeObjectForKey:@"@whitespaceChars"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
			NSString *s = [tok.stringValue stringByTrimmingQuotes];
			if ([s length]) {
                PKUniChar c = 0;
                if ([s hasPrefix:@"#x"]) {
                    c = (PKUniChar)[s integerValue];
                } else {
                    c = [s characterAtIndex:0];
                }
                [t.whitespaceState setWhitespaceChars:YES from:c to:c];
			}
        }
    }
    
    // single-line comments
    toks = [NSArray arrayWithArray:[_productionTab objectForKey:@"@singleLineComment"]];
    toks = [toks arrayByAddingObjectsFromArray:[_productionTab objectForKey:@"@singleLineComments"]];
    [_productionTab removeObjectForKey:@"@singleLineComment"];
    [_productionTab removeObjectForKey:@"@singleLineComments"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            NSString *s = [tok.stringValue stringByTrimmingQuotes];
            [t.commentState addSingleLineStartMarker:s];
        }
    }
    
    // multi-line comments
    toks = [NSArray arrayWithArray:[_productionTab objectForKey:@"@multiLineComment"]];
    toks = [toks arrayByAddingObjectsFromArray:[_productionTab objectForKey:@"@multiLineComments"]];
    NSAssert(0 == [toks count] % 2, @"@multiLineComments must be specified as quoted strings in multiples of 2");
    [_productionTab removeObjectForKey:@"@multiLineComment"];
    [_productionTab removeObjectForKey:@"@multiLineComments"];
    if ([toks count] > 1) {
        NSInteger i = 0;
        for ( ; i < [toks count] - 1; i++) {
            PKToken *startTok = [toks objectAtIndex:i];
            PKToken *endTok = [toks objectAtIndex:++i];
            if (startTok.isQuotedString && endTok.isQuotedString) {
                NSString *start = [startTok.stringValue stringByTrimmingQuotes];
                NSString *end = [endTok.stringValue stringByTrimmingQuotes];
                [t.commentState addMultiLineStartMarker:start endMarker:end];
            }
        }
    }
    
    // delimited strings
    toks = [NSArray arrayWithArray:[_productionTab objectForKey:@"@delimitedString"]];
    toks = [toks arrayByAddingObjectsFromArray:[_productionTab objectForKey:@"@delimitedStrings"]];
    NSAssert(0 == [toks count] % 3, @"@delimitedString must be specified as quoted strings in multiples of 3");
    [_productionTab removeObjectForKey:@"@delimitedString"];
    [_productionTab removeObjectForKey:@"@delimitedStrings"];
    if ([toks count] > 1) {
        for (NSInteger i = 0; i < [toks count] - 2; i++) {
            PKToken *startTok = [toks objectAtIndex:i];
            PKToken *endTok = [toks objectAtIndex:++i];
            PKToken *charSetTok = [toks objectAtIndex:++i];
            if (startTok.isQuotedString && endTok.isQuotedString) {
                NSString *start = [startTok.stringValue stringByTrimmingQuotes];
                NSString *end = [endTok.stringValue stringByTrimmingQuotes];
                NSCharacterSet *charSet = nil;
                if (charSetTok.isQuotedString) {
                    charSet = [NSCharacterSet characterSetWithCharactersInString:[charSetTok.stringValue stringByTrimmingQuotes]];
                }
                [t.delimitState addStartMarker:start endMarker:end allowedCharacterSet:charSet];
            }
        }
    }
    
    return t;
}


- (BOOL)boolForTokenForKey:(NSString *)key {
    BOOL result = NO;
    NSArray *toks = [_productionTab objectForKey:key];
    if ([toks count]) {
        PKToken *tok = [toks objectAtIndex:0];
        if (tok.isWord && [tok.stringValue isEqualToString:@"YES"]) {
            result = YES;
        }
    }
    [_productionTab removeObjectForKey:key];
    return result;
}


- (void)setTokenizerState:(PKTokenizerState *)state onTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key {
    NSArray *toks = [_productionTab objectForKey:key];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            NSString *s = [tok.stringValue stringByTrimmingQuotes];
            if (1 == [s length]) {
                PKUniChar c = [s characterAtIndex:0];
                [t setTokenizerState:state from:c to:c];
            }
        }
    }
    [_productionTab removeObjectForKey:key];
}


- (void)setFallbackStateOn:(PKTokenizerState *)state withTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key {
    NSArray *toks = [_productionTab objectForKey:key];
    if ([toks count]) {
        PKToken *tok = [toks objectAtIndex:0];
        if (tok.isWord) {
            PKTokenizerState *fallbackState = [t valueForKey:tok.stringValue];
            if (state != fallbackState) {
                state.fallbackState = fallbackState;
            }
        }
    }
    [_productionTab removeObjectForKey:key];
}


- (PKParser *)parserFromAST:(PKNodeBase *)rootNode {
    PKConstructNodeVisitor *v = [[[PKConstructNodeVisitor alloc] init] autorelease];
    
    v.assembler = _assembler;
    v.preassembler = _preassembler;

    v.assemblerSettingBehavior = _assemblerSettingBehavior;

    [self visit:rootNode with:v];
    
    PKParser *p = v.rootParser;
    return p;
}


- (void)visit:(PKNodeBase *)rootNode with:(id <PKNodeVisitor>)v {
    v.rootNode = rootNode;

    PKNodeType nodeType = rootNode.type;
    switch (nodeType) {
        case PKNodeTypeVariable:
            [v visitVariable:(PKNodeVariable *)rootNode];
            break;
        case PKNodeTypeConstant:
            [v visitConstant:(PKNodeConstant *)rootNode];
            break;
        case PKNodeTypeLiteral:
            [v visitLiteral:(PKNodeLiteral *)rootNode];
            break;
        case PKNodeTypeDelimited:
            [v visitDelimited:(PKNodeDelimited *)rootNode];
            break;
        case PKNodeTypePattern:
            [v visitPattern:(PKNodePattern *)rootNode];
            break;
        case PKNodeTypeComposite:
            [v visitComposite:(PKNodeComposite *)rootNode];
            break;
        case PKNodeTypeCollection:
            [v visitCollection:(PKNodeCollection *)rootNode];
            break;
        case PKNodeTypeOptional:
            [v visitOptional:(PKNodeOptional *)rootNode];
            break;
        case PKNodeTypeMultiple:
            [v visitMultiple:(PKNodeMultiple *)rootNode];
            break;
        default:
            NSAssert1(0, @"unknown nodeType %d", nodeType);
            break;
    }
}


#pragma mark -
#pragma mark Assembler Helpers

- (PKAlternation *)zeroOrOne:(PKParser *)p {
    PKAlternation *a = [PKAlternation alternation];
    [a add:[PKEmpty empty]];
    [a add:p];
    return a;
}


- (PKSequence *)oneOrMore:(PKParser *)p {
    PKSequence *s = [PKSequence sequence];
    [s add:p];
    [s add:[PKRepetition repetitionWithSubparser:p]];
    return s;
}


- (NSArray *)tokens:(NSArray *)toks byRemovingTokensOfType:(PKTokenType)tt {
    NSMutableArray *res = [NSMutableArray array];
    for (PKToken *tok in toks) {
        if (tt != tok.tokenType) {
            [res addObject:tok];
        }
    }
    return res;
}


#pragma mark -
#pragma mark Assembler Callbacks

- (void)parser:(PKParser *)p didMatchTokenizerDirective:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    NSArray *argToks = [[self tokens:[a objectsAbove:_equals] byRemovingTokensOfType:PKTokenTypeWhitespace] reversedArray];
    //NSArray *argToks = [a objectsAbove:_equals];
    [a pop]; // discard '='

    PKToken *nameTok = [a pop];
    NSAssert(nameTok, @"");
    NSAssert([nameTok isKindOfClass:[PKToken class]], @"");
    NSAssert(nameTok.isWord, @"");
    
    NSString *prodName = [NSString stringWithFormat:@"@%@", nameTok.stringValue];
    
    [_productionTab setObject:argToks forKey:prodName];
}


- (void)parser:(PKParser *)p didMatchStartProduction:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    NSString *prodName = @"@start";
    
    PKNodeBase *prodNode = [_productionTab objectForKey:prodName];
    if (!prodNode) {
        prodNode = (PKNodeBase *)[PKNodeCollection ASTWithToken:_seqToken];
        prodNode.parserName = prodName;
        [_productionTab setObject:prodNode forKey:prodName];
    }
    
    [a push:prodNode];

    a.target = prodNode;
}


- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert(islower([tok.stringValue characterAtIndex:0]), @"");
    
    NSString *prodName = tok.stringValue;
    
    PKNodeBase *prodNode = [_productionTab objectForKey:prodName];
    if (!prodNode) {
        prodNode = (PKNodeBase *)[PKNodeCollection ASTWithToken:_seqToken];
        prodNode.parserName = prodName;
        [_productionTab setObject:prodNode forKey:prodName];
    }
    [a push:prodNode];
    
    a.target = prodNode;
}


- (void)parser:(PKParser *)p didMatchEq:(PKAssembly *)a {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert(islower([tok.stringValue characterAtIndex:0]), @"");

    NSString *prodName = tok.stringValue;

    PKNodeBase *prodNode = [_productionTab objectForKey:prodName];
    if (!prodNode) {
        prodNode = (PKNodeBase *)[PKNodeCollection ASTWithToken:_seqToken];
        prodNode.parserName = prodName;
        [_productionTab setObject:prodNode forKey:prodName];
    }
    [a push:prodNode];
}


- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert(isupper([tok.stringValue characterAtIndex:0]), @"");

    PKAST *parserNode = [PKNodeConstant ASTWithToken:tok];
    [a push:parserNode];
}


- (void)parser:(PKParser *)p didMatchSpace:(PKAssembly *)a {
    //    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert([tok.stringValue isEqualToString:@"S"], @"");
    
    PKAST *parserNode = [PKNodeWhitespace ASTWithToken:tok];
    [a push:parserNode];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
    //    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    
    PKAST *litNode = [PKNodeLiteral ASTWithToken:tok];
    [a push:litNode];
}


- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    PKAST *rhs = [a pop];
    PKToken *tok = [a pop]; // '|'
    PKAST *lhs = [a pop];
    
    PKAST *altNode = [PKNodeCollection ASTWithToken:tok];
    [altNode addChild:lhs];
    [altNode addChild:rhs];
    
    [a push:altNode];
}


- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    NSArray *nodes = [a objectsAbove:_equals];
    [a pop]; // '='
    
    PKNodeBase *var = [a pop];
    NSAssert([var isKindOfClass:[PKNodeCollection class]], @"");
    
    for (PKAST *node in nodes) {
        [var addChild:node];
    }
    
    //[a push:var];
}


- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a {
    PKToken *selNameTok2 = [a pop];
    PKToken *selNameTok1 = [a pop];
    PKNodeVariable *node = [a pop];
    
    NSAssert([selNameTok1 isKindOfClass:[PKToken class]], @"");
    NSAssert([selNameTok2 isKindOfClass:[PKToken class]], @"");
    NSAssert(selNameTok1.isWord, @"");
    NSAssert(selNameTok2.isWord, @"");
    
    NSAssert([node isKindOfClass:[PKNodeVariable class]], @"");
    
    NSString *selName = [NSString stringWithFormat:@"%@:%@:", selNameTok1.stringValue, selNameTok2.stringValue];
    node.callbackName = selName;
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

}


- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);

    NSArray *objs = [a objectsAbove:_paren];
    NSAssert([objs count], @"");
    [a pop]; // pop '('
    
    if ([objs count] > 1) {
        PKAST *seqNode = [PKNodeCollection ASTWithToken:_seqToken];
        for (PKAST *child in objs) {
            NSAssert([child isKindOfClass:[PKAST class]], @"");
            [seqNode addChild:child];
        }
        [a push:seqNode];
    } else if ([objs count]) {
        [a push:[objs objectAtIndex:0]];
    }
}


- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKAST *minus = [a pop];
    PKToken *tok = [a pop]; // '-'
    PKAST *sub = [a pop];
    
    NSAssert(tok.isSymbol, @"");
    NSAssert([minus isKindOfClass:[PKAST class]], @"");
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
//    PKAST *diffNode = [PKNodeDifference ASTWithToken:tok];
    PKAST *diffNode = [PKNodeComposite ASTWithToken:tok];
    [diffNode addChild:sub];
    [diffNode addChild:minus];
    
    [a push:diffNode];
}


- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKAST *predicate = [a pop];
    PKToken *tok = [a pop]; // '&'
    PKAST *sub = [a pop];
    
    NSAssert(tok.isSymbol, @"");
    NSAssert([predicate isKindOfClass:[PKAST class]], @"");
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *intNode = [PKNodeCollection ASTWithToken:tok];
    [intNode addChild:sub];
    [intNode addChild:predicate];
    
    [a push:intNode];
}


- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a {
    PKToken *tok = [a pop];
    NSAssert(tok.isWord, @"");
    
    NSString *s = tok.stringValue;
    NSAssert([s length] > 0, @"");
    
    PKPatternOptions opts = PKPatternOptionsNone;
    if (NSNotFound != [s rangeOfString:@"i"].location) {
        opts |= PKPatternOptionsIgnoreCase;
    }
    if (NSNotFound != [s rangeOfString:@"m"].location) {
        opts |= PKPatternOptionsMultiline;
    }
    if (NSNotFound != [s rangeOfString:@"x"].location) {
        opts |= PKPatternOptionsComments;
    }
    if (NSNotFound != [s rangeOfString:@"s"].location) {
        opts |= PKPatternOptionsDotAll;
    }
    if (NSNotFound != [s rangeOfString:@"w"].location) {
        opts |= PKPatternOptionsUnicodeWordBoundaries;
    }
    
    [a push:[NSNumber numberWithInteger:opts]];
}


- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a {
    id obj = [a pop]; // opts (as Number*) or DelimitedString('/', '/')
    
    PKPatternOptions opts = PKPatternOptionsNone;
    if ([obj isKindOfClass:[NSNumber class]]) {
        opts = [obj unsignedIntValue];
        obj = [a pop];
    }
    
    NSAssert([obj isMemberOfClass:[PKToken class]], @"");
    PKToken *tok = (PKToken *)obj;
    NSAssert(tok.isDelimitedString, @"");
    
    NSString *s = tok.stringValue;
    NSAssert([s length] > 2, @"");
    
    NSAssert([s hasPrefix:@"/"], @"");
    NSAssert([s hasSuffix:@"/"], @"");
    
    NSString *re = [s stringByTrimmingQuotes];
    
    PKNodePattern *patNode = (PKNodePattern *)[PKNodePattern ASTWithToken:tok];
    patNode.string = re;
    patNode.options = opts;
    
    [a push:patNode];
}


- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a {
    PKNodeBase *node = [a pop];
    NSAssert([node isKindOfClass:[PKNodeBase class]], @"");

    node.discard = YES;
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    NSArray *toks = [a objectsAbove:_paren];
    [a pop]; // discard '(' fence

    PKNodeDelimited *delimNode = (PKNodeDelimited *)[PKNodeDelimited ASTWithToken:_delimToken];

    NSAssert([toks count] > 0 && [toks count] < 3, @"");
    NSString *start = [[[toks lastObject] stringValue] stringByTrimmingQuotes];
    NSString *end = nil;
    if ([toks count] > 1) {
        end = [[[toks objectAtIndex:0] stringValue] stringByTrimmingQuotes];
    }
    
    delimNode.startMarker = start;
    delimNode.endMarker = end;
    
    [a push:delimNode];
}


- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    [a push:[NSNumber numberWithFloat:tok.floatValue]];
}


- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop]; // '*'
    NSAssert(tok.isSymbol, @"");
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    //    PKAST *starNode = [PKNodeRepetition ASTWithToken:tok];
    PKAST *starNode = [PKNodeComposite ASTWithToken:tok];
    [starNode addChild:sub];

    [a push:starNode];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop]; // '+'
    NSAssert(tok.isSymbol, @"");
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *plusNode = [PKNodeMultiple ASTWithToken:tok];
    [plusNode addChild:sub];
    
    [a push:plusNode];
}


- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop]; // '?'
    NSAssert(tok.isSymbol, @"");
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *qNode = [PKNodeOptional ASTWithToken:tok];
    [qNode addChild:sub];
    
    [a push:qNode];
}


- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    PKToken *tok = [a pop]; // '~'
    NSAssert(tok.isSymbol, @"");

    //    PKAST *negNode = [PKNodeNegation ASTWithToken:tok];
    PKAST *negNode = [PKNodeComposite ASTWithToken:tok];
    [negNode addChild:sub];
    
    [a push:negNode];
}


- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a {
    NSRange r = [[a pop] rangeValue];
    PKToken *tok = [a pop]; // '{' tok

    PKNodeBase *childNode = [a pop];
    PKNodeCardinal *node = (PKNodeCardinal *)[PKNodeCardinal ASTWithToken:tok];
    
    [node addChild:childNode];
    
    NSInteger start = r.location;
    NSInteger end = r.length;

    node.rangeStart = start;
    node.rangeEnd = end;
    
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a {
    NSArray *toks = [a objectsAbove:self.curly];
    
    NSAssert([toks count] > 0, @"");
    
    PKToken *tok = [toks lastObject];
    PKFloat start = tok.floatValue;
    PKFloat end = start;
    if ([toks count] > 1) {
        tok = [toks objectAtIndex:0];
        end = tok.floatValue;
    }
    
    NSAssert(start <= end, @"");
    
    NSRange r = NSMakeRange(start, end);
    [a push:[NSValue valueWithRange:r]];
}


//- (PKNodeCollection *)currentAndFrom:(PKAssembly *)a {
//    NSMutableDictionary *d = a.target;
//    PKNodeCollection *and = [d objectForKey:KEY_AND];
//    if (!and) {
//        and = (PKNodeCollection *)[PKNodeCollection ASTWithToken:_seqToken];
//    }
//    return and;
//}


- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
//    PKNodeBase *child = [a pop];
//    PKNodeCollection *seq = nil;
//    
//    id seqOrEq = [a pop];
//    if ([seqOrEq isEqual:_equals]) {
//        seq = [a pop];
//        [a push:seq];
//        [a push:seqOrEq];
//    } else {
//        seq = (PKNodeCollection *)[PKNodeCollection ASTWithToken:_seqToken];
//        [a push:seqOrEq];
//        [a push:seq];
//    }
//    [seq addChild:child];

    
    PKNodeBase *child = [a pop];
    PKNodeCollection *seq = (PKNodeCollection *)[PKNodeCollection ASTWithToken:_seqToken];
    [seq addChild:child];
    
    NSLog(@"%@", [seq treeDescription]);
    
    [a push:seq];
}


- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, a);
    
    PKNodeBase *child = [a pop];
    PKNodeCollection *seq = [a pop];
    [seq addChild:child];
    
    NSLog(@"%@", [seq treeDescription]);
    
    [a push:seq];
}

@end
