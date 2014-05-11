//
//  BMESignUpMethodViewController.m
//  BeMyEyes
//
//  Created by Simon Støvring on 22/02/14.
//  Copyright (c) 2014 Be My Eyes. All rights reserved.
//

#import "BMESignUpMethodViewController.h"
#import <MRProgress/MRProgress.h>
#import <Accounts/Accounts.h>
#import "BMEAppDelegate.h"
#import "BMESignUpViewController.h"
#import "BMEClient.h"
#import "BMEUser.h"
#import "BMEFacebookInfo.h"

#define BMESignUpLoggedInSegue @"LoggedIn"
#define BMESignUpMethodSignUpSegue @"SignUp"
#define BMERegisteredSegue @"Registered"

@interface BMESignUpMethodViewController ()
@property (weak, nonatomic) IBOutlet UILabel *signUpTopLabel;
@property (weak, nonatomic) IBOutlet UILabel *signUpBottomLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsTopLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsBottomLabel;
@end

@implementation BMESignUpMethodViewController

#pragma mark -
#pragma mark Private Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Before checking if the user has enabled notifications,
    // we must be sure that we have given them the chance to do so
    if (self.role == BMERoleHelper) {
        [TheAppDelegate registerForRemoteNotifications];
    }
}

- (IBAction)facebookButtonPressed:(id)sender {
    if (self.role == BMERoleHelper) {
        [TheAppDelegate requirePushNotificationsEnabled:^(BOOL isEnabled) {
            if (isEnabled) {
                [self performFacebookRegistration];
            }
        }];
    } else {
        [self performFacebookRegistration];
    }
}

- (IBAction)signUpButtonPressed:(id)sender {
    [TheAppDelegate requirePushNotificationsEnabled:^(BOOL isEnabled) {
        if (isEnabled) {
            [self performSegueWithIdentifier:BMESignUpMethodSignUpSegue sender:self];
        }
    }];
}

- (IBAction)signUpButtonTouched:(id)sender {
    self.signUpTopLabel.alpha = 0.50f;
    self.signUpBottomLabel.alpha = 0.50f;
}

- (IBAction)signUpButtonReleased:(id)sender {
    self.signUpTopLabel.alpha = 1.0f;
    self.signUpBottomLabel.alpha = 1.0f;
}

- (IBAction)termsButtonTouched:(id)sender {
    self.termsTopLabel.alpha = 0.50f;
    self.termsBottomLabel.alpha = 0.50f;
}

- (IBAction)termsButtonReleased:(id)sender {
    self.termsTopLabel.alpha = 1.0f;
    self.termsBottomLabel.alpha = 1.0f;
}

- (void)performFacebookRegistration {
    MRProgressOverlayView *progressOverlayView = [MRProgressOverlayView showOverlayAddedTo:self.view.window animated:YES];
    progressOverlayView.mode = MRProgressOverlayViewModeIndeterminate;
    progressOverlayView.titleLabelText = NSLocalizedStringFromTable(@"OVERLAY_REGISTERING_TITLE", @"BMESignUpMethodViewController", @"Title in overlay displayed when registering");
    
    [[BMEClient sharedClient] authenticateWithFacebook:^(BMEFacebookInfo *fbInfo, NSError *error) {
        if (!error) {
            [[BMEClient sharedClient] createFacebookUserId:[fbInfo.userId integerValue] email:fbInfo.email firstName:fbInfo.firstName lastName:fbInfo.lastName role:self.role completion:^(BOOL success, NSError *error) {
                if (success && !error) {
                    progressOverlayView.titleLabelText = NSLocalizedStringFromTable(@"OVERLAY_LOGGING_IN_TITLE", @"BMESignUpMethodViewController", @"Title in overlay displayed when logging in");
                    
                    [[BMEClient sharedClient] loginWithEmail:fbInfo.email userId:[fbInfo.userId integerValue] success:^(BMEToken *token) {
                        [progressOverlayView hide:YES];
                        
                        [self didLogin];
                    } failure:^(NSError *error) {
                        [progressOverlayView hide:YES];
                        
                        [self performSegueWithIdentifier:BMERegisteredSegue sender:self];
                    }];
                } else {
                    [progressOverlayView hide:YES];
                    
                    if ([error code] == BMEClientErrorUserEmailAlreadyRegistered)  {
                        NSString *title = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_EMAIL_ALREADY_REGISTERED_TITLE", @"BMESignUpMethodViewController", @"Title in alert view shown when e-mail is already registered.");
                        NSString *message = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_EMAIL_ALREADY_REGISTERED_MESSAGE", @"BMESignUpMethodViewController", @"Message in alert view shown when e-mail is already registered.");
                        NSString *cancelButton = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_EMAIL_ALREADY_REGISTERED_CANCEL", @"BMESignUpMethodViewController", @"Title of cancel button in alert view shown when e-mail is already registered.");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
                        [alert show];
                    } else {
                        NSString *title = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_SIGN_UP_UNKNOWN_ERROR_TITLE", @"BMESignUpMethodViewController", @"Title in alert view shown when a TITLEnetwork error occurred during Facebook log in.");
                        NSString *message = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_SIGN_UP_UNKNOWN_ERROR_MESSAGE", @"BMESignUpMethodViewController", @"Message in alert view shown when a network error occurred during Facebook log in.");
                        NSString *cancelButton = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_SIGN_UP_UNKNOWN_ERROR_CANCEL", @"BMESignUpMethodViewController", @"Title of cancel button in alert view shown when a network error occurred during Facebook log in.");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
                        [alert show];
                    }
                }
            }];
        } else {
            [progressOverlayView hide:YES];
            
            if ([error code] == ACErrorAccountNotFound) {
                NSString *title = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_ACCOUNT_NOT_FOUND_TITLE", @"BMESignUpMethodViewController", @"Title in alert view shown when no Facebook account was found.");
                NSString *message = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_ACCOUNT_NOT_FOUND_MESSAGE", @"BMESignUpMethodViewController", @"Message in alert view shown when no Facebook account was found.");
                NSString *cancelButton = NSLocalizedStringFromTable(@"ALERT_FACEBOOK_ACCOUNT_NOT_FOUND_CANCEL", @"BMESignUpMethodViewController", @"Title of cancel button in alert view shown when no Facebook account was found.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
                [alert show];
            } else {
                NSString *title = NSLocalizedStringFromTable(@"ALERT_NOT_LOGGED_IN_TITLE", @"BMESignUpMethodViewController", @"Title in alert view shown when log in to Facebook failed");
                NSString *cancelButtonTitle = NSLocalizedStringFromTable(@"ALERT_NOT_LOGGED_IN_CANCEL", @"BMESignUpMethodViewController", @"Title of cancel button in alert view shown when log in to Facebook failed");
                NSString *message = message = NSLocalizedStringFromTable(@"ALERT_NOT_LOGGED_IN_MESSAGE", @"BMESignUpMethodViewController", @"Message in alert view shown when logging into Facebook but it failed because authentication failed");
            
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil, nil];
                [alert show];
            }
        }
    }];
}

- (void)didLogin {
    if ([BMEClient sharedClient].currentUser.role == BMERoleHelper) {
        [TheAppDelegate registerForRemoteNotifications];
    }
    
    [self performSegueWithIdentifier:BMESignUpLoggedInSegue sender:self];
}

#pragma mark -
#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:BMESignUpMethodSignUpSegue]) {
        ((BMESignUpViewController *)segue.destinationViewController).role = self.role;
    }
}

@end
