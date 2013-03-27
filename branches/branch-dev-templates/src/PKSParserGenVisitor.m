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
#import "NSString+ParseKitAdditions.h"

#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

#define CLASS_NAME @"className"
#define TOKEN_USER_TYPES_START_INDEX @"startIndex"
#define TOKEN_USER_TYPES @"tokenUserTypes"
#define METHODS @"methods"
#define METHOD_NAME @"methodName"
#define METHOD_BODY @"methodBody"
#define TOKEN_USER_TYPE @"tokenUserType"
#define CHILD_NAME @"childName"
#define DEPTH @"depth"
#define LOOKAHEAD_SET @"lookaheadSet"
#define OPT_BODY @"optBody"

@interface PKSParserGenVisitor ()
- (void)push:(NSString *)mstr;
- (NSString *)pop;
- (NSSet *)lookaheadSetForNode:(PKBaseNode *)node;

@property (nonatomic, retain) NSMutableArray *outputStringStack;
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
    self.outputString = nil;
    self.outputStringStack = nil;
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
            //[set addObject:_tokenUserTypes[node.token.tokenType]];
            [set addObject:[NSString stringWithFormat:@"TOKEN_TYPE_BUILTIN_%@", [node.token.stringValue uppercaseString]]];
        } break;
        case PKNodeTypeLiteral: {
            PKLiteralNode *litNode = (PKLiteralNode *)node;
            [set addObject:litNode.tokenUserType];
        } break;
        case PKNodeTypeReference: {
            NSString *name = node.token.stringValue;
            PKDefinitionNode *defNode = self.symbolTable[name];
            [set unionSet:[self lookaheadSetForNode:defNode]];
        } break;
        case PKNodeTypeAlternation: {
            for (PKBaseNode *child in node.children) {
                [set unionSet:[self lookaheadSetForNode:child]];
                break; // single look ahead
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


#pragma mark -
#pragma mark PKVisitor

- (void)visitRoot:(PKRootNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    NSParameterAssert(node);
        
    // setup stack
    self.outputStringStack = [NSMutableArray array];

    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[CLASS_NAME] = @"MyParser";
    vars[TOKEN_USER_TYPES_START_INDEX] = @(TOKEN_TYPE_BUILTIN_ANY + 1);
    vars[TOKEN_USER_TYPES] = node.tokenUserTypes;
    
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
    NSString *template = [self templateStringNamed:@"PKSClassTemplate"];
    NSString *outStr = [_engine processTemplate:template withVariables:vars];

    // cleanup
    self.outputString = outStr;

    NSLog(@"%@", outStr);
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    self.depth = 1;

    // setup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    if ([methodName isEqualToString:@"@start"]) {
        methodName = @"_start";
    }
    vars[METHOD_NAME] = methodName;
    
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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
        
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    vars[METHOD_NAME] = methodName;
    vars[DEPTH] = @(_depth);

    // merge
    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
    // push
    [self push:output];
}


- (void)visitComposite:(PKCompositeNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];
    
    // recurse
    NSUInteger idx = 0;
    for (PKBaseNode *child in node.children) {
        id predictVars = [NSMutableDictionary dictionary];

        NSSet *set = [self lookaheadSetForNode:child];
        predictVars[LOOKAHEAD_SET] = set;
        predictVars[DEPTH] = @(_depth);

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
    
    id predictVars = [NSMutableDictionary dictionary];
    predictVars[METHOD_NAME] = node.token.stringValue;
    predictVars[DEPTH] = @(_depth);
    NSString *output = [_engine processTemplate:[self templateStringNamed:@"PKSPredictElseTemplate"] withVariables:predictVars];
    [childStr appendString:output];

    // push
    [self push:childStr];
}


- (void)visitCardinal:(PKCardinalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
 
    NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)visitOptional:(PKOptionalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);

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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
   
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    vars[METHOD_NAME] = methodName;
    vars[DEPTH] = @(_depth);

    // merge
    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
    // push
    [self push:output];
}


- (void)visitLiteral:(PKLiteralNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *t = node.tokenUserType;
    vars[TOKEN_USER_TYPE] = t;
    vars[DEPTH] = @(_depth);

    // merge
    NSString *template = [self templateStringNamed:@"PKSMatchCallTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
    // push
    [self push:output];
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSAssert2(0, @"%s must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
}


- (void)visitPattern:(PKPatternNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
