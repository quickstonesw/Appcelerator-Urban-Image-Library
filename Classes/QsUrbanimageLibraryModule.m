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
@synthesize assetLibrary;

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
	assetLibrary = [[ALAssetsLibrary alloc] init];
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
    RELEASE_TO_NIL(assetLibrary);
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
    Boolean includeFullSizeImage = [TiUtils boolValue:[args objectForKey:@"includeFullSizeImage"] def:true];
    
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
    
    [self buildAssets:assetGroupType start:start end:end includeFullSizeImage:includeFullSizeImage];
}

-(void)photo:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *url = [args objectForKey:@"url"];
    ENSURE_STRING_OR_NIL(url);
    
    id error = [args objectForKey:@"error"];
    RELEASE_TO_NIL(errorCallback);
    
    id success = [args objectForKey:@"success"];
    RELEASE_TO_NIL(successCallback);
    
    errorCallback = [error retain];
    successCallback = [success retain];
    
    if (url)
    {
        NSURL *imageRefURL = [NSURL URLWithString:url];
        void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *) = ^(ALAsset *result)
        {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [self buildProperties:result includeFullSizeImage:true], @"photo", nil];
            
            [self _fireEventToListener:@"success" withObject:event listener:successCallback thisObject:nil];
        };
        
        
        NSLog(@"%@",imageRefURL);
        [assetLibrary assetForURL:imageRefURL
                 resultBlock:ALAssetsLibraryAssetForURLResultBlock 
                failureBlock:^(NSError *error){
                    if (errorCallback)
                        [self _fireEventToListener:@"error" withObject:error listener:errorCallback thisObject:nil];
                }];
    }
    
}

-(void)buildAssets:(NSUInteger) assetGroupType start:(NSUInteger)start end:(NSUInteger)end includeFullSizeImage:(Boolean)includeFullSizeImage
{
    NSMutableArray *assets = [[[NSMutableArray alloc] init] autorelease];
    
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = 
    ^(ALAsset *result, NSUInteger index, BOOL *stop)
    {
        if(result != nil) {
            if (index >= start) 
            {
                if (end > 0 && index > end) return;
                
                [assets addObject:[self buildProperties:result includeFullSizeImage:includeFullSizeImage]];
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
    
    [assetLibrary enumerateGroupsWithTypes:assetGroupType
                           usingBlock:assetGroupEnumerator
                         failureBlock: ^(NSError *error) {
                             if (errorCallback)
                                 [self _fireEventToListener:@"error" withObject:error listener:errorCallback thisObject:nil];
                         }];
}

-(NSDictionary*)buildProperties:(ALAsset*)asset includeFullSizeImage:(Boolean)includeFullSizeImage
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    CGImageRef fullImageRef = [rep fullResolutionImage];
    
    if (includeFullSizeImage && fullImageRef)
    {
        UIImageOrientation orientation = UIImageOrientationUp;
        
        
        int sourceOrientation = [[asset valueForProperty:ALAssetPropertyOrientation] intValue];
        
        if (sourceOrientation == 0) // Up
            orientation = UIImageOrientationUp;
        if (sourceOrientation == 1) // Down
            orientation = UIImageOrientationDown;
        else if (sourceOrientation == 2) //Right
            orientation = UIImageOrientationLeft;
        if (sourceOrientation == 3) // Left
            orientation = UIImageOrientationRight;
        else if (sourceOrientation == 4) // Up Mirrored
            orientation = UIImageOrientationUpMirrored;
        else if (sourceOrientation == 5) // Down Mirrored
            orientation = UIImageOrientationDownMirrored;
        else if (sourceOrientation == 6) // Left Mirrored
            orientation = UIImageOrientationLeftMirrored;
        else if (sourceOrientation == 7) // Right Mirrored
            orientation = UIImageOrientationRightMirrored;
        
        UIImage *fullImage = [UIImage imageWithCGImage:fullImageRef scale:1.0 orientation:orientation];
        [props setObject:[[[TiBlob alloc] initWithImage:fullImage] autorelease] 
                  forKey:@"image"];
    }
    
    CGImageRef thumbnailRef = [asset thumbnail];
    if (thumbnailRef)
    {
        UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailRef];
        [props setObject:[[[TiBlob alloc] initWithImage:thumbnail] autorelease] 
                  forKey:@"thumbnail"];
    }
    
    NSString *assetPropertyType = [asset valueForProperty:ALAssetPropertyType];
    NSString *type = nil;
    
    if ([@"ALAssetTypePhoto" isEqualToString:assetPropertyType])
        type = @"photo";
    else if ([@"ALAssetTypeVideo" isEqualToString:assetPropertyType])
        type = @"video";
    else
        type = @"unknown";
    
    [props setObject:type forKey:@"type"];
    
    CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
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
    
    if ([[asset valueForProperty:ALAssetPropertyDuration] isKindOfClass:[NSNumber class]])
        [props setObject:[asset valueForProperty:ALAssetPropertyDuration] forKey:@"playTime"];
    
    [props setObject:[asset valueForProperty:ALAssetPropertyOrientation] forKey:@"orientation"];
    [props setObject:[TiUtils UTCDateForDate:[asset valueForProperty:ALAssetPropertyDate]] forKey:@"creationDate"];
    [props setObject:[asset valueForProperty:ALAssetPropertyRepresentations] forKey:@"availableFormats"];
    [props setObject:[asset valueForProperty:ALAssetPropertyURLs] forKey:@"waysToAccess"];
    
    return props;
}

@end
