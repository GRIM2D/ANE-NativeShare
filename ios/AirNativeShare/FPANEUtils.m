//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//////////////////////////////////////////////////////////////////////////////////////

#import "FPANEUtils.h"


#pragma mark - Dispatch events

void FPANE_DispatchEvent(FREContext context, NSString *eventName)
{
    FREDispatchStatusEventAsync(context, (const uint8_t *)[eventName UTF8String], (const uint8_t *)"");
}

void FPANE_DispatchEventWithInfo(FREContext context, NSString *eventName, NSString *eventInfo)
{
    FREDispatchStatusEventAsync(context, (const uint8_t *)[eventName UTF8String], (const uint8_t *)[eventInfo UTF8String]);
}

void FPANE_Log(FREContext context, NSString *message)
{
    FPANE_DispatchEventWithInfo(context, @"LOGGING", message);
}


#pragma mark - FREObject -> Obj-C

NSString * FPANE_FREObjectToNSString(FREObject object)
{
    uint32_t stringLength;
    const uint8_t *string;
    FREGetObjectAsUTF8(object, &stringLength, &string);
    return [NSString stringWithUTF8String:(char*)string];
}

NSArray * FPANE_FREObjectToNSArrayOfNSString(FREObject object)
{
    uint32_t arrayLength;
    FREGetArrayLength(object, &arrayLength);
    
    uint32_t stringLength;
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:arrayLength];
    for (NSInteger i = 0; i < arrayLength; i++)
    {
        FREObject itemRaw;
        FREGetArrayElementAt(object, (uint)i, &itemRaw);
        
        // Convert item to string. Skip with warning if not possible.
        const uint8_t *itemString;
        if (FREGetObjectAsUTF8(itemRaw, &stringLength, &itemString) != FRE_OK)
        {
            NSLog(@"Couldn't convert FREObject to NSString at index %ld", (long)i);
            continue;
        }
        
        NSString *item = [NSString stringWithUTF8String:(char*)itemString];
        [mutableArray addObject:item];
    }
    
    return [NSArray arrayWithArray:mutableArray];
}

NSDictionary * FPANE_FREObjectsToNSDictionaryOfNSString(FREObject keys, FREObject values)
{
    uint32_t numKeys, numValues;
    FREGetArrayLength(keys, &numKeys);
    FREGetArrayLength(values, &numValues);
    
    uint32_t stringLength;
    uint32_t numItems = MIN(numKeys, numValues);
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
    for (NSInteger i = 0; i < numItems; i++)
    {
        FREObject keyRaw, valueRaw;
        FREGetArrayElementAt(keys, (uint)i, &keyRaw);
        FREGetArrayElementAt(values, (uint)i, &valueRaw);
        
        // Convert key and value to strings. Skip with warning if not possible.
        const uint8_t *keyString, *valueString;
        if (FREGetObjectAsUTF8(keyRaw, &stringLength, &keyString) != FRE_OK || FREGetObjectAsUTF8(valueRaw, &stringLength, &valueString) != FRE_OK)
        {
            NSLog(@"Couldn't convert FREObject to NSString at index %ld", (long)i);
            continue;
        }
        
        NSString *key = [NSString stringWithUTF8String:(char*)keyString];
        NSString *value = [NSString stringWithUTF8String:(char*)valueString];
        [mutableDictionary setObject:value forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

BOOL FPANE_FREObjectToBool(FREObject object)
{
    uint32_t b;
    FREGetObjectAsBool(object, &b);
    return b != 0;
}

NSInteger FPANE_FREObjectToInt(FREObject object)
{
    int32_t i;
    FREGetObjectAsInt32(object, &i);
    return i;
}

double FPANE_FREObjectToDouble(FREObject object)
{
    double x;
    FREGetObjectAsDouble(object, &x);
    return x;
}


#pragma mark - Obj-C -> FREObject

FREObject FPANE_BOOLToFREObject(BOOL boolean)
{
    FREObject result;
    if (FRENewObjectFromBool(boolean, &result) == FRE_OK)
    {
        return result;
    }
    return nil;
}

FREObject FPANE_IntToFREObject(NSInteger i)
{
    FREObject result;
    FRENewObjectFromInt32((int32_t)i, &result);
    return result;
}

FREObject FPANE_DoubleToFREObject(double d)
{
    FREObject result;
    FRENewObjectFromDouble(d, &result);
    return result;
}

FREObject FPANE_NSStringToFREObject(NSString *string)
{
    FREObject result;
    FREResult operationResult = FRENewObjectFromUTF8((int)string.length, (const uint8_t *)[string UTF8String], &result);
    if ( operationResult == FRE_OK)
    {
        return result;
    } else
    {
        if (operationResult == FRE_INVALID_ARGUMENT)
        {
            NSLog(@"could't convert string %@ - Invalid Argument", string);

        } else if (operationResult == FRE_WRONG_THREAD)
        {
            NSLog(@"could't convert string %@ - Wrong Thread", string);
        } else
        {
            NSLog(@"could't convert string %@ - Unknown error", string);
        }
        
    }
    return NULL;

}

FREObject FPANE_CreateError( NSString* error, NSInteger* id )
{
    FREObject ret;
    FREObject errorThrown;
    
    FREObject freId;
    FRENewObjectFromInt32( (int32_t)*id, &freId);
    FREObject argV[] = {
        FPANE_NSStringToFREObject(error),
        freId
    };
    FRENewObject((const uint8_t*)"Error", 2, argV, &ret, &errorThrown);
    
    return ret;
}