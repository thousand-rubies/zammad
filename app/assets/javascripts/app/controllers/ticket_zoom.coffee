class App.TicketZoom extends App.Controller
  elements:
    '.main':             'main'
    '.ticketZoom':       'ticketZoom'
    '.scrollPageHeader': 'scrollPageHeader'

  events:
    'click .js-submit':   'submit'
    'click .js-bookmark': 'bookmark'
    'click .js-reset':    'reset'
    'click .main':        'muteTask'

  constructor: (params) ->
    super

    # check authentication
    if !@authenticate()
      App.TaskManager.remove(@task_key)
      return

    @formMeta     = undefined
    @ticket_id    = params.ticket_id
    @article_id   = params.article_id
    @sidebarState = {}

    # if we are in init task startup, ignore overview_id
    if !params.init
      @overview_id = params.overview_id
    else
      @overview_id = false

    @key = "ticket::#{@ticket_id}"
    cache = App.SessionStorage.get(@key)
    if cache
      @load(cache)

    # check if ticket has beed updated every 30 min
    update = =>
      @fetch()
    @interval(update, 1800000, 'pull_check')

    # fetch new data if triggered
    @bind('Ticket:update Ticket:touch', (data) =>

      # check if current ticket has changed
      return if data.id.toString() isnt @ticket_id.toString()

      # check if we already have the request queued
      #@log 'notice', 'TRY', @ticket_id, new Date(data.updated_at), new Date(@ticketUpdatedAtLastCall)
      update = =>
        @fetch()
      if !@ticketUpdatedAtLastCall || ( new Date(data.updated_at).toString() isnt new Date(@ticketUpdatedAtLastCall).toString() )
        @delay(update, 1200, "ticket-zoom-#{@ticket_id}")
    )

    # rerender view, e. g. on langauge change
    @bind('ui:rerender', =>
      @fetch(true)
    )

  fetchStart: (force) =>
    if !force && @fetchIsRunning
      @fetchIsRunningAgain = true
      return false
    if force
      @fetchIsRunningAgain = false
    @fetchIsRunning = true
    true

  fetchDone: =>
    @fetchIsRunning = false
    if @fetchIsRunningAgain
      @fetchIsRunningAgain = false
      @fetch()

  fetch: (force) =>
    return if !@Session.get()
    return if !@fetchStart(force)

    # get data
    @ajax(
      id:    "ticket_zoom_#{@ticket_id}"
      type:  'GET'
      url:   "#{@apiPath}/tickets/#{@ticket_id}?all=true"
      processData: true
      success: (data, status, xhr) =>
        @fetchDone()

        # check if ticket has changed
        newTicketRaw = data.assets.Ticket[@ticket_id]
        if @ticketUpdatedAtLastCall && !force

          # return if ticket hasnt changed
          return if @ticketUpdatedAtLastCall is newTicketRaw.updated_at

          # notify if ticket changed not by my self
          if newTicketRaw.updated_by_id isnt @Session.get('id')
            App.TaskManager.notify(@task_key)

        # remember current data
        @ticketUpdatedAtLastCall = newTicketRaw.updated_at

        @load(data)
        App.SessionStorage.set(@key, data)

        if !@doNotLog
          @doNotLog = 1
          @recentView('Ticket', @ticket_id)

      error: (xhr) =>
        @fetchDone()

        statusText = xhr.statusText
        status     = xhr.status
        detail     = xhr.responseText

        # ignore if request is aborted
        return if statusText is 'abort'

        @renderDone = false

        # if ticket is already loaded, ignore status "0" - network issues e. g. temp. not connection
        if @ticketUpdatedAtLastCall && status is 0
          console.log('network issues e. g. temp. not connection', status, statusText, detail)
          return

        # show error message
        if status is 401 || statusText is 'Unauthorized'
          @taskHead      = '» ' + App.i18n.translateInline('Unauthorized') + ' «'
          @taskIconClass = 'diagonal-cross'
          @renderScreenUnauthorized(objectName: 'Ticket')
        else if status is 404 || statusText is 'Not Found'
          @taskHead      = '» ' + App.i18n.translateInline('Not Found') + ' «'
          @taskIconClass = 'diagonal-cross'
          @renderScreenNotFound(objectName: 'Ticket')
        else
          @taskHead      = '» ' + App.i18n.translateInline('Error') + ' «'
          @taskIconClass = 'diagonal-cross'

          if !detail
            detail = 'General communication error, maybe internet is not available!'
          @renderScreenError(
            status:     status
            detail:     detail
            objectName: 'Ticket'
          )
    )

  load: (data) =>

    # remember article ids
    @ticket_article_ids = data.ticket_article_ids

    # remember link
    @links = data.links

    # remember tags
    @tags = data.tags

    # get edit form attributes
    @formMeta = data.form_meta

    # load assets
    App.Collection.loadAssets(data.assets)

    # get data
    @ticket = App.Ticket.fullLocal(@ticket_id)
    @ticket.article = undefined

    # render page
    @render()

  meta: =>

    # default attributes
    meta =
      url: @url()
      id:  @ticket_id

    # set icon and tilte if defined
    if @taskIconClass
      meta.iconClass = @taskIconClass
    if @taskHead
      meta.head = @taskHead

    # set icon and title based on ticket
    if @ticket_id && App.Ticket.exists(@ticket_id)
      ticket         = App.Ticket.find(@ticket_id)
      meta.head      = ticket.title
      meta.title     = "##{ticket.number} - #{ticket.title}"
      meta.class     = "task-state-#{ ticket.getState() }"
      meta.type      = 'task'
      meta.iconTitle = ticket.iconTitle()
      meta.iconClass = ticket.iconClass()
    meta

  url: =>
    "#ticket/zoom/#{@ticket_id}"

  show: (params) =>
    @navupdate(url: '#', type: 'menu')

    # set all notifications to seen
    App.OnlineNotification.seen('Ticket', @ticket_id)

    # if controller is executed twice, go to latest article (e. g. click on notification)
    if @activeState
      @scrollToBottom()
      return
    @activeState = true

    # if ticket is shown the first time
    if !@shown
      @shown = true

      # trigger shown to article
      App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })

      # scroll to end of page
      @scrollToBottom()

    # observe content header position
    @positionPageHeaderStart()

    # start autosave
    @autosaveStart()

  hide: =>
    @activeState = false

    # stop observing content header position
    @positionPageHeaderStop()

    # stop autosave
    @autosaveStop()

  changed: =>
    return false if !@ticket
    currentParams = @formCurrent()
    currentStore = @currentStore()
    modelDiff = @formDiff(currentParams, currentStore)
    return false if !modelDiff || _.isEmpty(modelDiff)
    return false if _.isEmpty(modelDiff.ticket) && _.isEmpty(modelDiff.article)
    return true

  release: =>
    @autosaveStop()
    @positionPageHeaderStop()

  muteTask: =>
    App.TaskManager.mute(@task_key)

  positionPageHeaderStart: =>

    # init header update needed for safari, scroll event is fired
    @positionPageHeaderUpdate()

    # scroll is also fired on window resize, if element scroll is changed
    @main.bind(
      'scroll'
      @positionPageHeaderUpdate
    )

  positionPageHeaderStop: =>
    @main.unbind('scroll', @positionPageHeaderUpdate)

  @scrollHeaderPos: undefined

  positionPageHeaderUpdate: =>
    headerHeight     = @scrollPageHeader.outerHeight()
    mainScrollHeigth = @main.prop('scrollHeight')
    mainHeigth       = @main.height()

    scroll = @main.scrollTop()

    # if page header is not possible to use - mainScrollHeigth to low - hide page header
    if not mainScrollHeigth > mainHeigth + headerHeight
      @scrollPageHeader.css('transform', "translateY(#{-headerHeight}px)")

    if scroll > headerHeight
      scroll = headerHeight

    if scroll is @scrollHeaderPos
      return

    # translateY: headerHeight .. 0
    @scrollPageHeader.css('transform', "translateY(#{scroll - headerHeight}px)")

    @scrollHeaderPos = scroll

  render: =>

    # update taskbar with new meta data
    App.TaskManager.touch(@task_key)

    if !@renderDone
      @renderDone = true
      @autosaveLast = {}
      elLocal = $(App.view('ticket_zoom')
        ticket:         @ticket
        nav:            @nav
        isCustomer:     @isRole('Customer')
        scrollbarWidth: App.Utils.getScrollBarWidth()
      )

      new App.TicketZoomOverviewNavigator(
        el:          elLocal.find('.overview-navigator')
        ticket_id:   @ticket_id
        overview_id: @overview_id
      )

      new App.TicketZoomTitle(
        object_id:   @ticket_id
        overview_id: @overview_id
        el:          elLocal.find('.ticket-title')
        task_key:    @task_key
      )

      new App.TicketZoomMeta(
        object_id: @ticket_id
        el:        elLocal.find('.ticket-meta')
      )

      new App.TicketZoomAttributeBar(
        el:          elLocal.find('.js-attributeBar')
        overview_id: @overview_id
        callback:    @submit
        task_key:    @task_key
      )

      @form_id = App.ControllerForm.formId()

      @articleNew = new App.TicketZoomArticleNew(
        ticket:    @ticket
        ticket_id: @ticket_id
        el:        elLocal.find('.article-new')
        formMeta:  @formMeta
        form_id:   @form_id
        defaults:  @taskGet('article')
        task_key:  @task_key
        ui:        @
      )

      @highligher = new App.TicketZoomHighlighter(
        el:        elLocal.find('.highlighter')
        ticket_id: @ticket_id
      )

      @articleView = new App.TicketZoomArticleView(
        ticket:             @ticket
        el:                 elLocal.find('.ticket-article')
        ui:                 @
        highligher:         @highligher
        ticket_article_ids: @ticket_article_ids
      )

      new App.TicketCustomerAvatar(
        object_id: @ticket_id
        el:        elLocal.find('.ticketZoom-header')
      )

      @sidebar = new App.TicketZoomSidebar(
        el:           elLocal
        sidebarState: @sidebarState
        object_id:    @ticket_id
        model:        'Ticket'
        taskGet:      @taskGet
        task_key:     @task_key
        formMeta:     @formMeta
        markForm:     @markForm
        tags:         @tags
        links:        @links
      )

    # render init content
    if elLocal
      @html elLocal

    # show article
    else
      @articleView.execute(
        ticket_article_ids: @ticket_article_ids
      )

    if @sidebar

      # update tags
      if @sidebar.tagWidget
        @sidebar.tagWidget.reload(@tags)

      # update links
      if @sidebar.linkWidget
        @sidebar.linkWidget.reload(@links)

    # scroll to article if given
    if @article_id && document.getElementById("article-#{@article_id}")
      offset = document.getElementById("article-#{@article_id}").offsetTop
      offset = offset - 45
      scrollTo = ->
        @scrollTo(0, offset)
      @delay(scrollTo, 100, false)

    if @shown

      # scroll to end if new article has been added
      if !@last_ticket_article_ids || !_.isEqual(_.sortBy(@last_ticket_article_ids), _.sortBy(@ticket_article_ids))
        @last_ticket_article_ids = @ticket_article_ids
        @scrollToBottom()
        @positionPageHeaderUpdate()

    return if @initDone
    @initDone = true

    # if shown was before init rendering, start actions again
    return if !@shown
    @positionPageHeaderStart()
    App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })

  scrollToBottom: =>

    # because of .ticketZoom { min-: 101% } (force to show scrollbar to set layout correctly),
    # we need to check if we need to really scroll bottom, in case of content isn't really 100%,
    # just return (otherwise just a part of movable header is shown down)
    realContentHeight = 0
    realContentHeight += @$('.ticketZoom-controls').height()
    realContentHeight += @$('.ticketZoom-header').height()
    realContentHeight += @$('.ticket-article').height()
    realContentHeight += @$('.article-new').height()
    viewableContentHeight = @$('.main').height()
    return if viewableContentHeight > realContentHeight
    @main.scrollTop( @main.prop('scrollHeight') )

  autosaveStop: =>
    @clearDelay('ticket-zoom-form-update')
    @autosaveLast = {}
    @el.off('change.local blur.local keyup.local paste.local input.local')

  autosaveStart: =>
    @el.on('change.local blur.local keyup.local paste.local input.local', 'form, .js-textarea', (e) =>
      @delay(@markForm, 250, 'ticket-zoom-form-update')
    )
    @delay(@markForm, 800, 'ticket-zoom-form-update')

  markForm: (force) =>
    if !@autosaveLast
      @autosaveLast = @taskGet()
    return if !@ticket
    currentParams = @formCurrent()

    # check changed between last autosave
    sameAsLastSave = _.isEqual(currentParams, @autosaveLast)
    return if !force && sameAsLastSave
    @autosaveLast = clone(currentParams)

    # update changes in ui
    currentStore = @currentStore()
    modelDiff = @formDiff(currentParams, currentStore)
    @markFormDiff(modelDiff)
    @taskUpdateAll(modelDiff)

  currentStore: =>
    return if !@ticket
    currentStoreTicket = @ticket.attributes()
    delete currentStoreTicket.article
    currentStore  =
      ticket:  currentStoreTicket
      article:
        to:          ''
        cc:          ''
        type:        'note'
        body:        ''
        internal:    ''
        in_reply_to: ''
    currentStore

  formCurrent: =>
    currentParams =
      ticket:  @formParam(@el.find('.edit'))
      article: @formParam(@el.find('.article-add'))

    # add attachments if exist
    attachmentCount = @$('.article-add .textBubble .attachments .attachment').length
    if attachmentCount > 0
      currentParams.article.attachments = true
    else
      delete currentParams.article.attachments

    # remove not needed attributes
    delete currentParams.article.form_id
    currentParams

  formDiff: (currentParams, currentStore) ->

    # do not compare null or undefined value
    if currentStore.ticket
      for key, value of currentStore.ticket
        if value is null || value is undefined
          currentStore.ticket[key] = ''
    if currentParams.ticket
      for key, value of currentParams.ticket
        if value is null || value is undefined
          currentParams.ticket[key] = ''

    # get diff of model
    modelDiff =
      ticket:  App.Utils.formDiff(currentParams.ticket, currentStore.ticket)
      article: App.Utils.formDiff(currentParams.article, currentStore.article)

    modelDiff

  markFormDiff: (diff = {}) =>
    ticketForm    = @$('.edit')
    ticketSidebar = @$('.tabsSidebar-tab[data-tab="ticket"]')
    articleForm   = @$('.article-add')
    resetButton   = @$('.js-reset')

    params         = {}
    params.ticket  = @formParam(ticketForm)
    params.article = @formParam(articleForm)

    # clear all changes
    if _.isEmpty(diff.ticket) && _.isEmpty(diff.article)
      ticketSidebar.removeClass('is-changed')
      ticketForm.removeClass('form-changed')
      ticketForm.find('.form-group').removeClass('is-changed')
      resetButton.addClass('hide')

    # set changes
    else
      ticketForm.addClass('form-changed')
      if !_.isEmpty(diff.ticket)
        ticketSidebar.addClass('is-changed')
      else
        ticketSidebar.removeClass('is-changed')
      for currentKey, currentValue of params.ticket
        element = @$('.edit [name="' + currentKey + '"]').parents('.form-group')
        if !element.get(0)
          element = @$('.edit [data-name="' + currentKey + '"]').parents('.form-group')
        if currentKey of diff.ticket
          if !element.hasClass('is-changed')
            element.addClass('is-changed')
        else
          if element.hasClass('is-changed')
            element.removeClass('is-changed')

      resetButton.removeClass('hide')

  submit: (e, macro = {}) =>
    e.stopPropagation()
    e.preventDefault()

    # disable form
    @formDisable(e)

    # validate new article
    if !@articleNew.validate()
      @formEnable(e)
      return

    taskAction = @$('.js-secondaryActionButtonLabel').data('type')

    ticketParams = @formParam( @$('.edit') )

    # validate ticket
    ticket = App.Ticket.find(@ticket_id)

    # reset article - should not be resubmited on next ticket update
    ticket.article = undefined

    # update ticket attributes
    for key, value of ticketParams
      ticket[key] = value

    # apply macro
    for key, content of macro
      attributes = key.split('.')
      if attributes[0] is 'ticket'

        # apply tag changes
        if attributes[1] is 'tags'
          if @sidebar && @sidebar.edit && @sidebar.edit.tagWidget
            tags = content.value.split(',')
            for tag in tags
              if content.operator is 'remove'
                @sidebar.edit.tagWidget.remove(tag)
              else
                @sidebar.edit.tagWidget.add(tag)

        # apply user changes
        else if attributes[1] is 'owner_id'
          if content.pre_condition is 'current_user.id'
            ticket[attributes[1]] = App.Session.get('id')
          else
            ticket[attributes[1]] = content.value

        # apply direct value changes
        else
          ticket[attributes[1]] = content.value

    # set defaults
    if !@isRole('Customer')
      if !ticket['owner_id']
        ticket['owner_id'] = 1

    # check if title exists
    if !ticket['title']
      alert( App.i18n.translateContent('Title needed') )
      @formEnable(e)
      return

    # submit ticket & article
    @log 'notice', 'update ticket', ticket

    # stop autosave
    @autosaveStop()

    # validate ticket
    errors = ticket.validate(
      screen: 'edit'
    )
    if errors
      @log 'error', 'update', errors
      @formValidate(
        form:   @$('.edit')
        errors: errors
        screen: 'edit'
      )
      @formEnable(e)
      @autosaveStart()
      return

    console.log('ticket validateion ok')

    articleParams = @articleNew.params()
    if articleParams && articleParams.body
      article = new App.TicketArticle
      article.load(articleParams)
      errors = article.validate()
      if errors
        @log 'error', 'update article', errors
        @formValidate(
          form:   @$('.article-add')
          errors: errors
          screen: 'edit'
        )
        @formEnable(e)
        @autosaveStart()
        return

      ticket.article = article

    # submit changes
    ticket.save(
      done: (r) =>

        # reset article - should not be resubmited on next ticket update
        ticket.article = undefined

        # reset form after save
        @reset()

        if taskAction is 'closeNextInOverview'
          if @overview_id
            current_position = 0
            overview = App.Overview.find(@overview_id)
            list = App.OverviewListCollection.get(overview.link)
            for ticket in list.tickets
              current_position += 1
              if ticket.id is @ticket_id
                next = list.tickets[current_position]
                if next
                  # close task
                  App.TaskManager.remove(@task_key)

                  # open task via task manager to get overview information
                  App.TaskManager.execute(
                    key:        'Ticket-' + next.id
                    controller: 'TicketZoom'
                    params:
                      ticket_id:   next.id
                      overview_id: @overview_id
                    show:       true
                  )
                  @navigate "ticket/zoom/#{next.id}"
                  return

          # fallback, close task
          taskAction = 'closeTab'

        if taskAction is 'closeTab'
          App.TaskManager.remove(@task_key)
          nextTaskUrl = App.TaskManager.nextTaskUrl()
          if nextTaskUrl
            @navigate nextTaskUrl
            return

          @navigate '#'
          return

        @autosaveStart()
        @muteTask()
        @fetch()

        # enable form
        @formEnable(e)

        App.Event.trigger('overview:fetch')
    )

  bookmark: (e) ->
    $(e.currentTarget).find('.bookmark.icon').toggleClass('filled')

  reset: (e) =>
    if e
      e.preventDefault()

    # reset task
    @taskReset()

    # reset/delete uploaded attachments
    App.Ajax.request(
      type:  'DELETE'
      url:   App.Config.get('api_path') + '/ticket_attachment_upload'
      data:  JSON.stringify(form_id: @form_id)
      processData: false
    )

    # hide reset button
    @$('.js-reset').addClass('hide')

    # reset edit ticket / reset new article
    App.Event.trigger('ui::ticket::taskReset', { ticket_id: @ticket_id })

    # remove change flag on tab
    @$('.tabsSidebar-tab[data-tab="ticket"]').removeClass('is-changed')

  taskGet: (area) =>
    return {} if !App.TaskManager.get(@task_key)
    @localTaskData = App.TaskManager.get(@task_key).state || {}
    if area
      if !@localTaskData[area]
        @localTaskData[area] = {}
      return @localTaskData[area]
    if !@localTaskData
      @localTaskData = {}
    @localTaskData

  taskUpdate: (area, data) =>
    @localTaskData[area] = data
    App.TaskManager.update(@task_key, { 'state': @localTaskData })

  taskUpdateAll: (data) =>
    @localTaskData = data
    App.TaskManager.update(@task_key, { 'state': @localTaskData })

  # reset task state
  taskReset: =>
    @localTaskData =
      ticket:  {}
      article: {}
    App.TaskManager.update(@task_key, { 'state': @localTaskData })

class TicketZoomRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      ticket_id:  params.ticket_id
      article_id: params.article_id
      nav:        params.nav
      shown:      true

    App.TaskManager.execute(
      key:        "Ticket-#{@ticket_id}"
      controller: 'TicketZoom'
      params:     clean_params
      show:       true
    )

App.Config.set('ticket/zoom/:ticket_id', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id/nav/:nav', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id/:article_id', TicketZoomRouter, 'Routes')
