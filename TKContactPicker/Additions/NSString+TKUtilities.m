//
//  NSString+TKUtilities.m
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "NSString+TKUtilities.h"

#define VALID_NUMBER_CHARS @"0123456789,#;%*+" //Only these are valid for a phone number.


@implementation NSString (TKUtilities)

- (BOOL)containsString:(NSString *)aString
{
	NSRange range = [[self lowercaseString] rangeOfString:[aString lowercaseString]];
	return range.location != NSNotFound;
}

- (NSString*)telephoneWithReformat
{
    NSString *s = [[self componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:VALID_NUMBER_CHARS] invertedSet]] componentsJoinedByString:@""];    
    return s;
}

@end
