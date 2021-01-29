class StorageController < ApplicationController
    before_action :authenticate_user!

    def index
        @biosignal_new = Biosignal.new
        @group_new = Group.new
        @biosignalGroup_new = BiosignalGroup.new

        @groups_length = current_user.groups.length()

        @groups = getUserGroups()

        @signalTypes = [ SignalType::BVP, SignalType::ECG, SignalType::EDA, SignalType::EEG, SignalType::EMG, SignalType::RESP ]
        render 'index'
    end

    def getUserGroups
        groups = []

        newGroups = []
        needToUpdateGroups = false
        current_user.groups.each do |groupId|
            result = Group.where(id: groupId)

            if result.length() > 0
                newGroups << groupId
                group = result[0]
                groups << group
            else
                needToUpdateGroups = true
            end
        end

        if needToUpdateGroups
            current_user.groups = newGroups
            current_user.save
        end

        return groups
    end

    module SignalType
        BVP = OpenStruct.new(name: "Blood Volume Pulse (BVP)", type: "bvp")
        ECG = OpenStruct.new(name: "Electrocardiogram (ECG)", type: "ecg")
        EDA = OpenStruct.new(name: "Electrodermal Activity (EDA)", type: "eda")
        EEG = OpenStruct.new(name: "Electroencephalogram (EEG)", type: "eeg")
        EMG = OpenStruct.new(name: "Electromyography (EMG)", type: "emg")
        RESP = OpenStruct.new(name: "Respiration (RESP)", type: "resp")
    end
end
