class CookieCrypt11UpdateTo<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    change_table :<%= table_name %> do |t|
      t.text    :security_hash, default: '{}'
      t.integer :security_cycle, default: 1
    end
  end
end
