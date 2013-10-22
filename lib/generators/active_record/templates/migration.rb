class CookieCryptAddTo<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    change_table :<%= table_name %> do |t|
      <%='t.string   :username, null: false, default: ""' if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['username: string'].blank?") %>
      t.string   :security_question_one, default: ""
      t.string   :security_question_two, default: ""
      t.string   :security_answer_one, default: ""
      t.string   :security_answer_two, default: ""
      t.text     :agent_list, default: ""
      t.integer  :cookie_crypt_attempts_count, default: 0
    end
  end
end
