//
//  TKContactProperty.h
//  TKContactPicker
//
//  Created by marco on 11/3/15.
//  Copyright © 2015 TABKO Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKContact.h"

@interface TKContactProperty : NSObject


@property(readonly, copy, nonatomic) TKContact *contact;
@property(readonly, copy, nonatomic) NSString *key;
@property(readonly, nonatomic) id value;
@property(readonly, copy, nonatomic) NSString *label;
@property(readonly, copy, nonatomic) NSString *identifier;

@end
