//
//  TKNoContactViewController.m
//  Qnote
//
//  Created by Jongtae Ahn on 12. 9. 20..
//  Copyright (c) 2012년 Tabko Inc. All rights reserved.
//

#import "TKNoContactViewController.h"

@interface TKNoContactViewController ()

@end

@implementation TKNoContactViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"All Contacts", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
