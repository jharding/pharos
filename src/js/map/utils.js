(function(_) {
    var utils = {
        // serialize object into a query string
        // doesn't handle nesting
        param: function(obj) {
            var str = '';

            _(obj).each(function(value, key) {
                str += encodeURIComponent(key) + '=' + 
                       encodeURIComponent(value) + '&';
            });

            // chop off trailing &
            str = str.slice(0, -1);

            return str;
        },

        // deserialize query string into an object 
        // doesn't handle nesting
        deparam: function(str) {
            var obj = {};

            var pairs = str.split('&');
            _(pairs).each(function(pair) {
                pair = pair.split('=');
                var key = pair[0];
                var value = pair[1];

                obj[key] = decodeURIComponent(value);
            });

            return obj;
        }
    };

    // expose globally
    window.utils = utils;

})(window._);
