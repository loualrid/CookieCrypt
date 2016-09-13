include ActionView::Helpers::SanitizeHelper
require "useragent"
require "logger"
class Devise::CookieCryptController < DeviseController
  prepend_before_action :authenticate_scope!
  before_action :prepare_and_validate, :handle_cookie_crypt
  before_action :set_questions, :if => :show_request

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
      @request_path = request.fullpath.split('?').first
      render template: "devise/cookie_crypt/show"
    end
  end

  def update
    h = Hash.class_eval(resource.security_hash)
    if h.empty? # initial case (first login)

      (1..(params[:security].keys.count/2)).each do |n|
        h["security_question_#{n}"] = sanitize(params[:security]["security_question_#{n}".to_sym])
        h["security_answer_#{n}"] = Digest::SHA512.hexdigest(sanitize(params[:security]["security_answer_#{n}".to_sym]))
      end

      resource.security_hash = h.to_s

      resource.save

      authentication_success
    elsif (h.keys.count/2) < resource.class.cookie_crypt_minimum_questions # Need to update hash from an old install

      ((h.keys.count/2)+1..(params[:security].keys.count/2)+((h.keys.count/2))).each do |n|
        h["security_question_#{n}"] = sanitize(params[:security]["security_question_#{n}".to_sym])
        h["security_answer_#{n}"] = Digest::SHA512.hexdigest(sanitize(params[:security]["security_answer_#{n}".to_sym]))
      end
      resource.security_hash = h.to_s

      resource.save

      authentication_success
    else #normal login attempts
      puts "TESTING::#{ h }\n#{ resource.cookie_crypt_attempts_count }"
      
      if matching_answers?(h)
        generate_cookie unless params[:do_not_save_cookie]
        update_resource_cycle(h)
        log_agent_to_resource
        authentication_success
      else
        resource.cookie_crypt_attempts_count += 1
        resource.save
        set_flash_message :error, :attempt_failed
        if resource.max_cookie_crypt_login_attempts?
          update_resource_cycle(h)
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

    def prepare_and_validate
      redirect_to :root and return if resource.nil?
      @limit = resource.class.max_cookie_crypt_login_attempts
      if resource.max_cookie_crypt_login_attempts?
        sign_out(resource)
        render template: 'devise/cookie_crypt/max_login_attempts_reached' and return
      end
    end

    def set_questions # Options are: :one_question_cyclical, :one_question_random, :two_questions_cyclical, :two_questions_random, :all_questions
      h = Hash.class_eval(resource.security_hash)
      @questions = []
      unless h.empty?
        if resource.class.cookie_crypt_auth_through == :one_question_cyclical
          set_cyclicial_cyclemod(h)
        elsif resource.class.cookie_crypt_auth_through == :one_question_random
          set_random_cyclemod(h)
        elsif resource.class.cookie_crypt_auth_through == :two_questions_cyclical
          set_cyclicial_cyclemod(h)

          if session[:cyclemod]+resource.security_cycle+1 <= h.keys.count/2
            next_question_mod = session[:cyclemod]+resource.security_cycle+1
          else
            next_question_mod = 1
          end

          @questions << h["security_question_#{next_question_mod}"]
        elsif resource.class.cookie_crypt_auth_through == :two_questions_random
          if resource.cookie_crypt_attempts_count == 0
            session[:cyclemod] ||= Random.rand(1..(h.keys.count/2))
            r = Random.rand(1..(h.keys.count/2))
            while session[:cyclemod] == r || resource.security_cycle == r
              r = Random.rand(1..(h.keys.count/2))
            end
            session[:cyclemod2] ||= r
          elsif resource.cookie_crypt_attempts_count != 0 && resource.cookie_crypt_attempts_count%resource.class.cycle_question_on_fail_count == 0
            #The tick assists pages that are running redirects to other sources while in two-factor mode. Without it, their
            #cyclemod would desynch from the expected value on the change event (this if case) and they would be unable to auth unless the randoms matched.
            session[:cookie_tick] ||= 0 
            session[:cookie_tick] += 1

            if session[:cookie_tick] == 1
              r = Random.rand(1..(h.keys.count/2))
              while session[:cyclemod] == r || resource.security_cycle == r
                r = Random.rand(1..(h.keys.count/2))
              end
              session[:cyclemod] = r

              r = Random.rand(1..(h.keys.count/2))
              while session[:cyclemod] == r || resource.security_cycle == r
                r = Random.rand(1..(h.keys.count/2))
              end
              session[:cyclemod2] = r
            end
          else #reset the tick
            session[:cookie_tick] = 0
          end

          @questions << h["security_question_#{session[:cyclemod2]}"]
        else #:all_questions case
          h.keys.delete_if{|x| x.include?("answer")}.each do |key|
            @questions << h[key]
          end
        end


        unless resource.class.cookie_crypt_auth_through == :all_questions
          if resource.class.cookie_crypt_auth_through == :one_question_cyclical || 
            resource.class.cookie_crypt_auth_through == :two_questions_cyclical

            @questions << h["security_question_#{resource.security_cycle+session[:cyclemod]}"]
          else #random cyclemod case
            @questions << h["security_question_#{session[:cyclemod]}"]
          end
        end
      end
    end

    def show_request
      action_name == "show" || resource.cookie_crypt_attempts_count != 0
    end
end
