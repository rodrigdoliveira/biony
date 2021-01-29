class BiosignalGroup
    include Mongoid::Document
    mount_uploader :video, VideoUploader

    field :name,                type: String, default: ""
    field :notes,               type: String, default: ""
    field :groups,              type: Array, default: [] #BSON::ObjectId of Groups
    field :biosignals,          type: Array, default: [] #BSON::ObjectId of Biosignal
    field :videoActualStart,    type: Integer, default: 0
    field :videoActualEnd,      type: Integer, default: 0
    field :video,               type: String, default: ""
end