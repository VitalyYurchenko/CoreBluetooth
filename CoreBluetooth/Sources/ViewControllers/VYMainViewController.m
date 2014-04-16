//
//  VYMainViewController.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/11/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYMainViewController.h"

#ifdef CENTRAL
#import "VYCentralController.h"
#elif PERIPHERAL
#import "VYPeripheralController.h"
#endif

@interface VYMainViewController ()

#ifdef CENTRAL
@property (nonatomic) VYCentralController *centralController;
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
        _centralController = [VYCentralController new];
#elif PERIPHERAL
        _peripheralController = [VYPeripheralController new];
#endif
    }
    
    return self;
}

@end
