//
//  VYCentralController.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface VYCentralController : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, readonly) CBCentralManager *centralManager;
@property (nonatomic, readonly) CBPeripheral *peripheral;

@end
