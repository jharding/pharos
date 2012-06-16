(function(_) {
    var loader = (function() {
        // constants
        var API_KEY = 'AIzaSyCqSJp43Vp9Eo7oKjcyYqaXuH7qG8vSn9I';
        var MAP_SIZE = '400x300';
        var STATIC_MAP_TYPE = 'roadmap';
        var STATIC_MAP_URL = 'http://maps.googleapis.com/maps/api/staticmap?';
        var STREET_VIEW_URL = 'http://maps.googleapis.com/maps/api/streetview?';
        var MARKER_ICON_URL = '';

        // DOM references
        var staticMapImage = document.getElementById('static-map');
        var streetViewImage = document.getElementById('street-view');

        // deserialize url parameters and put them in an object
        var getMetadata = function() {
            var search = location.search;

            // strip the leading ?
            var parameters = search.slice(1);
            return utils.deparam(parameters);
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
                var metadata = getMetadata();
                var lat = metadata.lat || 0;
                var lng = metadata.lng || 0;
                var heading = metadata.heading || 0;

                loadStaticMap(lat, lng);
                loadStreetView(lat, lng, heading);
            }
        };

        return exports;
    })();

    // start your engines... 
    loader.start();

})(window._);
