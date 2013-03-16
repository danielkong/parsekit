//
//  PKNodeTerminal.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"

@interface PKConstantNode : PKBaseNode

@property (nonatomic, copy) NSString *literal;
@end
