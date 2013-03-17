//
//  PKDefinitionPhaseVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import <ParseKit/ParseKit.h>
#import "PKNodeVisitor.h"

@interface PKDefinitionPhaseVisitor : NSObject <PKNodeVisitor>

@property (nonatomic, retain) PKBaseNode *rootNode;

@property (nonatomic, retain) NSDictionary *parserClassForTokenTable;
@end
