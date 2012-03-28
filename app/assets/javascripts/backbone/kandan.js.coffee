#= require_self
#= require_tree ../../templates
#= require_tree ./models
#= require_tree ./collections
#= require_tree ./views
#= require_tree ./routers
#= require_tree ./helpers

window.Kandan =
  Models:       {}
  Collections:  {}
  Views:        {}
  Routers:      {}
  Helpers:      {}
  Broadcasters: {}
  Data:         {}
  Plugins:      {}

  # TODO this is a helper method to register plugins
  # in the order required until we come up with plugin management
  register_plugins: ->
    plugins = [
      "UserList"
      ,"YouTubeEmbed"
      ,"ImageEmbed"
      ,"LinkEmbed"
      ,"Pastie"
      ,"Attachments"
      ,"MeAnnounce"
    ]

    for plugin in plugins
      Kandan.Plugins.register "Kandan.Plugins.#{plugin}"

  initBroadcasterAndSubscribe: ()->
    window.broadcaster = new Kandan.Broadcasters.FayeBroadcaster()
    window.broadcaster.subscribe "/channels/*" ##{channel.get('id')}

  init: ->
    channels = new Kandan.Collections.Channels()
    channels.fetch({success: ()=>
      chat_area = new Kandan.Views.ChatArea({channels: channels})

      @initBroadcasterAndSubscribe()

      $(document).bind 'changeData', (element, name, value)->
        if(name=="active_users")
          Kandan.Data.ActiveUsers.runCallbacks('change')

      active_users = new Kandan.Collections.ActiveUsers()
      active_users.fetch({
        success: (collection)->
          collection.add([$(document).data('current_user')]) if not Kandan.Helpers.ActiveUsers.collectionHasCurrentUser(collection)

          Kandan.Helpers.ActiveUsers.setFromCollection(collection)

          # NOTE init plugins so that modifiers are registered
          Kandan.register_plugins()
          Kandan.Plugins.init_all()


          $(".main-area").html(chat_area.render().el)
          chatbox = new Kandan.Views.Chatbox()
          $(".main-area").append(chatbox.render().el)
          $('#channels').tabs({
            select: (event, ui)->
              $(document).data('active_channel_id',
                Kandan.Helpers.Channels.getChannelIdByTabIndex(ui.index))
              console.log "channel changed to index", ui.index
              Kandan.Data.Channels.runCallbacks('change')
          })

          $("#channels").tabs 'option', 'tabTemplate', '''
            <li>
              <a href="#{href}">#{label}</a>
              <span class="ui-icon ui-icon-close">x</span>
            </li>
          '''

          Kandan.Widgets.init_all()
      })
    })
