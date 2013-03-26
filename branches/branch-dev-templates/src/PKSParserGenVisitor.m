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

@implementation PKSParserGenVisitor

- (id)init {
    self = [super init];
    if (self) {
        [self setUpTemplateEngine];
    }
    return self;
}


- (void)dealloc {
//    self.interfaceString = nil;
//    self.implString = nil;
    self.engine = nil;
    self.outputString = nil;
    self.variables = nil;
    self.methods = nil;
    self.allMethodsString = nil;
    self.currentMethodString = nil;
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
    NSString *template = [self templateStringNamed:@"PKSClassTemplate"];
    self.outputString = template;
    
    self.engine = [MGTemplateEngine templateEngine];
    _engine.delegate = self;
    _engine.matcher = [ICUTemplateMatcher matcherWithTemplateEngine:_engine];
    
}


#pragma mark -
#pragma mark PKVisitor

- (void)visitRoot:(PKRootNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    NSParameterAssert(node);
    
    self.methods = [NSMutableArray array];
    self.variables = [NSMutableDictionary dictionary];
    self.allMethodsString = [NSMutableString string];
    
    id vars = [NSMutableDictionary dictionary];
    vars[@"className"] = @"MyParser";
    
    [self recurse:node];

    vars[@"methods"] = _allMethodsString;
    
    NSString *str = [_engine processTemplate:_outputString withVariables:vars];
    NSAssert([str length], @"");

    NSLog(@"%@", str);

    self.outputString = str;
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSString *methodName = node.token.stringValue;
    if ([methodName isEqualToString:@"@start"]) {
        methodName = @"_start";
    }
    
    NSString *template = [self templateStringNamed:@"PKSMethodTemplate"];
    id vars = [NSMutableDictionary dictionary];
    vars[@"methodName"] = methodName;
    
    self.currentMethodString = [NSMutableString string];

    [self recurse:node];
    
    vars[@"method"] = _currentMethodString;

    NSString *output = [_engine processTemplate:template withVariables:vars];
    [_allMethodsString appendString:output];
}


- (void)visitReference:(PKReferenceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSString *methodName = node.token.stringValue;

    NSString *template = [self templateStringNamed:@"PKSMethodCallTemplate"];
    id vars = [NSMutableDictionary dictionary];
    vars[@"methodName"] = methodName;
        
    NSString *output = [_engine processTemplate:template withVariables:vars];
    [_currentMethodString appendString:output];
}


- (void)visitComposite:(PKCompositeNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitCollection:(PKCollectionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitAlternation:(PKAlternationNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
    
}


- (void)visitLiteral:(PKLiteralNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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
