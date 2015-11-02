//
//  TKContact.h
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import "TKContact.h"

@implementation TKContact
@synthesize name, email, tels, thumbnail, recordID, sectionNumber, rowSelected, lastName, firstName;

//- (void)dealloc
//{
//    [name release];
//    [email release];
//    [tels release];
//    [thumbnail release];
//    [lastName release];
//    [firstName release];
//    
//    [super dealloc];
//}

- (NSString*)sorterFirstName {
    if (nil != firstName && ![firstName isEqualToString:@""]) {
        return firstName;
    }
    if (nil != lastName && ![lastName isEqualToString:@""]) {
        return lastName;
    }
    if (nil != name && ![name isEqualToString:@""]) {
        return name;
    }
    return @"_$!<No Name>$!_";
}

- (NSString*)sorterLastName {
    if (nil != lastName && ![lastName isEqualToString:@""]) {
        return lastName;
    }
    if (nil != firstName && ![firstName isEqualToString:@""]) {
        return firstName;
    }
    if (nil != name && ![name isEqualToString:@""]) {
        return name;
    }
    return @"_$!<No Name>$!_";
}

@end
