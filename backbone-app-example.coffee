class LiveSupportHeaderButtonsView extends Marionette.ItemView
  template  : '#live-support__header-buttons-template'
  tagName   : 'ul'
  className : 'buttons'
  ui        :
    save    : '[data-action=save]'
    restore : '[data-action=restore]'
  events    :
    'click @ui.save'    : -> vent.trigger( 'liveSupport:widget:save' )
    'click @ui.restore' : -> vent.trigger( 'liveSupport:widget:restore' )


class LiveSupportFormModel extends Backbone.Model
  url : -> Routing.generate( 'rest_api_v1_live_support_form_fields', slug : apps( 'liveSupport' ).settings.slug )


class LiveSupportNavigationCollection extends Backbone.Collection
  initialize : ->
    return @set([
      id      : 'settings'
      name    : 'Settings'
      current : false
    ,
      id      : 'integration'
      name    : 'Integration'
      current : false
    ])

  setCurrent : ( id ) -> @map( ( model ) -> model.set( 'current', "#{model.id}" is "#{id}" ) )

  getCurrent : -> @findWhere( current : true )


class LiveSupportNavigationItemView extends Marionette.ItemView
  template  : '#live-support__navigation-item-template'
  tagName   : 'li'
  className : 'live-support__navigation-item'

  serializeData : -> _.extend( @model.toJSON(), widgetId : apps( 'liveSupport' ).data.widgets.getCurrent().id )


# Navigation view
class LiveSupportNavigationView extends Marionette.CollectionView
  tagName   : 'ul'
  className : 'list-inline live-support__config-navigation'
  childView : LiveSupportNavigationItemView


class LiveSupportStoreView extends Marionette.ItemView
  className : 'col-md-6 col-sm-12 col-xs-12'
  template  : '#live-support__store-template'
  ui        :
    'applied' : '[name=applied]'
  events    :
    'change @ui.applied' : '_toggleAppliance'

  _toggleAppliance : ( event ) ->
    app = apps( 'liveSupport' )
    # TODO: Dirty! Ask backend to send a correct data with id for model with PATCH request
    $.ajax(
      url    : Routing.generate( 'rest_api_v1_live_support_store_relation',
        channelSetId : @model.get( 'channel_set' ).id
        id           : app.data.widgets.getCurrent().id
        slug         : app.settings.slug
      )
      data   :
        applied : event.currentTarget.checked
      method : 'PATCH'
      error  : ( response ) -> vent.trigger( 'layout:error:show', response.responseText )
    )


class LiveSupportStoreCollectionView extends Marionette.CollectionView
  className : 'row live-support__store-collection'
  childView : LiveSupportStoreView


# Integration view
class LiveSupportIntegrationView extends Marionette.LayoutView
  template  : '#live-support__integration-template'
  className : 'live-support__config-content-inner'
  regions   :
    stores : '[data-region=stores]'

  serializeData : ->
    slug = apps( 'liveSupport' ).settings.slug
    embedScriptUrl = Routing.generate( 'live_support.embed.js', { slug : slug, liveSupportItemId: @model.id }, true )
    embedCode = "<div id=\"payever-activator-div\"></div>\n<div id=\"payever-content-div\"></div>\n<script src=\"#{embedScriptUrl}\"></script>"
    _.extend( @model.toJSON(), embedCode: embedCode )

  onBeforeShow : ->
    @showChildView( 'stores', new LiveSupportStoreCollectionView( collection : @model.get( 'stores' ) ) )


# Settings form header
class LiveSupportSettingsFormHeaderView extends Marionette.ItemView
  template  : '#live-support__settings-form-header-template'
  tagName   : 'header'
  className : 'live-support__settings-form-header'

  serializeData : ->
    parentSectionLink  : @options.parentSectionLink
    parentSectionTitle : @options.parentSectionTitle
    sectionTitle       : @options.sectionTitle


class LiveSupportChatPreviewView extends Marionette.ItemView
  className   : 'messenger-app'
  template    : '#live-support__chat-preview-template'
  modelEvents :
    'change:welcome_title change:welcome_description change:logo' : 'render'


class LiveSupportBubblePreviewView extends Marionette.ItemView
  template  : '#live-support__bubble-preview-template'
  className : 'live-support__settings-preview'
  ui       :
    logoPreview : '[data-preview=logo]'
  modelEvents :
    'change:logo' : 'render'

  initialize : ->
    @listenTo( vent, 'liveSupport:preview:changeMessage', @_changeMessage )

  onShow : ->
    @ui.logoPreview.payever_ui_popover(
      content : @model.get( 'message' )
      inline  : true
    )

  _changeMessage : ( text ) ->
    @ui.logoPreview.trigger( 'popover:content:change', text )


# Abstract settings form
class LiveSupportSettingsFormView extends Marionette.LayoutView
  template    : '#live-support__settings-form-template'
  tagName     : 'form'
  ui          :
    sectionLink         : '[data-section-link]'
    formControl         : '[name]'
    logoPreview         : '[data-preview=logo]'
# ui-mapping for errors
    name                : '[name=name]'
    message             : '[name=message]'
    visibleType         : '[name=visible_type]'
    welcome_title       : '[name=welcome_title]'
    welcome_description : '[name=welcome_description]'
    logo_file           : '[name=logo_file]'
  events      :
    'click @ui.sectionLink'         : '_navigateToSection'
    'change @ui.formControl'        : '_changeModel'
    'keyup @ui.message'             : '_changeMessagePreview'
    'keyup @ui.welcome_title'       : '_changeModel'
    'keyup @ui.welcome_description' : '_changeModel'
    'change @ui.logo_file'          : '_saveLogo'
  modelEvents :
    'change:logo' : 'render'

  regions   :
    sectionHeader : '[data-region=sectionHeader]'

  initialize : ->
    @listenTo( vent, 'liveSupport:settings:showErrors', @_showErrors )

  serializeData : -> _.extend( @model.toJSON(), apps( 'liveSupport' ).data.form.toJSON() )

  onBeforeShow : ->
    if not @options.sectionId or @options.sectionId is 'settings'
      return
    sectionHeaderView =  new LiveSupportSettingsFormHeaderView(
      parentSectionLink  : @options.parentSectionLink
      parentSectionTitle : @options.parentSectionTitle
      sectionTitle       : @options.sectionTitle
    )
    @showChildView( 'sectionHeader', sectionHeaderView )

  onShow : ->
    @$('select').payever_ui_select()

  _saveLogo : ( event ) ->
    reader = new FileReader
    reader.onload = => @model.set( 'logo', reader.result )
    reader.readAsDataURL( event.currentTarget.files[0] )
    apps( 'liveSupport' ).data.logoFile = event.currentTarget.files[0]

  _navigateToSection : ( event ) ->
    event.preventDefault()
    vent.trigger( 'liveSupport:formSection:show', @$( event.currentTarget ).data( 'sectionLink' ) )

  _changeModel : ->
    Backbone.Syphon.InputReaders.register( 'checkbox', ( $el ) -> if $el.prop( 'checked' ) then $el.val() )
    @model.set( Backbone.Syphon.serialize( @$el, exclude : ['logo_file'] ) )

  _changeMessagePreview : ( event ) ->
    vent.trigger( 'liveSupport:preview:changeMessage', event.currentTarget.value )

  _showErrors : ( errors ) ->
    @$el.payever_ui_error( reset : true )
    for key, val of errors
      if val.errors then @ui[key]?.payever_ui_error( show : true, message : val.errors[0] )


# Settings layout view
class LiveSupportSettingsView extends Marionette.LayoutView
  template    : '#live-support__settings-template'
  className   : 'live-support__config-content-inner'
  regions     :
    form    : '[data-region=form]'
    preview : '[data-region=preview]'
  modelEvents :
    'change:visible_type' : '_showPreview'

  initialize : ->
    @listenTo( vent, 'liveSupport:formSection:show', @_showFormSection  )

  onBeforeShow : ->
    @_showPreview()
    @_showFormSection()

  _showFormSection : ( sectionId ) ->
    options =
      triggers : [ '#live-support__triggers-form-template', 'settings', 'Settings', 'Triggers' ]
      schedule : [ '#live-support__schedule-form-template', 'triggers', 'Triggers', 'Schedule' ]
      devices  : [ '#live-support__devices-form-template',  'triggers', 'Triggers', 'Devices' ]
      visitors : [ '#live-support__visitors-form-template', 'triggers', 'Triggers', 'Visitors' ]
      country  : [ '#live-support__country-form-template',  'triggers', 'Triggers', 'Country' ]
    settings =
      model     : @model
      sectionId : sectionId
    if options[ sectionId ]
      _.extend( settings, _.object( ['template', 'parentSectionLink', 'parentSectionTitle', 'sectionTitle'], options[sectionId] ) )
    @showChildView( 'form', new LiveSupportSettingsFormView( settings ) )

  _showPreview : ->
    PreviewViewClass = LiveSupportBubblePreviewView
    if @model.get('visible_type') is 'full_screen'
      PreviewViewClass = LiveSupportChatPreviewView
    @showChildView( 'preview', new PreviewViewClass( model : @model ) )


class LiveSupportConfigView extends Marionette.LayoutView
  template : '#live-support__config-template'
  regions  :
    headerButtons : '[data-region=headerButtons]'
    navigation    : '[data-region=navigation]'
    content       : '[data-region=content]'

  initialize : ->
    @model.backup()
    @listenTo( vent, 'liveSupport:widget:save', @_saveWidget  )
    @listenTo( vent, 'liveSupport:widget:restore', @_restoreWidget  )

  onBeforeShow : ->
    @showChildView( 'headerButtons', new LiveSupportHeaderButtonsView )
    @_showNavigation()
    @_showContent()

  _showNavigation : ->
    unless @model.isNew()
      @showChildView( 'navigation', new LiveSupportNavigationView( collection : apps( 'liveSupport' ).data.navigation ) )

  _showContent : ->
    appData = apps( 'liveSupport' ).data
    navigation = appData.navigation
    isIntegration = navigation.getCurrent()?.id is 'integration'
    ContentViewClass = LiveSupportSettingsView
    if isIntegration and !@model.isNew()
      ContentViewClass = LiveSupportIntegrationView
    @showChildView( 'content', new ContentViewClass( model : @model ) )

  _saveWidget : ->
    data = _.omit( @model.toJSON(), 'current', 'enabled', 'stores', 'logo', 'logo_empty' )
    helpers.compactObject( data )
    logoFile = apps( 'liveSupport' ).data.logoFile
    if logoFile
      data.logo = logoFile
    $.ajax(
      url         : Routing.generate( 'rest_api_v1_live_support_save', slug : apps( 'liveSupport' ).settings.slug )
      data        : helpers.objectToFormData( data, 'live_support_item' )
      method      : 'post'
      cache       : false
      contentType : false
      processData : false
      beforeSend  : -> vent.trigger( 'layout:loading:toggle', true )
      success     : ->
        app = apps( 'liveSupport' )
        app.data.widgets.reset()
        app.router.navigate( 'list', trigger : true )
      error       : ( response )  =>
        if response.responseJSON?.errors?.children
          vent.trigger( 'liveSupport:settings:showErrors', response.responseJSON.errors.children )
        else
          vent.trigger( 'layout:error:show', response )
        vent.trigger( 'layout:loading:toggle', false )
    )

  _restoreWidget : ->
    @model.restore()
    app = apps( 'liveSupport' )
    route = if app.data.widgets.length then 'list' else 'start'
    app.router.navigate( route, trigger : true )


class LiveSupportWidgetModel extends Backbone.Model
  defaults :
    visible_type        : null
    message             : null
    name                : null
    welcome_title       : 'Welcome to Store'
    welcome_description : 'Your welcome message here'
    logo                : null
    logo_empty          : '/images/default/no-business.png'
    schedule            : null
    country             : null
    visitor_navigation  : null
    device              : null
    stores              : new Backbone.Collection

  url : -> Routing.generate( 'rest_api_v1_live_support_get', id : @id, slug : apps( 'liveSupport' ).settings.slug )

  backup : ->
# cloning such a way because _.clone can't do deep copy
    @_initialAttributes = JSON.parse( JSON.stringify( _.omit( @attributes, 'stores', 'logo_file' ) ) )

  restore : ->
    @set( @_initialAttributes )

  toggle : ( state, slug ) ->
    $.ajax(
      url     : Routing.generate( 'rest_api_v1_live_support_switch_status', id : @id, slug : slug )
      method  : 'patch'
      data    :
        enabled : state
    )


class LiveSupportWidgetCollection extends Backbone.Collection
  model : LiveSupportWidgetModel

  url : ->
    return Routing.generate( 'rest_api_v1_live_support_list',
      slug : apps( 'liveSupport' ).settings.slug
    )

  setCurrent : ( id ) -> @map( ( model ) -> model.set( 'current', "#{model.id}" is "#{id}" ) )

  getCurrent : -> @findWhere( current : true )


class LiveSupportHeaderView extends Marionette.ItemView
  template  : '#live-support__header-template'
  tagName   : 'header'
  className : 'main-header modal-header clearfix'


class LiveSupportWidgetItemView extends Marionette.ItemView
  template  : '#live-support__widget-item-template'
  className : 'row live-support__widget-item'
  ui        :
    'toggle' : '[data-action=toggle]'
    'remove' : '[data-action=remove]'
  events    :
    'click @ui.toggle' : '_toggle'
    'click @ui.remove' : '_confirmRemove'

  _confirmRemove : ( event ) ->
    event.preventDefault()
    event.stopPropagation()
    vent.trigger( 'layout:action:confirm', @_remove.bind( @ ), "Remove widget?" )

  _remove : ( event ) -> @model.destroy()

  _toggle : ( event ) -> @model.toggle( event.currentTarget.checked, apps( 'liveSupport' ).settings.slug )


class LiveSupportWidgetCollectionView extends Marionette.CollectionView
  className : 'col-sm-12 col-xs-12 live-support__widget-collection'
  childView : LiveSupportWidgetItemView


class LiveSupportListView extends Marionette.LayoutView
  template : '#live-support__widgets-template'
  regions  :
    header  : '[data-region=header]'
    widgets : '[data-region=widgets]'

  onBeforeShow : ->
    @showChildView( 'header',  new LiveSupportHeaderView( type : 'main' ) )
    @showChildView( 'widgets', new LiveSupportWidgetCollectionView( collection : @collection ) )


class LiveSupportStartView extends Marionette.LayoutView
  template : '#live-support__start-template'
  regions  :
    header : '[data-region=header]'
  ui       :
    start : '[data-action=start]'
  events   :
    'click @ui.start' : '_start'

  onBeforeShow : -> @showChildView( 'header', new LiveSupportHeaderView( type : 'main' ) )

  _start : ->
    app = apps( 'liveSupport' )
    route = if app.data.widgets.length then 'list' else 'create'
    app.router.navigate( route, trigger : true )


class LiveSupportController extends Marionette.Object
  start : ->
    @_initializeData( 'widgets' )
      .then( ->
      vent.trigger( 'layout:view:toggle', new LiveSupportStartView )
      vent.trigger( 'layout:loading:toggle', false )
    )

  list : ->
    @_initializeData( 'widgets' )
      .then( ->
      app = apps( 'liveSupport' )
      unless app.data.widgets.length
        return app.router.navigate( 'start', trigger : true )
      view = new LiveSupportListView( collection : apps( 'liveSupport' ).data.widgets )
      vent.trigger( 'layout:view:toggle', view )
      vent.trigger( 'layout:loading:toggle', false )
    )

  create : ->
    @_initializeData( 'form' )
      .then( ->
      vent.trigger( 'layout:view:toggle', new LiveSupportConfigView( model : new LiveSupportWidgetModel ) )
      vent.trigger( 'layout:loading:toggle', false )
    )

  settings : ( widgetId, callback ) -> @_config( widgetId, 'settings', callback )

  integration : ( widgetId ) -> @_config( widgetId, 'integration' )

  _config : ( widgetId, navigationId ) ->
    @_initializeData( 'widgets', 'form' )
      .then( => @_prepareCurrentWidget( widgetId ) )
      .then( => @_prepareCurrentWidgetStores( widgetId ) )
      .then( ->
      appData = apps( 'liveSupport' ).data
      appData.navigation.setCurrent( navigationId )
      vent.trigger( 'layout:view:toggle', new LiveSupportConfigView( model : appData.widgets.getCurrent() ) )
      vent.trigger( 'layout:loading:toggle', false )
    )

  _initializeData : ( modelKeys... ) ->
    promises = for key in modelKeys
      promise = new Promise( ( resolve, reject ) ->
        model = apps( 'liveSupport' ).data[key]
        if model instanceof Backbone.Collection and model.length
          return resolve()
        if model instanceof Backbone.Model and not _.isEmpty( model.attributes )
          return resolve()
        model.fetch(
          beforeSend : -> vent.trigger( 'layout:loading:toggle', true )
          success    : resolve
          error      : reject
        )
      )
    return Promise.all( promises )

  _prepareCurrentWidget : ( widgetId ) ->
    return new Promise( ( resolve, reject ) ->
      widgets = apps( 'liveSupport' ).data.widgets
      currentWidget = widgets.get( widgetId )
      widgets.setCurrent( widgetId )
      if currentWidget.syncDone
        return resolve()
      currentWidget.fetch(
        beforeSend : -> vent.trigger( 'layout:loading:toggle', true )
        success : ->
          currentWidget.syncDone = true
          resolve()
        error : reject
      )
    )

  _prepareCurrentWidgetStores : ( widgetId ) ->
    return new Promise( ( resolve, reject ) ->
      stores = apps( 'liveSupport' ).data.widgets.get( widgetId ).get( 'stores' )
      if stores.length
        return resolve()
      stores.fetch(
        url        : Routing.generate( 'rest_api_v1_live_support_channel_sets_with_possible_live_support',
          id   : widgetId
          slug : apps( 'liveSupport' ).settings.slug
        )
        beforeSend : -> vent.trigger( 'layout:loading:toggle', true )
        success    : resolve
        error      : reject
      )
    )


# Live support router
class LiveSupportRouter extends Marionette.AppRouter
  controller : new LiveSupportController
  appRoutes  :
    ''                : 'list'
    'start'           : 'start'
    'list'            : 'list'
    'create'          : 'create'
    'settings/:id'    : 'settings'
    'integration/:id' : 'integration'


# Live support app
class LiveSupportApp extends Marionette.Application
  settings : $( '[data-settings]' ).data( 'settings' )
  router   : new LiveSupportRouter
  data     :
    widgets    : new LiveSupportWidgetCollection
    form       : new LiveSupportFormModel
    navigation : new LiveSupportNavigationCollection
    logoFile   : null

  onStart : -> Backbone.history.start() unless Backbone.History.started

# Starting live support app
$ -> apps( 'liveSupport', new LiveSupportApp ).start()
