describe "time conversions" do
  it "NSDate and Time should agreee on minutes since epoch" do
    t = Time.new
    d = NSDate.dateWithTimeIntervalSince1970(t.to_f)
    t.to_f.should == d.timeIntervalSince1970
  end

  it "Parsing '3/18/12 @ 7:00 PM' With Natural Language should work right" do
    NSDate.dateWithNaturalLanguageString('3/18/12 @ 7:00 PM'.gsub('-','/'), locale:NSUserDefaults.standardUserDefaults.dictionaryRepresentation).
      strftime("%m-%d-%Y | %I:%M %p").
      should == "03-18-2012 | 07:00 PM"
  end

  describe "auto_date_fields" do

    class Creatable
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns :name => :string,
              :created_at => :date
    end

    class Updateable
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns :name => :string,
              :updated_at => :date
    end

    it "Sets created_at when an item is created" do
      c = Creatable.new(:name => 'test')
      lambda{c.save}.should.change{c.created_at}
    end

    it "Sets updated_at when an item is created" do
      c = Updateable.new(:name => 'test')
      lambda{c.save}.should.change{c.updated_at}
    end

    it "Doesn't update created_at when an item is updated" do
      c = Creatable.create(:name => 'test')
      c.name = 'test 1'
      lambda{c.save}.should.not.change{c.created_at}
    end

    it "Updates updated_at when an item is updated" do
      c = Updateable.create(:name => 'test')
      sleep 1
      c.name = 'test 1'
      lambda{ c.save }.should.change{c.updated_at}
    end

  end

  describe "parsing ISO8601 date formats" do
    class Model
      include MotionModel::Model
      include MotionModel::ArrayModelAdapter
      columns :test_date => :date,
    end

    it 'parses ISO8601 format variant #1 (RoR  default)' do
      m = Model.new(test_date: '2012-04-23T18:25:43Z')
      m.test_date.should.not.be.nil
    end

    it 'parses ISO8601 variant #2, 3DP Accuracy (RoR4), JavaScript built-in JSON object' do
      m = Model.new(test_date: '2012-04-23T18:25:43.511Z')
      m.test_date.should.not.be.nil
    end

    it 'parses ISO8601 variant #3' do
      m = Model.new(test_date: '2012-04-23 18:25:43 +0000')
      m.test_date.should.not.be.nil
      m.test_date.utc.to_s.should.eql '2012-04-23 18:25:43 UTC'
    end
  end
end
