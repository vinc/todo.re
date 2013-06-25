require 'mongoid'

class User
  include Mongoid::Document
  field :email, type: String
  index :email, unique: true
  embeds_many :lists
end

class List
  include Mongoid::Document
  field :name, type: String, default: ''
  field :color, type: String, default: 'grey'
  embeds_many :tasks
  embedded_in :user
end

class Task
  include Mongoid::Document
  field :text, type: String, default: ''
  field :done, type: Boolean, default: false
  embedded_in :list
end
