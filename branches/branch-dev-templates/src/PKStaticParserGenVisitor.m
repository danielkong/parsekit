//
//  PKStaticParserGenVisitor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKStaticParserGenVisitor.h"
#import <ParseKit/ParseKit.h>
#import "NSString+ParseKitAdditions.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

@implementation PKStaticParserGenVisitor

- (void)dealloc {
//    self.interfaceString = nil;
//    self.implString = nil;
    self.engine = nil;
    self.outputString = nil;
    self.variables = nil;
    [super dealloc];
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


- (void)visitRoot:(PKRootNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
    NSParameterAssert(node);
    //NSAssert(self.symbolTable, @"");
    
    NSError *err = nil;
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"PKSParserTemplate" ofType:@"txt"];
    NSString *template = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    NSAssert([template length], @"");
    if (!template) {
        if (err) NSLog(@"%@", err);
        return;
    }

    self.variables = [[@{@"className": @"MyParser"} mutableCopy] autorelease];
    
    self.engine = [MGTemplateEngine templateEngine];
    _engine.delegate = self;
    _engine.matcher = [ICUTemplateMatcher matcherWithTemplateEngine:_engine];
    
    NSString *str = [_engine processTemplate:template withVariables:_variables];
    NSAssert([str length], @"");
    
    self.outputString = str;
    
    
//    self.interfaceString = [NSMutableString string];
//    self.implString = [NSMutableString string];
}


- (void)visitDefinition:(PKDefinitionNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
}


- (void)visitReference:(PKReferenceNode *)node {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, node);
    
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

@end
