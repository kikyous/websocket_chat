jQuery ->
  $.fn.editable.defaults.mode = 'inline'
  $.extend($.emojiarea.defaults, {
    button: '#addemoji'
  })
  $('textarea').emojiarea()
  $('#username').editable
    type: 'text',
    pk: 1,
    url: '/username',
    title: 'Enter username'
  $('#username').on 'save', (e, params)->
    location.reload()

  ws = new WebSocket("ws://0.0.0.0:1438")

  ws.onmessage = (evt)->
    $('#chat').append( evt.data ).scrollTop(900000)

  ws.onclose = ->
    dialog('连接已断开，请刷新页面')
    ws.send("Leaves the chat")

  ws.onopen = ->
    editor = $(".emoji-wysiwyg-editor:last")
    editor.empty().attr('contenteditable',true)
    send_msg("Join the chat")

  message = (title, content)->
    time = moment().format("YYYY-MM-DD HH:mm:ss")
    "<dl><dt><span class='badge badge-success'>#{title} #{time}</span></dt><dd>#{content}</dd></dl>"

  $("#send").click (e)->
    editor = $(".emoji-wysiwyg-editor:last")
    send_msg(editor.html())
    editor.empty()
    false

  send_msg = (text)->
    if ws.readyState != WebSocket.OPEN
      dialog('连接已断开，请刷新页面')
    else
      if(text.length > 0)
        $('#chat').append(message $('#username').text(), text)
        ws.send(text)
        $('#chat').scrollTop(900000)

  $(document).live 'keydown', (e)->
    if e.ctrlKey && e.keyCode == 13
      $('#send').trigger('click')

  $("#clear").click ->
    $('#chat dl').remove()

  $(document).on 'hidden', '#modal', ->
    $(@).remove()

  dialog = (msg)->
    html = "<div id='modal' class='modal hide fade'>
    <div class='modal-header'> <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
    <h3>WebSocketChat</h3>
    </div>
    <div class='modal-body'>
      <p>#{msg}</p>
    </div>
    <div class='modal-footer'>
      <a href='#' aria-hidden='true' data-dismiss='modal' class='btn'>关闭</a>
      <a href='#' class='btn btn-primary' onclick='location.reload()'>确认</a>
    </div>
    </div>"
    $('body').append(html)
    $('#modal').modal('show')

  $('#fileselect').on 'change', ->
    UploadFile()
  UploadFile = ->
    xhr = new XMLHttpRequest()
    fd = new FormData(document.getElementById('form'))
    xhr.onload = (evt)->
      data = JSON.parse(xhr.response)
      if data.type in ['jpg','jpeg','png','gif']
        elem = "<img src=#{data.url} />"
      else
        elem = "<a href=#{data.url}>#{data.name}</a>"
      $('.emoji-wysiwyg-editor').append(elem)
    xhr.open("POST", '/upload')
    xhr.send(fd)
