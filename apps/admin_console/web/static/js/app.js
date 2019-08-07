import "phoenix_html"
import socket from "./socket"

socket.connect()

let channel = socket.channel("events:all", {})
let message_div = document.getElementById("messages")
let block_input = document.getElementById("block_input")
let block_list  = document.getElementById("block_list")

block_input.addEventListener('keypress', e => {
    var key = e.which || e.keyCode
    if (key === 13) {
      window.blockUrl()
    }
});

window.blockUrl = function(){
  let url = block_input.value;
  if( url != "" ) {
    block_input.value = ""
    channel.push("block", {url: url})
  }
}

window.unblockAll = function() {
  channel.push("unblock_all", {})
}

let createMessageDiv = (payload) => {
  var new_div = document.createElement("div")
  var wow = payload.action.split(" ").join("_").toLowerCase()

  var name_part = document.createElement("span")
  name_part.className = wow + " text-left"
  var date = new Date
  var time_str = "" + date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds()
  name_part.appendChild(document.createTextNode("[" + time_str + "] " + payload.action + " : "))
  var message_part = document.createElement("span")
  message_part.className = "text-left"
  message_part.appendChild(document.createTextNode(payload.message))

  new_div.appendChild(name_part)
  new_div.appendChild(message_part)
  message_div.appendChild(new_div)
}

channel.on("new_event", payload => {
  let data = payload.message
  createMessageDiv(data)
  if(data.action == "block") {
    addBlocked(data.url)
  }
})

function unblock(url) {
  channel.push("unblock", {url: url})
}

function addBlocked(url) {
  var new_div = document.createElement("div")
  new_div.className = "block_entry"
  var text = document.createTextNode(url)
  var button = document.createElement("button")
  button.appendChild(document.createTextNode("Unblock"))
  button.onclick = () => {
   unblock(url)
  }
  button.className = "btn btn-danger unblock"

  new_div.appendChild(text)
  new_div.appendChild(button)
  block_list.appendChild(new_div)
}

channel.on("block_list", payload => {
  block_list.innerHTML = ""
  for(var blocked of payload.blocked) {
    addBlocked(blocked)
  }
})

channel.join()
  .receive("ok", () => channel.push("blocked?", {}))
