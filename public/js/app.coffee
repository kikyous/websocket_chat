jQuery ->
  $.fn.editable.defaults.mode = 'inline'
  $('#username').editable
    type: 'text',
    pk: 1,
    url: '/username',
    title: 'Enter username'
  $('#username').on 'save', (e, params)->
    location.reload()

  ws = new WebSocket("ws://0.0.0.0:8080")

  ws.onmessage = (evt)->
    $('#chat tbody').append('<tr><td>' + evt.data + '</td></tr>')
    $('.msg').scrollTop(400)

  ws.onclose = ->
    ws.send("Leaves the chat")

  ws.onopen = ->
    ws.send("Join the chat")

  $("form").submit (e)->
    if($("#msg").val().length > 0)
      ws.send($("#msg").val())
      $("#msg").val("")
    return false

  $(document).live 'keydown', (e)->
    if e.ctrlKey && e.keyCode == 13
      $('form').trigger('submit')

  $("#clear").click ->
    $('#chat tbody tr').remove()
