require "rails_helper"

RSpec.describe Author, type: :model do
  subject { build(:author) }

  # ---------------------------
  # Validations
  # ---------------------------
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(Author::MAX_NAME_LENGTH) }
    it { is_expected.to validate_length_of(:bio).is_at_most(Author::MAX_BIO_LENGTH) }
    it { is_expected.to validate_length_of(:nationality).is_at_most(Author::MAX_NATIONALITY_LENGTH) }

    it "is invalid if birth_date is in the future" do
      subject.birth_date = Date.current + 1.day
      expect(subject).not_to be_valid
    end

    it "is valid if death_date is after birth_date" do
      subject.birth_date = Date.new(1900, 1, 1)
      subject.death_date = Date.new(1950, 1, 1)
      expect(subject).to be_valid
    end

    it "is invalid if death_date is before or equal to birth_date" do
      subject.birth_date = Date.new(2000, 1, 1)
      subject.death_date = Date.new(1999, 12, 31)
      expect(subject).not_to be_valid
    end

    it "is invalid if death_date is in the future" do
      subject.birth_date = Date.new(1900, 1, 1)
      subject.death_date = Date.current + 1.day
      expect(subject).not_to be_valid
    end
  end

  # ---------------------------
  # Associations
  # ---------------------------
  describe "associations" do
    it { is_expected.to have_many(:books) }
    it { is_expected.to have_many(:favorites).dependent(:destroy) }
  end

  # ---------------------------
  # Scopes
  # ---------------------------
  describe "scopes" do
    describe ".alive" do
      it "returns authors with no death_date" do
        alive_author = create(:author, death_date: nil)
        create(:author, death_date: Date.yesterday)
        expect(Author.alive).to include(alive_author)
      end
    end

    describe ".deceased" do
      it "returns authors with death_date" do
        deceased_author = create(:author, death_date: Date.yesterday)
        create(:author, death_date: nil)
        expect(Author.deceased).to include(deceased_author)
      end
    end

    describe ".recent" do
      it "orders authors by created_at desc" do
        old_author = create(:author, created_at: 1.day.ago)
        new_author = create(:author, created_at: Time.current)
        expect(Author.recent.first).to eq(new_author)
      end
    end
  end

  # ---------------------------
  # Ransacker
  # ---------------------------
  describe ".ransackable_attributes" do
    it "returns only name as ransackable attribute" do
      expect(Author.ransackable_attributes).to eq(["name"])
    end
  end
end
