require 'open3'
class BiosignalsController < ApplicationController
    before_action :authenticate_user!

    def create
        puts "oi"
        if(!params[:biosignal].nil? && params[:biosignal] != "")      
            biosignal = Biosignal.new(biosignal_params)
            biosignal.user = current_user
            if biosignal.save!
                biosignal.rawSignal = params[:biosignal][:rawSignal].read
                biosignal.save!

                actualMetaData = ""
                attrs = {}
                biosignal.rawSignal.each_line do |line| #get Metadata
                    if(line[0] == "#")
                        metadatavalues = line[0..-2].split(":=") #ignore \n and split by :=
                        if metadatavalues.length > 1 #if := present
                            actualValue = metadatavalues[1]
                            if(metadatavalues[1][0] == " ")
                                actualValue = metadatavalues[1].slice(1, metadatavalues[1].length) #remove first space for convenience
                            end

                            actualLabel = ""
                            if(line[0..1] == "# ")
                                actualLabel = metadatavalues[0][2..-1] #remove # and space
                            else
                                actualLabel = metadatavalues[0][1..-1] #remove #
                            end
                            
                            attrs[actualLabel] = actualValue
                        else
                            if(line[0..1] == "# ")
                                actualMetaData = actualMetaData + line[2..-1] #remove # and space
                            else
                                actualMetaData = actualMetaData + line[1..-1] #remove #
                            end
                            
                        end
                    else
                        break
                    end
                end

                newNotes = (biosignal.notes == "" ? "" : biosignal.notes + "\n") + actualMetaData
                attrs.each do |at,value|
                    newNotes = newNotes + at + ":= " + value + "\n" 
                end
                if newNotes[-1] == "\n"
                    newNotes = newNotes[0..-2] #remove last \n
                end

                puts(attrs)

                biosignal.notes = newNotes
                biosignal.signalType = attrs["Labels"].downcase
                biosignal.save!

                samplingRate = "1000.00" #default?
                if(attrs.key?("Sampling Rate (Hz)"))
                    samplingRate = attrs["Sampling Rate (Hz)"]
                end

                result = {}
                Open3.popen3("python3.6 python/createSignal.py") do |stdin, stdout, stderr, wait_thr|
                    begin
                        stdin.puts(biosignal.signalType)
                        stdin.puts(params[:biosignal][:rawSignal].path)
                        stdin.puts(samplingRate)
                        wait_thr.value
                        result = JSON.parse(stdout.read)
                    rescue
                        p stderr.read
                    end
                end
                
                if result == 1
                    params[:biosignal][:rawSignal].rewind
                    biosignal.processedData = params[:biosignal][:rawSignal].read
                    biosignal.save!
                end
                
                redirect_to ''
            else
                render ''
            end
        else
            redirect_to ''
        end
    end

    def show
        biosignal = Biosignal.find(params[:signalId])
        render biosignal.signalType
    end

    def delete
        result = Biosignal.where(id: params[:signalId])
        finalResult = false
        if result.length() > 0
            biosignal = result[0]
            if biosignal.user.id == current_user.id
                biosignal.destroy
                finalResult = true
            end
        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def dataToD3
        biosignal = Biosignal.find(params[:signalId])

        respond_to do |format|
            format.json { render json: biosignal.to_json }
        end
    end

    def favorites
        biosignals = []

        favorites = []
        needToUpdateFavorites = false

        current_user.favorites.each do |fav|
            begin
                biosignal = Biosignal.find(fav)
                biosignal[:finishLoad] = false
                favorites << fav
                biosignals << biosignal
            rescue Mongoid::Errors::DocumentNotFound
                needToUpdateFavorites = true
            end
        end

        if needToUpdateFavorites
            current_user.favorites = favorites
            current_user.save
        end

        respond_to do |format|
            format.json { render json: biosignals.to_json }
        end
    end

    def addToFavorites
        result = Biosignal.where(id: params[:signalId])
        finalResult = false
        if result.length() > 0
            biosignal = result[0]
            if !(biosignal.id).in?(current_user.favorites)
                current_user.favorites << biosignal.id
                current_user.save
            else
                current_user.favorites.delete(biosignal.id)
                current_user.save
            end
            finalResult = true
        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def advancedSearch
        biosignals = []

        if(current_user.biosignals.length() > 0)
            current_user.biosignals.only(:name, :date, :notes, :signalType, :isFromGroup, :groupName, :isFav).order("date desc").each do |biosignal|
                biosignal[:isFromGroup] = false
                biosignal[:groupName] = ""
                biosignal[:isFav] = false
                biosignals << biosignal
            end
        end

        if(current_user.groups.length() > 0)
            current_user.groups.each do |groupId|
                group = Group.where(id: groupId)[0]

                group.biosignals.each do |signalId|
                    if !(signalId).in?(biosignals)
                        resultB = Biosignal.where(id: signalId).only(:name, :date, :notes, :signalType, :isFromGroup, :groupName, :isFav)

                        if resultB.length() > 0
                            biosignal = resultB[0]
                            biosignal[:isFromGroup] = true
                            biosignal[:groupName] = group.name
                            biosignal[:isFav] = false
                            biosignals << biosignal
                        end
                    end
                end
            end
        end

        filters = {}

        if params[:type] != "" && params[:type] != nil
            filters[:signalType] = params[:type]
        end

        biosignals = biosignals.select { |b| filterBiosignals(filters , b) }

        respond_to do |format|
            format.json { render json: biosignals.to_json }
        end
    end

    def filterBiosignals(filters, biosignal)
        if(filters.length > 0)
            filters.each do |f|
                if(biosignal[f[0]] != f[1])
                    return false
                end
            end
        end

        return true
    end

    def getUserBiosignals
        biosignals = {}

        if(current_user.biosignals.length() > 0)
            current_user.biosignals.only(:name, :date, :notes, :signalType, :isFromGroup, :groupName, :isFav).order("date desc").each do |biosignal|
                biosignal[:isFromGroup] = false
                biosignal[:groupName] = ""
                biosignal[:isFav] = false
                biosignals[biosignal.id] = biosignal
            end
        end

        if(current_user.groups.length() > 0)
            current_user.groups.each do |groupId|
                group = Group.where(id: groupId)[0]

                newGroupBiosignals = []
                needToUpdateGroupBiosignals = false
                group.biosignals.each do |signalId|
                    if !(signalId).in?(biosignals)
                        resultB = Biosignal.where(id: signalId).only(:name, :date, :notes, :signalType, :isFromGroup, :groupName, :isFav)

                        if resultB.length() > 0
                            newGroupBiosignals << signalId
                            biosignal = resultB[0]
                            biosignal[:isFromGroup] = true
                            biosignal[:groupName] = group.name
                            biosignal[:isFav] = false
                            biosignals[biosignal.id] = biosignal
                        else
                            needToUpdateGroupBiosignals = true
                        end
                    end
                end
                
                if needToUpdateGroupBiosignals
                    group.biosignals = newGroupBiosignals
                    group.save
                end
            end
        end

        current_user.favorites.each do |fav|
            if (fav).in?(biosignals)
                biosignals[fav][:isFav] = true
            end
        end

        biosignalArray = []
        biosignals.each do |key, value|
            biosignalArray << value
        end

        respond_to do |format|
            format.json { render json: biosignalArray.to_json }
        end
    end

    def shareWithGroup
        result = Group.where(id: params[:group])
        finalResult = false
        if result.length() > 0
            group = result[0]

            resultB = Biosignal.where(id: params[:signalId])

            if resultB.length() > 0
                biosignal = resultB[0]

                if !(biosignal.id).in?(group.biosignals)
                    group.biosignals << biosignal.id
                    group.save

                    finalResult = true
                end
            end

        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def createAnnotation

        result = Biosignal.where(id: params[:signalId])
        finalResult = false
        biosignal = nil
        innerIdx = (!params[:innerIdx].nil? && params[:innerIdx] != "") ? params[:innerIdx].to_i : 1
        if result.length() > 0
            biosignal = result[0]
            
            annotation = params[:annotation]

            biosignal.annotations << Annotation.new(:innerIdx => innerIdx,:minX => annotation["minX"], :maxX => annotation["maxX"], :description => annotation["description"], :color => annotation["color"])
            biosignal.save!

            finalResult = true
        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult, "biosignal" => biosignal } }
        end
    end

    def deleteAnnotation
        result = Biosignal.where(id: params[:signalId])
        finalResult = false
        biosignal = nil
        if result.length() > 0
            biosignal = result[0]
            resultA = biosignal.annotations.where(id: params[:annotationId])
            if resultA.length() > 0
                annotation = resultA[0]
                annotation.destroy
                finalResult = true
            end
        end

        respond_to do |format|
            format.json { render json: {"result" => finalResult, "biosignal" => biosignal } }
        end
    end

    def biosignal_params
        params.require(:biosignal).permit(:name, :date, :notes, :signalType, :rawSignal)
    end
end
