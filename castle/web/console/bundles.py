from __future__ import absolute_import

from webassets import Bundle

# tmp_js = Bundle(
    # 'client/app/templates/*.jst',
    # filters='underscore', output='tmp.js'
# )

castle_js = Bundle(
    #Bootstrap
    Bundle(
        'client/vendor/bootstrap/js/bootstrap-affix.js',
        'client/vendor/bootstrap/js/bootstrap-alert.js',
        'client/vendor/bootstrap/js/bootstrap-button.js',
        'client/vendor/bootstrap/js/bootstrap-carousel.js',
        'client/vendor/bootstrap/js/bootstrap-collapse.js',
        'client/vendor/bootstrap/js/bootstrap-dropdown.js',
        'client/vendor/bootstrap/js/bootstrap-modal.js',
        'client/vendor/bootstrap/js/bootstrap-scrollspy.js',
        'client/vendor/bootstrap/js/bootstrap-tab.js',
        'client/vendor/bootstrap/js/bootstrap-tooltip.js',
        'client/vendor/bootstrap/js/bootstrap-popover.js',
        'client/vendor/bootstrap/js/bootstrap-transition.js',
        'client/vendor/bootstrap/js/bootstrap-typeahead.js'
    ),
    #Templates
    Bundle(
        'client/app/templates/*.jst',
        filters='underscore'
    ),
    Bundle(
        'client/vendor/async.js',
        'client/vendor/gzip.min.js'

    ),
    #Castle
    Bundle(
        'client/app/coffee/config.coffee',
        'client/app/coffee/app.coffee',
        'client/app/coffee/models.coffee',
        'client/app/coffee/collections.coffee',
        'client/app/coffee/views.coffee',
        'client/app/coffee/main.coffee',
        filters='coffeescript', debug=False, output='.webassets-x-tmp/_castle.js'
    ),
    filters='yui_js', output='public/assets/js/castle.js'
)


castle_css = Bundle(
    'client/app/less/castle.less',
    filters='less, yui_css', output='public/assets/css/castle.css'
)
