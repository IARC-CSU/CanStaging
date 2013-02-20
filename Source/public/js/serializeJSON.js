/* Inspired by http://stackoverflow.com/questions/9087302/create-custom-json-string-from-form */
(function( $ ){
    $.fn.serializeJSON=function() {
        var json = {};
        jQuery.map($(this).serializeArray(), function(n, i){
            json[n['name']] = n['value'];
        });
        return json;
    };
})( jQuery );