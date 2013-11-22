class CookieCryptCompleteInstallAddTo<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    change_table :<%= table_name %> do |t|
      <%='t.string   :username, null: false, default: ""' if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['username: string'].blank?") %>
      t.text     :security_hash, default: "{}"
      t.integer  :security_cycle, default: 1
      t.text     :agent_list, default: ""
      t.integer  :cookie_crypt_attempts_count, default: 0
    end
  end
end
