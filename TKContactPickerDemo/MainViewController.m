//
//  MainViewController.m
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+TKUtilities.h"

#define thumbnailSize 75

@interface MainViewController ()

@end

@implementation MainViewController
@synthesize scrollView = _scrollView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setTitle:@"Contacts"];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showPeoplePicker:)]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)showPeoplePicker:(id)sender
{
    TKPeoplePickerNavigationController *controller = [[TKPeoplePickerNavigationController alloc] init];
    controller.peoplePickerDelegate = self;
    controller.pickerStyle = TKPeoplePickerNavigationControllerStyleNormal;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - TKContactsPickerControllerDelegate

- (void)tkPeoplePickerController:(TKPeoplePickerNavigationController*)picker didFinishPickingDataWithInfo:(NSArray*)contacts
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    for (id view in self.scrollView.subviews) {
        if ([view isKindOfClass:[UIButton class]])
            [(UIButton*)view removeFromSuperview];
    }
    
    __block CGRect nameButtonRect = CGRectMake(4, 4, thumbnailSize, thumbnailSize);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ABAddressBookRef addressBook = ABAddressBookCreate();
        [contacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            @autoreleasepool {
                TKContact *contact = (TKContact*)obj;
                NSNumber *personID = [NSNumber numberWithLong:contact.recordID];
                ABRecordID abRecordID = (ABRecordID)[personID intValue];
                ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);
                
                // Check person image
                UIImage *personImage = nil;
                if (abPerson != nil && ABPersonHasImageData(abPerson)) {
                    if ( &ABPersonCopyImageDataWithFormat != nil ) {// iOS >= 4.1
                        CFDataRef contactThumbnailData = ABPersonCopyImageDataWithFormat(abPerson, kABPersonImageFormatThumbnail);
                        personImage = [UIImage imageWithData:(__bridge NSData*)contactThumbnailData];
                        CFRelease(contactThumbnailData);
                        CFDataRef contactImageData = ABPersonCopyImageDataWithFormat(abPerson, kABPersonImageFormatOriginalSize);
                        CFRelease(contactImageData);
                        
                    }
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIButton *nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    if (personImage)
                        [nameButton setBackgroundImage:personImage forState:UIControlStateNormal];
                    else
                        [nameButton setBackgroundImage:[UIImage imageNamed:@"blank.png"] forState:UIControlStateNormal];
                    
                    [nameButton setFrame:nameButtonRect];
                    [nameButton setAlpha:0.0f];
                    [nameButton.titleLabel setFont:[UIFont systemFontOfSize:11]];
                    [nameButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    [nameButton setTitle:contact.name forState:UIControlStateNormal];
                    [nameButton setTitleEdgeInsets:UIEdgeInsetsMake(45, 0, 0, 0)];
                    [self.scrollView addSubview:nameButton];
                    
                    [UIView animateWithDuration:0.2 animations:^{
                        nameButton.alpha = 1.0f;
                    } completion:^(BOOL finished) {
                        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, nameButtonRect.origin.y + thumbnailSize + 4)];
                    }];
                    
                    if (idx != 0 && idx%4 == 3) {
                        nameButtonRect.origin.x = 4;
                        nameButtonRect.origin.y += thumbnailSize + 4;
                    }
                    else {
                        nameButtonRect.origin.x += thumbnailSize + 4;
                    }
                });
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CFRelease(addressBook);
        });
    });
}

- (void)tkPeoplePickerNavigationControllerDidCancel:(TKPeoplePickerNavigationController*)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}



- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker didSelectContact:(TKContact *)contact
{
    NSLog(@"select contact");
}
//
-(void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker didSelectContacts:(NSArray *)contacts
{
    NSLog(@"select contacts");
}

- (void)tkPeoplePickerNavigationController:(TKPeoplePickerNavigationController *)peoplePicker didSelectContact:(TKContact *)contact property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    CFTypeRef multiValue;
    CFIndex valueIdx;
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(peoplePicker.addressBook, (int)contact.recordID);

    // FIXME duplicate code from FavoritesListController.personViewController
    if (kABPersonPhoneProperty == property)
    {
        multiValue = ABRecordCopyValue(person, property);
        ABMultiValueRef phoneLabels = ABRecordCopyValue(person, kABPersonPhoneProperty);
        valueIdx = ABMultiValueGetIndexForIdentifier(multiValue,identifier);
        NSString *phoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(multiValue, valueIdx);
        NSString* _firstName = (__bridge_transfer NSString *) ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString* _lastName = (__bridge_transfer NSString *) ABRecordCopyValue(person, kABPersonLastNameProperty);
        NSString* fullName = @"";
        
        if (_firstName == nil) {
            fullName = _lastName;
        }
        else if (_lastName == nil) {
            fullName = _firstName;
        }
        else {
            fullName = [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
        }
        
        CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phoneLabels, valueIdx);
        NSString *_phoneLabel =(__bridge_transfer NSString*) ABAddressBookCopyLocalizedLabel(locLabel);
        fullName = [NSString stringWithFormat:@"%@ %@", fullName, _phoneLabel];
        NSLog(@"name:%@ phone:%@",fullName,phoneNumber);
        
        CFRelease(locLabel);
        CFRelease(phoneLabels);
        CFRelease(multiValue);
    }
    

}

@end
