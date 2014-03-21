module MotionModel
  module Formotion
    def self.included(base)
      base.extend(PublicClassMethods)
    end
    module PublicClassMethods
      def has_formotion_sections(sections = {})
        define_method( "formotion_sections") do
          sections
        end
      end
    end
    FORMOTION_MAP = {
      :string   => :string,
      :date     => :date,
      :time     => :date,
      :int      => :number,
      :integer  => :number,
      :float    => :number,
      :double   => :number,
      :bool     => :check,
      :boolean  => :check,
      :text     => :text
    }

    def should_return(column) #nodoc
      skippable = [:id]
      skippable += [:created_at, :updated_at] unless @expose_auto_date_fields
      !skippable.include?(column) && !relation_column?(column)
    end

    def returnable_columns #nodoc
      columns.select{|column| should_return(column)}
    end

    def default_hash_for(column, value)
      value = value.to_f if is_date_time?(column)

      {:key         => column.to_sym,
       :title       => column.to_s.humanize,
       :type        => FORMOTION_MAP[column_type(column)],
       :placeholder => column.to_s.humanize,
       :value       => value
       }
    end

    def is_date_time?(column)
      column_type = column_type(column)
      [:date, :time].include?(column_type)
     end

    def value_for(column) #nodoc
      value = self.send(column)
      value = value.to_f if value && is_date_time?(column)
      value
    end

    def combine_options(column, hash) #nodoc
      options = column(column).options[:formotion]
      options ? hash.merge(options) : hash
    end

    # <tt>to_formotion</tt> maps a MotionModel into a hash suitable for creating
    # a Formotion form. By default, the auto date fields, <tt>created_at</tt>
    # and <tt>updated_at</tt> are suppressed. If you want these shown in
    # your Formotion form, set <tt>expose_auto_date_fields</tt> to <tt>true</tt>
    #
    # If you want a title for your Formotion form, set the <tt>form_title</tt>
    # argument to a string that will become that title.
    def to_formotion(form_title = nil, expose_auto_date_fields = false, first_section_title = nil)
      return new_to_formotion(form_title) if form_title.is_a? Hash

      @expose_auto_date_fields = expose_auto_date_fields

      sections = {
        default: {rows: []}
      }
      if respond_to? 'formotion_sections'
        formotion_sections.each do |k,v|
          sections[k] = v
          sections[k][:rows] = []
        end
      end
      sections[:default][:title] ||= first_section_title

      returnable_columns.each do |column|
        value = value_for(column)
        h = default_hash_for(column, value)
        s = column(column).options[:formotion] ? column(column).options[:formotion][:section] : nil
        if s
          sections[s] ||= {}
          sections[s][:rows].push(combine_options(column,h))
        else
          sections[:default][:rows].push(combine_options(column, h))
        end
      end

      form = {
        sections: []
      }
      form[:title] ||= form_title
      sections.each do |k,section|
        form[:sections] << section
      end
      form
    end

    # <tt>new_to_formotion</tt> maps a MotionModel into a hash in a user-definable
    # manner, according to options.
    #
    # form_title:    String for form title
    # sections:      Array of sections
    #
    # Within sections, use these keys:
    #
    # title:         String for section title
    # field:         Name of field in your model (Symbol)
    #
    # Hash looks something like this:
    #
    # {sections: [
    #   {title:  'First Section',           # First section
    #    fields: [:name, :gender]           # contains name and gender
    #   },
    #   {title:  'Second Section',
    #    fields: [:address, :city, :state],  # Second section, address
    #    {title: 'Submit', type: :submit}    # city, state add submit button
    #   }
    # ]}
    def new_to_formotion(options = {form_title: nil, sections: []})
      form = {}

      @expose_auto_date_fields = options[:auto_date_fields]

      fields = returnable_columns
      form[:title] = options[:form_title] unless options[:form_title].nil?
      fill_from_options(form, options) if options[:sections]
      form
    end

    def fill_from_options(form, options)
      form[:sections] ||= []

      options[:sections].each do |section|
        form[:sections] << fill_section(section)
      end
      form
    end

    def fill_section(section)
      new_section = {}

      section.each_pair do |key, value|
        case key
        when :title
          new_section[:title] = value unless value.nil?
        when :fields
          new_section[:rows] ||= []
          value.each do |field_or_hash|
            new_section[:rows].push(fill_row(field_or_hash))
          end
        end
      end
      new_section
    end

    def fill_row(field_or_hash)
      case field_or_hash
        when Hash
          return field_or_hash unless field_or_hash.keys.detect{|key| key =~ /^formotion_/}
        else
          combine_options field_or_hash, default_hash_for(field_or_hash, self.send(field_or_hash))
      end
    end

    # <tt>from_formotion</tt> takes the information rendered from a Formotion
    # form and stuffs it back into a MotionModel. This data is not saved until
    # you say so, offering you the opportunity to validate your form data.
    def from_formotion!(data)
      self.returnable_columns.each{|column|
        if data[column] && column_type(column) == :date || column_type(column) == :time
          data[column] = Time.at(data[column]) unless data[column].nil?
        end
        value = self.send("#{column}=", data[column])
      }
    end
  end
end
