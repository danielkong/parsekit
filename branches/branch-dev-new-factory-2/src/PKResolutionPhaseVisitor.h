//
//  PKReferencePhaseVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKNodeVisitor.h"

@class PKSymbolTable;

@interface PKResolutionPhaseVisitor : NSObject <PKNodeVisitor>

@property (nonatomic, retain) PKBaseNode *rootNode;
@property (nonatomic, retain) PKSymbolTable *symbolTable;
@property (nonatomic, retain) NSDictionary *parserClassForTokenTable;
@end
