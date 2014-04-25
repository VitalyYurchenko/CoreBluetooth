//
//  VYService.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/24/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYService.h"

#import "VYCharacteristic.h"

@interface VYService ()

@property (nonatomic, copy) VYServiceDiscoverCharacteristicsBlock discoverCharacteristicsBlock;

@property (nonatomic, getter = isDiscoverCharacteristicsInProgress) BOOL discoverCharacteristicsInProgress;

@end

@implementation VYService

#pragma mark -
#pragma mark Object Lifecycle

+ (instancetype)serviceWithCBService:(CBService *)cbService
{
    return [[self alloc] initWithCBService:cbService];
}

- (instancetype)init
{
    return [self initWithCBService:nil];
}

- (instancetype)initWithCBService:(CBService *)cbService
{
    self = [super init];
    
    if (self != nil)
    {
        NSParameterAssert(cbService != nil);
        
        if (cbService != nil)
        {
            _CBService = cbService;
            
            _characteristics = [NSMutableDictionary dictionary];
        }
        else
        {
            self = nil;
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark Methods

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs completion:(VYServiceDiscoverCharacteristicsBlock)block
{
    NSAssert(![self isDiscoverCharacteristicsInProgress], @"Another discovery characteristics task is in progress.");
    
    if (![self isDiscoverCharacteristicsInProgress])
    {
        self.discoverCharacteristicsInProgress = YES;
        self.discoverCharacteristicsBlock = block;
        [self.CBService.peripheral discoverCharacteristics:characteristicUUIDs forService:self.CBService];
    }
}

- (void)configure
{
    
}

- (void)unconfigure
{
    
}

#pragma mark -
#pragma mark Handling CBPeripheral Callbacks

- (void)didDiscoverCharacteristicsWithError:(NSError *)error
{
    if (error == nil)
    {
        for (CBCharacteristic *cbCharacteristic in self.CBService.characteristics)
        {
            VYCharacteristic *characteristic = self.characteristics[cbCharacteristic.UUID];
            
            if (characteristic == nil)
            {
                characteristic = [VYCharacteristic characteristicWithCBCharacteristic:cbCharacteristic];
                
                self.characteristics[characteristic.CBCharacteristic.UUID] = characteristic;
            }
        }
    }
    
    if ([self isDiscoverCharacteristicsInProgress])
    {
        if (self.discoverCharacteristicsBlock != nil)
        {
            self.discoverCharacteristicsBlock(error);
            self.discoverCharacteristicsBlock = nil;
        }
        
        self.discoverCharacteristicsBlock = NO;
    }
}

@end
