module CookieCrypt
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      included do
        before_filter :handle_cookie_crypt
      end

      private

      def authentication_success
        flash[:notice] = 'Signed in through two-factor authentication successfully.'
        warden.session(resource_name)[:need_cookie_crypt_auth] = false
        bypass_sign_in resource
        resource.update_attribute(:cookie_crypt_attempts_count, 0)
        redirect_to stored_location_for(resource_name) || :root
      end

      def cookie_crypt_auth_path_for(resource_or_scope = nil)
        scope = Devise::Mapping.find_scope!(resource_or_scope)
        change_path = "#{scope}_cookie_crypt_path"
        send(change_path)
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

      def handle_cookie_crypt
        unless devise_controller?
          Devise.mappings.keys.flatten.any? do |scope|
            if signed_in?(scope) and warden.session(scope)[:need_cookie_crypt_auth]
              handle_failed_cookie_crypt_auth(scope)
            end
          end
        end
      end

      def handle_failed_cookie_crypt_auth(scope)
        if request.format.present? and request.format.html?
          session["#{scope}_return_tor"] = request.path if request.get?
          redirect_to cookie_crypt_auth_path_for(scope)
        else
          render nothing: true, status: :unauthorized
        end
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

      def matching_answers? hash
        answers = []
        answers_from_form = []
        params[:security_answers].each_key do |key|
          answers_from_form << key
        end
        
        unless resource.class.cookie_crypt_auth_through == :all_questions
          if resource.class.cookie_crypt_auth_through == :one_question_cyclical || 
            resource.class.cookie_crypt_auth_through == :two_questions_cyclical

            answers << "security_answer_#{resource.security_cycle+session[:cyclemod]}"
          else #random cyclemod case
            answers << "security_answer_#{session[:cyclemod]}"
          end
        end

        if resource.class.cookie_crypt_auth_through == :two_questions_cyclical
          if session[:cyclemod]+resource.security_cycle+1 <= hash.keys.count/2
            next_question_mod = session[:cyclemod]+resource.security_cycle+1
          else
            next_question_mod = 0
          end

          answers << "security_answer_#{next_question_mod}"
        elsif resource.class.cookie_crypt_auth_through == :two_questions_random
          answers << "security_answer_#{session[:cyclemod2]}"
        elsif resource.class.cookie_crypt_auth_through == :all_questions
          hash.keys.delete_if{|x| x.include?("question")}.each do |key|
            answers << key
          end
        end

        authed = false
        a_arr = []
        answers.each do |key|
          if hash[key] == Digest::SHA512.hexdigest(sanitize(params[:security_answers][key]))
            a_arr[answers.index(key)] = true
          else
            a_arr[answers.index(key)] = false
          end
        end

        authed = true unless a_arr.include?(false)
        authed
      end

      def set_cyclicial_cyclemod hash
        if resource.cookie_crypt_attempts_count == 0
          session[:cyclemod] = 0
        elsif resource.cookie_crypt_attempts_count != 0 && resource.cookie_crypt_attempts_count%resource.class.cycle_question_on_fail_count == 0 
          session[:cyclemod] += 1
        else #logout then log back in at a future time?
          session[:cyclemod] = 0
        end

        session[:cyclemod] = 0 if session[:cyclemod]+resource.security_cycle > hash.keys.count/2
      end

      def set_random_cyclemod hash
        if resource.cookie_crypt_attempts_count == 0
          session[:cyclemod] = Random.rand(1..(hash.keys.count/2))
        elsif resource.cookie_crypt_attempts_count != 0 && resource.cookie_crypt_attempts_count%resource.class.cycle_question_on_fail_count == 0 
          r = Random.rand(1..(hash.keys.count/2))
          while session[:cyclemod] == r || resource.security_cycle == r
            r = Random.rand(1..(hash.keys.count/2))
          end
          session[:cyclemod] = r

        else #logout then log back in at a future time?
          session[:cyclemod] = 0
        end
      end

      def update_resource_cycle hash
        #reset or rollover the cycle number
        if resource.class.cookie_crypt_auth_through == :one_question_cyclical || 
          resource.class.cookie_crypt_auth_through == :two_questions_cyclical

          if resource.security_cycle+1 > hash.keys.count/2
            resource.security_cycle = 1
          else
            resource.security_cycle += 1
          end
        elsif resource.class.cookie_crypt_auth_through == :one_question_random || 
          resource.class.cookie_crypt_auth_through == :two_questions_random

          resource.security_cycle = session[:cyclemod]
        end
        
        resource.save
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
  end
end
