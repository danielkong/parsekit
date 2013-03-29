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
#define LOOKAHEAD_SET @"lookaheadSet"
#define OPT_BODY @"optBody"
#define DISCARD @"discard"
#define NEEDS_BACKTRACK @"needsBacktrack"

@interface PKSParserGenVisitor ()
- (void)push:(NSString *)mstr;
- (NSString *)pop;
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


- (void)push:(NSString *)mstr {
    NSParameterAssert([mstr isKindOfClass:[NSString class]]);
    
    [_outputStringStack addObject:mstr];
}


- (NSString *)pop {
    NSAssert([_outputStringStack count], @"");
    NSString *pop = [[[_outputStringStack lastObject] retain] autorelease];
    [_outputStringStack removeLastObject];
    return pop;
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

    // recurse
    for (PKBaseNode *child in node.children) {
        [child visit:self];

        // pop
        [childStr appendString:[self pop]];
    }

    // merge
    vars[METHOD_BODY] = childStr;
    NSString *template = [self templateStringNamed:@"PKSMethodTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];

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
    NSString *templateName = self.isSpeculating ? @"PKSMethodSpeculateTemplate" : @"PKSMethodCallTemplate";
    NSString *template = [self templateStringNamed:templateName];
//    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
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


- (void)visitRepetition:(PKCompositeNode *)node {
    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[DEPTH] = @(_depth);
    
    NSAssert(1 == [node.children count], @"");
    PKBaseNode *child = node.children[0];
    
    NSSet *set = [self lookaheadSetForNode:child];

    // setup template
    vars[LOOKAHEAD_SET] = set;
    NSMutableString *output = [NSMutableString string];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSRepetitionStartTemplate"] withVariables:vars]];
    
    // recurse
    self.depth++;
    [child visit:self];
    self.depth--;
    
    // pop
    NSString *childStr = [self pop];
    [output appendString:childStr];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSRepetitionEndTemplate"] withVariables:vars]];
    
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
    
    // push
    [self push:childStr];
    
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
    BOOL needsBacktrack = [overlap count];
    
    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];
    self.isSpeculating = needsBacktrack;
    
    // recurse
    NSUInteger idx = 0;
    for (PKBaseNode *child in node.children) {
        id predictVars = [NSMutableDictionary dictionary];

        NSSet *set = lookaheadSets[idx];
        predictVars[LOOKAHEAD_SET] = set;
        predictVars[DEPTH] = @(_depth);
        predictVars[NEEDS_BACKTRACK] = @(needsBacktrack);

        NSString *templateName = nil;
        
        switch (idx) {
            case 0:
                templateName = @"PKSPredictIfTemplate";
                break;
            default:
                templateName = @"PKSPredictElseIfTemplate";
                break;
        }

        NSString *output = [_engine processTemplate:[self templateStringNamed:templateName] withVariables:predictVars];
        [childStr appendString:output];

        self.depth++;
        [child visit:self];
        self.depth--;
        
        // pop
        [childStr appendString:[self pop]];
        ++idx;
    }
    self.isSpeculating = NO;

    id predictVars = [NSMutableDictionary dictionary];
    predictVars[METHOD_NAME] = _currentDefName;
    predictVars[DEPTH] = @(_depth);
    NSString *output = [_engine processTemplate:[self templateStringNamed:@"PKSPredictElseTemplate"] withVariables:predictVars];
    [childStr appendString:output];

    // push
    [self push:childStr];
}


- (void)visitCardinal:(PKCardinalNode *)node {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
 
    NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
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
    NSMutableString *output = [NSMutableString string];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSOptionalStartTemplate"] withVariables:vars]];
    
    self.depth++;
    [child visit:self];
    self.depth--;
    
    // pop
    NSString *childStr = [self pop];
    [output appendString:childStr];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSOptionalEndTemplate"] withVariables:vars]];
    
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
    NSMutableString *output = [NSMutableString string];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSMultipleStartTemplate"] withVariables:vars]];
    
    self.depth++;
    [child visit:self];
    self.depth--;
    
    // pop
    NSString *childStr = [self pop];
    [output appendString:childStr];
    [output appendString:[_engine processTemplate:[self templateStringNamed:@"PKSMultipleEndTemplate"] withVariables:vars]];
    
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
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
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
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
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
