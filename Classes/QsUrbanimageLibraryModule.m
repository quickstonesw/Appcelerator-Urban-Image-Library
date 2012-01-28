/**
 * Copyright 2012 Quickstone Software, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. */

#import "QsUrbanimageLibraryModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation QsUrbanimageLibraryModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"c6d0f327-80e0-400f-929c-012ece34ec98";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"qs.urbanimage.library";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

-(void)photos:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *type = [args objectForKey:@"type"];
    ENSURE_STRING_OR_NIL(type);
    
    id error = [args objectForKey:@"error"];
    RELEASE_TO_NIL(errorCallback);
    
    id success = [args objectForKey:@"success"];
    RELEASE_TO_NIL(successCallback);
    
    errorCallback = [error retain];
    successCallback = [success retain];
    
    NSUInteger start = [TiUtils intValue:[args objectForKey:@"start"]];
    NSUInteger end = [TiUtils intValue:[args objectForKey:@"end"]];
    
    if (type == nil)
        type = @"photos";
    
    NSUInteger assetGroupType = ALAssetsGroupSavedPhotos;
    
    if ([@"library" caseInsensitiveCompare:type] == NSOrderedSame)
        assetGroupType = ALAssetsGroupLibrary;
    else if ([@"albums" caseInsensitiveCompare:type] == NSOrderedSame)
        assetGroupType = ALAssetsGroupAlbum;
    else if ([@"events" caseInsensitiveCompare:type] == NSOrderedSame)
        assetGroupType = ALAssetsGroupEvent;
    else if ([@"faces" caseInsensitiveCompare:type] == NSOrderedSame)
        assetGroupType = ALAssetsGroupFaces;
    else if ([@"photos" caseInsensitiveCompare:type] == NSOrderedSame)
        assetGroupType = ALAssetsGroupSavedPhotos;
    else if ([@"all" caseInsensitiveCompare:type] == NSOrderedSame)
        assetGroupType = ALAssetsGroupAll;
    
    [self buildAssets:assetGroupType start:start end:end];
}

-(void)buildAssets:(NSUInteger) assetGroupType start:(NSUInteger)start end:(NSUInteger)end
{
    NSMutableArray *assets = [[[NSMutableArray alloc] init] autorelease];
    
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = 
    ^(ALAsset *result, NSUInteger index, BOOL *stop)
    {
        if(result != nil) {
            if (index >= start) 
            {
                if (end > 0 && index > end) return;
                
                NSMutableDictionary *props = [NSMutableDictionary dictionary];
                
                ALAssetRepresentation *rep = [result defaultRepresentation];
                CGImageRef fullImageRef = [rep fullResolutionImage];
                if (fullImageRef)
                {
                    UIImage *fullImage = [UIImage imageWithCGImage:fullImageRef];
                    [props setObject:[[[TiBlob alloc] initWithImage:fullImage] autorelease] 
                              forKey:@"image"];
                }
                
                CGImageRef thumbnailRef = [result thumbnail];
                if (thumbnailRef)
                {
                    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailRef];
                    [props setObject:[[[TiBlob alloc] initWithImage:thumbnail] autorelease] 
                              forKey:@"thumbnail"];
                }
                
                NSString *assetPropertyType = [result valueForProperty:ALAssetPropertyType];
                NSString *type = nil;
                
                if ([@"ALAssetTypePhoto" isEqualToString:assetPropertyType])
                    type = @"photo";
                else if ([@"ALAssetTypeVideo" isEqualToString:assetPropertyType])
                    type = @"video";
                else
                    type = @"unknown";
                
                [props setObject:type forKey:@"type"];
                
                CLLocation *location = [result valueForProperty:ALAssetPropertyLocation];
                CLLocationCoordinate2D latlon = [location coordinate];
                if (!isnan(latlon.latitude) && !(isnan(latlon.longitude)))
                {
                    [props setObject: [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithFloat:latlon.latitude], @"latitude",
                                       [NSNumber numberWithFloat:latlon.longitude], @"longitude",
                                       [location altitude], @"altitude",
                                       [location course], @"course",
                                       [location horizontalAccuracy], @"horizontalAccuracy",
                                       [location verticalAccuracy], @"verticalAccuracy",
                                       [location speed], @"speed",
                                       [location timestamp], @"timestamp",
                                       nil] 
                              forKey: @"location"];
                }
                
                if ([[result valueForProperty:ALAssetPropertyDuration] isKindOfClass:[NSNumber class]])
                    [props setObject:[result valueForProperty:ALAssetPropertyDuration] forKey:@"playTime"];
                [props setObject:[result valueForProperty:ALAssetPropertyOrientation] forKey:@"orientation"];
                [props setObject:[TiUtils UTCDateForDate:[result valueForProperty:ALAssetPropertyDate]] forKey:@"creationDate"];
                [props setObject:[result valueForProperty:ALAssetPropertyRepresentations] forKey:@"availableFormats"];
                [props setObject:[result valueForProperty:ALAssetPropertyURLs] forKey:@"waysToAccess"];
                
                [assets addObject:props];
            }
        }
    };
    
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) =  
    ^(ALAssetsGroup *group, BOOL *stop) 
    {
        if(group != nil) {
            [group enumerateAssetsUsingBlock:assetEnumerator];
            if (successCallback) {
                NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                                       assets, @"photos", nil];
                [self _fireEventToListener:@"success" withObject:event listener:successCallback thisObject:nil];
            }
        }
    };
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:assetGroupType
                           usingBlock:assetGroupEnumerator
                         failureBlock: ^(NSError *error) {
                             if (errorCallback)
                                 [self _fireEventToListener:@"error" withObject:error listener:errorCallback thisObject:nil];
                         }];
}

@end
