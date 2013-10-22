module CookieCrypt
  module Orm
    module ActiveRecord
      module Schema
        include CookieCrypt::Schema
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::Table.send :include, CookieCrypt::Orm::ActiveRecord::Schema
ActiveRecord::ConnectionAdapters::TableDefinition.send :include, CookieCrypt::Orm::ActiveRecord::Schema
