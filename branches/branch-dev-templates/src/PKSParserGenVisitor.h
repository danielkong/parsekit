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
@property (nonatomic, retain) NSString *outputString;
@property (nonatomic, assign) NSUInteger depth;
@end
