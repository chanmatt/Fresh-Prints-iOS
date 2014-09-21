//
//  ViewController.m
//  Fresh Prints
//
//  Created by Matthew Chan on 9/20/14.
//  Copyright (c) 2014 Ignio Innovation. All rights reserved.
//

#import "ViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>
#import "QSTodoService.h"

@interface ViewController ()

// Private properties
@property (strong, nonatomic) QSTodoService *todoService;
@property (strong, nonatomic) NSTimer *checkingTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create the todoService - this creates the Mobile Service client inside the wrapped service
    self.todoService = [QSTodoService defaultService];
    [self.todoService refreshDataOnSuccess:^
    {
        self.checkingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCloud) userInfo:nil repeats:NO];
    }];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)resetAppearance
{
    UIImage * toImage = [UIImage imageNamed:@"freshprintsbg.png"];
    [UIView transitionWithView:self.theBG
                      duration:1.0f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.theBG.image = toImage;
                    } completion:nil];
}

- (void)doAuthentication
{
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    NSString *myLocalizedReasonString = @"Authenticate using your finger";
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:myLocalizedReasonString
                            reply:^(BOOL succesz, NSError *error) {
                                
                                if (succesz) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UIImage * toImage = [UIImage imageNamed:@"freshprintssuccess.png"];
                                        [UIView transitionWithView:self.theBG
                                                          duration:1.0f
                                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                                        animations:^{
                                                            self.theBG.image = toImage;
                                                        } completion:nil];
                                        [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                         target:self
                                                                       selector:@selector(resetAppearance)
                                                                       userInfo:nil
                                                                        repeats:NO];
                                        NSDictionary *item = [self.todoService.items objectAtIndex:0];
                                        [self.todoService completeItemGood:item completion:^(NSUInteger index)
                                         {
                                             self.checkingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCloud) userInfo:nil repeats:NO];
                                         }];
                                    });
                                    NSLog(@"User is authenticated successfully");
                                } else {
                                    
                                    switch (error.code) {
                                        case LAErrorAuthenticationFailed:
                                            NSLog(@"Authentication Failed");
                                            break;
                                            
                                        case LAErrorUserCancel:
                                            NSLog(@"User pressed Cancel button");
                                            break;
                                            
                                        case LAErrorUserFallback:
                                            NSLog(@"User pressed \"Enter Password\"");
                                            break;
                                            
                                        default:
                                            NSLog(@"Touch ID is not configured");
                                            break;
                                    }
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UIImage * toImage = [UIImage imageNamed:@"freshprintsfail.png"];
                                        [UIView transitionWithView:self.theBG
                                                          duration:1.0f
                                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                                        animations:^{
                                                            self.theBG.image = toImage;
                                                        } completion:nil];
                                        [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                         target:self
                                                                       selector:@selector(resetAppearance)
                                                                       userInfo:nil
                                                                        repeats:NO];
                                        NSDictionary *item = [self.todoService.items objectAtIndex:0];
                                        [self.todoService completeItemBad:item completion:^(NSUInteger index)
                                         {
                                             self.checkingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCloud) userInfo:nil repeats:NO];
                                         }];
                                    });
                                    NSLog(@"Authentication Fails");
                                }
                            }];
    } else {
        NSLog(@"Can not evaluate Touch ID");
        //[self changeItem];
        
    }
}

- (void)checkCloud {
    NSDictionary *item = [self.todoService.items objectAtIndex:0];
    NSString *theText = [item objectForKey:@"text"];
    NSLog(@"Cloud has been checked, word is: %@",theText);
    if ([theText isEqualToString:@"verifytime"]) {
        [self doAuthentication];
    } else {
        self.checkingTimer = nil;
        [self.todoService refreshDataOnSuccess:^
         {
             self.checkingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCloud) userInfo:nil repeats:NO];
         }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
