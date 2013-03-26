//
//  PKStaticParserGenVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBaseVisitor.h"

@class MGTemplateEngine;

@interface PKStaticParserGenVisitor : PKBaseVisitor

@property (nonatomic, retain) NSMutableString *interfaceString;
@property (nonatomic, retain) NSMutableString *implString;

@property (nonatomic, retain) MGTemplateEngine *engine;
@end
