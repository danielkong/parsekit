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

//@property (nonatomic, retain) NSMutableString *interfaceString;
//@property (nonatomic, retain) NSMutableString *implString;

@property (nonatomic, retain) MGTemplateEngine *engine;
@property (nonatomic, retain) NSString *outputString;
@property (nonatomic, retain) NSMutableDictionary *variables;
@property (nonatomic, retain) NSMutableArray *methods;


@property (nonatomic, retain) NSMutableString *methodsString;
@property (nonatomic, retain) NSMutableString *methodString;
@end
