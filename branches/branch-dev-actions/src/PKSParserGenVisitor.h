//
//  PKSParserGenVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBaseVisitor.h"
#import "MGTemplateEngine.h"

@interface PKSParserGenVisitor : PKBaseVisitor <MGTemplateEngineDelegate>

@property (nonatomic, retain) MGTemplateEngine *engine;
@property (nonatomic, retain) NSString *interfaceOutputString;
@property (nonatomic, retain) NSString *implementationOutputString;
@property (nonatomic, assign) NSUInteger depth;
@property (nonatomic, assign) BOOL needsBacktracking;
@property (nonatomic, assign) BOOL isSpeculating;
@end
