/*
 Copyright 2012 Quickstone Software LLC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

var urbanimagelibrary = require('qs.urbanimage.library');
Ti.API.info("module is => " + urbanimagelibrary);

var window = Ti.UI.createWindow({
	backgroundColor:'white'
});

var tableView = Ti.UI.createTableView({});
window.add(tableView);

function clickPhoto(photoView, photo) {
	photoView.addEventListener("click", function(e) {
		if (typeof photo.location !== 'undefined') {
			var photoAnnotation = Ti.Map.createAnnotation({
				latitude: photo.location.latitude,
				longitude: photo.location.longitude,
				title: "Taken: " + photo.creationDate
			});
			
			var mapview = Titanium.Map.createView({
				mapType: Titanium.Map.STANDARD_TYPE,
				region:{latitude:photo.location.latitude, longitude:photo.location.longitude, latitudeDelta:0.5, longitudeDelta:0.5},
				animate:true,
				userLocation:true,
				annotations:[photoAnnotation]
			});
			mapview.selectAnnotation(photoAnnotation);
			var w = Ti.UI.createWindow({navBarHidden:false});
			var closeButton = Ti.UI.createButton({
				title: "Close",
				style: Titanium.UI.iPhone.SystemButtonStyle.BORDERED
			});
			closeButton.addEventListener("click", function(e){
				w.close();
			});
			w.add(mapview);
            
			var toolbar = Ti.UI.iOS.createToolbar({
				items:[closeButton],
				bottom:'base',
				translucent: true
			});
			w.add(toolbar);
			w.open({
				model:true, 
				modalTransitionStyle:Ti.UI.iPhone.MODAL_TRANSITION_STYLE_COVER_VERTICAL, 
				modalStyle:Ti.UI.iPhone.MODAL_PRESENTATION_FULLSCREEN, 
				navBarHidden:false
			});
		}
	});
}

function updateTableView(photos) {
	var data = [];
	var row;
	for (var counter=0; counter < photos.length; counter++) {
		var photo = photos[counter];
		var image = Ti.UI.createImageView({
			image: photo.thumbnail,
			height: photo.thumbnail.height,
			width: photo.thumbnail.width,
			top: 0,
			left: 4 + ((counter % 4) * (photo.thumbnail.width +4))
		});
		var date = photo.creationDate.split("T");
		var dateLabel = Ti.UI.createLabel({
			text:date[0],
			font: {	fontSize: 10},
			bottom: 10,
			height: 10,
			left: 4 + ((counter % 4) * (photo.thumbnail.width +4))
		});
		var time = date[1].split(".");
		var timeLabel = Ti.UI.createLabel({
			text:time[0],
			font: {	fontSize: 10},
			bottom: 0,
			height: 10,
			left: 4 + ((counter % 4) * (photo.thumbnail.width +4))
		});
		if (counter % 4 === 0) {
			row = Ti.UI.createTableViewRow({
				height: 100,
				selectionStyle: Titanium.UI.iPhone.TableViewCellSelectionStyle.NONE
			});
			data.push(row);
		}
		row.add(image);
		row.add(dateLabel);
		row.add(timeLabel);
		clickPhoto(image, photo);
	}
	tableView.setData(data);
}

var photos = urbanimagelibrary.photos({
	success: function(e) {
		Ti.API.debug("Number of photos returned: " + e.photos.length);
		updateTableView(e.photos);
	},
	error: function(e) {
		Ti.API.error("An error occured! " + e);
	}
});

window.open();

