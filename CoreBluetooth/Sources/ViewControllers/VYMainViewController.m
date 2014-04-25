//
//  VYMainViewController.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/11/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYMainViewController.h"

#ifdef CENTRAL
#import "VYConstants.h"
#import "VYCentralManager.h"
#import "VYPeripheral.h"
#elif PERIPHERAL
#import "VYPeripheralController.h"
#endif

@interface VYMainViewController ()

#ifdef CENTRAL
@property (nonatomic) VYCentralManager *centralController;
#elif PERIPHERAL
@property (nonatomic) VYPeripheralController *peripheralController;
#endif

@end

@implementation VYMainViewController

#pragma mark -
#pragma mark <NSCoding>

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil)
    {
#ifdef CENTRAL
        _centralController = [VYCentralManager new];
#elif PERIPHERAL
        _peripheralController = [VYPeripheralController new];
#endif
    }
    
    return self;
}

#pragma mark -
#pragma mark Actions

- (IBAction)action:(id)sender
{
#ifdef CENTRAL
    __block VYPeripheral *connectedPeripheral = nil;
    
    [self.centralController.peripherals enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        if ([obj isConnected])
        {
            connectedPeripheral = obj;
            *stop = YES;
        }
    }];
    
    if (connectedPeripheral != nil)
    {
        // Show alert.
        NSString *title = @"Please Wait…";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        
        NSData *data = [kVYSampleText dataUsingEncoding:NSUTF8StringEncoding];
        
        [connectedPeripheral sendRequestData:data completion:^(NSData *responseData, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void)
            {
                NSString *string = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"Info: Data: %@ (%@); Error: %@", responseData, string, error);
                
                // Hide alert.
                [alertView dismissWithClickedButtonIndex:0 animated:YES];
                
                // Show alert.
                NSString *title = error != nil ? [error localizedDescription] : string;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            });
        }];
    }
    else
    {
        // Show alert.
        NSString *title = @"No Peripheral Connected";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
#endif
}

@end
