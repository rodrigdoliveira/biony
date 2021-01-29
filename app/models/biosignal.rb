class Biosignal
    include Mongoid::Document

    module SignalType
        BVP = "bvp".freeze
        ECG = "ecg".freeze
        EDA = "eda".freeze
        EEG = "eeg".freeze
        EMG = "emg".freeze
        RESP = "resp".freeze
    end

    SIGNAL_TYPES = [ SignalType::BVP, SignalType::ECG, SignalType::EDA, SignalType::EEG, SignalType::EMG, SignalType::RESP ]

    field :name,            type: String, default: ""
    field :date,            type: DateTime
    field :notes,           type: String, default: ""
    field :signalType,      type: String
    field :rawSignal,       type: String, default: ""
    field :processedData,   type: String, default: ""

    belongs_to :user,   class_name: 'User'
    embeds_many :annotations, class_name: 'Annotation'
end