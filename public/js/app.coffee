jQuery ->
  $.fn.editable.defaults.mode = 'inline'
  $('textarea').emojiarea
    buttonLabel: '插入表情'
    buttonPosition: 'before'
  $('#username').editable
    type: 'text',
    pk: 1,
    url: '/username',
    title: 'Enter username'
  $('#username').on 'save', (e, params)->
    location.reload()

  ws = new WebSocket("ws://0.0.0.0:1438")

  ws.onmessage = (evt)->
    $('#chat tbody').append('<tr><td>' + evt.data + '</td></tr>')
    if $('form').hasClass('notconnected')
      $('form').removeClass('notconnected')
      $('.emoji-wysiwyg-editor').empty().attr('contenteditable',true)
    $('.msg').scrollTop(900000)

  ws.onclose = ->
    ws.send("Leaves the chat")

  ws.onopen = ->
    ws.send("Join the chat")

  $("#send").click (e)->
    if $('form').hasClass('notconnected')
      return false
    if($("#msg").val().length > 0)
      ws.send($(".emoji-wysiwyg-editor").html())
      $(".emoji-wysiwyg-editor").empty()
    return false

  $(document).live 'keydown', (e)->
    if e.ctrlKey && e.keyCode == 13
      $('#send').trigger('click')

  $("#clear").click ->
    $('#chat tbody tr').remove()
