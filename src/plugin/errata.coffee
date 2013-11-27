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
      erratum = new Annotator.Erratum(item)
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
    readOnly: true

  viewer: null

  viewerHideTimer: null

  missing: []

  constructor: (element, options) ->
    super
    this._setupViewer()
    this

  _setupViewer: ->
    self = this
    @viewer = new Annotator.Viewer(readOnly: @options.readOnly)
    @viewer.hide()
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
      <div class="annotator-comment" data-id="''' + annotation.id + '''">
        <div class="comment-quote">''' + annotation.quote + '''</div>
      </div>
    ''')

    if annotation.id in @missing
      div.addClass('missing')

    self = this
    div
      .data('id', annotation.id)
      .data('comment', annotation)
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
    })
    this


  annotationsLoaded: (annotations) ->
    for annotation in annotations
      @_setupComment(annotation)
    this

  annotationCreated: (annotation) ->
    console.log(annotation)

  annotationDeleted: (annotation) ->
    console.log(annotation)

  annotationUpdated: (annotation) ->
    console.log(annotation)

  rangeNormalizeFail: (annotation) ->
    @missing.push(annotation.id)

  clearViewerHideTimer: ->
    clearTimeout(@viewerHideTimer)
    @viewerHideTimer = false

  startViewerHideTimer: ->
    if not @viewerHideTimer
      @viewerHideTimer = setTimeout @viewer.hide, 250
