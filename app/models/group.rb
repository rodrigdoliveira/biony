class Group
    include Mongoid::Document

    field :name,            type: String, default: ""
    field :total,           type: Integer, default: 1
    field :notes,           type: String, default: ""
    field :users,           type: Array, default: [] #BSON::ObjectId of User
    field :biosignals,      type: Array, default: [] #BSON::ObjectId of Biosignal
    field :biosignalgroups,       type: Array, default: [] #BSON::ObjectId of BiosignalGroup
end