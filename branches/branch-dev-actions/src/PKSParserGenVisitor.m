//
//  PKSParserGenVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKSParserGenVisitor.h"
#import <ParseKit/ParseKit.h>

#import "PKSParser.h"
#import "PKSTokenKindDescriptor.h"
#import "NSString+ParseKitAdditions.h"

#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

#define CLASS_NAME @"className"
#define TOKEN_KINDS_START_INDEX @"startIndex"
#define TOKEN_KINDS @"tokenKinds"
#define METHODS @"methods"
#define METHOD_NAME @"methodName"
#define METHOD_BODY @"methodBody"
#define TOKEN_KIND @"tokenKind"
#define CHILD_NAME @"childName"
#define DEPTH @"depth"
#define LAST @"last"
#define LOOKAHEAD_SET @"lookaheadSet"
#define OPT_BODY @"optBody"
#define DISCARD @"discard"
#define NEEDS_BACKTRACK @"needsBacktrack"
#define CHILD_STRING @"childString"
#define IF_TEST @"ifTest"
#define ACTION_BODY @"actionBody"
#define PREDICATE_BODY @"predicateBody"
#define PREDICATE @"predicate"

@interface PKSParserGenVisitor ()
- (void)push:(NSMutableString *)mstr;
- (NSMutableString *)pop;
- (NSSet *)lookaheadSetForNode:(PKBaseNode *)node;

@property (nonatomic, retain) NSMutableArray *outputStringStack;
@property (nonatomic, retain) NSString *currentDefName;
@end

@implementation PKSParserGenVisitor

- (id)init {
    self = [super init];
    if (self) {
        [self setUpTemplateEngine];
    }
    return self;
}


- (void)dealloc {
    self.engine = nil;
    self.interfaceOutputString = nil;
    self.implementationOutputString = nil;
    self.outputStringStack = nil;
    self.currentDefName = nil;
    [super dealloc];
}


- (NSString *)templateStringNamed:(NSString *)filename {
    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:@"txt"];
    NSString *template = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    NSAssert([template length], @"");
    if (!template) {
        if (err) NSLog(@"%@", err);
    }
    return template;
}


- (void)setUpTemplateEngine {
    self.engine = [MGTemplateEngine templateEngine];
    _engine.delegate = self;
    _engine.matcher = [ICUTemplateMatcher matcherWithTemplateEngine:_engine];
}


- (void)push:(NSMutableString *)mstr {
    NSParameterAssert([mstr isKindOfClass:[NSMutableString class]]);
    
    [_outputStringStack addObject:mstr];
}


- (NSMutableString *)pop {
    NSAssert([_outputStringStack count], @"");
    NSMutableString *mstr = [[[_outputStringStack lastObject] retain] autorelease];
    [_outputStringStack removeLastObject];

    NSAssert([mstr isKindOfClass:[NSMutableString class]], @"");
    return mstr;
}


- (NSSet *)lookaheadSetForNode:(PKBaseNode *)node {
    NSParameterAssert(node);
    NSAssert(self.symbolTable, @"");

    NSMutableSet *set = [NSMutableSet set];
    
    switch (node.type) {
        case PKNodeTypeConstant: {
            //[set addObject:_tokenKinds[node.token.tokenType]];
            NSString *name = [NSString stringWithFormat:@"TOKEN_KIND_BUILTIN_%@", [node.token.stringValue uppercaseString]];
            PKSTokenKindDescriptor *kind = [PKSTokenKindDescriptor descriptorWithStringValue:name name:name]; // yes, use name for both
            [set addObject:kind];
        } break;
        case PKNodeTypeLiteral: {
            PKLiteralNode *litNode = (PKLiteralNode *)node;
            [set addObject:litNode.tokenKind];
        } break;
        case PKNodeTypeReference: {
            NSString *name = node.token.stringValue;
            PKDefinitionNode *defNode = self.symbolTable[name];
            [set unionSet:[self lookaheadSetForNode:defNode]];
        } break;
        case PKNodeTypeAlternation: {
            for (PKBaseNode *child in node.children) {
                [set unionSet:[self lookaheadSetForNode:child]];
                //break; // single look ahead
            }
        } break;
        default: {
            for (PKBaseNode *child in node.children) {
                [set unionSet:[self lookaheadSetForNode:child]];
                break; // single look ahead
            }
        } break;
    }

    
    return set;
}


- (void)setUpSymbolTableFromRoot:(PKRootNode *)node {
    
    NSUInteger c = [node.children count];
    
    NSMutableDictionary *symTab = [NSMutableDictionary dictionaryWithCapacity:c];
    
    for (PKBaseNode *child in node.children) {
        NSString *key = child.token.stringValue;
        symTab[key] = child;
    }
    
    self.symbolTable = symTab;
}


#pragma mark -
#pragma mark PKVisitor

- (void)visitRoot:(PKRootNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    NSParameterAssert(node);
    
    // setup symbol table
    [self setUpSymbolTableFromRoot:node];
    
    // setup stack
    self.outputStringStack = [NSMutableArray array];

    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[CLASS_NAME] = [NSString stringWithFormat:@"%@Parser", node.grammarName];
    vars[TOKEN_KINDS_START_INDEX] = @(TOKEN_KIND_BUILTIN_ANY + 1);
    vars[TOKEN_KINDS] = node.tokenKinds;
    
    // do interface (header)
    NSString *intTemplate = [self templateStringNamed:@"PKSClassInterfaceTemplate"];
    self.interfaceOutputString = [_engine processTemplate:intTemplate withVariables:vars];
    
    // do impl (.m)
    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];
    
    // recurse
    for (PKBaseNode *child in node.children) {
        [child visit:self];
        
        // pop
        [childStr appendString:[self pop]];
    }
    
    // merge
    vars[METHODS] = childStr;
    NSString *implTemplate = [self templateStringNamed:@"PKSClassImplementationTemplate"];
    self.implementationOutputString = [_engine processTemplate:implTemplate withVariables:vars];

    //NSLog(@"%@", _interfaceOutputString);
    //NSLog(@"%@", _implementationOutputString);
}


- (NSString *)actionStringFrom:(PKBaseNode *)node {
    NSMutableString *result = [NSMutableString string];
    
    if (!self.isSpeculating && node.actionNode) {
        id vars = @{ACTION_BODY: node.actionNode.source, DEPTH: @(_depth)};
        [result appendString:[_engine processTemplate:[self templateStringNamed:@"PKSActionTemplate"] withVariables:vars]];
    }

    return result;
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    self.depth = 1;

    // setup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    if ([methodName isEqualToString:@"@start"]) {
        methodName = @"_start";
    }
    vars[METHOD_NAME] = methodName;
    self.currentDefName = methodName;

    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];

    [childStr appendString:[self actionStringFrom:node]];

    // recurse
    for (PKBaseNode *child in node.children) {
        [child visit:self];

        // pop
        [childStr appendString:[self pop]];
    }

    // merge
    vars[METHOD_BODY] = childStr;
    NSString *template = [self templateStringNamed:@"PKSMethodTemplate"];
    NSMutableString *output = [NSMutableString stringWithString:[_engine processTemplate:template withVariables:vars]];
    
    // push
    [self push:output];
}


- (void)visitReference:(PKReferenceNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
        
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    vars[METHOD_NAME] = methodName;
    vars[DEPTH] = @(_depth);
    vars[DISCARD] = @(node.discard);

    // merge
    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    NSMutableString *output = [NSMutableString stringWithString:[_engine processTemplate:template withVariables:vars]];
    
    [output appendString:[self actionStringFrom:node]];

    // push
    [self push:output];
}


- (void)visitComposite:(PKCompositeNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert(1 == [node.token.stringValue length], @"");
    PKUniChar c = [node.token.stringValue characterAtIndex:0];
    switch (c) {
        case '*':
            [self visitRepetition:node];
            break;
        default:
            NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
            break;
    }
}


// TODO make mutable
- (NSMutableString *)removeTabsAndNewLines:(NSMutableString *)inStr {
    [inStr replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [inStr length])];
    [inStr replaceOccurrencesOfString:@"    " withString:@"" options:0 range:NSMakeRange(0, [inStr length])];
    return inStr;
}


- (void)visitRepetition:(PKCompositeNode *)node {
    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[DEPTH] = @(_depth);
    
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    NSSet *set = [self lookaheadSetForNode:child];

    // setup template
    vars[LOOKAHEAD_SET] = set;
    vars[LAST] = @([set count] - 1);

    // TODO. only need to speculate if this repetition's child is non-terminal
    BOOL isChildTerminal = NO; //[child isKindOfClass:[PKConstantNode class]] || [child isKindOfClass:[PKLiteralNode class]];
    
    // rep body is always wrapped in an while AND an IF. so increase depth twice
    NSInteger depth = isChildTerminal ? 1 : 2;

    // recurse
    self.depth += depth;
    [child visit:self];
    self.depth -= depth;
    
    // pop
    NSMutableString *childStr = [self pop];
    vars[CHILD_STRING] = [[childStr copy] autorelease];
    
    NSString *templateName = @"PKSRepetitionTerminalTemplate";
    if (!isChildTerminal) {
        vars[IF_TEST] = [self removeTabsAndNewLines:childStr];
        templateName = @"PKSRepetitionNonTerminalTemplate";
    }
    
    // repetition
    NSMutableString *output = [NSMutableString stringWithString:[_engine processTemplate:[self templateStringNamed:templateName] withVariables:vars]];

    // action
    [output appendString:[self actionStringFrom:node]];

    // push
    [self push:output];

}


- (void)visitCollection:(PKCollectionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert(1 == [node.token.stringValue length], @"");
    PKUniChar c = [node.token.stringValue characterAtIndex:0];
    switch (c) {
        case '.':
            [self visitSequence:node];
            break;
        default:
            NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
            break;
    }
}


- (void)visitSequence:(PKCollectionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[DEPTH] = @(_depth);
    
    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];
    
    // recurse
    for (PKBaseNode *child in node.children) {
        [child visit:self];
        
        // pop
        [childStr appendString:[self pop]];
    }
    
    [childStr appendString:[self actionStringFrom:node]];

    // push
    [self push:childStr];
    
}


- (NSString *)semanticPredicateForNode:(PKBaseNode *)node throws:(BOOL)throws {
    NSString *result = nil;
    
    if (node.semanticPredicateNode) {
        NSString *predBody = node.semanticPredicateNode.source;
        NSAssert([predBody length], @"");
        BOOL isStat = [predBody rangeOfString:@";"].length > 0;
        
        NSString *templateName = nil;
        if (throws) {
            templateName = isStat ? @"PKSSemanticPredicateTestAndThrowStatTemplate" : @"PKSSemanticPredicateTestAndThrowExprTemplate";
        } else {
            templateName = isStat ? @"PKSSemanticPredicateTestStatTemplate" : @"PKSSemanticPredicateTestExprTemplate";
        }
        
        result = [_engine processTemplate:[self templateStringNamed:templateName] withVariables:@{PREDICATE_BODY: predBody}];
        NSAssert(result, @"");
    }

    return result;
}


- (BOOL)isEmptyNode:(PKBaseNode *)node {
    return [node.token.stringValue isEqualToString:@"Empty"];
}


- (NSMutableString *)recurseAlt:(PKAlternationNode *)node la:(NSMutableArray *)lookaheadSets {
    // setup child str buffer
    NSMutableString *result = [NSMutableString string];
    
    // recurse
    NSUInteger idx = 0;
    for (PKBaseNode *child in node.children) {
        if ([self isEmptyNode:child]) {
            node.hasEmptyAlternative = YES;
            ++idx;
            continue;
        }
        
        id vars = [NSMutableDictionary dictionary];
        
        NSSet *set = lookaheadSets[idx];
        vars[LOOKAHEAD_SET] = set;
        vars[LAST] = @([set count] - 1);
        vars[DEPTH] = @(_depth);
        vars[NEEDS_BACKTRACK] = @(_needsBacktracking);

        NSString *predStr = [self semanticPredicateForNode:child throws:NO];
        if (predStr) vars[PREDICATE] = predStr;

        // process template. cannot test `idx` here to determine `if` vs `else` due to possible Empty child borking `idx`
        NSString *templateName = [result length] ? @"PKSPredictElseIfTemplate" : @"PKSPredictIfTemplate";
        NSString *output = [_engine processTemplate:[self templateStringNamed:templateName] withVariables:vars];
        [result appendString:output];
        
        self.depth++;
        [child visit:self];
        self.depth--;
        
        // pop
        [result appendString:[self pop]];

        ++idx;
    }
    
    return result;
}


- (NSMutableString *)recurseAltForBracktracking:(PKAlternationNode *)node la:(NSMutableArray *)lookaheadSets {
    // setup child str buffer
    NSMutableString *result = [NSMutableString string];
    
    // recurse
    NSUInteger idx = 0;
    for (PKBaseNode *child in node.children) {
        if ([self isEmptyNode:child]) {
            node.hasEmptyAlternative = YES;
            ++idx;
            continue;
        }

        // recurse first and get entire child str
        self.depth++;

        // visit for speculative if test
        self.isSpeculating = YES;
        [child visit:self];
        self.isSpeculating = NO;
        NSString *ifTest = [self removeTabsAndNewLines:[self pop]];

        // visit for child body
        [child visit:self];
        NSString *childBody = [self pop];
        self.depth--;

        // setup vars
        id vars = [NSMutableDictionary dictionary];
        vars[DEPTH] = @(_depth);
        vars[NEEDS_BACKTRACK] = @(_needsBacktracking);
        vars[CHILD_STRING] = ifTest;
        
        NSString *predStr = [self semanticPredicateForNode:child throws:YES];
        if (predStr) vars[PREDICATE] = predStr;

        // process template. cannot test `idx` here to determine `if` vs `else` due to possible Empty child borking `idx`
        NSString *templateName = [result length] ? @"PKSSpeculateElseIfTemplate" : @"PKSSpeculateIfTemplate";
        NSString *output = [_engine processTemplate:[self templateStringNamed:templateName] withVariables:vars];

        [result appendString:output];
        [result appendString:childBody];

        ++idx;
    }
    
    return result;
}


- (void)visitAlternation:(PKAlternationNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // first fetch all child lookahead sets
    NSMutableArray *lookaheadSets = [NSMutableArray arrayWithCapacity:[node.children count]];
    NSMutableSet *overlap = nil;
    
    for (PKBaseNode *child in node.children) {
        NSSet *set = [self lookaheadSetForNode:child];
        [lookaheadSets addObject:set];
        
        if (overlap) {
            [overlap intersectSet:set]; // rest
        } else {
            overlap = [NSMutableSet set];
            [overlap unionSet:set]; // first
        }
    }
    
    //NSLog(@"%@", lookaheadSets);
    self.needsBacktracking = [overlap count];
    
    NSMutableString *childStr = nil;
    if (_needsBacktracking) {
        childStr = [self recurseAltForBracktracking:node la:lookaheadSets];
    } else {
        childStr = [self recurseAlt:node la:lookaheadSets];
    }

    self.needsBacktracking = NO;

    id vars = [NSMutableDictionary dictionary];
    vars[METHOD_NAME] = _currentDefName;
    vars[DEPTH] = @(_depth);
    
    NSString *elseStr = nil;
    if (node.hasEmptyAlternative) {
        elseStr = [_engine processTemplate:[self templateStringNamed:@"PKSPredictEndIfTemplate"] withVariables:vars];
    } else {
        elseStr = [_engine processTemplate:[self templateStringNamed:@"PKSPredictElseTemplate"] withVariables:vars];
    }
    [childStr appendString:elseStr];

    // push
    [self push:childStr];
}


- (void)visitOptional:(PKOptionalNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[DEPTH] = @(_depth);

    // recurse
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    NSSet *set = [self lookaheadSetForNode:child];
    vars[LOOKAHEAD_SET] = set;
    vars[LAST] = @([set count] - 1);

    NSMutableString *output = [NSMutableString string];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSOptionalStartTemplate"] withVariables:vars]];
    
    self.depth++;
    [child visit:self];
    self.depth--;
    
    // pop
    NSString *childStr = [self pop];
    [output appendString:childStr];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSOptionalEndTemplate"] withVariables:vars]];

    [output appendString:[self actionStringFrom:node]];

    // push
    [self push:output];
}


- (void)visitMultiple:(PKMultipleNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[DEPTH] = @(_depth);
    
    // recurse
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    NSSet *set = [self lookaheadSetForNode:child];
    vars[LOOKAHEAD_SET] = set;
    vars[LAST] = @([set count] - 1);

    NSMutableString *output = [NSMutableString string];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSMultipleStartTemplate"] withVariables:vars]];
    
    self.depth++;
    [child visit:self];
    self.depth--;
    
    // pop
    NSString *childStr = [self pop];
    [output appendString:childStr];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSMultipleEndTemplate"] withVariables:vars]];
    
    [output appendString:[self actionStringFrom:node]];

    // push
    [self push:output];
}


- (void)visitConstant:(PKConstantNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
   
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    vars[METHOD_NAME] = methodName;
    vars[DEPTH] = @(_depth);
    vars[DISCARD] = @(node.discard);
    
    // merge
    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    NSMutableString *output = [NSMutableString stringWithString:[_engine processTemplate:template withVariables:vars]];
    
    [output appendString:[self actionStringFrom:node]];

    // push
    [self push:output];
}


- (void)visitLiteral:(PKLiteralNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    vars[TOKEN_KIND] = node.tokenKind;
    vars[DEPTH] = @(_depth);
    vars[DISCARD] = @(node.discard);

    // merge
    NSString *template = [self templateStringNamed:@"PKSMatchCallTemplate"];
    NSMutableString *output = [NSMutableString stringWithString:[_engine processTemplate:template withVariables:vars]];
    
    [output appendString:[self actionStringFrom:node]];

    // push
    [self push:output];
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)visitPattern:(PKPatternNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)visitAction:(PKActionNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


#pragma mark -
#pragma mark MGTemplateEngineDelegate

- (void)templateEngine:(MGTemplateEngine *)engine blockStarted:(NSDictionary *)blockInfo {
    
}


- (void)templateEngine:(MGTemplateEngine *)engine blockEnded:(NSDictionary *)blockInfo {
    
}


- (void)templateEngineFinishedProcessingTemplate:(MGTemplateEngine *)engine {
    
}


- (void)templateEngine:(MGTemplateEngine *)engine encounteredError:(NSError *)error isContinuing:(BOOL)continuing {
    NSLog(@"%@", error);
}

@end
