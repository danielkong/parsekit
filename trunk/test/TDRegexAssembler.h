//
//  TDRegexAssembler.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/1/12.
//
//

#import <Foundation/Foundation.h>

@interface TDRegexAssembler : NSObject {
    NSNumber *curly;
    NSNumber *paren;
}

@property (nonatomic, retain) NSNumber *curly;
@property (nonatomic, retain) NSNumber *paren;
@end
