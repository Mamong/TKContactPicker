//
//  TKPeoplePickerController.m
//  Qnote
//
//  Created by Jongtae Ahn on 12. 9. 3..
//  Copyright (c) 2012년 Tabko Inc. All rights reserved.
//

#import "TKPeoplePickerController.h"
#define IOS_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface TKPeoplePickerController ()

//- (void)presentNoContactViewController;
- (void)presentContactsPickerController;

@end

@implementation TKPeoplePickerController
@synthesize addressBook = _addressBook;
@synthesize actionDelegate = _actionDelegate;
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

- (id)initPeoplePicker
{
    TKContactsPickerController *contactController = [[TKContactsPickerController alloc] initWithGroup:nil];
    contactController.delegate = self;
    self.contactController = contactController;

    self = [super initWithRootViewController:self.contactController];
    if (self) {
        _addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    }
    
    return self;
}

- (void)dealloc
{
    if (_addressBook) CFRelease(_addressBook);
//    [_groupController release];
//    [_contactController release];
//    [super dealloc];
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
    if ([self.actionDelegate respondsToSelector:@selector(tkPeoplePickerController:didFinishPickingDataWithInfo:)])
        [self.actionDelegate tkPeoplePickerController:self didFinishPickingDataWithInfo:data];
}

- (void)dismissAction
{
    if ([self.actionDelegate respondsToSelector:@selector(tkPeoplePickerControllerDidCancel:)])
        [self.actionDelegate tkPeoplePickerControllerDidCancel:self];
}



#pragma mark -
#pragma mark TKGroupPickerControllerDelegate

- (void)tkGroupPickerControllerDidCancel:(TKGroupPickerController *)picker
{
    [self dismissAction];
}

#pragma mark -
#pragma mark TKContactsPickerControllerDelegate

- (void)tkContactsPickerController:(TKContactsPickerController *)picker didFinishPickingDataWithInfo:(NSArray *)contacts
{
    //[self saveAction:contacts];
}

- (void)tkContactsPickerControllerDidCancel:(TKContactsPickerController *)picker
{
    [self dismissAction];
}

@end
