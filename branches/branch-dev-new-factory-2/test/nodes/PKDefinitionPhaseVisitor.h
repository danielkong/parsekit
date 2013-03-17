//
//  PKDefinitionPhaseVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeVisitor.h"

@class PKSymbolTable;

@interface PKDefinitionPhaseVisitor : NSObject <PKNodeVisitor>

@property (nonatomic, retain) PKBaseNode *rootNode;
@property (nonatomic, retain) PKSymbolTable *symbolTable;
@property (nonatomic, retain) NSDictionary *parserClassForTokenTable;
@end
