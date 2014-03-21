Object.send(:remove_const, :ModelWithOptions) if defined?(ModelWithOptions)
class ModelWithOptions
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Formotion

  columns :name => :string,
          :date => {:type => :date, :formotion => {:picker_type => :date_time}},
          :location => {:type => :string, :formotion => {:section => :address}},
          :created_at => :date,
          :updated_at => :date

  has_many :related_models

  has_formotion_sections :address => { title: "Address" }

end

class RelatedModel
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name => :string
  belongs_to :model_with_options
end

def section(subject)
  subject[:sections]
end

def rows(subject)
  section(subject).first[:rows]
end

def first_row(subject)
  rows(subject).first
end

describe "formotion" do
  before do
    @subject = ModelWithOptions.create(:name => 'get together', :date => '12-11-13 @ 9:00 PM', :location => 'my house')
  end

  it "generates a formotion hash" do
    @subject.to_formotion.should.not.be.nil
  end

  it "has the correct form title" do
    @subject.to_formotion('test form')[:title].should == 'test form'
  end

  it "has two sections" do
    @subject.to_formotion[:sections].length.should == 2
  end

  it "has 2 rows in default section" do
    @subject.to_formotion[:sections].first[:rows].length.should == 2
  end

  it "does not include title in the default section" do
    @subject.to_formotion[:sections].first[:title].should == nil
  end

  it "does include title in the :address section" do
    @subject.to_formotion[:sections][1][:title].should == 'Address'
  end

  it "has 1 row in :address section" do
    @subject.to_formotion[:sections][1][:rows].length.should == 1
  end

  it "value of location row in :address section is 'my house'" do
    @subject.to_formotion[:sections][1][:rows].first[:value].should == 'my house'
  end

  it "value of name row is 'get together'" do
    first_row(@subject.to_formotion)[:value].should == 'get together'
  end

  it "binds data from rendered form into model fields" do
    @subject.from_formotion!({:name => '007 Reunion', :date => 1358197323, :location => "Q's Lab"})
    @subject.name.should == '007 Reunion'
    @subject.date.utc.strftime("%Y-%m-%d %H:%M").should == '2013-01-14 21:02'
    @subject.location.should == "Q's Lab"
  end


  class Array
    def has_hash_value?(value)
      self.each do |ele|
        raise ArgumentError('has_hash_value? only works for arrays of hashes') unless ele.is_a?(Hash)

        ele.each_pair do |k, v|
          next unless v.class == value.class
          return true if v == value
        end
      end
      false
    end
  end

  describe 'auto fields behavior' do
    before do
      @first_section_rows = @subject.to_formotion[:sections].first[:rows]
    end

    # Note on why this is has_hash_value instead of has_hash_key.
    # The Formotion result is an array of hashes, and the real
    # keys are in the form:
    #
    # {key: :created_at}
    #
    # so the database field name is the value of the hash key :key
    it "does not include auto date fields in the hash by default" do
      @first_section_rows.has_hash_value?(:updated_at).should == false
      @first_section_rows.has_hash_value?(:created_at).should == false
    end

    class Array
      def has_hash_value?(value)
        self.each do |ele|
          raise ArgumentError('has_hash_value? only works for arrays of hashes') unless ele.is_a?(Hash)

          ele.each_pair do |k, v|
            next unless v.class == value.class
            return true if v == value
          end
        end
        false
      end
    end

    it "can optionally include auto date fields in the hash" do
      optional_result = @subject.to_formotion(nil, true)[:sections].first[:rows]
      result = optional_result.has_hash_value?(:created_at).should == true
      result = optional_result.has_hash_value?(:updated_at).should == true
    end

    it "does not include related columns in the collection" do
      result = @first_section_rows.has_hash_value?(:related_models).should == false
    end
  end

  describe "new syntax" do
    it "generates a formotion hash" do
      @subject.new_to_formotion.should.not.be.nil
    end

    it "has the correct form title" do
      @subject.new_to_formotion(form_title: 'test form')[:title].should == 'test form'
    end

    it "has two sections" do
      s = @subject.new_to_formotion(
        sections: [
          {title: 'one'},
          {title: 'two'}
          ]
          )[:sections].length.should == 2
    end

    it "does not include title in the default section" do
      @subject.new_to_formotion(
        sections: [
          {fields: [:name]},
          {title: 'two'}
          ]
          )[:sections].first[:title].should == nil
    end

    it "does include address in the second section" do
      @subject.new_to_formotion(
        sections: [
          {fields: [:name]},
          {title: 'two'}
          ]
          )[:sections][1][:title].should.not == nil
    end

    it "has two rows in the first section" do
      @subject.new_to_formotion(
        sections: [
          {fields: [:name, :date]},
          {title: 'two'}
          ]
          )[:sections][0][:rows].length.should == 2
    end

    it "has two rows in the first section" do
      @subject.new_to_formotion(
        sections: [
          {fields: [:name, :date]},
          {title: 'two'}
          ]
          )[:sections][0][:rows].length.should == 2
    end

    it "value of location row in :address section is 'my house'" do
      @subject.new_to_formotion(
        sections: [
          {title: 'name', fields: [:name, :date]},
          {title: 'address', fields: [:location]}
          ]
          )[:sections][1][:rows].first[:value].should == 'my house'
    end
    it "value of name row is 'get together'" do
        @subject.new_to_formotion(
        sections: [
          {title: 'name', fields: [:name, :date]},
          {title: 'address', fields: [:location]}
          ]
          )[:sections][1][:rows].first[:value].should == 'my house'
    end
    it "allows you to place buttons in your form" do
        result = @subject.new_to_formotion(
        sections: [
          {title: 'name', fields: [:name, :date, {title: 'Submit', type: :submit}]},
          {title: 'address', fields: [:location]}
          ]
          )

        result[:sections][0][:rows][2].should.is_a? Hash
        result[:sections][0][:rows][2].should.has_key?(:type)
        result[:sections][0][:rows][2][:type].should == :submit
    end

    it "creates date as a float in the formotion hash" do
        result = @subject.new_to_formotion(
        sections: [
          {title: 'name', fields: [:name, :date, {title: 'Submit', type: :submit}]},
          {title: 'address', fields: [:location]}
          ]
          )
        date_row = result[:sections][0][:rows][1]
        date_row.should.has_key?(:type)
        date_row[:type].should == :date
        date_row[:value].class.should == Float
    end
  end
end
