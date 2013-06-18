require 'mongoid'

require './models'

User.delete_all
User.create({
  email: 'alice@example.com',
  lists: [
    List.new({
      name: '1 BIG THING',
      color: 'red',
      tasks: [
        Task.new({
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
          done: false
        })
      ]
    }),
    List.new({
      name: '3 MEDIUM THINGS',
      color: 'orange',
      tasks: [
        Task.new({
          text: 'Nullam sit amet nisi laoreet orci dignissim imperdiet',
          done: true
        }),
        Task.new({
          text: 'Proin vehicula molestie dolor',
          done: false
        }),
        Task.new({
          text: 'Integer at massa ac tellus dictum dictum',
          done: true
        })
      ]
    }),
    List.new({
      name: '5 SMALL THINGS',
      color: 'yellow',
      tasks: [
        Task.new({
          text: 'Nunc purus mauris, varius nec dapibus placerat, iaculis eu massa. Nam ac hendrerit velit. Quisque mollis gravida tortor',
          done: false
        }),
        Task.new({
          text: 'Curabitur sed odio eget libero fermentum molestie eget eget turpis',
          done: true
        }),
        Task.new({
          text: 'Ut velit justo, vestibulum sed molestie in',
          done: true
        }),
        Task.new({
          text: 'Sed vulputate libero a dolor facilisis euismod',
          done: false
        }),
        Task.new({
          text: 'Proin ac nisi vel velit viverra convallis',
          done: true
        })
      ]
    })
  ]
})
