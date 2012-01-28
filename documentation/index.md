# Urban Image Library Module

## Description

The purpose of this library is to provide easy access to the user's photo library.
Not only will it return the photos, but it will also return useful information about 
the photo.  This library will return the following pieces of information about a photo:

1. The full resolution of the image
2. A thumbnail of the image
3. The type of file (image or video)
4. Location information including:

		latitude
		longitude
		altitude
		course
		horizontal accuracy
		vertical accuracy
		speed
		timestamp
	
5. If the file is a video it will return the duration
6. Orientation
7. Creation Date
8. Available file formats
9. Ways to access the file

This library also provides a way to return certain groups of photos and to also return a 
section of photos based on start and end parameters. 


## Accessing the Urban Image Library Module

To access this module from JavaScript, you would do the following:

	var urbanimagelibrary = require("qs.urbanimage.library");

The urbanimagelibrary variable is a reference to the Module object.	

## Reference

### Input Parameters

The photolibrary.photos module can be called using the following parameters:

#### type
> The type of group you would like photos and videos to be returned from.  For further
> information see [Apple's documentation](http://developer.apple.com/library/IOs/#documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40009722) 

		Possible values are:
		library - The library group that includes all assets
		albums - All albums synced from iTunes
		events - All events synced from iTunes
		faces - All faces synced from iTunes
		photos - All photos
		all - Everything

> The default is "photos"

#### success

> This is a callback that will be called once the photos have been gathered

#### error

> This is a callback that will be called if an error occurred while gathering the photos

#### start

> This will include all photos whose index is greater than or equal to the value passed 
> in to start.

> The default is 0.

#### end

> This will include all photos whos index is less than or equal to the value passed in to
> end.  If end is set to 0, then there is no upper limit imposed.  All remaining photos
> will be included.

> The default is 0.

### Output Parameters

The module will return an array of objects in the "photos" attribute.

#### image

> The full resolution of the image.

#### thumbnail

> A thumbnail of the image.

#### type

> The type of file.  This attribute can take on either "image", "video", or "unknown"

#### location 

> Location information - See [Apple's documentation for the CLLocation class](http://developer.apple.com/library/IOs/#documentation/CoreLocation/Reference/CLLocation_Class/CLLocation/CLLocation.html#//apple_ref/occ/cl/CLLocation) 

		The location object consists of the following attributes:
		latitude - The latitude
		longitude - The longitude
		altitude - The altitude measured in meters.
		course - The direction in which the device is traveling.
		horizontalAccuracy - The radius of uncertainty for the location, measured in meters.
		vertical accuracy - The accuracy of the altitude value in meters.
		speed - The instantaneous speed of the device in meters per second.
		timestamp - The time at which this location was determined.

#### playTime 

> If the file is a video, it will return the play time duration of the video.  If the file is not a video, then the "playTime" attribute is not returned.

#### orientation

The corresponding value contains the photo's orientation as described by the TIFF format.
The TIFF specification can be found at (http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf)

The orientation value can be any of the following values:

		1 - The 0th row represents the visual top of the image, and the 0th column represents the visual left-hand side.
		2 - The 0th row represents the visual top of the image, and the 0th column represents the visual right-hand side.
		3 - The 0th row represents the visual bottom of the image, and the 0th column represents the visual right-hand side.
		4 - The 0th row represents the visual bottom of the image, and the 0th column represents the visual left-hand side.
		5 - The 0th row represents the visual left-hand side of the image, and the 0th column represents the visual top.
		6 - The 0th row represents the visual right-hand side of the image, and the 0th column represents the visual top.
		7 - The 0th row represents the visual right-hand side of the image, and the 0th column represents the visual bottom.
		8 - The 0th row represents the visual left-hand side of the image, and the 0th column represents the visual bottom.

#### creationDate

> The date the photo was created.  This is returned as a string in UTC format.

#### availableFormats 

> This is a collection of different formats that are available, i.e. jpeg.

#### waysToAccess

> This is a collection of URLs that could be used to access the photo.


## Usage

It is very simple to use the module.  After registering the module with the application, add
the following code to your project:

		var photolibrary = require('qs.photos.library');
		var photos = photolibrary.photos({
			success: function(e) {
				Ti.API.debug(e.photos);
			},
			error: function(e) {
				Ti.API.error("An error occured! " + e);
			}
		});

This will load the Photo Library module and will return all saved photos on the device.

## Author

Quickstone Software, LLC 

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
