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
#import "PKDefinitionNode.h"
#import "PKReferenceNode.h"
#import "PKConstantNode.h"
#import "PKLiteralNode.h"
#import "PKDelimitedNode.h"
#import "PKPatternNode.h"
#import "PKWhitespaceNode.h"
#import "PKCompositeNode.h"
#import "PKCollectionNode.h"
#import "PKCardinalNode.h"
#import "PKOptionalNode.h"
#import "PKMultipleNode.h"
//#import "PKNodeRepetition.h"
//#import "PKNodeDifference.h"
//#import "PKNodeNegation.h"

#import "PKConstructNodeVisitor.h"
#import "PKSimplifyNodeVisitor.h"

#define USE_TRACK 0

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
- (PKTokenizer *)tokenizerFromSymbolTable:(NSMutableDictionary *)symTab;
- (PKParser *)parserFromSymbolTable:(NSMutableDictionary *)symTab;
- (Class)nodeClassForToken:(PKToken *)tok;

- (PKAST *)ASTFromGrammar:(NSString *)g error:(NSError **)outError;
- (PKAST *)ASTFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError;

- (void)parser:(PKParser *)p didMatchTokenizerDirective:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a;
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

@property (nonatomic, retain) PKToken *defToken;
@property (nonatomic, retain) PKToken *refToken;
@property (nonatomic, retain) PKToken *seqToken;
@property (nonatomic, retain) PKToken *trackToken;
@property (nonatomic, retain) PKToken *altToken;
@property (nonatomic, retain) PKToken *delimToken;
@property (nonatomic, retain) PKToken *patternToken;

@property (nonatomic, retain) NSMutableDictionary *productionTab;
//@property (nonatomic, retain) NSMutableDictionary *callbackTab;

@property (nonatomic, retain) NSDictionary *nodeClassForTokenTable;
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

        self.defToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"DEF" floatValue:0.0];
        self.refToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"REF" floatValue:0.0];
        self.seqToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"SEQ" floatValue:0.0];
        self.trackToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"TRACK" floatValue:0.0];
        self.altToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"|" floatValue:0.0];
        self.delimToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"DELIM" floatValue:0.0];

        self.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorOnAll;
        
        self.nodeClassForTokenTable =
        @{
          //@"DEF"            : [PKNodeDefinition class],
          //@"REF"            : [PKNodeReference class],
          @"SEQ"            : [PKCollectionNode class],
          @"TRACK"          : [PKCollectionNode class],
          @"&"              : [PKCollectionNode class],
          @"|"              : [PKCollectionNode class],
          @"-"              : [PKCompositeNode class],
          @"~"              : [PKCompositeNode class],
          @"*"              : [PKCompositeNode class],
          @"?"              : [PKOptionalNode class],
          @"+"              : [PKMultipleNode class],
          @"{"              : [PKCardinalNode class],
          @"S"              : [PKWhitespaceNode class],
          @"DELIM"          : [PKDelimitedNode class],
          @"Number"         : [PKConstantNode class],
          @"Word"           : [PKConstantNode class],
          @"QuotedString"   : [PKConstantNode class],
          @"Symbol"         : [PKConstantNode class],
        };

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
    
    self.defToken = nil;
    self.refToken = nil;
    self.seqToken = nil;
    self.trackToken = nil;
    self.altToken = nil;
    self.delimToken = nil;
    self.patternToken = nil;
    
    self.productionTab = nil;
//    self.callbackTab = nil;
    
    self.nodeClassForTokenTable = nil;
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
        
        NSMutableDictionary *symTab = [NSMutableDictionary dictionaryWithDictionary:[self symbolTableFromGrammar:g simplify:NO error:outError]];
        //NSLog(@"tab %@", tab);

        PKTokenizer *t = [self tokenizerFromSymbolTable:symTab];
        PKParser *start = [self parserFromSymbolTable:symTab];
        
        //NSLog(@"start %@", start);

        self.assembler = nil;
//        self.callbackTab = nil;
        
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


- (NSDictionary *)symbolTableFromGrammar:(NSString *)g error:(NSError **)outError {
    return [self symbolTableFromGrammar:g simplify:NO error:outError];
}


- (NSDictionary *)symbolTableFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError {
    //    self.callbackTab = [NSMutableDictionary dictionary];
    self.productionTab = [NSMutableDictionary dictionary];
    
    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = g;
    
    _grammarParser.parser.tokenizer = t;
    [_grammarParser.parser parse:g error:outError];
    
    if (simplify) {
        @autoreleasepool {
            PKBaseNode *rootNode = _productionTab[@"@start"];
            
            id <PKNodeVisitor>v = [[[PKSimplifyNodeVisitor alloc] init] autorelease];
            [self visit:rootNode with:v];
        }
    }
    
    NSDictionary *symTab = [[_productionTab copy] autorelease];
    self.productionTab = nil;
    
    return symTab;
}


- (PKAST *)ASTFromGrammar:(NSString *)g error:(NSError **)outError {
    return [self ASTFromGrammar:g simplify:NO error:outError];
}


- (PKAST *)ASTFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError {
    NSDictionary *tab = [self symbolTableFromGrammar:g simplify:simplify error:outError];
    PKBaseNode *rootNode = tab[@"@start"];
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


- (PKTokenizer *)tokenizerFromSymbolTable:(NSMutableDictionary *)symTab {
    self.wantsCharacters = [self boolForTokenForKey:@"@wantsCharacters" inSymbolTable:symTab];
    
    PKTokenizer *t = [PKTokenizer tokenizer];
    [t.commentState removeSingleLineStartMarker:@"//"];
    [t.commentState removeMultiLineStartMarker:@"/*"];
    
    t.whitespaceState.reportsWhitespaceTokens = [self boolForTokenForKey:@"@reportsWhitespaceTokens" inSymbolTable:symTab];
    t.commentState.reportsCommentTokens = [self boolForTokenForKey:@"@reportsCommentTokens" inSymbolTable:symTab];
    t.commentState.balancesEOFTerminatedComments = [self boolForTokenForKey:@"balancesEOFTerminatedComments" inSymbolTable:symTab];
    t.quoteState.balancesEOFTerminatedQuotes = [self boolForTokenForKey:@"@balancesEOFTerminatedQuotes" inSymbolTable:symTab];
    t.delimitState.balancesEOFTerminatedStrings = [self boolForTokenForKey:@"@balancesEOFTerminatedStrings" inSymbolTable:symTab];
    t.numberState.allowsTrailingDecimalSeparator = [self boolForTokenForKey:@"@allowsTrailingDecimalSeparator" inSymbolTable:symTab];
    t.numberState.allowsScientificNotation = [self boolForTokenForKey:@"@allowsScientificNotation" inSymbolTable:symTab];
    t.numberState.allowsOctalNotation = [self boolForTokenForKey:@"@allowsOctalNotation" inSymbolTable:symTab];
    t.numberState.allowsHexadecimalNotation = [self boolForTokenForKey:@"@allowsHexadecimalNotation" inSymbolTable:symTab];
    
    BOOL yn = YES;
    if (symTab[@"allowsFloatingPoint"]) {
        yn = [self boolForTokenForKey:@"allowsFloatingPoint" inSymbolTable:symTab];
    }
    t.numberState.allowsFloatingPoint = yn;
    
    [self setTokenizerState:t.wordState onTokenizer:t forTokensForKey:@"@wordState" inSymbolTable:symTab];
    [self setTokenizerState:t.numberState onTokenizer:t forTokensForKey:@"@numberState" inSymbolTable:symTab];
    [self setTokenizerState:t.quoteState onTokenizer:t forTokensForKey:@"@quoteState" inSymbolTable:symTab];
    [self setTokenizerState:t.delimitState onTokenizer:t forTokensForKey:@"@delimitState" inSymbolTable:symTab];
    [self setTokenizerState:t.symbolState onTokenizer:t forTokensForKey:@"@symbolState" inSymbolTable:symTab];
    [self setTokenizerState:t.commentState onTokenizer:t forTokensForKey:@"@commentState" inSymbolTable:symTab];
    [self setTokenizerState:t.whitespaceState onTokenizer:t forTokensForKey:@"@whitespaceState" inSymbolTable:symTab];
    
    [self setFallbackStateOn:t.commentState withTokenizer:t forTokensForKey:@"@commentState.fallbackState" inSymbolTable:symTab];
    [self setFallbackStateOn:t.delimitState withTokenizer:t forTokensForKey:@"@delimitState.fallbackState" inSymbolTable:symTab];
    
    NSArray *toks = nil;
    
    // muli-char symbols
    toks = [NSArray arrayWithArray:symTab[@"@symbol"]];
    toks = [toks arrayByAddingObjectsFromArray:symTab[@"@symbols"]];
    [symTab removeObjectForKey:@"@symbol"];
    [symTab removeObjectForKey:@"@symbols"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            [t.symbolState add:[tok.stringValue stringByTrimmingQuotes]];
        }
    }
    
    // wordChars
    toks = [NSArray arrayWithArray:symTab[@"@wordChar"]];
    toks = [toks arrayByAddingObjectsFromArray:symTab[@"@wordChars"]];
    [symTab removeObjectForKey:@"@wordChar"];
    [symTab removeObjectForKey:@"@wordChars"];
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
    toks = [NSArray arrayWithArray:symTab[@"@whitespaceChar"]];
    toks = [toks arrayByAddingObjectsFromArray:symTab[@"@whitespaceChars"]];
    [symTab removeObjectForKey:@"@whitespaceChar"];
    [symTab removeObjectForKey:@"@whitespaceChars"];
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
    toks = [NSArray arrayWithArray:symTab[@"@singleLineComment"]];
    toks = [toks arrayByAddingObjectsFromArray:symTab[@"@singleLineComments"]];
    [symTab removeObjectForKey:@"@singleLineComment"];
    [symTab removeObjectForKey:@"@singleLineComments"];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            NSString *s = [tok.stringValue stringByTrimmingQuotes];
            [t.commentState addSingleLineStartMarker:s];
        }
    }
    
    // multi-line comments
    toks = [NSArray arrayWithArray:symTab[@"@multiLineComment"]];
    toks = [toks arrayByAddingObjectsFromArray:symTab[@"@multiLineComments"]];
    NSAssert(0 == [toks count] % 2, @"@multiLineComments must be specified as quoted strings in multiples of 2");
    [symTab removeObjectForKey:@"@multiLineComment"];
    [symTab removeObjectForKey:@"@multiLineComments"];
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
    toks = [NSArray arrayWithArray:symTab[@"@delimitedString"]];
    toks = [toks arrayByAddingObjectsFromArray:symTab[@"@delimitedStrings"]];
    NSAssert(0 == [toks count] % 3, @"@delimitedString must be specified as quoted strings in multiples of 3");
    [symTab removeObjectForKey:@"@delimitedString"];
    [symTab removeObjectForKey:@"@delimitedStrings"];
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


- (BOOL)boolForTokenForKey:(NSString *)key inSymbolTable:(NSMutableDictionary *)symTab {
    BOOL result = NO;
    NSArray *toks = symTab[key];
    if ([toks count]) {
        PKToken *tok = [toks objectAtIndex:0];
        if (tok.isWord && [tok.stringValue isEqualToString:@"YES"]) {
            result = YES;
        }
    }
    [symTab removeObjectForKey:key];
    return result;
}


- (void)setTokenizerState:(PKTokenizerState *)state onTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key inSymbolTable:(NSMutableDictionary *)symTab {
    NSArray *toks = symTab[key];
    for (PKToken *tok in toks) {
        if (tok.isQuotedString) {
            NSString *s = [tok.stringValue stringByTrimmingQuotes];
            if (1 == [s length]) {
                PKUniChar c = [s characterAtIndex:0];
                [t setTokenizerState:state from:c to:c];
            }
        }
    }
    [symTab removeObjectForKey:key];
}


- (void)setFallbackStateOn:(PKTokenizerState *)state withTokenizer:(PKTokenizer *)t forTokensForKey:(NSString *)key inSymbolTable:(NSMutableDictionary *)symTab {
    NSArray *toks = symTab[key];
    if ([toks count]) {
        PKToken *tok = toks[0];
        if (tok.isWord) {
            PKTokenizerState *fallbackState = [t valueForKey:tok.stringValue];
            if (state != fallbackState) {
                state.fallbackState = fallbackState;
            }
        }
    }
    [symTab removeObjectForKey:key];
}


- (PKParser *)parserFromSymbolTable:(NSMutableDictionary *)symTab {
    NSParameterAssert([symTab count]);
    
    PKBaseNode *rootNode = symTab[@"@start"];
    NSAssert(rootNode, @"");
    
    PKConstructNodeVisitor *v = [[[PKConstructNodeVisitor alloc] init] autorelease];
    
//    NSLog(@"symTab %@", symTab);
//    NSLog(@"rootNode %@", [rootNode treeDescription]);
    
    v.rootNode = rootNode;
    v.parserTable = [NSMutableDictionary dictionaryWithCapacity:[symTab count]];
    v.productionTable = symTab;
    v.assembler = _assembler;
    v.preassembler = _preassembler;
    
    v.assemblerSettingBehavior = _assemblerSettingBehavior;
    
    @autoreleasepool {
        // visit @start first
        [self visit:rootNode with:v];
        [symTab removeObjectForKey:@"@start"];
        
        // visit others
        for (NSString *prodName in symTab) {
            v.currentParser = nil;
            PKBaseNode *node = symTab[prodName];
            NSAssert([node isKindOfClass:[PKBaseNode class]], @"");
            NSAssert(![node isKindOfClass:[PKDefinitionNode class]], @"");
            [self visit:node with:v];
        }
    }
    
    NSAssert([v.parserTable count], @"");
    //NSAssert(v.symTable[@"@start"], @"");
    
    PKParser *p = v.rootParser;
    NSAssert([p isKindOfClass:[PKParser class]], @"");

    return p;
}


- (void)visit:(PKBaseNode *)node with:(id <PKNodeVisitor>)v {
    PKNodeType nodeType = node.type;
    switch (nodeType) {
        case PKNodeTypeDefinition:
            [v visitDefinition:(PKDefinitionNode *)node];
            break;
        case PKNodeTypeReference:
            [v visitReference:(PKReferenceNode *)node];
            break;
        case PKNodeTypeConstant:
            [v visitConstant:(PKConstantNode *)node];
            break;
        case PKNodeTypeLiteral:
            [v visitLiteral:(PKLiteralNode *)node];
            break;
        case PKNodeTypeDelimited:
            [v visitDelimited:(PKDelimitedNode *)node];
            break;
        case PKNodeTypePattern:
            [v visitPattern:(PKPatternNode *)node];
            break;
        case PKNodeTypeComposite:
            [v visitComposite:(PKCompositeNode *)node];
            break;
        case PKNodeTypeCollection:
            [v visitCollection:(PKCollectionNode *)node];
            break;
        case PKNodeTypeOptional:
            [v visitOptional:(PKOptionalNode *)node];
            break;
        case PKNodeTypeMultiple:
            [v visitMultiple:(PKMultipleNode *)node];
            break;
        case PKNodeTypeCardinal:
            [v visitCardinal:(PKCardinalNode *)node];
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
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
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
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    NSString *prodName = @"@start";
    
    PKBaseNode *prodNode = _productionTab[prodName];
    if (!prodNode) {
        prodNode = (PKBaseNode *)[PKDefinitionNode ASTWithToken:_defToken];
        prodNode.parserName = prodName;
        _productionTab[prodName] = prodNode;
    }
    
    [a push:prodNode];

    a.target = prodNode;
}


- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert(islower([tok.stringValue characterAtIndex:0]), @"");
    
    NSString *prodName = tok.stringValue;
    
    PKBaseNode *prodNode = _productionTab[prodName];
    if (!prodNode) {
        prodNode = (PKBaseNode *)[PKDefinitionNode ASTWithToken:_defToken];
        prodNode.parserName = prodName;
        _productionTab[prodName] = prodNode;
    }
    [a push:prodNode];
    
    a.target = prodNode;
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert(islower([tok.stringValue characterAtIndex:0]), @"");

    NSString *prodName = tok.stringValue;

    PKBaseNode *prodNode = _productionTab[prodName];
    if (!prodNode) {
        prodNode = (PKBaseNode *)[PKDefinitionNode ASTWithToken:_defToken];
        prodNode.parserName = prodName;
        _productionTab[prodName] = prodNode;
    }

    prodNode = (PKBaseNode *)[PKReferenceNode ASTWithToken:_refToken];
    prodNode.parserName = prodName;

    [a push:prodNode];
}


- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert(isupper([tok.stringValue characterAtIndex:0]), @"");

    PKAST *parserNode = [PKConstantNode ASTWithToken:tok];
    [a push:parserNode];
}


- (void)parser:(PKParser *)p didMatchSpace:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    NSAssert([tok.stringValue isEqualToString:@"S"], @"");
    
    PKAST *parserNode = [PKWhitespaceNode ASTWithToken:tok];
    [a push:parserNode];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    PKToken *tok = [a pop];
    
    PKAST *litNode = [PKLiteralNode ASTWithToken:tok];
    [a push:litNode];
}


- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

    PKAST *rhs = [a pop];
    PKToken *tok = [a pop]; // '|'
    PKAST *lhs = [a pop];
    
    PKAST *altNode = [PKCollectionNode ASTWithToken:tok];

    for (PKBaseNode *operand in @[lhs, rhs]) {

        while (_seqToken == operand.token && 1 == [operand.children count]) {
            operand = [operand.children lastObject];
        }
        
//        if (_seqToken == operand.token) {
//            NSArray *nodes = operand.children;
//            if (1 == [nodes count]) {
//                operand = [nodes lastObject];
//            }
//        }
        [altNode addChild:operand];
    }

    [a push:altNode];
}


- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a {
    NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    NSArray *nodes = [a objectsAbove:_equals];
    NSAssert(1 == [nodes count], @"");
    
    [a pop]; // '='
    
    PKBaseNode *def = [a pop];
    NSAssert([def isKindOfClass:[PKDefinitionNode class]], @"");
    
    PKBaseNode *parent = def;
    while ([parent.children count] && 1 == [nodes count]); {
        parent = [nodes lastObject];
        nodes = parent.children;
    } 
    
    def.token = parent.token;
    NSAssert(parent.token.isSymbol, @"");
    
    if (1 == [nodes count] && ![nodes[0] parserName]) {
        NSString *parserName = def.parserName;
        def = [nodes lastObject];
        def.parserName = parserName;
        nodes = def.children;
    } else {
        PKToken *tok = [[def.token retain] autorelease];
        NSString *parserName = [[def.parserName retain] autorelease];
        
        Class nodeClass = [self nodeClassForToken:tok];
        def = (PKBaseNode *)[nodeClass ASTWithToken:tok];
        def.parserName = parserName;
        def.token = tok;

        for (PKAST *node in nodes) {
            [def addChild:node];
        }
    }
    

    NSAssert(![def isKindOfClass:[PKDefinitionNode class]], @"");
    _productionTab[def.parserName] = def;
    //NSLog(@"%@", _productionTab);
}


- (Class)nodeClassForToken:(PKToken *)tok {
    NSString *tokStr = tok.stringValue;
    NSAssert([tokStr length], @"");
    
    Class parserClass = _nodeClassForTokenTable[tokStr];
    if (!parserClass) {
        unichar c = [tokStr characterAtIndex:0];
        if ('\'' == c || '"' == c) {
            parserClass = [PKLiteralNode class];
        } else if ('/' == c) {
            parserClass = [PKPatternNode class];
        } else {
            NSLog(@"%@", tokStr);
        }
    }
    //NSAssert1(parserClass, @"unknown node type '%@'", tokStr);
    return parserClass;
}




- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a {
    PKToken *selNameTok2 = [a pop];
    PKToken *selNameTok1 = [a pop];
    PKReferenceNode *node = [a pop];
    
    NSAssert([selNameTok1 isKindOfClass:[PKToken class]], @"");
    NSAssert([selNameTok2 isKindOfClass:[PKToken class]], @"");
    NSAssert(selNameTok1.isWord, @"");
    NSAssert(selNameTok2.isWord, @"");
    
    NSAssert([node isKindOfClass:[PKCollectionNode class]], @"");
    
    NSString *selName = [NSString stringWithFormat:@"%@:%@:", selNameTok1.stringValue, selNameTok2.stringValue];
    node.callbackName = selName;
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

    NSArray *objs = [a objectsAbove:_paren];
    NSAssert([objs count], @"");
    [a pop]; // pop '('
        
    if ([objs count] > 1) {
        PKAST *seqNode = [PKCollectionNode ASTWithToken:_seqToken];
        for (PKAST *child in objs) {
            NSAssert([child isKindOfClass:[PKAST class]], @"");
            [seqNode addChild:child];
        }
        [a push:seqNode];
    } else if ([objs count]) {
        PKBaseNode *node = objs[0];
        
//        while (_seqToken == node.token && 1 == [node.children count]) {
//            node = [node.children lastObject];
//        }
        
        [a push:node];
    }
}


- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKAST *minus = [a pop];
    PKToken *tok = [a pop]; // '-'
    PKAST *sub = [a pop];
    
    NSAssert(tok.isSymbol, @"");
    NSAssert([minus isKindOfClass:[PKAST class]], @"");
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *diffNode = [PKCompositeNode ASTWithToken:tok];
    [diffNode addChild:sub];
    [diffNode addChild:minus];
    
    [a push:diffNode];
}


- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKAST *predicate = [a pop];
    PKToken *tok = [a pop]; // '&'
    PKAST *sub = [a pop];
    
    NSAssert(tok.isSymbol, @"");
    NSAssert([predicate isKindOfClass:[PKAST class]], @"");
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *intNode = [PKCollectionNode ASTWithToken:tok];
    [intNode addChild:sub];
    [intNode addChild:predicate];
    
    [a push:intNode];
}


- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

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
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

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
    
    PKPatternNode *patNode = (PKPatternNode *)[PKPatternNode ASTWithToken:tok];
    patNode.string = re;
    patNode.options = opts;
    
    [a push:patNode];
}


- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a {
    PKBaseNode *node = [a pop];
    NSAssert([node isKindOfClass:[PKBaseNode class]], @"");

    node.discard = YES;
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    NSArray *toks = [a objectsAbove:_paren];
    [a pop]; // discard '(' fence

    PKDelimitedNode *delimNode = (PKDelimitedNode *)[PKDelimitedNode ASTWithToken:_delimToken];

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
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop];
    [a push:[NSNumber numberWithFloat:tok.floatValue]];
}


- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop]; // '*'
    NSAssert(tok.isSymbol, @"");
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *starNode = [PKCompositeNode ASTWithToken:tok];
    
    while (_seqToken == sub.token && 1 == [sub.children count]) {
        sub = [sub.children lastObject];
    }
    
    [starNode addChild:sub];

    [a push:starNode];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop]; // '+'
    NSAssert(tok.isSymbol, @"");
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *plusNode = [PKMultipleNode ASTWithToken:tok];

    while (_seqToken == sub.token && 1 == [sub.children count]) {
        sub = [sub.children lastObject];
    }
    
    [plusNode addChild:sub];
    
    [a push:plusNode];
}


- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKToken *tok = [a pop]; // '?'
    NSAssert(tok.isSymbol, @"");
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    
    PKAST *qNode = [PKOptionalNode ASTWithToken:tok];

    while (_seqToken == sub.token && 1 == [sub.children count]) {
        sub = [sub.children lastObject];
    }
    
    [qNode addChild:sub];
    
    [a push:qNode];
}


- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    PKAST *sub = [a pop];
    NSAssert([sub isKindOfClass:[PKAST class]], @"");
    PKToken *tok = [a pop]; // '~'
    NSAssert(tok.isSymbol, @"");

    //    PKAST *negNode = [PKNodeNegation ASTWithToken:tok];
    PKAST *negNode = [PKCompositeNode ASTWithToken:tok];

    while (_seqToken == sub.token && 1 == [sub.children count]) {
        sub = [sub.children lastObject];
    }
    
    [negNode addChild:sub];
    
    [a push:negNode];
}


- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a {
    NSRange r = [[a pop] rangeValue];
    PKToken *tok = [a pop]; // '{' tok

    PKBaseNode *childNode = [a pop];
    PKCardinalNode *node = (PKCardinalNode *)[PKCardinalNode ASTWithToken:tok];
    
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


- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);

    PKBaseNode *child = [a pop];
    
    [a push:_seqToken];
    [a push:child];
}


- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, a);
    
    NSArray *subs = [a objectsAbove:_seqToken];
    [a pop]; // discard 'SEQ'

    PKCollectionNode *seq = (PKCollectionNode *)[PKCollectionNode ASTWithToken:_seqToken];
    for (PKBaseNode *child in [subs reverseObjectEnumerator]) {
        [seq addChild:child];
    }
    
    [a push:seq];
}

@end
