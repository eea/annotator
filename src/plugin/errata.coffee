class Annotator.Plugin.Errata extends Annotator.Plugin
  events:
    'annotationsLoaded': 'annotationsLoaded'
    'afterAnnotationCreated': 'annotationCreated'
    'annotationDeleted': 'annotationDeleted'
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
    this

  _setupComment: (annotation) ->
    text = Util.escape(annotation.text)
    user = annotation.user
    userString = if (user.name and user.id) then ('@' + user.id + ' (' + user.name + ')') else user

    div = $('''
      <div class="annotator-erratum annotator-item" data-id="''' + annotation.id + '''">
        <div class="erratum-quote">''' + annotation.quote + '''</div>
        <dl class="erratum-comment">
          <dt class="replytext">''' + text + '''</dt>
          <dd class="annotator-user">''' + userString + '''</dd>
        </dl>
      </div>
    ''')

    erratum = div.find('.erratum-comment').hide()
    replies = annotation.replies or []
    for reply in replies
      user = reply.user
      userString = if (user.name and user.id) then ('@' + user.id + ' (' + user.name + ')') else user
      text = Util.escape(reply.reply)
      comment = $('''
        <dt class="replytext">''' + text + '''</dt>
        <dd class="annotator-user">''' + userString + '''</dd>
      ''')
      comment.appendTo(erratum)

    missing = @missing[annotation.id]
    if missing
      div.addClass('missing')

    existing = @element.find('[data-id="' + annotation.id + '"]')
    if existing.length
      @annotationDeleted annotation

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
      'click': (evt) ->
        self.element.find('.erratum-comment').slideUp('fast')
        comment.find('.erratum-comment').slideDown('fast')
        if comment.parents('.fullscreen').length
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
    this

  annotationCreated: (annotation) ->
    @_setupComment(annotation)
    this

  annotationDeleted: (annotation) ->
    comment = @element.find('[data-id="' + annotation.id + '"]')
    comment.slideUp( -> comment.remove() )
    this

  annotationUpdated: (annotation) ->
    @_setupComment(annotation)
    this

  rangeNormalizeFail: (annotation) ->
    @missing[annotation.id] = annotation.quote
    this
