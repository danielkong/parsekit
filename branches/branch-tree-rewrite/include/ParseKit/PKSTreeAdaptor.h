//
//  PKSTreeAdaptor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import <Foundation/Foundation.h>

@class PKAST;
@class PKToken;

@interface PKSTreeAdaptor : NSObject

+ (PKSTreeAdaptor *)treeAdaptor;
+ (PKSTreeAdaptor *)treeAdaptorWithTreeClass:(Class)cls;

- (id)initWithTreeClass:(Class)cls;

- (PKAST *)newTreeWithToken:(PKToken *)tok; // returns +1
@end
