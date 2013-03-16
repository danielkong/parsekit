//
//  PKParserFactory.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 12/12/08.
//  Copyright 2009 Todd Ditchendorf All rights reserved.
//

#import "PKParserFactory.h"
#import <ParseKit/ParseKit.h>
#import "PKGrammarParser.h"
#import "NSString+ParseKitAdditions.h"
#import "NSArray+ParseKitAdditions.h"

#import "PKAST.h"
#import "PKBaseNode.h"
#import "PKRootNode.h"
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
//- (void)setAssemblerForParser:(PKParser *)p;
- (NSArray *)tokens:(NSArray *)toks byRemovingTokensOfType:(PKTokenType)tt;
- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName;
- (NSString *)defaultPreassemblerSelectorNameForParserName:(NSString *)parserName;

- (PKAlternation *)zeroOrOne:(PKParser *)p;
- (PKSequence *)oneOrMore:(PKParser *)p;

- (void)parser:(PKParser *)p didMatchTokenizerDirective:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchTrackExpr:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStartProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a;
//- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a;
//- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSpace:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchSpecificConstant:(PKAssembly *)a;
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
//@property (nonatomic, retain) NSMutableDictionary *parserTokensTable;
//@property (nonatomic, retain) NSMutableDictionary *parserClassTable;
//@property (nonatomic, retain) NSMutableDictionary *selectorTable;

@property (nonatomic, retain) PKRootNode *rootNode;
@property (nonatomic, assign) BOOL wantsCharacters;
@property (nonatomic, retain) PKToken *equals;
@property (nonatomic, retain) PKToken *curly;
@property (nonatomic, retain) PKToken *paren;
@property (nonatomic, retain) PKToken *square;

@property (nonatomic, retain) PKToken *defToken;
@property (nonatomic, retain) PKToken *refToken;
@property (nonatomic, retain) PKToken *seqToken;
@property (nonatomic, retain) PKToken *orToken;
@property (nonatomic, retain) PKToken *trackToken;
@property (nonatomic, retain) PKToken *diffToken;
@property (nonatomic, retain) PKToken *intToken;
@property (nonatomic, retain) PKToken *optToken;
@property (nonatomic, retain) PKToken *multiToken;
@property (nonatomic, retain) PKToken *repToken;
@property (nonatomic, retain) PKToken *cardToken;
@property (nonatomic, retain) PKToken *negToken;
@property (nonatomic, retain) PKToken *patToken;
@property (nonatomic, retain) PKToken *litToken;
@end

@implementation PKParserFactory

+ (PKParserFactory *)factory {
    return [[[PKParserFactory alloc] init] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.grammarParser = [[[PKGrammarParser alloc] initWithAssembler:self] autorelease];
        self.equals  = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"=" floatValue:0.0];
        self.curly   = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
        self.paren   = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" floatValue:0.0];
        self.square  = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"[" floatValue:0.0];

        self.defToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"$" floatValue:0.0];
        self.refToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"#" floatValue:0.0];
        self.seqToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"." floatValue:0.0];
        self.orToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"|" floatValue:0.0];
        self.trackToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"[" floatValue:0.0];
        self.diffToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"-" floatValue:0.0];
        self.intToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"&" floatValue:0.0];
        self.optToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"?" floatValue:0.0];
        self.multiToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"+" floatValue:0.0];
        self.repToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"*" floatValue:0.0];
        self.cardToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0.0];
        self.negToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"~" floatValue:0.0];
        self.patToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"/" floatValue:0.0];
        self.litToken = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"'" floatValue:0.0];
        
        self.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorOnAll;
    }
    return self;
}


- (void)dealloc {
    self.grammarParser = nil;
    self.assembler = nil;
    self.preassembler = nil;
//    self.parserTokensTable = nil;
//    self.parserClassTable = nil;
//    self.selectorTable = nil;
    self.rootNode = nil;
    self.equals = nil;
    self.curly = nil;
    self.paren = nil;
    self.square = nil;
    self.defToken = nil;
    self.refToken = nil;
    self.seqToken = nil;
    self.orToken = nil;
    self.diffToken = nil;
    self.intToken = nil;
    self.optToken = nil;
    self.multiToken = nil;
    self.repToken = nil;
    self.cardToken = nil;
    self.negToken = nil;
    self.patToken = nil;
    self.litToken = nil;
    [super dealloc];
}


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


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError {
    return [self parserFromGrammar:g assembler:a preassembler:nil error:outError];
}


- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError {
    PKParser *result = nil;

    @try {
        self.assembler = a;
        self.preassembler = pa;
        
        self.rootNode = (PKRootNode *)[self ASTFromGrammar:g error:outError];
        
        NSLog(@"rootNode %@", rootNode);
        
        PKTokenizer *t = [self tokenizerFromGrammarSettings];
        PKParser *start = [self parserFromAST:rootNode];
        
        NSLog(@"start %@", start);
        
        self.assembler = nil;
//        self.callbackTab = nil;
//        self.productionTab = nil;
        
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
    return [self ASTFromGrammar:g simplify:NO error:outError]; // simplify ??
}


- (PKAST *)ASTFromGrammar:(NSString *)g simplify:(BOOL)simplify error:(NSError **)outError {
    PKToken *rootTok = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"ROOT" floatValue:0.0];
    
    self.rootNode = [[[PKRootNode alloc] initWithToken:rootTok] autorelease];
    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = g;

    grammarParser.parser.tokenizer = t;
    [grammarParser.parser parse:g error:outError];
    
    return rootNode;
}


#pragma mark -
#pragma mark Private

- (PKTokenizer *)tokenizerForParsingGrammar {
    PKTokenizer *t = [PKTokenizer tokenizer];
    
    t.whitespaceState.reportsWhitespaceTokens = YES;
    
    // customize tokenizer to find tokenizer customization directives
    [t setTokenizerState:t.wordState from:'@' to:'@'];
    
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
    //TODO
    return [PKTokenizer tokenizer];
}


- (PKParser *)parserFromAST:(PKRootNode *)node {
    PKConstructNodeVisitor *v = [[[PKConstructNodeVisitor alloc] init] autorelease];
    
    v.assembler = assembler;
    v.preassembler = preassembler;
    
    [self visit:node with:v];
    PKParser *p = v.rootParser;
    return p;
}


- (void)visit:(PKBaseNode *)node with:(id <PKNodeVisitor>)v {
    PKNodeType nodeType = node.type;
    switch (nodeType) {
        case PKNodeTypeRoot:
            [v visitRoot:(PKRootNode *)node];
            break;
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


- (void)parser:(PKParser *)p didMatchTokenizerDirective:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//    NSArray *argToks = [[self tokens:[a objectsAbove:_equals] byRemovingTokensOfType:PKTokenTypeWhitespace] reversedArray];
//    //NSArray *argToks = [a objectsAbove:_equals];
//    [a pop]; // discard '='
//    
//    PKToken *nameTok = [a pop];
//    NSAssert(nameTok, @"");
//    NSAssert([nameTok isKindOfClass:[PKToken class]], @"");
//    NSAssert(nameTok.isWord, @"");
//    
//    NSString *prodName = [NSString stringWithFormat:@"@%@", nameTok.stringValue];
//    
//    [_productionTab setObject:argToks forKey:prodName];
}


- (void)parser:(PKParser *)p didMatchStartProduction:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    
    NSString *parserName = @"@start";
    NSAssert([parserName length], @"");
    NSAssert('@' == [parserName characterAtIndex:0], @"");
    
    // parser:didMatchVarProduction: [@start, =, foo, foo]@start/=/foo/;/foo^=/Word/;
    PKDefinitionNode *node = [PKDefinitionNode nodeWithToken:self.defToken parserName:parserName];
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    
    NSString *parserName = tok.stringValue;
    NSAssert([parserName length], @"");
    NSAssert(islower([parserName characterAtIndex:0]), @"");

    // parser:didMatchVarProduction: [@start, =, foo, foo]@start/=/foo/;/foo^=/Word/;
    PKDefinitionNode *node = [PKDefinitionNode nodeWithToken:self.defToken parserName:parserName];
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchSpace:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//    PKToken *tok = [a pop];
//    NSAssert(tok, @"");
//    NSAssert([tok isKindOfClass:[PKToken class]], @"");
//    NSAssert(tok.isWord, @"");
//    NSAssert([tok.stringValue isEqualToString:@"S"], @"");
//    
//    PKAST *parserNode = [PKWhitespaceNode ASTWithToken:tok];
//    [a push:parserNode];
}


- (void)parser:(PKParser *)p didMatchDecl:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    NSArray *nodes = [a objectsAbove:equals];
    NSAssert([nodes count], @"");

    [a pop]; // '='
    
    PKDefinitionNode *defNode = [a pop];
    NSAssert([defNode isKindOfClass:[PKDefinitionNode class]], @"");
        
    PKBaseNode *node = nil;
    
    if (1 == [nodes count]) {
        node = [nodes lastObject];
    } else {
        PKCollectionNode *seqNode = [PKCollectionNode nodeWithToken:seqToken];
        for (PKBaseNode *child in [nodes reverseObjectEnumerator]) {
            NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
            [seqNode addChild:child];
        }
        node = seqNode;
    }
    
    [defNode addChild:node];

    [self.rootNode addChild:defNode];
}


- (void)parser:(PKParser *)p didMatchTrackExpr:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
    NSArray *nodes = [a objectsAbove:square];
    NSAssert([nodes count], @"");
    [a pop]; // pop '['
    
    PKCollectionNode *trackNode = [PKCollectionNode nodeWithToken:trackToken];

    if ([nodes count] > 1) {
        for (PKBaseNode *child in [nodes reverseObjectEnumerator]) {
            NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
            [trackNode addChild:child];
        }
    } else if ([nodes count]) {
        PKBaseNode *node = [nodes lastObject];
        if (seqToken == node.token) {
            PKCollectionNode *seqNode = (PKCollectionNode *)node;
            NSAssert([seqNode isKindOfClass:[PKCollectionNode class]], @"");

            for (PKBaseNode *child in seqNode.children) {
                [trackNode addChild:child];
            }
        } else {
            [trackNode addChild:node];
        }
        
    }
    [a push:trackNode];
}


- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
    NSArray *nodes = [a objectsAbove:paren];
    NSAssert([nodes count], @"");
    [a pop]; // pop '('
    
    PKBaseNode *node = nil;
    
    if (1 == [nodes count]) {
        node = [nodes lastObject];
    } else {
        PKCollectionNode *seqNode = [PKCollectionNode nodeWithToken:seqToken];
        for (PKBaseNode *child in [nodes reverseObjectEnumerator]) {
            NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
            [seqNode addChild:child];
        }
        node = seqNode;
    }
    
    [a push:node];
}


- (NSArray *)tokens:(NSArray *)toks byRemovingTokensOfType:(PKTokenType)tt {
    NSMutableArray *res = [NSMutableArray array];
    for (PKToken *tok in toks) {
        if (PKTokenTypeWhitespace != tok.tokenType) {
            [res addObject:tok];
        }
    }
    return res;
}


- (NSString *)defaultAssemblerSelectorNameForParserName:(NSString *)parserName {
    NSString *prefix = nil;
    if ([parserName hasPrefix:@"@"]) {
        //        parserName = [parserName substringFromIndex:1];
        //        prefix = @"parser:didMatch_";
        return nil;
    } else {
        prefix = @"parser:didMatch";
    }
    NSString *s = [NSString stringWithFormat:@"%@%@", [[parserName substringToIndex:1] uppercaseString], [parserName substringFromIndex:1]]; 
    return [NSString stringWithFormat:@"%@%@:", prefix, s];
}


- (NSString *)defaultPreassemblerSelectorNameForParserName:(NSString *)parserName {
    NSString *prefix = nil;
    if ([parserName hasPrefix:@"@"]) {
        return nil;
    } else {
        prefix = @"parser:willMatch";
    }
    NSString *s = [NSString stringWithFormat:@"%@%@", [[parserName substringToIndex:1] uppercaseString], [parserName substringFromIndex:1]]; 
    return [NSString stringWithFormat:@"%@%@:", prefix, s];
}


- (void)parser:(PKParser *)p didMatchCallback:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//    PKToken *selNameTok2 = [a pop];
//    PKToken *selNameTok1 = [a pop];
//    NSString *selName = [NSString stringWithFormat:@"%@:%@:", selNameTok1.stringValue, selNameTok2.stringValue];
//    [a push:selName];
}


- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
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
    
    [a push:[NSNumber numberWithUnsignedInteger:opts]];
}


- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    id obj = [a pop]; // opts (as Number*) or DelimitedString('/', '/')
    
    PKPatternOptions opts = PKPatternOptionsNone;
    if ([obj isKindOfClass:[NSNumber class]]) {
        opts = [obj unsignedIntegerValue];
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
    
    PKPatternNode *patNode = [PKPatternNode nodeWithToken:patToken];
    patNode.string = re;
    patNode.options = opts;

    [a push:patNode];
}


- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);

//    id obj = [a pop];
//    if ([obj isKindOfClass:[PKTerminal class]]) {
//        PKTerminal *t = (PKTerminal *)obj;
//        [t discard];
//    }
//    [a push:obj];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    PKToken *tok = [a pop];

    NSString *s = [tok.stringValue stringByTrimmingQuotes];
    PKLiteralNode *litNode = nil;
    
    NSAssert([s length], @"");
    if (self.wantsCharacters) {
        litNode = [PKLiteralNode nodeWithToken:litToken parserName:s]; // ??
    } else {
        litNode = [PKLiteralNode nodeWithToken:litToken parserName:s];
    }

    [a push:litNode];
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    // parser:didMatchVariable: [@start, =, foo]@start/=/foo^;/foo/=/Word/;

    PKToken *tok = [a pop];
    NSAssert(tok, @"");
    NSAssert([tok isKindOfClass:[PKToken class]], @"");
    NSAssert(tok.isWord, @"");
    
    NSString *parserName = tok.stringValue;
    NSAssert([parserName length], @"");
    NSAssert(islower([parserName characterAtIndex:0]), @"");

    PKReferenceNode *node = [PKReferenceNode nodeWithToken:self.refToken parserName:parserName];
    [a push:node];
}


- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    PKToken *tok = [a pop];
    
    PKConstantNode *node = [PKConstantNode nodeWithToken:tok];
    [a push:node];
    
    // KEEP FOR VISITOR!!!!!!!!!!!!!
//    NSString *s = tok.stringValue;
//    
//    id obj = nil;
//    if ([s isEqualToString:@"Word"]) {
//        obj = [PKWord word];
//    } else if ([s isEqualToString:@"LowercaseWord"]) {
//        obj = [PKLowercaseWord word];
//    } else if ([s isEqualToString:@"UppercaseWord"]) {
//        obj = [PKUppercaseWord word];
//    } else if ([s isEqualToString:@"Number"]) {
//        obj = [PKNumber number];
//    } else if ([s isEqualToString:@"S"]) {
//        obj = [PKWhitespace whitespace];
//    } else if ([s isEqualToString:@"QuotedString"]) {
//        obj = [PKQuotedString quotedString];
//    } else if ([s isEqualToString:@"Symbol"]) {
//        obj = [PKSymbol symbol];
//    } else if ([s isEqualToString:@"Comment"]) {
//        obj = [PKComment comment];
//    } else if ([s isEqualToString:@"Any"]) {
//        obj = [PKAny any];
//    } else if ([s isEqualToString:@"Empty"]) {
//        obj = [PKEmpty empty];
//    } else if ([s isEqualToString:@"Char"]) {
//        obj = [PKChar char];
//    } else if ([s isEqualToString:@"Letter"]) {
//        obj = [PKLetter letter];
//    } else if ([s isEqualToString:@"Digit"]) {
//        obj = [PKDigit digit];
//    } else if ([s isEqualToString:@"Pattern"]) {
//        obj = tok;
//    } else if ([s isEqualToString:@"DelimitedString"]) {
//        obj = tok;
//    } else if ([s isEqualToString:@"YES"] || [s isEqualToString:@"NO"]) {
//        obj = tok;
//    } else {
//        [NSException raise:@"Grammar Exception" format:
//         @"User Grammar referenced a constant parser name (uppercase word) which is not supported: %@. Must be one of: Word, LowercaseWord, UppercaseWord, QuotedString, Number, Symbol, Empty.", s];
//    }
//    
//    [a push:obj];
}


- (void)parser:(PKParser *)p didMatchSpecificConstant:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//    PKToken *quoteTok = [a pop];
//    NSString *str = [quoteTok.stringValue stringByTrimmingQuotes];
//    
//    [a pop]; // pop 'Symbol'
//    
//    PKParser *sym = [PKSymbol symbolWithString:str];
//    
//    [a push:sym];
}


- (void)parser:(PKParser *)p didMatchDelimitedString:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//    NSArray *toks = [a objectsAbove:paren];
//    [a pop]; // discard '(' fence
//    
//    NSAssert([toks count] > 0 && [toks count] < 3, @"");
//    NSString *start = [[[toks lastObject] stringValue] stringByTrimmingQuotes];
//    NSString *end = nil;
//    if ([toks count] > 1) {
//        end = [[[toks objectAtIndex:0] stringValue] stringByTrimmingQuotes];
//    }
//
//    PKTerminal *t = [PKDelimitedString delimitedStringWithStartMarker:start endMarker:end];
//    
//    [a push:t];
}


- (void)parser:(PKParser *)p didMatchNum:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    PKToken *tok = [a pop];
    
    if (self.wantsCharacters) {
        PKUniChar c = [tok.stringValue characterAtIndex:0];
        [a push:[PKSpecificChar specificCharWithChar:c]];
    } else {
        [a push:[NSNumber numberWithDouble:tok.floatValue]];
    }
}


- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    PKBaseNode *minusNode = [a pop];
    PKBaseNode *subNode = [a pop];
    NSAssert([minusNode isKindOfClass:[PKBaseNode class]], @"");
    NSAssert([subNode isKindOfClass:[PKBaseNode class]], @"");
    
    PKCollectionNode *diffNode = [PKCollectionNode nodeWithToken:diffToken];
    [diffNode addChild:subNode];
    [diffNode addChild:minusNode];
    
    [a push:diffNode];
}


- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    PKBaseNode *predicateNode = [a pop];
    PKBaseNode *subNode = [a pop];
    NSAssert([predicateNode isKindOfClass:[PKBaseNode class]], @"");
    NSAssert([subNode isKindOfClass:[PKBaseNode class]], @"");
    
    PKCollectionNode *diffNode = [PKCollectionNode nodeWithToken:intToken];
    [diffNode addChild:subNode];
    [diffNode addChild:predicateNode];
    
    [a push:diffNode];
}


- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
    PKBaseNode *subNode = [a pop];
    NSAssert([subNode isKindOfClass:[PKBaseNode class]], @"");
    
    PKCollectionNode *repNode = [PKCollectionNode nodeWithToken:repToken];
    [repNode addChild:subNode];
    
    [a push:repNode];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
    PKBaseNode *subNode = [a pop];
    NSAssert([subNode isKindOfClass:[PKBaseNode class]], @"");
    
    PKCollectionNode *multiNode = [PKCollectionNode nodeWithToken:multiToken];
    [multiNode addChild:subNode];
    
    [a push:multiNode];
}


- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
    PKBaseNode *subNode = [a pop];
    NSAssert([subNode isKindOfClass:[PKBaseNode class]], @"");
    
    PKCollectionNode *optNode = [PKCollectionNode nodeWithToken:optToken];
    [optNode addChild:subNode];
    
    [a push:optNode];
}


- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);

    PKBaseNode *subNode = [a pop];
    NSAssert([subNode isKindOfClass:[PKBaseNode class]], @"");
    
    PKCollectionNode *negNode = [PKCollectionNode nodeWithToken:negToken];
    [negNode addChild:subNode];
    
    [a push:negNode];
}


- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    
    // KEEP THIS FOR VISITOR!!!!!!!!!!!!!
    //    NSRange r = [[a pop] rangeValue];
    //
    //    p = [a pop];
    //    PKSequence *s = [PKSequence sequence];
    //
    //    NSInteger start = r.location;
    //    NSInteger end = r.length;
    //
    //    for (NSInteger i = 0; i < start; i++) {
    //        [s add:p];
    //    }
    //
    //    for (NSInteger i = start ; i < end; i++) {
    //        [s add:[self zeroOrOne:p]];
    //    }
    //    
    //    [a push:s];

    
    NSRange r = [[a pop] rangeValue];
    
    PKBaseNode *child = [a pop];
    NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
    
    PKCardinalNode *cardNode = [PKCardinalNode nodeWithToken:cardToken];
    
    NSInteger start = r.location;
    NSInteger end = r.length;
    
    cardNode.rangeStart = start;
    cardNode.rangeEnd = end;
    
    [cardNode addChild:child];

    [a push:cardNode];
}


- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
    NSArray *nums = [a objectsAbove:self.curly];
    [a pop]; // discard '{' tok

    NSAssert([nums count] > 0, @"");
    
    NSNumber *n = [nums lastObject];
    PKFloat start = [n doubleValue];
    PKFloat end = start;
    if ([nums count] > 1) {
        n = nums[0];
        end = [n doubleValue];
    }
    
    NSAssert(start <= end, @"");
    
    NSRange r = NSMakeRange(start, end);
    [a push:[NSValue valueWithRange:r]];
}


- (NSArray *)objectsAbove:(PKToken *)tokA or:(PKToken *)tokB in:(PKAssembly *)a {
    NSMutableArray *result = [NSMutableArray array];
    
    while (![a isStackEmpty]) {
        id obj = [a pop];
        if ([obj isEqual:tokA] || [obj isEqual:tokB]) {
            [a push:obj];
            break;
        }
        [result addObject:obj];
    }
    
    return result;
}


- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);

    NSArray *rhsNodes = [a objectsAbove:orToken];
    
    PKToken *orTok = [a pop]; // pop '|'
    NSAssert([orTok isKindOfClass:[PKToken class]], @"");
    NSAssert(orTok.isSymbol, @"");
    NSAssert([orTok.stringValue isEqualToString:@"|"], @"");

    PKCollectionNode *orNode = [PKCollectionNode nodeWithToken:orTok parserName:nil];
    
    PKBaseNode *left = nil;

    NSArray *lhsNodes = [self objectsAbove:paren or:equals in:a];
    if (1 == [lhsNodes count]) {
        left = [lhsNodes lastObject];
    } else {
        PKCollectionNode *seqNode = [PKCollectionNode nodeWithToken:seqToken];
        for (PKBaseNode *child in [lhsNodes reverseObjectEnumerator]) {
            NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
            [seqNode addChild:child];
        }
        left = seqNode;
    }
    [orNode addChild:left];

    PKBaseNode *right = nil;

    if (1 == [rhsNodes count]) {
        right = [rhsNodes lastObject];
    } else {
        PKCollectionNode *seqNode = [PKCollectionNode nodeWithToken:seqToken];
        for (PKBaseNode *child in [rhsNodes reverseObjectEnumerator]) {
            NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
            [seqNode addChild:child];
        }
        right = seqNode;
    }
    [orNode addChild:right];

    [a push:orNode];
}


//- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a {
//    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//
//    PKBaseNode *child = [a pop];
//    PKCollectionNode *seqNode = nil;
//    
//    if (child.token == seqToken) {
//        NSAssert([child isKindOfClass:[PKCollectionNode class]], @"");
//
//        seqNode = (PKCollectionNode *)child;
//    } else {
//        NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
//        
//        seqNode = [PKCollectionNode nodeWithToken:seqToken];
//        [seqNode addChild:child];
//    }
//    
//    [a push:seqNode];
//}
//
//
//- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a {
//    NSLog(@"%@ %@", NSStringFromSelector(_cmd), a);
//
//    PKBaseNode *child = [a pop];
//    NSAssert([child isKindOfClass:[PKBaseNode class]], @"");
//    
//    PKCollectionNode *seqNode = [a pop];
//    NSAssert([seqNode isKindOfClass:[PKCollectionNode class]], @"");
//
//    [seqNode addChild:child];
//    [a push:seqNode];
//
//}

@synthesize grammarParser;
@synthesize assembler;
@synthesize preassembler;
//@synthesize parserTokensTable;
//@synthesize parserClassTable;
//@synthesize selectorTable;
@synthesize rootNode;
@synthesize wantsCharacters;
@synthesize equals;
@synthesize curly;
@synthesize paren;
@synthesize square;

@synthesize defToken;
@synthesize refToken;
@synthesize seqToken;
@synthesize orToken;
@synthesize trackToken;
@synthesize diffToken;
@synthesize intToken;
@synthesize optToken;
@synthesize multiToken;
@synthesize repToken;
@synthesize cardToken;
@synthesize negToken;
@synthesize patToken;
@synthesize litToken;

@synthesize assemblerSettingBehavior;
@end
