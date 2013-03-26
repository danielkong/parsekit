//
//  PKSMethod.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/13.
//
//

#import <Foundation/Foundation.h>

@interface PKSMethod : NSObject

- (void)addChild:(PKSMethod *)m;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *children;
@end
