require "../database.rb"
require 'rspec/autorun'

describe Database do
    let(:db) {Database.new}

    it "contains an incrementing counter" do
        id_db = Database.new
        expect(id_db.get_next_id()).to eq(0)
        expect(id_db.get_next_id()).to eq(1)
        expect(id_db.get_next_id()).to eq(2)
    end

    it "has a price_table" do
       expect(db.price_table["pants"]).to eq(45.50)
    end
    it "price_table is read-only" do
       expect {db.price_table["pants"] = 55.00}.to raise_error(FrozenError)
    end
    it "price_table has a default" do
       expect(db.price_table["fake item"]).to eq(9.99)
    end

    it "has a commission_table" do
       expect(db.commission_table["laptop"]).to eq(0.05)
    end
    it "commission_table is read-only" do
       expect {db.commission_table["laptop"] = 0.07}.to raise_error(FrozenError)
    end
    it "commission_table has a default" do
       expect(db.commission_table["fake item"]).to eq(0.0)
    end

    it "has a video_addons table" do
       expect(db.video_addons["Learning to Ski"]).to eq("First Aid")
    end
    it "video_addons is read-only" do
       expect {db.video_addons["Learning to Ski"] = "Ski Harder"}.to raise_error(FrozenError)
    end

    it "has a read/write processed_orders table" do
        expect {db.processed_orders[0] = "new order"}.not_to raise_error
        expect(db.processed_orders[0]).to eq("new order")
    end

    it "has a read-write failed_orders table" do
        expect {db.failed_orders[0] = "new order"}.not_to raise_error
        expect(db.failed_orders[0]).to eq("new order")
    end
end


