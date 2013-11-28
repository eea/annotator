class Annotator.Plugin.Errata extends Annotator.Plugin
  events:
    'annotationsLoaded': 'annotationsLoaded'
    'afterAnnotationCreated': 'annotationCreated'
    'annotationDeleted': 'annotationDeleted'
    'annotationUpdated': 'annotationUpdated'
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

  viewer: null

  viewerHideTimer: null

  missing: {}

  constructor: (element, options) ->
    super
    @annotator = @options.annotator
    this

  _setupViewer: ->
    self = this
    @viewer = new Annotator.Viewer(readOnly: @annotator.options.readOnly)
    @viewer.hide()
      .on("edit", @annotator.onEditAnnotation)
      .on("delete", @annotator.onDeleteAnnotation)
      #
      # Comment field
      #
      .addField({
        load: (field, annotation) ->
          $(field).html(Util.escape(annotation.text))
      })
      #
      # User field
      #
      .addField({
        load: (field, annotation) ->
          user = annotation.user
          userString = if (user.name and user.id) then ('@' + user.id + ' (' + user.name + ')') else user
          $(field).html(userString).addClass('annotator-user')
      })
      #
      # Replies field
      #
      .addField({
        load: (field, annotation) ->
          replies = annotation.replies or []

          if(replies.length)
            html = $('''
              <div style='padding:5px' class='annotator-replies-header'> <span> Replies </span></div>
              <div id="Replies">
                <li class="Replies"></li>
              </div>
            ''')

            where = html.find('.Replies')
            for reply in replies
              user = reply.user
              userString = if (user.name and user.id) then ('@' + user.id + ' (' + user.name + ')') else user
              div = $('''
                <div class="reply">
                  <div class="replytext">''' + reply.reply + '''</div>
                  <div class="annotator-user replyuser">''' + userString + '''</div>
                </div>
              ''').appendTo(where)

          $(field).html(html)
      })
      #
      # Append element and bind events
      #
      .element.appendTo(@element).bind({
        "mouseover": -> self.clearViewerHideTimer()
        "mouseout":  -> self.startViewerHideTimer()
      })
    this

  _setupComment: (annotation) ->
    div = $('''
      <div class="annotator-erratum" data-id="''' + annotation.id + '''">
        <div class="erratum-quote">''' + annotation.quote + '''</div>
      </div>
    ''')

    missing = @missing[annotation.id]
    if missing
      div.addClass('missing')

    self = this
    div
      .data('id', annotation.id)
      .data('comment', annotation)
      .hide()
      .prependTo(@element)
      .slideDown( -> self._reloadComment annotation )
    this


  _reloadComment: (annotation) ->
    comment = @element.find('[data-id="' + annotation.id + '"]')
    self = this
    comment.unbind()
    comment.bind({
      'mouseover': (evt) ->
        self.clearViewerHideTimer()
        data = comment.data('comment')
        location = Util.mousePosition(evt, this)
        self.viewer.element.css(location)
        self.viewer.load([data])
      'mouseout': (evt) ->
        self.startViewerHideTimer()
      'click': (evt) ->
        highlights = annotation.highlights
        if highlights and highlights.length
          scrollTop = $(highlights[0]).position().top
          $('html,body').animate({
            scrollTop: scrollTop
          })
    })
    this


  annotationsLoaded: (annotations) ->
    compare = (a, b) ->
      if a.updated < b.updated
        return -1
      else if a.updated > b.updated
        return 1
      return 0

    @element.empty()
    for annotation in annotations.sort(compare)
      @_setupComment(annotation)
    @_setupViewer()
    this

  annotationCreated: (annotation) ->
    @_setupComment(annotation)
    this

  annotationDeleted: (annotation) ->
    comment = @element.find('[data-id="' + annotation.id + '"]')
    comment.slideUp( -> comment.remove() )
    this

  annotationUpdated: (annotation) ->
    @_reloadComment(annotation)
    this

  rangeNormalizeFail: (annotation) ->
    @missing[annotation.id] = annotation.quote
    this

  clearViewerHideTimer: ->
    clearTimeout(@viewerHideTimer)
    @viewerHideTimer = false

  startViewerHideTimer: ->
    if not @viewerHideTimer
      @viewerHideTimer = setTimeout @viewer.hide, 250
