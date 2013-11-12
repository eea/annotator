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

  # Add a reply button to the viewer widget's controls span
  addReplyButton: (viewer, annotations) ->
    listing = @annotator.element.find('.annotator-annotation.annotator-item')
    for item, idx in listing
      item = $(item)
      replies = annotations[idx].replies or []

      if replies.length > 0
        item.append('''
          <div style='padding:5px' class='annotator-replies-header'> <span> Replies </span></div>
            <div id="Replies">
              <li class="Replies">
              </li>
            </div>''')

      if replies.length > 0
        replylist = @annotator.element.find('.Replies')
        for reply in replies
          username = if (reply.user.name and reply.user.id) then ('@' + reply.user.id + ' (' + reply.user.name + ')') else reply.user
          $(replylist[idx]).append('''<div class='reply'>
            <span class='replyuser'>''' + username + '''</span><button TITLE="Delete" class='annotator-delete-reply'>x</button><div class='replytext'>''' + reply.reply + '''</div></div>''')

      # Add the textarea
      item.append('''<div class='replybox'>
          <textarea class="replyentry" placeholder="Reply to this annotation..."></textarea>
          ''')

    viewer.checkOrientation()



  # Handle the event when the submit button is clicked
  #
  onReplyEntryClick: (event) ->
    # get content of the textarea
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
    # delete the reply
    reply_item = $(event.target).parents('.reply')
    parent_id = reply_item.parents('.annotator-annotation').data('annotation').id
    reply_text = reply_item.find('.replytext')[0].innerHTML

    # now look for annotations with parent == parent_id AND reply that matches reply_text and delete them
    for ann in @annotator.dumpAnnotations()
      if ann.parent == parent_id
        if ann.reply.reply == reply_text
            #          console.log('match, ', ann)
          ann.highlights = []
          @annotator.deleteAnnotation(ann)
          # remove reply from DOM
          $(reply_item).replaceWith('')
          break


  getReplyObject: ->
    replyObject =
        reply: ""

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
