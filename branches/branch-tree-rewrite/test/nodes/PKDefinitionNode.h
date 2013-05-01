//
//  PKNodeDefinition.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKBaseNode.h"

@class PKTreeNode;

@interface PKDefinitionNode : PKBaseNode

@property (nonatomic, retain) NSString *callbackName;
@property (nonatomic, retain) PKTreeNode *rewriteNode;
@end
