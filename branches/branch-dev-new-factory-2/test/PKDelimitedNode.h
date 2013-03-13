//
//  PKNodeDelimited.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/5/12.
//
//

#import "PKNodeTypes.h"

@interface PKDelimitedNode : PKBaseNode
@property (nonatomic, retain) NSString *startMarker;
@property (nonatomic, retain) NSString *endMarker;
@end
