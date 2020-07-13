
require 'test_helper'

require 'active_record_doctor/tasks/missing_string_length_validation'

class ActiveRecordDoctor::Tasks::MissingStringLengthValidationTest < ActiveSupport::TestCase
  def test_missing_validation_is_reported_on_string_only
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
        t.boolean :active
      end
    end

    assert_equal({ 'User' => ['name'] }, run_task)
  end

  def test_missing_validation_is_not_reported_on_type_column
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
        t.string :type
      end
    end

    assert_equal({ 'User' => ['name'] }, run_task)
  end

  def test_missing_validation_is_not_reported_on_polymorphic_type_column
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
        t.string :access_type
        t.integer :access_id
      end

      belongs_to :access, polymorphic: true
    end

    assert_equal({ 'User' => ['name'] }, run_task)
  end

  def test_missing_validation_is_not_reported_if_limit_present
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name, limit: 10
      end
    end

    assert_equal({}, run_task)
  end

  def test_missing_validation_is_not_reported_if_validation_present
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
      end

      validates :name, length: { maximum: 10 }
    end

    assert_equal({}, run_task)
  end

  def test_missing_validation_is_not_reported_if_validation_present_as_range
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
      end

      validates :name, length: { in: 1..10 }
    end

    assert_equal({}, run_task)
  end

  def test_missing_validation_is_reported_if_validation_maximum_is_not_present
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
      end

      validates :name, length: { minimum: 10 }
    end

    assert_equal({ 'User' => ['name'] }, run_task)
  end
end
