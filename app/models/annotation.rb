class Annotation
    include Mongoid::Document

    field :minX,                    type: Integer, default: 1
    field :maxX,                    type: Integer, default: 1
    field :description,             type: String, default: ""
    field :color,                   type: String, default: "#ffff00"

    field :innerIdx,                type: Integer, default: 1 #1 = FILTERED SIGNAL NO BIOSINAL

    embedded_in :biosignal, class_name: 'Biosignal'

end