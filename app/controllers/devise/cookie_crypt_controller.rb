include ActionView::Helpers::SanitizeHelper
require "useragent"
require "logger"
class Devise::CookieCryptController < DeviseController
  prepend_before_filter :authenticate_scope!
  before_filter :prepare_and_validate, :handle_cookie_crypt

  def show
    if has_matching_encrypted_cookie?
      if !using_an_agent_that_is_already_being_used?
        #An attacker has successfully obtained a user's cookie and login credentials and is trying to pass themselves off as the target
        #This is an attacker because the agent data does not match the agent data from when a cookie is generated for this user's machine.
        #A machine that "suddenly" has a cookie despite not being auth'd is an attacker.

        log_hack_attempt

        resource.cookie_crypt_attempts_count = resource.class.max_cookie_crypt_login_attempts
        resource.save #prevents attacker from deleting cookie and trying to login "normally" by inputting the user's two_fac answers

        sign_out(resource)
        redirect_to :root and return
      else
        authentication_success
      end
    else
      flash[:notice] = "Signed In Successfully, now going through two factor authentication."
      @user = resource
      render template: "devise/cookie_crypt/show"
    end
  end

  def update
    if resource.security_question_one.blank? # initial case (first login)

      resource.security_question_one = sanitize(params[:security_question_one])
      resource.security_question_two = sanitize(params[:security_question_two])
      resource.security_answer_one   = Digest::SHA512.hexdigest(sanitize(params[:security_answer_one]))
      resource.security_answer_two   = Digest::SHA512.hexdigest(sanitize(params[:security_answer_two]))
      resource.save

      authentication_success
    else
      
      if matching_answers?
        generate_cookie
        log_agent_to_resource
        authentication_success
      else
        resource.cookie_crypt_attempts_count += 1
        resource.save
        set_flash_message :error, :attempt_failed
        if resource.max_cookie_crypt_login_attempts?
          sign_out(resource)
          render template: 'devise/cookie_crypt/max_login_attempts_reached' and return
        else
          render :show
        end
      end
    end
  end

  private

    def authenticate_scope!
      self.resource = send("current_#{resource_name}")
    end

    def encrypted_username_and_pass
      Digest::SHA512.hexdigest("#{resource.username}_#{resource.encrypted_password}")
    end

    def generate_cookie
      cookies["#{resource.username}_#{Rails.application.class.to_s.split("::").first}".to_sym] = {
        value: "#{encrypted_username_and_pass}",
        expires: Date.class_eval("#{resource.class.cookie_deletion_time_frame}")
      }
    end

    def has_matching_encrypted_cookie?
      cookies["#{resource.username}_#{Rails.application.class.to_s.split("::").first}"] == encrypted_username_and_pass
    end

    def log_hack_attempt
      logger = Logger.new("#{Rails.root.join('log','hack_attempts.log')}")
      logger.warn "Attempt to bypass two factor authentication and devise detected from ip #{request.remote_ip} using #{resource_name}: #{resource.inspect}!"
    end

    def log_agent_to_resource
      unless using_an_agent_that_is_already_being_used?
        resource.agent_list = "#{resource.agent_list}#{'|' unless resource.agent_list.blank?}#{request.user_agent}"
        resource.save
      end
    end

    def matching_answers?
      resource.security_answer_one == Digest::SHA512.hexdigest(sanitize(params[:security_answer_one])) &&
        resource.security_answer_two == Digest::SHA512.hexdigest(sanitize(params[:security_answer_two]))
    end

    def prepare_and_validate
      redirect_to :root and return if resource.nil?
      @limit = resource.class.max_cookie_crypt_login_attempts
      if resource.max_cookie_crypt_login_attempts?
        sign_out(resource)
        render template: 'devise/cookie_crypt/max_login_attempts_reached' and return
      end
    end

    def authentication_success
      flash[:notice] = 'Signed in through two-factor authentication successfully.'
      warden.session(resource_name)[:need_cookie_crypt_auth] = false
      sign_in resource_name, resource, :bypass => true
      resource.update_attribute(:cookie_crypt_attempts_count, 0)
      redirect_to stored_location_for(resource_name) || :root
    end

    def using_an_agent_that_is_already_being_used?
      unless resource.agent_list.blank?
        request_agent = UserAgent.parse("#{request.user_agent}")
        resource.agent_list.split('|').each do |agent_string|
          if agent_string.include?("#{request_agent.application}")
            agent = UserAgent.parse("#{agent_string}")
            if agent.application == request_agent.application && agent.browser == request_agent.browser
              if request_agent >= agent #version number is higher for example
                #update user agent string and return true
                resource.agent_list = resource.agent_list.gsub("#{agent.browser}/#{agent.version}","#{request_agent.browser}/#{request_agent.version}")
                resource.save
                return true
              elsif request_agent.version == agent.version
                return true
              end
            end
          end
        end
      end
      false
    end

    def unrecognized_agent?
      resource.agent_list.include?("#{request.user_agent}")
    end
end
