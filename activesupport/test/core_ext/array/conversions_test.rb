require 'abstract_unit'
require 'active_support/core_ext/array'
require 'active_support/core_ext/big_decimal'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'

class ToSentenceTest < ActiveSupport::TestCase
  def test_plain_array_to_sentence
    assert_equal "", [].to_sentence
    assert_equal "one", ['one'].to_sentence
    assert_equal "one and two", ['one', 'two'].to_sentence
    assert_equal "one, two, and three", ['one', 'two', 'three'].to_sentence
  end

  def test_to_sentence_with_words_connector
    assert_equal "one two, and three", ['one', 'two', 'three'].to_sentence(words_connector: ' ')
    assert_equal "one & two, and three", ['one', 'two', 'three'].to_sentence(words_connector: ' & ')
    assert_equal "onetwo, and three", ['one', 'two', 'three'].to_sentence(words_connector: nil)
  end

  def test_to_sentence_with_last_word_connector
    assert_equal "one, two, and also three", ['one', 'two', 'three'].to_sentence(last_word_connector: ', and also ')
    assert_equal "one, twothree", ['one', 'two', 'three'].to_sentence(last_word_connector: nil)
    assert_equal "one, two three", ['one', 'two', 'three'].to_sentence(last_word_connector: ' ')
    assert_equal "one, two and three", ['one', 'two', 'three'].to_sentence(last_word_connector: ' and ')
  end

  def test_two_elements
    assert_equal "one and two", ['one', 'two'].to_sentence
    assert_equal "one two", ['one', 'two'].to_sentence(two_words_connector: ' ')
  end

  def test_one_element
    assert_equal "one", ['one'].to_sentence
  end

  def test_one_element_not_same_object
    elements = ["one"]
    assert_not_equal elements[0].object_id, elements.to_sentence.object_id
  end

  def test_one_non_string_element
    assert_equal '1', [1].to_sentence
  end

  def test_does_not_modify_given_hash
    options = { words_connector: ' ' }
    assert_equal "one two, and three", ['one', 'two', 'three'].to_sentence(options)
    assert_equal({ words_connector: ' ' }, options)
  end

  def test_with_blank_elements
    assert_equal ", one, , two, and three", [nil, 'one', '', 'two', 'three'].to_sentence
  end
end

class ToSTest < ActiveSupport::TestCase
  class TestDB
    @@counter = 0
    def id
      @@counter += 1
    end
  end

  def test_to_s_db
    collection = [TestDB.new, TestDB.new, TestDB.new]

    assert_equal "null", [].to_s(:db)
    assert_equal "1,2,3", collection.to_s(:db)
  end
end

class ToXmlTest < ActiveSupport::TestCase
  def test_to_xml_with_hash_elements
    xml = [
      { name: "David", age: 26, age_in_millis: 820497600000 },
      { name: "Jason", age: 31, age_in_millis: BigDecimal.new('1.0') }
    ].to_xml(skip_instruct: true, indent: 0)

    assert_equal '<objects type="array"><object>', xml.first(30)
    assert xml.include?(%(<age type="integer">26</age>)), xml
    assert xml.include?(%(<age-in-millis type="integer">820497600000</age-in-millis>)), xml
    assert xml.include?(%(<name>David</name>)), xml
    assert xml.include?(%(<age type="integer">31</age>)), xml
    assert xml.include?(%(<age-in-millis type="decimal">1.0</age-in-millis>)), xml
    assert xml.include?(%(<name>Jason</name>)), xml
  end

  def test_to_xml_with_non_hash_elements
    xml = [1, 2, 3].to_xml(skip_instruct: true, indent: 0)

    assert_equal '<fixnums type="array"><fixnum', xml.first(29)
    assert xml.include?(%(<fixnum type="integer">2</fixnum>)), xml
  end

  def test_to_xml_with_non_hash_different_type_elements
    xml = [1, 2.0, '3'].to_xml(skip_instruct: true, indent: 0)

    assert_equal '<objects type="array"><object', xml.first(29)
    assert xml.include?(%(<object type="integer">1</object>)), xml
    assert xml.include?(%(<object type="float">2.0</object>)), xml
    assert xml.include?(%(object>3</object>)), xml
  end

  def test_to_xml_with_dedicated_name
    xml = [
      { name: "David", age: 26, age_in_millis: 820497600000 }, { name: "Jason", age: 31 }
    ].to_xml(skip_instruct: true, indent: 0, root: "people")

    assert_equal '<people type="array"><person>', xml.first(29)
  end

  def test_to_xml_with_options
    xml = [
      { name: "David", street_address: "Paulina" }, { name: "Jason", street_address: "Evergreen" }
    ].to_xml(skip_instruct: true, skip_types: true, indent: 0)

    assert_equal "<objects><object>", xml.first(17)
    assert xml.include?(%(<street-address>Paulina</street-address>))
    assert xml.include?(%(<name>David</name>))
    assert xml.include?(%(<street-address>Evergreen</street-address>))
    assert xml.include?(%(<name>Jason</name>))
  end

  def test_to_xml_with_indent_set
    xml = [
      { name: "David", street_address: "Paulina" }, { name: "Jason", street_address: "Evergreen" }
    ].to_xml(skip_instruct: true, skip_types: true, indent: 4)

    assert_equal "<objects>\n    <object>", xml.first(22)
    assert xml.include?(%(\n        <street-address>Paulina</street-address>))
    assert xml.include?(%(\n        <name>David</name>))
    assert xml.include?(%(\n        <street-address>Evergreen</street-address>))
    assert xml.include?(%(\n        <name>Jason</name>))
  end

  def test_to_xml_with_dasherize_false
    xml = [
      { name: "David", street_address: "Paulina" }, { name: "Jason", street_address: "Evergreen" }
    ].to_xml(skip_instruct: true, skip_types: true, indent: 0, dasherize: false)

    assert_equal "<objects><object>", xml.first(17)
    assert xml.include?(%(<street_address>Paulina</street_address>))
    assert xml.include?(%(<street_address>Evergreen</street_address>))
  end

  def test_to_xml_with_dasherize_true
    xml = [
      { name: "David", street_address: "Paulina" }, { name: "Jason", street_address: "Evergreen" }
    ].to_xml(skip_instruct: true, skip_types: true, indent: 0, dasherize: true)

    assert_equal "<objects><object>", xml.first(17)
    assert xml.include?(%(<street-address>Paulina</street-address>))
    assert xml.include?(%(<street-address>Evergreen</street-address>))
  end

  def test_to_xml_with_instruct
    xml = [
      { name: "David", age: 26, age_in_millis: 820497600000 },
      { name: "Jason", age: 31, age_in_millis: BigDecimal.new('1.0') }
    ].to_xml(skip_instruct: false, indent: 0)

    assert_match(/^<\?xml [^>]*/, xml)
    assert_equal 0, xml.rindex(/<\?xml /)
  end

  def test_to_xml_with_block
    xml = [
      { name: "David", age: 26, age_in_millis: 820497600000 },
      { name: "Jason", age: 31, age_in_millis: BigDecimal.new('1.0') }
    ].to_xml(skip_instruct: true, indent: 0) do |builder|
      builder.count 2
    end

    assert xml.include?(%(<count>2</count>)), xml
  end

  def test_to_xml_with_empty
    xml = [].to_xml
    assert_match(/type="array"\/>/, xml)
  end

  def test_to_xml_dups_options
    options = { skip_instruct: true }
    [].to_xml(options)
    # :builder, etc, shouldn't be added to options
    assert_equal({ skip_instruct: true }, options)
  end
end

class ToParamTest < ActiveSupport::TestCase
  class ToParam < String
    def to_param
      "#{self}1"
    end
  end

  def test_string_array
    assert_equal '', %w().to_param
    assert_equal 'hello/world', %w(hello world).to_param
    assert_equal 'hello/10', %w(hello 10).to_param
  end

  def test_number_array
    assert_equal '10/20', [10, 20].to_param
  end

  def test_to_param_array
    assert_equal 'custom1/param1', [ToParam.new('custom'), ToParam.new('param')].to_param
  end
end