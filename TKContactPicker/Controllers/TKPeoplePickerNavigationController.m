//
//  TKPeoplePickerController.m
//  Qnote
//
//  Created by Jongtae Ahn on 12. 9. 3..
//  Copyright (c) 2012년 Tabko Inc. All rights reserved.

//  Altered by Marco       on 15. 11.2..
//  Copyright (c) 2015 ET Inc. All rights reserved.

#import "TKPeoplePickerNavigationController.h"
#define IOS_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface TKPeoplePickerNavigationController ()

@property (nonatomic, retain) TKContactsPickerController *contactController;


@end

@implementation TKPeoplePickerNavigationController
@synthesize addressBook = _addressBook;
@synthesize peoplePickerDelegate = _peoplePickerDelegate;
@synthesize contactController = _contactController;

#pragma mark -
#pragma mark External contacts changed callback

//void addressBookListenerCallback(ABAddressBookRef abRef, CFDictionaryRef dicRef, void *context);
//void addressBookListenerCallback(ABAddressBookRef abRef, CFDictionaryRef dicRef, void *context)
//{
//    NSLog(@"!!!!! Address Book Changed !!!!!");
//    [ABContactsHelper setAddressBook:abRef];
//    [[(TKPeoplePickerController*)context groupController] reloadData];
//    [[(TKPeoplePickerController*)context contactController] reloadData];
//}

//- (void)presentNoContactViewController
//{
//    TKNoContactViewController *noContactController = [[TKNoContactViewController alloc] initWithNibName:NSStringFromClass([TKNoContactViewController class]) bundle:nil];
//    noContactController.delegate = self;
//    [self pushViewController:noContactController animated:NO];
//    [noContactController release];
//}

//- (void)presentContactsPickerController
//{
//    //_addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
//    
//    TKContactsPickerController *contactController = [[TKContactsPickerController alloc] initWithGroup:nil];
//    contactController.delegate = self;
//    [self pushViewController:contactController animated:NO];
//    self.contactController = contactController;
//}

- (id)init
{
    TKContactsPickerController *contactController = [[TKContactsPickerController alloc] initWithGroups:nil];
    contactController.delegate = self;
    self.contactController = contactController;

    self = [super initWithRootViewController:self.contactController];
    if (self) {
        _addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
        _pickerStyle = TKPeoplePickerNavigationControllerStyleNormal;
    }
    
    return self;
}

- (void)dealloc
{
    if (_addressBook) CFRelease(_addressBook);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    ABAddressBookRegisterExternalChangeCallback([ABContactsHelper addressBook], addressBookListenerCallback, self);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    ABAddressBookUnregisterExternalChangeCallback([ABContactsHelper addressBook], addressBookListenerCallback, self);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)groupAction:(NSArray*)data
{
//    if ([self.actionDelegate respondsToSelector:@selector(tkPeoplePickerController:didFinishPickingDataWithInfo:)])
//        NSLog(@"not implement");
//        [self.actionDelegate tkPeoplePickerController:self didFinishPickingDataWithInfo:data];
}

- (void)dismissAction
{
//    if ([self.actionDelegate respondsToSelector:@selector(tkPeoplePickerControllerDidCancel:)])
//        [self.actionDelegate tkPeoplePickerControllerDidCancel:self];
}



#pragma mark -
#pragma mark TKGroupPickerControllerDelegate

- (void)tkGroupPickerControllerDidCancel:(TKGroupPickerController *)picker
{
    [self dismissAction];
}

#pragma mark -
#pragma mark TKContactsPickerControllerDelegate

- (void)tkContactsPickerController:(TKContactsPickerController *)peoplePicker
                   didSelectContact:(TKContact*)person
                          property:(ABPropertyID)property
                        identifier:(ABMultiValueIdentifier)identifier
{
    if ([self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationController:didSelectContact:property:identifier:)]) {
        [self.peoplePickerDelegate tkPeoplePickerNavigationController:self didSelectContact:person property:property identifier:identifier];
    }
}

- (void)tkContactsPickerController:(TKContactsPickerController *)peoplePicker
                  didSelectContact:(TKContact*)contact

{
    if ([self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationController:didSelectContact:)]) {
        [self.peoplePickerDelegate tkPeoplePickerNavigationController:self didSelectContact:contact];
    }
}

- (void)tkContactsPickerController:(TKContactsPickerController *)peoplePicker
                 didSelectContacts:(NSArray*)contacts
{
    if ([self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationController:didSelectContacts:)]) {
        [self.peoplePickerDelegate tkPeoplePickerNavigationController:self didSelectContacts:contacts];
    }
}

- (void)tkContactsPickerControllerDidCancel:(TKContactsPickerController *)picker
{
    if ([self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationControllerDidCancel:)]) {
        [self.peoplePickerDelegate tkPeoplePickerNavigationControllerDidCancel:self];
    }

}

- (BOOL)tkContactsPickerControllerAllowMultiSelection:(TKContactsPickerController *)picker
{
    if ([self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationController:didSelectContacts:)]) {
        return YES;
    }else
        return NO;
}

- (BOOL)tkContactsPickerController:(TKContactsPickerController *)picker shouldContinueAfterSelectingContact:(TKContact *)contact
{
    if ([self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationController:didSelectContact:)]||
        [self.peoplePickerDelegate respondsToSelector:@selector(tkPeoplePickerNavigationController:didSelectContacts:)]) {
        return NO;
    }else
        return YES;
}

@end
