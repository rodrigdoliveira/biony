class BiosignalGroupsController < ApplicationController
    before_action :authenticate_user!

    def create      
        biosignalGroup = BiosignalGroup.new(biosignalGroup_params)
        biosignalGroup.save
        current_user.biosignalgroups << biosignalGroup.id
        current_user.save
        redirect_to ''
    end

    def show
        @biosignalGroupId = params[:biosignalGroupId]

        @biosignalGroup = BiosignalGroup.find(params[:biosignalGroupId])

        biosignals = []

        @biosignalGroup.biosignals.each do |id|
            begin
                biosignal = Biosignal.find(id)
                biosignal[:finishLoad] = false
                biosignals << biosignal
            rescue Mongoid::Errors::DocumentNotFound
                #needToUpdateFavorites = true
            end
        end

        @biosignals = biosignals.to_json.html_safe
        render 'index'
    end

    def removeFromBiosignalGroup
        result = Biosignal.where(id: params[:biosignal])
        finalResult = false
        if result.length() > 0
            biosignal = result[0]

            resultB = BiosignalGroup.where(id: params[:biosignalGroupId])

            if resultB.length() > 0
                biosignalGroup = resultB[0]

                if (biosignal.id).in?(biosignalGroup.biosignals)
                    biosignalGroup.biosignals.delete(biosignal.id)
                    biosignalGroup.save

                    finalResult = true
                end
            end

        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def getUserBiosignalGroups
        biosignalGroups = {}

        newBiosignalGroups = []
        needToUpdateBiosignalGroups = false
        current_user.biosignalgroups.each do |group|
            result = BiosignalGroup.where(id: group)

            if result.length() > 0
                newBiosignalGroups << group
                biosignalGroup = result[0]
                biosignalGroup[:isFromGroup] = false
                biosignalGroup[:groupName] = ""
                biosignalGroups[biosignalGroup.id] = biosignalGroup
            else
                needToUpdateBiosignalGroups = true
            end
        end

        if needToUpdateBiosignalGroups
            current_user.biosignalgroups = newBiosignalGroups
            current_user.save
        end

        if(current_user.groups.length() > 0)
            current_user.groups.each do |groupId|
                group = Group.where(id: groupId)[0]

                newGroupBiosignalGroups = []
                needToUpdateGroupBiosignalGroups = false
                group.biosignalgroups.each do |biosignalGroupId|
                    if !(biosignalGroupId).in?(biosignalGroups)
                        resultB = BiosignalGroup.where(id: biosignalGroupId)

                        if resultB.length() > 0
                            newGroupBiosignalGroups << biosignalGroupId
                            biosignalGroup = resultB[0]
                            biosignalGroup[:isFromGroup] = true
                            biosignalGroup[:groupName] = group.name
                            p biosignalGroup.id
                            p "---"
                            p biosignalGroups
                            biosignalGroups[biosignalGroup.id] = biosignalGroup
                        else
                            needToUpdateGroupBiosignalGroups = true
                        end
                    end
                end
                
                if needToUpdateGroupBiosignalGroups
                    group.biosignalgroups = newGroupBiosignalGroups
                    group.save
                end
            end
        end

        respond_to do |format|
            format.json { render json: biosignalGroups.to_json }
        end
    end

    def addBiosignalToBiosignalGroup
        result = Biosignal.where(id: params[:biosignal])
        finalResult = false
        if result.length() > 0
            biosignal = result[0]

            resultB = BiosignalGroup.where(id: params[:biosignalGroupId])

            if resultB.length() > 0
                biosignalGroup = resultB[0]

                if !(biosignal.id).in?(biosignalGroup.biosignals)
                    biosignalGroup.biosignals << biosignal.id
                    biosignalGroup.save

                    finalResult = true
                end
            end

        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def shareWithGroup
        result = Group.where(id: params[:group])
        finalResult = false
        if result.length() > 0
            group = result[0]

            resultB = BiosignalGroup.where(id: params[:biosignalGroupId])

            if resultB.length() > 0
                biosignalGroup = resultB[0]

                if !(biosignalGroup.id).in?(group.biosignalgroups)
                    group.biosignalgroups << biosignalGroup.id
                    group.save

                    biosignalGroup.groups << group.id
                    biosignalGroup.save

                    finalResult = true
                end
            end

        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def videoRange
        result = BiosignalGroup.where(id: params[:biosignalGroupId])
        finalResult = false
        if result.length() > 0
            biosignalGroup = result[0]
            
            biosignalGroup.update_attributes!({videoActualEnd: params[:videoActualEnd].to_i, videoActualStart: params[:videoActualStart].to_i})
        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def biosignalGroup_params
        params.require(:biosignal_group).permit(:name, :notes, :users, :biosignals, :video)
    end

end
