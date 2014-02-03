class Annotator.Plugin.Errata extends Annotator.Plugin
  events:
    'afterAnnotationsLoaded': 'annotationsLoaded'
    'afterAnnotationCreated': 'annotationCreated'
    'afterAnnotationDeleted': 'annotationDeleted'
    'afterAnnotationUpdated': 'annotationUpdated'
    'rangeNormalizeFail': 'rangeNormalizeFail'

  options:
    element: '.annotator-errata'

  constructor: (element, options) ->
    super

  pluginInit: ->
    return unless Annotator.supported()

    @errata = []
    @elements = $(@options.element)
    for item in @elements
      erratum = new Annotator.Erratum(item, {annotator: @annotator})
      @errata.push erratum

  annotationsLoaded: (annotations) ->
    for erratum in @errata
      erratum.annotationsLoaded(annotations)

  annotationCreated: (annotation) ->
    for erratum in @errata
      erratum.annotationCreated(annotation)

  annotationDeleted: (annotation) ->
    for erratum in @errata
      erratum.annotationDeleted(annotation)

  annotationUpdated: (annotation) ->
    for erratum in @errata
      erratum.annotationUpdated(annotation)

  rangeNormalizeFail: (annotation) ->
    for erratum in @errata
      erratum.rangeNormalizeFail(annotation)

class Annotator.Erratum extends Delegator
  options:
    annotator: null

  missing: {}

  constructor: (element, options) ->
    super
    @annotator = @options.annotator
    @readOnly = @annotator.options.readOnly
    @_setupSections()
    this

  _setupSections: () ->
    @element.empty()
    @element.addClass('eea-accordion-panels collapsed-by-default non-exclusive')

    @pendingCount = 0
    @pending = $('''
      <div class="annotator-erratum-section annotator-erratum-pending eea-accordion-panel">
        <h2>Active comments (<span class="count">''' + @pendingCount + '''</span>)<span class="eea-icon eea-icon-right"></span></h2>
        <div class="pane"></div>
      </div>
    ''').appendTo(@element)

    @closedCount = 0
    @closed = $('''
      <div class="annotator-erratum-section annotator-erratum-closed eea-accordion-panel">
        <h2>Closed comments (<span class="count">''' + @closedCount + '''</span>)<span class="eea-icon eea-icon-right"></span></h2>
        <div class="pane"></div>
      </div>
    ''').appendTo(@element)

  _setupComment: (annotation) ->
    self = this
    textString = Util.escape(annotation.text)
    userTitle = annotation.user.name or annotation.user
    userString = Util.userString(annotation.user)
    isoDate = annotation.created
    if not isoDate.endsWith('Z')
      isoDate += 'Z'
    published = new Date(isoDate)
    dateString = Util.easyDate(published)

    div = $('''
      <div class="annotator-erratum annotator-item" data-id="''' + annotation.id + '''">
        <span class="annotator-controls">
          <button title="Close" class="annotator-delete">
            <span class="eea-icon eea-icon-square-o"></span>
          </button>
        </span>
        <div class="erratum-quote">
          <span class="erratum-header-date" title="''' + published.toDateString() + '''">''' + dateString + '''</span>
          <span class="erratum-header-user" title="''' + userTitle + '''">''' + userString + '''</span>
          <span class="erratum-header-text">''' + textString + '''</span>
        </div>
        <dl class="erratum-comment">
          <dt class="replyquote">''' + annotation.quote + '''</dt>
        </dl>
      </div>
    ''')

    div.find('.annotator-delete').click( (evt) ->
      self.annotator.onDeleteAnnotation(annotation)
    )

    erratum = div.find('.erratum-comment').hide()
    replies = annotation.replies or []
    if replies.length
      $('<dt class="erratum-header-replies">Replies</dt>').appendTo(erratum)

    for reply in replies
      textString = Util.escape(reply.reply)
      userTitle = reply.user.name or reply.user
      userString = Util.userString(reply.user)
      isoDate = reply.updated or reply.created
      if not isoDate.endsWith('Z')
        isoDate += 'Z'
      published = new Date(isoDate)
      # dateString = Util.dateString(published)
      dateString = Util.easyDate(published)
      comment = $('''
        <dt class="replytext">''' + textString + '''</dt>
        <dd class="annotator-date" title="''' + published.toDateString() + '''">''' + dateString + '''</dd>
        <dd class="annotator-user" title="''' + userTitle + '''">''' + userString + '''</dd>
      ''')
      comment.appendTo(erratum)

    missing = @missing[annotation.id]
    if missing
      div.addClass('missing')
      quote = div.find('.erratum-comment')
      quote.attr("data-tooltip", "Can't find the text the comment was referring to")
      quote.data("tooltip", "Can't find the text the comment was referring to")

    if @readOnly
      div.find('.annotator-controls').remove()
    else if not annotation.deleted
      replybox = $('''<div class='replybox'><textarea class="replyentry-errata" placeholder="Reply..."></textarea>''')
      replybox.appendTo(erratum)

      textarea = replybox.find('.replyentry-errata')
      textarea.bind('click', (evt) ->
        self.processKeypress(evt, annotation)
      )
      textarea.bind('keydown', (evt) ->
        self.processKeypress(evt, annotation)
      )

    icon = div.find('.eea-icon-square-o')
    if annotation.deleted
      where = @closed.find('.pane')

      icon
        .removeClass('eea-icon-square-o')
        .addClass('eea-icon-check-square-o')
        .attr('title', 'Reopen')

      icon.bind({
        "click": () ->
            icon.removeClass('eea-icon-check-square-o')
            icon.addClass('eea-icon-square-o')
      })

    else
      where = @pending.find('.pane')

      icon.bind({
        "click": () ->
            icon.removeClass('eea-icon-square-o')
            icon.addClass('eea-icon-check-square-o')
      })

    div
      .data('id', annotation.id)
      .data('comment', annotation)
      .hide()
      .prependTo(where)
      .slideDown( ->
        self._reloadComment annotation
        self._updateCounters()
      )

    this

  processKeypress: (event, annotation) =>
    self = this
    item =  $(event.target).parent()

    controls = item.find('.annotator-reply-controls')
    if controls.length == 0
      reply_controls = $('''<div class="annotator-reply-controls">
          <a href="#save" class="annotator-reply-save">Save</a>
          <a href="#cancel" class="annotator-cancel">Cancel</a>
          </div>
          </div>
          ''')
      item.append(reply_controls)
      save_btn = reply_controls.find('.annotator-reply-save')
      cancel_btn = reply_controls.find('.annotator-cancel')
      if save_btn
        save_btn.bind('click', (evt) ->
          evt.preventDefault()
          self.onReplyEntryClick(evt, annotation)
        )
      if cancel_btn
        cancel_btn.bind('click', (evt) ->
          evt.preventDefault()
          self.onCancelReply(evt, annotation)
        )

    if event.keyCode is 13 and !event.shiftKey
      # If "return" was pressed without the shift key, we're done.
      @onReplyEntryClick(event, annotation)
    else if event.keyCode is 27
      @onCancelReply(event, annotation)

  onReplyEntryClick: (event, annotation) ->
    event.preventDefault()
    item =  $(event.target).parent().parent()
    textarea = item.find('.replyentry-errata')
    reply = textarea.val()

    if reply != ''
      replyObject = @getReplyObject()
      replyObject.reply = reply

      if !annotation.replies
        annotation.replies = []
      annotation.replies.push(replyObject)

      annotation = @annotator.updateAnnotation(annotation)

  onCancelReply: (event, annotation) ->
    event.preventDefault()
    item = $(event.target).parents('.erratum-comment')
    reply_controls = item.find('.annotator-reply-controls')
    reply_controls.parent().find('.replyentry-errata').val('')
    reply_controls.remove()

  getReplyObject: ->
    replyObject =
        reply: ""
        created: new Date().toJSON()

    replyObject

  _reloadComment: (annotation) ->
    comment = @element.find('[data-id="' + annotation.id + '"]')
    self = this
    collapsed_annotation = comment.parent().attr('collapsed-annotation')
    if collapsed_annotation is annotation.id
      comment.addClass('open');
      comment.find('.erratum-comment').slideDown('fast')
    erratum_quote = comment.find('.erratum-quote')
    erratum_quote.unbind()
    erratum_quote.bind({
      'click': (evt) ->
        data = {annotation: annotation, element: comment}
        self.publish('beforeClick', data)
        opened = comment.hasClass('open')
        self.element.find('.erratum-comment').slideUp('fast')
        self.element.find('.annotator-erratum').removeClass('open')
        self.element.find('.erratum-comment').trigger('commentUnCollapsed', [data])
        if not opened
          comment.addClass('open')
          comment.find('.erratum-comment').slideDown('fast')
          comment.find('.erratum-comment').trigger('commentCollapsed', [data])
        self.publish('afterClick', data)
    })
    this

  _updateCounters: () ->
    @closedCount = @closed.find('.annotator-erratum').length
    @pendingCount = @pending.find('.annotator-erratum').length
    @closed.find('h2 .count').text(@closedCount)
    @pending.find('h2 .count').text(@pendingCount)

  annotationsLoaded: (annotations) ->
    compare = (a, b) ->
      if a.updated < b.updated
        return -1
      else if a.updated > b.updated
        return 1
      return 0

    @_setupSections()
    for annotation in annotations.sort(compare)
      @_setupComment(annotation)

    @publish "annotationsErrataLoaded", [annotations]
    this

  annotationCreated: (annotation) ->
    @_setupComment(annotation)
    this

  annotationDeleted: (annotation) ->
    self = this
    pending = @pending.find('[data-id="' + annotation.id + '"]')
    if pending.length
      annotation.deleted = true

    closed = @closed.find('[data-id="' + annotation.id + '"]')
    if closed.length
      annotation.deleted = false

    comment = @element.find('[data-id="' + annotation.id + '"]')
    comment.slideUp( ->
      comment.remove()
      self._setupComment(annotation)
    )

    @annotator.setupAnnotation(annotation)
    this

  annotationUpdated: (annotation) ->
    self = this
    comment = @element.find('[data-id="' + annotation.id + '"]')
    if comment.length
      comment.slideUp( ->
        comment.parent().attr('collapsed-annotation', comment.attr('data-id'))
        comment.remove()
      )
    @_setupComment(annotation)
    this

  rangeNormalizeFail: (annotation) ->
    @missing[annotation.id] = annotation.quote
    this
