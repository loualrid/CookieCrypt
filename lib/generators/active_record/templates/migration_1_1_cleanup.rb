class CookieCrypt11CleanupTo<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    remove_column :<%= table_name %>, :security_question_one
    remove_column :<%= table_name %>, :security_question_two
    remove_column :<%= table_name %>, :security_answer_one
    remove_column :<%= table_name %>, :security_answer_two
  end
end
