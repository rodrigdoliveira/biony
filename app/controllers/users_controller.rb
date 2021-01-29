class UsersController < ApplicationController
    def show
        warden.authenticate!(:apiToken)

        userInfo = {"id": current_user.id, "email": current_user.email, "groups": current_user.groups, "biosignalgroups": current_user.biosignalgroups, "favorites": current_user.favorites,
                    "respColor": current_user.respColor, "respZerosColor": current_user.respZerosColor, "edaColor": current_user.edaColor, "edaOnsetColor": current_user.edaOnsetColor,
                    "edaPeaksColor": current_user.edaPeaksColor, "emgColor": current_user.emgColor, "emgOnsetColor": current_user.emgOnsetColor, "bvpColor": current_user.bvpColor,
                    "bvpOnsetColor": current_user.bvpOnsetColor, "eegColor": current_user.eegColor, "ecgColor": current_user.ecgColor, "ecgRPeaksColor": current_user.ecgRPeaksColor}

        userInfo["biosignals"] = []

        current_user.biosignals.each do |b|
            userInfo["biosignals"] << {"id": b.id, "name": b.name, "date": b.date, "notes": b.notes, "signalType": b.signalType}
        end

        p userInfo

        render json: userInfo.to_json
    end

    
end
