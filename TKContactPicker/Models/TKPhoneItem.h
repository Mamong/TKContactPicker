//
//  TKPhoneItem.h
//  TKContactPicker
//
//  Created by marco on 11/9/15.
//  Copyright © 2015 TABKO Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKPhoneItem : NSObject


@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *tel;

@end
