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
    @readOnly = @annotator.options.readOnly
    this

  _setupComment: (annotation) ->
    self = this
    textString = Util.escape(annotation.text)
    userTitle = annotation.user.name or annotation.user
    userString = Util.userString(annotation.user)
    published = new Date(annotation.updated or annotation.created)
    dateString = Util.dateString(published)

    div = $('''
      <div class="annotator-erratum annotator-item" data-id="''' + annotation.id + '''">
        <span class="annotator-controls">
          <button title="Delete" class="annotator-delete">Delete</button>
        </span>
        <div class="erratum-quote">''' + annotation.quote + '''</div>
        <dl class="erratum-comment">
          <dt class="replytext">''' + textString + '''</dt>
          <dd class="annotator-date" title="''' + published.toDateString() + '''">''' + dateString + '''</dd>
          <dd class="annotator-user" title="''' + userTitle + '''">''' + userString + '''</dd>
        </dl>
      </div>
    ''')

    div.find('.annotator-delete').click( (evt) ->
      self.annotator.onDeleteAnnotation(annotation)
    )

    erratum = div.find('.erratum-comment').hide()
    replies = annotation.replies or []
    for reply in replies
      textString = Util.escape(reply.reply)
      userTitle = reply.user.name or reply.user
      userString = Util.userString(reply.user)
      published = new Date(reply.updated or reply.created)
      dateString = Util.dateString(published)
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
      quote.attr("data-tooltip", "Can't find the original text the comment was referring to")
      quote.data("tooltip", "Can't find the original text the comment was referring to")

    existing = @element.find('[data-id="' + annotation.id + '"]')
    if existing.length
      @annotationDeleted annotation

    if @readOnly
      div.find('.annotator-controls').remove()

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
        data = {annotation: annotation, element: comment}
        self.publish('beforeClick', data)
        self.element.find('.erratum-comment').slideUp('fast')
        comment.find('.erratum-comment').slideDown('fast')
        self.publish('afterClick', data)
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
