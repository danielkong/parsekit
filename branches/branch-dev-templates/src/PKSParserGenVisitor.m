//
//  PKSParserGenVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKSParserGenVisitor.h"
#import <ParseKit/ParseKit.h>
#import "NSString+ParseKitAdditions.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

#define CLASS_NAME @"className"
#define TOKEN_USER_TYPES @"tokenUserTypes"
#define METHODS @"methods"
#define METHOD_NAME @"methodName"
#define METHOD_BODY @"methodBody"
#define TOKEN_USER_TYPE @"tokenUserType"
#define CHILD_NAME @"childName"
#define DEPTH @"depth"
#define LOOKAHEAD_SET @"lookaheadSet"

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
    NSMutableSet *set = [NSMutableSet set];
    
    for (PKBaseNode *child in node.children) {
        switch (child.type) {
            case PKNodeTypeConstant: {
                [set addObject:_tokenUserTypes[child.token.tokenType]];
            } break;
            case PKNodeTypeLiteral: {
                PKLiteralNode *litNode = (PKLiteralNode *)child;
                [set addObject:litNode.tokenUserType];
            } break;
            default: {
                NSAssert(0, @"");
            } break;
        }
        
    }
    
    return set;
}





#pragma mark -
#pragma mark PKVisitor

- (void)visitRoot:(PKRootNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    NSParameterAssert(node);
    
    NSArray *tokenUserTypes = @[
      @"TOKEN_TYPE_BUILTIN_INVALID",
      @"TOKEN_TYPE_BUILTIN_NUMBER",
      @"TOKEN_TYPE_BUILTIN_QUOTED_STRING",
      @"TOKEN_TYPE_BUILTIN_SYMBOL",
      @"TOKEN_TYPE_BUILTIN_WORD",
      @"TOKEN_TYPE_BUILTIN_WHITESPACE",
      @"TOKEN_TYPE_BUILTIN_COMMENT",
      @"TOKEN_TYPE_BUILTIN_DELIMITED_STRING",
      @"TOKEN_TYPE_BUILTIN_ANY",
      @"TOKEN_TYPE_BUILTIN_URL",
      @"TOKEN_TYPE_BUILTIN_EMAIL",
      @"TOKEN_TYPE_BUILTIN_TWITTER",
      @"TOKEN_TYPE_BUILTIN_HASHTAG",
    ];
    
    self.tokenUserTypes = [tokenUserTypes arrayByAddingObjectsFromArray:node.tokenUserTypes];
    
    // setup stack
    self.outputStringStack = [NSMutableArray array];

    // setup vars
    id vars = [NSMutableDictionary dictionary];
    vars[CLASS_NAME] = @"MyParser";
    vars[TOKEN_USER_TYPES] = tokenUserTypes;
    
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
    
    self.depth = 0;

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
        self.depth = 1;
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

    // merge
    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
    // push
    [self push:output];
}


- (void)visitComposite:(PKCompositeNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitCollection:(PKCollectionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitAlternation:(PKAlternationNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    self.depth++;

    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];
    
    // recurse
    NSUInteger idx = 0;
    for (PKBaseNode *child in node.children) {
        id predictVars = [NSMutableDictionary dictionary];
//        predictVars[CHILD_NAME] = child.token.stringValue;
//        predictVars[DEPTH] = @(_depth);

        NSSet *set = [self lookaheadSetForNode:node];
        predictVars[LOOKAHEAD_SET] = set;
        
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

        [child visit:self];
        
        // pop
        [childStr appendString:[self pop]];
        ++idx;
    }
    
    id predictVars = [NSMutableDictionary dictionary];
    predictVars[METHOD_NAME] = node.token.stringValue;
    predictVars[DEPTH] = @(_depth);
    NSString *output = [_engine processTemplate:[self templateStringNamed:@"PKSPredictElseTemplate"] withVariables:predictVars];
    [childStr appendString:output];

    self.depth--;

    // push
    [self push:childStr];
}


- (void)visitCardinal:(PKCardinalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitOptional:(PKOptionalNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitMultiple:(PKMultipleNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitConstant:(PKConstantNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
   
    // stup vars
    id vars = [NSMutableDictionary dictionary];
    NSString *methodName = node.token.stringValue;
    vars[METHOD_NAME] = methodName;
    
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
    
    // merge
    NSString *template = [self templateStringNamed:@"PKSMatchCallTemplate"];
    NSString *output = [_engine processTemplate:template withVariables:vars];
    
    // push
    [self push:output];
}


- (void)visitDelimited:(PKDelimitedNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitPattern:(PKPatternNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
