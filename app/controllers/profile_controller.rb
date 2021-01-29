class ProfileController < ApplicationController
    before_action :authenticate_user!

    def index

        render 'index'
    end

    def changeColor
        finalResult = false
        if(color_params)
            current_user.update!(color_params)
            finalResult = true
        end
        respond_to do |format|
            format.json { render json: {"result" => finalResult } }
        end
    end

    def color_params
        params.permit(:respColor, :respZerosColor, :edaColor, :edaOnsetColor, :edaPeaksColor, :emgColor, :emgOnsetColor, :bvpColor, :bvpOnsetColor, :eegColor, :ecgColor, :ecgRPeaksColor)
    end
end
