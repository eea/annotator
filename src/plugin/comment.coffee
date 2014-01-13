class Annotator.Plugin.Comment extends Annotator.Plugin
  events:
    'annotationViewerShown' : 'addReplyButton'
    '.annotator-reply-save click': 'onReplyEntryClick'
    '.annotator-cancel click': 'hide'
    '.replyentry keydown' : 'processKeypress'
    '.replyentry click' : 'processKeypress'
    '.annotator-delete-reply click' : 'deleteReply'
  constructor: (element) ->
      super


  # Public: Initialises the plugin and adds custom fields to both the
  # annotator viewer and editor. The plugin also checks if the annotator is
  # supported by the current browser.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()

  #
  # Add a reply button to the viewer widget's controls span
  #
  addReplyButton: (viewer, annotations) ->
    listing = @annotator.element.find('.annotator-annotation.annotator-item')
    for item, idx in listing
      item = $(item)
      replies = annotations[idx].replies or []

      if replies.length > 0
        item.append('''<div class="annotator-replies"></div>''')

      if replies.length > 0
        replylist = @annotator.element.find('.annotator-replies')
        for reply in replies
          usertitle = reply.user.name or reply.user
          username = Util.userString(reply.user)
          published = new Date(reply.updated or reply.created)
          dateString = Util.dateString(published)
          div = '''<div class='reply'>'''
          if not @annotator.options.readOnly
              div += '''<span title="Delete" class='annotator-delete-reply eea-icon eea-icon-times'></span>'''
          div += '''
              <div class='replytext'>''' + reply.reply + '''</div>
              <div class='annotator-date' title="''' + published.toDateString() + '''">''' + dateString + '''</div>
              <div class='annotator-user replyuser' title="''' + usertitle + '''">''' + username + '''</div>
            </div>'''
          $(replylist[idx]).append(div)

      # Add the textarea
      if not @annotator.options.readOnly
        item.append('''<div class='replybox'><textarea class="replyentry" placeholder="Reply..."></textarea>''')

    viewer.checkOrientation()

  #
  # Handle the event when the submit button is clicked
  #
  onReplyEntryClick: (event) ->
    item =  $(event.target).parent().parent()
    textarea = item.find('.replyentry')
    reply = textarea.val()
    if reply != ''
      replyObject = @getReplyObject()
      replyObject.reply = reply

      item = $(event.target).parents('.annotator-annotation')
      new_annotation = item.data('annotation')
      if !new_annotation.replies
        new_annotation.replies = []
      new_annotation.replies.push(replyObject)

      new_annotation = @annotator.updateAnnotation(new_annotation)

      # hide the viewer
      @annotator.viewer.hide()


  deleteReply: (event) ->
    item = $(event.target).parents('.reply')
    annotation = item.parents('.annotator-annotation').data('annotation')
    text = item.find('.replytext')[0].innerHTML
    replies = annotation.replies or []

    for reply, idx in replies
      if text == reply.reply
        annotation.replies[idx].remove = true
        item.slideUp( -> item.remove() )

    annotation = @annotator.updateAnnotation(annotation)

  getReplyObject: ->
    replyObject =
        reply: ""
        created: new Date().toJSON()

    replyObject


  processKeypress: (event) =>
    item =  $(event.target).parent()
    controls = item.find('.annotator-reply-controls')
    if controls.length == 0
      item.append('''<div class="annotator-reply-controls">
          <a href="#save" class="annotator-reply-save">Save</a>
          <a href="#cancel" class="annotator-cancel">Cancel</a>
          </div>
          </div>
          ''')
      @annotator.viewer.checkOrientation()

    if event.keyCode is 27 # "Escape" key => abort.
      @annotator.viewer.hide()
    else if event.keyCode is 13 and !event.shiftKey
      # If "return" was pressed without the shift key, we're done.
      @onReplyEntryClick(event)

  hide: ->
    @annotator.viewer.hide()
