RSpec.shared_examples_for :backend do
  def uploadable(data = "hello")
    double(size: data.length, to_io: StringIO.new(data))
  end

  describe "#upload" do
    it "raises ArgumentError when invalid object is uploaded" do
      expect { backend.upload(double(size: 123)) }.to raise_error(ArgumentError)
      expect { backend.upload("hello") }.to raise_error(ArgumentError)
    end

    it "stores file for later retrieval" do
      file = backend.upload(uploadable)
      retrieved = backend.get(file.id)

      expect(retrieved.read).to eq("hello")
      expect(retrieved.size).to eq(5)
      expect(retrieved.exists?).to be_truthy
    end
  end

  describe "#delete" do
    it "removes a cached file" do
      file = backend.cache(uploadable)

      backend.delete(file.id)

      expect(backend.get(file.id).exists?).to be_falsy
    end

    it "removes a stored file" do
      file = backend.upload(uploadable)

      backend.delete(file.id)

      expect(backend.get(file.id).exists?).to be_falsy
    end

    it "does not affect other files a stored file" do
      file = backend.upload(uploadable)
      other = backend.upload(uploadable)

      backend.delete(file.id)

      expect(backend.get(file.id).exists?).to be_falsy
      expect(backend.get(other.id).exists?).to be_truthy
    end

    it "does nothing when file doesn't exist" do
      file = backend.upload(uploadable)

      backend.delete(file.id)
      backend.delete(file.id)
    end

    it "can be called through file" do
      file = backend.upload(uploadable)

      file.delete

      expect(backend.get(file.id).exists?).to be_falsy
    end
  end

  describe "#clear_cache!" do
    it "removes cached files" do
      file = backend.cache(uploadable)

      backend.clear_cache!

      expect(backend.get(file.id).exists?).to be_falsy
    end

    it "does not remove stored files" do
      file = backend.upload(uploadable)

      backend.clear_cache!

      expect(backend.get(file.id).exists?).to be_truthy
    end
  end

  describe "#open" do
    it "opens an IO object from the file" do
      file = backend.upload(uploadable)

      expect(backend.open(file.id).readpartial(4)).to eq("hell")
    end

    it "can be called with a block for automatic cleanup" do
      file = backend.upload(uploadable)

      result = backend.open(file.id) { |file| file.readpartial(4) }

      expect(result).to eq("hell")
    end

    it "can be called through the file" do
      file = backend.upload(uploadable)

      expect(file.to_io.readpartial(4)).to eq("hell")
    end
  end
end