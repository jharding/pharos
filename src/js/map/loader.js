(function(_) {
    var loader = (function() {
        // constants
        var API_KEY = 'AIzaSyCqSJp43Vp9Eo7oKjcyYqaXuH7qG8vSn9I';
        var MAP_SIZE = '400x300';
        var STATIC_MAP_TYPE = 'roadmap';
        var STATIC_MAP_URL = 'http://maps.googleapis.com/maps/api/staticmap?';
        var STREET_VIEW_URL = 'http://maps.googleapis.com/maps/api/streetview?';
        var MARKER_ICON_URL = 'http://pharosapp.com/public/img/map_icon.png';

        // DOM references
        var streetText = document.getElementById('street-text');
        var cityStateText = document.getElementById('city-state-text');
        var staticMapImage = document.getElementById('static-map');
        var streetViewImage = document.getElementById('street-view');

        // deserialize url parameters and put them in an object
        var getData = function() {
            var search = location.search;

            // strip the leading ?
            var parameters = search.slice(1);
            parameters = utils.deparam(parameters);
            
            var coordinates = parameters.l.split(',');
            var lat = coordinates[0];
            var lng = coordinates[1];

            return {
                lat: coordinates[0] || 0,
                lng: coordinates[1] || 0,
                heading: parameters.h || 0,
                street: parameters.sr || '',
                city: parameters.c || '',
                state: parameters.sa || ''
            };

        };

        var setAddress = function(street, city, state) {
           streetText.innerHTML = street;

            if (city) {
                cityStateText.innerHTML = city + ', ' + state;
            }

            else {
                cityStateText.innerHTML = state;
            }
        };

        var loadStaticMap = function(lat, lng) {
            var marker = 'icon:' + MARKER_ICON_URL + '|' + lat + ',' + lng;

            var parameters = {
                size: MAP_SIZE,
                maptype: STATIC_MAP_TYPE,
                markers: marker,
                sensor: false,
                key: API_KEY
            };

            var url = STATIC_MAP_URL + utils.param(parameters);
            staticMapImage.src = url;
        };

        var loadStreetView = function(lat, lng, heading) {
            var parameters = {
                size: MAP_SIZE,
                location: lat + ',' + lng,
                heading: heading,
                sensor: false,
                key: API_KEY
            };

            var url = STREET_VIEW_URL + utils.param(parameters);
            streetViewImage.src = url;
        };

        var exports = {
            start: function() {
                var data = getData();

                setAddress(data.street, data.city, data.state);
                loadStaticMap(data.lat, data.lng);
                loadStreetView(data.lat, data.lng, data.heading);
            }
        };

        return exports;
    })();

    // start your engines... 
    loader.start();

})(window._);
