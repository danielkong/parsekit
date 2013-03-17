//
//  PKBaseVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKNodeVisitor.h"

@protocol PKScope;
@class PKSymbolTable;
@class PKBaseNode;

@interface PKBaseVisitor : NSObject <PKNodeVisitor>

- (void)recurse:(PKBaseNode *)node;

@property (nonatomic, retain) PKBaseNode *rootNode;
@property (nonatomic, retain) PKSymbolTable *symbolTable;
@property (nonatomic, retain) id <PKScope>currentScope;
@end
