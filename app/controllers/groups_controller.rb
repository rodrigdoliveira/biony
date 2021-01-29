class GroupsController < ApplicationController
    before_action :authenticate_user!
    
    def create      
        group = Group.new(group_params)
        group.save
        group.users << current_user.id
        group.save
        current_user.groups << group.id
        current_user.save
        redirect_to ''
    end

    def addUser
        result = User.where(email: params[:userEmail])
        finalResult = false
        if result.length() > 0
            user = result[0]

            resultG = Group.where(id: params[:groupId])

            if resultG.length() > 0
                group = resultG[0]

                if !(group.id).in?(user.groups)
                    user.groups << group.id
                    user.save
                    group.users << user.id
                    group.total = group.total + 1
                    group.save

                    finalResult = true
                end
            end

        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def members
        finalResult = false
        resultG = Group.where(id: params[:groupId])
        members = []

        if resultG.length() > 0
            group = resultG[0]

            if (current_user.id).in?(group.users)
                group.users.each do |userId|
                    user = User.where(id: userId)[0]
                    members << user.email
                end

                finalResult = true
            end
        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult, "members" => members} }
        end
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

        respond_to do |format|
            format.json { render json: groups.to_json }
        end
    end

    def group_params
        params.require(:group).permit(:name, :notes, :users, :biosignals)
    end
end
