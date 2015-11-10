//
//  TKPeoplePickerController.h
//  Qnote
//
//  Created by Jongtae Ahn on 12. 9. 3..
//  Copyright (c) 2012년 Tabko Inc. All rights reserved.

//  Altered by Marco       on 15. 11.2..
//  Copyright (c) 2015 ET Inc. All rights reserved.


#import "TKContactsPickerController.h"

typedef NS_ENUM(NSUInteger, TKPeoplePickerNavigationControllerStyle) {
    TKPeoplePickerNavigationControllerStyleNormal,
    TKPeoplePickerNavigationControllerStyleAllPhones,
};


@class TKPeoplePickerNavigationController,TKContact;

@protocol TKPeoplePickerNavigationControllerDelegate <NSObject>

@optional


- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker
                          didSelectContact:(TKContact*)contact;

- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker
                         didSelectContacts:(NSArray*)contacts;


// Temp API, will replaced by tkPeoplePickerNavigationController:didSelectContactProperty:
- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker
                          didSelectContact:(TKContact *)contact
                                     index:(NSInteger)index
                                  property:(ABPropertyID)property
                                identifier:(ABMultiValueIdentifier)identifier;
//
//- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker
//                         didSelectContactProperty:(TKContactProperty)property

//
//- (BOOL)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker
//                          canPerformAction:(SEL)selector
//                                   contact:(ABRecordRef)contact
//                                  property:(ABPropertyID)property
//                                identifier:(ABMultiValueIdentifier)identifier;
//
//- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker
//                             performAction:(SEL)selector
//                                   contact:(ABRecordRef)contact
//                                  property:(ABPropertyID)property
//                                identifier:(ABMultiValueIdentifier)identifier;

- (void)tkPeoplePickerNavigationControllerDidCancel:(TKPeoplePickerNavigationController*)picker;
@end



@interface TKPeoplePickerNavigationController : UINavigationController <TKContactsPickerControllerDelegate>

@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, assign) id<TKPeoplePickerNavigationControllerDelegate> peoplePickerDelegate;
@property (nonatomic, assign) TKPeoplePickerNavigationControllerStyle pickerStyle;
//@property(nonatomic, copy) NSArray <NSNumber *> *displayedProperties;


- (id)init;

@end
