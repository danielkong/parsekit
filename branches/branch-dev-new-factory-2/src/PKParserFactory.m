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
- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchStartProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a;
- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a;
- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a;
//- (void)parser:(PKParser *)p didMatchTrack:(PKAssembly *)a;
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
@property (nonatomic, retain) NSMutableDictionary *parserTokensTable;
@property (nonatomic, retain) NSMutableDictionary *parserClassTable;
@property (nonatomic, retain) NSMutableDictionary *selectorTable;
@property (nonatomic, assign) BOOL wantsCharacters;
@property (nonatomic, retain) PKToken *equals;
@property (nonatomic, retain) PKToken *curly;
@property (nonatomic, retain) PKToken *paren;
@property (nonatomic, retain) PKToken *square;
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
        self.assemblerSettingBehavior = PKParserFactoryAssemblerSettingBehaviorOnAll;
    }
    return self;
}


- (void)dealloc {
    self.grammarParser = nil;
    self.assembler = nil;
    self.preassembler = nil;
    self.parserTokensTable = nil;
    self.parserClassTable = nil;
    self.selectorTable = nil;
    self.equals = nil;
    self.curly = nil;
    self.paren = nil;
    self.square = nil;
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
        
        PKRootNode *rootNode = (PKRootNode *)[self ASTFromGrammar:g error:outError];
        
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

//    self.callbackTab = [NSMutableDictionary dictionary];
//    self.productionTab = [NSMutableDictionary dictionary];
//
    PKTokenizer *t = [self tokenizerForParsingGrammar];
    t.string = g;

    grammarParser.parser.tokenizer = t;
    [grammarParser.parser parse:g error:outError];

//
//    NSLog(@"%@", _productionTab);
//    
//    PKAST *rootNode = [_productionTab objectForKey:@"@start"];
//    return rootNode;
    
    return nil;
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


- (PKParser *)parserFromAST:(PKBaseNode *)rootNode {
    PKConstructNodeVisitor *v = [[[PKConstructNodeVisitor alloc] init] autorelease];
    
    v.assembler = assembler;
    v.preassembler = preassembler;
    
    [self visit:rootNode with:v];
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
    NSLog(@"%s %@", (char*)_cmd, a);    
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
    NSLog(@"%s %@", (char*)_cmd, a);
//    NSString *prodName = @"@start";
//    
//    PKBaseNode *prodNode = _productionTab[prodName];
//    if (!prodNode) {
//        prodNode = (PKBaseNode *)[PKDefinitionNode ASTWithToken:_defToken];
//        prodNode.parserName = prodName;
//        _productionTab[prodName] = prodNode;
//    }
//    
//    [a push:prodNode];
//    
//    a.target = prodNode;
}


- (void)parser:(PKParser *)p didMatchVarProduction:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *tok = [a pop];
//    NSAssert(tok, @"");
//    NSAssert([tok isKindOfClass:[PKToken class]], @"");
//    NSAssert(tok.isWord, @"");
//    NSAssert(islower([tok.stringValue characterAtIndex:0]), @"");
//    
//    NSString *prodName = tok.stringValue;
//    
//    PKBaseNode *prodNode = _productionTab[prodName];
//    if (!prodNode) {
//        prodNode = (PKBaseNode *)[PKDefinitionNode ASTWithToken:_defToken];
//        prodNode.parserName = prodName;
//        _productionTab[prodName] = prodNode;
//    }
//    [a push:prodNode];
//    
//    a.target = prodNode;
}


- (void)parser:(PKParser *)p didMatchSpace:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
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
    NSLog(@"%s %@", (char*)_cmd, a);
//    NSArray *nodes = [a objectsAbove:_equals];
//    NSAssert(1 == [nodes count], @"");
//    
//    [a pop]; // '='
//    
//    PKBaseNode *def = [a pop];
//    NSAssert([def isKindOfClass:[PKDefinitionNode class]], @"");
//    
//    PKBaseNode *parent = def;
//    while ([parent.children count] && 1 == [nodes count]); {
//        parent = [nodes lastObject];
//        nodes = parent.children;
//    }
//    
//    def.token = parent.token;
//    NSAssert(parent.token.isSymbol, @"");
//    
//    if (1 == [nodes count] && ![nodes[0] parserName]) {
//        NSString *parserName = def.parserName;
//        def = [nodes lastObject];
//        def.parserName = parserName;
//        nodes = def.children;
//    } else {
//        PKToken *tok = [[def.token retain] autorelease];
//        NSString *parserName = [[def.parserName retain] autorelease];
//        
//        Class nodeClass = [self nodeClassForToken:tok];
//        def = (PKBaseNode *)[nodeClass ASTWithToken:tok];
//        def.parserName = parserName;
//        def.token = tok;
//        
//        for (PKAST *node in nodes) {
//            [def addChild:node];
//        }
//    }
//    
//    
//    NSAssert(![def isKindOfClass:[PKDefinitionNode class]], @"");
//    _productionTab[def.parserName] = def;
//    //NSLog(@"%@", _productionTab);
}


- (void)parser:(PKParser *)p didMatchSubExpr:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    
//    NSArray *objs = [a objectsAbove:_paren];
//    NSAssert([objs count], @"");
//    [a pop]; // pop '('
//    
//    if ([objs count] > 1) {
//        PKAST *seqNode = [PKCollectionNode ASTWithToken:_seqToken];
//        for (PKAST *child in objs) {
//            NSAssert([child isKindOfClass:[PKAST class]], @"");
//            [seqNode addChild:child];
//        }
//        [a push:seqNode];
//    } else if ([objs count]) {
//        PKBaseNode *node = objs[0];
//        
//        //        while (_seqToken == node.token && 1 == [node.children count]) {
//        //            node = [node.children lastObject];
//        //        }
//        
//        [a push:node];
//    }
}





- (void)parser:(PKParser *)p didMatchStatement:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    NSArray *toks = [[a objectsAbove:equals] reversedArray];
//    [a pop]; // discard '=' tok
//
//    NSString *parserName = nil;
//    NSString *selName = nil;
//    id obj = [a pop];
//    if ([obj isKindOfClass:[NSString class]]) { // a callback was provided
//        selName = obj;
//        parserName = [[a pop] stringValue];
//    } else {
//        parserName = [obj stringValue];
//    }
//    
//    if (selName) {
//        NSAssert([selName length], @"");
//        [selectorTable setObject:selName forKey:parserName];
//    }
//	NSMutableDictionary *d = a.target;
//    //NSLog(@"parserName: %@", parserName);
//    NSAssert([toks count], @"");
//    
//    // support for multiple @delimitedString = ... tokenizer directives
//    if ([parserName hasPrefix:@"@"]) {
//        // remove whitespace toks from tokenizer directives
//        if (![parserName isEqualToString:@"@start"]) {
//            toks = [self tokens:toks byRemovingTokensOfType:PKTokenTypeWhitespace];
//        }
//        
//        NSArray *existingToks = [d objectForKey:parserName];
//        if ([existingToks count]) {
//            toks = [toks arrayByAddingObjectsFromArray:existingToks];
//        }
//    }
//    
//    [d setObject:toks forKey:parserName];
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
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *selNameTok2 = [a pop];
//    PKToken *selNameTok1 = [a pop];
//    NSString *selName = [NSString stringWithFormat:@"%@:%@:", selNameTok1.stringValue, selNameTok2.stringValue];
//    [a push:selName];
}


- (void)parser:(PKParser *)p didMatchExpression:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    NSParameterAssert(a);
//    id obj = nil;
//    BOOL isTrack = NO;
//    NSMutableArray *objs = [NSMutableArray array];
//    
//    while (![a isStackEmpty]) {
//        obj = [a pop];
//        if ([obj isEqual:square]) {
//            isTrack = YES;
//            break;
//        } else if ([obj isEqual:paren]) {
//            break;
//        } else {
//            [objs addObject:obj];
//        }
//    }
//    
//    NSAssert([objs count], @"");
//    
//    // this implements track via '[' ... ']'. It's a bit ugly. could be improved.
//    if ([objs count] > 1) {
//        PKSequence *seq = nil;
//        if (isTrack) {
//            seq = [PKTrack track];
//        } else {
//            seq = [PKSequence sequence];
//        }
//        
//        for (id obj in [objs reverseObjectEnumerator]) {
//            [seq add:obj];
//        }
//        [a push:seq];
//    } else if ([objs count]) {
//        PKParser *p = [objs objectAtIndex:0];
//        if ([p isKindOfClass:[PKSequence class]] && isTrack) {
//            PKSequence *seq = (PKSequence *)p;
//            PKTrack *tr = [PKTrack track];
//            for (PKParser *sub in seq.subparsers) {
//                [tr add:sub];
//            }
//            p = tr;
//        }
//        [a push:p];
//    }
}


- (void)parser:(PKParser *)p didMatchDifference:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKParser *minus = [a pop];
//    PKParser *sub = [a pop];
//    NSAssert([minus isKindOfClass:[PKParser class]], @"");
//    NSAssert([sub isKindOfClass:[PKParser class]], @"");
//    
//    [a push:[PKDifference differenceWithSubparser:sub minus:minus]];
}


- (void)parser:(PKParser *)p didMatchIntersection:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKParser *predicate = [a pop];
//    PKParser *sub = [a pop];
//    NSAssert([predicate isKindOfClass:[PKParser class]], @"");
//    NSAssert([sub isKindOfClass:[PKParser class]], @"");
//    
//    PKIntersection *inter = [PKIntersection intersection];
//    [inter add:sub];
//    [inter add:predicate];
//    
//    [a push:inter];
}


- (void)parser:(PKParser *)p didMatchPatternOptions:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *tok = [a pop];
//    NSAssert(tok.isWord, @"");
//
//    NSString *s = tok.stringValue;
//    NSAssert([s length] > 0, @"");
//
//    PKPatternOptions opts = PKPatternOptionsNone;
//    if (NSNotFound != [s rangeOfString:@"i"].location) {
//        opts |= PKPatternOptionsIgnoreCase;
//    }
//    if (NSNotFound != [s rangeOfString:@"m"].location) {
//        opts |= PKPatternOptionsMultiline;
//    }
//    if (NSNotFound != [s rangeOfString:@"x"].location) {
//        opts |= PKPatternOptionsComments;
//    }
//    if (NSNotFound != [s rangeOfString:@"s"].location) {
//        opts |= PKPatternOptionsDotAll;
//    }
//    if (NSNotFound != [s rangeOfString:@"w"].location) {
//        opts |= PKPatternOptionsUnicodeWordBoundaries;
//    }
//    
//    [a push:[NSNumber numberWithInteger:opts]];
}


- (void)parser:(PKParser *)p didMatchPattern:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    id obj = [a pop]; // opts (as Number*) or DelimitedString('/', '/')
//    
//    PKPatternOptions opts = PKPatternOptionsNone;
//    if ([obj isKindOfClass:[NSNumber class]]) {
//        opts = [obj integerValue];
//        obj = [a pop];
//    }
//    
//    NSAssert([obj isMemberOfClass:[PKToken class]], @"");
//    PKToken *tok = (PKToken *)obj;
//    NSAssert(tok.isDelimitedString, @"");
//
//    NSString *s = tok.stringValue;
//    NSAssert([s length] > 2, @"");
//    
//    NSAssert([s hasPrefix:@"/"], @"");
//    NSAssert([s hasSuffix:@"/"], @"");
//
//    NSString *re = [s stringByTrimmingQuotes];
//    
//    PKTerminal *t = [PKPattern patternWithString:re options:opts];
//    
//    [a push:t];
}


- (void)parser:(PKParser *)p didMatchDiscard:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    id obj = [a pop];
//    if ([obj isKindOfClass:[PKTerminal class]]) {
//        PKTerminal *t = (PKTerminal *)obj;
//        [t discard];
//    }
//    [a push:obj];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *tok = [a pop];
//
//    NSString *s = [tok.stringValue stringByTrimmingQuotes];
//    PKTerminal *t = nil;
//    
//    NSAssert([s length], @"");
//    if (self.wantsCharacters) {
//        t = [PKSpecificChar specificCharWithChar:[s characterAtIndex:0]];
//    } else {
//        t = [PKCaseInsensitiveLiteral literalWithString:s];
//    }
//
//    [a push:t];
}


- (void)parser:(PKParser *)p didMatchVariable:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *tok = [a pop];
//    NSString *parserName = tok.stringValue;
//    
//    p = nil;
//    if ([parserTokensTable objectForKey:parserName]) {
//        p = [self expandedParserForName:parserName];
//    }
//    [a push:p];
}


- (void)parser:(PKParser *)p didMatchConstant:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *tok = [a pop];
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
    NSLog(@"%s %@", (char*)_cmd, a);
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
    NSLog(@"%s %@", (char*)_cmd, a);
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
    NSLog(@"%s %@", (char*)_cmd, a);
//    PKToken *tok = [a pop];
//    
//    if (self.wantsCharacters) {
//        PKUniChar c = [tok.stringValue characterAtIndex:0];
//        [a push:[PKSpecificChar specificCharWithChar:c]];
//    } else {
//        [a push:[NSNumber numberWithDouble:tok.floatValue]];
//    }
}


- (void)parser:(PKParser *)p didMatchStar:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    id top = [a pop];
//    PKRepetition *rep = [PKRepetition repetitionWithSubparser:top];
//    [a push:rep];
}


- (void)parser:(PKParser *)p didMatchPlus:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    id top = [a pop];
//    [a push:[self oneOrMore:top]];
}


- (void)parser:(PKParser *)p didMatchQuestion:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    id top = [a pop];
//    [a push:[self zeroOrOne:top]];
}


- (void)parser:(PKParser *)p didMatchPhraseCardinality:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
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
}


- (void)parser:(PKParser *)p didMatchCardinality:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    NSArray *toks = [a objectsAbove:self.curly];
//    [a pop]; // discard '{' tok
//
//    NSAssert([toks count] > 0, @"");
//    
//    PKToken *tok = [toks lastObject];
//    PKFloat start = tok.floatValue;
//    PKFloat end = start;
//    if ([toks count] > 1) {
//        tok = [toks objectAtIndex:0];
//        end = tok.floatValue;
//    }
//    
//    NSAssert(start <= end, @"");
//    
//    NSRange r = NSMakeRange(start, end);
//    [a push:[NSValue valueWithRange:r]];
}


- (void)parser:(PKParser *)p didMatchOr:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    id second = [a pop];
//    [a pop]; // pop '|'
//    id first = [a pop];
//    
//    PKAlternation *alt = [PKAlternation alternation];
//    [alt add:first];
//    [alt add:second];
//    [a push:alt];
}


- (void)parser:(PKParser *)p willMatchAnd:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    
//    PKBaseNode *child = [a pop];
//    
//    [a push:_seqToken];
//    [a push:child];
}


- (void)parser:(PKParser *)p didMatchAnd:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    NSMutableArray *parsers = [NSMutableArray array];
//    while (![a isStackEmpty]) {
//        id obj = [a pop];
//        if ([obj isKindOfClass:[PKParser class]]) {
//            [parsers addObject:obj];
//        } else {
//            [a push:obj];
//            break;
//        }
//    }
//    
//    if ([parsers count] > 1) {
//        PKSequence *seq = [PKSequence sequence];
//        for (PKParser *p in [parsers reverseObjectEnumerator]) {
//            [seq add:p];
//        }
//        
//        [a push:seq];
//    } else if (1 == [parsers count]) {
//        [a push:[parsers objectAtIndex:0]];
//    }
}


- (void)parser:(PKParser *)p didMatchNegation:(PKAssembly *)a {
    NSLog(@"%s %@", (char*)_cmd, a);
//    p = [a pop];
//    [a push:[PKNegation negationWithSubparser:p]];
}

@synthesize grammarParser;
@synthesize assembler;
@synthesize preassembler;
@synthesize parserTokensTable;
@synthesize parserClassTable;
@synthesize selectorTable;
@synthesize wantsCharacters;
@synthesize equals;
@synthesize curly;
@synthesize paren;
@synthesize square;
@synthesize assemblerSettingBehavior;
@end
