class ApiTokenStrategy < Warden::Strategies::Base
    def valid?
        apiToken.present?
    end

    def authenticate!
        user = User.where(apiToken: apiToken)[0]

        if user
            success!(user)
        else
            fail!('Invalid email or password')
        end
    end

    private

    def apiToken
        env['HTTP_AUTHORIZATION'].to_s.remove('Bearer ')
    end
end
