//
//  PKSimplifyNodeVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import <ParseKit/ParseKit.h>
#import "PKNodeVisitor.h"

@interface PKSimplifyNodeVisitor : NSObject <PKNodeVisitor>

@property (nonatomic, retain) PKBaseNode *rootNode;
@property (nonatomic, retain) PKBaseNode *currentParent;
@end
