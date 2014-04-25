//
//  VYCentralManager.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@class VYPeripheral;

@interface VYCentralManager : NSObject <CBCentralManagerDelegate>

@property (nonatomic, readonly) CBCentralManager *CBCentralManager;

@property (nonatomic, readonly) NSMutableDictionary *peripherals;

+ (instancetype)sharedManager;

- (void)scanForPeripherals;
- (void)stopScanForPeripherals;

- (void)connectPeripheral:(VYPeripheral *)peripheral;
- (void)disconnectPeripheral:(VYPeripheral *)peripheral;

@end
