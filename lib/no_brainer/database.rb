class NoBrainer::Database
  attr_accessor :connection

  delegate :database_name, :to => :connection

  def initialize(connection)
    self.connection = connection
  end

  def raw
    @raw ||= RethinkDB::RQL.db(database_name)
  end

  def purge!(options={})
    if options[:drop]
      connection.db_drop(database_name)
    else
      # truncating each table is much faster
      table_list.each do |table_name|
        NoBrainer.run { RethinkDB::RQL.table(table_name).delete }
      end
    end
  rescue RuntimeError => e
    raise e unless e.message =~ /No entry with that name/
  end

  [:table_create, :table_drop, :table_list].each do |cmd|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{cmd}(*args)
        NoBrainer.run { raw.#{cmd}(*args) }
      end
    RUBY
  end
end
