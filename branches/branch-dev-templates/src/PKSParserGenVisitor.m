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
#define METHODS @"methods"
#define METHOD_NAME @"methodName"
#define METHOD_BODY @"methodBody"
#define TOKEN_USER_TYPE @"tokenUserType"
#define CHILD_NAME @"childName"

@interface PKSParserGenVisitor ()
- (void)push:(NSString *)mstr;
- (NSString *)pop;

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
    
//    NSMutableString *peek = [_outputStringStack lastObject];
//    NSAssert([peek isKindOfClass:[NSMutableString class]], @"");
//    
//    [peek appendString:pop];
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
    
    // setup child str buffer
    NSMutableString *childStr = [NSMutableString string];
    
    // recurse
    NSUInteger idx = 0;
    for (PKBaseNode *child in node.children) {
        id predictVars = [NSMutableDictionary dictionary];
        predictVars[CHILD_NAME] = child.token.stringValue;
        
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
    NSString *output = [_engine processTemplate:[self templateStringNamed:@"PKSPredictElseTemplate"] withVariables:predictVars];
    [childStr appendString:output];

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
    //NSNumber *t = @(node.token.userType);
    NSString *t = [node.token.stringValue stringByTrimmingQuotes];
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
